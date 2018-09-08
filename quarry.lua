-- Quarry
--[[
    Mines a quarry of size specified by user. Run this code using
        "quarry length width height -f"
    where length, width, and height are the dimensions of the quarry and -f
    is an optional parameter: if provided, -f will make the robot mine in
    'fast' mode where it does not check for inventory efficiency. This will make
    it mine faster, but it may run out of inventory space before finishing the
    quarry.

    The robot mines the quarry relative to its start position. It must be placed
    in the bottom left corner 1 block above the desired location of the quarry,
    like so:

     _ _ _ _ _ _ _ _ _ _
    |                   |
    |                   |
    |    to-be-mined    |
    |      area         |
    |                   |
    |x _ _ _ _ _ _ _ _ _|

    where x is the start position of the robot, one block above where you
    actually want blocks to be mined.


    Note: if you are not using fast mode, it is recommended that you place 
    1 smooth stone, redstone ore, lapis lazuli ore, and coal ore in slots 3-6 
    in order to have good inventory efficiency (the robot compares mined blocks 
    to those in inventory to check if there is space for the mined block. It 
    can only compare the actual block directly to other actual blocks, rather 
    than comparing drops such as the redstone or coal items themselves).
--]]



-- Includes
local robot = require("robot")
local sides = require("sides")
local shell = require("shell")
local component = require("component")


-- Simplification of side names
local bottom = sides.bottom
local top = sides.top
local back = sides.back
local front = sides.front
local right = sides.right
local left = sides.left

-- Simplification of robot function names
local swing = robot.swing
local swingSide = component.robot.swing
local compareSide = component.robot.compare
local detectSide = component.robot.detect
local moveUp = robot.up
local moveDown = robot.down
local moveForward = robot.forward
local turnLeft = robot.turnLeft
local turnRight = robot.turnRight
local turnAround = robot.turnAround


-- Slot macros
first_mining_slot = 3

-- Exit macros
SUCCESS = 0
NO_TOOL = 1
NO_SPACE = 2
SWING_FAIL = 3
NO_BLOCK = 4
NO_TORCH = 5
PLACE_FAIL = 6
NOT_FOUND = 7
STUCK = 8



-- Attempts to mine block in front of robot
-- Returns SUCCESS on successful swing
-- Returns NO_TOOL if no tool equipped
-- Returns SWING_FAIL if swing failed (error or can't mine block with equipped
-- tool, e.g. iron pick mining obsidian)
-- Returns NO_BLOCK if no solid block in front of robot (e.g. liquid, air)
function safeSwing(side, fast)
    -- Return NO_TOOL if tool has broken (robot.durability will return 
    -- false)
    local durability, dur_message = robot.durability()
    if (not(durability) and dur_message == "no tool equipped") then
        return NO_TOOL
    end

    -- RETURN NO_BLOCK if block in front is not a solid block (e.g. liquid, air)
    if (not(detectSide(side))) then
        return NO_BLOCK
    -- Only do slot and swing checks if block in front is solid
    else
        -- Only do slot checks if fast mode is disabled
        if(not(fast)) then
            -- Check for any free slots in inventory
            free_slot = false
            for slot = first_mining_slot, robot.inventorySize() do
                -- If block to be mined is same as one in current slot, check if
                -- there is space in that slot for another block
                robot.select(slot)
                if (compareSide(side)) then
                    if (robot.space(slot) > 0) then
                        free_slot = true
                        break
                    end
                -- If block to be mined is not same as one in current slot, check if
                -- this slot is empty
                else
                    if (robot.count(slot) == 0) then
                        free_slot = true
                        break
                    end
                end
            end

            -- Return NO_SPACE if no free slots in inventory for block to be mined
            if (not(free_slot)) then
                return NO_SPACE
            end
        end

        -- Try to swing, if it fails return SWING_FAIL
        if (not(swingSide(side))) then
            return SWING_FAIL
        end
    end
    return SUCCESS
end


-- Moves forward and checks adjacent blocks for target if check is true
-- Returns STUCK when robot gets stuck and can't move forward (tries to mine
-- through obstacles 10 times first)
-- Returns SUCCESS on successful move
function moveForwardSafe()
    local stuck_count = 0
    -- If the forward move fails, try to break the block in front
    -- If this fails 10 times, give up and return STUCK 
    while (not(moveForward())) do
        safeSwing(front, fast)
        stuck_count = stuck_count + 1
        if (stuck_count == 10) then
            return STUCK
        end
    end

    return SUCCESS
end

-- Moves up and checks adjacent blocks for target if check is true
-- Returns STUCK when robot gets stuck and can't move up
-- Returns SUCCESS on successful move
function moveUpSafe()
    local stuck_count = 0
    -- If the move up fails, try to break the block above
    -- If this fails 10 times, give up and return STUCK 
    while (not(moveUp())) do
        -- Have to use component method to get robot to swing up
        safeSwing(top, fast)
        stuck_count = stuck_count + 1
        if (stuck_count == 10) then
            return STUCK
        end
    end

    return SUCCESS
end

-- Moves down and checks adjacent blocks for target if check is true
-- Returns STUCK when robot gets stuck and can't move down
-- Returns SUCCESS on successful move
function moveDownSafe()
    local stuck_count = 0
    -- If the move up fails, try to break the block below
    -- If this fails 10 times, give up and return STUCK 
    while (not(moveDown())) do
         -- Have to use component method to get robot to swing down
        safeSwing(bottom, fast)
        stuck_count = stuck_count + 1
        if (stuck_count == 10) then
            return STUCK
        end
    end

    return SUCCESS
end



function quarry(length, width, height, fast)
    local turndir = "right"
    local swing_code
    -- Mine a rectangular prism
    for z = 1, height do
        -- Mine a plane
        for x = 1, length do
            -- Mine a column
            for y = 1, width - 1 do
                swing_code = safeSwing(bottom, fast)
                if (swing_code == NO_TOOL) then
                    return NO_TOOL
                elseif (swing_code == NO_SPACE) then
                    return NO_SPACE
                end

                if (moveForwardSafe() == STUCK) then
                    return STUCK
                end
            end
            
            -- If last column, just mine block below
            if (x == length) then
                swing_code = safeSwing(bottom, fast)
                if (swing_code == NO_TOOL) then
                    return NO_TOOL
                elseif (swing_code == NO_SPACE) then
                    return NO_SPACE
                end
            -- If just finished odd column and not last column, turn right for next
            elseif (turndir == "right") then
                swing_code = safeSwing(bottom, fast)
                if (swing_code == NO_TOOL) then
                    return NO_TOOL
                elseif (swing_code == NO_SPACE) then
                    return NO_SPACE
                end
                turnRight()
                if (moveForwardSafe() == STUCK) then
                    return STUCK
                end
                turnRight()
                turndir = "left"
            -- Otherwise, turn left for next
            else
                swing_code = safeSwing(bottom, fast)
                if (swing_code == NO_TOOL) then
                    return NO_TOOL
                elseif (swing_code == NO_SPACE) then
                    return NO_SPACE
                end
                turnLeft()
                if (moveForwardSafe() == STUCK) then
                    return STUCK
                end
                turnLeft()
                turndir = "right"
            end
        end
        turnAround()
        moveDownSafe()

        -- If even length or even z level, then should start turning right
        if (z % 2 == 0 or length % 2 ~= 0) then
            turndir = "right"
        -- Otherwise, should start turning left
        else
            turndir = "left"
        end
    end
end

-- Parse arguments and run quarry with args as length, width, height
local args, ops = shell.parse(...)

local status  = quarry(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), ops["f"])

if (status == NO_TOOL) then
    error = "Tool broke!"
    print(error)
    return NO_TOOL
elseif (status == NO_SPACE) then
    error = "Out of Inventory Space!"
    print(error)
    return NO_SPACE
elseif (status == STUCK) then
    error = "Stuck!"
    print(error)
    return STUCK
end