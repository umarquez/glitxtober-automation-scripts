# Episodio 07 — La imagen se convierte en música

**Estado:** TODO — requiere una etapa posterior en VS Code.

Sonic Pi consume dos arrays de 16 valores (`brightness` y `saturation`), pero el episodio completo necesita un extractor en Python que lea una imagen y produzca esos datos. Por esa razón todavía no se crea un runner de grabación definitivo.

## Arquitectura prevista

```mermaid
flowchart LR
  I[Imagen] --> P[Python en VS Code]
  P -->|brightness[16]| S[Sonic Pi]
  P -->|saturation[16]| S
  S --> N[Altura]
  S --> C[Cutoff / amplitud]
  N --> A[Audio]
  C --> A
```

## TODO — fase VS Code

- Crear `image_features.py` con Pillow y `colorsys`.
- Fijar la convención de entrada para Imagen A / Imagen B.
- Validar que cada array tenga exactamente 16 valores entre `0` y `1`.
- Definir cómo Hammerspoon alternará entre VS Code y Sonic Pi durante la grabación.
- Crear el runner final sólo cuando el extractor y el flujo A/B estén estabilizados.

## Código Sonic Pi previsto

La parte Sonic Pi mapeará brillo a notas de una escala pentatónica menor y saturación a cutoff/amplitud. El código musical se mantiene pendiente de automatización, no de diseño.
