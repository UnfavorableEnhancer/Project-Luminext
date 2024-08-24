extends Control

func _ready() -> void:
	$Center/Text.modulate.a = 0

# Shows system message which overlays everything
func _show_message(text : String) -> void:
	$Center/Text.text = text
	
	var tween : Tween = create_tween().set_parallel(true)
	
	# Animate appearance
	tween.tween_property($Center/Text,"modulate:a",1.0,1.0).from(0.0)
	tween.tween_property($Center/Text,"scale:y",1.0,0.5).from(0.0)
	tween.tween_interval(5.0)
	tween.chain().tween_property($Center/Text,"modulate:a",0.0,0.5)
	tween.tween_property($Center/Text,"scale:y",0.0,1.0).from(0.5)
	
