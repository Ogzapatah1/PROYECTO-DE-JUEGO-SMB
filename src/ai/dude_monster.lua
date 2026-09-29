-- Movement decisions for one Dude Monster. The caller owns physics and terrain sensing.

local Behavior = {}

local PATROL_SPEED = 30
local ATTACK_SPEED = 45
local ATTACK_ENTER_DISTANCE = 128
local ATTACK_EXIT_DISTANCE = 176
local STOP_DISTANCE = 8

Behavior.MAX_SPEED = ATTACK_SPEED

function Behavior.decide(state, direction, playerDx, leftSafe, rightSafe)
    local function canGo(side)
        return (side < 0 and leftSafe) or (side > 0 and rightSafe)
    end

    if state == "attack" then
        if not playerDx or math.abs(playerDx) > ATTACK_EXIT_DISTANCE then
            state = "patrol"
        end
    elseif playerDx and math.abs(playerDx) <= ATTACK_ENTER_DISTANCE then
        state = "attack"
    end

    if state == "attack" then
        if playerDx > STOP_DISTANCE then
            direction = 1
        elseif playerDx < -STOP_DISTANCE then
            direction = -1
        else
            return state, direction, 0
        end

        return state, direction, canGo(direction) and ATTACK_SPEED or 0
    end

    if not canGo(direction) then
        if not canGo(-direction) then return state, direction, 0 end
        direction = -direction
    end

    return state, direction, PATROL_SPEED
end

return Behavior
