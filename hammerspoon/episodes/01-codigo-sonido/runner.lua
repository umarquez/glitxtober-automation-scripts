-- Glitxtober 2026 — Episodio 01: Código → sonido
--
-- Canonical source: ORIGINAL.md in this directory.
-- Strategy: preserve the cumulative visual construction of the pilot. The
-- runner starts from one note and progressively adds timing, live_loops,
-- drums, bass, timbre and two constrained generative decisions.
--
-- Reliability note:
-- Steps 11-13 use atomic editor updates. Those steps previously depended on
-- repeated line selections in Sonic Pi and could damage adjacent lines. Their
-- target state is now computed first and pasted as one verified buffer update.

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
use_synth :bass_foundation

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

local MELODY_ARTICULATED = [=[live_loop :melody do
use_synth :pluck

play :d5, release: 0.2, amp: 0.9
sleep 0.5
play :fs5, release: 0.2, amp: 0.9
sleep 0.25
play :a5, release: 0.2, amp: 0.9
sleep 0.25
play :b5, release: 0.2, amp: 0.9
sleep 0.5
play :a5, release: 0.2, amp: 0.9
sleep 0.5
play :fs5, release: 0.2, amp: 0.9
sleep 0.25
play :e5, release: 0.2, amp: 0.9
sleep 0.25
play :fs5, release: 0.2, amp: 0.9
sleep 1.5
end]=]

local function trimBlock(text)
  return text:gsub("^\n", ""):gsub("\n$", "")
end

local STEP11_DOCUMENT = table.concat({
  "use_bpm 120",
  "",
  MELODY_ARTICULATED,
  "",
  trimBlock(KICK),
  "",
  trimBlock(SNARE),
  "",
  trimBlock(HATS),
  "",
  trimBlock(BASS),
}, "\n")

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

local spec = {
  episode = "01",
  title = "Código → sonido",

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

    { name = "06 — Bajo: :bass_foundation", actions = {
      { type = "append_block", text = BASS },
    }},

    { name = "07A — Lead: :fm", actions = {
      { type = "insert_after", target = "live_loop :melody do", text = "use_synth :fm\n\n" },
    }},

    { name = "07B — Lead: :pluck", actions = {
      { type = "replace_line", target = "use_synth :fm", text = "use_synth :pluck" },
    }},

    { name = "07C — Articulación; conservar :pluck", actions = {
      { type = "set", text = STEP11_DOCUMENT, atomic = true },
    }},

    { name = "08A — Primera decisión generativa", actions = {
      {
        type = "replace_line",
        target = "play :b5, release: 0.2, amp: 0.9",
        text = "play choose([:a5, :b5, :d6]), release: 0.2, amp: 0.9",
        atomic = true,
      },
    }},

    { name = "08B — Segunda decisión generativa", actions = {
      {
        type = "replace_line",
        target = "play :e5, release: 0.2, amp: 0.9",
        text = "play choose([:d5, :e5, :a5]), release: 0.2, amp: 0.9",
        atomic = true,
      },
    }},

    { name = "09 — Pieza completa / mini performance", actions = {} },
  },
}

local runner = Runner.new(spec)
local baseEdit = runner.edit

-- EP01-specific reliability override for the historically fragile articulation
-- and choose edits. The model is updated first, then the entire editor buffer is
-- replaced in one paste operation. No Shift+Down selection is involved.
function runner:edit(action, done)
  if not action.atomic then
    return baseEdit(self, action, done)
  end

  local nextDocument

  if action.type == "set" then
    nextDocument = stripOneFinalNewline(action.text)
  elseif action.type == "replace_line" then
    nextDocument = replaceExactLine(
      self.document,
      action.target,
      stripOneFinalNewline(action.text)
    )

    if not nextDocument then
      self:cancel("No encontré target atómico: " .. tostring(action.target), true)
      return
    end
  else
    self:cancel("Acción atómica no soportada: " .. tostring(action.type), true)
    return
  end

  self.document = nextDocument
  self:repairEditorBuffer(function(ok)
    if not ok then
      self:cancel("No pude aplicar la edición atómica; usa ⌃⌥⌘R", true)
      return
    end

    self:schedule(self.C.settleAfterEdit, done)
  end)
end

return runner
