-- src/selftest/test_player.lua
--
-- PURPOSE: Test Player module with real bump world (flat ground via tile).
--          Validates movement, gravity, jump, variable jump, animation states.

local Runner = require("src.selftest.runner")
local Input  = require("src/input")
local Player = require("src/entities/player")
local bump   = require("lib/bump")


local function run()
    local c = Runner.checks("player")

    -- Enable test mode for Input
    Input.setTestMode(true)
    Input.load()

    -- Create a minimal bump world with ONE flat ground tile
    local world = bump.newWorld(32)
    -- Add a ground tile at y=224 (spanning full width)
    local GROUND_Y = 224
    local groundW = 640  -- 20 tiles * 32
    world:add("ground", 0, GROUND_Y, groundW, 32)

    -- Spawn player 48px above ground tile (y=176) so gravity pulls down to land at y=192
    local spawnX, spawnY = 256, GROUND_Y - 48
    local player = Player.new(spawnX, spawnY, world)
    local dt = 1/60

    c:eq("initial x", player.x, spawnX)
    c:eq("initial y", player.y, spawnY)
    c:eq("initial grounded", player.grounded, true)
    c:eq("initial anim state", player.anim:getState(), "idle")

    -- ─── Gravity pulls down ──────────────────────────────────────────────────
    player:update(dt)
    c:truthy("gravity increases y velocity", player.vy > 0)

    -- ─── Falls and lands on ground ───────────────────────────────────────────
    for _ = 1, 120 do player:update(dt) end  -- 2 seconds
    c:truthy("lands on ground", player.grounded)
    c:close("y at ground level", player.y, GROUND_Y - 32, 1.0)

    -- ─── Move right ──────────────────────────────────────────────────────────
    Input.force("move_right", true)
    local startX = player.x
    for _ = 1, 40 do player:update(dt) end
    c:truthy("moves right", player.x > startX + 1)
    c:eq("anim state = walk", player.anim:getState(), "walk")
    c:eq("direction = 1 (right)", player.direction, 1)

    -- ─── Move right + run ────────────────────────────────────────────────────
    Input.force("run", true)
    startX = player.x
    for _ = 1, 40 do player:update(dt) end
    c:truthy("runs faster", player.x > startX + 50)  -- RUN_SPEED * 40 * dt ≈ 133
    c:eq("anim state = run", player.anim:getState(), "run")

    -- ─── Stop → idle ─────────────────────────────────────────────────────────
    Input.force("move_right", false)
    Input.force("run", false)
    for _ = 1, 10 do player:update(dt) end
    c:eq("anim state = idle", player.anim:getState(), "idle")

    -- ─── Move left ───────────────────────────────────────────────────────────
    Input.force("move_left", true)
    startX = player.x
    for _ = 1, 40 do player:update(dt) end
    c:truthy("moves left", player.x < startX - 1)
    c:eq("direction = -1 (left)", player.direction, -1)

    -- ─── Jump from ground ────────────────────────────────────────────────────
    Input.force("move_left", false)
    for _ = 1, 60 do player:update(dt) end  -- settle
    c:truthy("grounded before jump", player.grounded)

    local groundY = player.y
    Input.force("jump", true)
    for _ = 1, 12 do player:update(dt) end  -- rising
    c:falsy("airborne after jump", player.grounded)
    c:truthy("y decreased (rose up)", player.y < groundY - 5)

    Input.force("jump", false)  -- release early = jump cut
    for _ = 1, 60 do player:update(dt) end  -- fall
    c:truthy("falls back down", player.y > groundY - 10)

    -- Land again
    for _ = 1, 120 do player:update(dt) end
    c:truthy("lands again", player.grounded)

    -- ─── Variable jump: hold vs tap ──────────────────────────────────────────
    for _ = 1, 60 do player:update(dt) end
    groundY = player.y

    -- Hold jump full
    Input.force("jump", true)
    for _ = 1, 30 do player:update(dt) end
    local holdHeight = groundY - player.y

    Input.force("jump", false)
    for _ = 1, 120 do player:update(dt) end  -- land

    -- Tap jump (release immediately)
    for _ = 1, 60 do player:update(dt) end
    groundY = player.y
    Input.force("jump", true)
    for _ = 1, 2 do player:update(dt) end
    Input.force("jump", false)  -- immediate release
    for _ = 1, 60 do player:update(dt) end
    local tapHeight = groundY - player.y

    c:truthy("hold jump goes higher than tap", holdHeight > tapHeight + 2)

    -- Disable test mode
    Input.setTestMode(false)

    return c:summary()
end


return { run = run }