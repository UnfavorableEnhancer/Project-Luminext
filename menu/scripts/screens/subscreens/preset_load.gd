extends MenuScreen

const PRESET_BUTTON : PackedScene = preload("res://menu/objects/regular_button.tscn")


func _ready() -> void:
	menu.screens["foreground"]._raise()
	
	cursor_selection_success.connect(_scroll)
	_load()


func _load() -> void:
	var presets : Array  = Data._parse(Data.PARSE.PRESETS)
	if presets.is_empty() : 
		$Scroll/V/Label.text = "NO_PRESETS"
		_assign_selectable($BACK, Vector2i(0,0))
		return
	
	var count : int = 0
	for preset_path : String in presets:
		var button : MenuSelectableButton = PRESET_BUTTON.instantiate()
		button.call_function_name = "_load_preset"
		button.call_string = preset_path
		button.text = preset_path.get_file()
		button.press_sound_name = "confirm"
		button.glow_color = Color("27a1a3")
		button.custom_minimum_size = Vector2(1104,48)
		button.menu_position = Vector2(0,count)
		
		$Scroll/V.add_child(button)
		count += 1
	
	_assign_selectable($BACK, Vector2i(0, count))
	
	cursor = Vector2i(0,0)
	_move_cursor()


func _scroll(cursor_pos : Vector2) -> void:
	$Scroll.scroll_vertical = clamp(cursor_pos.y * 208 ,0 ,INF)


func _load_preset(preset_path : String) -> void:
	var preset : GameConfigPreset = GameConfigPreset.new()
	preset._load(preset_path)
	preset._apply_preset()
	Data.menu.screens["game_config"]._load_settings()
	_remove()
