-- conf.lua
-- Love2D reads this file automatically BEFORE main.lua even starts.
-- This is where we configure the window, not in code.

function love.conf(t)
    t.window.title  = "Platformer SMB"    -- title bar text
    t.window.width  = 512                 -- base resolution (16:9 friendly)
    t.window.height = 288                 -- at 4x scale this is 1536x864
    t.window.vsync  = 1                   -- lock to monitor refresh rate

    -- Disable modules we don't need.
    -- We use bump.lua for collision, NOT Love2D's built-in Box2D physics.
    t.modules.physics  = false
    t.modules.joystick = false
end
