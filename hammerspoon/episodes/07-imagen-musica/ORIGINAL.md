# Código original — Episodio 07

### Snapshot 1 — Datos de prueba

```ruby
use_bpm 100
brightness = [0.10, 0.18, 0.25, 0.42, 0.60, 0.82, 0.75, 0.51,
              0.34, 0.20, 0.28, 0.48, 0.70, 0.91, 0.66, 0.30]
```

### Snapshot 2 — Brillo a altura

```ruby
notes = scale(:d3, :minor_pentatonic, num_octaves: 2)

live_loop :image_notes do
  brightness.each do |value|
    idx = (value * (notes.length - 1)).round
    play notes[idx], release: 0.2, amp: 0.6
    sleep 0.25
  end
end
```

### Snapshot 3 — Añadir saturación

```ruby
saturation = [0.20, 0.35, 0.50, 0.72, 0.80, 0.62, 0.40, 0.30,
              0.18, 0.25, 0.55, 0.77, 0.90, 0.68, 0.44, 0.22]

live_loop :image_notes do
  16.times do |step|
    value = brightness[step]
    idx = (value * (notes.length - 1)).round
    cutoff = 45 + saturation[step] * 70
    play notes[idx], release: 0.2, cutoff: cutoff, amp: 0.45 + value * 0.35
    sleep 0.25
  end
end
```

### Snapshot 4 — Extractor mínimo en Python

```python
from PIL import Image
import colorsys

img = Image.open("imagen.jpg").convert("RGB").resize((16, 1))
pixels = list(img.getdata())

brightness = []
saturation = []

for r, g, b in pixels:
    lum = (0.2126*r + 0.7152*g + 0.0722*b) / 255
    _, sat, _ = colorsys.rgb_to_hsv(r/255, g/255, b/255)
    brightness.append(round(lum, 3))
    saturation.append(round(sat, 3))

print("brightness =", brightness)
print("saturation =", saturation)
```

### Snapshot 5 — Prueba A/B

Ejecutar el mismo código con arrays obtenidos de **Imagen A** e **Imagen B**. No cambiar escala, tempo ni fórmula de cutoff.
