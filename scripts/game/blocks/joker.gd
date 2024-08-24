extends Block

# Joker (Shuffle) block changes color every timeline pass

class_name Joker


func _ready() -> void:
	super()

	Data.game.timeline_started.connect(_joke)
	# Make it slightly darker, than other blocks so it can be distinguished
	self_modulate = Color.LIGHT_GRAY


# Changes block color to random one
func _joke() -> void:
	if not is_falling and not is_tweening and not is_dying:
		var colors : Array[int] = []

		if Data.profile.config["gameplay"]["red"] : colors.append(BLOCK_COLOR.RED)
		if Data.profile.config["gameplay"]["white"] : colors.append(BLOCK_COLOR.WHITE)
		if Data.profile.config["gameplay"]["green"] : colors.append(BLOCK_COLOR.GREEN)
		if Data.profile.config["gameplay"]["purple"] : colors.append(BLOCK_COLOR.PURPLE)
		
		color = colors.pick_random()
		
		var tween : Tween = create_tween()
		var tween_time : float = 60.0 / Data.game.skin.bpm / 2.0
		tween.tween_property(self, "modulate:a", 0.0, tween_time / 2.0)
		tween.tween_property(self, "modulate:a", 1.0, tween_time / 2.0)
		await tween.step_finished
		_render()

		await get_tree().create_timer(0.01).timeout
		Data.game._square_check(grid_position.x)
