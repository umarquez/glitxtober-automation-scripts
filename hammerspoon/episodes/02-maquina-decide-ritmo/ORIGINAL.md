# Código original — Episodio 02

### Snapshot 1 — La máquina decide el kick

```ruby
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
```

### Snapshot 2 — Añadir backbeat probabilístico

Añadir dentro del mismo recorrido:

```ruby
snare_probability = 0.10
snare_probability = 0.85 if step == 4 or step == 12

sample :elec_hi_snare, amp: 0.8 if rand < snare_probability
```

### Snapshot 3 — Añadir hi-hat como densidad

```ruby
hat_probability = 0.35
hat_probability = 0.70 if step % 2 == 0

sample :drum_cymbal_closed, amp: 0.35 if rand < hat_probability
```

### Snapshot 4 — Tres voces, un mismo sistema

```ruby
use_bpm 120

live_loop :machine_beat do
  16.times do |step|
    # Kick
    if step == 0
      sample :bd_haus
    elsif step % 4 == 0
      sample :bd_haus if rand < 0.70
    elsif step % 2 == 0
      sample :bd_haus if rand < 0.15
    else
      sample :bd_haus if rand < 0.05
    end

    # Snare / clap
    snare_probability = 0.10
    snare_probability = 0.85 if step == 4 or step == 12
    sample :elec_hi_snare, amp: 0.8 if rand < snare_probability

    # Hi-hat
    hat_probability = 0.35
    hat_probability = 0.70 if step % 2 == 0
    sample :drum_cymbal_closed, amp: 0.35 if rand < hat_probability

    sleep 0.25
  end
end
```

### Snapshot 5 — Cambiar comportamiento sin reescribir el beat

Modificar únicamente:

```ruby
hat_probability = 0.80
hat_probability = 0.70 if step % 2 == 0
```
