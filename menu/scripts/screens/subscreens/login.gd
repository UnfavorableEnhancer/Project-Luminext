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

const PROFILE_BUTTON : PackedScene = preload("res://menu/objects/regular_button.tscn")


func _ready() -> void:
	Data.menu._change_music("login")
	create_tween().tween_property(Data.main.black,"color",Color(0,0,0,0),1.0)
	cursor_selection_success.connect(_scroll)
	
	menu.screens["foreground"]._raise()
	
	match Data.profile.status:
		Profile.STATUS.NO_PROFILES_EXIST:
			$V/Text.text = "\n" + tr("LOGIN_WELCOME1") + "\n\n" + tr("LOGIN_WELCOME2")
			$V/Control/Line.visible = false
			$V/UNK.visible = true
			$V/Profiles.visible = false
			return
		Profile.STATUS.OK:
			$V/Text.text = tr("LOGIN_SELECT_OPTION")
		Profile.STATUS.GLOBAL_DATA_ERROR:
			$V/Text.text = tr("LOGIN_DATA_ERROR") + "\n" + tr("LOGIN_SELECT_OPTION")
		Profile.STATUS.PROFILE_IS_MISSING:
			$V/Text.text = tr("LOGIN_PROFILE_MISSING") + "\n" + tr("LOGIN_SELECT_OPTION")
		Profile.STATUS.PROGRESS_MISSING:
			$V/Text.text = tr("LOGIN_SAVEDATA_MISSING") + "\n" + tr("LOGIN_SELECT_OPTION")
		Profile.STATUS.PROGRESS_FAIL:
			$V/Text.text = tr("LOGIN_SAVEDATA_CORRUPT") + "\n" + tr("LOGIN_SELECT_OPTION")
		Profile.STATUS.CONFIG_MISSING, Profile.STATUS.CONFIG_FAIL:
			var dialog : MenuScreen = menu._add_screen("accept_dialog")
			dialog.desc_text = tr("PE_CONFIG_MISSING")
			dialog.accept_function = _continue_loading

	var tween : Tween = create_tween()
	tween.tween_interval(0.75)
	var profiles : Array = Data._parse(Data.PARSE.PROFILES)
	var count : int = 0
	for profile_name : String in profiles:
		profile_name = profile_name.get_file().get_slice('.',0)
		
		var button : MenuSelectableButton = PROFILE_BUTTON.instantiate()
		button.call_function_name = "_load_profile"
		button.call_string = profile_name
		if profile_name == Data.profile.name : button.text = profile_name + " [CURRENT]"
		else : button.text = profile_name
		
		button.press_sound_name = "confirm4"
		button.glow_color = Color("27a1a3")
		button.custom_minimum_size = Vector2(928,48)
		button.menu_position = Vector2i(0,count)
		button.description = "PE_SELECT"
		button.description_node = $V/Desc
		button.button_layout = 13
		button.modulate.a = 0.0
		$V/Profiles/V.add_child(button)
		_assign_selectable(button, Vector2i(0,count))
		tween.tween_property(button, "modulate:a", 1.0, 0.1).from(0.0)
		
		count += 1
	
	$V/Profiles.custom_minimum_size = Vector2(0,clamp(56 * count, 0, 360))

	_assign_selectable($V/Menu/Create, Vector2i(0,count))
	_assign_selectable($V/Menu/Exit, Vector2i(0,count+1))
	
	await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


func _scroll(_cursor_pos : Vector2i) -> void:
	if Data.current_input_mode == Data.INPUT_MODE.MOUSE: return

	$V/Profiles.scroll_vertical = clamp(currently_selected.position.y, 0 ,INF)


func _load_profile(profile_name : String) -> void:
	Data.profile._load_profile(profile_name)

	if Data.profile.status == Profile.STATUS.PROFILE_IS_MISSING:
		Data.main._display_system_message("PROFILE IS MISSING!\nLOADING FAILED")
		return
	
	if Data.profile.status == Profile.STATUS.PROGRESS_MISSING :
		Data.main._display_system_message("PROFILE SAVE DATA IS MISSING!\nLOADING FAILED")
		return
	
	if Data.profile.status == Profile.STATUS.PROGRESS_FAIL :
		Data.main._display_system_message("PROFILE SAVE DATA IS CORRUPTED!\nLOADING FAILED")
		return

	if Data.profile.status == Profile.STATUS.CONFIG_FAIL or Data.profile.status == Profile.STATUS.CONFIG_MISSING:
		var dialog : MenuScreen = menu._add_screen("accept_dialog")
		dialog.desc_text = tr("PE_CONFIG_MISSING")
		dialog.accept_function = _continue_loading
		return
	
	menu.screens["foreground"].get_node("ProfileLayout/Name").text = profile_name
	# Hack to make music changing
	menu.is_music_playing = false
	menu._change_screen("main_menu")


func _continue_loading() -> void:
	menu.screens["foreground"].get_node("ProfileLayout/Name").text = Data.profile.name
	# Hack to make music changing
	menu.is_music_playing = false
	menu._change_screen("main_menu")


func _start_profile_create() -> void:
	var input : MenuScreen = menu._add_screen("text_input")
	input.desc_text = tr("PE_CREATE_DIALOG")
	input.accept_function = _create_profile


func _create_profile(profile_name : String) -> void:
	Data.profile._create_profile(profile_name)
	menu.screens["foreground"].get_node("ProfileLayout/Name").text = profile_name
	# Hack to make music changing
	menu.is_music_playing = false
	Data.menu._change_screen("main_menu")


func _exit() -> void:
	var dialog : MenuScreen = Data.menu._add_screen("accept_dialog")
	dialog.desc_text = tr("EXIT_DIALOG")
	dialog.accept_function = Data.main._exit
