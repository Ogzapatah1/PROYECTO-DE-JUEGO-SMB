-- main.lua
-- This file's only job is to wire together all the modules.
-- It should never contain game logic itself.
-- Think of it as the "table of contents" for your game.

--UPPERCASE in the comments indicate main sections (REQUIRE, LOAD, etc)
-- ─── REQUIRE MODULES ─────────────────────────────────────────────────────────
-- in the folder src we will put all our modules, for now we only have 2
-- created and anabled: input and animation
-- "require" runs the target file once, caches it, and returns
-- whatever that file returned (usually a table of functions).

local Input     = require("src/input")
local Animation = require("src/animation")

-- Future modules will be uncommented as we build them:
-- local Camera       = require("src/camera")
-- local Tilemap      = require("src/tilemap")
-- local Player       = require("src/entities/player")
-- local SceneManager = require("src/scene_manager")


-- ─── LOVE.LOAD ───────────────────────────────────────────────────────────────
-- Runs once at startup. Initialize everything here.

function love.load()
    -- CRITICAL for pixel art: prevents blurring when we scale up.
    -- "nearest" keeps each pixel as a sharp square instead of interpolating.
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Boot the input system (seeds its internal state tables)
    Input.load()

    -- Animation objects are created per-entity, not here.
    -- Example: player will call Animation.new(...) inside its own load().
end


-- ─── LOVE.UPDATE ─────────────────────────────────────────────────────────────
-- Runs every frame. dt = seconds since the last frame.
-- ALWAYS multiply movement/velocity by dt to stay frame-rate independent.

function love.update(dt)
    Input.update()    -- must be FIRST — all other systems read from input

    -- Future: Player.update(dt), Camera.update(dt), etc.
end


-- ─── LOVE.DRAW ───────────────────────────────────────────────────────────────
-- Runs every frame after update. Drawing only — no logic here.

function love.draw()
    -- TEMPORARY TEST: shows "true" when you hold the right arrow key.
    -- Delete this line once you confirm input is working.
    love.graphics.print("move_right: " .. tostring(Input.isDown("move_right")), 10, 10)
    love.graphics.print("jump (isPressed): " .. tostring(Input.isPressed("jump")), 10, 30)

    -- Future: Camera.attach(), draw world, Camera.detach(), draw HUD
end
