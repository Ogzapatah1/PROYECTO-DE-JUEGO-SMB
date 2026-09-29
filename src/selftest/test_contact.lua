-- src/selftest/test_contact.lua
-- Exercises the real LÖVE update flow without adding test-only game APIs.

local Runner = require("src.selftest.runner")
local Tilemap = require("src.tilemap")

local function updateUpvalue(name)
    for index = 1, 64 do
        local key, value = debug.getupvalue(love.update, index)
        if not key then break end
        if key == name then return value, index end
    end
    error("love.update has no upvalue named " .. name)
end

local function place(entity, x, y)
    entity.x, entity.y = x, y
    entity.vx, entity.vy = 0, 0
    entity.world:update(entity, x, y)
end

local function run()
    local c = Runner.checks("contact")

    local player = updateUpvalue("player")
    local enemies = updateUpvalue("enemies")
    local map = updateUpvalue("map")
    local points = Tilemap.getSpawns(map, "dude_monster_spawn")
    c:truthy("level has a point for contact test", #points > 0)
    c:eq("one enemy per Tiled point", #enemies, #points)
    for index, point in ipairs(points) do
        c:eq("enemy " .. index .. " spawn X", enemies[index] and enemies[index].x, point.x)
        c:eq("enemy " .. index .. " spawn Y", enemies[index] and enemies[index].y, point.y)
    end
    if #enemies == 0 then return c:summary() end
    local enemy = enemies[1]
    place(enemy, player.x, player.y)
    love.update(0)

    c:eq("contact shows death screen", updateUpvalue("gameState"), "died")
    c:eq("contact costs one life", updateUpvalue("lives"), 2)
    if updateUpvalue("gameState") ~= "died" then return c:summary() end

    love.update(0)
    c:eq("death screen cannot drain another life", updateUpvalue("lives"), 2)
    love.update(5.1)
    c:eq("respawn returns to play", updateUpvalue("gameState"), "playing")
    c:eq("respawn keeps remaining lives", updateUpvalue("lives"), 2)
    enemies = updateUpvalue("enemies")
    c:eq("respawn restores every enemy", #enemies, #points)
    for index, point in ipairs(points) do
        c:eq("respawn enemy " .. index .. " X", enemies[index] and enemies[index].x, point.x)
        c:eq("respawn enemy " .. index .. " Y", enemies[index] and enemies[index].y, point.y)
    end
    c:truthy("respawn separates player and enemy",
        math.abs(updateUpvalue("player").x - updateUpvalue("enemies")[1].x) > 32)

    love.keypressed("r") -- reset level state for the finish-line case
    player = updateUpvalue("player")
    enemies = updateUpvalue("enemies")
    local map = updateUpvalue("map")
    place(player, map.width * map.tilewidth - 64, 100)
    place(enemies[1], player.x, player.y)
    love.update(0)
    c:eq("finish wins same-frame contact", updateUpvalue("gameState"), "stage_finished")
    c:eq("finish keeps all lives", updateUpvalue("lives"), 3)

    love.keypressed("r") -- reset level state for the last-life case
    local _, livesIndex = updateUpvalue("lives")
    debug.setupvalue(love.update, livesIndex, 1)
    player = updateUpvalue("player")
    enemies = updateUpvalue("enemies")
    place(enemies[1], player.x, player.y)
    love.update(0)
    c:eq("last-life contact shows game over", updateUpvalue("gameState"), "game_over")
    c:eq("last-life contact reaches zero", updateUpvalue("lives"), 0)
    if updateUpvalue("gameState") ~= "game_over" then return c:summary() end

    love.update(6.1)
    c:eq("game over restarts play", updateUpvalue("gameState"), "playing")
    c:eq("game over restores three lives", updateUpvalue("lives"), 3)

    return c:summary()
end

return { run = run }
