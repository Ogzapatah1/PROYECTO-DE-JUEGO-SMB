-- src/selftest/test_tilemap.lua
--
-- PURPOSE: Test STI map loading (layers, tilesets, spawn objects).
--          Validates the map file structure without full physics.

local Runner = require("src.selftest.runner")
local Tilemap = require("src/tilemap")


local function run()
    local c = Runner.checks("tilemap")

    -- ─── Load test map ───────────────────────────────────────────────────────
    local map = Tilemap.load("assets/maps/level_1_1.lua")
    c:truthy("Tilemap.load returns map", map ~= nil)

    -- ─── Map dimensions ──────────────────────────────────────────────────────
    c:eq("map width in tiles", map.width, 20)
    c:eq("map height in tiles", map.height, 11)
    c:eq("tile width", map.tilewidth, 32)
    c:eq("tile height", map.tileheight, 32)

    -- ─── Layers ──────────────────────────────────────────────────────────────
    c:truthy("map has layers", map.layers and #map.layers > 0)
    c:truthy("layer count >= 2", #map.layers >= 2)

    -- Find ground layer
    local groundLayer = map.layers["ground"]
    c:truthy("ground layer exists", groundLayer ~= nil)
    if groundLayer then
        c:eq("ground layer type", groundLayer.type, "tilelayer")
        c:truthy("ground layer has data", groundLayer.data ~= nil)
        c:truthy("ground layer collidable", groundLayer.properties and groundLayer.properties.collidable == true)
    end

    -- Find spawn layer
    local spawnLayer = map.layers["spawn"]
    c:truthy("spawn layer exists", spawnLayer ~= nil)
    if spawnLayer then
        c:eq("spawn layer type", spawnLayer.type, "objectgroup")
        c:truthy("spawn layer has objects", spawnLayer.objects and #spawnLayer.objects > 0)
    end

    -- ─── Tileset ─────────────────────────────────────────────────────────────
    c:truthy("tilesets exist", map.tilesets and #map.tilesets > 0)
    if #map.tilesets > 0 then
        local ts = map.tilesets[1]
        c:eq("tileset name", ts.name, "cave")
        c:eq("tile count", ts.tilecount, 60)
        c:eq("columns", ts.columns, 10)
        c:truthy("tileset has image", ts.image ~= nil)
    end

    -- ─── Tiles table populated ───────────────────────────────────────────────
    c:truthy("map.tiles is populated", map.tiles and next(map.tiles) ~= nil)
    if map.tiles then
        -- Should have tile 1 (gid 1 = first tile in tileset)
        c:truthy("gid 1 exists", map.tiles[1] ~= nil)
    end

    -- ─── Spawn point ─────────────────────────────────────────────────────────
    local spawnX, spawnY = Tilemap.getSpawn(map, "player_spawn")
    c:truthy("getSpawn returns coords", spawnX ~= nil and spawnY ~= nil)
    if spawnX then
        c:close("spawn X ~ 160", spawnX, 160, 1)
        c:close("spawn Y ~ 256", spawnY, 256, 1)
    end

    -- ─── Bounds ──────────────────────────────────────────────────────────────
    local minX, minY, maxX, maxY = Tilemap.getBounds(map)
    c:eq("bounds min", minX, 0)
    c:eq("bounds minY", minY, 0)
    c:eq("bounds maxX", maxX, 20 * 32)
    c:eq("bounds maxY", maxY, 11 * 32)

    return c:summary()
end


return { run = run }