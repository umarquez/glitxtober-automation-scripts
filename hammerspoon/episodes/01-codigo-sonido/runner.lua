-- Glitxtober 2026 — Episodio 01: Código → sonido
--
-- Canonical source: ORIGINAL.md in this directory.
-- Strategy: preserve the cumulative visual construction of the pilot. The
-- runner starts from one note and progressively adds timing, live_loops,
-- drums, bass, timbre and two constrained generative decisions.

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

return Runner.new({
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
      {
        type = "replace_line",
        target = "play :b5, release: 0.2, amp: 0.9",
        text = "play choose([:a5, :b5, :d6]), release: 0.2, amp: 0.9",
      },
    }},

    { name = "08B — Segunda decisión generativa", actions = {
      {
        type = "replace_line",
        target = "play :e5, release: 0.2, amp: 0.9",
        text = "play choose([:d5, :e5, :a5]), release: 0.2, amp: 0.9",
      },
    }},

    { name = "09 — Pieza completa / mini performance", actions = {} },
  },
})
