-- Glitxtober 2026 — Episodio 01: Código → sonido
-- Hammerspoon runner v4.1 — newline-safe

local R = {
  beat = 1,
  busy = false,
  generation = 0,
  timer = nil,
  app = nil,
  document = "",
  dirty = false,
  needsReset = true,
}

local C = {
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

  alertDuration = 1.30,
  alertClearance = 0.20,
  appFocusDelay = 0.50,
  editorFocusDelay = 0.18,
  navDelay = 0.020,
  settleAfterNav = 0.08,
  settleAfterEdit = 0.22,
  tidyDelay = 0.70,
  runDelay = 0.25,
  clearDelay = 0.18,
  stopRepeatDelay = 0.18,
  stopSettleDelay = 0.55,
}

local HOOK_REST = [=[
sleep 0.5
play :fs5
sleep 0.25
play :a5
sleep 0.25
play :b5
sleep 0.5
play :a5
sleep 0.5
play :fs5
sleep 0.25
play :e5
sleep 0.25
play :fs5
sleep 1.5
]=]

local KICK = [=[
live_loop :kick, sync: :melody do
4.times do
sample :bd_haus
sleep 1
end
end
]=]

local SNARE = [=[
live_loop :snare, sync: :melody do
sleep 1
sample :elec_hi_snare, amp: 0.8
sleep 2
sample :elec_hi_snare, amp: 0.8
sleep 1
end
]=]

local HATS = [=[
live_loop :hats, sync: :melody do
8.times do
sample :drum_cymbal_closed, amp: 0.35
sleep 0.5
end
end
]=]

local BASS = [=[
live_loop :bass, sync: :melody do
use_synth :fm

play :d2, release: 0.25, amp: 0.7
sleep 1.5
play :a1, release: 0.25, amp: 0.7
sleep 0.5
play :b1, release: 0.25, amp: 0.7
sleep 1.5
play :a1, release: 0.25, amp: 0.7
sleep 0.5
end
]=]

local BEATS = {
  { name = "01 — Una instrucción, un sonido", actions = {
    { type = "set", text = "play :d5" },
  }},

  { name = "02 — Construir el hook", actions = {
    { type = "append", text = HOOK_REST },
  }},

  { name = "03 — Fijar el tempo", actions = {
    { type = "prepend", text = "use_bpm 120\n\n" },
  }},

  { name = "04 — Repetir sin copiar", actions = {
    { type = "insert_before", target = "play :d5", text = "live_loop :melody do\n" },
    { type = "append", text = "end" },
  }},

  { name = "05A — Añadir kick", actions = {
    { type = "append_block", text = KICK },
  }},

  { name = "05B — Añadir clap / snare", actions = {
    { type = "append_block", text = SNARE },
  }},

  { name = "05C — Añadir hi-hat", actions = {
    { type = "append_block", text = HATS },
  }},

  { name = "06 — Bajo sincopado", actions = {
    { type = "append_block", text = BASS },
  }},

  { name = "07A — Lead: :beep", actions = {
    { type = "insert_after", target = "live_loop :melody do", text = "use_synth :beep\n\n" },
  }},

  { name = "07B — Lead: :prophet", actions = {
    { type = "replace_line", target = "use_synth :beep", text = "use_synth :prophet" },
  }},

  { name = "07C — Lead: :pluck + articulación", actions = {
    { type = "replace_line", target = "use_synth :prophet", text = "use_synth :pluck" },
    { type = "replace_line", target = "play :d5", text = "play :d5, release: 0.2, amp: 0.9" },
    { type = "replace_line", target = "play :fs5", text = "play :fs5, release: 0.2, amp: 0.9" },
    { type = "replace_line", target = "play :a5", text = "play :a5, release: 0.2, amp: 0.9" },
    { type = "replace_line", target = "play :b5", text = "play :b5, release: 0.2, amp: 0.9" },
    { type = "replace_line", target = "play :a5", text = "play :a5, release: 0.2, amp: 0.9" },
    { type = "replace_line", target = "play :fs5", text = "play :fs5, release: 0.2, amp: 0.9" },
    { type = "replace_line", target = "play :e5", text = "play :e5, release: 0.2, amp: 0.9" },
    { type = "replace_line", target = "play :fs5", text = "play :fs5, release: 0.2, amp: 0.9" },
  }},

  { name = "08A — Primera decisión generativa", actions = {
    { type = "replace_line", target = "play :b5, release: 0.2, amp: 0.9",
      text = "play choose([:a5, :b5, :d6]), release: 0.2, amp: 0.9" },
  }},

  { name = "08B — Segunda decisión generativa", actions = {
    { type = "replace_line", target = "play :e5, release: 0.2, amp: 0.9",
      text = "play choose([:d5, :e5, :a5]), release: 0.2, amp: 0.9" },
  }},

  { name = "09 — Pieza completa / mini performance", actions = {} },
}

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

local function validateSources()
  local checks = {
    { KICK,  "sample :bd_haus\nsleep 1", "kick" },
    { SNARE, "sample :elec_hi_snare, amp: 0.8\nsleep 2", "snare 1" },
    { SNARE, "sample :elec_hi_snare, amp: 0.8\nsleep 1", "snare 2" },
    { HATS,  "sample :drum_cymbal_closed, amp: 0.35\nsleep 0.5", "hats" },
  }

  for _, check in ipairs(checks) do
    if not check[1]:find(check[2], 1, true) then
      error("EP01 source validation failed: " .. check[3])
    end
  end
end

local function validateModel(document)
  local lines = linesOf(document)

  for i, line in ipairs(lines) do
    if line:match("^sample%s+") and line:find("sleep", 1, true) then
      return false, "sample y sleep están en la misma línea"
    end

    if line:match("^live_loop%s+") and i > 1 and lines[i - 1] ~= "" then
      return false, "falta línea en blanco antes de " .. line
    end
  end

  return true
end

validateSources()

function R:schedule(delay, fn, generation)
  local gen = generation or self.generation
  if self.timer then self.timer:stop() end

  self.timer = hs.timer.doAfter(delay, function()
    self.timer = nil
    if gen ~= self.generation then return end
    fn()
  end)
end

function R:cancel(message, dirty)
  self.generation = self.generation + 1
  if self.timer then self.timer:stop(); self.timer = nil end
  if dirty and self.busy then self.dirty = true end
  self.busy = false
  if message then hs.alert.show(message, 1.8) end
end

local function preflight()
  if not hs.accessibilityState(false) then
    hs.accessibilityState(true)
    hs.alert.show("Hammerspoon necesita Accessibility", 3)
    return false
  end

  if hs.eventtap.isSecureInputEnabled() then
    hs.alert.show("Secure Input bloquea la escritura automática", 3)
    return false
  end

  return true
end

function R:key(mods, key, holdUs)
  if not self.app then return end
  hs.eventtap.keyStroke(mods, key, holdUs or C.keyStrokeUs, self.app)
end

function R:focusEditor(done)
  if not preflight() then self.busy = false; return end
  if not hs.application.launchOrFocus(C.appName) then
    self.busy = false
    hs.alert.show("No pude abrir Sonic Pi", 2)
    return
  end

  local gen = self.generation
  self:schedule(C.appFocusDelay, function()
    self.app = hs.application.get(C.appName)
    if not self.app then
      self.busy = false
      hs.alert.show("No encontré el proceso de Sonic Pi", 2)
      return
    end

    self.app:activate(true)
    self:key({"ctrl", "shift"}, "e")
    self:schedule(C.editorFocusDelay, done, gen)
  end, gen)
end

function R:typeText(text, done)
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
    local delay = rand(C.charMin, C.charMax)

    if ch == "\n" then
      local previousLine = text:sub(1, i - 2):match("([^\n]*)$") or ""
      self:key({}, "return", C.returnUs)
      delay = delay + (C.returnUs / 1000000) + rand(C.newlineMin, C.newlineMax)

      if previousLine:match("%f[%a]do%s*$") or previousLine:match("^%s*end%s*$") then
        delay = delay + C.structuralExtra
      elseif previousLine:match("^%s*sample%s+") then
        delay = delay + C.sampleExtra
      end
    else
      hs.eventtap.keyStrokes(ch, self.app)
      if ch == "," or ch == ":" or ch == ")" or ch == "]" then
        delay = delay + C.punctuationExtra
      elseif ch == " " then
        delay = delay * 0.65
      end
    end

    self:schedule(delay, nextChar, gen)
  end

  nextChar()
end

function R:boundary(which, done)
  local gen = self.generation
  self:key({"cmd"}, "a")
  self:schedule(C.settleAfterNav, function()
    self:key({}, which == "start" and "left" or "right")
    self:schedule(C.settleAfterNav, done, gen)
  end, gen)
end

function R:goToLine(lineNumber, done)
  local gen = self.generation
  self:boundary("start", function()
    local remaining = lineNumber - 1
    local function step()
      if gen ~= self.generation then return end
      if remaining <= 0 then
        self:schedule(C.settleAfterNav, done, gen)
        return
      end
      self:key({}, "down")
      remaining = remaining - 1
      self:schedule(C.navDelay, step, gen)
    end
    step()
  end)
end

function R:clear(done)
  local gen = self.generation
  self:key({"cmd"}, "a")
  self:schedule(C.clearDelay, function()
    self:key({}, "delete")
    self:schedule(C.clearDelay, done, gen)
  end, gen)
end

function R:edit(action, done)
  local kind = action.type

  if kind == "set" then
    local text = stripFinalNewline(action.text)
    self:clear(function()
      self:typeText(text, function()
        self.document = text
        self:schedule(C.settleAfterEdit, done)
      end)
    end)
    return
  end

  if kind == "append" then
    local text = stripFinalNewline(action.text)
    local prefix = self.document == "" and "" or "\n"
    self:boundary("end", function()
      self:typeText(prefix .. text, function()
        self.document = self.document == "" and text or (self.document .. "\n" .. text)
        self:schedule(C.settleAfterEdit, done)
      end)
    end)
    return
  end

  if kind == "append_block" then
    local text = stripFinalNewline(action.text)
    local prefix = self.document == "" and "" or "\n\n"
    self:boundary("end", function()
      self:typeText(prefix .. text, function()
        self.document = self.document == "" and text or (self.document .. "\n\n" .. text)
        self:schedule(C.settleAfterEdit, done)
      end)
    end)
    return
  end

  if kind == "prepend" then
    local text = normalize(action.text)
    self:boundary("start", function()
      self:typeText(text, function()
        self.document = text .. self.document
        self:schedule(C.settleAfterEdit, done)
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
        self:schedule(C.settleAfterEdit, done)
      end)
    end)
    return
  end

  if kind == "insert_after" then
    local text = normalize(action.text)
    self:goToLine(line + 1, function()
      self:typeText(text, function()
        self.document = insertModel(self.document, line, text, true)
        self:schedule(C.settleAfterEdit, done)
      end)
    end)
    return
  end

  if kind == "replace_line" then
    local replacement = stripFinalNewline(action.text)
    local gen = self.generation
    self:goToLine(line, function()
      self:key({"shift"}, "down")
      self:schedule(C.settleAfterNav, function()
        self:typeText(replacement .. "\n", function()
          self.document = replaceModelLine(self.document, line, replacement)
          self:schedule(C.settleAfterEdit, done, gen)
        end)
      end, gen)
    end)
    return
  end

  self:cancel("Acción desconocida: " .. tostring(kind), true)
end

function R:tidyRun(done)
  local gen = self.generation
  self:key({"cmd"}, "m")
  self:schedule(C.tidyDelay, function()
    self:key({"cmd"}, "r")
    self:schedule(C.runDelay, done, gen)
  end, gen)
end

function R:runBeat()
  if self.busy then hs.alert.show("Editando…", 0.8); return end
  if self.needsReset then hs.alert.show("Primero usa ⌃⌥⌘R", 1.8); return end
  if self.dirty then hs.alert.show("Toma desincronizada; usa ⌃⌥⌘R", 2); return end

  local beat = BEATS[self.beat]
  if not beat then hs.alert.show("Episodio 01 completo ✓", 1.5); return end

  self.busy = true
  self.generation = self.generation + 1
  local gen = self.generation

  hs.alert.show(string.format("%02d/%02d  %s", self.beat, #BEATS, beat.name), C.alertDuration)

  self:focusEditor(function()
    if gen ~= self.generation then return end

    local waitForAlert = math.max(0, C.alertDuration - C.appFocusDelay - C.editorFocusDelay)
    local index = 1

    local function nextAction()
      if gen ~= self.generation then return end
      local action = beat.actions[index]

      if not action then
        local ok, err = validateModel(self.document)
        if not ok then self:cancel("Modelo inválido: " .. err, true); return end

        self:tidyRun(function()
          if gen ~= self.generation then return end
          self.busy = false
          self.beat = self.beat + 1
          if self.beat <= #BEATS then
            hs.alert.show("Listo. ⌃⌥⌘N → siguiente beat", 1)
          else
            hs.alert.show("Episodio 01 completo ✓", 1.5)
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

    self:schedule(waitForAlert + C.alertClearance, nextAction, gen)
  end)
end

function R:resetTake()
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
    self:schedule(C.stopRepeatDelay, function()
      self:key({"cmd"}, "s")
      self:schedule(C.stopSettleDelay, function()
        self:clear(function()
          if gen ~= self.generation then return end
          self.busy = false
          self.needsReset = false
          hs.alert.show("Runtime limpio — ⌃⌥⌘N para empezar", 1.6)
        end)
      end, gen)
    end, gen)
  end)
end

function R:info()
  local beat = BEATS[self.beat]
  if beat then
    hs.alert.show(string.format("Siguiente: %02d/%02d — %s", self.beat, #BEATS, beat.name), 2)
  else
    hs.alert.show("Episodio 01 completo ✓", 1.5)
  end
end

math.randomseed(os.time())

hs.hotkey.bind({"ctrl", "alt", "cmd"}, "n", function() R:runBeat() end)
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "r", function() R:resetTake() end)
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "i", function() R:info() end)
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "x", function()
  R:cancel("Automatización cancelada — reinicia la toma", true)
end)

hs.hotkey.bind({"ctrl", "alt", "cmd"}, "t", function()
  if R.busy then return end
  R.generation = R.generation + 1
  R.busy = true
  local gen = R.generation
  R:focusEditor(function()
    if gen ~= R.generation then return end
    hs.eventtap.keyStrokes("# Hammerspoon OK", R.app)
    R.busy = false
    R.dirty = true
    R.needsReset = true
    hs.alert.show("Prueba enviada — reinicia la toma", 1.5)
  end)
end)

if hs.accessibilityState(false) then
  hs.alert.show("Glitxtober EP01 v4.1 — newline-safe", 1.6)
else
  hs.accessibilityState(true)
  hs.alert.show("Falta permiso de Accessibility", 3)
end
