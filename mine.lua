-- Mine
--[[ 
    Creates a branch mine while searching for a provided target block and 
    sending a signal to a receiver computer when it is found.

    The robot REQUIRES a wireless network card and navigation module for this
    code to function. A computer with a wireless network card to receive signals
    from the robot is required if you want anything to actually receive the
    'target block found' signals.

    This mines 2x3x6 'spacer tunnels' between 2x3x64 'branch tunnels'. A top-
    down view of the tunnel layout below:

    x = robot start position
    t = torch placement

     ... _ _ _ _ _ _ _ _ _ _ _ _ 
    |    _ _ _ _ _ _ _ t _ _ _ _ ... 64 blocks out
    |  t|
    |   |
    |   |
    |   |
    |   |
    |   |
    |   |_ _ _ _ _ _ _ _ _ _ _ _ 
    |    _ _ _ _ _ _ _ t _ _ _ _ ... 64 blocks out
    |  t|
    |   |
    |   |
    |   |
    |   |
    |   |
       x

    Cross-section of spacer tunnel:
     _ _
    |  t|
    |   |
    |_ x|

    Cross-section of branch tunnel:
     _
    |t|
    | |
    |_|


    The robot will place torches in the spots marked in the diagram (provided
    torches are supplied in torch_slot (default slot 1)) and will
    produce the tunnels relative to the block marked with an x on the diagram.

    The robot will search adjacent blocks for the target block supplied to
    target_slot (default slot 2). When this block is found, the robot will
    broadcast a wireless signal to any receiving computers on SEND_PORT (default
    port 123) containing the XYZ coordinates from the navigation module
    (relative to the location where the map for the navigation module was 
    created). If out of range of the navigation module's coordinates, the
    robot will report finding the target block 'out of range'.

    The robot will continue mining spacer and branch tunnels until either its
    tool breaks, it runs out of inventory space to hold mined blocks, or it
    gets 'stuck', meaning that something is blocking its movement that it get
    through after attempting to break through 8 times. When it does stop mining,
    it will broadcast a signal on SEND_PORT (default port 123) with an error
    message explaining why.

    Note: it is recommended that you place 1 smooth stone, redstone ore, lapis 
    lazuli ore, and coal ore in slots 3-6 in order to have good inventory
    efficiency (the robot compares mined blocks to those in inventory to check
    if there is space for the mined block. It can only compare the actual block
    directly to other actual blocks, rather than comparing drops such as the
    redstone or coal items themselves).
--]]


-- Includes
local robot = require("robot")
local sides = require("sides")
local component = require("component")
local modem = component.modem
local navigation = component.navigation

-- Simplification of robot function names
local swing = robot.swing
local place = robot.place
local compareSide = component.robot.compare
local moveUp = robot.up
local moveDown = robot.down
local moveForward = robot.forward
local turnLeft = robot.turnLeft
local turnRight = robot.turnRight
local turnAround = robot.turnAround

-- Simplification of side names
local bottom = sides.bottom
local top = sides.top
local back = sides.back
local front = sides.front
local right = sides.right
local left = sides.left

-- Port macro
SEND_PORT = 123

-- Slot macros
torch_slot = 1
target_slot = 2
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


-- Compares all blocks adjacent to robot to block in target_slot
-- Returns SUCCESS and prints "Target found!" if block is found
-- Returns NOT_FOUND if target block is not found adjacent to robot
function checkBlocks()
        local found_status = NOT_FOUND

        -- Select target slot to compare blocks to
        robot.select(target_slot)

        -- Compare only works with bottom, top, and front :/
        if (compareSide(bottom) or compareSide(top) or compareSide(front)) then
            local x, y, z = navigation.getPosition()

            -- If x is not nil, target was found within range of nav upgrade
            if (x) then
                print("Target found at " .. "X:" .. x .. " Y:" .. y .. " Z:" .. z)
            else
                print("Target found out of range")
            end
            modem.broadcast(SEND_PORT, robot.name(), x, y, z)
            found_status = SUCCESS
        end

        -- Turn the robot in a circle and check front each time
        for i = 1, 3 do
            turnRight()
            if (compareSide(front)) then
                local x, y, z = navigation.getPosition()
                
                -- If x is not nil, target was found within range of nav upgrade
                if (x) then
                    print("Target found at " .. "X:" .. x .. " Y:" .. y .. " Z:" .. z)
                else
                    print("Target found out of range")
                end
                modem.broadcast(SEND_PORT, robot.name(), x, y, z)
                found_status = SUCCESS
            end
        end
        turnRight()

        return found_status
end

-- Moves forward and checks adjacent blocks for target if check is true
-- Returns STUCK when robot gets stuck and can't move forward (tries to mine
-- through obstacles 10 times first)
-- Returns SUCCESS on successful move
function moveForwardSafe(check)
    local stuck_count = 0
    -- If the forward move fails, try to break the block in front
    -- If this fails 10 times, give up and return STUCK 
    while (not(moveForward())) do
        safeSwing()
        stuck_count = stuck_count + 1
        if (stuck_count == 10) then
            return STUCK
        end
    end

    -- Check blocks around robot for target block
    if (check) then
        checkBlocks()
    end
    return SUCCESS
end

-- Moves up and checks adjacent blocks for target if check is true
-- Returns STUCK when robot gets stuck and can't move up
-- Returns SUCCESS on successful move
function moveUpSafe(check)
    local stuck_count = 0
    -- If the move up fails, try to break the block above
    -- If this fails 10 times, give up and return STUCK 
    while (not(moveUp())) do
        -- Have to use component method to get robot to swing up
        component.robot.swing(top)
        stuck_count = stuck_count + 1
        if (stuck_count == 10) then
            return STUCK
        end
    end

    -- Check blocks around robot for target block
    if (check) then
        checkBlocks()
    end
    return SUCCESS
end

-- Moves down and checks adjacent blocks for target if check is true
-- Returns STUCK when robot gets stuck and can't move down
-- Returns SUCCESS on successful move
function moveDownSafe(check)
    local stuck_count = 0
    -- If the move up fails, try to break the block below
    -- If this fails 10 times, give up and return STUCK 
    while (not(moveDown())) do
         -- Have to use component method to get robot to swing down
        component.robot.swing(bottom)
        stuck_count = stuck_count + 1
        if (stuck_count == 10) then
            return STUCK
        end
    end

    -- Check blocks around robot for target block
    if (check) then
        checkBlocks()
    end
    return SUCCESS
end

-- Attempts to mine block in front of robot
-- Returns SUCCESS on successful swing
-- Returns NO_TOOL if no tool equipped
-- Returns SWING_FAIL if swing failed (error or can't mine block with equipped
-- tool, e.g. iron pick mining obsidian)
-- Returns NO_BLOCK if no solid block in front of robot (e.g. liquid, air)
function safeSwing()
    -- Return NO_TOOL if tool has broken (robot.durability will return 
    -- false)
    local durability, dur_message = robot.durability()
    if (not(durability) and dur_message == "no tool equipped") then
        return NO_TOOL
    end

    -- RETURN NO_BLOCK if block in front is not a solid block (e.g. liquid, air)
    if (select(2, robot.detect()) ~= "solid") then
        return NO_BLOCK
    -- Only do slot and swing checks if block in front is solid
    else
        -- Check for any free slots in inventory
        free_slot = false
        for slot = first_mining_slot, robot.inventorySize() do
            -- If block to be mined is same as one in current slot, check if
            -- there is space in that slot for another block
            robot.select(slot)
            if (robot.compare()) then
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

        -- Try to swing, if it fails return SWING_FAIL
        if (not(swing())) then
            return SWING_FAIL
        end
    end
    return SUCCESS
end

-- Tries to place a torch in front of robot
-- Returns NO_TORCH if no torches in slot 1
-- Returns PLACE_FAIL if place failed (error, not enough space, or no wall to
-- place on)
-- TODO: add network signal for torch fail
function placeTorch()
    -- Return NO_TORCH if nothing in slot 1 (torch slot)
    if (robot.count(1) == 0) then
        return NO_TORCH
    end

    -- Select torch slot
    robot.select(torch_slot)
    -- Return PLACE_FAIL if place failed
    if (not(place())) then
        return PLACE_FAIL
    end

    return SUCCESS
end

-- Mine 1x3 space in front of robot, starting at robot's height and ending
-- two blocks above
-- Returns NO_TOOL before finishing column if tool breaks
-- Returns NO_SPACE before finishing column if robot runs out of inv space
function mineUp()
    local swing_code = safeSwing()
    if (swing_code == NO_TOOL) then
        return NO_TOOL
    elseif (swing_code == NO_SPACE) then
        return NO_SPACE
    end

    if (moveUpSafe(true) == STUCK) then
        return STUCK
    end

    swing_code = safeSwing()
    if (swing_code == NO_TOOL) then
        return NO_TOOL
    elseif (swing_code == NO_SPACE) then
        return NO_SPACE
    end

    if (moveUpSafe(true) == STUCK) then
        return STUCK
    end

    swing_code = safeSwing()
    if (swing_code == NO_TOOL) then
        return NO_TOOL
    elseif (swing_code == NO_SPACE) then
        return NO_SPACE
    end

    return SUCCESS
end

-- Mine 1x3 space in front of robot, starting at robot's height and ending
-- two blocks below
-- Returns NO_TOOL before finishing column if tool breaks
-- Returns NO_SPACE before finishing column if robot runs out of inv space
function mineDown()
    local swing_code = safeSwing()
    if (swing_code == NO_TOOL) then
        return NO_TOOL
    elseif (swing_code == NO_SPACE) then
        return NO_SPACE
    end

    if (moveDownSafe(true) == STUCK) then
        return STUCK
    end

    swing_code = safeSwing()
    if (swing_code == NO_TOOL) then
        return NO_TOOL
    elseif (swing_code == NO_SPACE) then
        return NO_SPACE
    end

    if (moveDownSafe(true) == STUCK) then
        return STUCK
    end

    swing_code = safeSwing()
    if (swing_code == NO_TOOL) then
        return NO_TOOL
    elseif (swing_code == NO_SPACE) then
        return NO_SPACE
    end

    return SUCCESS
end


-- Strafe left 1 block
function strafeLeft()
    turnLeft()
    moveForwardSafe(true)
    turnRight()
end

-- Strafe right 1 block
function strafeRight()
    turnRight()
    moveForwardSafe(true)
    turnLeft()
end


-- Mine a spacer tunnel between branches, including torch
-- Returns NO_TOOL when tool breaks
-- Returns NO_SPACE when robot runs out of inv space
-- Returns SUCCESS on success
function mineSpacer()
    local status
    -- Mine 6 2x3 spaces forward, starting at bottom right block
    for i = 1, 6 do
        status = mineUp()
        -- Return now if mineUp failed
        if (status == NO_TOOL) then
            return NO_TOOL
        elseif (status == NO_SPACE) then
            return NO_SPACE
        elseif (status == STUCK) then
            return STUCK
        end 

        -- Strafe left for even blocks in space, strafe right for odd
        if (i % 2 ~= 0) then
            strafeLeft()
        else
            strafeRight()
        end

        status = mineDown()
        -- Return now if mineDown failed
        if (status == NO_TOOL) then
            return NO_TOOL
        elseif (status == NO_SPACE) then
            return NO_SPACE
        elseif (status == STUCK) then
            return STUCK
        end 
        moveForwardSafe(true)
    end

    -- Place torch on right wall
    strafeLeft()
    turnRight()

    if (moveUpSafe(false) == STUCK) then
        return STUCK
    end

    if (moveUpSafe(false) == STUCK) then
        return STUCK
    end

    placeTorch()

    -- Mine another 2x3 space, avoiding the torch block
    turnLeft()

    status = mineDown()
     -- Return now if mineDown failed
    if (status == NO_TOOL) then
        return NO_TOOL
    elseif (status == NO_SPACE) then
        return NO_SPACE
    elseif (status == STUCK) then
        return STUCK
    end 

    moveForwardSafe(true)
    turnRight()

    status = mineUp()
    -- Return now if mineUp failed
    if (status == NO_TOOL) then
        return NO_TOOL
    elseif (status == NO_SPACE) then
        return NO_SPACE
    elseif (status == STUCK) then
        return STUCK
    end

    moveForwardSafe(true)

    return SUCCESS
end


-- Mine a branch
-- Returns NO_TOOL when tool breaks
-- Returns NO_SPACE when robot runs out of inv space
-- Returns SUCCESS on success
function mineBranch()
    local status
    -- Mine 64 1x3 spaces forward in groups of 8
    for i = 1, 8 do
        -- Mine 8 1x3 spaces forward (in pairs), starting at top block
        for i = 1, 4 do
            status = mineDown()
            -- Return now if mineDown failed
            if (status == NO_TOOL) then
                return NO_TOOL
            elseif (status == NO_SPACE) then
                return NO_SPACE
            elseif (status == STUCK) then
                return STUCK
            end 

            moveForwardSafe(true)

            status = mineUp()
            -- Return now if mineUp failed
            if (status == NO_TOOL) then
                return NO_TOOL
            elseif (status == NO_SPACE) then
                return NO_SPACE
            elseif (status == STUCK) then
                return STUCK
            end 

            moveForwardSafe(true)
        end

        -- Turn around and place a torch on the block behind, then turn back
        turnAround()
        placeTorch()
        turnAround()
    end

    -- Turn around and return to spacer tunnel
    turnAround()

    if (moveDownSafe(true) == STUCK) then
        return STUCK
    end
    
    if (moveDownSafe(true) == STUCK) then
        return STUCK
    end
    for i = 1, 64 do
        moveForwardSafe(false)
    end
    turnRight()
    
    return SUCCESS
end



-- Main loop; keep mining spacers and branches until something goes wrong
-- Returns NO_TOOL when tool breaks
-- Returns NO_SPACE when robot runs out of inv space
-- Returns STUCK when robot gets stuck
function mine()
    local status
    local error
    
    while(true) do
        status = mineSpacer()
        if (status == NO_TOOL) then
            error = "Tool broke!"
            print(error)
            modem.broadcast(SEND_PORT, robot.name(), "ERROR", error)
            return NO_TOOL
        elseif (status == NO_SPACE) then
            error = "Out of Inventory Space!"
            print(error)
            modem.broadcast(SEND_PORT, robot.name(), "ERROR", error)
            return NO_SPACE
        elseif (status == STUCK) then
            error = "Stuck!"
            print(error)
            modem.broadcast(SEND_PORT, robot.name(), "ERROR", error)
            return STUCK
        end

        status = mineBranch()
        if (status == NO_TOOL) then
            error = "Tool broke!"
            print(error)
            modem.broadcast(SEND_PORT, robot.name(), "ERROR", error)
            return NO_TOOL
        elseif (status == NO_SPACE) then
            error = "Out of Inventory Space!"
            print(error)
            modem.broadcast(SEND_PORT, robot.name(), "ERROR", error)
            return NO_SPACE
        elseif (status == STUCK) then
            error = "Stuck!"
            print(error)
            modem.broadcast(SEND_PORT, robot.name(), "ERROR", error)
            return STUCK
        end
    end
end

modem.setStrength(10000)
mine()