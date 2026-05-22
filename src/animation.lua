-- src/animation.lua
--
-- PURPOSE: Wrap anim8 with a state machine so entities say
--          anim:setState("run") and animation follows automatically.
--
-- WHY THIS MATTERS:
-- The tutorial scattered player.anim = player.animations.right
-- across four if-blocks. This module centralizes all that.
-- Entities manage STATES. This module manages FRAMES.
--
-- REQUIRE CHAIN:
--   main.lua → src/entities/player.lua → src/animation.lua → lib/anim8
--
-- HOW anim8 WORKS (quick reference):
--   1. Create a grid:  anim8.newGrid(frameW, frameH, sheetW, sheetH)
--   2. Pick frames:    grid("1-4", 2)  = columns 1-4, row 2
--   3. Make animation: anim8.newAnimation(frames, secondsPerFrame)
--   4. Each frame:     anim:update(dt)  then  anim:draw(image, x, y, ...)

local anim8 = require("lib/anim8")


-- ─── ANIMATION CLASS ─────────────────────────────────────────────────────────
-- Lua doesn't have built-in classes, but we can simulate them with tables
-- and metatables. Animation.__index = Animation means that when you call
-- a method on an instance (e.g. myAnim:update(dt)), Lua looks up
-- that method in the Animation table if it's not on the instance itself.

local Animation = {}
Animation.__index = Animation


-- ─── ANIMATION.NEW ───────────────────────────────────────────────────────────
-- Creates one animation controller for ONE entity (e.g. the player).
-- Call this inside the entity's own load/init function, not in main.lua.
--
-- PARAMETERS:
--   spritesheet    the image loaded with love.graphics.newImage()
--   frameW, frameH pixel dimensions of a SINGLE frame in the sheet
--   states         table defining every animation state, for example:
--
--       {
--         idle  = { cols = "1-1", row = 1, duration = 0.15 },
--         walk  = { cols = "1-6", row = 2, duration = 0.08 },
--         jump  = { cols = "1-2", row = 3, duration = 0.12 },
--         fall  = { cols = "1-1", row = 4, duration = 0.15 },
--       }
--
--   cols     which columns to use ("1-4" = frames 1, 2, 3, 4)
--   row      which row of the sprite sheet to pull frames from
--   duration seconds per frame (smaller number = faster animation)

function Animation.new(spritesheet, frameW, frameH, states)
    -- setmetatable links this new table to Animation so it inherits all methods
    local self = setmetatable({}, Animation)

    self.image  = spritesheet
    self.frameW = frameW
    self.frameH = frameH

    -- Build the anim8 grid from the sprite sheet dimensions
    local grid = anim8.newGrid(
        frameW, frameH,
        spritesheet:getWidth(),
        spritesheet:getHeight()
    )

    -- Build one anim8 animation object per state definition
    self.anims = {}
    for name, def in pairs(states) do
        self.anims[name] = anim8.newAnimation(
            grid(def.cols, def.row),    -- which frames to use
            def.duration                -- seconds between frame changes
        )
    end

    self.currentState = nil     -- name of the active state (string)
    self.currentAnim  = nil     -- the active anim8 animation object

    -- 1 = facing right (default), -1 = facing left
    -- We flip the sprite with a negative scaleX instead of needing
    -- separate left-facing rows in the sprite sheet. Saves sheet space.
    self.direction = 1

    return self
end


-- ─── ANIMATION:SETSTATE ──────────────────────────────────────────────────────
-- Switch to a named animation state.
--
-- The early return is CRITICAL: if we're already in this state, do nothing.
-- Without it, calling setState("walk") every frame would restart the
-- animation from frame 1 each frame, making it look completely frozen.

function Animation:setState(name)
    if self.currentState == name then return end    -- already here, do nothing

    -- Catch typos during development
    if not self.anims[name] then
        print("WARNING: animation state '" .. name .. "' does not exist")
        return
    end

    self.currentState = name
    self.currentAnim  = self.anims[name]
    self.currentAnim:gotoFrame(1)       -- always start a new state from frame 1
end


-- ─── ANIMATION:SETDIRECTION ──────────────────────────────────────────────────
-- Set which way the entity faces.
-- dir = 1 (right) or -1 (left)
-- Stored here and applied in draw() as a horizontal scale flip.

function Animation:setDirection(dir)
    self.direction = dir
end


-- ─── ANIMATION:GETSTATE ──────────────────────────────────────────────────────
-- Returns the name of the current state.
-- Useful when an entity needs to check its own animation state.

function Animation:getState()
    return self.currentState
end


-- ─── ANIMATION:UPDATE ────────────────────────────────────────────────────────
-- Advance the animation timer by dt seconds.
-- Must be called every frame from the entity's update().

function Animation:update(dt)
    if self.currentAnim then
        self.currentAnim:update(dt)
    end
end


-- ─── ANIMATION:DRAW ──────────────────────────────────────────────────────────
-- Draw the current frame at world position (x, y).
--
-- ox, oy shift the drawing origin to the sprite's CENTER.
-- This means x,y represents the middle of the sprite, not its top-left corner.
-- That matters for collision box alignment and camera tracking.

function Animation:draw(x, y)
    if not self.currentAnim then return end

    local ox = self.frameW / 2      -- horizontal center of one frame
    local oy = self.frameH / 2      -- vertical center of one frame

    self.currentAnim:draw(
        self.image,         -- the sprite sheet
        x, y,               -- world position
        0,                  -- rotation (0 = none)
        self.direction,     -- scaleX: 1 = normal, -1 = flip horizontally
        1,                  -- scaleY: always 1
        ox, oy              -- origin offset: draw from center
    )
end


return Animation
