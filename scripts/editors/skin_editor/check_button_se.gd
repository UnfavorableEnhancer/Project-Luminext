extends CheckButton

#-----------------------------------------------------------------------
# This check button is used to toggle some entries
#-----------------------------------------------------------------------

@onready var editor : MenuScreen = Data.menu.get_node("Skin Editor")

@export var entry_name : String = "" # Data entry this button edits
@export_multiline var description : String = "" # Description shown when button is hovered by mouse


func _ready() -> void:
	toggled.connect(_toggle)
	mouse_entered.connect(_selected)
	
	if text == "ON" : set_pressed_no_signal(true) 


# Called when button is toggled 
func _toggle(on : bool) -> void:
	editor._toggle_skn_data(entry_name, on)
	text = "ON" if on else "OFF"


# Called when hovered by mouse
func _selected() -> void:
	editor._show_description(description)
