extends FX

class_name Square

#-----------------------------------------------------------------------
# Square script
#
# Despite being yet another special effect, square does contain a lot of its own
# functions which help game to manage squares creation/deletion.
#-----------------------------------------------------------------------

var squared_blocks : Array[Block] = [] # All blocks contained inside this square

var grid_position : Vector2i = Vector2i(0,0)

var is_removing : bool = false 
var is_looping : bool = false
var is_refreshing : bool = false

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
	_start()


func _sync_settings() -> void:
	_refresh_render(true)


# Renders square visuals
func _render() -> void:
	if Data.profile.config["video"]["force_standard_blocks"] :
		$S1.sprite_frames = Data.blank_skin.textures["square"]
	else:
		$S1.sprite_frames = Data.game.skin.skin_data.textures["square"]
	
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
	match parameter:
		"rsquare" : if color == BlockBase.BLOCK_COLOR.RED : $S1.play()
		"wsquare" : if color == BlockBase.BLOCK_COLOR.WHITE : $S1.play()
		"gsquare" : if color == BlockBase.BLOCK_COLOR.GREEN : $S1.play()
		"psquare" : if color == BlockBase.BLOCK_COLOR.PURPLE : $S1.play()


# Updates square visuals to fit currently loaded skin data with fade-out-in animation
func _refresh_render(quick_effect : bool = false) -> void:
	if is_refreshing: return

	is_refreshing = true
	
	var tween_time : float = 60.0 / Data.game.skin.bpm
	var tween : Tween = create_tween()
	
	if quick_effect:
		# Fade-out animation
		tween.tween_property(self,"modulate",Color(1,1,1,0),0.25).from(Color(1,1,1,1))
		tween.tween_property(self,"modulate",Color(1,1,1,1),0.25)

		await tween.step_finished
	else:
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
		Data.game.squares.erase(grid_position)
		queue_free()


# Called when square animation is finished, and it resets animation
func _on_S1_animation_finished() -> void:
	$S1.stop()
	if is_looping: $S1.play()


# Called when square appear animation ends
func _on_ANIM_animation_finished(_anim_name : String) -> void:
	$Glow.free()
	$S3.free()
	$Lines.free()
	$S4.free()
