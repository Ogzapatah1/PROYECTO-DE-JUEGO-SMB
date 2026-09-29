-- main.lua
-- Wires together the game modules and LÖVE callbacks.
-- It also owns the current game flow: lives, respawn, game over,
-- stage finish, and enemy spawning. Entity movement stays in src/entities/.

--UPPERCASE in the comments indicate main sections (REQUIRE, LOAD, etc)
-- ─── REQUIRE MODULES ─────────────────────────────────────────────────────────
-- in the folder src we will put all our modules.
-- "require" runs the target file once, caches it, and returns
-- whatever that file returned (usually a table of functions).

local Input     = require("src/input")
local Animation = require("src/animation")
local Player    = require("src/entities/player")
local Enemy     = require("src/entities/enemy")
local Tilemap   = require("src/tilemap")
local Camera    = require("src/camera")
local Gameplay  = require("src/gameplay")

local bump = require("lib/bump")

-- Future modules will be uncommented as we build them:
-- local SceneManager = require("src/scene_manager")


-- ─── CONFIG ───────────────────────────────────────────────────────────────────
-- All in one place so it's easy to change.

local MAP_PATH           = "assets/maps/level_1_1.lua"
local CAMERA_SCALE        = 1        -- pixel-art zoom
local BUMP_CELL          = 32       -- bump world cell size (matches tile size)
local PIT_Y               = 350      -- y position threshold for falling into pit
local INITIAL_LIVES       = 3        -- starting lives
local DEATH_DELAY         = 5.0      -- seconds to show "YOU DIED!" screen
local GAMEOVER_DELAY      = 6.0      -- seconds to show "GAME OVER!" screen
local STAGE_FINISH_DELAY  = 5.0      -- seconds to show ending / no more stages screen


-- ─── GLOBALS (initialized in love.load) ───────────────────────────────────────
local map
local world
local player
local camera
local enemies = {}

local lives        = INITIAL_LIVES
local currentStage = 1
local gameState    = "playing"   -- "playing", "died", "game_over", "stage_finished", "no_more_stages", "ending"
local stateTimer   = 0


local function spawnDudeMonsters()
    for _, e in ipairs(enemies) do
        if world and world:hasItem(e) then world:remove(e) end
    end
    enemies = {}

    for _, point in ipairs(Tilemap.getSpawns(map, "dude_monster_spawn")) do
        enemies[#enemies + 1] = Enemy.new(point.x, point.y, world)
    end
end

-- ─── RESPAWN PLAYER ───────────────────────────────────────────────────────────
local function respawnPlayer()
    local spawnX, spawnY = Tilemap.getSpawn(map, "player_spawn")
    if not spawnX then
        spawnX, spawnY = map.width * map.tilewidth / 2, map.tileheight * 4
    end
    player.x = spawnX
    player.y = spawnY
    player.vx = 0
    player.vy = 0
    player.grounded = true
    player.anim:setState("idle")
    world:update(player, player.x, player.y)

    spawnDudeMonsters()
end


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

    -- Create the player using top-left world coordinates for its collision box.
    player = Player.new(spawnX, spawnY, world)

    -- Camera with world bounds (Tilemap.getBounds returns minX, minY, maxX, maxY)
    local _, _, mapW, mapH = Tilemap.getBounds(map)
    camera = Camera.new(mapW, mapH, CAMERA_SCALE)

    -- Reset lives, stage, and state
    lives = INITIAL_LIVES
    currentStage = 1
    gameState = "playing"
    stateTimer = 0

    -- Spawn each Dude Monster placed in Tiled.
    spawnDudeMonsters()
end


-- ─── TEST DISPATCHER ─────────────────────────────────────────────────────────
-- --test=input,animation,player,tilemap,bump,camera,full,enemy,gameplay,contact | --selftest (=full) | standalone

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

    if gameState == "playing" then
        player:update(dt)

        -- Each enemy decides whether to patrol or pursue the player.
        for _, enemy in ipairs(enemies) do
            enemy:update(dt, player.x)
        end

        -- Update map animations (animated tiles, etc.)
        map:update(dt)

        -- Camera follows player center
        camera:update(dt, player.x + player.width / 2, player.y + player.height / 2)

        -- Stage finish wins if the player reaches the exit and an enemy together.
        -- Enemy contact and falling into a pit share the same death transition.
        local _, _, mapW, _ = Tilemap.getBounds(map)
        local outcome = Gameplay.outcome(player, enemies, mapW, PIT_Y)
        if outcome == "finish" then
            gameState = "stage_finished"
            stateTimer = 0
        elseif outcome == "death" then
            gameState, lives, stateTimer = Gameplay.loseLife(
                gameState, lives, stateTimer, DEATH_DELAY, GAMEOVER_DELAY)
        end

    elseif gameState == "died" or gameState == "game_over" then
        local shouldRespawn
        gameState, lives, stateTimer, shouldRespawn = Gameplay.advanceDeath(
            gameState, lives, stateTimer, dt, INITIAL_LIVES)
        if shouldRespawn then respawnPlayer() end

    elseif gameState == "no_more_stages" then
        stateTimer = stateTimer - dt
        if stateTimer <= 0 then
            love.event.quit()
        end

    elseif gameState == "ending" then
        stateTimer = stateTimer - dt
        if stateTimer <= 0 then
            love.event.quit()
        end
    end
end


-- ─── LOVE.KEYPRESSED ─────────────────────────────────────────────────────────
-- Hotkey shortcuts (e.g. press R to reload map from disk live, C/F on stage clear)

function love.keypressed(key)
    local k = key:lower()
    if k == "r" then
        print("[GAME] Reloading level from disk...")
        loadGame()
    elseif gameState == "stage_finished" then
        if k == "c" then
            gameState = "no_more_stages"
            stateTimer = STAGE_FINISH_DELAY
        elseif k == "f" then
            gameState = "ending"
            stateTimer = STAGE_FINISH_DELAY
        end
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

    -- Draw player & enemies with SAME transform
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    love.graphics.scale(camera.scale)
    love.graphics.translate(-camera.x, -camera.y)
    player:draw()
    for _, enemy in ipairs(enemies) do
        enemy:draw()
    end
    love.graphics.pop()

    -- Debug HUD (screen coordinates, no camera transform)
    local info = player:getInfo()
    love.graphics.print(("pos (%.0f, %.0f)  vel (%.0f, %.0f)"):format(info.x, info.y, info.vx, info.vy), 10, 10)
    love.graphics.print(("grounded: %s   anim: %s   lives: %d   stage: %d"):format(tostring(info.grounded), info.anim, lives, currentStage), 10, 30)
    love.graphics.print("arrows=move  X=run  Z=jump  R=reload map", 10, 50)
    love.graphics.print(("cam (%.0f, %.0f)"):format(camera.x, camera.y), 10, 70)

    -- Overlay screens (Death / Game Over / Stage Clear / Ending)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local font    = love.graphics.getFont()

    if gameState == "died" then
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)

        love.graphics.setColor(1, 0.3, 0.3, 1)
        local t1 = "YOU DIED!"
        love.graphics.print(t1, math.floor((screenW - font:getWidth(t1)) / 2), math.floor(screenH / 2 - 30))

        love.graphics.setColor(1, 1, 1, 1)
        local t2 = ("You have %d %s left"):format(lives, lives == 1 and "life" or "lives")
        love.graphics.print(t2, math.floor((screenW - font:getWidth(t2)) / 2), math.floor(screenH / 2))

        local t3 = ("Restarting stage in %d..."):format(math.ceil(stateTimer))
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.print(t3, math.floor((screenW - font:getWidth(t3)) / 2), math.floor(screenH / 2 + 30))
        love.graphics.setColor(1, 1, 1, 1)

    elseif gameState == "game_over" then
        love.graphics.setColor(0, 0, 0, 0.88)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)

        love.graphics.setColor(1, 0.1, 0.1, 1)
        local t1 = "GAME OVER!"
        love.graphics.print(t1, math.floor((screenW - font:getWidth(t1)) / 2), math.floor(screenH / 2 - 20))

        love.graphics.setColor(1, 1, 1, 1)
        local t2 = ("Restarting game in %d..."):format(math.ceil(stateTimer))
        love.graphics.print(t2, math.floor((screenW - font:getWidth(t2)) / 2), math.floor(screenH / 2 + 15))
        love.graphics.setColor(1, 1, 1, 1)

    elseif gameState == "stage_finished" then
        love.graphics.setColor(0, 0, 0, 0.82)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)

        love.graphics.setColor(1, 0.85, 0.2, 1)
        local t1 = ("Congratulations!, you finish stage %d"):format(currentStage)
        love.graphics.print(t1, math.floor((screenW - font:getWidth(t1)) / 2), math.floor(screenH / 2 - 20))

        love.graphics.setColor(1, 1, 1, 1)
        local t2 = "Press C to continue or F to finish"
        love.graphics.print(t2, math.floor((screenW - font:getWidth(t2)) / 2), math.floor(screenH / 2 + 15))

    elseif gameState == "no_more_stages" then
        love.graphics.setColor(0, 0, 0, 0.88)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)

        love.graphics.setColor(1, 0.85, 0.2, 1)
        local t1 = "Sorry, no more Stages available!"
        love.graphics.print(t1, math.floor((screenW - font:getWidth(t1)) / 2), math.floor(screenH / 2 - 20))

        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        local t2 = ("Stopping game in %d..."):format(math.ceil(stateTimer))
        love.graphics.print(t2, math.floor((screenW - font:getWidth(t2)) / 2), math.floor(screenH / 2 + 15))
        love.graphics.setColor(1, 1, 1, 1)

    elseif gameState == "ending" then
        love.graphics.setColor(0, 0, 0, 0.88)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)

        love.graphics.setColor(0.3, 0.8, 1, 1)
        local t1 = "Ending..."
        love.graphics.print(t1, math.floor((screenW - font:getWidth(t1)) / 2), math.floor(screenH / 2 - 20))

        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        local t2 = ("Stopping game in %d..."):format(math.ceil(stateTimer))
        love.graphics.print(t2, math.floor((screenW - font:getWidth(t2)) / 2), math.floor(screenH / 2 + 15))
        love.graphics.setColor(1, 1, 1, 1)
    end
end
