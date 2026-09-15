-- src/entities/player.lua
--
-- PURPOSE: Own EVERYTHING about the player: position, velocity, physics,
--          animation state, and how input maps to movement.
--
-- WHY THIS MATTERS:
-- main.lua should never know "how to move a player". It only knows
-- "there is a player, update it, draw it". All the details live here,
-- and future enemies will copy this exact structure.
--
-- REQUIRE CHAIN:
--   main.lua → src/entities/player.lua → src/animation.lua → lib/anim8
--                                        → src/input.lua
--                                        → lib/bump (for collision)

local Input     = require("src/input")
local Animation = require("src/animation")
local bump      = require("lib/bump")


-- ─── TUNING CONSTANTS ────────────────────────────────────────────────────────
-- Once real physics + bump.lua collision exists, these move into
-- the gameplay config. For now they live here.

local GRAVITY     = 700    -- px per second² (how fast we fall)
local WALK_SPEED  = 120    -- px per second while walking
local RUN_SPEED   = 200    -- px per second while holding "run"
local JUMP_SPEED  = -300   -- px per second (negative = up)
local JUMP_CUT    = 0.5    -- velocity multiplier on early jump release


-- ─── ANIMATION STATES ────────────────────────────────────────────────────────
-- One horizontal-strip PNG per state (see src/animation.lua). These files
-- all share the same 32×32 frame and are stored in assets/sprites/.

local animStates = {
    idle = { path = "assets/sprites/Pink_Monster_Idle_4.png",  frames = 4, duration = 0.15 },
    walk = { path = "assets/sprites/Pink_Monster_Walk_6.png",  frames = 6, duration = 0.10 },
    run  = { path = "assets/sprites/Pink_Monster_Run_6.png",   frames = 6, duration = 0.07 },
    jump = { path = "assets/sprites/Pink_Monster_Jump_8.png",  frames = 8, duration = 0.12 },
}


-- ─── PLAYER CLASS ────────────────────────────────────────────────────────────
-- Same metatable pattern as Animation. Player.__index = Player lets every
-- instance call Player:update(...) etc.

local Player = {}
Player.__index = Player


-- ─── PLAYER.NEW ──────────────────────────────────────────────────────────────
-- Create the player. x, y is the top-left corner of the collision box.
-- width/height is the collision box (32x32 = full tile).
-- The player is added to the bump world here.

function Player.new(x, y, world)
    local self = setmetatable({}, Player)

    self.x = x
    self.y = y
    self.vx = 0
    self.vy = 0
    self.width  = 32
    self.height = 32
    self.grounded = true
    self.world = world
    self.direction = 1  -- 1 = right, -1 = left

    -- Build the animation controller with all the player's states
    self.anim = Animation.new(animStates)
    self.anim:setState("idle")

    -- Register self in bump world (collision box top-left = self.x, self.y)
    world:add(self, self.x, self.y, self.width, self.height)

    return self
end


-- ─── PLAYER:UPDATE ──────────────────────────────────────────────────────────
-- Runs every frame. Order matters:
--   1. read input      → decide horizontal velocity
--   2. jump input      → set upward velocity (only when grounded)
--   3. apply gravity   → velocity gets pulled down over time
--   4. move via bump   → position changes with collision resolution
--   5. pick animation  → choose the state that matches what happened

function Player:update(dt)
    -- 1. Horizontal movement
    local speed = RUN_SPEED
    if not Input.isDown("run") then speed = WALK_SPEED end

    if     Input.isDown("move_right") then self.vx =  speed
    elseif Input.isDown("move_left")  then self.vx = -speed
    else                                   self.vx = 0
    end

    -- 2. Jump — only from the ground. isPressed = the single tap frame.
    if Input.isPressed("jump") and self.grounded then
        self.vy = JUMP_SPEED
        self.grounded = false
    end

    -- Variable jump height: releasing jump early cuts upward velocity in half,
    -- so tapping jump gives a short hop while holding it gives a full leap.
    if Input.isReleased("jump") and self.vy < 0 then
        self.vy = self.vy * JUMP_CUT
    end

    -- 3. Gravity pulls us down every frame
    self.vy = self.vy + GRAVITY * dt

    -- 4. Move via bump collision resolution.
    --    desired position = current + velocity * dt
    --    bump returns actual position after sliding against obstacles
    local goalX = self.x + self.vx * dt
    local goalY = self.y + self.vy * dt

    local actualX, actualY, cols, len = self.world:move(self, goalX, goalY, self.filter)

    -- Detect ground contact: any collision with normal.y == -1 (hit from above)
    self.grounded = false
    for i = 1, len do
        local col = cols[i]
        if col.normal.y == -1 then
            self.grounded = true
            self.vy = 0
            break
        end
    end

    self.x = actualX
    self.y = actualY

    -- Guide direction for the sprite flip
    if self.vx ~= 0 then
        self.direction = self.vx < 0 and -1 or 1
        self.anim:setDirection(self.direction)
    end

    -- 5. Animation state from what actually happened this frame
    if not self.grounded then
        self.anim:setState("jump")
    elseif self.vx ~= 0 then
        self.anim:setState(math.abs(self.vx) == RUN_SPEED and "run" or "walk")
    else
        self.anim:setState("idle")
    end

    self.anim:update(dt)
end


-- ─── FILTER FUNCTION FOR BUMP ────────────────────────────────────────────────
-- Called by bump for every potential collision.
-- Return "slide" to slide along walls (standard platformer behavior).
-- Return "cross" to pass through (for one-way platforms, collectibles, etc.).

function Player.filter(item, other)
    -- "other" is the tile/object we might hit. Its properties come from Tiled.
    -- For now: everything solid = slide.
    return "slide"
end


-- ─── PLAYER:DRAW ─────────────────────────────────────────────────────────────
-- Everything the player needs to appear. Animation handles its own scale.
-- Top-left is self.x, self.y; draw at center of collision box.

function Player:draw()
    self.anim:draw(self.x + self.width / 2, self.y + self.height / 2)
end


-- ─── PLAYER:GETINFO ──────────────────────────────────────────────────────────
-- Debug helper: a snapshot of the player's state to print in the HUD.
-- Lets us confirm each input → physics → animation link behaves.

function Player:getInfo()
    return {
        x = self.x,
        y = self.y,
        vx = self.vx,
        vy = self.vy,
        grounded = self.grounded,
        anim = self.anim:getState(),
    }
end


return Player