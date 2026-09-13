# Código original — Episodio 04

### Snapshot 1 — Reloj de 16 pasos

```ruby
use_bpm 120

live_loop :clock do
  16.times do |step|
    puts step
    sleep 0.25
  end
end
```

### Snapshot 2 — Un patrón de kick

```ruby
use_bpm 120

kick = (ring 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)

live_loop :sequencer do
  step = tick
  sample :bd_haus if kick[step] == 1
  sleep 0.25
end
```

### Snapshot 3 — Kick + snare

```ruby
use_bpm 120

kick  = (ring 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)
snare = (ring 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0)

live_loop :sequencer do
  step = tick
  sample :bd_haus if kick[step] == 1
  sample :elec_hi_snare, amp: 0.8 if snare[step] == 1
  sleep 0.25
end
```

### Snapshot 4 — Tres voces

```ruby
use_bpm 120

kick  = (ring 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)
snare = (ring 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0)
hats  = (ring 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0)

live_loop :sequencer do
  step = tick
  sample :bd_haus if kick[step] == 1
  sample :elec_hi_snare, amp: 0.8 if snare[step] == 1
  sample :drum_cymbal_closed, amp: 0.3 if hats[step] == 1
  sleep 0.25
end
```

### Snapshot 5 — Cambiar el groove sin cambiar el motor

Sustituir sólo el patrón de kick:

```ruby
kick = (ring 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0)
```

### Snapshot 6 — Estado final de performance

```ruby
use_bpm 120

kick  = (ring 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0)
snare = (ring 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0)
hats  = (ring 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0)

live_loop :sequencer do
  step = tick
  sample :bd_haus if kick[step] == 1
  sample :elec_hi_snare, amp: 0.8 if snare[step] == 1
  sample :drum_cymbal_closed, amp: 0.3 if hats[step] == 1
  sleep 0.25
end
```
