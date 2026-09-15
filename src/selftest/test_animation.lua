-- src/selftest/test_animation.lua
--
-- PURPOSE: Test Animation module (state transitions, frame advancement, draw safety).
--          Uses the actual PNG assets; no graphics context needed (just validates calls).

local Runner = require("src.selftest.runner")
local Animation = require("src/animation")


local function run()
    local c = Runner.checks("animation")

    -- Define minimal states using actual assets
    local states = {
        idle = { path = "assets/sprites/Pink_Monster_Idle_4.png",  frames = 4, duration = 0.15 },
        walk = { path = "assets/sprites/Pink_Monster_Walk_6.png",  frames = 6, duration = 0.10 },
    }

    -- ─── Creation ─────────────────────────────────────────────────────────────
    local anim = Animation.new(states)
    c:truthy("Animation.new returns object", anim ~= nil)
    c:eq("initial state is nil", anim:getState(), nil)
    c:eq("initial direction is 1", anim.direction, 1)

    -- ─── setState basics ─────────────────────────────────────────────────────
    anim:setState("idle")
    c:eq("setState idle", anim:getState(), "idle")
    c:eq("anim direction still 1", anim.direction, 1)

    anim:setState("walk")
    c:eq("setState walk", anim:getState(), "walk")

    -- ─── setState idempotent (guard clause) ──────────────────────────────────
    -- Calling setState with same state should NOT restart animation
    local anim_walk = anim.anims["walk"].anim  -- the actual anim8 animation object
    anim_walk:gotoFrame(3)  -- jump to frame 3
    anim:setState("walk")   -- same state
    c:eq("setState same state does not restart", anim_walk.position, 3)

    -- ─── Invalid state warning ───────────────────────────────────────────────
    -- Should not crash, should print warning
    anim:setState("nonexistent")
    c:eq("invalid state leaves current state unchanged", anim:getState(), "walk")

    -- ─── setDirection ────────────────────────────────────────────────────────
    anim:setDirection(-1)
    c:eq("direction flips to -1", anim.direction, -1)
    anim:setDirection(1)
    c:eq("direction flips back to 1", anim.direction, 1)

    -- ─── update advances frames ──────────────────────────────────────────────
    anim:setState("idle")
    anim:update(0)  -- dt=0, no advance
    local frame1 = anim.anims["idle"].anim.position
    anim:update(0.2)  -- dt > duration (0.15), should advance
    local frame2 = anim.anims["idle"].anim.position
    c:truthy("update advances frame", frame2 > frame1)

    -- ─── draw doesn't crash (headless) ───────────────────────────────────────
    -- In headless mode, draw might not work, but shouldn't error
    local ok, err = pcall(function() anim:draw(0, 0) end)
    c:truthy("draw doesn't error", ok, err and ("error: " .. err) or "")

    -- ─── frame timing per state ──────────────────────────────────────────────
    anim:setState("walk")
    c:eq("walk has correct frame count", #anim.anims["walk"].anim.frames, 6)

    return c:summary()
end


return { run = run }