extends UIElement


func _ready() -> void:
	$Charge.scale.x = 0 


func _change_style(_style : int, skin_data : SkinData = null) -> void:
	create_tween().tween_property($Charge, "color", skin_data.textures["timeline_color"], 1.0)


func _level_up() -> void:
	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property($LevelUp, "modulate:a", 0.0, 1.0).from(1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property($LevelUp, "scale", Vector2($Charge.scale.x * 6,6), 1.0).from(Vector2($Charge.scale.x,1)).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func _change_progress(value : float) -> void:
	create_tween().tween_property($Charge, "scale:x", value, 1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

