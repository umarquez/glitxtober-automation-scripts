# Glitxtober Automation Scripts

Automatizaciones para la producción y grabación de pantalla de Glitxtober.

## Hammerspoon + Sonic Pi

El primer runner está en:

`hammerspoon/episodes/ep01_codigo_sonido.lua`

Corresponde al Episodio 01 — **Código → sonido** y construye el código incrementalmente en Sonic Pi.

### Instalación sugerida

Clona este repositorio dentro de `~/.hammerspoon/` y carga primero el router de estado y después el episodio desde `~/.hammerspoon/init.lua`:

```lua
local ROOT = os.getenv("HOME") .. "/.hammerspoon/glitxtober-automation-scripts"

GLITX_STATUS_CONFIG = {
  showAlerts = false,
  alertScreen = "secondary",
  recordingAppName = "Sonic Pi",
}

dofile(ROOT .. "/hammerspoon/glitx_status.lua")
dofile(ROOT .. "/hammerspoon/episodes/ep01_codigo_sonido.lua")
```

Después usa **Reload Config** en Hammerspoon.

Hammerspoon necesita permiso en **System Settings → Privacy & Security → Accessibility** para generar los eventos de teclado.

### Mensajes de estado

Los mensajes del runner se envían siempre a la **Hammerspoon Console**, por lo que no necesitan aparecer sobre la pantalla que estás grabando.

Las alertas visuales están deshabilitadas por defecto:

```lua
GLITX_STATUS_CONFIG = {
  showAlerts = false,
}
```

Para activarlas en una pantalla secundaria:

```lua
GLITX_STATUS_CONFIG = {
  showAlerts = true,
  alertScreen = "secondary",
}
```

El router intenta identificar la pantalla donde está Sonic Pi y usa otro monitor como pantalla de control. Si no encuentra una segunda pantalla, **no hace fallback a la pantalla de grabación**: conserva únicamente el mensaje en consola.

También puedes forzar una pantalla por nombre usando `hs.screen.find()`:

```lua
GLITX_STATUS_CONFIG = {
  showAlerts = true,
  alertScreenName = "DELL U2720Q",
}
```

`hammerspoon/glitx_status.lua` intercepta los mensajes existentes del runner, los registra en consola y sólo dibuja una alerta si `showAlerts` es `true`.

### Controles

- `Ctrl + Alt + Cmd + N`: siguiente beat de grabación.
- `Ctrl + Alt + Cmd + R`: detener Sonic Pi, limpiar el buffer y reiniciar la toma.
- `Ctrl + Alt + Cmd + I`: mostrar el siguiente beat.
- `Ctrl + Alt + Cmd + X`: cancelar la automatización actual.
- `Ctrl + Alt + Cmd + T`: prueba mínima de escritura.

### Confiabilidad de saltos de línea

La versión actual usa una estrategia conservadora para evitar que Sonic Pi fusione instrucciones durante la escritura automática:

- `Return` se mantiene durante 180 ms y la escritura espera entre 300–420 ms antes de continuar.
- Las líneas que terminan en `do`/`end` y las líneas `sample ...` reciben una pausa adicional.
- Los bloques `live_loop` de primer nivel se separan con **dos Returns**. Esto conserva la línea en blanco del código original y evita que un salto perdido pueda producir algo como `endlive_loop ...`.
- Los fragmentos de batería se validan al cargar el script para comprobar que `sample` y `sleep` están en líneas separadas.
- Antes de ejecutar cada beat se valida el modelo interno para detectar estructuras imposibles, como un `sample` y un `sleep` en la misma línea.

Para una toma nueva, comienza siempre con `Ctrl + Alt + Cmd + R`.
