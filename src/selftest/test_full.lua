-- src/selftest/test_full.lua
--
-- PURPOSE: Full integration test (spawn → move → jump → collide → camera).
--          This is the "acceptance test" that exercises the entire pipeline.

local Runner = require("src.selftest.runner")
local Input    = require("src/input")
local Tilemap  = require("src/tilemap")
local Player   = require("src/entities/player")
local Camera   = require("src/camera")
local bump     = require("lib/bump")


local function run()
    local c = Runner.checks("full")

    -- Enable test mode for Input
    Input.setTestMode(true)
    Input.load()

    -- ─── Full world setup ────────────────────────────────────────────────────
    local map = Tilemap.load("assets/maps/level_1_1.lua")
    local world = bump.newWorld(32)
    map:bump_init(world)

    local spawnX, spawnY = Tilemap.getSpawn(map, "player_spawn")
    local player = Player.new(spawnX, spawnY, world)

    local _, _, mapW, mapH = Tilemap.getBounds(map)
    local cam = Camera.new(mapW, mapH, 3)

    local dt = 1/60

    -- ─── Spawn validation ────────────────────────────────────────────────────
    c:close("spawn X", player.x, spawnX, 0.1)
    c:close("spawn Y", player.y, spawnY, 0.1)
    c:truthy("initial grounded", player.grounded)
    c:eq("initial anim idle", player.anim:getState(), "idle")

    -- ─── Let player settle on ground ─────────────────────────────────────────
    for _ = 1, 120 do player:update(dt) end
    c:truthy("settled grounded", player.grounded)

    -- ─── Full movement cycle: right → left → run right → jump → land ────────
    local function simulate(frames, inputs)
        Input.force("move_right", false)
        Input.force("move_left", false)
        Input.force("run", false)
        Input.force("jump", false)
        for k, v in pairs(inputs or {}) do Input.force(k, v) end
        for _ = 1, frames do player:update(dt) end
    end

    -- Move right (walk)
    simulate(40, { move_right = true })
    c:truthy("walk right", player.x > spawnX + 10)
    c:eq("anim walk", player.anim:getState(), "walk")
    c:eq("direction right", player.direction, 1)

    -- Run right
    simulate(40, { move_right = true, run = true })
    c:truthy("run right faster", player.x > spawnX + 100)

    -- Stop
    simulate(10, {})
    c:eq("anim idle after stop", player.anim:getState(), "idle")

    -- Move left
    local rightX = player.x
    simulate(40, { move_left = true })
    c:truthy("walk left", player.x < rightX - 10)  -- position changed

    -- ─── Jump sequence ───────────────────────────────────────────────────────
    -- Settle
    simulate(60, {})
    c:truthy("grounded before jump", player.grounded)
    local preJumpY = player.y

    -- Jump (hold)
    simulate(20, { jump = true })
    c:falsy("airborne", player.grounded)
    c:truthy("rose up", player.y < preJumpY - 10)

    -- Release jump early (variable height)
    simulate(40, { jump = false })
    local midAirY = player.y

    -- Land
    simulate(120, {})
    c:truthy("landed", player.grounded)

    -- ─── Camera follows through all movement ────────────────────────────────
    local startCamX = cam.x
    simulate(1, {})
    cam:update(dt, player.x + player.width / 2, player.y + player.height / 2)
    c:close("camera follows X", cam.x, player.x + player.width / 2, 1.0)
    c:close("camera follows Y", cam.y, player.y + player.height / 2, 1.0)

    -- ─── Camera bounds respected ─────────────────────────────────────────────
    -- Move player to far left
    player.x = 50
    player.y = 100
    world:update(player, player.x, player.y)
    cam:update(dt, player.x + player.width / 2, player.y + player.height / 2)
    c:close("camera clamped left", cam.x, 85.33, 0.5)

    -- Move player to far right
    player.x = 590
    player.y = 100
    world:update(player, player.x, player.y)
    cam:update(dt, player.x + player.width / 2, player.y + player.height / 2)
    c:close("camera clamped right", cam.x, 554.67, 0.5)

    -- ─── World-to-screen conversion works ────────────────────────────────────
    local sx, sy = cam:worldToScreen(player.x, player.y)
    c:truthy("worldToScreen produces coords", sx > 0 and sy > 0)

    -- ─── STI map animations update ───────────────────────────────────────────
    local ok, err = pcall(function() map:update(dt) end)
    c:truthy("map:update doesn't error", ok, err)

    Input.setTestMode(false)

    return c:summary()
end


return { run = run }