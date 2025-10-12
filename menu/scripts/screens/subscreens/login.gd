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
## Created on boot sequence and allows to edit avaiable profiles or create new one
##-----------------------------------------------------------------------

const PROFILE_BUTTON : PackedScene = preload("res://menu/objects/regular_button.tscn") ## Profile button instance


func _ready() -> void:
	parent_menu._change_music("login")
	main._toggle_darken(false)

	cursor_selection_success.connect(_scroll)
	
	parent_menu.screens["foreground"]._raise()

	match Player.profile_status:
		Profile.PROFILE_STATUS.NO_PROFILES_EXIST:
			$V/Text.text = "\n" + tr("LOGIN_WELCOME1") + "\n\n" + tr("LOGIN_WELCOME2")
			$V/Control/Line.visible = false
			$V/UNK.visible = true
			$V/Profiles.visible = false

			await parent_menu.all_screens_added
			cursor = Vector2i(0,0)
			_move_cursor()
			return

		Profile.PROFILE_STATUS.OK:
			$V/Text.text = tr("LOGIN_SELECT_OPTION")

		Profile.PROFILE_STATUS.GLOBAL_DATA_ERROR:
			$V/Text.text = tr("LOGIN_DATA_ERROR") + "\n" + tr("LOGIN_SELECT_OPTION")

		Profile.PROFILE_STATUS.PROFILE_IS_MISSING:
			$V/Text.text = tr("LOGIN_PROFILE_MISSING") + "\n" + tr("LOGIN_SELECT_OPTION")

		Profile.PROFILE_STATUS.PROGRESS_MISSING:
			$V/Text.text = tr("LOGIN_SAVEDATA_MISSING") + "\n" + tr("LOGIN_SELECT_OPTION")

		Profile.PROFILE_STATUS.PROGRESS_FAIL:
			$V/Text.text = tr("LOGIN_SAVEDATA_CORRUPT") + "\n" + tr("LOGIN_SELECT_OPTION")

		Profile.PROFILE_STATUS.CONFIG_MISSING, Profile.PROFILE_STATUS.CONFIG_FAIL:
			var dialog : MenuScreen = parent_menu._add_screen("accept_dialog")
			dialog.desc_text = tr("PE_CONFIG_MISSING")
			dialog.accept_function = _continue_loading

	_load_profile_list()

	await parent_menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


## Loads all avaiable profiles list
func _load_profile_list() -> void:
	selectables.clear()
	var tween : Tween = create_tween()
	tween.tween_interval(0.75)

	var profiles : Array[String] = Data._parse(Data.PARSE.PROFILES, true)
	var count : int = 0
	for profile_name : String in profiles:
		profile_name = profile_name.get_file().get_slice('.',0)
		
		var button : MenuSelectableButton = PROFILE_BUTTON.instantiate()

		button.call_function_name = "_load_profile"
		button.call_string = profile_name

		if profile_name == Player.profile_name : button.text = profile_name + " [CURRENT]"
		else : button.text = profile_name
		
		button.press_sound_name = "confirm4"
		button.glow_color = Color("27a1a3")
		button.custom_minimum_size = Vector2(928,48)
		button.menu_position = Vector2i(0,count)
		button.description = "PE_SELECT"
		button.description_node = $V/Desc
		button.button_layout = 13
		button.modulate.a = 0.0

		button.parent_screen = self
		button.parent_menu = parent_menu

		_set_selectable_position(button, Vector2i(0,count))

		$V/Profiles/V.add_child(button)
		tween.tween_property(button, "modulate:a", 1.0, 0.1).from(0.0)
		
		count += 1
	
	$V/Profiles.custom_minimum_size = Vector2(0,clamp(56 * count, 0, 360))

	_set_selectable_position($V/Menu/Create, Vector2i(0,count))
	_set_selectable_position($V/Menu/Exit, Vector2i(0,count+1))
	

## Scrolls profile list scroll bar
func _scroll(_cursor_pos : Vector2i) -> void:
	if main.current_input_mode == Main.INPUT_MODE.MOUSE: return

	$V/Profiles.scroll_vertical = clamp(currently_selected.position.y, 0 ,INF)


## Loads selected profile
func _load_profile(profile_name : String) -> void:
	Player._load(profile_name)

	match Player.profile_status:
		Profile.PROFILE_STATUS.PROFILE_IS_MISSING:
			main._display_system_message("PROFILE IS MISSING!\nLOADING FAILED")
			return

		Profile.PROFILE_STATUS.PROGRESS_MISSING:
			main._display_system_message("PROFILE SAVE DATA IS MISSING!\nLOADING FAILED")
			return

		Profile.PROFILE_STATUS.PROGRESS_FAIL:
			main._display_system_message("PROFILE SAVE DATA IS CORRUPTED!\nLOADING FAILED")
			return

		Profile.PROFILE_STATUS.CONFIG_FAIL, Profile.PROFILE_STATUS.CONFIG_MISSING:
			var dialog : MenuScreen = parent_menu._add_screen("accept_dialog")
			dialog.desc_text = tr("PE_CONFIG_MISSING")
			dialog.accept_function = _continue_loading
			return
	
	parent_menu.screens["foreground"]._update_profile_info()
	
	parent_menu._change_music("menu_theme")
	parent_menu._change_screen("main_menu")


## Continues profile loading after confirmation dialog close
func _continue_loading() -> void:
	parent_menu.screens["foreground"]._update_profile_info()

	parent_menu._change_music("menu_theme")
	parent_menu._change_screen("main_menu")


## Shows input dialog for inputting new profile name
func _start_profile_create() -> void:
	var input : MenuScreen = parent_menu._add_screen("text_input")
	input.desc_text = tr("PE_CREATE_DIALOG")
	input.accept_function = _create_profile


## Creates new profile with **'profile_name'**
func _create_profile(profile_name : String) -> void:
	Player._create_profile(profile_name)
	parent_menu.screens["foreground"]._update_profile_info()
	
	parent_menu._change_music("menu_theme")
	parent_menu._change_screen("main_menu")


## Shows confirmation dialog for closing the game
func _exit() -> void:
	var dialog : MenuScreen = parent_menu._add_screen("accept_dialog")
	dialog.desc_text = tr("EXIT_DIALOG")
	dialog.accept_function = main._exit
