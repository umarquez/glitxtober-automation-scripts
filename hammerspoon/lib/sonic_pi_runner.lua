-- Shared Hammerspoon runner for Glitxtober Sonic Pi episodes.
--
-- Reliability invariant:
--   Sonic Pi is never allowed to Run a buffer that differs structurally from
--   the runner's internal model. Newlines are inserted with clipboard paste
--   rather than Return key events, and the full editor buffer is copied back
--   and verified before every Run. A mismatch triggers one atomic full-buffer
--   repair + re-verification; if that still fails, the take is cancelled.

local Runner = {}
Runner.__index = Runner

local DEFAULTS = {
  appName = "Sonic Pi",

  -- Human-readable typing cadence.
  charMin = 0.018,
  charMax = 0.048,
  punctuationExtra = 0.014,

  -- Keyboard/clipboard timings.
  keyStrokeUs = 50000,
  newlinePasteDelay = 0.14,
  clipboardSettleDelay = 0.10,
  verifyCopyDelay = 0.16,
  repairPasteDelay = 0.30,

  -- Focus/navigation/run timings.
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

local SUPPORTED_ACTIONS = {
  set = true,
  append = true,
  append_block = true,
  prepend = true,
  insert_before = true,
  insert_after = true,
  replace_line = true,
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

  -- Console-only fallback: never contaminate the recording unexpectedly.
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

-- Long bracket literals normally carry one formatting newline before ]=].
-- Remove exactly one final newline, preserving intentional blank lines.
local function stripOneFinalNewline(text)
  text = normalize(text)
  return (text:gsub("\n$", "", 1))
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
  local inserted = linesOf(stripOneFinalNewline(text))
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

-- Compare editor text with the internal model while ignoring indentation added
-- by Sonic Pi/Tidy. Line boundaries are deliberately preserved, so a dropped
-- newline such as `sample :bd_haussleep 1` can never compare equal to the
-- intended two-line model.
local function canonicalBuffer(text)
  local lines = linesOf(normalize(text))

  for i, line in ipairs(lines) do
    line = line:gsub("^[ \t]+", "")
    line = line:gsub("[ \t]+$", "")
    lines[i] = line
  end

  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end

  return join(lines)
end

Runner.canonicalBuffer = canonicalBuffer
Runner.buffersMatch = function(actual, expected)
  return canonicalBuffer(actual) == canonicalBuffer(expected)
end

local function validateModel(document)
  local lines = linesOf(document)

  for i, line in ipairs(lines) do
    local trimmed = line:gsub("^%s+", "")

    -- Regression guard for the original dropped-newline failure.
    if trimmed:match("^sample%s+") and trimmed:find("sleep", 1, true) then
      return false, "sample y sleep están en la misma línea"
    end

    if trimmed:match("^live_loop%s+") and i > 1 and lines[i - 1] ~= "" then
      return false, "falta línea en blanco antes de " .. trimmed
    end

    if line:find("endlive_loop", 1, true) then
      return false, "dos bloques quedaron fusionados: endlive_loop"
    end
  end

  return true
end

local function validateAction(action)
  if type(action) ~= "table" then
    return false, "la acción no es una tabla"
  end

  if not SUPPORTED_ACTIONS[action.type] then
    return false, "tipo de acción desconocido: " .. tostring(action.type)
  end

  if type(action.text) ~= "string" then
    return false, "la acción " .. tostring(action.type) .. " requiere text"
  end

  if action.type == "replace_line" and normalize(action.text):find("\n", 1, true) then
    return false, "replace_line sólo admite una línea; divide el cambio en acciones explícitas"
  end

  if action.type == "insert_before" or
     action.type == "insert_after" or
     action.type == "replace_line" then
    if type(action.target) ~= "string" or action.target == "" then
      return false, "la acción " .. action.type .. " requiere target"
    end
  end

  return true
end

local function applyModelAction(document, action)
  local ok, err = validateAction(action)
  if not ok then return nil, err end

  local kind = action.type
  local text = stripOneFinalNewline(action.text)

  if kind == "set" then
    return text
  end

  if kind == "append" then
    if document == "" then return text end
    return document .. "\n" .. text
  end

  if kind == "append_block" then
    if document == "" then return text end
    return document .. "\n\n" .. text
  end

  if kind == "prepend" then
    return normalize(action.text) .. document
  end

  local line = findLine(document, action.target)
  if not line then
    return nil, "no se encontró target: " .. tostring(action.target)
  end

  if kind == "insert_before" then
    return insertModel(document, line, action.text, false)
  end

  if kind == "insert_after" then
    return insertModel(document, line, action.text, true)
  end

  if kind == "replace_line" then
    return replaceModelLine(document, line, text)
  end

  return nil, "acción no implementada: " .. tostring(kind)
end

-- Pure/static review. No Hammerspoon API is needed here.
function Runner.reviewSpec(spec)
  if type(spec) ~= "table" then
    return nil, "la especificación no es una tabla"
  end

  if type(spec.beats) ~= "table" or #spec.beats == 0 then
    return nil, "la especificación requiere al menos un beat"
  end

  local document = ""
  local snapshots = {}
  local seenNames = {}

  for beatIndex, beat in ipairs(spec.beats) do
    if type(beat) ~= "table" or type(beat.name) ~= "string" or beat.name == "" then
      return nil, string.format("beat %d sin nombre válido", beatIndex)
    end

    if seenNames[beat.name] then
      return nil, "nombre de beat duplicado: " .. beat.name
    end
    seenNames[beat.name] = true

    local actions = beat.actions or {}
    if type(actions) ~= "table" then
      return nil, string.format("beat %d: actions debe ser una tabla", beatIndex)
    end

    for actionIndex, action in ipairs(actions) do
      local nextDocument, actionErr = applyModelAction(document, action)
      if not nextDocument then
        return nil, string.format(
          "beat %d (%s), acción %d: %s",
          beatIndex,
          beat.name,
          actionIndex,
          actionErr
        )
      end
      document = nextDocument
    end

    local modelOk, modelErr = validateModel(document)
    if not modelOk then
      return nil, string.format("beat %d (%s): %s", beatIndex, beat.name, modelErr)
    end

    snapshots[beatIndex] = document
  end

  return {
    snapshots = snapshots,
    finalDocument = document,
  }
end

function Runner.new(spec)
  local review, reviewErr = Runner.reviewSpec(spec)
  assert(review, string.format(
    "EP%s — especificación inválida: %s",
    tostring(spec and spec.episode or "XX"),
    tostring(reviewErr)
  ))

  if _G.GLITX_ACTIVE_RUNNER and _G.GLITX_ACTIVE_RUNNER.destroy then
    _G.GLITX_ACTIVE_RUNNER:destroy()
  end

  local self = setmetatable({
    episode = spec.episode or "XX",
    title = spec.title or "Sonic Pi",
    beats = spec.beats,
    C = merge(DEFAULTS, spec.config),
    review = review,

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
  if dirty then self.dirty = true end
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

  if not hs.pasteboard then
    status("hs.pasteboard no está disponible; no ejecutaré sin verificación", 3)
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

local function captureClipboard()
  return {
    hasText = hs.pasteboard.getContents() ~= nil,
    text = hs.pasteboard.getContents(),
  }
end

local function restoreClipboard(snapshot)
  if snapshot and snapshot.hasText then
    hs.pasteboard.setContents(snapshot.text or "")
  else
    hs.pasteboard.clearContents()
  end
end

function Runner:typeText(text, done)
  text = normalize(text)
  local gen, i, n = self.generation, 1, #text
  local clipboard = captureClipboard()

  local function finish()
    restoreClipboard(clipboard)
    done()
  end

  local function fail(message)
    restoreClipboard(clipboard)
    self:cancel(message, true)
  end

  local function nextChar()
    if gen ~= self.generation then
      restoreClipboard(clipboard)
      return
    end

    if i > n then
      finish()
      return
    end

    if hs.eventtap.isSecureInputEnabled() then
      fail("Secure Input activado")
      return
    end

    local ch = text:sub(i, i)
    i = i + 1
    local delay = rand(self.C.charMin, self.C.charMax)

    if ch == "\n" then
      -- Do not synthesize Return. A clipboard newline is an atomic text insert
      -- and cannot become the literal concatenation `...sample...sleep...`.
      local ok = hs.pasteboard.setContents("\n")
      if ok == false then
        fail("No pude preparar el salto de línea en el portapapeles")
        return
      end

      self:key({"cmd"}, "v")
      delay = delay + self.C.newlinePasteDelay
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
    local text = stripOneFinalNewline(action.text)
    self:clear(function()
      self:typeText(text, function()
        self.document = text
        self:schedule(self.C.settleAfterEdit, done)
      end)
    end)
    return
  end

  if kind == "append" then
    local text = stripOneFinalNewline(action.text)
    local prefix = self.document == "" and "" or "\n"
    self:boundary("end", function()
      self:typeText(prefix .. text, function()
        self.document = self.document == "" and text or (self.document .. "\n" .. text)
        self:schedule(self.C.settleAfterEdit, done)
      end)
    end)
    return
  end

  if kind == "append_block" then
    local text = stripOneFinalNewline(action.text)
    local prefix = self.document == "" and "" or "\n\n"
    self:boundary("end", function()
      self:typeText(prefix .. text, function()
        self.document = self.document == "" and text or (self.document .. "\n\n" .. text)
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
    local replacement = stripOneFinalNewline(action.text)
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

-- Copy the real Sonic Pi editor buffer back to Hammerspoon. The user's text
-- clipboard is restored immediately afterwards.
function Runner:readEditorBuffer(done)
  local gen = self.generation
  local clipboard = captureClipboard()

  self:key({"cmd"}, "a")
  self:schedule(self.C.settleAfterNav, function()
    self:key({"cmd"}, "c")
    self:schedule(self.C.verifyCopyDelay, function()
      local actual = hs.pasteboard.getContents()
      restoreClipboard(clipboard)

      if gen ~= self.generation then return end
      done(actual or "")
    end, gen)
  end, gen)
end

function Runner:verifyEditorBuffer(done)
  self:readEditorBuffer(function(actual)
    if Runner.buffersMatch(actual, self.document) then
      done(true, actual)
    else
      done(false, actual)
    end
  end)
end

-- Atomic recovery path. This is intentionally not the normal recording path;
-- it only runs if verification detects that simulated typing/navigation and the
-- editor diverged. The model is pasted as one block, eliminating any possibility
-- of a dropped individual newline during repair.
function Runner:repairEditorBuffer(done)
  local gen = self.generation
  local clipboard = captureClipboard()

  self:key({"cmd"}, "a")
  self:schedule(self.C.settleAfterNav, function()
    local ok = hs.pasteboard.setContents(self.document)
    if ok == false then
      restoreClipboard(clipboard)
      done(false)
      return
    end

    self:key({"cmd"}, "v")
    self:schedule(self.C.repairPasteDelay, function()
      restoreClipboard(clipboard)
      if gen ~= self.generation then return end
      done(true)
    end, gen)
  end, gen)
end

function Runner:verifiedTidyRun(done)
  local gen = self.generation

  local function runOnlyAfterVerified()
    self:verifyEditorBuffer(function(ok)
      if gen ~= self.generation then return end

      if not ok then
        self:cancel(
          "SEGURIDAD: el buffer aún difiere del modelo después de reparar; NO se ejecutó. Usa ⌃⌥⌘R",
          true
        )
        return
      end

      self:key({"cmd"}, "r")
      self:schedule(self.C.runDelay, done, gen)
    end)
  end

  local function tidyThenVerify(allowRepair)
    self:key({"cmd"}, "m")
    self:schedule(self.C.tidyDelay, function()
      self:verifyEditorBuffer(function(ok)
        if gen ~= self.generation then return end

        if ok then
          self:key({"cmd"}, "r")
          self:schedule(self.C.runDelay, done, gen)
          return
        end

        if not allowRepair then
          self:cancel(
            "SEGURIDAD: buffer inconsistente; NO se ejecutó. Usa ⌃⌥⌘R",
            true
          )
          return
        end

        status("Buffer inconsistente detectado — reparación automática antes de Run", 1.6)
        self:repairEditorBuffer(function(repaired)
          if gen ~= self.generation then return end
          if not repaired then
            self:cancel("No pude reparar el buffer; NO se ejecutó. Usa ⌃⌥⌘R", true)
            return
          end

          -- Tidy the repaired canonical model and verify once more. There is no
          -- code path from here to Run without a successful second copy-back.
          self:key({"cmd"}, "m")
          self:schedule(self.C.tidyDelay, runOnlyAfterVerified, gen)
        end)
      end)
    end, gen)
  end

  tidyThenVerify(true)
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

  status(string.format("%02d/%02d  %s", self.beat, #self.beats, beat.name), self.C.statusDuration)

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

        -- Critical safety barrier: never Run without reading the actual editor
        -- contents back and proving that line structure matches the model.
        self:verifiedTidyRun(function()
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
    status(string.format("Siguiente: %02d/%02d — %s", self.beat, #self.beats, beat.name), 2)
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

  table.insert(self.hotkeys, hs.hotkey.bind(mods, "n", function() self:runBeat() end))
  table.insert(self.hotkeys, hs.hotkey.bind(mods, "r", function() self:resetTake() end))
  table.insert(self.hotkeys, hs.hotkey.bind(mods, "i", function() self:info() end))
  table.insert(self.hotkeys, hs.hotkey.bind(mods, "x", function()
    self:cancel("Automatización cancelada — reinicia la toma", true)
  end))
  table.insert(self.hotkeys, hs.hotkey.bind(mods, "t", function() self:testTyping() end))
end

function Runner:destroy()
  self:cancel(nil, false)

  for _, hotkey in ipairs(self.hotkeys or {}) do
    hotkey:delete()
  end

  self.hotkeys = {}
end

return Runner
