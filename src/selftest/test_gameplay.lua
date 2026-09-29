-- src/selftest/test_gameplay.lua
-- Checks contact, finish priority, and life-state transitions.

local Runner = require("src.selftest.runner")
local Enemy = require("src.entities.enemy")

local function run()
    local c = Runner.checks("gameplay")
    local ok, Gameplay = pcall(require, "src/gameplay")
    c:truthy("gameplay rules load", ok, tostring(Gameplay))
    if not ok then return c:summary() end

    local player = { x = 100, y = 100, width = 32, height = 32 }
    local enemy = { x = 120, y = 100, width = 32, height = 32 }
    c:eq("enemy overlap causes death", Gameplay.outcome(player, { enemy }, 640, 350), "death")

    enemy.x = 132 -- touching edges is not an overlap
    c:eq("adjacent boxes do not collide", Gameplay.outcome(player, { enemy }, 640, 350), nil)

    local dude = Enemy.new(126, 100)
    c:eq("outer enemy pixels do not hurt", Gameplay.outcome(player, { dude }, 640, 350), nil)
    dude.x = 125
    c:eq("inner enemy area still hurts", Gameplay.outcome(player, { dude }, 640, 350), "death")
    dude.x, dude.y = 100, 128
    c:eq("enemy feet outside contact area", Gameplay.outcome(player, { dude }, 640, 350), nil)
    dude.y = 127
    c:eq("enemy vertical contact still hurts", Gameplay.outcome(player, { dude }, 640, 350), "death")

    player.x = 576 -- stage finish begins at map width minus 64
    enemy.x = 576
    c:eq("finish wins simultaneous contact", Gameplay.outcome(player, { enemy }, 640, 350), "finish")

    player.x = 100
    player.y = 350
    enemy.x = 300
    c:eq("pit still causes death", Gameplay.outcome(player, { enemy }, 640, 350), "death")

    c:truthy("life transition available", type(Gameplay.loseLife) == "function")
    if type(Gameplay.loseLife) ~= "function" then return c:summary() end

    local state, lives, timer = Gameplay.loseLife("playing", 3, 0, 5, 6)
    c:eq("contact loses one life", lives, 2)
    c:eq("remaining lives show death screen", state, "died")
    c:eq("death screen delay", timer, 5)

    state, lives, timer = Gameplay.loseLife(state, lives, timer, 5, 6)
    c:eq("repeat contact cannot lose another life", lives, 2)

    state, lives, timer = Gameplay.loseLife("playing", 1, 0, 5, 6)
    c:eq("last life reaches zero", lives, 0)
    c:eq("last life shows game over", state, "game_over")
    c:eq("game-over delay", timer, 6)

    c:truthy("recovery transition available", type(Gameplay.advanceDeath) == "function")
    if type(Gameplay.advanceDeath) ~= "function" then return c:summary() end

    local respawn
    state, lives, timer, respawn = Gameplay.advanceDeath("died", 2, 5, 1, 3)
    c:eq("death screen remains during countdown", state, "died")
    c:eq("death countdown advances", timer, 4)
    c:falsy("no early respawn", respawn)

    state, lives, timer, respawn = Gameplay.advanceDeath("died", 2, 0.1, 0.2, 3)
    c:eq("death countdown returns to play", state, "playing")
    c:eq("respawn keeps remaining lives", lives, 2)
    c:truthy("respawn requested", respawn)

    state, lives, timer, respawn = Gameplay.advanceDeath("game_over", 0, 0.1, 0.2, 3)
    c:eq("game over returns to play", state, "playing")
    c:eq("game over restores initial lives", lives, 3)
    c:truthy("game over requests respawn", respawn)

    return c:summary()
end

return { run = run }
