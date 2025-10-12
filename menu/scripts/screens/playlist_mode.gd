# Project Luminext - an advanced open-source Lumines spiritual successor
# Copyright (C) <2024-2025> <unfavorable_enhancer>
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

##-----------------------------------------------------------------------
## Menu screen for [PlaylistMode] gamemode
## Displays currently loaded skin list and allows to build own playlist from it
##-----------------------------------------------------------------------

signal all_skins_displayed ## Emitted when all skins from skin list are displayed

const SKIN_BUTTON : PackedScene = preload("res://menu/objects/skin_button.tscn") ## Skin button instance
const ALBUM_BAR : PackedScene = preload("res://menu/objects/album_bar.tscn") ## Album label instance

var skin_list_rows_amount : int = 0 ## Amount of rows in displayed skin list
var currently_swapping_skin_pos : int = -1 ## Currently selected to be swapped position in playlist


func _ready() -> void:
	parent_menu.keep_locked = true
	parent_menu.screens["background"]._change_gradient_colors(Color("0b3155"),Color("11433f"),Color("14013f"),Color("1f1f1f"),Color("010509"))

	cursor_selection_success.connect(_scroll)
	Data.skin_playlist.playlist_changed.connect(_display_current_playlist)
	
	_load_skin_list()
	_display_current_playlist()
	
	$Skins/Info.text = str(Data.skin_list.skins_amount) + " " + tr("SKINS_TOTAL")

	await parent_menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


## Checks if skin list is already parsing and starts new parse if needed
func _load_skin_list() -> void:
	if Data.skin_list.is_parsing:
		main._toggle_loading(true)

		await Data.skin_list.parsed
		await get_tree().create_timer(0.01).timeout

		main._toggle_loading(false)
	else:
		main._toggle_loading(true)

		Data.skin_list._parse_threaded()
		await Data.skin_list.parsed
		await get_tree().create_timer(0.01).timeout

		main._toggle_loading(false)
	
	_display_skins_list()
	
	if parent_menu.currently_adding_screens_amount > 0 : await parent_menu.all_screens_added
	parent_menu.keep_locked = false
	parent_menu.is_locked = false


## Displays all skins from skin list
func _display_skins_list() -> void:
	Console._log("Displaying skin list")
	
	for album : String in Data.skin_list.skins:
		if Data.skin_list.skins[album].is_empty(): continue

		Console._log("Adding album : " + album)
		
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
			var skin_metadata : SkinMetadata = Data.skin_list._get_skin_metadata_by_album(album, number)
			if skin_metadata == null : return

			Console._log("Adding skin : " + skin_metadata.name)

			if row_number == 4:
				row_number = 0
				if album_numbers.size() > 4: skin_list_rows_amount += 1

			var skin_button : MenuSelectableButton = SKIN_BUTTON.instantiate()
			skin_button.skin_metadata = skin_metadata

			skin_button.parent_screen = self
			skin_button.parent_menu = parent_menu

			skin_button.custom_minimum_size = Vector2(256,64)
			skin_button.skin_selected.connect(_display_skin_metadata)
			skin_button.invalid_skin_selected.connect(_display_invalid_skin_metadata)
			skin_button.locked_skin_selected.connect(_display_locked_skin_metadata)

			_set_selectable_position(skin_button,Vector2(row_number + 1,skin_list_rows_amount + 1))
			grid.call_deferred("add_child",skin_button)
			
			row_number += 1
		
		skin_list_rows_amount += 1
	
	Console._log("All skins displayed")
	all_skins_displayed.emit()


## Scrolls skin list or playlist scroll bar
func _scroll(cursor_pos : Vector2i) -> void:
	if main.current_input_mode == Main.INPUT_MODE.MOUSE: return

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
		# We need to wait a little or menu screen will just immidiately close when last skin in playlist is removed
		await get_tree().create_timer(0.1).timeout
		cancel_cursor_pos = Vector2i(0,5)


## ***Redefenition***
## Moves cursor into **'direction'** and selects avaiable [MenuSelectableButton]/[MenuSelectableSlider][br]
## **'oneshot'** - Set true if you don't want cursor to search for selectables, if cursor failed to select
func _move_cursor(direction : int = CURSOR_DIRECTION.HERE, one_shot : bool = false) -> bool:
	if parent_menu.is_locked : return false
	if selectables.is_empty() : return false
	if parent_menu.current_screen_name != snake_case_name: return false

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


## Displays current playlist
func _display_current_playlist() -> void:
	for skin_button : MenuSelectableButton in $Playlist/S/V.get_children():
		selectables.erase(skin_button.menu_position)
		skin_button.queue_free()
	
	if Data.skin_playlist.skins_ids.is_empty():
		$Playlist/Counter.text = "0"
		cursor = Vector2(5,0)
		_move_cursor()
		return
	
	var count : int = 0
	for i : int in Data.skin_playlist.skins_ids.size():
		var skin_button : MenuSelectableButton = SKIN_BUTTON.instantiate()
		skin_button.skin_metadata = Data.skin_playlist._get_skin_metadata_in_position(i)
		_set_selectable_position(skin_button,Vector2(5,count + 1))

		skin_button.parent_screen = self
		skin_button.parent_menu = parent_menu

		skin_button.is_in_playlist = true
		skin_button.button_layout = 5

		skin_button.skin_selected.connect(_display_skin_metadata)
		skin_button.invalid_skin_selected.connect(_display_invalid_skin_metadata)
		skin_button.locked_skin_selected.connect(_display_locked_skin_metadata)
		
		$Playlist/S/V.add_child(skin_button)
		count += 1
	
	$Playlist/Counter.text = str(count)
	visited_cursor_positions[5] = 0
	if cursor.x == 5:
		if cursor.y == count:
			_move_cursor(CURSOR_DIRECTION.UP)
		else:
			_move_cursor()


## Displays selected skin button metadata info
func _display_skin_metadata(metadata : SkinMetadata) -> void:
	if metadata == null:
		_display_invalid_skin_metadata("ERROR! Invalid metadata")
		return
	
	if metadata.cover_art == null : %CoverArt.texture = load("res://menu/images/misc/unk.png")
	else : %CoverArt.texture = metadata.cover_art
	%MadeBy.text = "MADE BY : " + metadata.skin_by + " | " + Time.get_datetime_string_from_unix_time(metadata.save_date as int).replace("T"," ")
	%BPM.text = str(snapped(metadata.bpm,0.001))
	%Name.text = metadata.name
	%Music.text = metadata.artist
	%FileName.text = metadata.path
	%Info.text = metadata.info


## Displays selected invalid skin button error message
func _display_invalid_skin_metadata(error : String) -> void:
	%CoverArt.texture = load("res://menu/images/unk.png")
	%MadeBy.text = "MADE BY : MISSING_NO"
	%BPM.text = "666"
	%Name.text = "UNKNOWN SKIN"
	%Music.text = error
	%FileName.text = ""
	%Info.text = ""
	return


## Displays selected locked skin button lock condition
func _display_locked_skin_metadata(lock_condition : String) -> void:
	%CoverArt.texture = load("res://menu/images/unk.png")
	%MadeBy.text = "MADE BY : ??????"
	%BPM.text = "???"
	%Name.text = "LOCKED SKIN"
	%Music.text = lock_condition
	%FileName.text = ""
	%Info.text = ""
	return


## Adds given **'amount'** of random skins to playlist
func _add_random_skin(amount : String) -> void:
	var random_skins_list : Array[SkinMetadata] = []
	match amount:
		"1" : random_skins_list = Data.skin_list._get_random_skin_metadata(1)
		"5" : random_skins_list = Data.skin_list._get_random_skin_metadata(5)
		"10" : random_skins_list = Data.skin_list._get_random_skin_metadata(10)
		"all" : random_skins_list = Data.skin_list._get_random_skin_metadata(-1)
	
	if random_skins_list.is_empty() : return
	for skin_metadata : SkinMetadata in random_skins_list:
		Data.skin_playlist._add_to_playlist(skin_metadata, false)
	
	_display_current_playlist()


## Clears playlist
func _clear_playlist() -> void:
	$Error.color = Color("28e5a780")
	create_tween().tween_property($Error,"modulate:a",0.0,0.25).from(1.0)
	
	Data.skin_playlist._clear()
	_display_current_playlist()


## Swaps selected skin position in playlist with currently stored position in **'currently_swapping_skin_pos'**[br]
## If **'currently_swapping_skin_pos'** = -1, then it stores given position there and awaits for another position
func _swap_skins(skin_position : int) -> void:
	if skin_position == -1: return

	if currently_swapping_skin_pos == -1:
		# Lock left and right menu cursor movement directions
		input_lock[0] = true
		input_lock[1] = true
		$Swap.position = Vector2(0,0)
		$Swap.modulate.a = 0
		create_tween().tween_property($Swap,"modulate:a",1.0,1.0)
		currently_swapping_skin_pos = skin_position
		$Playlist/CLEAR._set_disable(true)
		return
		
	else:
		Data.skin_playlist._swap_skins(currently_swapping_skin_pos, skin_position)
		_display_current_playlist()
		# Return white color for first selected to swap skin since it turned purple
		selectables[Vector2i(5,currently_swapping_skin_pos)].modulate = Color.WHITE
		currently_swapping_skin_pos = -1
		# Unlock left and right menu cursor movement directions
		input_lock[0] = false
		input_lock[1] = false
		$Swap.position = Vector2(9999,0)
		create_tween().tween_property($Swap,"modulate:a",0.0,1.0)
		$Playlist/CLEAR._set_disable(false)


## Opens input dialog for saving current playlist
func _save_playlist() -> void:
	if Data.skin_playlist.skins_ids.is_empty():
		$Error.color = Color("e5286280")
		create_tween().tween_property($Error,"modulate:a",0.0,0.25).from(1.0)
		parent_menu._play_sound("error")
		return
	
	parent_menu._play_sound("confirm2")
	var input : MenuScreen = parent_menu._add_screen("text_input")
	input.desc_text = "ENTER PLAYLIST NAME"
	input.accept_function = Data.skin_playlist._save


## Starts endless [PlaylistMode] game with current playlist
func _start_game_endless() -> void:
	_start_game(true)


## Starts [PlaylistMode] game with current playlist[br]
## - **'endless_mode'** - if true, then the game will be endless[br]
## - **'single_skin'** - if not **NULL**, then it would be played endlessly instead of current playlist[br]

func _start_game(endless_mode : bool = false, single_skin : SkinMetadata = null) -> void:
	var single_skin_mode : bool = false
	var playlist : SkinPlaylist = Data.skin_playlist
	var first_skin_metadata : SkinMetadata
	
	if single_skin == null:
		if playlist.skins_ids.is_empty():
			$Error.color = Color("e5286280")
			create_tween().tween_property($Error,"modulate:a",0.0,0.25).from(1.0)
			parent_menu._play_sound("error")
			return
		
		var invalid_skins : Array[String] = playlist._validate()
		if invalid_skins.size() > 0:
			$Error.color = Color("e5286280")
			create_tween().tween_property($Error,"modulate:a",0.0,0.25).from(1.0)
			parent_menu._play_sound("error")
			return
		
		first_skin_metadata = playlist._get_skin_metadata_in_position(0)
		if playlist.skins_ids.size() == 1 : single_skin_mode = true
	
	else:
		playlist = SkinPlaylist.new()
		playlist._add_to_playlist(single_skin, false)
		
		first_skin_metadata = single_skin
		single_skin_mode = true

	var gamecore : LuminextGame = LuminextGame.new()
	
	var gamemode : Gamemode = PlaylistMode.new()
	gamemode.is_single_skin_mode = single_skin_mode
	gamemode.is_single_run = not endless_mode
	gamemode.current_playlist = playlist
	
	parent_menu._play_sound("enter")
	parent_menu._play_sound("_announce", first_skin_metadata.announce)
	
	main._start_game(gamecore, gamemode)
