-- src/selftest/test_bump.lua
--
-- PURPOSE: Test bump.lua collision with STI map tiles.
--          Validates: world creation, collidable tiles registered, player moves/slides.

local Runner = require("src.selftest.runner")
local Tilemap = require("src/tilemap")
local Player  = require("src/entities/player")
local bump    = require("lib/bump")


local function run()
    local c = Runner.checks("bump")

    local Input = require("src/input")
    Input.setTestMode(true)
    Input.load()

    -- ─── Load map and init bump ──────────────────────────────────────────────
    local map = Tilemap.load("assets/maps/level_1_1.lua")
    local world = bump.newWorld(32)
    map:bump_init(world)

    -- ─── World created ───────────────────────────────────────────────────────
    c:truthy("bump world created", world ~= nil)

    -- ─── Collidable tiles registered ─────────────────────────────────────────
    local items = world:getItems()
    c:truthy("world has collidable items", #items > 0)
    c:truthy("multiple collidables", #items >= 49, ("got %d"):format(#items))  -- our map has ~49 solid tiles

    -- Verify each item has rect
    for _, item in ipairs(items) do
        local x, y, w, h = world:getRect(item)
        c:truthy("item has rect", x ~= nil and y ~= nil and w ~= nil and h ~= nil)
        c:eq("tile width", w, 32)
        c:eq("tile height", h, 32)
        -- Only check first few to avoid spam
        if _ > 5 then break end
    end

    -- ─── Spawn player on real bump world ─────────────────────────────────────
    local spawnX, spawnY = Tilemap.getSpawn(map, "player_spawn")
    c:truthy("spawn coords valid", spawnX and spawnY)
    local player = Player.new(spawnX, spawnY, world)
    local dt = 1/60

    -- ─── Player added to world ───────────────────────────────────────────────
    local px, py, pw, ph = world:getRect(player)
    c:truthy("player in world", px ~= nil)
    c:eq("player rect size", pw, 32)
    c:eq("player rect size", ph, 32)

    -- ─── Player falls and lands on ground ────────────────────────────────────
    for _ = 1, 120 do player:update(dt) end
    local info = player:getInfo()
    c:truthy("player grounded on bump tiles", info.grounded)
    c:close("player y near ground", info.y, 256.0, 2.0)

    -- ─── Move right on ground ────────────────────────────────────────────────
    local Input = require("src/input")
    Input.force("move_right", true)
    local startX = player.x
    for _ = 1, 40 do player:update(dt) end
    c:truthy("moves right on bump", player.x > startX + 1)

    -- ─── Hit wall (pillar at col 17) ─────────────────────────────────────────
    -- Pillar is at x ≈ 17*32 = 544. Player at spawn 160, moves right.
    -- Reset player to left of pillar
    player.x = 400
    player.y = 256
    player.vx = 0
    player.vy = 0
    world:update(player, player.x, player.y)

    Input.force("move_right", true)
    for _ = 1, 60 do player:update(dt) end
    -- Player should stop at pillar (x ~ 512 = 16*32, before pillar at 544)
    c:truthy("stops at wall", player.x < 540)

    -- ─── Land on platform (row 5, col 13-14) ─────────────────────────
    -- Platform at y = 5*32 = 160. Player top-left on platform = 160 - 32 = 128.
    player.x = 384
    player.y = 120
    player.vx = 0
    player.vy = 0
    world:update(player, player.x, player.y)

    for _ = 1, 30 do player:update(dt) end
    -- Should land on platform (y = 160 - 32 = 128)
    info = player:getInfo()
    c:truthy("lands on platform", info.grounded)
    c:close("y on platform", info.y, 128.0, 5.0)

    -- ─── Slide along wall (vertical collision) ───────────────────────────────
    -- Move left into pillar while jumping
    player.x = 500
    player.y = 100
    player.vx = 0
    player.vy = 0
    world:update(player, player.x, player.y)
    Input.force("move_left", true)
    Input.force("move_right", false)
    for _ = 1, 20 do player:update(dt) end
    -- Should slide down pillar (y increases)
    c:truthy("slides down wall", player.y > 100)

    Input.setTestMode(false)

    return c:summary()
end


return { run = run }