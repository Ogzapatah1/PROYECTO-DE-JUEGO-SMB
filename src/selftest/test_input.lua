-- src/selftest/test_input.lua
--
-- PURPOSE: Test Input module (isDown, isPressed, isReleased).
--          Runs in isolation, no graphics needed.

local Runner = require("src.selftest.runner")
local Input  = require("src/input")


local function run()
    local c = Runner.checks("input")

    -- Enable test mode so Input.update() doesn't read real keyboard
    Input.setTestMode(true)

    -- Seed Input state
    Input.load()

    -- ─── isDown + isPressed on press ─────────────────────────────────────────
    -- Pattern: force() creates edge, check IMMEDIATELY, then update() advances
    Input.force("move_right", true)   -- up→down edge created
    c:truthy("isDown true after force", Input.isDown("move_right"))
    c:truthy("isPressed true on press edge", Input.isPressed("move_right"))
    c:falsy("isReleased false", Input.isReleased("move_right"))
    Input.update()  -- advance frame: edge consumed

    -- ─── isDown held, no edge ────────────────────────────────────────────────
    c:truthy("isDown true on frame 2 (held)", Input.isDown("move_right"))
    c:falsy("isPressed false on hold", Input.isPressed("move_right"))
    c:falsy("isReleased false", Input.isReleased("move_right"))
    Input.update()

    c:truthy("isDown true on frame 3 (held)", Input.isDown("move_right"))
    c:falsy("isPressed false on hold", Input.isPressed("move_right"))
    c:falsy("isReleased false", Input.isReleased("move_right"))
    Input.update()

    -- ─── Release: isReleased edge ────────────────────────────────────────────
    Input.force("move_right", false)  -- down→up edge
    c:falsy("isDown false after force release", Input.isDown("move_right"))
    c:falsy("isPressed false", Input.isPressed("move_right"))
    c:truthy("isReleased true on release edge", Input.isReleased("move_right"))
    Input.update()  -- advance: edge consumed

    -- ─── Press again ─────────────────────────────────────────────────────────
    Input.force("move_right", true)
    c:truthy("isDown true on press", Input.isDown("move_right"))
    c:truthy("isPressed true on press edge", Input.isPressed("move_right"))
    c:falsy("isReleased false", Input.isReleased("move_right"))
    Input.update()

    -- Held
    c:falsy("isPressed false on hold", Input.isPressed("move_right"))
    Input.update()

    -- ─── Release again ───────────────────────────────────────────────────────
    Input.force("move_right", false)
    c:truthy("isReleased true on release edge", Input.isReleased("move_right"))
    Input.update()

    -- ─── Multiple keys simultaneous press ────────────────────────────────────
    Input.force("move_left", true)
    Input.force("jump", true)
    c:truthy("multiple isDown true", Input.isDown("move_left") and Input.isDown("jump"))
    c:truthy("multiple isPressed true on first frame", Input.isPressed("move_left") and Input.isPressed("jump"))
    Input.update()

    -- ─── Edge case: force same value ────────────────────────────────────────
    Input.force("move_left", true)    -- already true
    c:falsy("isPressed false when forced to same value", Input.isPressed("move_left"))
    Input.update()

    -- Disable test mode for other tests
    Input.setTestMode(false)

    return c:summary()
end


return { run = run }