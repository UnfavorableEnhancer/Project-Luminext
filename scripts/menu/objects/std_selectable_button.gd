extends MenuSelectableButton

# warning-ignore-all:return_value_discarded

@export var desc_node_path : NodePath
@export var description : String = "" # Description shown on button select


func _ready():
	connect("selected", Callable(self, "_selected"))
	connect("deselected", Callable(self, "_deselected"))

	if work_mode == WORK_MODE.TOGGLE:
		connect("selection_toggled", Callable(self, "_toggled"))
	else:
		if has_node("IO"):
			$IO.visible = false


func _selected():
	if not desc_node_path.is_empty():
		get_node(desc_node_path).text = description
	
	modulate = Color.CYAN


func _deselected():
	modulate = Color.WHITE


func _toggled(is_toggled):
	$IO.text = tr("ON") if is_toggled else tr("OFF")
