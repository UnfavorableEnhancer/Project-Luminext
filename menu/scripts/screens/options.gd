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

signal input_received # Used for control assign sequence

enum OPTIONS_TABS {ALL, AUDIO, VIDEO, CONTROLS, LANGUAGE}

var original_config : Dictionary = {} # Stores config with which this screen was opened

var is_in_assign_mode : bool = false
var input_to_assign : InputEvent = null

var current_tab : int = OPTIONS_TABS.AUDIO


func _ready() -> void:
	if menu.screens.has("background"):
		menu.screens["background"]._change_gradient_colors(Color("00210b"),Color("00211f"),Color("0a2430"),Color("121f35"),Color("000A00"))
	
	original_config = Data.profile.config.duplicate(true)

	_set_selectables(OPTIONS_TABS.AUDIO)

	Data.input_method_changed.connect(_reload_all_action_icons)
	cursor_selection_success.connect(_scroll)

	_load_settings()

	await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()
	

func _scroll(cursor_pos : Vector2) -> void:
	if Data.current_input_mode == Data.INPUT_MODE.MOUSE: return

	if cursor_pos.x == 1:
		if current_tab == OPTIONS_TABS.AUDIO:
			$AUDIO/SCROLL.scroll_vertical = clamp(cursor_pos.y * 68 - 136 ,0 ,INF)
		elif current_tab == OPTIONS_TABS.VIDEO:
			$VIDEO/SCROLL.scroll_vertical = clamp(cursor_pos.y * 68 - 136 ,0 ,INF)


func _change_tab(to_tab : String) -> void:
	var tween : Tween = create_tween().set_parallel(true)

	match to_tab:
		"audio":
			current_tab = OPTIONS_TABS.AUDIO
			$AUDIO.visible = true
			$VIDEO.visible = false
			$CONTROLS.visible = false
			$LANGUAGE.visible = false
			_set_selectables(current_tab)
			
			tween.tween_property($AUDIO,"scale:y",1.0,0.25).from(0.0)
			tween.tween_property($AUDIO,"modulate:a",1.0,0.25).from(0.0)
		
		"video":
			current_tab = OPTIONS_TABS.VIDEO
			$AUDIO.visible = false
			$VIDEO.visible = true
			$CONTROLS.visible = false
			$LANGUAGE.visible = false
			_set_selectables(current_tab)

			tween.tween_property($VIDEO,"scale:y",1.0,0.25).from(0.0)
			tween.tween_property($VIDEO,"modulate:a",1.0,0.25).from(0.0)
		
		"controls":
			current_tab = OPTIONS_TABS.CONTROLS
			$AUDIO.visible = false
			$VIDEO.visible = false
			$CONTROLS.visible = true
			$LANGUAGE.visible = false
			_set_selectables(current_tab)

			tween.tween_property($CONTROLS,"scale:y",1.0,0.25).from(0.0)
			tween.tween_property($CONTROLS,"modulate:a",1.0,0.25).from(0.0)
		
		"language":
			current_tab = OPTIONS_TABS.LANGUAGE
			$AUDIO.visible = false
			$VIDEO.visible = false
			$CONTROLS.visible = false
			$LANGUAGE.visible = true
			_set_selectables(current_tab)

			tween.tween_property($LANGUAGE,"scale:y",1.0,0.25).from(0.0)
			tween.tween_property($LANGUAGE,"modulate:a",1.0,0.25).from(0.0)


func _change_option(value : float, setting_name : String) -> void:
	Data.profile._assign_setting(setting_name, value)
	
	if current_tab == OPTIONS_TABS.AUDIO:
		if setting_name == "music_volume" or setting_name == "sound_volume" : Data.profile._apply_setting(setting_name)


# Starts control assign sequence
func _assign_control(action_name : String) -> void:
	if is_in_assign_mode: return
	is_in_assign_mode = true

	$Overlay/Assign/Text.text = "PRESS ANY KEY/GAMEPAD BUTTON TO ASSIGN" + "\n" + tr(action_name.to_upper())

	$A.play("uassign")
	menu.is_locked = true
	
	await get_tree().create_timer(0.25).timeout
	await input_received

	Data.profile._update_input_config(action_name, input_to_assign, true)
	_load_icon_for_action(action_name)

	$A.play("unsign")
	await get_tree().create_timer(0.1).timeout
	menu.is_locked = false
	is_in_assign_mode = false


func _input(event : InputEvent) -> void:
	super(event)

	if is_in_assign_mode:
		input_to_assign = event
		input_received.emit()


func _set_selectables(tab : int) -> void:
	selectables.clear()
	
	_assign_selectable($Menu/AUDIO, Vector2i(0,0))
	_assign_selectable($Menu/VISUAL, Vector2i(0,1))
	_assign_selectable($Menu/CONTROL, Vector2i(0,2))
	_assign_selectable($Menu/LANGUAGE, Vector2(0,3))
	_assign_selectable($Menu/APPLY, Vector2i(0,4))
	_assign_selectable($Menu/RESET, Vector2i(0,5))
	_assign_selectable($Menu/RESET2, Vector2i(0,6))
	_assign_selectable($Menu/EXIT, Vector2i(0,7))

	var tab_instance : Control

	match tab:
		OPTIONS_TABS.AUDIO: tab_instance = $AUDIO/SCROLL/V
		OPTIONS_TABS.VIDEO: tab_instance = $VIDEO/SCROLL/V

		OPTIONS_TABS.CONTROLS: 
			_assign_selectable($CONTROLS/Input/MoveLeft/Button, Vector2i(1,0))
			_assign_selectable($CONTROLS/Input/MoveRight/Button, Vector2i(2,0))
			_assign_selectable($CONTROLS/Input/RotateLeft/Button, Vector2i(1,1))
			_assign_selectable($CONTROLS/Input/RotateRight/Button, Vector2i(2,1))
			_assign_selectable($CONTROLS/Input/QuickDrop/Button, Vector2i(1,2))
			_assign_selectable($CONTROLS/Input/PieceSwap/Button, Vector2i(2,2))
			_assign_selectable($CONTROLS/Input/Accept/Button, Vector2i(1,3))
			_assign_selectable($CONTROLS/Input/Cancel/Button, Vector2i(2,3))
			_assign_selectable($CONTROLS/Input/Extra/Button, Vector2i(1,4))
			return

		OPTIONS_TABS.LANGUAGE: tab_instance = $LANGUAGE/SCROLL/V
		
	var y_position : int = -1

	for child_idx : int in tab_instance.get_child_count():
		var child : Control = tab_instance.get_child(child_idx)
		if not child is TextureRect : continue

		y_position += 1
		var selectable : Control = child.get_child(0)

		_assign_selectable(selectable, Vector2i(1,y_position))


func _apply_current_tab() -> void:
	if current_tab == OPTIONS_TABS.AUDIO: Data.profile._apply_setting("all_audio")
	if current_tab == OPTIONS_TABS.VIDEO: Data.profile._apply_setting("all_video")
	if current_tab == OPTIONS_TABS.CONTROLS: Data.profile._apply_setting("all_controls")
	if current_tab == OPTIONS_TABS.LANGUAGE: Data.profile._apply_setting("all_misc")


func _reset_current_tab_to_standard() -> void:
	match current_tab:
		OPTIONS_TABS.AUDIO: Data.profile._reset_setting("all_audio")
		OPTIONS_TABS.VIDEO: Data.profile._reset_setting("all_video")
		OPTIONS_TABS.CONTROLS: Data.profile._reset_setting("all_controls")
		OPTIONS_TABS.LANGUAGE: Data.profile._reset_setting("all_misc")
	
	_load_settings()


func _reset_current_tab_changes() -> void:
	match current_tab:
		OPTIONS_TABS.AUDIO: Data.profile._reset_setting("all_audio", 0, original_config)
		OPTIONS_TABS.VIDEO: Data.profile._reset_setting("all_video", 0, original_config)
		OPTIONS_TABS.CONTROLS: Data.profile._reset_setting("all_controls", 0, original_config)
		OPTIONS_TABS.LANGUAGE: Data.profile._reset_setting("all_misc", 0, original_config)
	
	_load_settings()


func _load_settings() -> void:
	_reload_all_action_icons()
	
	$AUDIO/SCROLL/V/AUDIODEVICE/Slider.max_value = AudioServer.get_output_device_list().size() - 1
	
	get_tree().call_group("toggle_buttons","_set_toggle_by_data", Data.profile.config)
	get_tree().call_group("sliders","_set_value_by_data", Data.profile.config)
	
	_set_language_icon()


func _reload_all_action_icons() -> void:
	for action_name : String in ["rotate_right","rotate_left","move_right","move_left","quick_drop","side_ability","ui_accept","ui_cancel","ui_extra"]:
		_load_icon_for_action(action_name)


func _load_icon_for_action(action : String) -> void:
		var action_holder : TextureRect = null
		
		match action:
			"move_left" : action_holder = $CONTROLS/Input/MoveLeft
			"move_right" : action_holder = $CONTROLS/Input/MoveRight
			"rotate_left" : action_holder = $CONTROLS/Input/RotateLeft
			"rotate_right" : action_holder = $CONTROLS/Input/RotateRight
			"quick_drop" : action_holder = $CONTROLS/Input/QuickDrop
			"side_ability" : action_holder = $CONTROLS/Input/PieceSwap
			"ui_accept" : action_holder = $CONTROLS/Input/Accept
			"ui_cancel" : action_holder = $CONTROLS/Input/Cancel
			"ui_extra" : action_holder = $CONTROLS/Input/Extra
		
		action_holder.get_node("Icon").free()
		
		var new_icon : TextureRect = menu._create_button_icon(action, Vector2(48,48))
		new_icon.name = "Icon"
		new_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		new_icon.position = Vector2(616,0)
		action_holder.add_child(new_icon) 


func _select_language(locale_name : String) -> void:
	Data.profile._assign_setting("language", locale_name, Profile.SETTING_TYPE.MISC)
	_set_language_icon()


func _set_language_icon() -> void:
	get_tree().call_group("language_marks","set","visible",false)
	
	match Data.profile.config["misc"]["language"]:
		"en" : $LANGUAGE/SCROLL/V/Flag/Mark.visible = true
		"it" : $LANGUAGE/SCROLL/V/Flag2/Mark.visible = true


func _open_translation_page() -> void:
	pass


func _exit_with_apply() -> void:
	Data.profile._apply_setting("all")
	Data.profile._save_config()
	
	menu._change_screen(previous_screen_name)


func _exit_with_cancel() -> void:
	Data.profile.config = original_config

	menu._change_screen(previous_screen_name)
