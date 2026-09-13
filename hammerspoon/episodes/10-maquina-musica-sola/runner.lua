local ROOT =
  rawget(_G, "GLITX_ROOT") or
  (os.getenv("HOME") .. "/.hammerspoon/glitxtober-automation-scripts")

local Runner = dofile(ROOT .. "/hammerspoon/lib/sonic_pi_runner.lua")

local DRUMS = [=[
live_loop :drums do
state = get(:state) || :intro

case state
when :intro
sample :bd_haus, amp: 0.7
sleep 1
when :groove
sample :bd_haus
sleep 0.5
when :variation
sample :bd_haus
sample :drum_cymbal_closed, amp: 0.25 if one_in(2)
sleep 0.5
when :breakdown
sample :elec_tick, amp: 0.25
sleep 1
end
end
]=]

local NEXT_STATE = [=[
define :next_state do |current|
case current
when :intro
:groove
when :groove
[:variation, :breakdown].choose
when :variation
[:groove, :breakdown].choose
when :breakdown
:groove
else
:groove
end
end

]=]

local AUTONOMOUS = NEXT_STATE .. [=[
use_bpm 116
use_random_seed 2026
set :state, :intro

]=] .. DRUMS .. [=[

live_loop :director do
sleep 32
current = get(:state) || :intro
set :state, next_state(current)
puts "STATE: #{get(:state)}"
end
]=]

local BASS = [=[
bass_notes = (ring :d2, :d2, :f2, :a1)

live_loop :bass do
sync :drums
state = get(:state) || :intro

if [:groove, :variation].include?(state)
use_synth :fm
note = bass_notes.tick(:bass)
note += 12 if state == :variation and one_in(4)
play note, release: 0.2, amp: 0.65
end

sleep 0.5
end
]=]

local MOTIF = [=[
motif = (ring :d4, :f4, :a4, :c5)

live_loop :motif do
state = get(:state) || :intro

if state == :intro
play motif.tick(:motif), release: 0.6, amp: 0.25
sleep 1
elsif state == :variation
play motif.tick(:motif), release: 0.15, cutoff: rrand(70, 105), amp: 0.4
sleep 0.25
else
sleep 0.5
end
end
]=]

return Runner.new({
  episode = "10",
  title = "Una máquina que hace música sola",

  beats = {
    { name = "01 — Un estado global", actions = {
      { type = "set", text = "set :state, :intro\nputs get(:state)" },
    }},

    { name = "02 — Una capa escucha el estado", actions = {
      { type = "prepend", text = "use_bpm 116\n\n" },
      { type = "append_block", text = DRUMS },
    }},

    { name = "03 — Director determinista", actions = {
      {
        type = "append_block",
        text = [=[
states = (ring :intro, :groove, :variation, :groove, :breakdown, :groove)

live_loop :director do
set :state, states.tick(:form)
puts "STATE: #{get(:state)}"
sleep 32
end
]=],
      },
    }},

    { name = "04 — Tabla de transiciones", actions = {
      { type = "prepend", text = NEXT_STATE },
    }},

    { name = "05 — Director autónomo reproducible", actions = {
      { type = "set", text = AUTONOMOUS },
    }},

    { name = "06 — Bajo condicionado por estado", actions = {
      { type = "append_block", text = BASS },
    }},

    { name = "07 — Motivo con memoria de estado", actions = {
      { type = "append_block", text = MOTIF },
    }},

    { name = "08 — Performance final", actions = {} },
  },
})
