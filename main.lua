-- main.lua
-- This file's only job is to wire together all the modules.
-- It should never contain game logic itself.
-- Think of it as the "table of contents" for your game.

--UPPERCASE in the comments indicate main sections (REQUIRE, LOAD, etc)
-- ─── REQUIRE MODULES ─────────────────────────────────────────────────────────
-- in the folder src we will put all our modules.
-- "require" runs the target file once, caches it, and returns
-- whatever that file returned (usually a table of functions).

local Input     = require("src/input")
local Animation = require("src/animation")
local Player    = require("src/entities/player")
local Tilemap   = require("src/tilemap")
local Camera    = require("src/camera")

local bump = require("lib/bump")

-- Future modules will be uncommented as we build them:
-- local SceneManager = require("src/scene_manager")


-- ─── CONFIG ───────────────────────────────────────────────────────────────────
-- All in one place so it's easy to change.

local MAP_PATH     = "assets/maps/level_1_1.lua"
local CAMERA_SCALE = 1.5        -- pixel-art zoom
local BUMP_CELL    = 32       -- bump world cell size (matches tile size)


-- ─── GLOBALS (initialized in love.load) ───────────────────────────────────────
local map
local world
local player
local camera


-- ─── LOAD GAME ───────────────────────────────────────────────────────────────
-- All one-time initialization. Extracted so the test runner can pcall() it
-- and capture the exact error if it fails.

local function loadGame()
    -- CRITICAL for pixel art: prevents blurring when we scale up.
    -- "nearest" keeps each pixel as a sharp square instead of interpolating.
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Boot the input system (seeds its internal state tables)
    Input.load()

    -- Load the map via STI
    map = Tilemap.load(MAP_PATH)

    -- Create bump world and register all collidable tiles via STI bump plugin
    world = bump.newWorld(BUMP_CELL)
    map:bump_init(world)

    -- Find player spawn from object layer
    local spawnX, spawnY = Tilemap.getSpawn(map, "player_spawn")
    if not spawnX then
        -- Fallback: center of map, near top
        spawnX, spawnY = map.width * map.tilewidth / 2, map.tileheight * 4
    end

    -- Create the player (position in world pixels, center of sprite)
    player = Player.new(spawnX, spawnY, world)

    -- Camera with world bounds (Tilemap.getBounds returns minX, minY, maxX, maxY)
    local _, _, mapW, mapH = Tilemap.getBounds(map)
    camera = Camera.new(mapW, mapH, CAMERA_SCALE)
end


-- ─── TEST DISPATCHER ─────────────────────────────────────────────────────────
-- --test=input,animation,player,tilemap,bump,camera,full | --selftest (=full) | standalone

local function parseArgs(args)
    local req = {}
    for _, a in ipairs(args or {}) do
        -- --test=<name> or --test (implies full)
        local v = a:match("^%-%-test=?(.+)") or a:match("^%-%-selftest=?(.+)")
        if a == "--test" or a == "--selftest" then
            req[#req+1] = "full"
        elseif v and v ~= "" then
            for name in v:gmatch("[^,]+") do
                req[#req+1] = name
            end
        end
    end
    return req
end

local function runTestByName(name, args)
    local Runner = require("src.selftest.runner")
    local mod    = "src.selftest.test_" .. name
    local okMod, testMod = pcall(require, mod)
    if not okMod then
        return Runner.run(name, function()
            local c = Runner.checks(name)
            c:check("module loads", false, "cannot require " .. mod .. " : " .. tostring(testMod))
            return c:summary()
        end)
    end
    return Runner.run(name, function() return testMod.run(args) end)
end

local function runAllTests(requests, args)
    if #requests == 0 then return 0 end
    print(("[DISPATCHER] Tests requested: %s"):format(table.concat(requests, ", ")))
    local worst = 0
    for _, name in ipairs(requests) do
        local code = runTestByName(name, args)
        if code ~= 0 then worst = code end
    end
    return worst
end


-- ─── LOVE.LOAD ───────────────────────────────────────────────────────────────
-- In --test / --selftest mode, init is wrapped so a load error is
-- written to a report file and the process exits 1 (not silently blank).
-- In normal mode, just loadGame().

function love.load(args)
    local requests = parseArgs(args)
    if #requests > 0 then
        local ok, err = pcall(loadGame)
        if not ok then
            local Runner = require("src.selftest.runner")
            Runner.run("load", function()
                local c = Runner.checks("load")
                c:check("loadGame succeeds", false, tostring(err) .. "\n" .. debug.traceback("", 2))
                return c:summary()
            end)
            love.event.quit(1)
            return
        end
        local exitCode = runAllTests(requests, args)
        love.event.quit(exitCode)
        return
    end

    loadGame()
end


-- ─── LOVE.UPDATE ─────────────────────────────────────────────────────────────
-- Runs every frame. dt = seconds since the last frame.
-- ALWAYS multiply movement/velocity by dt to stay frame-rate independent.

function love.update(dt)
    Input.update()    -- must be FIRST — all other systems read from input

    player:update(dt)

    -- Update map animations (animated tiles, etc.)
    map:update(dt)

    -- Camera follows player center
    camera:update(dt, player.x + player.width / 2, player.y + player.height / 2)
end


-- ─── LOVE.KEYPRESSED ─────────────────────────────────────────────────────────
-- Hotkey shortcuts (e.g. press R to reload map from disk live)

function love.keypressed(key)
    if key == "r" then
        print("[GAME] Reloading level from disk...")
        loadGame()
    end
end


-- ─── LOVE.DRAW ───────────────────────────────────────────────────────────────
-- Runs every frame after update. Drawing only — no logic here.

function love.draw()
    -- STI draw(tx, ty, sx): world point (wx, wy) -> screen ((wx + tx) * sx, (wy + ty) * sy).
    -- We want camera center (camera.x, camera.y) at screen center.
    -- So tx = screenW/2/scale - camera.x
    local tx = love.graphics.getWidth() / (2 * camera.scale) - camera.x
    local ty = love.graphics.getHeight() / (2 * camera.scale) - camera.y

    -- Draw map
    map:draw(tx, ty, camera.scale)

    -- Draw player with SAME transform
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    love.graphics.scale(camera.scale)
    love.graphics.translate(-camera.x, -camera.y)
    player:draw()
    love.graphics.pop()

    -- Debug HUD (screen coordinates, no camera transform)
    local info = player:getInfo()
    love.graphics.print(("pos (%.0f, %.0f)  vel (%.0f, %.0f)"):format(info.x, info.y, info.vx, info.vy), 10, 10)
    love.graphics.print("grounded: " .. tostring(info.grounded) .. "   anim: " .. info.anim, 10, 30)
    love.graphics.print("arrows=move  X=run  Z=jump  R=reload map", 10, 50)
    love.graphics.print(("cam (%.0f, %.0f)"):format(camera.x, camera.y), 10, 70)
end