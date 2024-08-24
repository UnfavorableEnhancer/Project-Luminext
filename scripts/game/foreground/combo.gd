extends UIElement


func _ready() -> void:
	$H.modulate = Color(1,0,0,0)


# Displays combo
func _set_combo(value : int) -> void:
	if value > 1: 
		$H.modulate = Color(1,1,1,0.75)
		$H/combo.text = "x" + str(value)
	else : 
		if $H.modulate == Color(1,0,0,0) : return
		var tween : Tween = create_tween().set_parallel(true)
		tween.tween_property($H, "modulate", Color(1,0,0,0), 0.5).from(Color(1,1,1,1))
