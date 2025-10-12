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
## This menu screen allows to edit profile config settings
##-----------------------------------------------------------------------

signal input_received ## Emitted when input is received, used in control assign sequence

## All avaiable options tabs
enum OPTIONS_TABS {ALL, AUDIO, VIDEO, CONTROLS, LANGUAGE, GAME}

var is_in_assign_mode : bool = false ## True if currently assigning button to an action
var input_to_assign : InputEvent = null ## Stores input which is going to be assigned to an action

var current_tab : int = OPTIONS_TABS.AUDIO ## Currently selected option tab


func _ready() -> void:
	if parent_menu.screens.has("background"):
		parent_menu.screens["background"]._change_gradient_colors(Color("00210b"),Color("00211f"),Color("0a2430"),Color("121f35"),Color("000A00"))

	_set_selectables(OPTIONS_TABS.AUDIO)

	main.input_method_changed.connect(_reload_all_action_icons)
	cursor_selection_success.connect(_scroll)

	_load_settings()

	await parent_menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()
	

## Scrolls selected tab scroll bar
func _scroll(cursor_pos : Vector2) -> void:
	if main.current_input_mode == Main.INPUT_MODE.MOUSE: return

	if cursor_pos.x == 1:
		if current_tab == OPTIONS_TABS.AUDIO:
			$AUDIO/SCROLL.scroll_vertical = clamp(cursor_pos.y * 68 - 136 ,0 ,INF)
		elif current_tab == OPTIONS_TABS.VIDEO:
			$VIDEO/SCROLL.scroll_vertical = clamp(cursor_pos.y * 68 - 136 ,0 ,INF)
		elif current_tab == OPTIONS_TABS.CONTROLS:
			$CONTROLS/SCROLL.scroll_vertical = clamp(cursor_pos.y * 68 - 136 ,0 ,INF)
		elif current_tab == OPTIONS_TABS.LANGUAGE:
			$LANGUAGE/SCROLL.scroll_vertical = clamp(cursor_pos.y * 68 - 136 ,0 ,INF)
		elif current_tab == OPTIONS_TABS.GAME:
			$GAME/SCROLL.scroll_vertical = clamp(cursor_pos.y * 68 - 136 ,0 ,INF)


## Changes current settings tab
func _change_tab(to_tab : String) -> void:
	var tween : Tween = create_tween().set_parallel(true)

	match to_tab:
		"audio":
			current_tab = OPTIONS_TABS.AUDIO
			
			$AUDIO.visible = true
			$VIDEO.visible = false
			$CONTROLS.visible = false
			$LANGUAGE.visible = false
			$GAME.visible = false
			
			$AUDIO.position = Vector2(528,88)
			_set_selectables(current_tab)
			
			tween.tween_property($AUDIO,"scale:y",1.0,0.25).from(0.0)
			tween.tween_property($AUDIO,"modulate:a",1.0,0.25).from(0.0)
		
		"video":
			current_tab = OPTIONS_TABS.VIDEO
			$AUDIO.visible = false
			$VIDEO.visible = true
			$CONTROLS.visible = false
			$LANGUAGE.visible = false
			$GAME.visible = false
			
			$VIDEO.position = Vector2(528,88)
			_set_selectables(current_tab)
			
			tween.tween_property($VIDEO,"scale:y",1.0,0.25).from(0.0)
			tween.tween_property($VIDEO,"modulate:a",1.0,0.25).from(0.0)
		
		"controls":
			current_tab = OPTIONS_TABS.CONTROLS
			$AUDIO.visible = false
			$VIDEO.visible = false
			$CONTROLS.visible = true
			$LANGUAGE.visible = false
			$GAME.visible = false
			
			$CONTROLS.position = Vector2(528,88)
			_set_selectables(current_tab)
			
			tween.tween_property($CONTROLS,"scale:y",1.0,0.25).from(0.0)
			tween.tween_property($CONTROLS,"modulate:a",1.0,0.25).from(0.0)
		
		"language":
			current_tab = OPTIONS_TABS.LANGUAGE
			$AUDIO.visible = false
			$VIDEO.visible = false
			$CONTROLS.visible = false
			$LANGUAGE.visible = true
			$GAME.visible = false
			
			$LANGUAGE.position = Vector2(528,88)
			_set_selectables(current_tab)
			
			tween.tween_property($LANGUAGE,"scale:y",1.0,0.25).from(0.0)
			tween.tween_property($LANGUAGE,"modulate:a",1.0,0.25).from(0.0)
		
		"game":
			current_tab = OPTIONS_TABS.GAME
			$AUDIO.visible = false
			$VIDEO.visible = false
			$CONTROLS.visible = false
			$LANGUAGE.visible = false
			$GAME.visible = true
			
			$GAME.position = Vector2(528,88)
			_set_selectables(current_tab)
			
			tween.tween_property($GAME,"scale:y",1.0,0.25).from(0.0)
			tween.tween_property($GAME,"modulate:a",1.0,0.25).from(0.0)


## Used by sliders to set config value
func _change_option(value : float, setting_name : String) -> void:
	Player._set_config_value(setting_name, value)
	
	if current_tab == OPTIONS_TABS.AUDIO:
		if setting_name == "music_volume" or setting_name == "sound_volume" : Player._apply_config_setting(setting_name)


## Waits for player button input and assigns it to **'action_name'**
func _assign_control(action_name : String) -> void:
	if is_in_assign_mode: return
	is_in_assign_mode = true

	$Overlay/Assign/Text.text = "PRESS ANY KEY/GAMEPAD BUTTON TO ASSIGN" + "\n" + tr(action_name.to_upper())

	$A.play("uassign")
	parent_menu.is_locked = true
	
	await get_tree().create_timer(0.25).timeout
	await input_received

	Player._update_input_config(action_name, input_to_assign, true)
	_load_icon_for_action(action_name)

	$A.play("unsign")
	await get_tree().create_timer(0.1).timeout
	parent_menu.is_locked = false
	is_in_assign_mode = false


func _input(event : InputEvent) -> void:
	super(event)

	if is_in_assign_mode:
		input_to_assign = event
		input_received.emit()


## Sets menu screen selectables for **'tab'**
func _set_selectables(tab : int) -> void:
	selectables.clear()
	
	_set_selectable_position($Menu/AUDIO, Vector2i(0,0))
	_set_selectable_position($Menu/VISUAL, Vector2i(0,1))
	_set_selectable_position($Menu/CONTROL, Vector2i(0,2))
	_set_selectable_position($Menu/LANGUAGE, Vector2(0,3))
	_set_selectable_position($Menu/GAME, Vector2(0,4))
	_set_selectable_position($Menu/APPLY, Vector2i(0,5))
	_set_selectable_position($Menu/RESET, Vector2i(0,6))
	_set_selectable_position($Menu/RESET2, Vector2i(0,7))
	_set_selectable_position($Menu/EXIT, Vector2i(0,8))

	var tab_instance : Control

	match tab:
		OPTIONS_TABS.AUDIO: tab_instance = $AUDIO/SCROLL/V
		OPTIONS_TABS.VIDEO: tab_instance = $VIDEO/SCROLL/V
		OPTIONS_TABS.CONTROLS: tab_instance = $CONTROLS/SCROLL/V
		OPTIONS_TABS.LANGUAGE: tab_instance = $LANGUAGE/SCROLL/V
		OPTIONS_TABS.GAME: tab_instance = $GAME/SCROLL/V
		
	var y_position : int = -1

	for child_idx : int in tab_instance.get_child_count():
		var child : Control = tab_instance.get_child(child_idx)
		if not child is TextureRect : continue

		y_position += 1
		var selectable : Control = child.get_child(0)

		_set_selectable_position(selectable, Vector2i(1,y_position))


## Applyes all changed settings in current tab
func _apply_current_tab() -> void:
	if current_tab == OPTIONS_TABS.AUDIO: Player._apply_setting("all_audio")
	if current_tab == OPTIONS_TABS.VIDEO: Player._apply_setting("all_video")
	if current_tab == OPTIONS_TABS.CONTROLS: Player._apply_setting("all_controls")
	if current_tab == OPTIONS_TABS.LANGUAGE: Player._apply_setting("language")
	if current_tab == OPTIONS_TABS.GAME: Player._apply_setting("all_game")


## Resets all changed settings to default values in current tab
func _reset_current_tab_to_standard() -> void:
	match current_tab:
		OPTIONS_TABS.AUDIO: Player._reset_setting("all_audio",true)
		OPTIONS_TABS.VIDEO: Player._reset_setting("all_video",true)
		OPTIONS_TABS.CONTROLS: Player._reset_setting("all_controls",true)
		OPTIONS_TABS.LANGUAGE: Player._reset_setting("language",true)
		OPTIONS_TABS.GAME: Player._reset_setting("all_game",true)
	
	_load_settings()


## Resets all changed settings to initial values in current tab
func _reset_current_tab_changes() -> void:
	match current_tab:
		OPTIONS_TABS.AUDIO: Player._reset_setting("all_audio")
		OPTIONS_TABS.VIDEO: Player._reset_setting("all_video")
		OPTIONS_TABS.CONTROLS: Player._reset_setting("all_controls")
		OPTIONS_TABS.LANGUAGE: Player._reset_setting("language")
		OPTIONS_TABS.GAME: Player._reset_setting("all_game")
	
	_load_settings()


## Loads current profile config settings
func _load_settings() -> void:
	_reload_all_action_icons()
	
	$AUDIO/SCROLL/V/AUDIODEVICE/Slider.max_value = AudioServer.get_output_device_list().size() - 1
	
	get_tree().call_group("toggle_buttons","_set_toggle_by_data")
	get_tree().call_group("sliders","_set_value_by_data")
	
	_set_language_icon()


## Loads correct button icons for all actions
func _reload_all_action_icons() -> void:
	for action_name : String in Player.config.control.keys():
		_load_icon_for_action(action_name)


## Loads correct button icons for **'action'**
func _load_icon_for_action(action : String) -> void:
		var action_holder : TextureRect = null
		
		match action:
			"move_left" : action_holder = $CONTROLS/SCROLL/V/MoveLeft
			"move_right" : action_holder = $CONTROLS/SCROLL/V/MoveRight
			"rotate_left" : action_holder = $CONTROLS/SCROLL/V/RotateLeft
			"rotate_right" : action_holder = $CONTROLS/SCROLL/V/RotateRight
			"quick_drop" : action_holder = $CONTROLS/SCROLL/V/QuickDrop
			#"side_ability" : action_holder = $CONTROLS/SCROLL/V/PieceSwap
			"ui_accept" : action_holder = $CONTROLS/SCROLL/V/Accept
			"ui_cancel" : action_holder = $CONTROLS/SCROLL/V/Cancel
			"ui_extra" : action_holder = $CONTROLS/SCROLL/V/Extra1
			_ : return
		
		action_holder.get_node("Icon").free()
		
		var new_icon : TextureRect = Menu._create_button_icon(action, Vector2(52,52))
		new_icon.name = "Icon"
		new_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		new_icon.position = Vector2(1268,0)
		action_holder.add_child(new_icon) 


## Sets game language value to **'locale-name'**
func _select_language(locale_name : String) -> void:
	Player._set_config_value("language", locale_name)
	_set_language_icon()


## Sets language icon depending on selected locale
func _set_language_icon() -> void:
	get_tree().call_group("language_marks","set","visible",false)
	
	match Player.config.misc["language"]:
		"en" : $LANGUAGE/SCROLL/V/Flag/Mark.visible = true
		"it" : $LANGUAGE/SCROLL/V/Flag2/Mark.visible = true
		"pt" : $LANGUAGE/SCROLL/V/Flag3/Mark.visible = true


## Opens GitHub wiki page about game translation
func _open_translation_page() -> void:
	OS.shell_open("https://github.com/UnfavorableEnhancer/Project-Luminext/wiki/Translating-this-game")


## Exits this menu screen with applying of all changed settings
func _exit_with_apply() -> void:
	Player._apply_config_setting("all")
	Player._save_profile()
	
	parent_menu._change_screen(previous_screen_name)


## Exits this menu screen with canceling of all changed settings
func _exit_with_cancel() -> void:
	Player._reset_config_setting("all")

	parent_menu._change_screen(previous_screen_name)
