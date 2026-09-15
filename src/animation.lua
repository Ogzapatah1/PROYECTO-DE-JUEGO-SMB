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
--
-- FORMAT (multi-file): each state is ONE horizontal strip PNG, row 1.
--   states = {
--     idle = { path = "assets/sprites/Pink_Monster_Idle_4.png", frames = 4, duration = 0.15 },
--     walk = { path = "assets/sprites/Pink_Monster_Walk_6.png", frames = 6, duration = 0.10 },
--   }

local anim8 = require("lib/anim8")


-- ─── ANIMATION CLASS ─────────────────────────────────────────────────────────
-- Lua doesn't have built-in classes, but we can simulate them with tables
-- and metatables. Animation.__index = Animation means that when you call
-- a method on an instance (e.g. myAnim:update(dt)), Lua looks up
-- that method in the Animation table if it's not on the instance itself.

local Animation = {}
Animation.__index = Animation


-- ─── DEFAULT FRAME SIZE ──────────────────────────────────────────────────────
-- All current sprites (Pink Monster, cave tiles) are 32×32.
-- States can still override with their own frameW/frameH if needed.

Animation.defaultFrameW = 32
Animation.defaultFrameH = 32


-- ─── ANIMATION.NEW ───────────────────────────────────────────────────────────
-- Creates one animation controller for ONE entity (e.g. the player).
-- Call this inside the entity's own load/init function, not in main.lua.
--
-- PARAMETERS:
--   states   table defining every animation state, one PNG per state:
--
--       {
--         idle = { path = "...Idle_4.png",  frames = 4, duration = 0.15 },
--         walk = { path = "...Walk_6.png",  frames = 6, duration = 0.10 },
--         jump = { path = "...Jump_8.png",  frames = 8, duration = 0.12 },
--       }
--
--   frames     number of frames in the strip (width / frameW)
--   duration   seconds per frame (smaller number = faster animation)
--   (optional) frameW, frameH per state, default 32×32

function Animation.new(states)
    -- setmetatable links this new table to Animation so it inherits all methods
    local self = setmetatable({}, Animation)

    -- Build one anim8 animation object per state definition
    self.anims = {}
    for name, def in pairs(states) do
        local frameW = def.frameW or Animation.defaultFrameW
        local frameH = def.frameH or Animation.defaultFrameH

        local image = love.graphics.newImage(def.path)

        -- Defensive check: declared frames must match the real strip width
        local realFrames = image:getWidth() / frameW
        if realFrames ~= def.frames then
            print("WARNING: state '" .. name .. "' says " .. def.frames ..
                  " frames but image is " .. realFrames)
        end

        -- Vertical strips are row 1, always N columns wide
        -- grid(cols, rows): columns 1..N on the single first row
        local grid = anim8.newGrid(frameW, frameH, image:getWidth(), image:getHeight())

        self.anims[name] = {
            image   = image,
            anim    = anim8.newAnimation(grid("1-" .. def.frames, 1), def.duration),
            frameW  = frameW,
            frameH  = frameH,
        }
    end

    self.currentState = nil     -- name of the active state (string)
    self.currentAnim  = nil     -- the active anim8 animation object
    self.currentImage = nil     -- the active state's image
    self.frameW = Animation.defaultFrameW
    self.frameH = Animation.defaultFrameH

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
    self.currentAnim  = self.anims[name].anim
    self.currentImage = self.anims[name].image
    self.frameW = self.anims[name].frameW
    self.frameH = self.anims[name].frameH
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

function Animation:draw(x, y, scale)
    if not self.currentAnim then return end

    scale = scale or 1

    local ox = self.frameW / 2      -- horizontal center of one frame
    local oy = self.frameH / 2      -- vertical center of one frame

    self.currentAnim:draw(
        self.currentImage,  -- this state's own PNG
        x, y,               -- world position
        0,                  -- rotation (0 = none)
        self.direction * scale, -- scaleX: 1 = normal, -1 = flip horizontally
        scale,              -- scaleY: always 1
        ox, oy              -- origin offset: draw from center
    )
end


return Animation