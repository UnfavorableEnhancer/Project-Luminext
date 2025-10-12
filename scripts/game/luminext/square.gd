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

##-----------------------------------------------------------------------
## Square contains several blocks of same color and can be deleted by timeline
##-----------------------------------------------------------------------

class_name Square

var game : LuminextGame ## Game instance

var grid_position : Vector2i = Vector2i(0,0) ## Current square position on game field grid

var color : int = BlockBase.BLOCK_COLOR.WHITE ## Current square color
var start_animation : String = "start" ## Name of the animation which must be started on square spawn

var is_updating_texture : bool = false ## Is square currently updating its texture
var texture_override : int = Config.BLOCK_TEXTURE_OVERRIDE.NONE ## Current block texture override

var squared_blocks : Array ## All squared by this square blocks from top left to bottom right


func _init() -> void:
	Player.config.changed.connect(_sync_settings)


func _ready() -> void:
	position.x = (grid_position.x + 1) * LuminextGame.CELL_SIZE
	position.y = (grid_position.y + 1) * LuminextGame.CELL_SIZE

	# Set z-index to show the most closer to the right down edge square
	z_as_relative = true
	z_index = int(grid_position.y + grid_position.x * 10)
	name = "s" + str(position.x + 10) + str(position.y + 10)
	
	texture_override = Player.config.video["blocks_replacement"]
	add_to_group("entity")
	_render()

	if game.is_skin_transition_now : _update_render()

	# Animation must stop on finish, so we would be able to run animation again at specific moment
	$S1.animation_finished.connect($S1.stop)
	$ANIM.play(start_animation)


func _sync_settings() -> void:
	var new_texture_override : int = Player.config.video["blocks_replacement"]
	if texture_override != new_texture_override:
		texture_override = new_texture_override
		_update_render()


## Changes square textures to fit currently loaded skin data
func _render() -> void:
	var shade_color : Color = Color.WHITE

	match texture_override:
		Config.BLOCK_TEXTURE_OVERRIDE.NONE:
			var skin_data : SkinData

			if game.is_skin_transition_now : skin_data = game.old_skin_data
			else : skin_data = game.skin.skin_data

			$S1.sprite_frames = skin_data.textures["square"]

			match color:
				BlockBase.BLOCK_COLOR.RED: 
					shade_color = skin_data.textures["red_fx"]
					$S1.animation = "rsquare"
				BlockBase.BLOCK_COLOR.WHITE: 
					shade_color = skin_data.textures["white_fx"]
					$S1.animation = "wsquare"
				BlockBase.BLOCK_COLOR.GREEN: 
					shade_color = skin_data.textures["green_fx"]
					$S1.animation = "gsquare"
				BlockBase.BLOCK_COLOR.PURPLE: 
					shade_color = skin_data.textures["purple_fx"]
					$S1.animation = "psquare"
				_:
					shade_color = skin_data.textures["white_fx"]
					$S1.animation = "wsquare"
				
		Config.BLOCK_TEXTURE_OVERRIDE.STANDARD:
			$S1.sprite_frames = Data.blank_skin.textures["square"]
			match color:
				BlockBase.BLOCK_COLOR.RED: 
					shade_color = Color("ec7d24")
					$S1.animation = "rsquare"
				BlockBase.BLOCK_COLOR.WHITE: 
					shade_color = Color.WHITE
					$S1.animation = "wsquare"
				BlockBase.BLOCK_COLOR.GREEN: 
					shade_color = Color.GREEN
					$S1.animation = "gsquare"
				BlockBase.BLOCK_COLOR.PURPLE: 
					shade_color = Color.PURPLE
					$S1.animation = "psquare"
				_:
					shade_color = Color.WHITE
					$S1.animation = "wsquare"
	
	$Glow.material.set_shader_parameter("tint_color", shade_color)
	
	match Player.config.video["fx_quality"]:
		Config.EFFECTS_QUALITY.MINIMUM: start_animation = "min"
		Config.EFFECTS_QUALITY.LOW: start_animation = "min"
		Config.EFFECTS_QUALITY.MEDIUM: start_animation = "med"
		Config.EFFECTS_QUALITY.HIGH: start_animation = "start"
		Config.EFFECTS_QUALITY.BEAUTIFUL: start_animation = "start"

	# Assign the first frame of the square animation to the one of the sprites used in square appear animation
	if has_node("S4") : 
		$S4.texture = $S1.sprite_frames.get_frame_texture($S1.animation,0)


## Updates square textures to fit currently loaded skin data with fade-out animation [br]
## Doesn't work if texture override is enabled
func _update_render(transition_time : float = 0.25) -> void:
	if is_updating_texture: return
	is_updating_texture = true
	
	if transition_time < 0.01:
		_render()
		is_updating_texture = false
		return

	var tween : Tween = create_tween()
	
	# Fade-out animation
	tween.tween_property(self,"modulate:a",0.0,transition_time).from(1.0)
	tween.tween_callback(_render)
	tween.tween_property(self,"modulate:a",1.0,transition_time)

	if game.is_changing_skin_now:
		tween.custom_step((Time.get_ticks_msec() - game.skin_transition_start_time) / 1000.0)

	await tween.finished
	is_updating_texture  = false


## Removes this square
func _remove() -> void:
	for block : Block in squared_blocks:
		if is_instance_valid(block) : block._square_undelete(grid_position)

	game.squares.erase(grid_position)
	if game.new_squares.has(grid_position) : 
		game.new_squares.erase(grid_position)

	queue_free()


## Plays square animation
func _play(anim_color : StringName) -> void:
	var anim_color_value : int = color

	match anim_color:
		&"red" : anim_color_value = BlockBase.BLOCK_COLOR.RED
		&"white" : anim_color_value = BlockBase.BLOCK_COLOR.WHITE
		&"green" : anim_color_value = BlockBase.BLOCK_COLOR.GREEN
		&"purple" : anim_color_value = BlockBase.BLOCK_COLOR.PURPLE
		&"special" : anim_color_value = BlockBase.BLOCK_COLOR.SPECIAL

	if color == anim_color_value : 
		$S1.set_frame_and_progress(0,0)
		$S1.play()


## Called when square appear animation ends and removes unnessessary sprites
func _on_ANIM_animation_finished(_anim_name : String) -> void:
	$Glow.free()
	$S3.free()
	$Lines.free()
	$S4.free()
