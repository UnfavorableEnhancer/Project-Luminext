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


extends AnimatedSprite2D

##-----------------------------------------------------------------------
## Base block class which only renders block depending on its current color and special
##-----------------------------------------------------------------------

class_name BlockBase

signal color_changed ## Emitted when block color changes 

## All avaiable block colors
enum BLOCK_COLOR {
	RED, 
	WHITE, 
	GREEN, 
	PURPLE, 
	MULTI, ## Can be combined with any other block color
	GARBAGE, ## Cannot be used in building squares, but would be destroyed if adjacent square explodes
	DARK, ## Cannot be used in building squares
	SPECIAL, ## Used for special blocks animation
} 

## Used in block search functions
enum SIDE {
	UP_LEFT,
	LEFT,
	DOWN_LEFT,
	UP,
	SELF,
	DOWN,
	UP_RIGHT,
	RIGHT,
	DOWN_RIGHT
}

const TRAIL : PackedScene = preload("res://scenery/game/block_trail.tscn") ## Trail effect scene

var game : LuminextGame ## Game instance
var ruleset : Ruleset ## Used by game ruleset

var trail : GPUParticles2D = null ## Trail effect instance
var trail_quality : int = 80 ## Amount of trail effect particles
var is_trail_enabled : bool = false ## If true, trail will be added on block spawn

var is_updating_texture : bool = false ## Is block currently updating its texture
var texture_override : int = Config.BLOCK_TEXTURE_OVERRIDE.NONE ## Current block texture override

var is_ghost : bool = false ## Is this block a ghost one

var color : int = BLOCK_COLOR.RED ## Current block color
var special : StringName ## Block special ability name

var special_sprite : AnimatedSprite2D = null ## Block special ability overlay sprite instance

var grid_position : Vector2i = Vector2i(0,0) ## Current block position on game field grid


func _init() -> void:
	Player.config.changed.connect(_sync_settings)

	match Player.config.video["fx_quality"]:
		Config.EFFECTS_QUALITY.MINIMUM: trail_quality = 8
		Config.EFFECTS_QUALITY.LOW: trail_quality = 24
		Config.EFFECTS_QUALITY.MEDIUM: trail_quality = 48
		Config.EFFECTS_QUALITY.HIGH: trail_quality = 64
		Config.EFFECTS_QUALITY.BEAUTIFUL: trail_quality = 80


## Syncs settings with current profile
func _sync_settings() -> void:
	var new_texture_override : int = Player.config.video["blocks_replacement"]
	if texture_override != new_texture_override:
		texture_override = new_texture_override
		_update_render()


func _ready() -> void:
	texture_override = Player.config.video["blocks_replacement"]
	add_to_group("entity")
	_render()

	if game.is_skin_transition_now : _update_render()

	# Animation must stop on finish, so we would be able to run animation again at specific moment
	animation_finished.connect(func() -> void: if animation != &"die": stop())


## Adds trail to this block if enabled
func _setup_trail() -> void:
	if not is_trail_enabled: return
	if trail: return

	trail = TRAIL.instantiate()
	trail.texture = sprite_frames.get_frame_texture(animation,0)
	trail.amount = trail_quality
	add_child(trail)


## Changes block textures to fit currently loaded skin data
func _render() -> void:
	match texture_override:
		Config.BLOCK_TEXTURE_OVERRIDE.NONE : 
			if game.is_skin_transition_now : sprite_frames = game.old_skin_data.textures["block"]
			else : sprite_frames = game.skin.skin_data.textures["block"]
		Config.BLOCK_TEXTURE_OVERRIDE.STANDARD : 
			sprite_frames = Data.blank_skin.textures["block"]
	
	if is_ghost:
		modulate.a = 0.5

	match color:
		BLOCK_COLOR.RED : animation = &"red"
		BLOCK_COLOR.WHITE : animation = &"white"
		BLOCK_COLOR.GREEN : animation = &"green"
		BLOCK_COLOR.PURPLE : animation = &"purple"
		BLOCK_COLOR.MULTI : animation = &"multi"
		BLOCK_COLOR.GARBAGE : animation = &"garbage"
		BLOCK_COLOR.DARK : animation = &"garbage"
	
	if not trail : _setup_trail()
	else : trail.texture = sprite_frames.get_frame_texture(animation,0)
	
	if special.is_empty():
		if special_sprite != null:
			special_sprite.queue_free()
			special_sprite = null
	else:
		_render_special()

	
## Changes block special overlay texture to fit currently loaded skin data
func _render_special() -> void:
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

		special_sprite.z_as_relative = false
		special_sprite.z_index = LuminextGame.SPECIAL_BLOCKS_Z_INDEX
		
		# Animation must stop on finish, so we would be able to run animation again at specific moment, which is defined by skin data
		special_sprite.animation_finished.connect(special_sprite.stop)
		add_child(special_sprite)
	
	match texture_override:
		Config.BLOCK_TEXTURE_OVERRIDE.NONE : 
			if game.is_skin_transition_now : special_sprite.sprite_frames = game.old_skin_data.textures["special"]
			else : special_sprite.sprite_frames = game.skin.skin_data.textures["special"]
		Config.BLOCK_TEXTURE_OVERRIDE.STANDARD : 
			special_sprite.sprite_frames = Data.blank_skin.textures["special"]
	
	special_sprite.animation = special


## Updates block textures to fit currently loaded skin data with fade-out animation [br]
## Doesn't work if texture override is enabled [br]
func _update_render(transition_time : float = 0.25) -> void:
	if is_updating_texture: return
	is_updating_texture = true

	if transition_time < 0.01:
		_render()
		is_updating_texture = false
		return

	var tween : Tween = create_tween()

	# Fade-out-in animation
	tween.tween_property(self,"modulate:a",0.0,transition_time).from(1.0)
	tween.tween_callback(_render)
	tween.tween_property(self,"modulate:a",1.0,transition_time)

	if game.is_changing_skin_now:
		tween.custom_step((Time.get_ticks_msec() - game.skin_transition_start_time) / 1000.0)

	await tween.finished
	is_updating_texture = false


## Changes block color and updates its textures
func _change_color(new_color : int) -> void:
	color = new_color
	_update_render()

	color_changed.emit()


## Returns adjacent block instance at passed **'direction'**[br]
func _find_block(direction : int) -> Block:
	var side_vector : Vector2i = grid_position
	match direction:
		SIDE.UP_LEFT : side_vector += Vector2i(-1, -1)
		SIDE.LEFT : side_vector += Vector2i(-1, 0)
		SIDE.DOWN_LEFT : side_vector += Vector2i(-1, 1)
		SIDE.UP : side_vector += Vector2i(0, -1)
		SIDE.DOWN : side_vector += Vector2i(0, 1)
		SIDE.UP_RIGHT : side_vector += Vector2i(1, -1)
		SIDE.RIGHT : side_vector += Vector2i(1, 0)
		SIDE.DOWN_RIGHT : side_vector += Vector2i(1, 1)
	
	var block : Block = game.blocks.get(side_vector, null)
	if not is_instance_valid(block) : return null
	else : return block


## Called by call_group function and is used to simultaneously play specified color animation
func _play(anim_color : StringName) -> void:
	if animation == &"die" : return
	if is_ghost : return

	var anim_color_value : int = color

	match anim_color:
		&"red" : anim_color_value = BLOCK_COLOR.RED
		&"white" : anim_color_value = BLOCK_COLOR.WHITE
		&"green" : anim_color_value = BLOCK_COLOR.GREEN
		&"purple" : anim_color_value = BLOCK_COLOR.PURPLE
		&"special" : anim_color_value = BLOCK_COLOR.SPECIAL
	
	if anim_color_value == BLOCK_COLOR.SPECIAL and special_sprite != null:
		set_frame_and_progress(0,0)
		play()
		special_sprite.set_frame_and_progress(0,0)
		special_sprite.play()
		return

	if anim_color_value == color: 
		set_frame_and_progress(0,0)
		play()
		return
	
	# Some special blocks are tied to white color animation timings
	if anim_color_value == BLOCK_COLOR.WHITE and color > BLOCK_COLOR.PURPLE: 
		set_frame_and_progress(0,0)
		play()
