# Código original — Episodio 01

Fuente canónica de las fases/snapshots del episodio. El runner puede subdividir una fase para cámara, pero no cambia la intención musical documentada aquí.

### Snapshot 1 — Una instrucción, un sonido

```ruby
play :d5
```

### Snapshot 2 — Construir el hook

```ruby
play :d5
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
```

### Snapshot 3 — Fijar el tempo

```ruby
use_bpm 120

play :d5
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
```

### Snapshot 4 — Repetir sin copiar

```ruby
use_bpm 120

live_loop :melody do
  play :d5
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
end
```

### Snapshot 5A — Añadir kick

Añadir al estado anterior:

```ruby
live_loop :kick, sync: :melody do
  4.times do
    sample :bd_haus
    sleep 1
  end
end
```

### Snapshot 5B — Añadir clap / snare

```ruby
live_loop :snare, sync: :melody do
  sleep 1
  sample :elec_hi_snare, amp: 0.8
  sleep 2
  sample :elec_hi_snare, amp: 0.8
  sleep 1
end
```

### Snapshot 5C — Añadir hi-hat

```ruby
live_loop :hats, sync: :melody do
  8.times do
    sample :drum_cymbal_closed, amp: 0.35
    sleep 0.5
  end
end
```

### Snapshot 6 — Bajo sincopado

```ruby
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
```

### Snapshot 7 — Elegir el timbre del lead

Probar `:beep`, `:prophet` y `:pluck`; el estado final usa `:pluck`.

```ruby
live_loop :melody do
  use_synth :pluck

  play :d5, release: 0.2, amp: 0.9
  sleep 0.5
  play :fs5, release: 0.2, amp: 0.9
  sleep 0.25
  play :a5, release: 0.2, amp: 0.9
  sleep 0.25
  play :b5, release: 0.2, amp: 0.9
  sleep 0.5
  play :a5, release: 0.2, amp: 0.9
  sleep 0.5
  play :fs5, release: 0.2, amp: 0.9
  sleep 0.25
  play :e5, release: 0.2, amp: 0.9
  sleep 0.25
  play :fs5, release: 0.2, amp: 0.9
  sleep 1.5
end
```

### Snapshot 8 — Dos decisiones generativas

```ruby
live_loop :melody do
  use_synth :pluck

  play :d5, release: 0.2, amp: 0.9
  sleep 0.5
  play :fs5, release: 0.2, amp: 0.9
  sleep 0.25
  play :a5, release: 0.2, amp: 0.9
  sleep 0.25
  play choose([:a5, :b5, :d6]), release: 0.2, amp: 0.9
  sleep 0.5
  play :a5, release: 0.2, amp: 0.9
  sleep 0.5
  play :fs5, release: 0.2, amp: 0.9
  sleep 0.25
  play choose([:d5, :e5, :a5]), release: 0.2, amp: 0.9
  sleep 0.25
  play :fs5, release: 0.2, amp: 0.9
  sleep 1.5
end
```

### Snapshot 9 — Pieza completa

```ruby
use_bpm 120

live_loop :melody do
  use_synth :pluck

  play :d5, release: 0.2, amp: 0.9
  sleep 0.5
  play :fs5, release: 0.2, amp: 0.9
  sleep 0.25
  play :a5, release: 0.2, amp: 0.9
  sleep 0.25
  play choose([:a5, :b5, :d6]), release: 0.2, amp: 0.9
  sleep 0.5
  play :a5, release: 0.2, amp: 0.9
  sleep 0.5
  play :fs5, release: 0.2, amp: 0.9
  sleep 0.25
  play choose([:d5, :e5, :a5]), release: 0.2, amp: 0.9
  sleep 0.25
  play :fs5, release: 0.2, amp: 0.9
  sleep 1.5
end

live_loop :kick, sync: :melody do
  4.times do
    sample :bd_haus
    sleep 1
  end
end

live_loop :snare, sync: :melody do
  sleep 1
  sample :elec_hi_snare, amp: 0.8
  sleep 2
  sample :elec_hi_snare, amp: 0.8
  sleep 1
end

live_loop :hats, sync: :melody do
  8.times do
    sample :drum_cymbal_closed, amp: 0.35
    sleep 0.5
  end
end

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
```
