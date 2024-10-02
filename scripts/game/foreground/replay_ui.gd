extends UIElement

func _ready() -> void:
	var tween : Tween = create_tween().set_loops()
	tween.tween_property($text, "modulate", Color(0,0,0,0), 1.0)
	tween.tween_property($text, "modulate", Color.WHITE, 1.0)
