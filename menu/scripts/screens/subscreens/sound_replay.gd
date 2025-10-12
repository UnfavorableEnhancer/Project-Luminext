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
## Displays currently loaded skin list and allows to start any skin skintest
##-----------------------------------------------------------------------

signal all_skins_displayed ## Emitted when all skins from skin list are displayed

const SKIN_BUTTON : PackedScene = preload("res://menu/objects/skin_button.tscn") ## Skin button instance
const ALBUM_BAR : PackedScene = preload("res://menu/objects/album_bar.tscn") ## Album label instance

var skin_list_rows_amount : int = 0 ## Amount of rows in displayed skin list


func _ready() -> void:
	parent_menu.keep_locked = true
	parent_menu.screens["foreground"]._raise()

	cursor_selection_success.connect(_scroll)
	
	_load_skin_list()

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
			skin_button.custom_minimum_size = Vector2(256,64)

			skin_button.skin_selected.connect(_display_skin_metadata)
			skin_button.invalid_skin_selected.connect(_display_invalid_skin_metadata)
			skin_button.locked_skin_selected.connect(_display_locked_skin_metadata)

			skin_button.parent_screen = self
			skin_button.parent_menu = parent_menu

			_set_selectable_position(skin_button,Vector2(row_number + 1,skin_list_rows_amount + 1))

			grid.call_deferred("add_child",skin_button)
			
			row_number += 1
		
		skin_list_rows_amount += 1
	
	Console._log("All skins displayed")
	all_skins_displayed.emit()


## Scrolls skin list
func _scroll(cursor_pos : Vector2i) -> void:
	if main.current_input_mode == Main.INPUT_MODE.MOUSE: return

	# Scroll skin list
	if cursor_pos.y < skin_list_rows_amount: 
		$Skins/S.scroll_vertical = clamp(currently_selected.position.y + currently_selected.get_parent().position.y - 256 ,0 ,INF)


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


## Displays selected skin button metadata info
func _display_skin_metadata(metadata : SkinMetadata) -> void:
	if metadata == null:
		_display_invalid_skin_metadata("ERROR! Invalid metadata")
		return
	
	%MadeBy.text = "MADE BY : " + metadata.skin_by + " | " + Time.get_datetime_string_from_unix_time(metadata.save_date as int).replace("T"," ")
	%Name.text = metadata.name
	%Music.text = metadata.artist
	%FileName.text = metadata.path
	%Info.text = metadata.info


## Displays selected invalid skin button error message
func _display_invalid_skin_metadata(error : String) -> void:
	%MadeBy.text = "MADE BY : MISSING_NO"
	%Name.text = "UNKNOWN SKIN"
	%Music.text = error
	%FileName.text = ""
	%Info.text = ""
	return


## Displays selected locked skin button lock condition
func _display_locked_skin_metadata(lock_condition : String) -> void:
	%MadeBy.text = "MADE BY : ??????"
	%Name.text = "LOCKED SKIN"
	%Music.text = lock_condition
	%FileName.text = ""
	%Info.text = ""
	return


## Starts skintest with selected **'skin_metadata'**
func _start_game(skin_metadata : SkinMetadata = null) -> void:
	if skin_metadata == null: return
	
	parent_menu._play_sound("announce", skin_metadata.announce)
	parent_menu._play_sound("enter")
	
	main._test_skin(skin_metadata)
