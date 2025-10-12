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


extends Button

##-----------------------------------------------------------------------
## Button is automatically connected to the parent screen **'selectables'**, which allows cursor to select it
## When pressed button does an action specified by **'work_mode'**.
##-----------------------------------------------------------------------

class_name MenuSelectableButton

signal selected ## Emitted when button is selected
signal deselected ## Emitted when button is deselected
signal selection_toggled(is_toggled : bool) ## Emitted when button is toggled
signal disable_toggled(is_off : bool) ## Emitted when button disable state is toggled

## All possible button press actions
enum WORK_MODE {
	CALL, ## Button calls a function specified in "call_function" with "call_string" as argument
	CHANGE_SCREEN, ## Button changes menu screen to specified in "call_string"
	ADD_SCREEN, ## Button adds new menu screen specified in "call_string"
	REMOVE_SCREEN, ## Button removes existing menu screen specified in "call_string"
	TOGGLE, ## Button toggles a function specified in "call_function"
	RETURN_TO_PREVIOUS_SCREEN, ## Button makes menu to return to previous screen
	CALL_WHEN_SELECTED, ## Button calls a function specified in "call_function" with "call_string" as argument, when selected
	KILL_THIS_SCREEN, ## Button removes current menu screen
	SPECIAL ## Button does some unique function which must be coded manually
}

@export var menu_position : Vector2i = Vector2i(0,0) ## Button position in current screen, used for selection by menu cursor
@export var work_mode: WORK_MODE = WORK_MODE.CALL ## What this button does when pressed
@export var press_sound_name : String = '' ## Button press sound name
@export var is_cancel_button : bool = false ## If true this button would be triggered by cancel input on current screen

@export var call_string : String # String this button will send to the parent screen function if string is not empty
@export var call_function_name : String = "" # Name of the function inside parent screen script this button will call on press

@export var parent_screen : MenuScreen = null ## Parent [MenuScreen] reference
var parent_menu : Menu = null ## Parent [Menu] instance

var accept_action : Callable ## What action this button should do on accept pressed (works only in [WORK_MODE.SPECIAL])
var cancel_action : Callable ## What action this button should do on cancel pressed (works only in [WORK_MODE.SPECIAL])
var extra_action : Callable ## What action this button should do on extra pressed (works only in [WORK_MODE.SPECIAL])

var is_selected : bool = false ## Is button selected now by menu cursor
@export var is_off : bool = false ## Is button disabled and cannot be selected
@export var is_toggled : bool = false ## Is button toggled


func _ready() -> void:
	# Slider must ignore focus to avoid some mouse related bugs
	focus_mode = FOCUS_NONE
	
	# Temporary solution
	if not Engine.is_editor_hint():
		if parent_menu == null : parent_menu = parent_screen.parent_menu
	
		if work_mode == WORK_MODE.TOGGLE: add_to_group("toggle_buttons")

		parent_menu.screen_add_started.connect(_deselect)
		gui_input.connect(_on_press)
		mouse_entered.connect(_mouse_select)
	
		_set_selectable(true)
		if is_cancel_button: parent_screen.cancel_cursor_pos = menu_position
		if is_disabled: disable_toggled.emit(true)


## Sets this button selectable state, making it either selectable or not
func _set_selectable(on : bool) -> void:
	if on and menu_position.y > -1 and menu_position.x > -1: 
		parent_screen.selectables[menu_position] = self
	elif not on:
		parent_screen.selectables.erase(menu_position)


## Called when button is selected
func _select() -> void:
	if parent_menu.is_locked or parent_menu.current_screen_name != parent_screen.snake_case_name: 
		return

	if not is_selected:
		is_selected = true

		if work_mode == WORK_MODE.CALL_WHEN_SELECTED: _work(true)
		selected.emit()


## Called when button is deseleted
func _deselect() -> void:
	if is_selected: 
		is_selected = false
		deselected.emit()


## Sets button disable state
func _set_disable(on : bool) -> void:
	is_off = on
	disable_toggled.emit(on)


## Called when hovered by mouse
func _mouse_select() -> void:
	if parent_menu.is_locked or parent_menu.current_screen_name != parent_screen.snake_case_name: 
		return

	parent_screen.cursor = menu_position
	parent_screen._move_cursor()


# Mouse input handler
func _on_press(event : InputEvent) -> void:
	if is_off or not is_selected or parent_menu.is_locked or parent_menu.current_screen_name != parent_screen.snake_case_name: 
		return

	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT: 
				_work()
			MOUSE_BUTTON_RIGHT: 
				cancel_action.call()
			MOUSE_BUTTON_MIDDLE: 
				extra_action.call()


# Keyboard input handler
func _input(event : InputEvent) -> void:
	if is_off or not is_selected or parent_menu.is_locked or parent_menu.current_screen_name != parent_screen.snake_case_name: 
		return

	if event.is_action_pressed("ui_accept") : 
		_work()
	elif event.is_action_pressed("ui_cancel") and work_mode == WORK_MODE.SPECIAL: 
		cancel_action.call()
	elif event.is_action_pressed("ui_extra") and work_mode == WORK_MODE.SPECIAL:
		extra_action.call()


## Called when button is pressed [br]
## **'silent'** - If true, no press sound will play
func _work(silent : bool = false) -> void:
	if not silent : parent_menu._play_sound(press_sound_name)
	
	match work_mode:
		WORK_MODE.CHANGE_SCREEN : parent_menu._change_screen(call_string)
		WORK_MODE.RETURN_TO_PREVIOUS_SCREEN : parent_menu._change_screen(parent_screen.previous_screen_name)
		WORK_MODE.KILL_THIS_SCREEN : parent_screen._remove()
		WORK_MODE.ADD_SCREEN : parent_menu._add_screen(call_string)
		WORK_MODE.REMOVE_SCREEN : parent_menu._remove_screen(call_string)
		WORK_MODE.TOGGLE : _toggle()
		WORK_MODE.CALL, WORK_MODE.CALL_WHEN_SELECTED : 
			if call_function_name.is_empty(): return
			
			if call_string.is_empty(): parent_screen.call(call_function_name)
			else: parent_screen.call(call_function_name, call_string)
		WORK_MODE.SPECIAL : accept_action.call()


## Called by every press if button 'work_mode' is TOGGLE 
func _toggle() -> void:
	if work_mode != WORK_MODE.TOGGLE or is_off: return

	is_toggled = !is_toggled
	
	if not call_function_name.is_empty():
		if call_string.is_empty(): parent_screen.call(call_function_name, is_toggled)
		else: parent_screen.call(call_function_name, is_toggled, call_string)
	
	selection_toggled.emit(is_toggled)
