-- Glitxtober — Hammerspoon status router
-- Console output is always enabled.
-- On-screen alerts are opt-in through GLITX_STATUS_CONFIG.showAlerts.

local Status = {}

local userConfig = rawget(_G, "GLITX_STATUS_CONFIG") or {}

local C = {
  showAlerts = userConfig.showAlerts == true,
  alertScreen = userConfig.alertScreen or "secondary",
  alertScreenName = userConfig.alertScreenName,
  recordingAppName = userConfig.recordingAppName or "Sonic Pi",
}

local originalAlertShow = hs.alert.show

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

  -- If Sonic Pi has no resolvable window yet, prefer any screen that is not
  -- the current main screen.
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

  -- Any other string is treated as an hs.screen.find() query/name.
  if type(C.alertScreen) == "string" then
    local screen = hs.screen.find(C.alertScreen)
    if screen then return screen end
    console("No se encontró la pantalla de alertas: " .. tostring(C.alertScreen))
  end

  return nil
end

local function parseAlertArgs(...)
  local style = nil
  local duration = nil

  for i = 1, select("#", ...) do
    local arg = select(i, ...)
    local argType = type(arg)

    if argType == "table" and not style then
      style = arg
    elseif argType ~= "userdata" and duration == nil then
      -- hs.alert treats the first remaining argument as duration.
      duration = arg
    end
  end

  return style, duration
end

function Status.show(message, ...)
  console(message)

  if not C.showAlerts then
    return nil
  end

  local screen = configuredScreen()
  if not screen then
    -- Safety first: do not fall back to the recording screen.
    console("Alerta visual omitida: no hay una pantalla de control disponible")
    return nil
  end

  local style, duration = parseAlertArgs(...)

  if style and duration ~= nil then
    return originalAlertShow(message, style, screen, duration)
  elseif style then
    return originalAlertShow(message, style, screen)
  elseif duration ~= nil then
    return originalAlertShow(message, screen, duration)
  end

  return originalAlertShow(message, screen)
end

function Status.log(message)
  console(message)
end

function Status.config()
  return C
end

-- The episode runners currently call hs.alert.show directly. Route those calls
-- through this module so every existing status message is sent to the console,
-- while keeping visual alerts optional.
hs.alert.show = Status.show

_G.GlitxStatus = Status

console(
  "Status router listo — consola ON, alertas " ..
  (C.showAlerts and "ON" or "OFF")
)

return Status
