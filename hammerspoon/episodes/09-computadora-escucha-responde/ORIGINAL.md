# Código original — Episodio 09

### Snapshot 1 — Probar estados sin audio externo

```ruby
set :level, 0.1

live_loop :reactor do
  level = get(:level) || 0

  if level < 0.25
    # reposo
  elsif level < 0.60
    play :d4, release: 0.15, amp: 0.5
  else
    play_pattern_timed [:d4, :a4], [0.125, 0.125], release: 0.1, amp: 0.7
  end

  sleep 0.25
end
```

Cambiar manualmente `:level` a `0.4` y `0.8` para validar la lógica musical.

### Snapshot 2 — Recibir nivel por OSC

```ruby
set :level, 0.0

live_loop :level_input do
  use_real_time
  value = sync "/osc*/level"
  set :level, value[0]
end
```

### Snapshot 3 — Analizador mínimo en Python

```python
import numpy as np
import sounddevice as sd
from pythonosc.udp_client import SimpleUDPClient

client = SimpleUDPClient("127.0.0.1", 4560)
GAIN = 8.0

def callback(indata, frames, time, status):
    mono = indata[:, 0]
    rms = float(np.sqrt(np.mean(mono * mono)))
    level = max(0.0, min(1.0, rms * GAIN))
    client.send_message("/level", level)

with sd.InputStream(channels=1, samplerate=44100,
                    blocksize=1024, callback=callback):
    input("Enter para detener\n")
```

### Snapshot 4 — Tres estados musicales

```ruby
live_loop :response do
  level = get(:level) || 0

  case level
  when 0...0.25
    sleep 0.25
  when 0.25...0.60
    use_synth :pluck
    play :d4, release: 0.15, amp: 0.5
    sleep 0.25
  else
    use_synth :prophet
    play [:d4, :a4].tick(:response_notes), release: 0.2,
      cutoff: 95, amp: 0.7
    sleep 0.125
  end
end
```

### Snapshot 5 — Estado visible

```ruby
live_loop :monitor do
  level = get(:level) || 0
  state = if level < 0.25
            :low
          elsif level < 0.60
            :mid
          else
            :high
          end
  puts "level=#{level.round(2)} state=#{state}"
  sleep 0.1
end
```

### Snapshot 6 — Calibración

Ajustar `GAIN`, `0.25` y `0.60` usando la ganancia real del micrófono. No agrega código fijo nuevo; los valores finales se documentarán después de la calibración de hardware.
