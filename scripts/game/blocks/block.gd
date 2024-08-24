extends BlockBase

#-----------------------------------------------------------------------
# In-field block class
#
# Used to be placed into game field and has gravity and colision.
#-----------------------------------------------------------------------

class_name Block

signal started_moving # Emitted when block starts moving
signal reset # Emitted when block resets
signal falled_down # Emitted when block falled down
signal deleted # Emitted when block is deleted
signal squared # Emitted when block is squared

# Various overlays which might render on top of block
enum OVERLAY_MARK {
	ERASE, # Used when block is being erased by timeline
	DELETE, # Used when block is turned deletable by some special block
	MULTI # Used when multi block is being squared
}

const FALL_SPEED : float = 0.065 # Base gravity speed

var marks : Array = []

var is_tweening : bool = false # True if this block fall animation is currently playing
var is_falling : bool = false
var is_dying : bool = false
var is_scanned : bool = false # True if is scanned by timeline
var has_moved : bool = true # True if block has moved at least one cell down

var squared_by : Array = [] # Array of squares in which this block is inside


func _init() -> void:
	super()
	
	is_trail_enabled = Data.profile.config["video"]["block_trail"]
	match Data.profile.config["video"]["fx_quality"]:
		Profile.EFFECTS_QUALITY.MEDIUM: trail_quality = 16
		Profile.EFFECTS_QUALITY.HIGH: trail_quality = 24
		Profile.EFFECTS_QUALITY.BEAUTIFUL: trail_quality = 48
		_: is_trail_enabled = false


func _ready() -> void:
	super()
	
	position = Vector2(grid_position.x * 68 - 34, grid_position.y * 68 + 32) 
	name = str(grid_position + Vector2i(10,10)) 
	color_changed.connect(_reset.bind(true))
	
	if grid_position.y <= -1:
		queue_free()
		return
	
	_fall()
	
	# If move was suddenly blocked by something, try moving again
	await get_tree().create_timer(FALL_SPEED + 0.01).timeout
	if not is_falling: _fall()


# Moves block down one game field cell
# Called recursevly and calls square check function when lands
func _fall() -> void:
	if is_dying: return
	if is_tweening: return

	var blocks : Dictionary = Data.game.blocks
	
	# Check if there's another block at bottom or we are at field floor
	if blocks.has(grid_position + Vector2i(0,1)) or grid_position.y == 9:
		is_falling = false
		falled_down.emit()

		blocks[grid_position] = self

		if is_trail_enabled and is_instance_valid(trail):
			trail.emitting = false
		
		# This delay is needed for proper square check work
		await get_tree().create_timer(0.001).timeout
		# If block never moved, square check wouldn't be called
		if has_moved: Data.game._square_check(grid_position.x)
		has_moved = false
		
		position = Vector2(grid_position.x * 68 - 34, grid_position.y * 68 + 32)
		return
	
	if not is_falling:
		is_falling = true
		_reset(true)
		started_moving.emit()
	
	has_moved = true

	# Update block position
	blocks.erase(grid_position)
	blocks[grid_position + Vector2i(0,1)] = self
	grid_position.y += 1
	name = str(grid_position + Vector2i(10,10)) 
	
	# Animate motion
	is_tweening = true
	var fall_time : float = FALL_SPEED * (1.0 / Data.profile.config["gameplay"]["block_gravity"])
	var fall_tween : Tween = create_tween()
	fall_tween.tween_property(self,"position",Vector2(position.x,position.y + 68),fall_time)
	await fall_tween.step_finished
	is_tweening = false

	_fall()


# Resets block to it's normal state
func _reset(remove_squares : bool) -> void:
	Data.game.delete.erase(grid_position)
	
	for mark : Sprite2D in marks : mark.free()
	marks.clear()
	
	if remove_squares:
		for square : Variant in squared_by: 
			if not is_instance_valid(square) : continue
			
			if not square.is_removing: 
				square._remove()
	
		squared_by.clear()
	
	reset.emit()


# Makes this block deletable by timeline
func _make_deletable() -> void:
	Data.game.delete[grid_position] = self


# Called when block is squared
func _square(square : FX) -> void :
	_make_deletable()
	
	squared_by.append(square)
	square.squared_blocks.append(self)
	squared.emit()

	if color == BLOCK_COLOR.MULTI: _add_mark(OVERLAY_MARK.MULTI)


# Creates some special mark for block which overlays texture 
func _add_mark(mark_style : int = OVERLAY_MARK.ERASE) -> void:
	var mark_node_name : String
	var mark_node_texture : Texture2D
	
	match mark_style:
		OVERLAY_MARK.ERASE: 
			mark_node_name = "Erase"
			mark_node_texture = Data.game.skin.skin_data.textures["erase"]
		OVERLAY_MARK.DELETE: 
			mark_node_name = "Delete"
			mark_node_texture = Data.game.skin.skin_data.textures["select"]
		OVERLAY_MARK.MULTI: 
			mark_node_name = "Multi"
			mark_node_texture = Data.game.skin.skin_data.textures["multi_mark"]
	
	if not has_node(mark_node_name):
		var mark_sprite : Sprite2D = Sprite2D.new()
		mark_sprite.name = mark_node_name
		
		if mark_style == OVERLAY_MARK.DELETE :
			mark_sprite.z_index = 1
		else : 
			mark_sprite.z_index = 198
		
		# Make it slightly larger to cover block texture
		mark_sprite.scale = Vector2(1.0625,1.0625)
		
		mark_sprite.texture = mark_node_texture
		add_child(mark_sprite)
		marks.append(mark_sprite)
		# TODO : Test is this shit needed if mark_style != OVERLAY_MARK.ERASE : marks.append(mark_sprite)

		# Mark appear animation
		create_tween().tween_property(mark_sprite,"modulate",Color(1,1,1,1),0.15).from(Color(1,1,1,0))


# Removes block safely, with special disappear animation
func _free() -> void:
	if is_dying: return
	is_dying = true
	name = "dead"
	
	_reset(true)
	Data.game.blocks.erase(grid_position)

	for mark : Sprite2D in marks : mark.free()
	if is_instance_valid(special_sprite): 
		Data.profile.progress["stats"]["total_special_blocks_used"] += 1
		special_sprite.free()
	
	# Set very high z index to make animation visible
	z_index = 200
	
	deleted.emit()
	
	# Play disappear animation
	animation = "die"
	play()
	await animation_finished
	
	queue_free()
