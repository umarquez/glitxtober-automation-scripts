-- Shared Hammerspoon runner for Glitxtober Sonic Pi episodes.
-- Handles safe typing, line navigation, incremental edits, reset/run and hotkeys.

local Runner = {}
Runner.__index = Runner

local DEFAULTS = {
  appName = "Sonic Pi",

  charMin = 0.018,
  charMax = 0.048,
  punctuationExtra = 0.014,

  keyStrokeUs = 50000,
  returnUs = 180000,
  newlineMin = 0.30,
  newlineMax = 0.42,
  structuralExtra = 0.16,
  sampleExtra = 0.14,

  appFocusDelay = 0.50,
  editorFocusDelay = 0.18,
  beatStartDelay = 0.30,
  navDelay = 0.020,
  settleAfterNav = 0.08,
  settleAfterEdit = 0.22,
  tidyDelay = 0.70,
  runDelay = 0.25,
  clearDelay = 0.18,
  stopRepeatDelay = 0.18,
  stopSettleDelay = 0.55,

  statusDuration = 1.30,
}

local function copyTable(source)
  local out = {}
  for k, v in pairs(source or {}) do out[k] = v end
  return out
end

local function merge(base, extra)
  local out = copyTable(base)
  for k, v in pairs(extra or {}) do out[k] = v end
  return out
end

local function status(message, duration)
  if _G.GlitxStatus and _G.GlitxStatus.show then
    return _G.GlitxStatus.show(message, duration or DEFAULTS.statusDuration)
  end

  hs.printf("[Glitxtober] %s", tostring(message))
  return nil
end

local function rand(a, b)
  return a + math.random() * (b - a)
end

local function normalize(text)
  if not text then return "" end
  return text:gsub("\r\n", "\n"):gsub("\r", "\n")
end

local function stripFinalNewline(text)
  return (normalize(text):gsub("\n$", ""))
end

local function linesOf(text)
  text = normalize(text)
  if text == "" then return {} end

  local out, start = {}, 1
  while true do
    local pos = text:find("\n", start, true)
    if not pos then
      table.insert(out, text:sub(start))
      break
    end

    table.insert(out, text:sub(start, pos - 1))
    start = pos + 1

    if start > #text then
      table.insert(out, "")
      break
    end
  end

  return out
end

local function join(lines)
  return table.concat(lines, "\n")
end

local function findLine(document, target)
  for i, line in ipairs(linesOf(document)) do
    if line == target then return i end
  end
  return nil
end

local function replaceModelLine(document, index, replacement)
  local lines = linesOf(document)
  lines[index] = replacement
  return join(lines)
end

local function insertModel(document, index, text, after)
  local lines = linesOf(document)
  local inserted = linesOf(stripFinalNewline(text))
  local out = {}

  for i, line in ipairs(lines) do
    if not after and i == index then
      for _, x in ipairs(inserted) do table.insert(out, x) end
    end

    table.insert(out, line)

    if after and i == index then
      for _, x in ipairs(inserted) do table.insert(out, x) end
    end
  end

  return join(out)
end

local function validateModel(document)
  local lines = linesOf(document)

  for i, line in ipairs(lines) do
    local trimmed = line:gsub("^%s+", "")

    if trimmed:match("^sample%s+") and trimmed:find("sleep", 1, true) then
      return false, "sample y sleep están en la misma línea"
    end

    if trimmed:match("^live_loop%s+") and i > 1 and lines[i - 1] ~= "" then
      return false, "falta línea en blanco antes de " .. trimmed
    end
  end

  return true
end

function Runner.new(spec)
  assert(type(spec) == "table", "Runner.new requiere una especificación")
  assert(type(spec.beats) == "table", "La especificación requiere beats")

  if _G.GLITX_ACTIVE_RUNNER and _G.GLITX_ACTIVE_RUNNER.destroy then
    _G.GLITX_ACTIVE_RUNNER:destroy()
  end

  local self = setmetatable({
    episode = spec.episode or "XX",
    title = spec.title or "Sonic Pi",
    beats = spec.beats,
    C = merge(DEFAULTS, spec.config),

    beat = 1,
    busy = false,
    generation = 0,
    timer = nil,
    app = nil,
    document = "",
    dirty = false,
    needsReset = true,
    hotkeys = {},
  }, Runner)

  math.randomseed(os.time())
  self:bindHotkeys()
  _G.GLITX_ACTIVE_RUNNER = self

  status(
    string.format(
      "EP%s — %s — runner listo; usa ⌃⌥⌘R antes de comenzar",
      self.episode,
      self.title
    ),
    1.6
  )

  return self
end

function Runner:schedule(delay, fn, generation)
  local gen = generation or self.generation
  if self.timer then self.timer:stop() end

  self.timer = hs.timer.doAfter(delay, function()
    self.timer = nil
    if gen ~= self.generation then return end
    fn()
  end)
end

function Runner:cancel(message, dirty)
  self.generation = self.generation + 1
  if self.timer then self.timer:stop(); self.timer = nil end
  if dirty and self.busy then self.dirty = true end
  self.busy = false
  if message then status(message, 1.8) end
end

function Runner:preflight()
  if not hs.accessibilityState(false) then
    hs.accessibilityState(true)
    status("Hammerspoon necesita Accessibility", 3)
    return false
  end

  if hs.eventtap.isSecureInputEnabled() then
    status("Secure Input bloquea la escritura automática", 3)
    return false
  end

  return true
end

function Runner:key(mods, key, holdUs)
  if not self.app then return end
  hs.eventtap.keyStroke(mods, key, holdUs or self.C.keyStrokeUs, self.app)
end

function Runner:focusEditor(done)
  if not self:preflight() then self.busy = false; return end

  if not hs.application.launchOrFocus(self.C.appName) then
    self.busy = false
    status("No pude abrir Sonic Pi", 2)
    return
  end

  local gen = self.generation
  self:schedule(self.C.appFocusDelay, function()
    self.app = hs.application.get(self.C.appName)

    if not self.app then
      self.busy = false
      status("No encontré el proceso de Sonic Pi", 2)
      return
    end

    self.app:activate(true)
    self:key({"ctrl", "shift"}, "e")
    self:schedule(self.C.editorFocusDelay, done, gen)
  end, gen)
end

function Runner:typeText(text, done)
  text = normalize(text)
  local gen, i, n = self.generation, 1, #text

  local function nextChar()
    if gen ~= self.generation then return end
    if i > n then done(); return end

    if hs.eventtap.isSecureInputEnabled() then
      self:cancel("Secure Input activado", true)
      return
    end

    local ch = text:sub(i, i)
    i = i + 1
    local delay = rand(self.C.charMin, self.C.charMax)

    if ch == "\n" then
      local previousLine = text:sub(1, i - 2):match("([^\n]*)$") or ""
      self:key({}, "return", self.C.returnUs)

      delay =
        delay +
        (self.C.returnUs / 1000000) +
        rand(self.C.newlineMin, self.C.newlineMax)

      if previousLine:match("%f[%a]do%s*$") or previousLine:match("^%s*end%s*$") then
        delay = delay + self.C.structuralExtra
      elseif previousLine:match("^%s*sample%s+") then
        delay = delay + self.C.sampleExtra
      end
    else
      hs.eventtap.keyStrokes(ch, self.app)

      if ch == "," or ch == ":" or ch == ")" or ch == "]" then
        delay = delay + self.C.punctuationExtra
      elseif ch == " " then
        delay = delay * 0.65
      end
    end

    self:schedule(delay, nextChar, gen)
  end

  nextChar()
end

function Runner:boundary(which, done)
  local gen = self.generation

  self:key({"cmd"}, "a")
  self:schedule(self.C.settleAfterNav, function()
    self:key({}, which == "start" and "left" or "right")
    self:schedule(self.C.settleAfterNav, done, gen)
  end, gen)
end

function Runner:goToLine(lineNumber, done)
  local gen = self.generation

  self:boundary("start", function()
    local remaining = lineNumber - 1

    local function step()
      if gen ~= self.generation then return end

      if remaining <= 0 then
        self:schedule(self.C.settleAfterNav, done, gen)
        return
      end

      self:key({}, "down")
      remaining = remaining - 1
      self:schedule(self.C.navDelay, step, gen)
    end

    step()
  end)
end

function Runner:clear(done)
  local gen = self.generation

  self:key({"cmd"}, "a")
  self:schedule(self.C.clearDelay, function()
    self:key({}, "delete")
    self:schedule(self.C.clearDelay, done, gen)
  end, gen)
end

function Runner:edit(action, done)
  local kind = action.type

  if kind == "set" then
    local text = stripFinalNewline(action.text)

    self:clear(function()
      self:typeText(text, function()
        self.document = text
        self:schedule(self.C.settleAfterEdit, done)
      end)
    end)

    return
  end

  if kind == "append" then
    local text = stripFinalNewline(action.text)
    local prefix = self.document == "" and "" or "\n"

    self:boundary("end", function()
      self:typeText(prefix .. text, function()
        self.document =
          self.document == "" and text or (self.document .. "\n" .. text)
        self:schedule(self.C.settleAfterEdit, done)
      end)
    end)

    return
  end

  if kind == "append_block" then
    local text = stripFinalNewline(action.text)
    local prefix = self.document == "" and "" or "\n\n"

    self:boundary("end", function()
      self:typeText(prefix .. text, function()
        self.document =
          self.document == "" and text or (self.document .. "\n\n" .. text)
        self:schedule(self.C.settleAfterEdit, done)
      end)
    end)

    return
  end

  if kind == "prepend" then
    local text = normalize(action.text)

    self:boundary("start", function()
      self:typeText(text, function()
        self.document = text .. self.document
        self:schedule(self.C.settleAfterEdit, done)
      end)
    end)

    return
  end

  local line = findLine(self.document, action.target)
  if not line then
    self:cancel("No encontré: " .. tostring(action.target), true)
    return
  end

  if kind == "insert_before" then
    local text = normalize(action.text)

    self:goToLine(line, function()
      self:typeText(text, function()
        self.document = insertModel(self.document, line, text, false)
        self:schedule(self.C.settleAfterEdit, done)
      end)
    end)

    return
  end

  if kind == "insert_after" then
    local text = normalize(action.text)

    self:goToLine(line + 1, function()
      self:typeText(text, function()
        self.document = insertModel(self.document, line, text, true)
        self:schedule(self.C.settleAfterEdit, done)
      end)
    end)

    return
  end

  if kind == "replace_line" then
    local replacement = stripFinalNewline(action.text)
    local gen = self.generation

    self:goToLine(line, function()
      self:key({"shift"}, "down")

      self:schedule(self.C.settleAfterNav, function()
        self:typeText(replacement .. "\n", function()
          self.document = replaceModelLine(self.document, line, replacement)
          self:schedule(self.C.settleAfterEdit, done, gen)
        end)
      end, gen)
    end)

    return
  end

  self:cancel("Acción desconocida: " .. tostring(kind), true)
end

function Runner:tidyRun(done)
  local gen = self.generation

  self:key({"cmd"}, "m")
  self:schedule(self.C.tidyDelay, function()
    self:key({"cmd"}, "r")
    self:schedule(self.C.runDelay, done, gen)
  end, gen)
end

function Runner:runBeat()
  if self.busy then status("Editando…", 0.8); return end
  if self.needsReset then status("Primero usa ⌃⌥⌘R", 1.8); return end
  if self.dirty then status("Toma desincronizada; usa ⌃⌥⌘R", 2); return end

  local beat = self.beats[self.beat]
  if not beat then
    status("Episodio completo ✓", 1.5)
    return
  end

  self.busy = true
  self.generation = self.generation + 1
  local gen = self.generation

  status(
    string.format("%02d/%02d  %s", self.beat, #self.beats, beat.name),
    self.C.statusDuration
  )

  self:focusEditor(function()
    if gen ~= self.generation then return end

    local index = 1

    local function nextAction()
      if gen ~= self.generation then return end
      local action = beat.actions and beat.actions[index] or nil

      if not action then
        local ok, err = validateModel(self.document)
        if not ok then
          self:cancel("Modelo inválido: " .. err, true)
          return
        end

        self:tidyRun(function()
          if gen ~= self.generation then return end

          self.busy = false
          self.beat = self.beat + 1

          if self.beat <= #self.beats then
            status("Listo. ⌃⌥⌘N → siguiente beat", 1)
          else
            status("Episodio completo ✓", 1.5)
          end
        end)

        return
      end

      self:edit(action, function()
        if gen ~= self.generation then return end
        index = index + 1
        nextAction()
      end)
    end

    self:schedule(self.C.beatStartDelay, nextAction, gen)
  end)
end

function Runner:resetTake()
  self:cancel(nil, false)

  self.beat = 1
  self.document = ""
  self.dirty = false
  self.needsReset = true
  self.generation = self.generation + 1

  local gen = self.generation
  self.busy = true

  self:focusEditor(function()
    if gen ~= self.generation then return end

    self:key({"cmd"}, "s")
    self:schedule(self.C.stopRepeatDelay, function()
      self:key({"cmd"}, "s")

      self:schedule(self.C.stopSettleDelay, function()
        self:clear(function()
          if gen ~= self.generation then return end

          self.busy = false
          self.needsReset = false
          status("Runtime limpio — ⌃⌥⌘N para empezar", 1.6)
        end)
      end, gen)
    end, gen)
  end)
end

function Runner:info()
  local beat = self.beats[self.beat]

  if beat then
    status(
      string.format(
        "Siguiente: %02d/%02d — %s",
        self.beat,
        #self.beats,
        beat.name
      ),
      2
    )
  else
    status("Episodio completo ✓", 1.5)
  end
end

function Runner:testTyping()
  if self.busy then return end

  self.generation = self.generation + 1
  self.busy = true
  local gen = self.generation

  self:focusEditor(function()
    if gen ~= self.generation then return end

    hs.eventtap.keyStrokes("# Hammerspoon OK", self.app)
    self.busy = false
    self.dirty = true
    self.needsReset = true

    status("Prueba enviada — reinicia la toma", 1.5)
  end)
end

function Runner:bindHotkeys()
  local mods = {"ctrl", "alt", "cmd"}

  table.insert(self.hotkeys, hs.hotkey.bind(mods, "n", function()
    self:runBeat()
  end))

  table.insert(self.hotkeys, hs.hotkey.bind(mods, "r", function()
    self:resetTake()
  end))

  table.insert(self.hotkeys, hs.hotkey.bind(mods, "i", function()
    self:info()
  end))

  table.insert(self.hotkeys, hs.hotkey.bind(mods, "x", function()
    self:cancel("Automatización cancelada — reinicia la toma", true)
  end))

  table.insert(self.hotkeys, hs.hotkey.bind(mods, "t", function()
    self:testTyping()
  end))
end

function Runner:destroy()
  self:cancel(nil, false)

  for _, hotkey in ipairs(self.hotkeys or {}) do
    hotkey:delete()
  end

  self.hotkeys = {}
end

return Runner
