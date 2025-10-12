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
## Allows to edit avaiable profiles or create new one
##-----------------------------------------------------------------------

const PROFILE_BUTTON : PackedScene = preload("res://menu/objects/regular_button.tscn") ## Profile button instance

var is_in_delete_mode : bool = false ## If true, then we can remove some profiles


func _ready() -> void:
	parent_menu.screens["foreground"]._raise()

	cursor_selection_success.connect(_scroll)
	_display_profile_list()
	
	await parent_menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


## Scrolls profile list scroll bar
func _scroll(_cursor_pos : Vector2i) -> void:
	if Main.current_input_mode == Main.INPUT_MODE.MOUSE: return
	
	if cursor.y < selectables.size() - 4:
		$V/Profiles.scroll_vertical = clamp(currently_selected.position.y, 0 ,INF)


## Loads and displays all aviable profiles list
func _display_profile_list() -> void:
	for button : MenuSelectableButton in $V/Profiles/V.get_children():
		button.queue_free()
	selectables.clear()
	
	var profiles : Array[String] = Data._parse(Data.PARSE.PROFILES, true)
	
	if profiles.is_empty() : 
		$V/Text.text = tr("PE_NO_PROFILES")
		$V/Menu/Delete._disabled(true)
	elif profiles.size() < 2:
		$V/Menu/Delete._disabled(true)
	
	var tween : Tween = create_tween()
	tween.tween_interval(0.75)
	var count : int = 0
	for profile_name : String in profiles:
		profile_name = profile_name.get_file().get_slice('.',0)
		
		var button : MenuSelectableButton = PROFILE_BUTTON.instantiate()
		button.call_function_name = "_load_profile"
		button.call_string = profile_name
		if profile_name == Player.profile_name:
			button.text = profile_name + " " + tr("PE_CURRENT")
		else:
			button.text = profile_name
		
		button.press_sound_name = "confirm4"
		button.glow_color = Color("27a1a3")
		button.custom_minimum_size = Vector2(928,48)
		button.menu_position = Vector2i(0,count)
		button.description = "PE_SELECT"
		button.description_node = $V/Desc
		button.button_layout = 12
		button.modulate.a = 0.0
		_set_selectable_position(button, Vector2i(0,count))
		
		button.parent_menu = parent_menu
		button.parent_screen = self
		
		$V/Profiles/V.add_child(button)
		tween.tween_property(button, "modulate:a", 1.0, 0.1).from(0.0)
		count += 1
	
	$V/Profiles.custom_minimum_size = Vector2(0,clamp(56 * count, 0, 360))
	
	_set_selectable_position($V/Menu/Create, Vector2i(0,count))
	_set_selectable_position($V/Menu/Delete, Vector2i(0,count+1))
	_set_selectable_position($V/Menu/Cancel, Vector2i(0,count+2))


## Loads selected profile or deletes it if we are currently in delete mode
func _load_profile(profile_name : String) -> void:
	if is_in_delete_mode:
		_continue_deletion(profile_name)
		return
	
	Player._load_profile(profile_name)

	match Player.profile_status:
		Profile.PROFILE_STATUS.PROFILE_IS_MISSING:
			main._display_system_message("PROFILE IS MISSING!/nLOADING FAILED")
			return
		
		Profile.PROFILE_STATUS.PROGRESS_MISSING :
			main._display_system_message("PROFILE SAVE DATA IS MISSING!/nLOADING FAILED")
			return
		
		Profile.PROFILE_STATUS.PROGRESS_FAIL :
			main._display_system_message("PROFILE SAVE DATA IS CORRUPTED!/nLOADING FAILED")
			return

		Profile.PROFILE_STATUS.CONFIG_FAIL, Profile.PROFILE_STATUS.CONFIG_MISSING:
			var dialog : MenuScreen = parent_menu._add_screen("accept_dialog")
			dialog.desc_text = tr("PE_CONFIG_MISSING")
			dialog.accept_function = _continue_loading
			return
	
	parent_menu.screens["foreground"]._update_profile_info()
	_remove()


## Turns on delete mode
func _delete_profile() -> void:
	is_in_delete_mode = true
	$V/Text.text = tr("PE_DELETE_OPTION")
	$V/Text.modulate = Color.RED
	$V/Menu/Create._set_disable(true)
	$V/Menu/Delete.text = tr("PE_CANCEL_DELETE")


## Shows confirmation dialog for deleting selected profile and deletes it if confirmed
func _continue_deletion(profile_name : String) -> void:
	var dialog : MenuScreen = parent_menu._add_screen("")
	dialog.desc_text = tr("PE_DELETE_DIALOG")
	var accepted : bool = await dialog.closed

	if accepted:
		Player._delete_profile(profile_name)
		_delete_profile()
		# Added delay so newly created buttons wont assign to accept menu which is going to be deleted
		await get_tree().create_timer(0.8).timeout
		_display_profile_list()
		
		if profile_name == Player.profile_name:
			$V/Text.text = tr("PE_MUST_SELECT")
			$V/Menu/Cancel._set_disable(true)
	else:
		is_in_delete_mode = false
		$V/Text.text = tr("PE_SELECT_OPTION")
		$V/Text.modulate = Color.WHITE
		$V/Menu/Create._set_disable(false)
		$V/Menu/Delete.text = tr("PE_DELETE")


## Continues profile loading after confirmation dialog close
func _continue_loading() -> void:
	parent_menu.screens["foreground"]._update_profile_info()
	_remove()


## Shows input dialog for inputting new profile name
func _start_profile_create() -> void:
	var input : MenuScreen = parent_menu._add_screen("text_input")
	input.desc_text = tr("PE_CREATE_DIALOG")
	input.accept_function = _create_profile


## Creates new profile with **'profile_name'**
func _create_profile(profile_name : String) -> void:
	Player._create_profile(profile_name)
	parent_menu.screens["foreground"]._update_profile_info()
	_remove()
