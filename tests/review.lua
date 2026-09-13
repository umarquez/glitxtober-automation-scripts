-- Headless review for Glitxtober Hammerspoon runners.
--
-- This test intentionally does not automate a GUI. It stubs the Hammerspoon
-- APIs used while modules are loaded, then loads every runner. Runner.new()
-- performs a pure model review of every beat/action, so a missing target,
-- unsupported action, multiline replace_line, or invalid model fails here.

local root = os.getenv("GLITX_ROOT") or "."
_G.GLITX_ROOT = root

local function noop() end

local function fakeHotkey()
  return { delete = noop }
end

_G.hs = {
  printf = noop,
  accessibilityState = function() return true end,

  hotkey = {
    bind = function() return fakeHotkey() end,
  },

  timer = {
    doAfter = function()
      return { stop = noop }
    end,
  },

  eventtap = {
    isSecureInputEnabled = function() return false end,
    keyStroke = noop,
    keyStrokes = noop,
  },

  application = {
    launchOrFocus = function() return true end,
    get = function() return nil end,
  },

  screen = {
    allScreens = function() return {} end,
    mainScreen = function() return nil end,
    find = function() return nil end,
  },

  alert = {
    show = noop,
  },
}

_G.GLITX_STATUS_CONFIG = {
  showAlerts = false,
  recordingAppName = "Sonic Pi",
}

dofile(root .. "/hammerspoon/glitx_status.lua")

-- Avoid a placeholder warning obscuring CI output while still exercising the
-- string escaping/configuration path used by Episode 03.
_G.GLITX_EP03_CONFIG = {
  midiPort = "CI MIDI Port",
}

local runners = {
  "01-codigo-sonido",
  "02-maquina-decide-ritmo",
  "03-controlando-sinte",
  "04-secuenciador",
  "05-ritmos-euclidianos",
  "06-un-sample-cien-sonidos",
  "10-maquina-musica-sola",
}

local reviewed = 0

for _, slug in ipairs(runners) do
  local path = root .. "/hammerspoon/episodes/" .. slug .. "/runner.lua"
  local ok, runnerOrError = pcall(dofile, path)

  if not ok then
    error("FAIL " .. slug .. ": " .. tostring(runnerOrError))
  end

  local runner = runnerOrError
  assert(type(runner) == "table", slug .. " no devolvió un runner")
  assert(type(runner.beats) == "table" and #runner.beats > 0, slug .. " no tiene beats")
  assert(type(runner.review) == "table", slug .. " no generó review estático")
  assert(
    type(runner.review.snapshots) == "table" and
    #runner.review.snapshots == #runner.beats,
    slug .. " no generó un snapshot revisado por beat"
  )
  assert(
    type(runner.review.finalDocument) == "string" and
    runner.review.finalDocument ~= "",
    slug .. " terminó con un documento vacío"
  )

  reviewed = reviewed + 1
  io.write(string.format("PASS %-32s %2d beats\n", slug, #runner.beats))
end

if _G.GLITX_ACTIVE_RUNNER and _G.GLITX_ACTIVE_RUNNER.destroy then
  _G.GLITX_ACTIVE_RUNNER:destroy()
end

io.write(string.format("\n%d runners revisados sin errores de modelo.\n", reviewed))
