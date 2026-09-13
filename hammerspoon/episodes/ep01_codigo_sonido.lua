-- Compatibility shim.
-- Canonical Episode 01 runner:
-- hammerspoon/episodes/01-codigo-sonido/runner.lua

local ROOT =
  rawget(_G, "GLITX_ROOT") or
  (os.getenv("HOME") .. "/.hammerspoon/glitxtober-automation-scripts")

return dofile(ROOT .. "/hammerspoon/episodes/01-codigo-sonido/runner.lua")
