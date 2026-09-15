-- src/camera.lua
--
-- PURPOSE: Track a target (player) within world bounds with fixed zoom.
--          Does NOT apply any graphics transform — STI handles that.
--          Just computes the camera position (world center) and scale.
--
-- USAGE:
--   cam = Camera.new(mapW, mapH, scale)
--   cam:update(dt, targetX, targetY)
--   -- Then in draw:
--   map:draw(-cam.x, -cam.y, cam.scale)

local Camera = {}
Camera.__index = Camera


-- ─── CAMERA.NEW ──────────────────────────────────────────────────────────────
-- Create a camera with world bounds and fixed zoom.
-- worldW, worldH = map size in pixels
-- scale = pixel-art zoom (e.g., 3)

function Camera.new(worldW, worldH, scale)
    local self = setmetatable({
        x = 0,
        y = 0,
        worldW = worldW,
        worldH = worldH,
        scale = scale,
    }, Camera)
    return self
end


-- ─── CAMERA:UPDATE ───────────────────────────────────────────────────────────
-- Follow target (player center), clamped to world bounds.
-- targetX, targetY = world coordinates to center on
-- dt = delta time (unused, kept for API compatibility)

function Camera:update(dt, targetX, targetY)
    local halfW = love.graphics.getWidth() / (2 * self.scale)
    local halfH = love.graphics.getHeight() / (2 * self.scale)

    -- Desired camera center = target position
    local desiredX = targetX
    local desiredY = targetY

    -- Clamp to world bounds
    desiredX = math.max(halfW, math.min(self.worldW - halfW, desiredX))
    desiredY = math.max(halfH, math.min(self.worldH - halfH, desiredY))

    -- Instant follow
    self.x = desiredX
    self.y = desiredY
end


-- ─── CAMERA:WORLDTOCAMERA / SCREENTOWORLD ────────────────────────────────────
-- Convert between world and screen coordinates (accounting for camera).

function Camera:worldToScreen(wx, wy)
    local sx = (wx - self.x) * self.scale + love.graphics.getWidth() / 2
    local sy = (wy - self.y) * self.scale + love.graphics.getHeight() / 2
    return sx, sy
end


function Camera:screenToWorld(sx, sy)
    local wx = (sx - love.graphics.getWidth() / 2) / self.scale + self.x
    local wy = (sy - love.graphics.getHeight() / 2) / self.scale + self.y
    return wx, wy
end


return Camera