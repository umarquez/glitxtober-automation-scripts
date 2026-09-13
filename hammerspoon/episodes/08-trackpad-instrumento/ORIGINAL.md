# Código original — Episodio 08

### Snapshot 1 — Bridge mínimo en Python

```python
import tkinter as tk
from pythonosc.udp_client import SimpleUDPClient

client = SimpleUDPClient("127.0.0.1", 4560)
root = tk.Tk()
root.geometry("640x400")
root.title("Gesture Bridge")

def on_move(event):
    w = max(root.winfo_width() - 1, 1)
    h = max(root.winfo_height() - 1, 1)
    x = max(0.0, min(1.0, event.x / w))
    y = max(0.0, min(1.0, 1.0 - event.y / h))
    client.send_message("/gesture", [x, y])

root.bind("<Motion>", on_move)
root.mainloop()
```

### Snapshot 2 — Recibir X/Y en Sonic Pi

```ruby
set :gesture_x, 0.5
set :gesture_y, 0.5

live_loop :gesture_input do
  use_real_time
  x, y = sync "/osc*/gesture"
  set :gesture_x, x
  set :gesture_y, y
end
```

### Snapshot 3 — Cinco estados de cutoff

```ruby
cutoffs = [25, 45, 65, 90, 115]

live_loop :read_x do
  x = get(:gesture_x) || 0.5
  x_zone = [(x * 5).floor, 4].min
  puts "X zone: #{x_zone} cutoff: #{cutoffs[x_zone]}"
  sleep 0.1
end
```

### Snapshot 4 — Cuatro densidades

```ruby
gates = [
  [1,0,0,0,1,0,0,0],
  [1,0,1,0,1,0,1,0],
  [1,1,0,1,1,1,0,1],
  [1,1,1,1,1,1,1,1]
]
```

### Snapshot 5 — Secuencia + gesto

```ruby
use_bpm 120
notes = [:d3, :f3, :a3, :c4, :a3, :g3, :f3, :a3]
cutoffs = [25, 45, 65, 90, 115]
gates = [
  [1,0,0,0,1,0,0,0],
  [1,0,1,0,1,0,1,0],
  [1,1,0,1,1,1,0,1],
  [1,1,1,1,1,1,1,1]
]

live_loop :instrument do
  step = tick(:step) % 8
  x = get(:gesture_x) || 0.5
  y = get(:gesture_y) || 0.5
  x_zone = [(x * 5).floor, 4].min
  y_zone = [(y * 4).floor, 3].min

  midi_cc 23, cutoffs[x_zone], port: "<microfreak_port>", channel: 1

  if gates[y_zone][step] == 1
    midi notes[step], sustain: 0.15, port: "<microfreak_port>", channel: 1
  end

  sleep 0.5
end
```

### Snapshot 6 — Performance

Recorrer deliberadamente las esquinas y el centro del área gestual y confirmar que cada zona produce estados repetibles. No agrega código nuevo; es una fase de ejecución/validación.
