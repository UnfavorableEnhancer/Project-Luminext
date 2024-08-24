extends LineEdit

#-----------------------------------------------------------------------
# This text edit is used to input data into some SkinData entry
#-----------------------------------------------------------------------

@onready var editor : MenuScreen = Data.menu.current_screen

@export var data : String = ""
@export_multiline var description : String = ""


func _ready() -> void:
	text_changed.connect(_txt_changed)
	mouse_entered.connect(_selected)


func _txt_changed(new_text : String) -> void:
	editor._edit_skn_text_data(data, new_text)


func _selected() -> void:
	editor._show_description(description)
