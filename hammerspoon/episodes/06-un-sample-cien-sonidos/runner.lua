local ROOT =
  rawget(_G, "GLITX_ROOT") or
  (os.getenv("HOME") .. "/.hammerspoon/glitxtober-automation-scripts")

local Runner = dofile(ROOT .. "/hammerspoon/lib/sonic_pi_runner.lua")

local SOURCE = [=[
use_bpm 110
sample :loop_amen
]=]

local LOW = [=[
use_bpm 110

live_loop :low_pulse do
sample :loop_amen, start: 0.0, finish: 0.125, rate: 0.5, amp: 1.1
sleep 1
end
]=]

local HIGH = [=[
live_loop :high_ticks do
sample :loop_amen, start: 0.5, finish: 0.5625, rate: 2.0, amp: 0.35
sleep 0.5
end
]=]

local REVERSE = [=[
live_loop :reverse_texture do
sample :loop_amen, rate: -1, amp: 0.2
sleep 8
end
]=]

return Runner.new({
  episode = "06",
  title = "Un sample, cien sonidos",

  beats = {
    { name = "01 — La fuente", actions = {
      { type = "set", text = SOURCE },
    }},

    { name = "02 — Un fragmento", actions = {
      {
        type = "replace_line",
        target = "sample :loop_amen",
        text = "sample :loop_amen, start: 0.0, finish: 0.125",
      },
    }},

    { name = "03 — Misma región, otra velocidad", actions = {
      {
        type = "replace_line",
        target = "sample :loop_amen, start: 0.0, finish: 0.125",
        text = [=[
sample :loop_amen, start: 0.0, finish: 0.125, rate: 0.5
sleep 1
sample :loop_amen, start: 0.0, finish: 0.125, rate: 2.0
]=],
      },
    }},

    { name = "04 — La misma fuente al revés", actions = {
      { type = "set", text = "use_bpm 110\nsample :loop_amen, rate: -1" },
    }},

    { name = "05 — Pulso grave desde un slice", actions = {
      { type = "set", text = LOW },
    }},

    { name = "06 — Añadir una capa aguda", actions = {
      { type = "append_block", text = HIGH },
    }},

    { name = "07 — Textura invertida", actions = {
      { type = "append_block", text = REVERSE },
    }},

    { name = "08 — Arreglo completo de una sola fuente", actions = {} },

    { name = "09 — Mutación de performance", actions = {
      {
        type = "replace_line",
        target = "sample :loop_amen, start: 0.5, finish: 0.5625, rate: 2.0, amp: 0.35",
        text = "sample :loop_amen, start: 0.5, finish: 0.5625, rate: 1.5, amp: 0.35",
      },
    }},
  },
})
