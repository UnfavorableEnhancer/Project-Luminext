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


extends FX

class_name Square

#-----------------------------------------------------------------------
# Square script
#
# Despite being yet another special effect, square does contain a lot of its own
# functions which help game to manage squares creation/deletion.
#-----------------------------------------------------------------------

var squared_blocks : Array[Block] = [] # All blocks contained inside this square
var adjacent_squares : Dictionary = {} # All adjacent squares "coordinates" : squares

var grid_position : Vector2i = Vector2i(0,0)

var is_removing : bool = false 
var is_refreshing : bool = false

var is_standard_graphics : bool = false # True if block uses standard graphics

func _ready() -> void:
	add_to_group("squares")

	Data.profile.settings_changed.connect(_sync_settings)
	
	# Set z-index to show the most closer to the right down edge square
	z_index = int(position.y + position.x * 10)
	name = "s" + str(position.x + 10) + str(position.y + 10)
	# This object wont be removed when animation end
	is_persistent = true
	
	# Add square texture and color
	var color : Color
	
	if Data.profile.config["video"]["force_standard_blocks"] :
		match parameter:
			BlockBase.BLOCK_COLOR.RED: color = Color("ec7d24")
			BlockBase.BLOCK_COLOR.WHITE : color = Color.WHITE
			BlockBase.BLOCK_COLOR.GREEN : color = Color.GREEN
			BlockBase.BLOCK_COLOR.PURPLE : color = Color.PURPLE
	else:
		var skin_data : SkinData = Data.game.skin.skin_data
		match parameter:
			BlockBase.BLOCK_COLOR.RED: color = skin_data.textures["red_fx"]
			BlockBase.BLOCK_COLOR.WHITE : color = skin_data.textures["white_fx"]
			BlockBase.BLOCK_COLOR.GREEN : color = skin_data.textures["green_fx"]
			BlockBase.BLOCK_COLOR.PURPLE : color = skin_data.textures["purple_fx"]
	
	$Glow.material.set_shader_parameter("tint_color", color)
	
	if Data.profile.config["video"]["square_quality"] == Profile.SQUARES_QUALITY.HIGH: anim = "start"
	elif Data.profile.config["video"]["square_quality"] == Profile.SQUARES_QUALITY.MEDIUM: anim = "med"
	else: anim = "min"
	
	_render()
	
	$S1.animation_finished.connect($S1.stop)
	
	_start()


func _sync_settings() -> void:
	if Data.profile.config["video"]["force_standard_blocks"] : 
		if not is_standard_graphics:
			is_standard_graphics = true
			_refresh_render(true)
	else: 
		if is_standard_graphics:
			is_standard_graphics = false
			_refresh_render(true)


# Renders square visuals
func _render() -> void:
	if Data.profile.config["video"]["force_standard_blocks"] :
		$S1.sprite_frames = Data.blank_skin.textures["square"]
		is_standard_graphics = true
	else:
		$S1.sprite_frames = Data.game.skin.skin_data.textures["square"]
		is_standard_graphics = false
	
	var animation : String

	match parameter:
		BlockBase.BLOCK_COLOR.RED: animation = "rsquare"
		BlockBase.BLOCK_COLOR.WHITE : animation = "wsquare"
		BlockBase.BLOCK_COLOR.GREEN : animation = "gsquare"
		BlockBase.BLOCK_COLOR.PURPLE : animation = "psquare"
		_: animation = "wsquare"

	$S1.animation = animation

	# Assign the first frame of the square animation to the one of the sprites used in square appear animation
	if has_node("S4") : $S4.texture = $S1.sprite_frames.get_frame_texture(animation,0)


# Plays square animation
func _play(color : int) -> void:
	if is_removing : return

	if parameter == color : 
		$S1.set_frame_and_progress(0,0)
		$S1.play()


# Updates square visuals to fit currently loaded skin data with fade-out-in animation
func _refresh_render(quick_effect : bool = false) -> void:
	if is_refreshing: return

	is_refreshing = true
	
	var tween_time : float = 60.0 / Data.game.skin.bpm
	var tween : Tween = create_tween()
	
	if quick_effect : tween_time = 0.25
	
	# Fade-out animation
	tween.tween_property(self,"modulate",Color(1,1,1,0),tween_time).from(Color(1,1,1,1))
	tween.tween_property(self,"modulate",Color(1,1,1,1),tween_time)

	await tween.step_finished

	if Data.profile.config["video"]["force_standard_blocks"] :
		$S1.sprite_frames = Data.blank_skin.textures["square"]
	else:
		$S1.sprite_frames = Data.game.skin.skin_data.textures["square"]

	is_refreshing  = false


# Removes square from game safely
func _remove() -> void:
	if not is_removing:
		is_removing = true
		for block : Block in squared_blocks: 
			if block.squared_by.size() == 1: block._reset(true)
		
		if adjacent_squares.size() > 0:
			for square_pos : Vector2i in adjacent_squares.keys():
				var square : Variant = adjacent_squares[square_pos]
				if is_instance_valid(square):
					square.adjacent_squares.erase(grid_position)
		
		Data.game.squares.erase(grid_position)
		queue_free()


# Check adjacent squares for grouping
func _check_adjacent() -> void:
	var squares : Dictionary = Data.game.squares

	adjacent_squares.clear()

	for i : Vector2i in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]:
		var coord : Vector2i = grid_position + i
		var square : Variant = squares.get(coord, null)
		if is_instance_valid(square):
			adjacent_squares[coord] = squares[coord]
			square.adjacent_squares[grid_position] = self


# Called when square appear animation ends
func _on_ANIM_animation_finished(_anim_name : String) -> void:
	$Glow.free()
	$S3.free()
	$Lines.free()
	$S4.free()
