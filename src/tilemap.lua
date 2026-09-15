-- src/tilemap.lua
--
-- PURPOSE: Load and draw Tiled maps via STI.
--          This is the bridge between the map file and the game.
--
-- REQUIRE CHAIN:
--   main.lua → src/tilemap.lua → lib/sti → lib/anim8 (indirect)
--
-- FLOW:
--   1. love.load: map = Tilemap.load("assets/maps/level_1_1.lua")
--   2. love.update(dt): map:update(dt)
--   3. love.draw(): Camera.attach(); map:draw(-camera.x, -camera.y, camera.scale); Camera.detach()

local sti = require("lib/sti")


local Tilemap = {}


-- ─── TILEMAP.LOAD ────────────────────────────────────────────────────────────
-- Load a map file and return the STI map object.
-- Plugins are loaded here — bump plugin registers collision data.

function Tilemap.load(path)
    local map = sti(path, { "bump" })
    return map
end


-- ─── TILEMAP.GETSPAWN ────────────────────────────────────────────────────────
-- Return the player spawn point from the "spawn" object layer.
-- Tiled point objects have x,y in pixels already.

function Tilemap.getSpawn(map, objectName)
    local spawnLayer = map.layers["spawn"]
    if not spawnLayer then return nil end
    for _, obj in ipairs(spawnLayer.objects) do
        if obj.name == objectName then
            return obj.x, obj.y
        end
    end
    return nil
end


-- ─── TILEMAP.GETBOUNDS ───────────────────────────────────────────────────────
-- Return the map bounds in pixels (for camera limits).

function Tilemap.getBounds(map)
    return 0, 0, map.width * map.tilewidth, map.height * map.tileheight
end


return Tilemap