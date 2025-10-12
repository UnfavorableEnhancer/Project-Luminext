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


extends BlockBase

##-----------------------------------------------------------------------
## Placed on game field block class
## Has gravity and basic collision detection and can merge with other same colored blocks into squares
##-----------------------------------------------------------------------

class_name Block

signal physics_tick ## Emitted when new physics tick started

signal started_falling ## Emitted when block starts falling
signal landed ## Emitted when block has landed

signal squared ## Emitted when block is squared
signal unsquared ## Emitted when block is freed from all squares

signal set_deleted ## Emitted when block is set to be deleted
signal undeleted ## Emitted when block is freed from deletion

signal scanned ## Emitted when block is scanned by timeline
signal reset ## Emitted when block is reset
signal removed ## Emitted when block is removed

## Avaiable texture overlays
enum OVERLAY {
	ERASE, ## Used when block is being erased by timeline
	DELETE, ## Used when block is turned deletable by some special block
	MULTI ## Used when multi block is being squared
}

const SPRITE_SIZE : float = 64.0 ## Base size of block sprite
const FALL_SPEED : float = LuminextGame.CELL_SIZE * 16 ## Block falling speed in pixels per second

var overlays : Dictionary[int, Sprite2D] = {} ## All created on this block overlays [br] [overlay_type : int] = [Sprite2D]

var is_falling : bool = false ## True if block is currently falling
var is_deletable : bool = false ## If true, block can be deleted by timeline
var is_scanned : bool = false ## True if block is scanned by timeline
var is_removing : bool = false ## True if block is currently removing

var fall_left : float = 0.0 ## Pixels left before falling one cell down
var gravity_multiplier : float = 1.0 ## Current block falling speed multiplier

var squares : Dictionary[Vector2i, bool] ## All squares which contain this block [br] [position : Vector2i] = true
var specials : Dictionary[Vector2i, bool] ## All special blocks which want to delete this block [br] [position : Vector2i] = true


func _init() -> void:
	super()
	
	match Player.config.video["fx_quality"]:
		Config.EFFECTS_QUALITY.MEDIUM: trail_quality = 16
		Config.EFFECTS_QUALITY.HIGH: trail_quality = 24
		Config.EFFECTS_QUALITY.BEAUTIFUL: trail_quality = 32
		_: is_trail_enabled = false


func _ready() -> void:
	gravity_multiplier = ruleset.params["block_gravity"]	
	is_trail_enabled = Player.config.video["block_trail"]
	
	super()

	position.x = grid_position.x * LuminextGame.CELL_SIZE + (LuminextGame.CELL_SIZE / 2.0)
	position.y = grid_position.y * LuminextGame.CELL_SIZE + (LuminextGame.CELL_SIZE / 2.0)

	name = "B" + str(grid_position + Vector2i(10,10)) 
	color_changed.connect(_reset.bind(true))

	scale = Vector2(LuminextGame.REAL_CELL_SIZE / SPRITE_SIZE, LuminextGame.REAL_CELL_SIZE / SPRITE_SIZE)
	
	_start_fall()
	
	# If move was suddenly blocked by something, try moving again
	await physics_tick
	if not is_falling: _start_fall()


## Starts moving block down if there's free space avaiable
func _start_fall() -> void:
	if is_removing : return
	if is_falling : return

	var bottom_block : Block = game.blocks.get(grid_position + Vector2i(0,1), null)
	if (is_instance_valid(bottom_block) and not bottom_block.is_falling and not bottom_block.is_removing) or grid_position.y == LuminextGame.BORDER.BOTTOM:
		return

	is_falling = true
	_reset()
	
	fall_left = LuminextGame.CELL_SIZE
	if is_trail_enabled: trail.emitting = true
	started_falling.emit()


## Called on each physics tick and processes block fall
func _physics(delta : float) -> void:
	physics_tick.emit()

	if not is_falling and fall_left <= 0: return
	
	var speed : float = FALL_SPEED * delta * gravity_multiplier
	
	if fall_left > speed:
		fall_left -= speed
		position.y += speed
		return
	
	game.blocks.erase(grid_position)
	position.y += fall_left
	grid_position.y += 1
	game.blocks[grid_position] = self
	name = "B" + str(grid_position + Vector2i(10,10))
	
	var bottom_block : Block = game.blocks.get(grid_position + Vector2i(0,1), null)
	if (is_instance_valid(bottom_block) and not bottom_block.is_falling and not bottom_block.is_removing) or grid_position.y == 9:
		_land()
	else:
		fall_left = LuminextGame.CELL_SIZE


## Places this block on the game field after fall
func _land() -> void:
	is_falling = false
	fall_left = 0.0
	if is_trail_enabled: trail.emitting = false
	landed.emit()

	await physics_tick
	game._prepare_square_check(Rect2i(grid_position.x - 1, grid_position.x + 1, grid_position.y - 1, grid_position.y + 1))


## Sets block to be deletable by square
func _square_delete(square_position : Vector2i) -> void:
	squares[square_position] = true
	_set_deletable(true)

	if color == BLOCK_COLOR.MULTI: _add_overlay(OVERLAY.MULTI)
	squared.emit()


## Removes square from **'squares'** and tries to set this block undeletable
func _square_undelete(square_position : Vector2i) -> void:
	if not squares.has(square_position) : return
	squares.erase(square_position)

	if squares.is_empty(): 
		unsquared.emit()

		if specials.is_empty():
			_set_deletable(false)


## Sets block to be deletable by special block
func _special_delete(special_block_position : Vector2i) -> void:
	specials[special_block_position] = true
	_set_deletable(true)


## Removes special block from **'specials'** and tries to set this block undeletable
func _special_undelete(special_block_position : Vector2i) -> void:
	if not specials.has(special_block_position) : return

	specials.erase(special_block_position)

	if specials.is_empty() and squares.is_empty(): 
		_set_deletable(false)
	

## Makes this block deletable or not by timeline [br]
## When turning off, checks if any other square or special block wants to delete this block
func _set_deletable(on : bool) -> void:
	if on:
		is_deletable = true
		set_deleted.emit()
		_add_overlay(OVERLAY.DELETE)

	else:
		if not specials.is_empty() : return
		if not squares.is_empty() : return
		
		is_deletable = false
		undeleted.emit()
		_remove_overlay(OVERLAY.DELETE)


## Resets block back to non deletable state no matter what square or special block wants to delete it [br]
## Usually called when block is falling [br]
## If **'try_square_check'** is true, tries square check in local area after reset
func _reset(try_square_check : bool = false) -> void:
	squares.clear()
	specials.clear()
	_set_deletable(false)
	
	if color == BLOCK_COLOR.MULTI: _remove_overlay(OVERLAY.MULTI)
	
	game._remove_square(grid_position)
	game._remove_square(grid_position + Vector2i(-1,-1))
	game._remove_square(grid_position + Vector2i(0,-1))
	game._remove_square(grid_position + Vector2i(-1,0))

	reset.emit()

	if try_square_check : 
		await physics_tick
		game._prepare_square_check(Rect2i(grid_position.x - 2, grid_position.x + 2, grid_position.y - 2, grid_position.y + 2))


## Sets block to scanned by timeline state
func _scan() -> void:
	is_scanned = true
	scanned.emit()
	_add_overlay(OVERLAY.ERASE)
			

## Creates special overlay texture and puts it on block
func _add_overlay(overlay_type : int = OVERLAY.ERASE) -> void:
	if overlays.has(overlay_type) : return

	var overlay_texture : Texture2D
	
	match overlay_type:
		OVERLAY.ERASE : overlay_texture = game.skin.skin_data.textures["erase"]
		OVERLAY.DELETE : overlay_texture = game.skin.skin_data.textures["select"]
		OVERLAY.MULTI : overlay_texture = game.skin.skin_data.textures["multi_mark"]
	
	var overlay_sprite : Sprite2D = Sprite2D.new()
	
	if overlay_type == OVERLAY.DELETE : overlay_sprite.z_index = LuminextGame.BLOCK_DELETE_OVERLAY_Z_INDEX
	else : overlay_sprite.z_index = LuminextGame.BLOCK_OVERLAY_Z_INDEX
	overlay_sprite.z_as_relative = false
	
	# Make it slightly larger to cover block texture
	overlay_sprite.scale = Vector2(1.0625,1.0625)
	overlay_sprite.texture = overlay_texture
	add_child(overlay_sprite)
	overlays[overlay_type] = overlay_sprite

	# overlay appear animation
	create_tween().tween_property(overlay_sprite,"modulate:a",1.0,0.15).from(0.0)


## Removes special overlay texture from block
func _remove_overlay(overlay_type : int = OVERLAY.ERASE) -> void:
	if overlays.has(overlay_type):
		overlays[overlay_type].free()
		overlays.erase(overlay_type)


## Removes this block with special animation
func _remove() -> void:
	if is_removing: return
	is_removing = true
	
	_reset()
	game.blocks.erase(grid_position)

	for overlay : Sprite2D in overlays.values() : overlay.free()
	overlays.clear()

	if special_sprite != null: 
		Player.savedata.stats["total_special_blocks_used"] += 1
		special_sprite.free()
	
	# Set very high z index to make animation visible
	z_index = LuminextGame.REMOVING_BLOCK_Z_INDEX
	z_as_relative = false
	
	removed.emit()
	
	# Play disappear animation
	animation = "die"
	play()
	await animation_finished
	queue_free()
