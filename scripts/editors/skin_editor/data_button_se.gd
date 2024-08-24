extends Button

#-----------------------------------------------------------------------
# This button is used to input data into SkinData 'stream' dictionary which usually contain paths
#-----------------------------------------------------------------------

@onready var editor : MenuScreen = Data.menu.screens["skin_editor"]

@export var data_name : String = "" # Data name this button edits
@export var file_dialog_to_open : String = "" # What format is needed to load
@export_multiline var description : String = ""


func _ready() -> void:
	add_to_group("data_buttons")
	
	gui_input.connect(_on_press)
	mouse_entered.connect(_selected)
	
	#text = tr("EDITOR_INSERT") + " " + tr("EDITOR_" + data_name.to_upper())
	text = data_name.to_upper()


# Remove assigned data
func _remove_data() -> void:
	editor.skin_data.stream[data_name] = null
	#text = tr("EDITOR_INSERT") + " " + tr("EDITOR_" + data_name.to_upper())
	text = data_name.to_upper()


# Load and display data path or display that data is loaded
func _load_data() -> void:
	if editor.skin_data.stream[data_name] == null:
		_remove_data()
		return
	elif editor.skin_data.stream[data_name] is String:
		text = editor.skin_data.stream[data_name]
		text = text.substr(text.length() - 20)
	else:
		#text = tr("EDITOR_SOME") + " " + tr("EDITOR_" + data_name.to_upper())
		text = data_name.to_upper()


# Called on button press
func _on_press(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				editor._open_file_dialog(file_dialog_to_open)
				await editor.file_selected
				var path : String = editor._edit_skn_stream_data(data_name)
				
				if path == "" : return
				text = path.substr(path.length() - 20)
				
			MOUSE_BUTTON_RIGHT: _remove_data()


# Called when hovered by mouse
func _selected() -> void:
	editor._show_description(description)
