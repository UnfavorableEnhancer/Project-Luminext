extends MenuScreen

enum OPTIONS_TABS {BLOCKS, RULES, PARAMS}

var current_tab : int = OPTIONS_TABS.BLOCKS
var original_config : Dictionary = {} # Stores config with which this screen was opened


func _ready() -> void:
	if menu.screens.has("background"):
		menu.screens["background"]._change_gradient_colors(Color("00210b"),Color("00211f"),Color("0a2430"),Color("121f35"),Color("00000A"))

	_set_selectables(OPTIONS_TABS.BLOCKS)

	original_config = Data.profile.config.duplicate(true)

	cursor_selection_success.connect(_scroll)

	_load_settings()

	await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


func _set_seed() -> void:
	var input : MenuScreen = menu._add_screen("text_input")
	input.desc_text = "Enter seed number"
	input.object_to_call = self
	input.call_function_name = "_set_seed_continue"
	input._start()


func _set_seed_continue(value : String) -> void:
	Data.profile.config["gameplay"]["seed"] = int(value)
	$PARAMS/SCROLL/V/SEED/Button/IO.text = value


func _scroll(cursor_pos : Vector2) -> void:
	if Data.current_input_mode == Data.INPUT_MODE.MOUSE: return

	if cursor_pos.x == 1:
		if current_tab == OPTIONS_TABS.BLOCKS:
			$BLOCKS/SCROLL.scroll_vertical = clamp(cursor_pos.y * 68 - 136 ,0 ,INF)
		elif current_tab == OPTIONS_TABS.PARAMS:
			$PARAMS/SCROLL.scroll_vertical = clamp(cursor_pos.y * 68 - 136 ,0 ,INF)


func _change_tab(to_tab : String) -> void:
	var tween : Tween = create_tween().set_parallel(true)

	match to_tab:
		"blocks":
			current_tab = OPTIONS_TABS.BLOCKS
			$BLOCKS.visible = true
			$RULES.visible = false
			$PARAMS.visible = false
			_set_selectables(current_tab)
			
			tween.tween_property($BLOCKS,"scale:y",1.0,0.25).from(0.0)
			tween.tween_property($BLOCKS,"modulate:a",1.0,0.25).from(0.0)
		
		"rules":
			current_tab = OPTIONS_TABS.RULES
			$BLOCKS.visible = false
			$RULES.visible = true
			$PARAMS.visible = false
			_set_selectables(current_tab)

			tween.tween_property($RULES,"scale:y",1.0,0.25).from(0.0)
			tween.tween_property($RULES,"modulate:a",1.0,0.25).from(0.0)
		
		"params":
			current_tab = OPTIONS_TABS.PARAMS
			$BLOCKS.visible = false
			$RULES.visible = false
			$PARAMS.visible = true
			_set_selectables(current_tab)

			tween.tween_property($PARAMS,"scale:y",1.0,0.25).from(0.0)
			tween.tween_property($PARAMS,"modulate:a",1.0,0.25).from(0.0)


func _change_option(value : float, setting_name : String) -> void:
	Data.profile._assign_setting(setting_name, value)


func _set_selectables(tab : int) -> void:
	selectables.clear()
	
	_assign_selectable($Menu/BLOCKS, Vector2i(0,0))
	_assign_selectable($Menu/RULES, Vector2i(0,1))
	_assign_selectable($Menu/PARAMS, Vector2i(0,2))
	_assign_selectable($Menu/APPLY, Vector2i(0,3))
	_assign_selectable($Menu/LOAD, Vector2i(0,4))
	_assign_selectable($Menu/SAVE, Vector2i(0,5))
	_assign_selectable($Menu/EXIT, Vector2i(0,6))

	var tab_instance : Control

	match tab:
		OPTIONS_TABS.BLOCKS: tab_instance = $BLOCKS/SCROLL/V
		OPTIONS_TABS.RULES: tab_instance = $RULES/SCROLL/V
		OPTIONS_TABS.PARAMS: tab_instance = $PARAMS/SCROLL/V
		
	var y_position : int = -1

	for child_idx : int in tab_instance.get_child_count():
		var child : Control = tab_instance.get_child(child_idx)
		if not child is TextureRect : continue

		y_position += 1
		var selectable : Control = child.get_child(0)

		_assign_selectable(selectable, Vector2i(1,y_position))


func _load_settings() -> void:
	get_tree().call_group("toggle_buttons","_set_toggle_by_data", Data.profile.config)
	get_tree().call_group("sliders","_set_value_by_data", Data.profile.config)
	
	$PARAMS/SCROLL/V/SEED/Button/IO.text = str(Data.profile.config["gameplay"]["seed"])


func _exit_with_apply() -> void:
	Data.profile._save_config()
	
	menu._change_screen(previous_screen_name)


func _exit_with_cancel() -> void:
	Data.profile.config = original_config

	menu._change_screen(previous_screen_name)


func _save_preset() -> void:
	var preset : GameConfigPreset = GameConfigPreset.new()
	preset._store_current_config()

	var input : MenuScreen = Data.menu._add_screen("text_input")
	input.desc_text = "ENTER CONFIGURATION PRESET NAME"
	input.object_to_call = preset
	input.call_function_name = "_save"
	input._start()
