extends Node2D

class_name UIElement


func _ready() -> void:
	pass


func _play_animation(anim_name : String) -> void:
	$A.play(anim_name)


# Called by foreground and changes this UIElement design
func _change_style(_style : int, _skin_data : SkinData = null) -> void:
	pass


# Called when visual options were changed
func _update_settings() -> void:
	pass
