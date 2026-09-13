# Código original — Episodio 05

### Snapshot 1 — 3 pulsos en 8 pasos

```ruby
use_bpm 120
pattern = spread(3, 8)

live_loop :euclid do
  step = tick
  sample :bd_haus if pattern[step]
  sleep 0.5
end
```

### Snapshot 2 — Cambiar sólo la cantidad de pulsos

```ruby
pattern = spread(5, 8)
```

### Snapshot 3 — Rejilla de 16 pasos

```ruby
use_bpm 120
kick = spread(5, 16)

live_loop :euclid do
  step = tick
  sample :bd_haus if kick[step]
  sleep 0.25
end
```

### Snapshot 4 — Dos distribuciones

```ruby
use_bpm 120
kick = spread(5, 16)
perc = spread(3, 16)

live_loop :euclid do
  step = tick
  sample :bd_haus if kick[step]
  sample :elec_hi_snare, amp: 0.7 if perc[step]
  sleep 0.25
end
```

### Snapshot 5 — Tres voces

```ruby
use_bpm 120
kick = spread(5, 16)
perc = spread(3, 16)
hats = spread(7, 16)

live_loop :euclid do
  step = tick
  sample :bd_haus if kick[step]
  sample :elec_hi_snare, amp: 0.7 if perc[step]
  sample :drum_cymbal_closed, amp: 0.3 if hats[step]
  sleep 0.25
end
```

### Snapshot 6 — Una cifra transforma el groove

Cambiar únicamente:

```ruby
hats = spread(11, 16)
```

### Snapshot 7 — Performance A/B

**Versión A**

```ruby
kick = spread(5, 16)
perc = spread(3, 16)
hats = spread(7, 16)
```

**Versión B**

```ruby
kick = spread(7, 16)
perc = spread(5, 16)
hats = spread(11, 16)
```
