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
signal piece_quick_drop(position : Vector2) # Emitted when piece quick drops
signal piece_landed # Emitted when piece lands and ends its job

enum MOVE {LEFT = -1, RIGHT = 1} # Enum for piece left-right movement
enum BORDER {LEFT = 1, RIGHT = 15} # Game field borders X posiitons

const BASE_QUICK_DROP_SPEED : int = 110 # In pixels per tick
const BASE_DASH_SPEED : int = 90 # In pixels per tick

const ENTRY_DELAY : float = 0.25 # Delay before player can quick drop piece
const QUICK_DROP_HOLD_DELAY : float = 0.3 # If player holds quick drop when new piece is swawned, drop it after this delay

var blocks : Dictionary # Vector2 : BlockBase

var delay_timer : Timer = null # Timer which starts piece falling
var fall_delay : float = 1.0 # Time before piece starts falling by itself

var fall_timer : Timer = null # Timer which makes piece fall by one cell
var fall_speed : float = 1.0 # Delay between each piece fall, if equals 0 piece falls to the floor instantly

var can_be_quick_dropped : bool = false # Can player quick drop this piece?

var dash_timer : Timer # Timer which starts piece dash
var dash_speed : int = BASE_DASH_SPEED
var dash_delay : float = 0.5 # Delay in seconds before piece starts dashing

var quick_drop_speed : int = BASE_QUICK_DROP_SPEED

var is_dashing : bool = false
var has_dash_sound_played : bool = false

var is_dying : bool = false

var is_staying_up : bool = false # Prevent instant quick dropping by holding drop button
var is_droping : bool = false # Is piece quick dropping now?

var current_dash_side : int = 0 # Which side piece is dashing right now

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
	quick_drop_speed = int(Data.profile.config["gameplay"]["quick_drop_speed"] * BASE_QUICK_DROP_SPEED)
	dash_speed = int(Data.profile.config["gameplay"]["piece_dash_speed"] * BASE_DASH_SPEED)
	dash_delay = Data.profile.config["gameplay"]["piece_dash_delay"]
	is_trail_enabled = Data.profile.config["video"]["block_trail"]
	
	dash_timer = Timer.new()
	dash_timer.timeout.connect(func() -> void : is_dashing = true)
	add_child(dash_timer)


func _ready() -> void:
	position = Vector2(grid_position.x * 68, grid_position.y * 68 - 2)
	piece_moved.emit(position)
	
	var entry_delay_timer : Timer = Timer.new()
	entry_delay_timer.timeout.connect(func() -> void: can_be_quick_dropped = true)
	entry_delay_timer.timeout.connect(entry_delay_timer.queue_free)
	add_child(entry_delay_timer)
	entry_delay_timer.start(ENTRY_DELAY)
	
	if fall_speed > 0:
		fall_timer = Timer.new()
		fall_timer.timeout.connect(_fall)
		add_child(fall_timer)
		fall_timer.wait_time = fall_speed
	
	if fall_delay > 0:
		delay_timer = Timer.new()
		delay_timer.timeout.connect(delay_timer.queue_free)

		if fall_speed > 0: delay_timer.timeout.connect(fall_timer.start)
		else: delay_timer.timeout.connect(_instant_drop)

		add_child(delay_timer)
		delay_timer.start(fall_delay)
	else:
		if fall_speed > 0: fall_timer.start()
		else: fall_timer.start(1.0)
	
	if Input.is_action_pressed("move_right") or emulated_inputs["move_right"]: 
		current_dash_side = MOVE.RIGHT
		dash_timer.start(dash_delay)
	elif Input.is_action_pressed("move_left") or emulated_inputs["move_left"]: 
		current_dash_side = MOVE.LEFT
		dash_timer.start(dash_delay)

	# Prevent from instant quick droping on piece spawn
	if Input.is_action_pressed("quick_drop") or emulated_inputs["quick_drop"]:
		is_staying_up = true

		var stay_timer : Timer = Timer.new()
		stay_timer.timeout.connect(func() -> void: is_staying_up = false)
		stay_timer.timeout.connect(stay_timer.queue_free)
		add_child(stay_timer)
		stay_timer.start(QUICK_DROP_HOLD_DELAY)
	
	_render()


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
	if Data.game.is_paused or Data.game.is_input_locked or is_dying: return
	
	if event.is_action_pressed("move_right"):
		_move_piece(MOVE.RIGHT)

		if is_dashing : _reset_dash() 
		dash_timer.start(dash_delay)
		current_dash_side = MOVE.RIGHT

	elif event.is_action_pressed("move_left"): 
		_move_piece(MOVE.LEFT)

		if is_dashing : _reset_dash() 
		dash_timer.start(dash_delay)
		current_dash_side = MOVE.LEFT
	
	elif event.is_action_pressed("rotate_right"): _rotate_piece(MOVE.RIGHT)
	elif event.is_action_pressed("rotate_left"): _rotate_piece(MOVE.LEFT)

	# TODO : Test if this shit is needed
	#if (event.is_action_released("move_right") and current_dash_side == MOVE.RIGHT) or (event.is_action_released("move_left") and current_dash_side == MOVE.LEFT):
	elif event.is_action_released("move_right") or event.is_action_released("move_left"):
		_reset_dash()
		
		if is_trail_enabled:
			is_trailing = false
			for block : BlockBase in blocks.values() : block.trail.emitting = false
	
	elif event.is_action_released("quick_drop"):
		is_staying_up = false
		is_droping = false
		
		if is_trail_enabled:
			is_trailing = false
			for block : BlockBase in blocks.values() : block.trail.emitting = false


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


func _reset_dash() -> void:
	is_dashing = false
	dash_timer.stop()
	current_dash_side = 0
	has_dash_sound_played = false
	position.x = grid_position.x * 68.0

	piece_moved.emit(position)


# Continous input handler
func _process(delta : float) -> void:
	if Data.game.is_paused or is_dying: return

	if is_dashing: _dash(current_dash_side, delta)
	
	if can_be_quick_dropped and not is_staying_up:
		if emulated_inputs["quick_drop"] or (Input.is_action_pressed("quick_drop") and not Data.game.is_input_locked):
			if fall_timer != null : fall_timer.paused = true
			_quick_drop(delta)
		
		else:
			if fall_timer != null : fall_timer.paused = false
			is_droping = false
			position.y = grid_position.y * 68 - 2


func _emulate_press(action_name : String) -> void:
	if Data.game.is_paused or is_dying: return
	
	match action_name:
		&"move_right":
			emulated_inputs["move_right"] = true
			_move_piece(MOVE.RIGHT)
			if is_dashing : _reset_dash() 
			dash_timer.start(dash_delay)
			current_dash_side = MOVE.RIGHT
		&"move_left": 
			emulated_inputs["move_left"] = true
			_move_piece(MOVE.LEFT)
			if is_dashing : _reset_dash() 
			dash_timer.start(dash_delay)
			current_dash_side = MOVE.LEFT
		&"rotate_right" : 
			_rotate_piece(MOVE.RIGHT)
		&"rotate_left" : 
			_rotate_piece(MOVE.LEFT)
		&"side_ability" :
			Data.game.piece_queue._shift_queue()
		&"quick_drop" : 
			emulated_inputs["quick_drop"] = true
			is_staying_up = false
			is_droping = false
			if is_trail_enabled:
				is_trailing = false
				for block : BlockBase in blocks.values() : block.trail.emitting = false


func _emulate_release(action_name : String) -> void:
	if Data.game.is_paused or is_dying: return

	match action_name:
		&"move_right", &"move_left":
			emulated_inputs[action_name] = false
			_reset_dash()
		
			if is_trail_enabled:
				is_trailing = false
				for block : BlockBase in blocks.values() : block.trail.emitting = false
		&"quick_drop" : 
			emulated_inputs["quick_drop"] = false
			is_staying_up = false
			is_droping = false
			if is_trail_enabled:
				is_trailing = false
				for block : BlockBase in blocks.values() : block.trail.emitting = false


# Moves piece sideways given direction (side) and distance (move_amount)
# Returns true if piece moved succesfully and false if was stopped by block or field border
func _process_move(side : int, move_amount : float) -> bool:
	var grid : Dictionary = Data.game.blocks
	
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
		if grid.has(Vector2i(check_x, grid_position.y - 1)) or grid.has(Vector2i(check_x, grid_position.y)): 
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


# Instantly drops piece to the floor
func _instant_drop() -> void:
	if Data.game.is_paused : await Data.game.paused
	_process_drop(999)


# Moves piece down with given distance (move_amount)
func _process_drop(move_amount : float) -> void:
	var grid : Dictionary = Data.game.blocks
	
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
		
		var down_left_block_collision : bool = grid.has(Vector2i(grid_position.x, check_y))
		var down_right_block_collision : bool = grid.has(Vector2i(grid_position.x + 1, check_y))
		
		if down_right_block_collision or down_left_block_collision:
			# If we're at the top of game field
			if check_y == 0: _slide_piece(check_y, down_left_block_collision, down_right_block_collision, grid)
			else:
				position.y += 68.0 * check_y - position.y - 68
				grid_position.y = min(ceil(position.y / 68.0), 9) as int
				piece_quick_drop.emit(position)
				_place_piece()
				return
		
		check_y += 1 
	
	position.y += move_amount
	grid_position.y = min(ceil(position.y / 68.0), 9) as int
	piece_quick_drop.emit(position)


# Slides block at side if it collides with just one block at the bottom, and triggers game over if collides with more blocks
func _slide_piece(check_y : int, down_left_block_collision : bool, down_right_block_collision : bool, grid : Dictionary) -> void:
	if down_right_block_collision and down_left_block_collision:
		Data.game._game_over()
		return
	
	if down_left_block_collision and not down_right_block_collision: 
		if grid_position.x == BORDER.RIGHT:
			Data.game._game_over()
			return

		_move_piece(MOVE.RIGHT)
		down_right_block_collision = grid.has(Vector2i(grid_position.x + 1, check_y))
		
		if down_right_block_collision:
			Data.game._game_over()
			return
	
	elif down_right_block_collision and not down_left_block_collision: 
		if grid_position.x == BORDER.LEFT:
			Data.game._game_over()
			return

		_move_piece(MOVE.LEFT)
		down_left_block_collision = grid.has(Vector2i(grid_position.x, check_y))
		
		if down_left_block_collision:
			Data.game._game_over()
			return


# Moves piece sideways by one block
func _move_piece(side : int) -> void:
	var grid : Dictionary = Data.game.blocks
	
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
		if grid_position.y == -1: _slide_piece(grid_position.y + 2,down_block_collision_left,down_block_collision_right,grid)
		else:
			piece_moved.emit(position)
			_place_piece()
			return
		
	position.y += 68
	grid_position.y += 1
	piece_moved.emit(position)


# Dash function which moves block by float value with delta
func _dash(side : int, delta : float) -> void:
	var success : bool = _process_move(side, 68 * dash_speed * delta * side)
	
	if not success: 
		_reset_dash()
		piece_moved.emit(position)
		return
	
	if is_trail_enabled and not is_trailing:
		is_trailing = true
		for block : BlockBase in blocks.values() : block.trail.emitting = true
	
	if not has_dash_sound_played:
		if (side == MOVE.RIGHT): Data.game._add_sound(&'right_dash',Vector2(position.x+300,position.y+320),false,false)
		else: Data.game._add_sound(&'left_dash',Vector2(position.x+300,position.y+320),false,false)
	
	has_dash_sound_played = true
	piece_moved.emit(position)


# Quickly and smoothly drops piece down
func _quick_drop(delta : float) -> void:
	is_droping = true
	
	if is_trail_enabled and not is_trailing:
		is_trailing = true
		for block : BlockBase in blocks.values() : block.trail.emitting = true
	
	_process_drop(68 * quick_drop_speed * delta)


# This is called by fall timer, and moves block down by 1
func _fall() -> void:
	if not Data.game.is_paused and not is_droping:
		is_staying_up = false
		_drop_piece()


# Pauses piece falling
func _pause(on : bool = true) -> void:
	fall_timer.paused = on


func _place_piece() -> void:
	if fall_timer != null : fall_timer.paused = true
	set_process(false)
	
	if is_trail_enabled:
		for block : BlockBase in blocks.values() : block.trail.emitting = false
	
	Data.game._add_sound(&'drop',Vector2(position.x+300,position.y+500),false,false)
	
	# Add blocks to the field from bottom right one, so block movement would be right and blocks won't clip thru eachother
	var blocks_array : Array = blocks.keys()
	blocks_array.reverse()
	for block_pos : Vector2i in blocks_array: 
		Data.game._add_block(Vector2i(grid_position.x + block_pos.x, grid_position.y + block_pos.y - 1), blocks[block_pos].color, blocks[block_pos].special)
	
	var piece_start_pos : Vector2 = Vector2(8,-1)
	if Data.profile.config["gameplay"]["save_holder_position"]: piece_start_pos = Vector2(grid_position.x,-1)
	
	Data.game._give_new_piece(piece_start_pos)
	piece_landed.emit()


# Properly removes piece from field
func _end() -> void:
	if is_dying : return
	is_dying = true
	
	for block : BlockBase in blocks.values():
		block.self_modulate.a = 0.0
		if is_trail_enabled : block.trail.emitting = false
		if is_instance_valid(block.special_sprite) : block.special_sprite.visible = false
	
	var die_timer : Timer = Timer.new()
	die_timer.timeout.connect(queue_free)
	add_child(die_timer)
	die_timer.start(0.5)
