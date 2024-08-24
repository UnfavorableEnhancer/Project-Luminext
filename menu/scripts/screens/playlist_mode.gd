# Project Luminext - an advanced open-source Lumines spiritual successor
# Copyright (C) <2024> <unfavorable_enhancer>
# Contact : <random.likes.apes@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


extends MenuScreen

const SKIN_BUTTON : PackedScene = preload("res://menu/objects/skin_button.tscn") # Skin button instance
const ALBUM_BAR : PackedScene = preload("res://menu/objects/album_bar.tscn") # Album label instance

signal all_skins_displayed

var skin_list_rows_amount : int = 0

var currently_swapping_skin_pos : int = -1 # Used in playlist skin swap


func _ready() -> void:
	menu.keep_locked = true
	Data.menu.screens["background"]._change_gradient_colors(Color("0b3155"),Color("11433f"),Color("14013f"),Color("1f1f1f"),Color("010509"))

	cursor_selection_success.connect(_scroll)
	Data.playlist.playlist_changed.connect(_display_current_playlist)
	
	if not Data.menu.is_music_playing:
		Data.menu._change_music("menu_theme")
		if Data.menu.custom_data.has("last_music_pos"):
			Data.menu.music_player.seek(Data.menu.custom_data["last_music_pos"])
	
	_load_skin_list()
	_display_current_playlist()
	
	$Skins/Info.text = str(Data.skin_list.files_amount) + " SKINS TOTAL"

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
			_assign_selectable(skin_button,Vector2(row_number + 1,skin_list_rows_amount))
			skin_button.parent_screen = self
			grid.call_deferred("add_child",skin_button)
			
			row_number += 1
		
		skin_list_rows_amount += 1
	
	print("ALL SKINS DISPLAYED!")
	all_skins_displayed.emit()


func _end() -> void:
	Data.profile._save_progress()


func _scroll(cursor_pos : Vector2i) -> void:
	if Data.current_input_mode == Data.INPUT_MODE.MOUSE: return

	# Scroll skin list
	if cursor_pos.x > 0 and cursor_pos.x < 5: 
		$Skins/S.scroll_vertical = clamp(currently_selected.position.y + currently_selected.get_parent().position.y - 256 ,0 ,INF)
		cancel_cursor_pos = Vector2i(0,5)
	
	# Scroll playlist
	elif cursor_pos.x == 5: 
		# When cursor is on playlist, cancel button is used to remove skin from playlist
		cancel_cursor_pos = Vector2i(-1,-1)
		$Playlist/S.scroll_vertical = clamp(cursor_pos.y * 64 - 128 ,0 ,INF)
	
	else: 
		# We need to wait a little or playlist mode just immidiately closes when last skin in playlist is removed
		await get_tree().create_timer(0.1).timeout
		cancel_cursor_pos = Vector2i(0,5)


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

# Displays playlist
func _display_current_playlist() -> void:
	for skin_button : MenuSelectableButton in $Playlist/S/V.get_children():
		selectables.erase(skin_button.menu_position)
		skin_button.queue_free()
	
	if Data.playlist.skins.is_empty():
		$Playlist/Counter.text = "0"
		cursor = Vector2(0,0)
		_move_cursor()
		return
	
	var count : int = 0
	for skin_entry : Array in Data.playlist.skins:
		var skin_path : String = skin_entry[0]
		var skin_button : MenuSelectableButton = SKIN_BUTTON.instantiate()
		skin_button.skin_metadata = Data.skin_list._get_skin_metadata_by_file_path(skin_path)
		_assign_selectable(skin_button,Vector2(5,count))
		skin_button.parent_screen = self
		skin_button.is_in_playlist = true
		
		$Playlist/S/V.add_child(skin_button)
		count += 1
	
	$Playlist/Counter.text = str(count)
	visited_cursor_positions[5] = 0
	if cursor.y == count:
		_move_cursor(CURSOR_DIRECTION.UP)
	else:
		_move_cursor()


func _display_skin_metadata(metadata : SkinMetadata) -> void:
	if metadata == null:
		%CoverArt.texture = load("res://menu/images/unk.png")
		%MadeBy.text = "MADE BY : MISSING_NO"
		%BPM.text = "120"
		%Name.text = "UNKNOWN SKIN"
		%Music.text = ""
		%FileName.text = ""
		%Info.text = "PLEASE CHECK IF ANY SKIN IS PLACED INSIDE SKINS FOLDER"
		return
	
	if metadata.cover_art == null : %CoverArt.texture = load("res://menu/images/unk.png")
	else : %CoverArt.texture = metadata.cover_art
	%MadeBy.text = "MADE BY : " + metadata.skin_by + " | " + Time.get_datetime_string_from_unix_time(metadata.save_date as int).replace("T"," ")
	%BPM.text = str(snapped(metadata.bpm,0.001))
	%Name.text = metadata.name
	%Music.text = metadata.artist
	%FileName.text = metadata.path
	%Info.text = metadata.info


func _swap_skins(skin_position : int) -> void:
	if skin_position > -1:
		if currently_swapping_skin_pos == -1:
			# Lock left and right menu cursor movement directions
			input_lock[0] = true
			input_lock[1] = true
			$Swap.position = Vector2(0,0)
			$Swap.modulate.a = 0
			create_tween().tween_property($Swap,"modulate:a",1.0,1.0)
			currently_swapping_skin_pos = skin_position
			return
			
		else:
			Data.playlist._swap_skins(currently_swapping_skin_pos, skin_position)
			_display_current_playlist()
			# Return white color for first selected to swap skin since it turned purple
			selectables[Vector2i(5,currently_swapping_skin_pos)].modulate = Color.WHITE
			currently_swapping_skin_pos = -1
			# Unlock left and right menu cursor movement directions
			input_lock[0] = false
			input_lock[1] = false
			$Swap.position = Vector2(9999,0)
			create_tween().tween_property($Swap,"modulate:a",0.0,1.0)


func _save_playlist() -> void:
	if Data.playlist.skins.is_empty():
		var tween : Tween = create_tween()
		tween.tween_property($Error,"modulate:a",0.0,0.25).from(1.0)
		Data.menu._sound("error")
		return
	
	Data.menu._sound("confirm2")
	var input : MenuScreen = Data.menu._add_screen("text_input")
	input.desc_text = "ENTER PLAYLIST NAME"
	input.object_to_call = Data.playlist
	input.call_function_name = "_save"
	input._start()


# func _reload_skin_list():
# 	cursor = Vector2(0,0)
# 	Data.menu._move_cursor()
# 	skin_list_rows_amount = 0
	
# 	get_tree().call_group("skin_list_buttons","_set_selectable",false)

# 	for object in $Skins/S/V.get_children():
# 		object.queue_free()
	
# 	Data.skin_list.was_parsed = false
# 	_load_skin_list()
# 	_display_current_playlist()


func _start_game_endless() -> void:
	_start_game(null,false,true)


# Starts playlist mode game
func _start_game(first_skin_metadata : SkinMetadata = null, single_skin_mode : bool = false, endless_mode : bool = false) -> void:
	if first_skin_metadata == null:
		if Data.playlist.skins.is_empty():
			var tween : Tween = create_tween()
			tween.tween_property($Error,"modulate:a",0.0,0.25).from(1.0)
			Data.menu._sound("error")
			return
		
		var first_skin_hash : StringName = Data.playlist.skins[0][1]
		first_skin_metadata = Data.skin_list._get_skin_metadata_by_hash(first_skin_hash)
		if first_skin_metadata == null:
			var tween : Tween = create_tween()
			tween.tween_property($Error,"modulate:a",0.0,0.25).from(1.0)
			Data.menu._sound("error")
			return

	if Data.playlist.skins.size() == 1: single_skin_mode = true
	
	if Data.menu.is_music_playing:
		Data.menu.custom_data["last_music_pos"] = Data.menu.music_player.get_playback_position()
	Data.menu._sound("_announce", first_skin_metadata.announce)

	var gamemode : Gamemode = PlaylistMode.new()
	gamemode.is_single_skin_mode = single_skin_mode
	gamemode.is_single_run = not endless_mode
	gamemode.current_playlist = Data.playlist

	Data.menu._sound("enter")
	Data.main._start_game(first_skin_metadata, gamemode)
