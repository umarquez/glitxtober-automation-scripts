-- Glitxtober 2026 — Episodio 02: La máquina decide el ritmo
--
-- Canonical source: ORIGINAL.md.
-- Strategy: keep one 16-step live_loop and add probability rules inside the
-- same clock. The audible pattern remains emergent; only the probability model
-- is written explicitly.

local ROOT =
  rawget(_G, "GLITX_ROOT") or
  (os.getenv("HOME") .. "/.hammerspoon/glitxtober-automation-scripts")

local Runner = dofile(ROOT .. "/hammerspoon/lib/sonic_pi_runner.lua")

local KICK = [=[
use_bpm 120

live_loop :machine_beat do
16.times do |step|
if step == 0
sample :bd_haus
elsif step % 4 == 0
sample :bd_haus if rand < 0.70
elsif step % 2 == 0
sample :bd_haus if rand < 0.15
else
sample :bd_haus if rand < 0.05
end

sleep 0.25
end
end
]=]

return Runner.new({
  episode = "02",
  title = "La máquina decide el ritmo",

  beats = {
    { name = "01 — La máquina decide el kick", actions = {
      { type = "set", text = KICK },
    }},

    { name = "02 — Añadir backbeat probabilístico", actions = {
      {
        type = "insert_before",
        target = "sleep 0.25",
        text = [=[
snare_probability = 0.10
snare_probability = 0.85 if step == 4 or step == 12
sample :elec_hi_snare, amp: 0.8 if rand < snare_probability

]=],
      },
    }},

    { name = "03 — Añadir hi-hat como densidad", actions = {
      {
        type = "insert_before",
        target = "sleep 0.25",
        text = [=[
hat_probability = 0.35
hat_probability = 0.70 if step % 2 == 0
sample :drum_cymbal_closed, amp: 0.35 if rand < hat_probability

]=],
      },
    }},

    { name = "04 — Tres voces, un mismo sistema", actions = {} },

    { name = "05 — Aumentar densidad del hi-hat", actions = {
      {
        type = "replace_line",
        target = "hat_probability = 0.35",
        text = "hat_probability = 0.80",
      },
    }},
  },
})
