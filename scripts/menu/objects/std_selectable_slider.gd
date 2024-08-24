extends MenuSelectableSlider

# warning-ignore-all:return_value_discarded

@export var desc_node_path : NodePath
@export var description : String = '' # Description shown on button select

@export var value_text_path : NodePath


func _ready() -> void:
	connect("selected", Callable(self, "_selected"))
	connect("deselected", Callable(self, "_deselected"))

	await create_tween().tween_interval(0.1).finished

	connect("value_changed", Callable(self, "_on_value_changed"))


func _selected():
	if not desc_node_path.is_empty():
		get_node(desc_node_path).text = description
	
	$Light3D.visible = true


func _deselected():
	$Light3D.visible = false


func _on_value_changed(value):
	get_node(value_text_path).text = Data.profile._return_setting_value_string(call_string, value)
