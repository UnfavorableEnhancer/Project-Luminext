# Project Luminext - an advanced open-source Lumines spiritual successor
# Copyright (C) <2024-2025> <unfavorable_enhancer>
# Contact : <random.likes.apes@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


extends GameCore

class_name LuminextGame

##-----------------------------------------------------------------------
## Main script which controls 'Lumines-like' gameplay
##-----------------------------------------------------------------------

signal new_piece_is_given ## Emmited when player gets new piece
signal timeline_started ## Emmited when new timeline starts from beginning of game field

const TIMELINE_SCENE : PackedScene = preload("res://scenery/game/timeline.tscn") ## Timeline scene instance
const SQUARE_SCENE : PackedScene = preload("res://scenery/game/square.tscn") ## Square scene instance

const TIMELINE_Z_INDEX : int = -70
const BLAST_Z_INDEX : int = -201
const REMOVING_BLOCK_Z_INDEX : int = -202
const GHOSTS_Z_INDEX : int = -250
const BLOCK_OVERLAY_Z_INDEX : int = -300
const BLOCK_DELETE_OVERLAY_Z_INDEX : int = -501
const PIECE_Z_INDEX : int = -502
const SPECIAL_BLOCKS_Z_INDEX : int = -503
const BLOCKS_Z_INDEX : int = -504

const REAL_CELL_SIZE : float = 64.0 ## Actual size of single cell in pixels
const CELL_MARGIN : float = 4.0 ## Distance between cells in pixels
const CELL_SIZE : float = REAL_CELL_SIZE + CELL_MARGIN ## Size of single cell in pixels

const FIELD_X_OFFSET : float = 416.0 ## Game field base X offset in pixels
const FIELD_Y_OFFSET : float = 200.0 ## Game field base Y offset in pixels

enum BORDER {LEFT = 0, RIGHT = 15, TOP = 0, BOTTOM = 9} ## Game field borders grid coordinates

var square_check_area : Dictionary [Vector2i, bool] = {} ## All block positions which needs to be checked for squares

var is_timeline_active : bool = true ## If true, timeline spawns on each skin music sample end
var is_giving_pieces_to_player : bool = true ## If true, each time new piece is added to queue, latest one will be given to player's hands

var blocks : Dictionary[Vector2i, Block] = {} ## All existing on the game field blocks [br] [position : Vector2i] = [Block]
var squares : Dictionary[Vector2i, Square] = {} ## All existing on the game field squares [br] [position : Vector2i] = [Square]

var new_squares : Dictionary[Vector2i, Square] = {} ## All new created squares in current physics tick
var is_adding_square_number : bool = false ## True if square number is added

var ghosts : Array[Node2D] = [] ## All ghosts (blocks or squares) on the game field

var timeline : Node2D = null # Current timeline, removes deletable blocks and squares

var piece : Piece = null ## Current piece in player's hands
var piece_fall_delay : float = 1.0 ## Delay in seconds before piece fall one cell down
var piece_fall_start_delay : float = 1.0 ## Delay in seconds before piece starts auto falling

var piece_queue : PieceQueue ## Piece queue reference, contains pieces to be given in player hands next


func _init() -> void:
	gamecore_name = "Luminext"


func _ready() -> void:
	name = "Luminext"

	reset_started.connect(_on_reset_started)
	paused.connect(_on_pause)

	piece_queue = PieceQueue.new()
	piece_queue.name = "PieceQueue"
	piece_queue.game = self
	piece_queue.ruleset = gamemode.ruleset
	piece_queue.size = Vector2(144, 476)
	piece_queue.position = Vector2(124, 140)
	
	piece_queue.z_as_relative = false
	piece_queue.z_index = GAMEFIELD_Z_INDEX
	add_child(piece_queue)

	super()

	gamefield.position = Vector2(FIELD_X_OFFSET, FIELD_Y_OFFSET)


## Called on game reset start
func _on_reset_started() -> void:
	_clear_field()
	_clear_ghosts()
	
	if timeline != null : timeline.queue_free()
	timeline = null

	if piece != null : piece.queue_free()
	piece = null

	piece_queue._clear()


## Called on pause state change
func _on_pause(on : bool) -> void:
	if timeline != null : timeline.is_paused = on


## Processes single game tick
func _tick(delta : float = TICK) -> void:
	for action : StringName in current_input.keys():
		if (action != &"pause" and input_lock[action] == true) : continue
		if Input.is_action_just_pressed(action) : current_input[action] = true
		if Input.is_action_just_released(action) : current_input[action] = false

	if _is_action_pressed("pause") : 
		if not is_paused : _pause(true)
		else : _pause(false)

	if not is_paused :
		replay._tick()

		if piece : piece._physics(delta)
		if timeline : timeline._physics(delta)
		
		for x : int in range(BORDER.RIGHT, BORDER.LEFT - 1, -1):
			for y : int in range(BORDER.BOTTOM, BORDER.TOP - 1, -1):
				var block : Block = blocks.get(Vector2i(x,y), null)
				if is_instance_valid(block) : block._physics(delta)

		if not square_check_area.is_empty():
			_square_check()

		if _is_action_pressed(&"side_ability") : _side_ability()

		skin._physics(delta)
	
	for action : StringName in current_input.keys():
		latest_input[action] = current_input[action]


func _physics_process(delta: float) -> void:
	if not is_physics_active : return
	_tick(delta)


## Activates player side ability
func _side_ability() -> void:
	if not gamemode.ruleset.rules["piece_swaping"]:
		if piece == null or piece.is_quick_dropping: return

		var next_piece : PieceData = piece_queue.swap_piece(piece.piece_data)
		if next_piece == null : return

		_add_sound(&"queue_shift", Vector2(200,300), false, false)
		Player.savedata.stats["total_piece_swaps"] += 1
		_replace_current_piece(next_piece)


## Gives new piece to the player's hand, replacing old one[br]
## - **'piece_start_pos'** - New piece spawn position in game field grid coordinates[br]
## - **'piece_data'** - If not passed, last piece for queue will be taken instead (if not locked by **'is_giving_pieces_to_player'**)
func _give_new_piece(piece_start_pos : Vector2i = Vector2i(8,-1), piece_data : PieceData = null) -> void:
	if piece != null : 
		piece._remove()
		piece = null
	
	if piece_data == null:
		if not is_giving_pieces_to_player : return
		piece_data = piece_queue._get_piece()
	
	piece = Piece.new()
	piece.grid_position = piece_start_pos
	piece.fall_start_delay = piece_fall_start_delay
	piece.fall_delay = piece_fall_delay
	piece.piece_data = piece_data
	
	piece.ruleset = gamemode.ruleset
	piece.game = self

	piece.z_as_relative = false
	piece.z_index = PIECE_Z_INDEX

	if Player.config.video["background_shaking"] and not skin.skin_data.metadata.settings["no_shaking"]:
		piece.moved.connect(skin._shake_background)
		piece.quick_drop.connect(skin._shake_background)
	
	gamefield.add_child(piece)
	new_piece_is_given.emit()
	
	piece_data.free()


## Replaces current piece data with passed one
func _replace_current_piece(piece_data : PieceData) -> void:
	if not is_instance_valid(piece): return

	for block_pos : Vector2i in piece.blocks.keys():
		var block : BlockBase = piece.blocks[block_pos]
		block.color = piece_data.blocks[block_pos][0]
		block.special = piece_data.blocks[block_pos][1]
		block._render()

	create_tween().tween_property(piece,"modulate",Color(1,1,1,1),0.25).from(Color(0,0,0,0))


## Adds block to the game field [br]
## - **'to_position'** - New block spawn position in game field grid coordinates[br]
## - **'color'** - New block color (all possible colors are described in [BlockBase] script)[br]
## - **'special'** - New block special ability (all possible specials are described in [BlockBase] script)[br]
## - **'smooth'** - If true, block is spawned with fadeout animation
func _add_block(to_position : Vector2i, color : int, special : StringName, smooth : bool = false) -> void:
	if blocks.has(to_position) : return
	if to_position.y < BORDER.TOP or to_position.y > BORDER.BOTTOM: return
	if to_position.x < BORDER.LEFT or to_position.x > BORDER.RIGHT: return

	var block : Block = null
	
	match special:
		&"chain" : block = Chain.new()
		&"merge" : block = Merge.new()
		&"laser" : block = Laser.new()
		&"wipe" : block = Wipe.new()
		&"joker" : block = Joker.new()
	
	if block == null:
		if color == Block.BLOCK_COLOR.GARBAGE: block = Garbage.new()
		else: block = Block.new()
	
	block.grid_position = to_position
	block.color = color
	block.special = special
	block.game = self
	block.ruleset = gamemode.ruleset

	block.z_as_relative = false
	block.z_index = BLOCKS_Z_INDEX
	
	blocks[to_position] = block
	gamefield.add_child(block)

	if smooth : create_tween().tween_property(block, "modulate", Color(1,1,1,1), 0.25).from(Color(0,0,0,0))


## Causes all existing on game field blocks to fall if they have empty space below[br]
## If **'delay'** is > 0, then blocks will fall only after delay is passed
func _move_blocks(delay : float = 0.0) -> void:
	await get_tree().create_timer(delay, true, true).timeout

	# Call blocks from down-right corner, and go up-left, so they would fall in right order and won't clip thru each other
	for x : int in range(BORDER.RIGHT, BORDER.LEFT - 1, -1):
		for y : int in range(BORDER.BOTTOM, BORDER.TOP - 1, -1):
			var block : Block = blocks.get(Vector2i(x,y), null)
			if is_instance_valid(block) : block._start_fall()


## Removes block at game field position
func _remove_block(in_position : Vector2i) -> void:
	var block : Block = blocks.get(in_position, null)
	if is_instance_valid(block) : block._remove()
	

## Removes all existing blocks and squares from the field
func _clear_field() -> void:
	for block : Block in blocks.values():
		if not is_instance_valid(block) : continue
		block._remove()
	for square : Square in squares.values():
		if not is_instance_valid(square) : continue
		square.queue_free()

	blocks.clear()
	squares.clear()
	new_squares.clear()
	is_adding_square_number = false


## Adds passed area to **'square_check_area'** and starts a delay which will start new square check
func _prepare_square_check(area : Rect2i) -> void:
	for x : int in range(area.position.x,area.position.y):
		for y : int in range(area.size.x,area.size.y):
			square_check_area[Vector2i(x,y)] = true
		

## Scans **'square_check_area'** for possible squares and creates them if possible
func _square_check() -> void:
	for square_position : Vector2i in square_check_area.keys():
		var squared_blocks : Array = _check_square_possible(square_position)
		if squared_blocks.is_empty() : continue
		_create_square(square_position, squared_blocks)

	_add_square_numbers()
	square_check_area.clear()


## Checks is square possible in passed game field position [br]
## On success returns array which consists of 4 [Block] instances and blocks color at the end
func _check_square_possible(in_position : Vector2i) -> Array:
	var block : Block = blocks.get(in_position, null)
	if not is_instance_valid(block) : return []
	if block.is_falling : return []
	# If block color is dark, garbage or null
	if block.color > 4 : return []
	
	var squared_blocks : Array = [block]
	var color : int = block.color
	
	var adjacent_blocks_pos : Array[Vector2i] = [in_position + Vector2i(1,0), in_position + Vector2i(0,1), in_position + Vector2i(1,1)]
	for pos : Vector2i in adjacent_blocks_pos:
		var next_block : Block = blocks.get(pos, null)
		if not is_instance_valid(next_block) : return []
		if next_block.is_falling : return []
		if next_block.color > 4 : return []
		
		var next_color : int = next_block.color
		
		if color == BlockBase.BLOCK_COLOR.MULTI:
			color = next_color
			squared_blocks.append(next_block)
			continue
		
		if next_color == BlockBase.BLOCK_COLOR.MULTI:
			squared_blocks.append(next_block)
			continue
		
		if next_color != color: return []

		squared_blocks.append(next_block)
	
	squared_blocks.append(color)
	return squared_blocks


## Checks every square in **'created_squares'**, builds their groups and adds respective group sizes number animation
func _add_square_numbers() -> void:
	if is_adding_square_number : return
	if new_squares.is_empty() : return
	is_adding_square_number = true

	var i : int = 0
	while i < new_squares.size():
		var square_position : Vector2i = new_squares.keys()[i]
		var square_group : Dictionary = _get_square_group(square_position, new_squares)
		
		var fx_pos : Vector2
		fx_pos.x = (square_position.x + 1) * CELL_SIZE + FIELD_X_OFFSET
		fx_pos.y = (square_position.y + 1) * CELL_SIZE + FIELD_Y_OFFSET

		_add_sound("square", fx_pos, false, false)
		_add_fx("num", fx_pos, square_group.size())

		i += 1

	#await get_tree().create_timer(SQUARE_NUMBER_DELAY,true,true).timeout
	is_adding_square_number = false


## Creates square in passed game field position [br]
## **'squared_blocks'** Array must contain 4 [Block] instances inside square and blocks color
func _create_square(in_position : Vector2i, squared_blocks : Array) -> void:
	if squares.has(in_position) : return
	
	var square : Square = SQUARE_SCENE.instantiate()
	square.color = squared_blocks[4]
	square.grid_position = in_position
	square.game = self

	new_squares[in_position] = square
	squares[in_position] = square
	
	# Remove blocks color string from array
	squared_blocks.pop_back()
	square.squared_blocks = squared_blocks
	for block : Block in squared_blocks : block._square_delete(in_position)
	
	gamefield.add_child(square)


## Removes square at game field position
func _remove_square(in_position : Vector2i) -> void:
	var square : Square = squares.get(in_position, null)
	if is_instance_valid(square) : square._remove()


## If any square exists in passed position, returns dictionary containing all connected in group squares: [br] 
## [position : Vector2i] = [Square] [br]
## Also removes matching squares from **'all_positions_dictionary'**
func _get_square_group(in_position : Vector2i, all_positions_dictionary : Dictionary = {}) -> Dictionary:
	if not squares.has(in_position) : return {}
	
	var square_group : Dictionary[Vector2i, Square]
	var squares_to_check : Array[Vector2i] = [in_position]

	while not squares_to_check.is_empty():
		var square_position : Vector2i = squares_to_check.pop_back()

		if square_group.has(square_position) : continue
		var square : Square = squares.get(square_position, null)
		if not is_instance_valid(square) : continue

		square_group[square_position] = square

		# Clean up matching positions, so we wont calculate square groups twice
		if not all_positions_dictionary.is_empty():
			if all_positions_dictionary.has(square_position): 
				all_positions_dictionary.erase(square_position)

		squares_to_check.append_array([
			square_position + Vector2i(1,0), 
			square_position + Vector2i(-1,0), 
			square_position + Vector2i(0,1),
			square_position + Vector2i(0,-1),
			square_position + Vector2i(1,1), 
			square_position + Vector2i(-1,1), 
			square_position + Vector2i(1,-1),
			square_position + Vector2i(-1,-1),
		])

	return square_group


## Returns array of all square groups in passed positions dictionary (bool part is dummy and can be any value)
func _get_all_square_groups_in_positions(positions_to_check : Dictionary[Vector2i, bool]) -> Array:
	var square_groups : Array[Dictionary] = []

	while not positions_to_check.is_empty():
		var square_position : Vector2i = positions_to_check.keys().front()
		var square_group : Dictionary[Vector2i, Square] = _get_square_group(square_position, positions_to_check)

		square_groups.append(square_group)

	return square_groups


## Called on each skin music sample end
func _on_skin_sample_ended() -> void:
	if is_timeline_active : _create_timeline()


## Starts new timeline from beginning, and removes current one
func _create_timeline() -> void:
	if timeline != null : timeline._remove()
	if is_game_over: return
	
	timeline = TIMELINE_SCENE.instantiate()

	timeline.squares_deleted.connect(
		func(_pass : int) -> void : 
			skin._set_playback_state(SkinPlayer.PLAYBACK_STATE.ADVANCING)
	)

	game_over.connect(timeline._remove)
	reset_started.connect(timeline.queue_free)
	skin.beat.connect(timeline._beat)

	timeline.game = self
	timeline.get_node("Color").modulate = skin.skin_data.textures["timeline_color"]
	timeline.z_as_relative = false
	timeline.z_index = TIMELINE_Z_INDEX
	
	gamefield.add_child(timeline)

	if is_paused : timeline.is_paused = true
	timeline_started.emit()


## Adds ghost block to the game field. It doesnt interact with other blocks and is transparent [br]
## - **'to_position'** - New ghost block a0sapawn position in game field grid coordinates[br]
## - **'color'** - New ghost block color (all possible colors are described in [BlockBase] script)[br]
## - **'special'** - New ghost block special ability (all possible specials are described in [BlockBase] script)[br]
## - **'smooth'** - If true, ghost block is spawned with fadeout animation
func _add_ghost_block(to_position : Vector2i, color : int, special : StringName, smooth : bool = false) -> void:
	if to_position.y < 0 or to_position.y > 9: return
	if to_position.x < 0 or to_position.x > 15: return

	var ghost_block : BlockBase = BlockBase.new()
		
	ghost_block.position.x = to_position.x * CELL_SIZE - (CELL_SIZE / 2.0)
	ghost_block.position.x = to_position.y * CELL_SIZE + (CELL_SIZE / 2.0)
	ghost_block.color = color
	ghost_block.special = special
	ghost_block.is_ghost = true
	ghost_block.z_as_relative = false
	ghost_block.z_index = GHOSTS_Z_INDEX
	
	ghosts.append(ghost_block)

	gamefield.add_child(ghost_block)
	ghost_block._render()

	if smooth:
		create_tween().tween_property(ghost_block, "modulate", Color(1,1,1,0.5), 0.25).from(Color(0,0,0,0))


## Adds ghost square to the game field. It doesnt interact with timeline and is transparent [br]
## - **'to_position'** - New ghost square spawn position in game field grid coordinates[br]
## - **'color'** - New ghost square color (all possible colors are described in [BlockBase] script)[br]
## - **'smooth'** - If true, ghost square is spawned with fadeout animation
func _add_ghost_square(to_position : Vector2i, color : int, smooth : bool = false) -> void:
	if to_position.y < 0 or to_position.y > 9: return
	if to_position.x < 0 or to_position.x > 15: return
	
	var ghost_square : ColorRect = ColorRect.new()

	match color:
		BlockBase.BLOCK_COLOR.RED : ghost_square.color = skin.skin_data.textures["red_fx"]
		BlockBase.BLOCK_COLOR.WHITE : ghost_square.color = skin.skin_data.textures["red_fx"]
		BlockBase.BLOCK_COLOR.GREEN : ghost_square.color = skin.skin_data.textures["red_fx"]
		BlockBase.BLOCK_COLOR.PURPLE : ghost_square.color = skin.skin_data.textures["red_fx"]
		BlockBase.BLOCK_COLOR.MULTI : ghost_square.color = skin.skin_data.textures["red_fx"]
	
	ghost_square.color.a = 0.5
	ghost_square.position.x = to_position.x * CELL_SIZE - (CELL_SIZE / 2.0)
	ghost_square.position.x = to_position.y * CELL_SIZE + (CELL_SIZE / 2.0)
	ghost_square.z_as_relative = false
	ghost_square.z_index = GHOSTS_Z_INDEX
	ghosts.append(ghost_square)

	gamefield.add_child(ghost_square)

	if smooth : create_tween().tween_property(ghost_square, "modulate", Color(1,1,1,0.5), 0.25).from(Color(0,0,0,0))


## Removes all exitings on game field ghosts (both blocks and squares)
func _clear_ghosts() -> void:
	for i : int in ghosts.size():
		ghosts.pop_back().queue_free()


## Executes entered into Console command
func _execute_console_command(command : String, arguments : PackedStringArray) -> void:
	super(command, arguments)

	match command:		
		# Lists all blocks on the grid
		"blklist" :
			if blocks.is_empty() : Console._output("Empty"); return

			for pos : Vector2i in blocks:
				var block : Block = blocks[pos]
				var color : String = ""
				match block.color:
					BlockBase.BLOCK_COLOR.RED : color = "Red"
					BlockBase.BLOCK_COLOR.WHITE : color = "White"
					BlockBase.BLOCK_COLOR.GREEN : color = "Green"
					BlockBase.BLOCK_COLOR.PURPLE : color = "Purple"
					BlockBase.BLOCK_COLOR.MULTI : color = "Multi"
					BlockBase.BLOCK_COLOR.GARBAGE : color = "Garbage"
					BlockBase.BLOCK_COLOR.DARK : color = "Dark"
					BlockBase.BLOCK_COLOR.SPECIAL : color = "Special"
					_ : color = "Unknown"
				var special : String = block.special
				Console._output("X = " + str(pos.x) + ",Y = " + str(pos.y) + " : " + color + " " + special)
		
		# Lists all squares on the grid
		"sqrlist" :
			if squares.is_empty() : Console._output("Empty"); return
			
			for pos : Vector2i in squares:
				var square : Square = squares[pos]
				var blocks_array : String = ""
				for block : Block in square.squared_blocks:
					var color : String = ""
					match block.color:
						BlockBase.BLOCK_COLOR.RED : color = "Red"
						BlockBase.BLOCK_COLOR.WHITE : color = "White"
						BlockBase.BLOCK_COLOR.GREEN : color = "Green"
						BlockBase.BLOCK_COLOR.PURPLE : color = "Purple"
						BlockBase.BLOCK_COLOR.MULTI : color = "Multi"
						BlockBase.BLOCK_COLOR.GARBAGE : color = "Garbage"
						BlockBase.BLOCK_COLOR.DARK : color = "Dark"
						BlockBase.BLOCK_COLOR.SPECIAL : color = "Special"
						_ : color = "Unknown"
					var special : String = block.special
					blocks_array = blocks_array + color + " " + special + ", "
				Console._output("X = " + str(pos.x) + ",Y = " + str(pos.y) + " : " + blocks_array)
		
		# Lists all deletable blocks on the grid
		"dltlist" :
			if blocks.is_empty() : Console._output("Empty"); return

			for pos : Vector2i in blocks:
				var block : Block = blocks[pos]
				if not block.is_deletable : continue

				var color : String = ""
				match block.color:
					BlockBase.BLOCK_COLOR.RED : color = "Red"
					BlockBase.BLOCK_COLOR.WHITE : color = "White"
					BlockBase.BLOCK_COLOR.GREEN : color = "Green"
					BlockBase.BLOCK_COLOR.PURPLE : color = "Purple"
					BlockBase.BLOCK_COLOR.MULTI : color = "Multi"
					BlockBase.BLOCK_COLOR.GARBAGE : color = "Garbage"
					BlockBase.BLOCK_COLOR.DARK : color = "Dark"
					BlockBase.BLOCK_COLOR.SPECIAL : color = "Special"
					_ : color = "Unknown"
				var special : String = block.special
				Console._output("X = " + str(pos.x) + ",Y = " + str(pos.y) + " : " + color + " " + special)
		
		# Places specified block at specified position
		"plcblk" :
			if arguments.size() < 1: Console._output("Error! X coordinate is not entered"); return
			if arguments.size() < 2: Console._output("Error! Y coordinate is not entered"); return
			if arguments.size() < 3: Console._output("Error! Block type is not entered. Enter 'blktypes' to get list of all avaiable block types"); return

			var pos : Vector2i = Vector2i(int(arguments[0]), int(arguments[1]))
			var color : int = int(arguments[2].substr(0,2))
			if color > 5 : Console._output("Error! Invalid block type. Enter 'blktypes' to get list of all avaiable block types"); return

			var special : StringName = ""
			match int(arguments[2].substr(2)):
				1 : special = &"chain"
				2 : special = &"merge"
				3 : special = &"laser"
				4 : special = &"wipe"
				5 : special = &"joker"
				_: special = ""
			
			_add_block(pos, color, special)
		
		# Fills specified rectangle with blocks
		"rectblk" :
			if arguments.size() < 1: Console._output("Error! Rect origin X coordinate is not entered"); return
			if arguments.size() < 2: Console._output("Error! Rect origin Y coordinate is not entered"); return
			if arguments.size() < 3: Console._output("Error! Rect width is not entered"); return
			if arguments.size() < 4: Console._output("Error! Rect height is not entered"); return
			if arguments.size() < 5: Console._output("Error! Block type is not entered. Enter 'blktypes' to get list of all avaiable block types"); return

			var color : int = int(arguments[4].substr(0,2))
			if color > 5 : Console._output("Error! Invalid block type. Enter 'blktypes' to get list of all avaiable block types"); return

			var special : StringName = ""
			match int(arguments[4].substr(2)):
				1 : special = &"chain"
				2 : special = &"merge"
				3 : special = &"laser"
				4 : special = &"wipe"
				5 : special = &"joker"
				_: special = ""
			
			for x : int in int(arguments[2]):
				for y : int in int(arguments[3]):
					var pos : Vector2i = Vector2i(int(arguments[0]) + x, int(arguments[1]) + y)
					_add_block(pos, color, special)
		
		# Removes block from position
		"remblk" :
			if arguments.size() < 1: Console._output("Error! X coordinate is not entered"); return
			if arguments.size() < 2: Console._output("Error! Y coordinate is not entered"); return
			if arguments.size() < 3: Console._output("Error! Block type is not entered. Enter 'blktypes' to get list of all avaiable block types"); return

			var pos : Vector2i = Vector2i(int(arguments[0]), int(arguments[1]))
			if not blocks.has(pos):
				Console._output("Error! Invalid position...")
				return
			
			blocks[pos]._remove()
		
		# Clears game field
		"fldclr" :
			_clear_field()
		
		# Toggles paint mode, which allows to place blocks with your mouse!
		"paintmode" :
			Console._output("WIP")
		
		# Allows piece to pass thru blocks, but it still lands at field bottom
		"noclip" :
			Console._output("WIP")
		
		# Sets piece drop speed (overrides corresponding config parameter)
		"pspeed" :
			if arguments.size() < 1: Console._output("Error! Value is not entered"); return
			piece_fall_delay = float(arguments[0])
		
		# Sets piece start delay (overrides corresponding config parameter)
		"pdelay" :
			if arguments.size() < 1: Console._output("Error! Value is not entered"); return
			piece_fall_start_delay = float(arguments[0])
		
		# Deletes current timeline and spawns new one
		"tlreset" :
			_create_timeline()
		
		# Stops current timeline
		"tlpause" :
			if not is_instance_valid(timeline) : Console._output("Error! Timeline is not found"); return
			timeline._pause(true)
		
		# Resumes current timeline
		"tlresume" :
			if not is_instance_valid(timeline) : Console._output("Error! Timeline is not found"); return
			timeline._pause(false)
		
		# Stops timeline creation process
		"tlstop" :
			is_timeline_active = false
		
		# Resumes timeline creation process
		"tlcont" :
			is_timeline_active = true
		
		# Changes current BPM (overrides corresponding config parameter)
		"setbpm" :
			if arguments.size() < 1: Console._output("Error! Value is not entered"); return
			if skin == null : Console._output("Error! Skin is not loaded"); return
			skin.bpm = float(arguments[0])
		
		# Stops piece generation process
		"qstop" :
			is_giving_pieces_to_player = false
		
		# Resumes piece generation process
		"qresume" :
			is_giving_pieces_to_player = true
		
		# Resets piece queue removing all current pieces and making new ones
		"qreset" :
			piece_queue._reset()
		
		# Removes all pieces from the piece queue
		"qclear" :
			piece_queue._clear()
		
		# Appends specified piece to the piece queue
		"qappend" :
			if arguments.size() < 1: Console._output("Error! 1st block type is not entered. Enter 'blktypes' to get list of all avaiable block types"); return
			if arguments.size() < 2: Console._output("Error! 2nd block type is not entered. Enter 'blktypes' to get list of all avaiable block types"); return
			if arguments.size() < 3: Console._output("Error! 3rd block type is not entered. Enter 'blktypes' to get list of all avaiable block types"); return
			if arguments.size() < 4: Console._output("Error! 4th block type is not entered. Enter 'blktypes' to get list of all avaiable block types"); return
			
			var piece_data : PieceData = PieceData.new()
			var i : int = 1
			for block_pos : Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
				var color : int = int(arguments[i].substr(1,1))
				if color > 5 : Console._output("Error! Invalid block type. Enter 'blktypes' to get list of all avaiable block types"); return

				var special : StringName = ""
				match int(arguments[i].substr(0,1)):
					1 : special = &"chain"
					2 : special = &"merge"
					3 : special = &"laser"
					4 : special = &"wipe"
					5 : special = &"joker"
					_: special = ""

				piece_data.blocks[block_pos] = [color, special]
				i += 1
			
			piece_queue._append_piece(piece_data)
