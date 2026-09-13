# Código original — Episodio 03

El placeholder `<microfreak_port>` se sustituye por el nombre exacto que Sonic Pi muestra en Preferences → IO.

### Snapshot 1 — Una nota sale del código y suena en hardware

```ruby
use_bpm 120

midi_note_on :d3, 90, port: "<microfreak_port>", channel: 1
sleep 0.4
midi_note_off :d3, port: "<microfreak_port>", channel: 1
```

### Snapshot 2 — Secuencia fija de 8 notas

```ruby
use_bpm 120

notes = (ring :d3, :f3, :a3, :c4, :a3, :g3, :f3, :a3)

live_loop :notes do
  note = notes.tick
  midi_note_on note, 90, port: "<microfreak_port>", channel: 1
  sleep 0.4
  midi_note_off note, port: "<microfreak_port>", channel: 1
  sleep 0.1
end
```

### Snapshot 3 — Un solo mensaje cambia el filtro

```ruby
midi_cc 23, 30, port: "<microfreak_port>", channel: 1
sleep 1
midi_cc 23, 110, port: "<microfreak_port>", channel: 1
```

### Snapshot 4 — Ciclo independiente de cutoff

```ruby
cutoffs = (ring 30, 55, 85, 110, 65)

live_loop :cutoff do
  midi_cc 23, cutoffs.tick, port: "<microfreak_port>", channel: 1
  sleep 0.5
end
```

### Snapshot 5 — Dos ciclos simples, una relación cambiante

Ejecutar juntos `live_loop :notes` del snapshot 2 y `live_loop :cutoff` del snapshot 4. Las longitudes 8 y 5 hacen que la pareja nota–cutoff tarde 40 pasos en repetirse.

### Snapshot 5B — Versión robusta para grabación

```ruby
use_bpm 120

notes = [:d3, :f3, :a3, :c4, :a3, :g3, :f3, :a3]
cutoffs = [30, 55, 85, 110, 65]

live_loop :cutoff do
  cutoffs.each do |value|
    sync :control_step
    midi_cc 23, value, port: "<microfreak_port>", channel: 1
  end
end

live_loop :notes do
  notes.each do |note|
    cue :control_step
    midi_note_on note, 90, port: "<microfreak_port>", channel: 1
    sleep 0.4
    midi_note_off note, port: "<microfreak_port>", channel: 1
    sleep 0.1
  end
end
```
