-- Gameplay rules that can be checked independently of rendering.

local Gameplay = {}

local function boxesOverlap(a, b)
    return a.x < b.x + b.width and a.x + a.width > b.x
       and a.y < b.y + b.height and a.y + a.height > b.y
end

function Gameplay.outcome(player, enemies, mapW, pitY)
    if player.x >= mapW - 64 then return "finish" end
    if player.y >= pitY then return "death" end

    for _, enemy in ipairs(enemies) do
        local contactBox = enemy.getContactBox and enemy:getContactBox() or enemy
        if boxesOverlap(player, contactBox) then return "death" end
    end

    return nil
end

function Gameplay.loseLife(state, lives, timer, deathDelay, gameoverDelay)
    if state ~= "playing" then return state, lives, timer end

    lives = lives - 1
    if lives > 0 then return "died", lives, deathDelay end
    return "game_over", lives, gameoverDelay
end

function Gameplay.advanceDeath(state, lives, timer, dt, initialLives)
    if state ~= "died" and state ~= "game_over" then
        return state, lives, timer, false
    end

    timer = timer - dt
    if timer > 0 then return state, lives, timer, false end

    if state == "game_over" then lives = initialLives end
    return "playing", lives, 0, true
end

return Gameplay
