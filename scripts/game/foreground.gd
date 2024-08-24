extends Node2D

signal style_changed

var ui_elements : Dictionary

var is_changing : bool = false
var is_song_looping : bool = false


# Resets background to its initial empty state
func _reset() -> void:
	for element : UIElement in ui_elements:
		ui_elements[element].queue_free()
		ui_elements.erase(element)


# Adds UIElement
func _add_ui_element(element_name : String) -> UIElement:
	var element_instance : UIElement = load("res://scenery/game/foreground/" + element_name + ".tscn").instantiate()
	ui_elements[element_name] = element_instance
	add_child(element_instance)
	return element_instance

# Removes UIElement
func _remove_ui_element(element_name : String) -> void:
	if ui_elements.has(element_name):
		ui_elements[element_name].queue_free()
		ui_elements.erase(element_name)


# Changes style of all UIElements with fade-out-in animation, 'speed' defines speed of that animation
func _change_style(style : int, skin_data : SkinData, speed : float = 1.0) -> void:
	if is_changing : return
	is_changing = true

	create_tween().tween_property(self, "modulate:a", 0.0, speed / 2.0)

	await get_tree().create_timer(speed / 2.0).timeout

	for ui_element : UIElement in ui_elements.values():
		ui_element._change_style(style, skin_data)

	create_tween().tween_property(self, "modulate:a", 1.0, speed / 2.0)

	style_changed.emit()
	is_changing = false
