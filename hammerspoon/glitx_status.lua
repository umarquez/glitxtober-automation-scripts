-- Glitxtober status router.
--
-- Policy:
--   * console logging is always enabled;
--   * visual alerts are disabled by default;
--   * when enabled, alerts are sent only to a configured/control display;
--   * there is no fallback to the Sonic Pi recording display.

local Status = {}

local userConfig = rawget(_G, "GLITX_STATUS_CONFIG") or {}

local C = {
  showAlerts = userConfig.showAlerts == true,
  alertScreen = userConfig.alertScreen or "secondary",
  alertScreenName = userConfig.alertScreenName,
  recordingAppName = userConfig.recordingAppName or "Sonic Pi",
  defaultDuration = userConfig.defaultDuration or 1.30,
}

local function console(message)
  hs.printf("[Glitxtober] %s", tostring(message))
end

local function recordingScreen()
  local app = hs.application.get(C.recordingAppName)
  if not app then return nil end

  local window = app:mainWindow()
  if not window then return nil end

  return window:screen()
end

local function secondaryScreen()
  local recording = recordingScreen()
  local screens = hs.screen.allScreens()

  if #screens < 2 then return nil end

  if recording then
    for _, screen in ipairs(screens) do
      if screen:id() ~= recording:id() then
        return screen
      end
    end
  end

  local main = hs.screen.mainScreen()
  for _, screen in ipairs(screens) do
    if not main or screen:id() ~= main:id() then
      return screen
    end
  end

  return nil
end

local function configuredScreen()
  if C.alertScreenName then
    local screen = hs.screen.find(C.alertScreenName)
    if screen then return screen end

    console("No se encontró la pantalla configurada: " .. tostring(C.alertScreenName))
    return nil
  end

  if C.alertScreen == "secondary" then
    return secondaryScreen()
  end

  if C.alertScreen == "main" then
    return hs.screen.mainScreen()
  end

  if type(C.alertScreen) == "string" then
    local screen = hs.screen.find(C.alertScreen)
    if screen then return screen end
    console("No se encontró la pantalla de alertas: " .. tostring(C.alertScreen))
  end

  return nil
end

function Status.show(message, duration)
  console(message)

  if not C.showAlerts then
    return nil
  end

  local screen = configuredScreen()
  if not screen then
    console("Alerta visual omitida: no hay una pantalla de control disponible")
    return nil
  end

  return hs.alert.show(message, screen, duration or C.defaultDuration)
end

function Status.log(message)
  console(message)
end

function Status.config()
  return C
end

_G.GlitxStatus = Status

console(
  "Status router listo — consola ON, alertas " ..
  (C.showAlerts and "ON" or "OFF")
)

return Status
