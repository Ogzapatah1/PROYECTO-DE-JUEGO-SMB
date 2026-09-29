-- src/selftest/test_enemy.lua
--
-- PURPOSE: Validate Enemy (Dude_Monster) creation, animation, movement AI towards player.

local Runner = require("src/selftest.runner")
local Enemy  = require("src/entities/enemy")
local bump   = require("lib/bump")

local function run()
    local c = Runner.checks("enemy")

    local world = bump.newWorld(32)

    -- Test Enemy Creation
    local enemy = Enemy.new(200, 100, world)
    c:truthy("enemy created", enemy ~= nil)
    c:eq("initial x", enemy.x, 200)
    c:eq("initial y", enemy.y, 100)
    c:truthy("isEnemy flag set", enemy.isEnemy == true)

    -- Test Enemy Movement towards player on the right
    local dt = 1/60
    enemy:update(dt, 300) -- Player at x=300 (to the right of enemy at x=200)
    c:truthy("moves right towards player", enemy.vx > 0)
    c:eq("direction right", enemy.direction, 1)

    -- Test Enemy Movement towards player on the left
    enemy.x = 400
    enemy:update(dt, 200) -- Player at x=200 (to the left of enemy at x=400)
    c:truthy("moves left towards player", enemy.vx < 0)
    c:eq("direction left", enemy.direction, -1)

    -- Test Animation State
    c:eq("anim state walk", enemy.anim:getState(), "walk")

    return c:summary()
end

return { run = run }
