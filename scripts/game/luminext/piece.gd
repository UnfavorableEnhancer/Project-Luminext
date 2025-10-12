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


extends Node2D

class_name Piece

##-----------------------------------------------------------------------
## Controlled by player and can be moved and rotated
## Lands when it hits game field bottom or some placed block below
##-----------------------------------------------------------------------

signal moved(position : Vector2) ## Emitted when piece moves and returns new piece position
signal moved_side(side : int) ## Emitted when piece moves and returns movement side
signal rotated(side : int) ## Emitted when piece rotates and returns rotation side
signal dashed(side : int) ## Emitted when piece dashes and returns movement side
signal quick_drop(position : Vector2) ## Emitted when piece quick drops and returns new piece position
signal landed ## Emitted when piece lands

enum MOVE {LEFT = -1, RIGHT = 1} ## Left and right movement constants

const BASE_QUICK_DROP_SPEED : float = 68.0 / 0.01 ## Base quick drop speed in pixels per tick
const BASE_DASH_SPEED : float = 68.0 / 0.0125 ## Base dash speed in pixels per tick

const ENTRY_DELAY : float = 0.25 ## Delay before player can quick drop piece
const QUICK_DROP_HOLD_DELAY : float = 0.3 ## If player holds quick drop when new piece is spawned, drop it only after this delay passes

var game : LuminextGame ## Game instance
var ruleset : Ruleset ## Ruleset instance

var piece_data : PieceData ## Used piece data
var blocks : Dictionary[Vector2i, BlockBase] = {} ## All blocks inside this piece [br] [Vector2i] : [BlockBase]

var fall_start_delay : float = 1.0 ## Time left before piece starts auto falling

var fall_delay : float = 1.0 ## Delay in seconds between each piece fall, if equals 0 piece falls to the floor instantly
var fall_delay_left : float = 1.0 ## Time left before piece falls down one cell

var dash_delay : float = 0.5 ## Delay in seconds before piece starts dashing
var dash_delay_left : float = 0.5 ## Time left before piece starts dashing
var is_dashing : bool = false ## True if piece is currently dashing
var current_dash_side : int = 0 ## Side which piece is currently dashing
var dash_speed : float = BASE_DASH_SPEED ## Current piece dash speed in pixels per tick

var quick_drop_delay_left : float = 0.0 ## Time left before piece can be quick dropped
var can_be_quick_dropped : bool = true ## If true, player can quick drop this piece
var is_quick_dropping : bool = false ## True if piece is currently quick dropping
var quick_drop_speed : float = BASE_QUICK_DROP_SPEED ## Current piece quick drop speed in pixels per tick

## All latest pressed inputs, used to determine action press/release
var latest_input : Dictionary[StringName, bool] = {
	&"move_left" : false,
	&"move_right" : false,
	&"rotate_left" : false,
	&"rotate_right" : false,
	&"quick_drop" : false,
	&"side_ability" : false
}

var is_removing : bool = false ## True if piece is currently removing

var grid_position : Vector2i = Vector2i(0,0) ## Current piece position on game field grid

var is_trail_enabled : bool = true ## If true, block trails will be added on piece spawn
var is_trailing : bool = false ## True if piece trails are currently enabled


func _ready() -> void:
	name = "Piece"
	modulate = Color(0,0,0,0)
	
	quick_drop_speed = ruleset.params["quick_drop_speed"] * BASE_QUICK_DROP_SPEED
	dash_speed = ruleset.params["piece_dash_speed"] * BASE_DASH_SPEED
	dash_delay = ruleset.params["piece_dash_delay"]
	is_trail_enabled = Player.config.video["block_trail"]
	
	for block_pos : Vector2i in piece_data.blocks.keys():
		var block : BlockBase = BlockBase.new()

		block.game = game
		block.ruleset = ruleset
		
		block.position.x = LuminextGame.CELL_SIZE * block_pos.x - (LuminextGame.CELL_SIZE / 2.0) 
		block.position.y = LuminextGame.CELL_SIZE * block_pos.y - (LuminextGame.CELL_SIZE / 2.0)
		block.color = piece_data.blocks[block_pos][0]
		block.special = piece_data.blocks[block_pos][1]
		
		block.is_trail_enabled = is_trail_enabled
		
		blocks[block_pos] = block
		add_child(block)
		
		if is_trail_enabled : block.trail.emitting = false
	
	position = Vector2(grid_position.x * LuminextGame.CELL_SIZE, grid_position.y * LuminextGame.CELL_SIZE)
	moved.emit(position)

	# Appear animation
	create_tween().tween_property(self, "modulate", Color(1,1,1,1), 0.25)
	
	if game.current_input[&"move_right"]:
		dash_delay_left = dash_delay
		current_dash_side = MOVE.RIGHT
	
	elif game.current_input[&"move_left"]:
		dash_delay_left = dash_delay
		current_dash_side = MOVE.LEFT

	# Prevent from instant quick droping on piece spawn
	if game.current_input[&"quick_drop"]:
		is_quick_dropping = true
		_toggle_trail(true)
		can_be_quick_dropped = false
		quick_drop_delay_left = QUICK_DROP_HOLD_DELAY


# Block rotation function
func _rotate_piece(side : int = 1) -> void:
	if side == MOVE.RIGHT:
		game._add_sound(&'rotate_right',Vector2(position.x+300,position.y+320),false,false)
		
		blocks[Vector2i(0,0)].position.x += LuminextGame.CELL_SIZE
		blocks[Vector2i(1,0)].position.y += LuminextGame.CELL_SIZE
		blocks[Vector2i(1,1)].position.x -= LuminextGame.CELL_SIZE
		blocks[Vector2i(0,1)].position.y -= LuminextGame.CELL_SIZE
		
		var buf : BlockBase = blocks[Vector2i(0,0)]
		blocks[Vector2i(0,0)] = blocks[Vector2i(0,1)]
		blocks[Vector2i(0,1)] = blocks[Vector2i(1,1)]
		blocks[Vector2i(1,1)] = blocks[Vector2i(1,0)]
		blocks[Vector2i(1,0)] = buf
	
	if side == MOVE.LEFT:
		game._add_sound(&'rotate_left',Vector2(position.x+300,position.y+320),false,false)
		
		blocks[Vector2i(0,0)].position.y += LuminextGame.CELL_SIZE
		blocks[Vector2i(1,0)].position.x -= LuminextGame.CELL_SIZE
		blocks[Vector2i(1,1)].position.y -= LuminextGame.CELL_SIZE
		blocks[Vector2i(0,1)].position.x += LuminextGame.CELL_SIZE
		
		var buf : BlockBase = blocks[Vector2i(0,0)]
		blocks[Vector2i(0,0)] = blocks[Vector2i(1,0)]
		blocks[Vector2i(1,0)] = blocks[Vector2i(1,1)]
		blocks[Vector2i(1,1)] = blocks[Vector2i(0,1)]
		blocks[Vector2i(0,1)] = buf
	
	rotated.emit(side)


## Tests is input pressed in current physics frame and updates input state
func _is_action_pressed(action : StringName) -> bool:
	if game.current_input[action] and not latest_input[action]:
		latest_input[action] = game.current_input[action]
		return true
	
	return false


## Tests is input released in current physics frame and updates input state
func _is_action_released(action : StringName) -> bool:
	if not game.current_input[action] and latest_input[action]:
		latest_input[action] = game.current_input[action]
		return true
	
	return false


## Called by physics tick
func _physics(delta : float) -> void:
	if game.is_paused or is_removing: return
	
	if _is_action_pressed(&"move_right"):
		_move_piece(MOVE.RIGHT)
		if is_dashing : _reset_dash() 
		dash_delay_left = dash_delay
		current_dash_side = MOVE.RIGHT

	if _is_action_pressed(&"move_left"):
		_move_piece(MOVE.LEFT)
		if is_dashing : _reset_dash() 
		dash_delay_left = dash_delay
		current_dash_side = MOVE.LEFT
	
	if _is_action_pressed(&"quick_drop"):
		is_quick_dropping = true
		_toggle_trail(true)
	
	if _is_action_pressed(&"rotate_right") : _rotate_piece(MOVE.RIGHT)
	if _is_action_pressed(&"rotate_left") : _rotate_piece(MOVE.LEFT)

	if _is_action_released(&"move_right") : if current_dash_side == MOVE.RIGHT : _reset_dash()
	if _is_action_released(&"move_left") : if current_dash_side == MOVE.LEFT : _reset_dash()

	if _is_action_released(&"quick_drop"):
		is_quick_dropping = false
		position.y = grid_position.y * LuminextGame.CELL_SIZE
		_toggle_trail(false)
	
	_is_action_released(&"rotate_right")
	_is_action_released(&"rotate_left")

	if not can_be_quick_dropped:
		quick_drop_delay_left -= delta
		if quick_drop_delay_left <= 0.0 : can_be_quick_dropped = true
	else:
		if is_quick_dropping:
			_process_drop(quick_drop_speed * delta)
			return

	if fall_start_delay <= 0.0:
		if fall_delay == 0.0: 
			_instant_drop()
			return

		fall_delay_left -= delta
		if fall_delay_left <= 0.0:
			fall_delay_left = fall_delay
			_drop_piece()
	else:
		fall_start_delay -= delta
	
	if current_dash_side != 0:
		dash_delay_left -= delta
		if dash_delay_left <= 0.0:
			_dash_piece(delta)


## Moves piece sideways to passed **'direction'** and **'distance'** [br]
## Returns true if piece moved succesfully and false if was stopped by block or field border
func _process_move(direction : int, distance : float) -> bool:
	var virtual_pos : float = position.x + distance # Current piece move distance
	var virtual_pos_x : int = 0 # Same as above, but in game field coords
	
	# Convert to grid coordinates system
	if direction == MOVE.RIGHT : virtual_pos_x = ceili(virtual_pos / LuminextGame.CELL_SIZE) + 1
	else : virtual_pos_x = int(virtual_pos / LuminextGame.CELL_SIZE) - 2
	
	var check_x : int = grid_position.x # This position is used to check are any blocks on the way piece is moving now
	
	while check_x != virtual_pos_x:
		check_x += direction
		
		# If there's grid border, move piece to the distance between piece and border
		if check_x > LuminextGame.BORDER.RIGHT :
			position.x += LuminextGame.CELL_SIZE * LuminextGame.BORDER.RIGHT - position.x
			grid_position.x = LuminextGame.BORDER.RIGHT
			return false
		if check_x < LuminextGame.BORDER.LEFT + 1 : 
			position.x -= position.x - LuminextGame.CELL_SIZE
			grid_position.x = LuminextGame.BORDER.LEFT + 1
			return false
		
		# If our check met some block, move piece to the distance between piece and block
		var bottom_side_block : Block = game.blocks.get(Vector2i(check_x, grid_position.y), null)

		if is_instance_valid(bottom_side_block): 
			if direction == MOVE.RIGHT : 
				position.x += LuminextGame.CELL_SIZE * (check_x - 1) - position.x
				grid_position.x = check_x - 1
				return false
			else : 
				position.x += LuminextGame.CELL_SIZE * (check_x + 2) - position.x
				grid_position.x = check_x + 2
				return false
	
	position.x += distance

	if direction == MOVE.RIGHT : grid_position.x = virtual_pos_x - 1
	else : grid_position.x = virtual_pos_x

	return true


## Moves piece down with given **'distance'**
func _process_drop(distance : float) -> void:
	var virtual_pos : float = position.y + distance # Current piece move distance
	var virtual_pos_y : int = (ceil(virtual_pos / LuminextGame.CELL_SIZE) + 1) as int # Same as above, but in grid coords
	
	var check_y : int = grid_position.y # This position is used to check are any blocks on the way piece is moving now
	
	while check_y != virtual_pos_y:
		# If there's grid floor, move piece to the distance between piece and floor
		if check_y > LuminextGame.BORDER.BOTTOM :
			position.y += LuminextGame.CELL_SIZE * LuminextGame.BORDER.BOTTOM - position.y
			grid_position.y = LuminextGame.BORDER.BOTTOM
			quick_drop.emit(position)
			_place_piece()
			return
		
		var down_left_block_collision : bool = is_instance_valid(game.blocks.get(Vector2i(grid_position.x - 1, check_y), null))
		var down_right_block_collision : bool = is_instance_valid(game.blocks.get(Vector2i(grid_position.x, check_y), null))
		
		if down_right_block_collision or down_left_block_collision:
			# If we're at the top of game field
			if check_y == 0: _slide_piece(check_y, down_left_block_collision, down_right_block_collision)
			else:
				position.y += LuminextGame.CELL_SIZE * (check_y - 1) - position.y
				grid_position.y = ceil(position.y / LuminextGame.CELL_SIZE) as int
				quick_drop.emit(position)
				_place_piece()
				return
		
		check_y += 1 
	
	position.y += distance
	grid_position.y = ceil(position.y / LuminextGame.CELL_SIZE) as int
	quick_drop.emit(position)


## Instantly drops piece to the floor
func _instant_drop() -> void:
	if game.is_paused : await game.paused
	_process_drop(999)


## Slides block at side if it collides with just one block at the bottom, and triggers game over if collides with more blocks
func _slide_piece(check_y : int, down_left_block_collision : bool, down_right_block_collision : bool) -> void:
	if down_right_block_collision and down_left_block_collision:
		game._game_over()
		return
	
	if down_left_block_collision and not down_right_block_collision: 
		if grid_position.x == LuminextGame.BORDER.RIGHT :
			game._game_over()
			return

		_move_piece(MOVE.RIGHT)
		down_right_block_collision = is_instance_valid(game.blocks.get(Vector2i(grid_position.x, check_y), null))
		
		if down_right_block_collision:
			game._game_over()
			return
	
	elif down_right_block_collision and not down_left_block_collision: 
		if grid_position.x == (LuminextGame.BORDER.LEFT + 1):
			game._game_over()
			return

		_move_piece(MOVE.LEFT)
		down_left_block_collision = is_instance_valid(game.blocks.get(Vector2i(grid_position.x - 1, check_y), null))
		
		if down_left_block_collision:
			game._game_over()
			return


## Moves piece into **'direction'** by one game field cell
func _move_piece(direction : int) -> void:
	if direction == MOVE.RIGHT :
		if grid_position.x + 1 > LuminextGame.BORDER.RIGHT:
			return 
		var bottom_right_block_collision : bool = is_instance_valid(game.blocks.get(Vector2i(grid_position.x + 1, grid_position.y), null))
		if bottom_right_block_collision: 
			return 
	else:
		if grid_position.x - 1 < (LuminextGame.BORDER.LEFT + 1):
			return 
		var bottom_left_block_collision : bool = is_instance_valid(game.blocks.get(Vector2i(grid_position.x - 2, grid_position.y), null))
		if bottom_left_block_collision: 
			return 
	
	position.x += LuminextGame.CELL_SIZE * direction
	grid_position.x += direction
	
	game._add_sound(&'move',Vector2(position.x + LuminextGame.FIELD_X_OFFSET, position.y + LuminextGame.FIELD_Y_OFFSET),false,false)
	
	moved.emit(position)
	moved_side.emit(direction)


## Drops piece down by one game field cell
func _drop_piece() -> void:
	# If piece is at game field floor
	if grid_position.y + 1 > LuminextGame.BORDER.BOTTOM :
		position.y += LuminextGame.BORDER.BOTTOM * LuminextGame.CELL_SIZE - position.y
		grid_position.y = LuminextGame.BORDER.BOTTOM
		moved.emit(position)
		_place_piece()
		return
	
	var down_left_block_collision : bool = is_instance_valid(game.blocks.get(Vector2i(grid_position.x - 1, grid_position.y + 1), null))
	var down_right_block_collision : bool = is_instance_valid(game.blocks.get(Vector2i(grid_position.x, grid_position.y + 1), null))
	
	if down_right_block_collision or down_left_block_collision:
		# If we're at the top of game field
		if grid_position.y == -1: _slide_piece(grid_position.y + 2,down_left_block_collision,down_right_block_collision)
		else:
			moved.emit(position)
			_place_piece()
			return
		
	position.y += LuminextGame.CELL_SIZE
	grid_position.y += 1
	moved.emit(position)


## Dashes piece into **'current_dash_side'**
func _dash_piece(delta : float) -> void:
	var success : bool = _process_move(current_dash_side, dash_speed * delta * current_dash_side)
	if not success: 
		_reset_dash()
		return
	
	_toggle_trail(true)
	
	if not is_dashing:
		if (current_dash_side == MOVE.RIGHT): 
			game._add_sound(&'right_dash',Vector2(position.x + LuminextGame.FIELD_X_OFFSET, position.y + LuminextGame.FIELD_Y_OFFSET),false,false)
			dashed.emit(MOVE.RIGHT)
		else: 
			game._add_sound(&'left_dash',Vector2(position.x + LuminextGame.FIELD_X_OFFSET, position.y + LuminextGame.FIELD_Y_OFFSET),false,false)
			dashed.emit(MOVE.LEFT)
	
	is_dashing = true
	moved.emit(position)


## Resets piece dash state
func _reset_dash() -> void:
	is_dashing = false
	current_dash_side = 0
	position.x = grid_position.x * LuminextGame.CELL_SIZE

	_toggle_trail(false)

	moved.emit(position)


## Toggles piece blocks trails
func _toggle_trail(on : bool) -> void:
	if not is_trail_enabled: return

	if on and not is_trailing:
		is_trailing = true
		for block : BlockBase in blocks.values() : block.trail.emitting = true
	elif not on and is_trailing:
		is_trailing = false
		for block : BlockBase in blocks.values() : block.trail.emitting = false


## Places piece down, freeing blocks it contained
func _place_piece() -> void:
	is_removing = true
	landed.emit()
	
	game._add_sound(&'drop',Vector2(position.x + LuminextGame.FIELD_X_OFFSET, position.y + LuminextGame.FIELD_Y_OFFSET),false,false)
	
	# Add blocks to the field from bottom right one, so block movement would be right and blocks won't clip thru eachother
	var blocks_array : Array = blocks.keys()
	blocks_array.reverse()
	for block_pos : Vector2i in blocks_array: 
		game._add_block(Vector2i(grid_position.x + block_pos.x - 1, grid_position.y + block_pos.y - 1), blocks[block_pos].color, blocks[block_pos].special)
	
	var piece_start_pos : Vector2 = Vector2(8,-1)
	if ruleset.rules["save_holder_position"]: piece_start_pos = Vector2(grid_position.x,-1)
	
	game._give_new_piece(piece_start_pos)
	game._prepare_square_check(Rect2i(grid_position.x - 2, grid_position.x + 1, grid_position.y - 2, grid_position.y + 1))


## Properly removes piece from game field field
func _remove() -> void:
	game.piece = null
	
	for block : BlockBase in blocks.values() : 
		block.self_modulate.a = 0.0
		if block.has_node("Special") : block.get_node("Special").self_modulate.a = 0.0
		if is_trail_enabled: block.trail.emitting = false
	
	get_tree().create_timer(0.5).timeout.connect(queue_free)
