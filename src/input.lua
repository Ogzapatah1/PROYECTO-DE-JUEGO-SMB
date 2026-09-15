-- src/input.lua
--
-- PURPOSE: Abstract raw keyboard keys into named game ACTIONS.
--
-- WHY THIS MATTERS:
-- Instead of love.keyboard.isDown("right") scattered everywhere,
-- every system asks: input.isDown("move_right").
-- Change a key binding in ONE place and the whole game updates.
--
-- REQUIRE CHAIN:
--   main.lua  →  src/input.lua  (no further dependencies)

local Input = {}    -- this table is returned to whoever requires this file


-- ─── KEY BINDINGS ────────────────────────────────────────────────────────────
-- action name  →  actual keyboard key
-- Edit THIS table to rebind keys. Nothing else needs to change.

local bindings = {
    move_left  = "left",
    move_right = "right",
    jump       = "z",       -- z/x is more Mario-like than arrow keys for actions
    run        = "x",
    -- Add more as needed: pause = "escape", interact = "up", etc.
}


-- ─── STATE TABLES ────────────────────────────────────────────────────────────
-- We track TWO frames of input: this frame ("current") and last frame ("previous").
-- Comparing them lets us detect the exact moment a key is pressed or released,
-- not just whether it is held down right now.

local current  = {}     -- key states THIS frame
local previous = {}     -- key states LAST frame

-- Test mode: when true, Input.update() does NOT read the real keyboard.
-- Allows tests to fully control input via Input.force().
local testMode = false


-- ─── INPUT.LOAD ──────────────────────────────────────────────────────────────
-- Called once from main.lua love.load().
-- Seeds both tables so "previous" is never nil on the very first frame.

function Input.load()
    for action, _ in pairs(bindings) do
        current[action]  = false
        previous[action] = false
    end
end


-- ─── INPUT.SETTESTMODE ────────────────────────────────────────────────────────
-- Enable/disable test mode. When enabled, Input.update() skips reading the
-- real keyboard, so Input.force() has full control.
-- Call Input.setTestMode(true) at the start of a test, and false at the end.

function Input.setTestMode(enabled)
    testMode = enabled
end


-- ─── INPUT.UPDATE ────────────────────────────────────────────────────────────
-- Called FIRST in love.update(dt), before anything else reads input.
--
-- Pattern each frame:
--   1. current  → previous   (what was "now" becomes "history")
--   2. keyboard → current    (fresh snapshot becomes "now") — SKIPPED in test mode

function Input.update()
    -- Step 1: copy current into previous (advance frame).
    -- SKIPPED in test mode only for the keyboard read, NOT for frame advance.
    -- Tests control current via force(), but need previous to advance.
    for action, _ in pairs(bindings) do
        previous[action] = current[action]
    end

    -- Step 2: read the keyboard fresh into current (UNLESS test mode)
    if not testMode then
        for action, key in pairs(bindings) do
            current[action] = love.keyboard.isDown(key)
        end
    end
end


-- ─── INPUT.ISDOWN ────────────────────────────────────────────────────────────
-- Returns true every frame the action key is HELD DOWN.
-- Use for: walking left/right, running.
-- "Keep doing this while I hold the key."

function Input.isDown(action)
    return current[action] == true
end


-- ─── INPUT.ISPRESSED ─────────────────────────────────────────────────────────
-- Returns true ONLY on the single frame the key transitions up → down.
-- Use for: jumping, attacking, opening menus.
-- "Trigger exactly once when I tap the key."
--
-- Logic: it IS down now, but was NOT down the frame before.
-- That one-frame window is the "just pressed" moment.

function Input.isPressed(action)
    return current[action] == true and previous[action] == false
end


-- ─── INPUT.ISRELEASED ────────────────────────────────────────────────────────
-- Returns true ONLY on the single frame the key transitions down → up.
-- Use for: variable jump height (cut upward velocity when you release jump early).
-- "Trigger exactly once when I let go."

function Input.isReleased(action)
    return current[action] == false and previous[action] == true
end


-- ─── INPUT.FORCE (DEBUG/TEST ONLY) ───────────────────────────────────────────
-- Manually set an action's state without reading the real keyboard.
-- Used by the --selftest mode to simulate button presses.
-- Sets previous = ~value so isPressed/isReleased edge triggers fire correctly
-- ONLY when the value actually CHANGES. If value is the same, leaves previous
-- alone (assumes update() already advanced the frame correctly).

function Input.force(action, value)
    if current[action] ~= value then
        -- Value CHANGED: create edge by setting previous to opposite
        previous[action] = not value
    end
    -- If value unchanged, DON'T touch previous (update() already advanced it)
    current[action] = value
end


return Input
