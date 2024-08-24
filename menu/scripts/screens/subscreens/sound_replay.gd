extends MenuScreen

const SKIN_BUTTON : PackedScene = preload("res://menu/objects/skin_button.tscn") # Skin button instance
const ALBUM_BAR : PackedScene = preload("res://menu/objects/album_bar.tscn") # Album label instance

var skin_list_rows_amount : int = 0

var currently_swapping_skin_pos : int = -1 # Used in playlist skin swap


func _ready() -> void:
	menu.keep_locked = true
	menu.screens["foreground"]._raise()

	cursor_selection_success.connect(_scroll)
	
	var skin_files_count : int = Data.skin_list._count_skin_files_amount()
	$Skins/Info.text = str(skin_files_count) + " SKINS TOTAL"
	if skin_files_count != Data.skin_list.files_amount:
		Data.skin_list.was_parsed = false
	
	_load_skin_list()
	
	await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


# Loads and displays skin list
func _load_skin_list() -> void:
	if Data.skin_list.currently_parsing:
		Data.main._toggle_loading(true)
		await Data.skin_list.parsed
		await get_tree().create_timer(0.01).timeout
		Data.main._toggle_loading(false)

	elif not Data.skin_list.was_parsed:
		Data.main._toggle_loading(true)
		Data.skin_list._parse_threaded()
		
		await Data.skin_list.parsed
		await get_tree().create_timer(0.01).timeout
		Data.main._toggle_loading(false)
	
	_display_skins_list()
	
	if menu.currently_adding_screens_amount > 0 : await menu.all_screens_added
	menu.keep_locked = false
	menu.is_locked = false


# Displays all skins from skin list
func _display_skins_list() -> void:
	print("DISPLAY SKINS START")
	selectables.clear()
	
	for album : String in Data.skin_list.skins:
		if Data.skin_list.skins[album].is_empty(): continue
		
		var bar : ColorRect = ALBUM_BAR.instantiate()
		bar.get_node("Album").text = album
		$Skins/S/V.call_deferred("add_child",bar)
		
		var grid : GridContainer = GridContainer.new()
		grid.set("theme_override_constants/v_separation", 16)
		grid.set("theme_override_constants/h_separation", 16)
		grid.set("size_flags_horizontal", 0)
		grid.columns = 4
		$Skins/S/V.call_deferred("add_child",grid)
		
		var row_number : int = 0
		var album_numbers : Array = Data.skin_list.skins[album].keys()
		album_numbers.sort()
		
		for number : int in album_numbers:
			if row_number == 4:
				row_number = 0
				if album_numbers.size() > 4: skin_list_rows_amount += 1
			
			var skin_button : MenuSelectableButton = SKIN_BUTTON.instantiate()
			skin_button.skin_metadata = Data.skin_list.skins[album][number]
			skin_button.custom_minimum_size = Vector2(256,64)
			skin_button.skin_selected.connect(_display_skin_metadata)
			_assign_selectable(skin_button,Vector2i(row_number,skin_list_rows_amount))
			skin_button.parent_screen = self
			skin_button.sound_replay_button = true
			grid.call_deferred("add_child",skin_button)
			
			row_number += 1
		
		skin_list_rows_amount += 1
	
	_assign_selectable($BACK, Vector2i(0,skin_list_rows_amount))
	cancel_cursor_pos = Vector2i(0,skin_list_rows_amount)
	
	print("ALL SKINS DISPLAYED!")
	emit_signal("all_skins_displayed")


func _scroll(cursor_pos : Vector2i) -> void:
	if Data.current_input_mode == Data.INPUT_MODE.MOUSE: return

	# Scroll skin list
	if cursor_pos.y < skin_list_rows_amount: 
		$Skins/S.scroll_vertical = clamp(currently_selected.position.y + currently_selected.get_parent().position.y - 256 ,0 ,INF)


func _move_cursor(direction : int = CURSOR_DIRECTION.HERE, one_shot : bool = false) -> bool:
	if menu.is_locked : return false
	if selectables.is_empty() : return false
	if menu.current_screen_name != snake_case_name: return false

	var old_cursor_position : Vector2i = cursor
	cursor_move_try.emit()
	
	match direction:
		CURSOR_DIRECTION.LEFT:
			if cursor.x > 0 : 
				cursor.x -= 1
			else:
				return false
		
		CURSOR_DIRECTION.RIGHT:
			cursor.x += 1
		
		CURSOR_DIRECTION.UP:
			if cursor.y > 0 : 
				cursor.y -= 1
			else:
				return false
		
		CURSOR_DIRECTION.DOWN:
			cursor.y += 1
	
	last_cursor_dir = direction
	
	if selectables.has(cursor):
		if not is_instance_valid(selectables[cursor]): 
			cursor = old_cursor_position
			return false
		
		previously_selected = currently_selected
		if is_instance_valid(previously_selected) : previously_selected._deselect()
		currently_selected = selectables[cursor]
		selectables[cursor]._select()
		
		# Store last visited Y position in current column, so when moving left or right, cursor could stick to that position next time
		visited_cursor_positions[cursor.x] = cursor.y

		cursor_selection_success.emit(cursor)
		return true
	
	if one_shot: 
		return false
	
	# If inside skin list
	if cursor.x > 0 and cursor.x < 5:
		if direction == CURSOR_DIRECTION.UP or direction == CURSOR_DIRECTION.DOWN:
			for i : int in range(4,0,-1):
				if selectables.has(Vector2i(i,cursor.y)):
					cursor = Vector2i(i,cursor.y)
					_move_cursor()
					return false

	if direction == CURSOR_DIRECTION.RIGHT or direction == CURSOR_DIRECTION.LEFT:
		# If there's no selectable object at this coordinates, try to select last selected on that column
		if visited_cursor_positions.has(cursor.x):
			var close_position : Vector2i = Vector2i(cursor.x, visited_cursor_positions[cursor.x])
			
			if selectables.has(close_position):
				cursor = Vector2i(close_position)
				_move_cursor()
				return true
		
		elif selectables.has(Vector2i(cursor.x, 0)):
			cursor = Vector2i(cursor.x, 0)
			_move_cursor()
			return true
	
	# If failed to find any button at all, turn cursor back
	cursor = old_cursor_position
	cursor_selection_fail.emit(cursor, direction)
	return false


func _display_skin_metadata(metadata : SkinMetadata) -> void:
	if metadata == null:
		%MadeBy.text = "MADE BY : MISSING_NO"
		%Name.text = "UNKNOWN SKIN"
		%Music.text = ""
		%FileName.text = ""
		%Info.text = "PLEASE CHECK IF ANY SKIN IS PLACED INSIDE SKINS FOLDER"
		return
	
	%MadeBy.text = "MADE BY : " + metadata.skin_by + " | " + Time.get_datetime_string_from_unix_time(metadata.save_date as int).replace("T"," ")
	%Name.text = metadata.name
	%Music.text = metadata.artist
	%FileName.text = metadata.path
	%Info.text = metadata.info


# Starts playlist mode game
func _start_game(first_skin_metadata : SkinMetadata = null) -> void:
	if first_skin_metadata == null: return
	
	if Data.menu.is_music_playing:
		Data.menu.custom_data["last_music_pos"] = Data.menu.music_player.get_playback_position()
	Data.menu._sound("announce", first_skin_metadata.announce)

	Data.menu._sound("enter")
	_remove()
	
	Data.main._test_skin(first_skin_metadata)
