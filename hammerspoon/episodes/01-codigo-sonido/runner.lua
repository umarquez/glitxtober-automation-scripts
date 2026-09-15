-- Glitxtober 2026 — Episodio 01: Código → sonido
--
-- Canonical source: ORIGINAL.md in this directory.
-- Strategy: preserve visible, cumulative coding while keeping every structural
-- edit deterministic in Sonic Pi.
--
-- Structural-first rule:
--   write the block opener first, then its closing `end`, before inserting body
--   content. Nested body insertion uses the shared line-based editor path: the
--   caret is placed at the beginning of the existing `end` line and the body is
--   typed before it, always ending in exactly one newline.
--
-- Local-edit rule:
--   late edits locate their exact current text through Sonic Pi's Find UI.
--   We do not navigate by counting visual cursor movements for those edits.

local ROOT =
  rawget(_G, "GLITX_ROOT") or
  (os.getenv("HOME") .. "/.hammerspoon/glitxtober-automation-scripts")

local Runner = dofile(ROOT .. "/hammerspoon/lib/sonic_pi_runner.lua")

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

local SNARE_BODY = [=[
sleep 1
sample :elec_hi_snare, amp: 0.8
sleep 2
sample :elec_hi_snare, amp: 0.8
sleep 1
]=]

local BASS_BODY = [=[
use_synth :bass_foundation

play :d2, release: 0.25, amp: 0.7
sleep 1.5
play :a1, release: 0.25, amp: 0.7
sleep 0.5
play :b1, release: 0.25, amp: 0.7
sleep 1.5
play :a1, release: 0.25, amp: 0.7
sleep 0.5
]=]

local ARTICULATION_SUFFIX = ", release: 0.2, amp: 0.9"

local function normalize(text)
  return (text or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
end

local function stripOneFinalNewline(text)
  return (normalize(text):gsub("\n$", "", 1))
end

local function replaceExactLine(document, target, replacement)
  local lines = {}
  local found = false

  for line in (normalize(document) .. "\n"):gmatch("(.-)\n") do
    if not found and line == target then
      table.insert(lines, replacement)
      found = true
    else
      table.insert(lines, line)
    end
  end

  if not found then return nil end
  return table.concat(lines, "\n")
end

local function insertBeforeExactLine(document, target, text)
  return replaceExactLine(
    document,
    target,
    stripOneFinalNewline(text) .. "\n" .. target
  )
end

local function articulated(target)
  return {
    type = "replace_line",
    target = target,
    text = target .. ARTICULATION_SUFFIX,
    typed_suffix = ARTICULATION_SUFFIX,
  }
end

local function tokenChange(target, replacement, from, to)
  return {
    type = "replace_line",
    target = target,
    text = replacement,
    token_from = from,
    token_to = to,
  }
end

local function insideBlock(opener, text)
  local body = stripOneFinalNewline(text)
  return {
    type = "insert_after",
    target = opener,
    -- The shared insert_after path starts at the next line. The final newline
    -- is intentional: it leaves the already-existing `end` on its own line.
    text = body .. "\n",
  }
end

local spec = {
  episode = "01",
  title = "Código → sonido",

  config = {
    -- Slow, irregular cadence for a more human on-camera typing feel.
    charMin = 0.045,
    charMax = 0.105,
    punctuationExtra = 0.025,

    navDelay = 0.10,
    settleAfterNav = 0.18,
    keyStrokeUs = 70000,
  },

  beats = {
    { name = "01 — Una instrucción, un sonido", actions = {
      { type = "set", text = "play :d5" },
    }},

    { name = "02 — Construir el hook", actions = {
      { type = "append", text = HOOK_REST },
    }},

    { name = "03 — Fijar el tempo", actions = {
      { type = "prepend", text = "use_bpm 120\n\n" },
    }},

    -- Camera sequence: create a blank line above the first play, type the
    -- opener into that blank line, then append the closing end. Nothing runs
    -- until the complete beat is structurally closed.
    { name = "04 — Repetir sin copiar", actions = {
      {
        type = "insert_before",
        target = "play :d5",
        text = "live_loop :melody do\n",
        typed_wrap_opener = true,
      },
      { type = "append", text = "end" },
    }},

    -- Shell first, then nested shell, then nested body.
    { name = "05A — Añadir kick", actions = {
      { type = "append_block", text = "live_loop :kick, sync: :melody do\nend" },
      insideBlock("live_loop :kick, sync: :melody do", "4.times do\nend"),
      insideBlock("4.times do", "sample :bd_haus\nsleep 1"),
    }},

    { name = "05B — Añadir clap / snare", actions = {
      { type = "append_block", text = "live_loop :snare, sync: :melody do\nend" },
      insideBlock("live_loop :snare, sync: :melody do", SNARE_BODY),
    }},

    { name = "05C — Añadir hi-hat", actions = {
      { type = "append_block", text = "live_loop :hats, sync: :melody do\nend" },
      insideBlock("live_loop :hats, sync: :melody do", "8.times do\nend"),
      insideBlock("8.times do", "sample :drum_cymbal_closed, amp: 0.35\nsleep 0.5"),
    }},

    { name = "06 — Bajo: :bass_foundation", actions = {
      { type = "append_block", text = "live_loop :bass, sync: :melody do\nend" },
      insideBlock("live_loop :bass, sync: :melody do", BASS_BODY),
    }},

    { name = "07A — Lead: :fm", actions = {
      insideBlock("live_loop :melody do", "use_synth :fm\n"),
    }},

    { name = "07B — Lead: :pluck", actions = {
      tokenChange("use_synth :fm", "use_synth :pluck", ":fm", ":pluck"),
    }},

    { name = "07C — Articulación; conservar :pluck", actions = {
      articulated("play :d5"),
      articulated("play :fs5"),
      articulated("play :a5"),
      articulated("play :b5"),
      articulated("play :a5"),
      articulated("play :fs5"),
      articulated("play :e5"),
      articulated("play :fs5"),
    }},

    { name = "08A — Primera decisión generativa", actions = {
      tokenChange(
        "play :b5, release: 0.2, amp: 0.9",
        "play choose([:a5, :b5, :d6]), release: 0.2, amp: 0.9",
        ":b5",
        "choose([:a5, :b5, :d6])"
      ),
    }},

    { name = "08B — Segunda decisión generativa", actions = {
      tokenChange(
        "play :e5, release: 0.2, amp: 0.9",
        "play choose([:d5, :e5, :a5]), release: 0.2, amp: 0.9",
        ":e5",
        "choose([:d5, :e5, :a5])"
      ),
    }},

    { name = "09 — Pieza completa / mini performance", actions = {} },
  },
}

local runner = Runner.new(spec)
local baseEdit = runner.edit

local function moveRepeated(runner, mods, key, count, done)
  local gen = runner.generation
  local remaining = count

  local function step()
    if gen ~= runner.generation then return end
    if remaining <= 0 then done(); return end

    runner:key(mods, key)
    remaining = remaining - 1
    runner:schedule(runner.C.navDelay, step, gen)
  end

  step()
end

local function findEditorText(runner, text, done)
  local gen = runner.generation

  runner:key({"cmd"}, "f")
  runner:schedule(runner.C.settleAfterNav, function()
    if gen ~= runner.generation then return end

    runner:key({"cmd"}, "a")
    runner:schedule(runner.C.settleAfterNav, function()
      if gen ~= runner.generation then return end

      hs.eventtap.keyStrokes(text, runner.app)
      runner:schedule(runner.C.settleAfterEdit, function()
        if gen ~= runner.generation then return end

        runner:key({}, "return")
        runner:schedule(runner.C.settleAfterNav, function()
          if gen ~= runner.generation then return end

          runner:key({}, "escape")
          runner:schedule(runner.C.settleAfterNav, done, gen)
        end, gen)
      end, gen)
    end, gen)
  end, gen)
end

local function verifyLocalEdit(runner, done)
  local gen = runner.generation
  runner:schedule(runner.C.settleAfterEdit, function()
    if gen ~= runner.generation then return end

    runner:verifyEditorBuffer(function(ok)
      if gen ~= runner.generation then return end
      if not ok then
        runner:cancel(
          "Edición local no coincidió con el modelo; se detuvo antes del siguiente cambio. Usa ⌃⌥⌘R",
          true
        )
        return
      end
      done()
    end)
  end, gen)
end

function runner:edit(action, done)
  if action.typed_wrap_opener then
    local opener = stripOneFinalNewline(action.text)
    local nextDocument = insertBeforeExactLine(self.document, action.target, opener)
    if not nextDocument then
      self:cancel("No encontré target para envolver: " .. tostring(action.target), true)
      return
    end

    local gen = self.generation
    findEditorText(self, action.target, function()
      if gen ~= self.generation then return end

      -- Collapse at the left edge of the selected first play. First create the
      -- blank line visibly; then move up into it and type the live_loop opener.
      self:key({}, "left")
      self:schedule(self.C.settleAfterNav, function()
        self:typeText("\n", function()
          if gen ~= self.generation then return end

          self:key({}, "up")
          self:schedule(self.C.settleAfterNav, function()
            self:key({"cmd"}, "left")
            self:schedule(self.C.settleAfterNav, function()
              self:typeText(opener, function()
                if gen ~= self.generation then return end
                self.document = nextDocument
                verifyLocalEdit(self, done)
              end)
            end, gen)
          end, gen)
        end)
      end, gen)
    end)
    return
  end

  if action.typed_suffix then
    local expected = action.target .. action.typed_suffix
    if expected ~= stripOneFinalNewline(action.text) then
      self:cancel("La articulación declarada no coincide con el modelo", true)
      return
    end

    local nextDocument = replaceExactLine(self.document, action.target, expected)
    if not nextDocument then
      self:cancel("No encontré target para articulación: " .. tostring(action.target), true)
      return
    end

    local gen = self.generation
    findEditorText(self, action.target, function()
      if gen ~= self.generation then return end

      self:key({}, "right")
      self:schedule(self.C.settleAfterNav, function()
        self:typeText(action.typed_suffix, function()
          if gen ~= self.generation then return end
          self.document = nextDocument
          verifyLocalEdit(self, done)
        end)
      end, gen)
    end)
    return
  end

  if action.token_from then
    local startAt, endAt = action.target:find(action.token_from, 1, true)
    if not startAt then
      self:cancel("El token esperado no existe en la línea target", true)
      return
    end

    if action.target:find(action.token_from, endAt + 1, true) then
      self:cancel("El token aparece más de una vez en la línea target", true)
      return
    end

    local expected =
      action.target:sub(1, startAt - 1) ..
      action.token_to ..
      action.target:sub(endAt + 1)

    if expected ~= stripOneFinalNewline(action.text) then
      self:cancel("El cambio local declarado no coincide con el modelo", true)
      return
    end

    local nextDocument = replaceExactLine(self.document, action.target, expected)
    if not nextDocument then
      self:cancel("No encontré target para cambio local: " .. tostring(action.target), true)
      return
    end

    local charsAfter = #action.target - endAt
    local gen = self.generation

    findEditorText(self, action.target, function()
      if gen ~= self.generation then return end

      self:key({}, "right")
      self:schedule(self.C.settleAfterNav, function()
        moveRepeated(self, {}, "left", charsAfter, function()
          moveRepeated(self, {"shift"}, "left", #action.token_from, function()
            self:typeText(action.token_to, function()
              if gen ~= self.generation then return end
              self.document = nextDocument
              verifyLocalEdit(self, done)
            end)
          end)
        end)
      end, gen)
    end)
    return
  end

  return baseEdit(self, action, done)
end

return runner
