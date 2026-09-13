# Código original — Episodio 06

La documentación usa `:loop_amen` como única fuente reproducible. En producción puede sustituirse por la grabación vocal de “Glitxtober”, manteniendo la restricción de una sola fuente.

### Snapshot 1 — La fuente

```ruby
use_bpm 110
sample :loop_amen
```

### Snapshot 2 — Un fragmento

```ruby
use_bpm 110
sample :loop_amen, start: 0.0, finish: 0.125
```

### Snapshot 3 — Misma región, otra velocidad

```ruby
sample :loop_amen, start: 0.0, finish: 0.125, rate: 0.5
sleep 1
sample :loop_amen, start: 0.0, finish: 0.125, rate: 2.0
```

### Snapshot 4 — La misma fuente al revés

```ruby
sample :loop_amen, rate: -1
```

### Snapshot 5 — Pulso grave desde un slice

```ruby
use_bpm 110

live_loop :low_pulse do
  sample :loop_amen, start: 0.0, finish: 0.125, rate: 0.5, amp: 1.1
  sleep 1
end
```

### Snapshot 6 — Añadir una capa aguda

```ruby
live_loop :high_ticks do
  sample :loop_amen, start: 0.5, finish: 0.5625, rate: 2.0, amp: 0.35
  sleep 0.5
end
```

### Snapshot 7 — Textura invertida

```ruby
live_loop :reverse_texture do
  sample :loop_amen, rate: -1, amp: 0.2
  sleep 8
end
```

### Snapshot 8 — Arreglo completo de una sola fuente

```ruby
use_bpm 110

live_loop :low_pulse do
  sample :loop_amen, start: 0.0, finish: 0.125, rate: 0.5, amp: 1.1
  sleep 1
end

live_loop :high_ticks do
  sample :loop_amen, start: 0.5, finish: 0.5625, rate: 2.0, amp: 0.35
  sleep 0.5
end

live_loop :reverse_texture do
  sample :loop_amen, rate: -1, amp: 0.2
  sleep 8
end
```

### Snapshot 9 — Mutación de performance

Cambiar únicamente `rate: 2.0` a `rate: 1.5` dentro de `:high_ticks`.

```ruby
sample :loop_amen, start: 0.5, finish: 0.5625, rate: 1.5, amp: 0.35
```
