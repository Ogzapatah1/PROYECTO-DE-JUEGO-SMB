-- src/entities/enemy.lua
--
-- PURPOSE: Own everything about enemy entities (Dude_Monster):
--          spawn position, movement AI (approaching player), animation,
--          gravity, and bump world collision.

local Animation = require("src/animation")

local GRAVITY    = 700    -- px per second²
local WALK_SPEED = 60     -- px per second when approaching player

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
    self.direction = 1
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

-- Collision filter: pass through player, slide against solid tiles
function Enemy.filter(item, other)
    if other.isPlayer or (other.getInfo and other:getInfo()) then
        return "cross"
    end
    return "slide"
end

function Enemy:update(dt, playerX)
    -- AI logic: move towards player position
    if playerX then
        local dist = playerX - self.x
        if math.abs(dist) > 8 then
            if dist > 0 then
                self.vx = WALK_SPEED
                self.direction = 1
            else
                self.vx = -WALK_SPEED
                self.direction = -1
            end
        else
            self.vx = 0
        end
    end

    -- Apply gravity
    self.vy = self.vy + GRAVITY * dt

    -- Collision movement via bump
    if self.world then
        local goalX = self.x + self.vx * dt
        local goalY = self.y + self.vy * dt

        local actualX, actualY, cols, len = self.world:move(self, goalX, goalY, Enemy.filter)

        self.grounded = false
        for i = 1, len do
            if cols[i].normal.y == -1 then
                self.grounded = true
                self.vy = 0
                break
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
        self.anim:setState("walk")
    else
        self.anim:setState("idle")
    end

    self.anim:update(dt)
end

function Enemy:draw()
    self.anim:draw(self.x + self.width / 2, self.y + self.height / 2)
end

return Enemy
