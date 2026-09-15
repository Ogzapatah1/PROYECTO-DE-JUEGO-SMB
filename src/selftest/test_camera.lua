-- src/selftest/test_camera.lua
--
-- PURPOSE: Test Camera module (follow, bounds clamping, scale, world<->screen).
--          Pure math, no graphics.

local Runner = require("src.selftest.runner")
local Camera  = require("src/camera")


local function run()
    local c = Runner.checks("camera")

    -- Map size: 20*32 = 640 x 11*32 = 352
    local mapW, mapH = 640, 352
    local scale = 3

    local cam = Camera.new(mapW, mapH, scale)

    -- ─── Initial state ───────────────────────────────────────────────────────
    c:eq("initial x", cam.x, 0)
    c:eq("initial y", cam.y, 0)
    c:eq("scale", cam.scale, scale)
    c:eq("worldW", cam.worldW, mapW)
    c:eq("worldH", cam.worldH, mapH)

    -- ─── Follow target in center of world ────────────────────────────────────
    cam:update(0, 320, 176)  -- center of map
    c:close("follows X", cam.x, 320, 0.1)
    c:close("follows Y", cam.y, 176, 0.1)

    -- ─── Clamp to left/top bounds ────────────────────────────────────────────
    -- Screen is 512x288 at scale 3 -> halfW = 512/(2*3) = 85.33, halfH = 48
    -- So minX = 85.33, minY = 48
    cam:update(0, 0, 0)
    c:close("clamp left", cam.x, 85.33, 0.1)
    c:close("clamp top", cam.y, 48, 0.1)

    -- ─── Clamp to right/bottom bounds ────────────────────────────────────────
    -- maxX = 640 - 85.33 = 554.67, maxY = 352 - 48 = 304
    cam:update(0, 640, 352)
    c:close("clamp right", cam.x, 554.67, 0.1)
    c:close("clamp bottom", cam.y, 304, 0.1)

    -- ─── Inside bounds (no clamp) ────────────────────────────────────────────
    cam:update(0, 200, 200)
    c:close("inside X", cam.x, 200, 0.1)
    c:close("inside Y", cam.y, 200, 0.1)

    -- ─── World <-> Screen conversion ─────────────────────────────────────────
    -- cam at (200, 200), scale 3, screen center (256, 144)
    -- world (200, 200) -> screen center
    local sx, sy = cam:worldToScreen(200, 200)
    c:close("worldToScreen center", sx, 256, 1)
    c:close("worldToScreen center", sy, 144, 1)

    -- world (232, 200) -> 32px right -> 32*3 = 96px right on screen
    sx, sy = cam:worldToScreen(232, 200)
    c:close("worldToScreen right", sx, 256 + 96, 1)
    c:close("worldToScreen same Y", sy, 144, 1)

    -- Screen to world inverse
    local wx, wy = cam:screenToWorld(256, 144)
    c:close("screenToWorld center", wx, 200, 0.1)
    c:close("screenToWorld center", wy, 200, 0.1)

    wx, wy = cam:screenToWorld(256 + 96, 144)
    c:close("screenToWorld right", wx, 232, 0.1)

    -- ─── Multiple updates (idempotent) ───────────────────────────────────────
    cam:update(0, 300, 100)
    cam:update(0, 300, 100)
    c:close("idempotent update", cam.x, 300, 0.1)
    c:close("idempotent update", cam.y, 100, 0.1)

    return c:summary()
end


return { run = run }