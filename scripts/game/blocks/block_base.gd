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


extends AnimatedSprite2D

#-----------------------------------------------------------------------
# Base block class
#
# Does block visuals and animation rendering
# Other logic must be added by inheriting this class
#-----------------------------------------------------------------------

class_name BlockBase

signal color_changed # Emitted when block color changes (type_changed)

# All avaiable block colors
enum BLOCK_COLOR {
	RED, 
	WHITE, 
	GREEN, 
	PURPLE, 
	MULTI, # Can be combined with any other block color
	GARBAGE, # Cannot be used in building squares, but would be destroyed if adjacent square explodes
	DARK, # Cannot be used in building squares
	SPECIAL, # Used for special blocks animation
	NULL # Invalid color
} 

# Used in block search functions
# 0 3 6
# 1 * 7
# 2 5 8
enum SIDE {UP_LEFT,LEFT,DOWN_LEFT,UP,SELF,DOWN,UP_RIGHT,RIGHT,DOWN_RIGHT}

const TRAIL : PackedScene = preload("res://scenery/game/block_trail.tscn") # Trail effect scene

var trail : GPUParticles2D = null # Trail effect instance
var trail_quality : int = 80 # How much particles trail effect will use
var is_trail_enabled : bool = false # If true, trail will be added on block spawn

var is_refreshing : bool = false # Is block currently changing its visuals
var is_animation_looping : bool = false # Should animation loop

var color : int = BLOCK_COLOR.RED # Current block color which is used in making squares
var special : StringName # Block special ability name

var special_sprite : AnimatedSprite2D = null

# Block coordinates transposed to the game field coordinates
var grid_position : Vector2i = Vector2i(0,0)


func _init() -> void:
	Data.profile.settings_changed.connect(_sync_settings)

	if Data.profile.config["video"]["force_standard_blocks"] : sprite_frames = Data.blank_skin.textures["block"]
	else : sprite_frames = Data.game.skin.skin_data.textures["block"]


func _sync_settings() -> void:
	_refresh_render(true)


func _ready() -> void:
	add_to_group("blocks")
	
	# Animation must stop on finish, so we would be able to run animation again at specific moment, which is defined by skin data
	animation_finished.connect(_stop_anim)


func _setup_trail() -> void:
	if not is_trail_enabled: return
	if trail: return
	
	match Data.profile.config["video"]["fx_quality"]:
		Profile.EFFECTS_QUALITY.MINIMUM: trail_quality = 16
		Profile.EFFECTS_QUALITY.LOW: trail_quality = 32
		Profile.EFFECTS_QUALITY.MEDIUM: trail_quality = 64
		Profile.EFFECTS_QUALITY.HIGH: trail_quality = 96
		Profile.EFFECTS_QUALITY.BEAUTIFUL: trail_quality = 128

	trail = TRAIL.instantiate()
	trail.texture = sprite_frames.get_frame_texture(animation,0)
	trail.amount = trail_quality
	add_child(trail)


# Updates block visuals to fit currently loaded skin data with fade-out-in animation
func _refresh_render(quick_effect : bool = false) -> void:
	if is_refreshing: return
	
	is_refreshing = true
	
	var skin_data : SkinData = Data.game.skin.skin_data
	var tween_time : float = 60.0 / skin_data.metadata.bpm * 1.5
	var tween : Tween = create_tween()
	
	if quick_effect:
		# Fade-in from dark animation
		tween.tween_property(self,"modulate",Color(1,1,1,0),0.25).from(Color(1,1,1,1))
		tween.tween_property(self,"modulate",Color(1,1,1,1),0.25).from(Color(1,1,1,0))

		await tween.step_finished
	else:
		# Fade-out-in animation
		tween.tween_property(self,"modulate",Color(1,1,1,0),tween_time).from(Color(1,1,1,1))
		tween.tween_property(self,"modulate",Color(1,1,1,1),tween_time)

		await tween.step_finished

	if not Data.profile.config["video"]["force_standard_blocks"]: 
		sprite_frames = skin_data.textures["block"]
		if is_instance_valid(special_sprite): 
			special_sprite.sprite_frames = skin_data.textures["special"]
	else:
		sprite_frames = Data.blank_skin.textures["block"]
		if is_instance_valid(special_sprite):
			special_sprite.sprite_frames = Data.blank_skin.textures["special"]
	
	if is_trail_enabled:
		trail.texture = sprite_frames.get_frame_texture(animation,0)
	
	is_refreshing  = false


# Changes block visuals to fit currently loaded skin data and own color and special properties
func _render() -> void:
	if color == BLOCK_COLOR.NULL : return
	
	match color:
		BLOCK_COLOR.RED : animation = &"red"
		BLOCK_COLOR.WHITE : animation = &"white"
		BLOCK_COLOR.GREEN : animation = &"green"
		BLOCK_COLOR.PURPLE : animation = &"purple"
		BLOCK_COLOR.MULTI : animation = &"multi"
		BLOCK_COLOR.GARBAGE : animation = &"garbage"
		BLOCK_COLOR.DARK : animation = &"garbage"

	color_changed.emit()
	_setup_trail()
	
	if not special.is_empty():
		# Ignore "joker" block since it just changes block color and doesnt have other visuals to add
		if special == &"joker": return
		
		match color:
			BLOCK_COLOR.RED : animation = &"rchain"
			BLOCK_COLOR.WHITE : animation = &"wchain"
			BLOCK_COLOR.GREEN : animation = &"gchain"
			BLOCK_COLOR.PURPLE : animation = &"pchain"
		
		if special_sprite == null:
			special_sprite = AnimatedSprite2D.new()
			special_sprite.name = "Special"
			special_sprite.frames = Data.game.skin.skin_data.textures["special"]
			special_sprite.animation = special
			
			# Animation must stop on finish, so we would be able to run animation again at specific moment, which is defined by skin data
			special_sprite.animation_finished.connect(special_sprite.stop)
			add_child(special_sprite)
	else:
		if is_instance_valid(special_sprite):
			special_sprite.queue_free()


# Returns adjacent block at side
func _find_block(side : int) -> Block:
	var look : Vector2i = BlockBase._look(side, grid_position)
	if Data.game.blocks.has(look): return Data.game.blocks[look]
	else : return null


# Helper function for searching surrounding blocks
static func _look(side : int, from_position : Vector2i) -> Vector2i:
	var vector : Vector2i = Vector2i(0,0)
	match side:
		SIDE.UP_LEFT : vector = Vector2i(-1, -1)
		SIDE.LEFT : vector = Vector2i(-1, 0)
		SIDE.DOWN_LEFT : vector = Vector2i(-1, 1)
		SIDE.UP : vector = Vector2i(0, -1)
		SIDE.DOWN : vector = Vector2i(0, 1)
		SIDE.UP_RIGHT : vector = Vector2i(1, -1)
		SIDE.RIGHT : vector = Vector2i(1, 0)
		SIDE.DOWN_RIGHT : vector = Vector2i(1, 1)
	
	return from_position + vector


# Called by call_group function and is used to simultaneously play specified color animation
func _play(anim_color : int = BLOCK_COLOR.RED) -> void:
	if animation == &"die" : return
	
	if anim_color == BLOCK_COLOR.SPECIAL and special_sprite:
		play()
		$Special.play()
	
	else:
		if anim_color == color: play()
		# Some special blocks are tied to white color animation timings
		elif anim_color == BLOCK_COLOR.WHITE and color > 3: play()


# Stops block animation back to first frame, so we can later play it again at specific moment
func _stop_anim() -> void:
	if animation != &"die": stop()
	if is_animation_looping: play()
