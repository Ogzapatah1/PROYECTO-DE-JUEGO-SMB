-- src/selftest/test_enemy.lua
--
-- PURPOSE: Validate Enemy (Dude_Monster) creation, animation, movement AI towards player.

local Runner = require("src/selftest.runner")
local Enemy  = require("src/entities/enemy")
local Tilemap = require("src.tilemap")
local bump   = require("lib/bump")

local function run()
    local c = Runner.checks("enemy")

    local loaded, Brain = pcall(require, "src.ai.dude_monster")
    c:truthy("Dude Monster behavior loads", loaded, tostring(Brain))
    if not loaded then return c:summary() end

    local mode, facing, speed = Brain.decide("patrol", -1, 200, true, true)
    c:eq("distant player leaves patrol active", mode, "patrol")
    c:eq("patrol starts left", facing, -1)
    c:eq("patrol speed", speed, 30)

    mode, facing, speed = Brain.decide("patrol", -1, 200, false, true)
    c:eq("patrol turns away from left gap", facing, 1)
    c:eq("patrol moves after turning", speed, 30)

    mode, facing, speed = Brain.decide("patrol", -1, 200, false, false)
    c:eq("patrol waits when both sides unsafe", speed, 0)

    mode, facing, speed = Brain.decide("patrol", -1, 100, true, true)
    c:eq("near player triggers attack", mode, "attack")
    c:eq("attack faces player", facing, 1)
    c:eq("attack speed", speed, 45)

    mode, facing, speed = Brain.decide("attack", 1, 100, true, false)
    c:eq("attack waits at gap", speed, 0)
    c:eq("waiting enemy still faces player", facing, 1)

    mode, facing, speed = Brain.decide("attack", 1, 100, true, true)
    c:eq("attack resumes when path is safe", speed, 45)

    mode, facing, speed = Brain.decide("attack", 1, 150, true, true)
    c:eq("attack does not flicker at range boundary", mode, "attack")

    mode, facing, speed = Brain.decide("attack", 1, 200, true, false)
    c:eq("distant player returns to patrol", mode, "patrol")
    c:eq("patrol turns away from unsafe edge", facing, -1)

    local function gapWorld()
        local result = bump.newWorld(32)
        result:add({}, 0, 132, 128, 32)
        result:add({}, 192, 132, 128, 32)
        return result
    end

    local patroller = Enemy.new(64, 100, gapWorld())
    patroller:update(1/60, 300)
    c:eq("real enemy begins in patrol", patroller.behaviorState, "patrol")
    c:eq("real patrol moves left", patroller.direction, -1)
    c:close("real patrol advances left", patroller.x, 63.5, 0.01)
    local turns, lastDirection = 0, patroller.direction
    local stayedOnGround = true
    for _ = 1, 500 do
        patroller:update(1/60, 1000)
        if patroller.direction ~= lastDirection then turns = turns + 1 end
        lastDirection = patroller.direction
        if patroller.y > 100.01 then stayedOnGround = false end
    end
    c:truthy("patrol repeats between safe edges", turns >= 2)
    c:truthy("patrol never falls into the gap", stayedOnGround)

    local leftEdge = Enemy.new(0.5, 100, gapWorld())
    leftEdge:update(1/60, 300)
    c:eq("real patrol turns before left gap", leftEdge.direction, 1)
    c:truthy("real patrol moves away from gap", leftEdge.x > 0.5)

    local chaser = Enemy.new(95.5, 100, gapWorld())
    chaser:update(1/60, 200)
    c:eq("real enemy enters attack", chaser.behaviorState, "attack")
    c:eq("real attack faces across gap", chaser.direction, 1)
    c:close("real attack stops before gap", chaser.x, 95.5, 0.01)
    for _ = 1, 10 do chaser:update(1/60, 200) end
    c:close("waiting attack does not fall", chaser.x, 95.5, 0.01)
    chaser:update(1/60, 150)
    c:close("closer player across gap remains unreachable", chaser.x, 95.5, 0.01)
    chaser:update(1/60, 80)
    c:truthy("attack resumes toward player on same side", chaser.x < 95.5)
    c:eq("independent enemy stays in patrol", patroller.behaviorState, "patrol")

    local wallWorld = bump.newWorld(32)
    wallWorld:add({}, 0, 132, 320, 32)
    wallWorld:add({}, 32, 64, 32, 68)
    local wallPatrol = Enemy.new(64, 100, wallWorld)
    wallPatrol:update(1/60, 300)
    c:eq("patrol turns after wall collision", wallPatrol.direction, 1)
    c:close("wall blocks patrol movement", wallPatrol.x, 64, 0.01)

    local world = bump.newWorld(32)
    world:add({}, 0, 132, 500, 32)

    -- Test Enemy Creation
    local enemy = Enemy.new(200, 100, world)
    c:truthy("enemy created", enemy ~= nil)
    c:eq("initial x", enemy.x, 200)
    c:eq("initial y", enemy.y, 100)
    c:truthy("isEnemy flag set", enemy.isEnemy == true)
    local x, y, w, h = world:getRect(enemy)
    c:eq("terrain collider width unchanged", w, 32)
    c:eq("terrain collider height unchanged", h, 32)

    -- Test Enemy Movement towards player on the right
    local dt = 1/60
    enemy:update(dt, 300) -- Player at x=300 (to the right of enemy at x=200)
    c:truthy("moves right towards player", enemy.vx > 0)
    c:close("attack approach distance", enemy.x, 200.75, 0.01)
    c:eq("direction right", enemy.direction, 1)

    -- Test Enemy Movement towards player on the left
    enemy.x = 400
    world:update(enemy, enemy.x, enemy.y)
    enemy:update(dt, 350) -- Player close to the left of the enemy
    c:truthy("moves left towards player", enemy.vx < 0)
    c:eq("direction left", enemy.direction, -1)

    -- Test Animation State
    c:eq("attack uses run animation", enemy.anim:getState(), "run")

    -- Level 1.1 spawn points must keep each monster clear of tiles and on stage.
    local levelMap = Tilemap.load("assets/maps/level_1_1.lua")
    local levelWorld = bump.newWorld(32)
    levelMap:bump_init(levelWorld)
    local levelEnemies = {}
    for index, point in ipairs(Tilemap.getSpawns(levelMap, "dude_monster_spawn")) do
        local placed = Enemy.new(point.x, point.y, levelWorld)
        levelEnemies[#levelEnemies + 1] = placed
        local _, overlaps = levelWorld:queryRect(placed.x, placed.y,
            placed.width, placed.height,
            function(item) return not item.isEnemy and not item.isPlayer end)
        c:eq("level enemy " .. index .. " starts clear of terrain", overlaps, 0)
    end
    for _ = 1, 60 do
        for _, placed in ipairs(levelEnemies) do placed:update(1/60, 108.834) end
    end
    for index, placed in ipairs(levelEnemies) do
        c:truthy("level enemy " .. index .. " remains visible", placed.y < levelMap.height * levelMap.tileheight)
        c:truthy("level enemy " .. index .. " reaches ground", placed.grounded)
    end

    return c:summary()
end

return { run = run }
