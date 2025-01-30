# Project Luminext - an advanced open-source Lumines spiritual successor
# Copyright (C) <2024> <unfavorable_enhancer>
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


extends Node2D

class_name Piece

signal piece_moved(position : Vector2) # Emitted when piece moves
signal piece_rotated(side : int) # Emitted when piece rotates
signal piece_dashed(side : int) # Emitted when piece dashes
signal piece_quick_drop(position : Vector2) # Emitted when piece quick drops
signal piece_landed # Emitted when piece lands and ends its job

enum MOVE {LEFT = -1, RIGHT = 1} # Enum for piece left-right movement
enum BORDER {LEFT = 1, RIGHT = 15} # Game field borders X posiitons

const TICK : float =  1.0 / 120.0

const BASE_QUICK_DROP_SPEED : float = 68.0 / 120.0 / 0.01 # In pixels per tick
const BASE_DASH_SPEED : float = 68.0 / 120.0 / 0.0125 # In pixels per tick

const ENTRY_DELAY : float = 0.25 # Delay before player can quick drop piece
const QUICK_DROP_HOLD_DELAY : float = 0.3 # If player holds quick drop when new piece is swawned, drop it after this delay

var blocks : Dictionary # Vector2 : BlockBase

var fall_delay : float = 1.0 # Time before piece starts falling by itself

var fall_speed : float = 1.0 # Delay between each piece fall, if equals 0 piece falls to the floor instantly
var fall_speed_left : float = 1.0

var dash_delay : float = 0.5 # Delay in seconds before piece starts dashing
var dash_left : float = 0.5
var is_dashing : bool = false
var current_dash_side : int = 0 # Which side piece is dashing right now
var dash_speed : float = BASE_DASH_SPEED

var can_be_quick_dropped : bool = true # Can player quick drop this piece?
var is_quick_dropping : bool = false
var quick_drop_speed : float = BASE_QUICK_DROP_SPEED
var quick_drop_delay : float = 0.0

var is_dying : bool = false

var replay : Replay = null
# Used by replays to emulate player inputs
var emulated_inputs : Dictionary = {
	&"move_left" : false,
	&"move_right" : false,
	&"quick_drop" : false
}

# Piece position transposed to game field coordinates
var grid_position : Vector2i = Vector2i(0,0)

var is_trail_enabled : bool = true
var is_trailing : bool = false


func _init() -> void:	
	process_priority = -666
	process_physics_priority = -666

	quick_drop_speed = Data.profile.config["gameplay"]["quick_drop_speed"] * BASE_QUICK_DROP_SPEED
	dash_speed = Data.profile.config["gameplay"]["piece_dash_speed"] * BASE_DASH_SPEED
	dash_delay = Data.profile.config["gameplay"]["piece_dash_delay"]
	is_trail_enabled = Data.profile.config["video"]["block_trail"]


func _ready() -> void:
	_render()

	position = Vector2(grid_position.x * 68, grid_position.y * 68 - 2)
	piece_moved.emit(position)
	
	if (Input.is_action_pressed("move_right") or emulated_inputs["move_right"]) and not Data.game.input_lock[&"move_right"]:
		dash_left = dash_delay
		current_dash_side = MOVE.RIGHT
	elif (Input.is_action_pressed("move_left") or emulated_inputs["move_left"]) and not Data.game.input_lock[&"move_left"]:
		dash_left = dash_delay
		current_dash_side = MOVE.LEFT

	# Prevent from instant quick droping on piece spawn
	if (Input.is_action_pressed("quick_drop") or emulated_inputs["quick_drop"]) and not Data.game.input_lock[&"quick_drop"]:
		is_quick_dropping = true
		_toggle_trail(true)
		can_be_quick_dropped = false
		quick_drop_delay = QUICK_DROP_HOLD_DELAY
	
	
func _render() -> void:
	modulate = Color(0,0,0,0)
	
	for block_pos : Vector2i in blocks.keys():
		var block : BlockBase = BlockBase.new()
		block.position = Vector2(-34 + 68 * block_pos.x, -34 + 68 * block_pos.y)
		block.color = blocks[block_pos][0]
		block.special = blocks[block_pos][1]
		block.is_trail_enabled = is_trail_enabled
		add_child(block)
		block._render()
		if is_trail_enabled : block.trail.emitting = false
		blocks[block_pos] = block
	
	# Appear animation
	create_tween().tween_property(self, "modulate", Color(1,1,1,1), 0.25)


# Single input handler
func _input(event : InputEvent) -> void:
	if Data.game.is_paused or is_dying: return
	
	if event.is_action_pressed(&"move_right") and not Data.game.input_lock[&"move_right"]:
		replay._record_action_press(&"move_right")
		_move_piece(MOVE.RIGHT)
		if is_dashing : _reset_dash() 
		dash_left = dash_delay
		current_dash_side = MOVE.RIGHT
	elif event.is_action_pressed(&"move_left") and not Data.game.input_lock[&"move_left"]:
		replay._record_action_press(&"move_left")
		_move_piece(MOVE.LEFT)
		if is_dashing : _reset_dash() 
		dash_left = dash_delay
		current_dash_side = MOVE.LEFT
	elif event.is_action_pressed(&"quick_drop") and not Data.game.input_lock[&"quick_drop"]:
		replay._record_action_press(&"quick_drop")
		is_quick_dropping = true
		_toggle_trail(true)
	elif event.is_action_pressed(&"rotate_right") and not Data.game.input_lock[&"rotate_right"]:
		replay._record_action_press(&"rotate_right")
		_rotate_piece(MOVE.RIGHT)
	elif event.is_action_pressed(&"rotate_left") and not Data.game.input_lock[&"rotate_left"]:
		replay._record_action_press(&"rotate_left")
		_rotate_piece(MOVE.LEFT)
	elif event.is_action_released(&"move_right") and not Data.game.input_lock[&"move_right"]:
		replay._record_action_release(&"move_right")
		if current_dash_side == MOVE.RIGHT: _reset_dash()
	elif event.is_action_released(&"move_left") and not Data.game.input_lock[&"move_left"]:
		replay._record_action_release(&"move_left")
		if current_dash_side == MOVE.LEFT: _reset_dash()
	elif event.is_action_released(&"quick_drop") and not Data.game.input_lock[&"quick_drop"]:
		replay._record_action_release(&"quick_drop")
		is_quick_dropping = false
		position.y = grid_position.y * 68 - 2
		_toggle_trail(false)


# Block rotation function
func _rotate_piece(side : int = 1) -> void:
	if side == MOVE.RIGHT:
		Data.game._add_sound(&'rotate_right',Vector2(position.x+300,position.y+320),false,false)
		
		blocks[Vector2i(0,0)].position.x += 68
		blocks[Vector2i(1,0)].position.y += 68
		blocks[Vector2i(1,1)].position.x -= 68
		blocks[Vector2i(0,1)].position.y -= 68
		
		var buf : BlockBase = blocks[Vector2i(0,0)]
		blocks[Vector2i(0,0)] = blocks[Vector2i(0,1)]
		blocks[Vector2i(0,1)] = blocks[Vector2i(1,1)]
		blocks[Vector2i(1,1)] = blocks[Vector2i(1,0)]
		blocks[Vector2i(1,0)] = buf
	
	if side == MOVE.LEFT:
		Data.game._add_sound(&'rotate_left',Vector2(position.x+300,position.y+320),false,false)
		
		blocks[Vector2i(0,0)].position.y += 68
		blocks[Vector2i(1,0)].position.x -= 68
		blocks[Vector2i(1,1)].position.y -= 68
		blocks[Vector2i(0,1)].position.x += 68
		
		var buf : BlockBase = blocks[Vector2i(0,0)]
		blocks[Vector2i(0,0)] = blocks[Vector2i(1,0)]
		blocks[Vector2i(1,0)] = blocks[Vector2i(1,1)]
		blocks[Vector2i(1,1)] = blocks[Vector2i(0,1)]
		blocks[Vector2i(0,1)] = buf
	
	piece_rotated.emit(side)


# Continous input handler
func _physics() -> void:
	if Data.game.is_paused or is_dying: return

	if not can_be_quick_dropped:
		quick_drop_delay -= TICK
		if quick_drop_delay <= 0.0 : can_be_quick_dropped = true
	else:
		if is_quick_dropping:
			_process_drop(quick_drop_speed)
			return

	if fall_delay <= 0.0:
		if fall_speed == 0.0: _instant_drop(); return

		fall_speed_left -= TICK
		if fall_speed_left <= 0.0:
			fall_speed_left = fall_speed
			_drop_piece()
	else:
		fall_delay -= TICK
	
	if current_dash_side != 0:
		dash_left -= TICK
		if dash_left <= 0.0:
			_dash_piece()


func _emulate_press(action_name : StringName) -> void:
	if Data.game.is_paused or is_dying: return
	
	match action_name:
		&"move_right":
			_move_piece(MOVE.RIGHT)
			if is_dashing : _reset_dash() 
			dash_left = dash_delay
			current_dash_side = MOVE.RIGHT
		&"move_left": 
			_move_piece(MOVE.LEFT)
			if is_dashing : _reset_dash() 
			dash_left = dash_delay
			current_dash_side = MOVE.LEFT
		&"rotate_right" : 
			_rotate_piece(MOVE.RIGHT)
		&"rotate_left" : 
			_rotate_piece(MOVE.LEFT)
		&"quick_drop" : 
			is_quick_dropping = true
			_toggle_trail(true)


func _emulate_release(action_name : StringName) -> void:
	if Data.game.is_paused or is_dying: return

	match action_name:
		&"move_right" :
			if current_dash_side == MOVE.RIGHT: _reset_dash()
		&"move_left" :
			if current_dash_side == MOVE.LEFT: _reset_dash()
		&"quick_drop" : 
			is_quick_dropping = false
			position.y = grid_position.y * 68 - 2
			_toggle_trail(false)


# Moves piece sideways given direction (side) and distance (move_amount)
# Returns true if piece moved succesfully and false if was stopped by block or field border
func _process_move(side : int, move_amount : float) -> bool:
	var grid : Dictionary = Data.game.all_blocks
	
	var virtual_pos : float = position.x + move_amount # Current piece move distance
	var virtual_pos_x : int = 0 # Same as above, but in game field coords
	
	# Convert to grid coordinates system
	if side == MOVE.RIGHT : virtual_pos_x = (ceil(virtual_pos / 68.0) + 1) as int
	else : virtual_pos_x = int(virtual_pos / 68.0)
	
	var check_x : int = grid_position.x # This position is used to check are any blocks on the way piece is moving now
	
	while check_x != virtual_pos_x:
		check_x += side
		
		# If there's grid border, move piece to the distance between piece and border
		if check_x > BORDER.RIGHT :
			position.x += 1050 - position.x - 30
			grid_position.x = check_x - 1
			return false
		if check_x < BORDER.LEFT : 
			position.x -= position.x - 68
			grid_position.x = check_x + 1
			return false
		
		# If our check met some block, move piece to the distance between piece and block
		if is_instance_valid(grid.get(Vector2i(check_x, grid_position.y - 1))) or is_instance_valid(grid.get(Vector2i(check_x, grid_position.y))): 
			if side == MOVE.RIGHT : 
				position.x += 68 * check_x - position.x - 136
				grid_position.x = check_x - 2
				return false
			else : 
				position.x += 68 * check_x - position.x + 68
				grid_position.x = check_x + 1
				return false
	
	position.x += move_amount

	if side == MOVE.RIGHT : grid_position.x = virtual_pos_x - 1
	else : grid_position.x = virtual_pos_x

	return true


# Moves piece down with given distance (move_amount)
func _process_drop(move_amount : float) -> void:
	var grid : Dictionary = Data.game.all_blocks
	
	var virtual_pos : float = position.y + move_amount # Current piece move distance
	var virtual_pos_y : int = (ceil(virtual_pos / 68.0) + 1) as int # Same as above, but in grid coords
	
	var check_y : int = grid_position.y # This position is used to check are any blocks on the way piece is moving now
	
	while check_y != virtual_pos_y:
		# If there's grid floor, move piece to the distance between piece and floor
		if check_y > 9 :
			position.y += 610 - position.y
			grid_position.y = 9
			piece_quick_drop.emit(position)
			_place_piece()
			return
		
		var down_left_block_collision : bool = is_instance_valid(grid.get(Vector2i(grid_position.x, check_y)))
		var down_right_block_collision : bool = is_instance_valid(grid.get(Vector2i(grid_position.x + 1, check_y)))
		
		if down_right_block_collision or down_left_block_collision:
			# If we're at the top of game field
			if check_y == 0: _slide_piece(check_y, down_left_block_collision, down_right_block_collision)
			else:
				position.y += 68.0 * check_y - position.y - 68
				grid_position.y = ceil(position.y / 68.0) as int
				piece_quick_drop.emit(position)
				_place_piece()
				return
		
		check_y += 1 
	
	position.y += move_amount
	grid_position.y = ceil(position.y / 68.0) as int
	piece_quick_drop.emit(position)


# Instantly drops piece to the floor
func _instant_drop() -> void:
	if Data.game.is_paused : await Data.game.paused
	_process_drop(999)


# Slides block at side if it collides with just one block at the bottom, and triggers game over if collides with more blocks
func _slide_piece(check_y : int, down_left_block_collision : bool, down_right_block_collision : bool) -> void:
	var grid : Dictionary = Data.game.all_blocks

	if down_right_block_collision and down_left_block_collision:
		Data.game._game_over()
		return
	
	if down_left_block_collision and not down_right_block_collision: 
		if grid_position.x == BORDER.RIGHT:
			Data.game._game_over()
			return

		_move_piece(MOVE.RIGHT)
		down_right_block_collision = is_instance_valid(grid.get(Vector2i(grid_position.x + 1, check_y)))
		
		if down_right_block_collision:
			Data.game._game_over()
			return
	
	elif down_right_block_collision and not down_left_block_collision: 
		if grid_position.x == BORDER.LEFT:
			Data.game._game_over()
			return

		_move_piece(MOVE.LEFT)
		down_left_block_collision = is_instance_valid(grid.get(Vector2i(grid_position.x, check_y)))
		
		if down_left_block_collision:
			Data.game._game_over()
			return


# Moves piece sideways by one block
func _move_piece(side : int) -> void:
	var grid : Dictionary = Data.game.all_blocks
	
	if side == MOVE.RIGHT :
		if grid_position.x + 1 > BORDER.RIGHT :
			return 
		# If game field has down right block placed we can't move
		if grid.has(Vector2i(grid_position.x + 2, grid_position.y)): 
			return 
	else:
		if grid_position.x - 1 < BORDER.LEFT : 
			return 
		# If game field has down left block placed we can't move
		if grid.has(Vector2i(grid_position.x - 1, grid_position.y)): 
			return 
	
	position.x += 68 * side
	grid_position.x += side
	
	Data.game._add_sound(&'move',Vector2(position.x+300,position.y+320),false,false)
	
	piece_moved.emit(position)


# Drops piece down by one block
func _drop_piece() -> void:
	var grid : Dictionary = Data.game.blocks
	
	# If piece is at game field floor
	if grid_position.y + 1 > 9 :
		position.y += 610 - position.y
		grid_position.y = 9
		piece_moved.emit(position)
		_place_piece()
		return
	
	var down_block_collision_left : bool = grid.has(Vector2i(grid_position.x, grid_position.y + 1))
	var down_block_collision_right : bool = grid.has(Vector2i(grid_position.x + 1, grid_position.y + 1))
	
	if down_block_collision_right or down_block_collision_left:
		# If we're at the top of game field
		if grid_position.y == -1: _slide_piece(grid_position.y + 2,down_block_collision_left,down_block_collision_right)
		else:
			piece_moved.emit(position)
			_place_piece()
			return
		
	position.y += 68
	grid_position.y += 1
	piece_moved.emit(position)


# Dash function which moves block by float value with delta
func _dash_piece() -> void:
	var success : bool = _process_move(current_dash_side, dash_speed * current_dash_side)
	if not success: 
		_reset_dash()
		return
	
	_toggle_trail(true)
	
	if not is_dashing:
		if (current_dash_side == MOVE.RIGHT): 
			Data.game._add_sound(&'right_dash',Vector2(position.x+300,position.y+320),false,false)
			piece_dashed.emit(MOVE.RIGHT)
		else: 
			Data.game._add_sound(&'left_dash',Vector2(position.x+300,position.y+320),false,false)
			piece_dashed.emit(MOVE.LEFT)
	
	is_dashing = true
	piece_moved.emit(position)


func _reset_dash() -> void:
	is_dashing = false
	current_dash_side = 0
	position.x = grid_position.x * 68.0

	_toggle_trail(false)

	piece_moved.emit(position)


func _toggle_trail(on : bool) -> void:
	if is_trail_enabled:
		if on:
			is_trailing = true
			for block : BlockBase in blocks.values() : block.trail.emitting = true
		elif not on and is_trailing:
			is_trailing = false
			for block : BlockBase in blocks.values() : block.trail.emitting = false


func _place_piece() -> void:
	is_dying = true
	piece_landed.emit()
	
	Data.game._add_sound(&'drop',Vector2(position.x+300,position.y+500),false,false)
	
	# Add blocks to the field from bottom right one, so block movement would be right and blocks won't clip thru eachother
	var blocks_array : Array = blocks.keys()
	blocks_array.reverse()
	for block_pos : Vector2i in blocks_array: 
		Data.game._add_block(Vector2i(grid_position.x + block_pos.x, grid_position.y + block_pos.y - 1), blocks[block_pos].color, blocks[block_pos].special)
	
	var piece_start_pos : Vector2 = Vector2(8,-1)
	if Data.profile.config["gameplay"]["save_holder_position"]: piece_start_pos = Vector2(grid_position.x,-1)
	
	Data.game._give_new_piece(piece_start_pos)


# Properly removes piece from field
func _end() -> void:
	Data.game.piece = null
	
	for block : BlockBase in blocks.values() : 
		block.self_modulate.a = 0.0
		if block.has_node("Special") : block.get_node("Special").self_modulate.a = 0.0
		if is_trail_enabled: block.trail.emitting = false
	
	get_tree().create_timer(0.5).timeout.connect(queue_free)
