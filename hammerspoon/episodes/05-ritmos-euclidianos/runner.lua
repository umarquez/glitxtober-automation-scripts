local ROOT =
  rawget(_G, "GLITX_ROOT") or
  (os.getenv("HOME") .. "/.hammerspoon/glitxtober-automation-scripts")

local Runner = dofile(ROOT .. "/hammerspoon/lib/sonic_pi_runner.lua")

local START = [=[
use_bpm 120
pattern = spread(3, 8)

live_loop :euclid do
step = tick
sample :bd_haus if pattern[step]
sleep 0.5
end
]=]

return Runner.new({
  episode = "05",
  title = "Ritmos euclidianos",

  beats = {
    { name = "01 — 3 pulsos en 8 pasos", actions = {
      { type = "set", text = START },
    }},

    { name = "02 — 5 pulsos en 8 pasos", actions = {
      { type = "replace_line", target = "pattern = spread(3, 8)", text = "pattern = spread(5, 8)" },
    }},

    { name = "03 — Rejilla de 16 pasos", actions = {
      { type = "replace_line", target = "pattern = spread(5, 8)", text = "kick = spread(5, 16)" },
      { type = "replace_line", target = "sample :bd_haus if pattern[step]", text = "sample :bd_haus if kick[step]" },
      { type = "replace_line", target = "sleep 0.5", text = "sleep 0.25" },
    }},

    { name = "04 — Dos distribuciones", actions = {
      { type = "insert_after", target = "kick = spread(5, 16)", text = "perc = spread(3, 16)\n" },
      {
        type = "insert_before",
        target = "sleep 0.25",
        text = "sample :elec_hi_snare, amp: 0.7 if perc[step]\n",
      },
    }},

    { name = "05 — Tres voces", actions = {
      { type = "insert_after", target = "perc = spread(3, 16)", text = "hats = spread(7, 16)\n" },
      {
        type = "insert_before",
        target = "sleep 0.25",
        text = "sample :drum_cymbal_closed, amp: 0.3 if hats[step]\n",
      },
    }},

    { name = "06 — Una cifra transforma el groove", actions = {
      { type = "replace_line", target = "hats = spread(7, 16)", text = "hats = spread(11, 16)" },
    }},

    { name = "07 — Performance A/B", actions = {
      { type = "replace_line", target = "kick = spread(5, 16)", text = "kick = spread(7, 16)" },
      { type = "replace_line", target = "perc = spread(3, 16)", text = "perc = spread(5, 16)" },
    }},
  },
})
