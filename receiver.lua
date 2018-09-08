-- Receiver
--[[
    This code is to be run on a 'receiver' computer, which receives signals
    from robots running either Mine or Quarry.

    It receives signals from the robots and prints out messages displaying what
    they have sent, along with the in-game time at which the signal was received
    and the name of the robot that sent the message.

    It also outputs a log of the messages to /home/log.txt (WARNING: this log 
    is wiped and overwritten each time Receiver is run)

    This program will continue looping and checking for signals until provided
    an interrupt (Ctrl+C)
--]]



-- Includes
local component = require("component")
local event = require("event")
local filesystem = require("filesystem")
local modem = component.modem


-- Port macro
RECEIVE_PORT = 123


modem.setStrength(10000)

-- Open port
modem.open(RECEIVE_PORT)

if filesystem.exists("/home/log.txt") then
    filesystem.remove("/home/log.txt")
end
local file = filesystem.open("/home/log.txt", "w")

-- Keep looping, waiting for a signal
while (true) do
    -- Wait for signal on port
    local _, _, from, port, _, robot, x, y, z = event.pull("modem_message")
    -- Print out robot name and location of found target ore (or error message)
    local logentry
    -- x will be the string "ERROR" if the mining robot sends an error; y will
    -- be the error message
    if (not(x)) then
        logentry = os.date("%c ") .. robot .. " found target ore out of range"
    elseif(type(x) == "string") then
        logentry = os.date("%c ") .. robot .. " " .. x .. ": " .. y
    else
        logentry = os.date("%c ") .. robot .. " found target ore at X:" .. x .. " Y:" .. y .. " Z:" .. z
    end
    print(logentry)
    file:write(logentry)
end

-- Close port
modem.close(RECEIVE_PORT)

file:close()