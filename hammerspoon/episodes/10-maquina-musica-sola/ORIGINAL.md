# Código original — Episodio 10

### Snapshot 1 — Un estado global

```ruby
set :state, :intro
puts get(:state)
```

### Snapshot 2 — Una capa que escucha el estado

```ruby
use_bpm 116

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
```

### Snapshot 3 — Director determinista

```ruby
states = (ring :intro, :groove, :variation, :groove, :breakdown, :groove)

live_loop :director do
  set :state, states.tick(:form)
  puts "STATE: #{get(:state)}"
  sleep 32 # 8 compases de 4/4
end
```

### Snapshot 4 — Tabla de transiciones

```ruby
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
```

### Snapshot 5 — Director autónomo reproducible

```ruby
use_random_seed 2026
set :state, :intro

live_loop :director do
  sleep 32
  current = get(:state) || :intro
  set :state, next_state(current)
  puts "STATE: #{get(:state)}"
end
```

### Snapshot 6 — Bajo condicionado por estado

```ruby
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
```

### Snapshot 7 — Motivo con memoria de estado

```ruby
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
```

### Snapshot 8 — Performance final

Ejecutar `:director`, `:drums`, `:bass` y `:motif` juntos. No agrega una nueva estructura de código; combina los bloques anteriores conservando la misma máquina de estados.
