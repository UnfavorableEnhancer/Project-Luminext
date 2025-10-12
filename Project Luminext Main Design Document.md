# Developers

- unfavorable_enhancer - Lead developer, Programmer, Artist and Game designer

# Description

Open-source recreation of old well known arcade puzzle game Lumines with many advanced mechanics and creativity features.

# Inspired by

- Lumines
- Osu
- DDR series
- Technictix
- Tetris Effect
- TGM series
- Tetr.io
- Gunpey-R (PSP)
- Flash Games
- Space Invaders Extreme
- Luxor Evolved
- and many other 2000s games I cant name

# Philosophy

1. Game doesn't have one defined art style, each artist/musician brings something new into the project. (Only menu have neutral art style)
2. This project is free for everyone to enjoy and contribute
3. Every aspect of original Lumines series must be improved in some way
4. Game should provide extensive modding tools to make it live forever
5. Game must feature possibilities for growth of strong competitive scene

# Main mechanics

Game allows to select and play with one of 4 main gamecores
Each gamecore has individual progress and gamemode setups, but skins and character unlocks are shared between all cores
#### Luminext

*Basics:*
- Player controls a piece of 2x2 blocks of different colors
- Placing blocks in 2x2 formation creates a square
- Timeline moves from left to right with music rhythm (BPM) and deletes all squares and their blocks which it passes
- After square or block is deleted, player score is increased
- If more than 4 and 16 and 32 squares were erased, score increase is multiplied by x4, x16 and x32 respectively and bonus points are awarded.
- If more than 4 squares are erased on several timeline passes. Each timeline pass increases combo meter, which multiplies all score increase with limit of x32.
- If more than 4 squares are erased on timeline pass, bonus score is awarded.
- Player can select between any of 3 pieces in queue

*Blocks:*
- Red, white, green and purple regular block colors
- Multi block can combine into square with any block color
- Garbage block cannot be squared, but destroys after adjacent block is deleted
- Dark block cannot be erased at all
- Chaos block changes its color every timeline pass
- Gold block multiplies square group score by 2 if placed inside square (behaves like multi block). Gold block always can be deleted by timeline, but gives nothing if not squared.
- Special blocks are given to player after some amount of pieces is placed:
	- Chain - removes all connected adjacent blocks of same color
	- Merge - turns all blocks in 3x3 grid into same color
	- Bomb - explodes all blocks in 3x3 grid
	- Laser - removes all block in several lines
	- Wipe - removes all blocks of same color in 5x5 grid
	- Stop - pauses timeline movement for few seconds
	- Slow - slows down timeline movement for few seconds
	- Locker - turns all blocks into garbage ones in 5x5 grid if squared (behaves like multi block). Disappears after 3 timeline passes.
	- Shuffle - randomizes color of blocks in 5x5 area when landed
	- Sort  - places all blocks in 5x5 area of single color at top and all blocks of other color at the bottom
 
 *Gimmicks*
- Block Rain - causes blocks fall from the top of the game field
- Field Rotation - rotates whole game field. Block gravity stays the same way
- Custom Pieces - allow for pieces of different forms than 2x2
- Block Aging - turns block into dark blocks after several timeline passes
- Timeline Speed - is determined by song BPM and can be variable through the skin
- Block Grow - spawns blocks from the bottom of game field, pushing everything upwards
- Darkness Grow - spawns dark blocks from the bottom of game field, pushing everything upwards
- Piece Ghosting - makes piece invisible after few seconds
- Blindness - turns all blocks into same color after several timeline passes
- Auto rotation - blocks starts rotating on they own
- Reversed controls - controls are reversed
- Custom board size - Allows to set any board size

*Abilities*
Player have three slots into which he can assign:
 - Up to two passive abilities
 - Up to one active ability

Passive abilities doesn't need charging but in general pretty weak:
- Queue Shift - allows to swap current piece in hand with next in queue
- Piece Save - allows to store current piece for future use
- Instant Special - makes all special blocks work instantly on land
- Easy Mode - piece stays twice as longer before start falling, but all incoming score is halved and rank cannot go higher than B (Nice!)
- Combo Amplifier [Unlocked for beating mission] - allows to use x64 combo multiplier
- Roundabout [Unlocked for beating mission] - allows piece to come out of opposite side of playfield 
- Accelerator  [Unlocked for beating mission] - active ability gauge charges 2 times faster but piece fall speed is also 3 times faster
- Checker Ban  [Unlocked for beating mission] - no checker patterned pieces in queue but piece fall speed is 4 times faster
- Plus Module [Unlocked for 100% Puzzle mode] - allows to build pluses which multiply all incoming score by 2. Player can hold up to 5 pluses (x10 score multiplier) but they all break when combo is broken too
- Extend Extra [Unlocked for surviving Adventure mode killscreen for one full playback] - clears whole game field if piece is placed at the top, works only once per run

Active abilities are charged by squares deletion and are quite powerful:
- Give Special *(20 charges)* - instantly turns one of blocks in piece into special one
- Queue Hack *(32 charges)* - turns 5 pieces in queue into single colored ones
- Blast Piece *(48 charges)* - turns current piece into special blast piece which destroys all blocks in huge radius
- Field Cleaner *(48 charges)* - removes first 3 lines of blocks from bottom of the field
- Score Amplifier *(48 charges)* [Unlocked for beating mission] - doubles amount of squares gained for three timeline passes (doesn't double ability charge gain)
- Cannon *(32 charges)* [Unlocked for beating mission] - turns piece handler into a cannon which can fire multiple shots to destroy blocks
- Chaos Stabilizer *(64 charges)* [Unlocked for beating mission] - removes all dark and chaos blocks
- Multification *(48 charges)* [Unlocked for beating mission] - turns random blocks on game field into multi blocks and turns all blocks in queue into multi blocks
- Time Control *(100 charges)* [Unlocked for 100% Time Attack mode] - stops timeline movement and piece falling for few seconds
- Total Merge *(100 charges)* [Unlocked for 100% Mission mode] - turns all blocks into single color
# Gamemodes
#### Singleplayer gamemodes

-  *Adventure mode*
	- Player completes a series of skins with gradually increasing difficulty. 
	- After reaching the end of skins series, game loops back to the first skin and new **lap** is started.
	- There are always 3 laps minimum in each adventure:
		- Start - Only piece drop speed increase and maybe some special blocks toggle
		- Advance - Some serious gimmicks could be enabled
		- Excellence - Hard gimmicks and very big piece drop speeds
	- After player finishes all 3 laps, they approach a **killscreen** which is one unique and infinite skin. After that only piece drop speed will be increasing and only few gimmicks will occur.
	- Player can select either completing each lap individually (then game will end on lap finish) or try a marathon a beat all laps together. New laps can be unlocked only in marathon.
	- Adventure can also feature several **challenge laps**. Each challenge lap usually revolve around one hard gimmick set to the length of the entiere adventure (like making field upside down and etc.).
	- There's always a **master lap** in each adventure. It's unlocked only after finishing all 3 standard and all challenge laps. It features hardest possible difficulty.
- *Playlist mode*
	- Player creates own playlist from any of the unlocked skins and play them with any game rules he wants.
- *Time Attack mode*
	- Player must build as many squares as possible within time limit. 
	- Skin BPM is always 120 BPM. Player can select any other skin but only 120 BPM skins can participate in ranking.
	- Avaiable time limits:
		- 60 sec
		- 120 sec
		- 180 sec
		- 300 sec
		- 600 sec
		- Custom sec - Can be any player desire (max 9999), but isn't saved in online leaderboards
	- Avaiable game rulesets:
		- Standard - Main Project Luminext rules
		- Classic - Rules which mimic Lumines Remastered gameplay
		- Arcade - Rules with all special blocks enabled
		- 3 Color - Rules with 3 block colors enabled and some helping special blocks
		- Hardcore - Rules with garbage and chaos blocks
- *Puzzle mode*
	- Player completes one of the available puzzle sequences. 
	- Each puzzle sequence features a series of small puzzles which must be beaten sequentially in time limit. 
	- Time limit extends on each small puzzle solve and skin visuals and music changes too.
	- Available puzzle categories:
		- Shape-in - Player builds a specified shape using same-colored blocks
		- Stack-down - Player is given with set piece queue and must use all pieces and leave field clear
		- Clean-up - Player must clear part or whole field from blocks
		- Freestyle - Goals are combined (like you need to build a figure first and then erase it) 
	- Custom puzzles can be made and exported into clipboard to be put into Discord as emoji art.
- *Mission mode*
	- Player completes one of the available missions. 
	- Each mission unlocks content of its type and are very difficult to beat. They usually use very obscure and weird mechanics.
	- Mission could be one of three types: 
		- Ability mission - Shows player how to use ability this mission unlocks
		- Character mission - Revolves around "saving" featured character from a huge danger (skin with major gimmick applied)
		- Skin mission - Showcases skin this mission unlocks with heavy gimmick put on
		  
			***Skin missions***
		1. 180 degrees (get 180 squares in 180 sec with field rotated by 180 degrees) [Unlocks bonus skin]
		2. Full darkness (survive for 120 secs with piece and blocks disappearing) [Unlocks bonus skin]
		3. Tetr**? (get score 1000000 with tetris pieces) [Unlocks bonus skin]
		4. Diggin' (trigger all clear bonus with almost fully fulled field in 300 sec) [Unlocks bonus skin]
		5. Clockworking (get score 500000 in 90 sec with piece rotating on its own, player cannot rotate piece) [Unlocks bonus skin]
		   
			***Passive ability missions***
		6. too much BPM (get 4 combo in 90 sec at 400 BPM) [Unlocks Combo Amplifier ability]
		7. G220 (get 220 squares in 220 sec with max piece fall speed) [Unlocks Accelerator ability]
		8. Absolute chain (trigger single color and full screen bonuses simultaneously in 90 sec) [Unlocks Roundabout ability]
		9. Overcheckered (fill whole game field with checkerboard pattern in 180 sec) [Unlocks Checker Ban ability]
		   
			***Active ability missions***
		10. Big things (score 1000000 with 3x3 pieces in 120 sec) [Unlocks Score Amplifier ability]
		11. Stack invaders (destroy all forming from bottom of the game field squares with cannon ability for 90 sec) [Unlocks Cannon ability]
		12. Heavy metal (create 100 dark blocks using locker blocks in 180 sec, all 100 dark blocks must be on game field) [Unlocks Chaos Stabilizer ability]
		13. 64x (build a square group of 64 squares and delete it in 120 sec) [Unlocks Multification ability]
		
			***Character missions***
		14. 4x4 (get 16 squares in 60 sec with all block colors enabled) [Unlocks bonus character]
		15. fin (survive for 120 sec with board size of 4x12) [Unlocks bonus character]
		16. wiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiide (survive for 120 sec with board size of 12x4) [Unlocks bonus character]
		17. Complete chaos (get 120 squares for 120 sec with all blocks being chaos blocks) [Unlocks bonus character]
		18. Best of 2012 (get 64 squares in 90 sec, each 3 pieces has shuffle block) [Unlocks bonus character]
		19. Handlocked (get 120 squares in 60 sec with piece rotation disabled) [Unlocks bonus character]
		20. Running out time (survive for 120 secs with blocks slowly turning to dark blocks, game field must be clear by the end of the run) [Unlocks bonus character]
- *Synthesia mode*
	- Player can play with own music and with any of selected block/sound/visualizer sets.
- *Practice mode*
	- Player can complete a tutorial sequence which teaches with basic game mechanics.
	- Also player can infinitely train one of available stack patterns.
- *Custom mode*
	- User made gamemodes browser

# Avaiable content
#### Total
- 30 skins
- 30 characters
- 20 abilities
- 50 puzzle sequences
- 7 gamemodes

- 20 adventure skins
- 2 time attack skins (for 60-180 sec and 300-600 sec)
- 1 puzzle mode skin
- 1 tutorial skin
- 8 bonus skins
	- 3 adventure lap completion (including killscreen skin)
	- 5 mission skins
- 42 characters
	- 5 avaiable from start
	- 30 unlocked by achievements
	- 7 unlocked by beating missions

# Progression system

#### Ranking system

Each gamemode (except Playlist and Synthesia) gives player a rank depending on how well he completed the gamemode goal
All gamemodes use same ranks:
+ *(E) E*  [0%] -  Given for especially bad gameplay and serves mostly an easter egg purpose
+ *(D) Duh*  [25%] -  Given for bad gameplay, player most likely just rushed this gamemode to just beat it
+ *(C) OK*  [50%] -  Given for OK gameplay, player don't understand mechanics yet but making good progress
+ *(B) Nice!*  [75%] -  Given for good gameplay, player do everything well, but many things could be improved
+ *(A) Awesome!!* [100%] -  Given for really good gameplay, player plays very well but makes some mistakes
+ ***(S) Excellent.***  [101%] -  Given for masterpiece gameplay
+ ***(M) Magnificent*** [120%] - Given for impossible gameplay

Total game percentage is calculated by taking a median of all given by ranks progress percentages. 

Player can view requirements for unlocking most of the characters, gamemodes, skins and etc. in Achievements menu.
However some skins, characters and etc. are fully secret.

# Modding capabilites

- Skin editor - allows to create own skins with full animated background scenery, custom textures, music and etc.
- Avatar editor - allows to create and animate own avatar
- Addon editor - allows to bundle multiple skins and avatars into single bundle with custom progression system
- Adventure editor - allows to create custom adventures
- Puzzle editor - allows to easily create and share new puzzles
- Skin player - allows to play and watch any skin without gameplay
- Replay player - allows to replay recorded player gameplay
- Custom gamemodes - users would be able to code own simple gamemodes
- Custom gamecores - users would be able to replace base gameplay with any other
- Custom menus - users would be able to launch the game with custom menu

# Development roadmap

*Must do*
1) 0.1 - Initial public pre-release. Playlist mode/Time attack mode/Sythesia mode
2) 0.11 - Replay recording/Online leaderboards + Translations support
3) 0.2 - Practice mode/QOL fixes and improvements + Code rewrite
4) 0.3 - Adventure mode/Gimmicks + Adventure editor
5) 0.4 - Puzzle mode
6) 0.5 - Avatars + Avatar editor
7) 0.6 - Addon editor
8) 0.7 - Abilities
9) 0.8 - Mission mode
10) 0.9 - Custom gamemodes and more modding enhacements
11) 1.0 - Release
*Should do*
12) 1.1 - Endurance mode
13) 1.2 - VS CPU mode + Local VS 2P mode
14) 1.3 - Tetris gamecore (only for playlist & time attack mode)
*Maybe...*
15) 1.4 - Advanced skin editor
16) 1.5 - Multiplayer gamemodes