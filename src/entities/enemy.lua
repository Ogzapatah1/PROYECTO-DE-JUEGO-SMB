-- src/entities/enemy.lua
--
-- PURPOSE: Apply Dude Monster behavior decisions to animation, gravity, and
--          bump collision. The patrol/attack rules live in src/ai/dude_monster.lua.

local Animation = require("src/animation")
local Behavior = require("src/ai/dude_monster")

local GRAVITY    = 700    -- px per second²
local CONTACT_INSET_X = 6 -- contact only; keep the full 32x32 terrain collider
local CONTACT_INSET_Y = 4

local animStates = {
    idle = { path = "assets/sprites/enemies/3 Dude_Monster/Dude_Monster_Idle_4.png",  frames = 4, duration = 0.15 },
    walk = { path = "assets/sprites/enemies/3 Dude_Monster/Dude_Monster_Walk_6.png",  frames = 6, duration = 0.12 },
    run  = { path = "assets/sprites/enemies/3 Dude_Monster/Dude_Monster_Run_6.png",   frames = 6, duration = 0.08 },
}

local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x, y, world)
    local self = setmetatable({}, Enemy)

    self.x = x
    self.y = y
    self.width = 32
    self.height = 32
    self.vx = 0
    self.vy = 0
    self.grounded = false
    self.world = world
    self.direction = -1
    self.behaviorState = "patrol"
    self.isEnemy = true

    -- Build animation controller
    self.anim = Animation.new(animStates)
    self.anim:setState("idle")

    -- Add to bump collision world if provided
    if self.world then
        self.world:add(self, self.x, self.y, self.width, self.height)
    end

    return self
end

-- Pass through the player for movement; Gameplay.outcome applies contact death.
-- Slide against solid terrain tiles.
function Enemy.filter(item, other)
    if other.isPlayer or (other.getInfo and other:getInfo()) then
        return "cross"
    end
    return "slide"
end

function Enemy:getContactBox()
    return {
        x = self.x + CONTACT_INSET_X,
        y = self.y + CONTACT_INSET_Y,
        width = self.width - CONTACT_INSET_X * 2,
        height = self.height - CONTACT_INSET_Y * 2,
    }
end

local function isTerrain(item)
    return not item.isPlayer and not item.isEnemy
end

-- Ask bump whether the leading foot will still have terrain after a step.
function Enemy:hasGroundAhead(direction, distance)
    if not self.world then return true end
    local probeX = direction < 0
        and self.x - distance - 1
        or self.x + self.width + distance
    local _, count = self.world:queryRect(
        probeX, self.y + self.height + 1, 1, 2, isTerrain)
    return count > 0
end

function Enemy:update(dt, playerX)
    local playerDx = playerX and playerX - self.x or nil
    local probeDistance = Behavior.MAX_SPEED * dt
    local leftSafe = self:hasGroundAhead(-1, probeDistance)
    local rightSafe = self:hasGroundAhead(1, probeDistance)
    local speed
    self.behaviorState, self.direction, speed = Behavior.decide(
        self.behaviorState, self.direction, playerDx, leftSafe, rightSafe)
    self.vx = self.direction * speed

    -- Apply gravity
    self.vy = self.vy + GRAVITY * dt

    -- Collision movement via bump
    if self.world then
        local goalX = self.x + self.vx * dt
        local goalY = self.y + self.vy * dt

        local actualX, actualY, cols, len = self.world:move(self, goalX, goalY, Enemy.filter)

        self.grounded = false
        local hitWall = false
        for i = 1, len do
            if cols[i].normal.y == -1 then
                self.grounded = true
                self.vy = 0
            end
            if cols[i].normal.x ~= 0 then hitWall = true end
        end

        if hitWall then
            self.vx = 0
            if self.behaviorState == "patrol" then
                self.direction = -self.direction
            end
        end

        self.x = actualX
        self.y = actualY
    else
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt
    end

    -- Update sprite direction and animation state
    self.anim:setDirection(self.direction)
    if self.vx ~= 0 then
        self.anim:setState(self.behaviorState == "attack" and "run" or "walk")
    else
        self.anim:setState("idle")
    end

    self.anim:update(dt)
end

function Enemy:draw()
    self.anim:draw(self.x + self.width / 2, self.y + self.height / 2)
end

return Enemy
