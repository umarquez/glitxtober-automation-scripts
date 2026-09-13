-- Glitxtober 2026 — Episodio 04: Construye tu propio secuenciador
--
-- Canonical source: ORIGINAL.md.
-- Strategy: establish a 16-step clock, move the pattern into data, then add
-- voices while keeping the playback engine unchanged.

local ROOT =
  rawget(_G, "GLITX_ROOT") or
  (os.getenv("HOME") .. "/.hammerspoon/glitxtober-automation-scripts")

local Runner = dofile(ROOT .. "/hammerspoon/lib/sonic_pi_runner.lua")

local CLOCK = [=[
use_bpm 120

live_loop :clock do
16.times do |step|
puts step
sleep 0.25
end
end
]=]

local KICK_SEQUENCER = [=[
use_bpm 120

kick = (ring 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)

live_loop :sequencer do
step = tick
sample :bd_haus if kick[step] == 1
sleep 0.25
end
]=]

return Runner.new({
  episode = "04",
  title = "Construye tu propio secuenciador",

  beats = {
    { name = "01 — Reloj de 16 pasos", actions = {
      { type = "set", text = CLOCK },
    }},

    { name = "02 — Un patrón de kick", actions = {
      { type = "set", text = KICK_SEQUENCER },
    }},

    { name = "03 — Kick + snare", actions = {
      {
        type = "insert_after",
        target = "kick = (ring 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)",
        text = "snare = (ring 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0)\n",
      },
      {
        type = "insert_before",
        target = "sleep 0.25",
        text = "sample :elec_hi_snare, amp: 0.8 if snare[step] == 1\n",
      },
    }},

    { name = "04 — Tres voces", actions = {
      {
        type = "insert_after",
        target = "snare = (ring 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0)",
        text = "hats = (ring 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0)\n",
      },
      {
        type = "insert_before",
        target = "sleep 0.25",
        text = "sample :drum_cymbal_closed, amp: 0.3 if hats[step] == 1\n",
      },
    }},

    { name = "05 — Cambiar groove sin cambiar motor", actions = {
      {
        type = "replace_line",
        target = "kick = (ring 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)",
        text = "kick = (ring 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0)",
      },
    }},

    { name = "06 — Estado final de performance", actions = {
      {
        type = "replace_line",
        target = "snare = (ring 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0)",
        text = "snare = (ring 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0)",
      },
      {
        type = "replace_line",
        target = "hats = (ring 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0)",
        text = "hats = (ring 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0)",
      },
    }},
  },
})
