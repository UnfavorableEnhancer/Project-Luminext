extends MenuScreen


const PROFILE_BUTTON : PackedScene = preload("res://menu/objects/regular_button.tscn")

var delete_mode : bool = false


func _ready() -> void:
	menu.screens["foreground"]._raise()

	cursor_selection_success.connect(_scroll)
	_display_profile_list()
	
	await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


func _scroll(_cursor_pos : Vector2i) -> void:
	if Data.current_input_mode == Data.INPUT_MODE.MOUSE: return
	
	if cursor.y < selectables.size() - 4:
		$V/Profiles.scroll_vertical = clamp(currently_selected.position.y, 0 ,INF)


func _display_profile_list() -> void:
	for button : MenuSelectableButton in $V/Profiles/V.get_children():
		button.queue_free()
	selectables.clear()
	
	var profiles : Array = Data._parse(Data.PARSE.PROFILES)
	
	if profiles.is_empty() : 
		$V/Text.text = "NO PROFILES FOUND"
		$V/Delete._disabled(true)
	
	var tween : Tween = create_tween()
	tween.tween_interval(0.75)
	var count : int = 0
	for profile_name : String in profiles:
		profile_name = profile_name.get_file().get_slice('.',0)
		
		var button : MenuSelectableButton = PROFILE_BUTTON.instantiate()
		button.call_function_name = "_load_profile"
		button.call_string = profile_name
		if profile_name == Data.profile.name:
			button.text = profile_name + " [CURRENT]"
		else:
			button.text = profile_name
		
		button.press_sound_name = "confirm4"
		button.glow_color = Color("27a1a3")
		button.custom_minimum_size = Vector2(928,48)
		button.menu_position = Vector2i(0,count)
		button.description = "Select this profile."
		button.description_node = $V/Desc
		button.button_layout = 12
		button.modulate.a = 0.0
		_assign_selectable(button, Vector2i(0,count))
		
		$V/Profiles/V.add_child(button)
		tween.tween_property(button, "modulate:a", 1.0, 0.1).from(0.0)
		count += 1
	
	$V/Profiles.custom_minimum_size = Vector2(0,clamp(56 * count, 0, 360))
	
	_assign_selectable($V/Menu/Create, Vector2i(0,count))
	_assign_selectable($V/Menu/Delete, Vector2i(0,count+1))
	_assign_selectable($V/Menu/Cancel, Vector2i(0,count+2))


func _load_profile(profile_name : String) -> void:
	if delete_mode:
		var dialog : MenuScreen = menu._add_screen("accept_dialog")
		dialog.desc_text = "Are you sure you want to delete this profile?"
		dialog.object_to_call = self
		dialog.call_function_name = "_continue_deletion"
		dialog.call_function_argument = profile_name
		dialog.cancel_function_name = "_delete_profile"
		return
	
	Data.profile._load_profile(profile_name)

	if Data.profile.status == Profile.STATUS.PROFILE_IS_MISSING:
		Data.main._display_system_message("PROFILE IS MISSING!/nLOADING FAILED")
		return
	
	if Data.profile.status == Profile.STATUS.PROGRESS_MISSING :
		Data.main._display_system_message("PROFILE SAVE DATA IS MISSING!/nLOADING FAILED")
		return
	
	if Data.profile.status == Profile.STATUS.PROGRESS_FAIL :
		Data.main._display_system_message("PROFILE SAVE DATA IS CORRUPTED!/nLOADING FAILED")
		return

	if Data.profile.status == Profile.STATUS.CONFIG_FAIL or Data.profile.status == Profile.STATUS.CONFIG_MISSING:
		var dialog : MenuScreen = menu._add_screen("accept_dialog")
		dialog.desc_text = "Warning! This profile config file is missing. Continue?"
		dialog.object_to_call = self
		dialog.call_function_name = "_continue_loading"
		return
	
	menu.screens["foreground"].get_node("ProfileLayout/Name").text = profile_name
	_remove()


func _delete_profile() -> void:
	if delete_mode:
		delete_mode = false
		$V/Text.text = "SELECT PROFILE TO LOAD"
		$V/Text.modulate = Color.WHITE
		$V/Menu/Create._disable(false)
		$V/Menu/Delete.text = "DELETE PROFILE"
	else:
		if $V/Profiles/V.get_child_count() < 1 : return
		
		delete_mode = true
		$V/Text.text = "SELECT PROFILE TO DELETE"
		$V/Text.modulate = Color.RED
		$V/Menu/Create._disable(true)
		$V/Menu/Delete.text = "CANCEL DELETION"


func _continue_deletion(profile_name : String) -> void:
	Data.profile._delete_profile(profile_name)
	_delete_profile()
	# Added delay so newly created buttons wont assign to accept menu which is going to be deleted
	await get_tree().create_timer(0.8).timeout
	_display_profile_list()
	
	if profile_name == Data.profile.name:
		$V/Text.text = "YOU MUST SELECT OR CREATE AN PROFILE IN ORDER TO CONTINUE"
		$V/Menu/Cancel._disable(true)


func _continue_loading() -> void:
	menu.screens["foreground"].get_node("ProfileLayout/Name").text = Data.profile.name
	_remove()


func _start_profile_create() -> void:
	var input : MenuScreen = menu._add_screen("text_input")
	input.desc_text = "Enter new profile name"
	input.object_to_call = self
	input.call_function_name = "_create_profile"
	input._start()


func _create_profile(profile_name : String) -> void:
	Data.profile._create_profile(profile_name)
	menu.screens["foreground"].get_node("ProfileLayout/Name").text = profile_name
	_remove()