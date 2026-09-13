-- Glitxtober 2026 — Episodio 03: Controlando un sinte desde el código
--
-- Canonical source: ORIGINAL.md.
-- Dependency: Sonic Pi MIDI output + MicroFreak (or another MIDI synth).
-- No VS Code/external program is required for this episode.
--
-- Configure the exact MIDI port in ~/.hammerspoon/init.lua:
-- GLITX_EP03_CONFIG = { midiPort = "<port shown by Sonic Pi>" }

local ROOT =
  rawget(_G, "GLITX_ROOT") or
  (os.getenv("HOME") .. "/.hammerspoon/glitxtober-automation-scripts")

local Runner = dofile(ROOT .. "/hammerspoon/lib/sonic_pi_runner.lua")

local userConfig = rawget(_G, "GLITX_EP03_CONFIG") or {}
local midiPort = userConfig.midiPort or "<microfreak_port>"

local function rubyString(value)
  value = tostring(value):gsub("\\", "\\\\"):gsub('"', '\\"')
  return '"' .. value .. '"'
end

local PORT = rubyString(midiPort)

if midiPort == "<microfreak_port>" and _G.GlitxStatus then
  _G.GlitxStatus.log(
    "EP03 usa <microfreak_port>; configura GLITX_EP03_CONFIG.midiPort para la toma final"
  )
end

local ONE_NOTE = string.format([=[
use_bpm 120

midi_note_on :d3, 90, port: %s, channel: 1
sleep 0.4
midi_note_off :d3, port: %s, channel: 1
]=], PORT, PORT)

local NOTES_LOOP = string.format([=[
use_bpm 120

notes = (ring :d3, :f3, :a3, :c4, :a3, :g3, :f3, :a3)

live_loop :notes do
note = notes.tick
midi_note_on note, 90, port: %s, channel: 1
sleep 0.4
midi_note_off note, port: %s, channel: 1
sleep 0.1
end
]=], PORT, PORT)

local CC_TEST = string.format([=[
midi_cc 23, 30, port: %s, channel: 1
sleep 1
midi_cc 23, 110, port: %s, channel: 1
]=], PORT, PORT)

local CUTOFF_LOOP = string.format([=[
cutoffs = (ring 30, 55, 85, 110, 65)

live_loop :cutoff do
midi_cc 23, cutoffs.tick, port: %s, channel: 1
sleep 0.5
end
]=], PORT)

local NOTES_AND_CUTOFF = string.format([=[
use_bpm 120

notes = (ring :d3, :f3, :a3, :c4, :a3, :g3, :f3, :a3)
cutoffs = (ring 30, 55, 85, 110, 65)

live_loop :notes do
note = notes.tick
midi_note_on note, 90, port: %s, channel: 1
sleep 0.4
midi_note_off note, port: %s, channel: 1
sleep 0.1
end

live_loop :cutoff do
midi_cc 23, cutoffs.tick, port: %s, channel: 1
sleep 0.5
end
]=], PORT, PORT, PORT)

local ROBUST = string.format([=[
use_bpm 120

notes = [:d3, :f3, :a3, :c4, :a3, :g3, :f3, :a3]
cutoffs = [30, 55, 85, 110, 65]

live_loop :cutoff do
cutoffs.each do |value|
sync :control_step
midi_cc 23, value, port: %s, channel: 1
end
end

live_loop :notes do
notes.each do |note|
cue :control_step
midi_note_on note, 90, port: %s, channel: 1
sleep 0.4
midi_note_off note, port: %s, channel: 1
sleep 0.1
end
end
]=], PORT, PORT, PORT)

return Runner.new({
  episode = "03",
  title = "Controlando un sinte desde el código",

  beats = {
    { name = "01 — Una nota sale del código", actions = {
      { type = "set", text = ONE_NOTE },
    }},

    { name = "02 — Secuencia fija de 8 notas", actions = {
      { type = "set", text = NOTES_LOOP },
    }},

    { name = "03 — Un mensaje cambia el filtro", actions = {
      { type = "set", text = CC_TEST },
    }},

    { name = "04 — Ciclo independiente de cutoff", actions = {
      { type = "set", text = CUTOFF_LOOP },
    }},

    { name = "05 — Dos ciclos simples", actions = {
      { type = "set", text = NOTES_AND_CUTOFF },
    }},

    { name = "05B — Performance robusta / reloj compartido", actions = {
      { type = "set", text = ROBUST },
    }},
  },
})
