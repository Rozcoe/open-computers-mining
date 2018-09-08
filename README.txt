OpenComputers Mining

This code is for use with the OpenComputers mod for Minecraft, which can be found here: 
Curseforge: https://minecraft.curseforge.com/projects/opencomputers
OpenComputers Website: https://ocdoc.cil.li/

All information for installing and using the mod can be found on Curseforge and on the OpenComputers website's "Tutorials" and "Getting started" sections




Description:
These three source files are to be used in your OpenComputers computers and allow your robot to perform useful mining functions so that
you can just send out your robots to do the tedious work.

Mine will mine out a branch mine for you and send signals back to your (optional) receiver computer when it finds a block that you're looking 
for (e.g. diamond ore)

Quarry will mine out a rectangular prism region with size defined by you. Quarry does not send any signals out, as it's just meant to blindly
mine out a region.

Receiver is meant to be placed on a remote computer, which is used to keep track of what's going on with all of your mining robots. When
one of them finds a target block or stops mining for whatever reason, a signal gets sent to the receiver computer so you can see what's
happening remotely. There is no limit to the number of mining robots you can have running and sending signals to your receiver at once.




Installation:
1. Create an OpenComputers robot in-game (using an assembler) with a wireless network card component and a navigation upgrade
	A youtube tutorial on creating a robot in-game can be found here: https://www.youtube.com/watch?v=jo9xrnDXhGg
	
2. Take note of the long string of characters that shows up when you mouse over the hard drive you are using (you will need it soon)

2. (Optional) If you would like more inventory space or for the robot to mine without players present in the chunk, make sure to add the relevant upgrades

3. Once the robot is assembled, open up Windows Explorer (outside of the game) and navigate to your game folder (usually C:\Users\your user name\AppData\Roaming\.minecraft
	For servers, navigate to your server folder
	
4. Find a folder with the same name as your world (e.g. 'New World' by default) and open it

5. Open the 'opencomputers' folder in here

6. Now, look for a folder with the same name as the long string of characters you took from the hard drive in-game before. Open that folder.

7. In here, open the 'home' folder

8. Place the 'mine.lua' and 'quarry.lua' source files here and you're done!

9. (Optional) If you are planning on actually receiving signals from the robot when a target block is found, navigate to the folder for your receiver computer's hard drive and place 'reciever.lua' in that home folder




Usage:
	Right-click and boot your robot/receiver computer and the .lua files should now be in your home directory. Simply type the name of the program you want to run (e.g. 'mine') to run it (see quarry usage notes for extra info)

	
	
	
	
	Mine:

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
	
	
	
	
	
	Quarry:
	
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
	
	
	
	
	
	
	Receiver
	
	This code is to be run on a 'receiver' computer, which receives signals
    from robots running either Mine or Quarry.

    It receives signals from the robots and prints out messages displaying what
    they have sent, along with the in-game time at which the signal was received
    and the name of the robot that sent the message.

    It also outputs a log of the messages to /home/log.txt (WARNING: this log 
    is wiped and overwritten each time Receiver is run)

    This program will continue looping and checking for signals until provided
    an interrupt (Ctrl+C)