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


extends HSlider

##-----------------------------------------------------------------------
## Slider is automatically connected to the parent screen **'selectables'**, which allows cursor to select it
## Then, when slider is selected, moving cursor left/right makes slider **'value'** decrease/increase, and it calls some parent screen function where changed **'value'** is passed in
##-----------------------------------------------------------------------

class_name MenuSelectableSlider

signal selected ## Emitted when slider is selected
signal deselected ## Emitted when slider is deselected
signal disable_toggled(is_off : bool) ## Emitted when slider disable state is toggled

const HOLD_BEFORE_INPUT_DASH : float = 0.25 ## How much seconds to wait before slider can "dash"

@export var menu_position : Vector2i = Vector2i(0,0) ## Slider position in current screen, used for selection by menu cursor
@export var input_dash_speed : int = 1 ## How much to increase value when slider is "dashing"

@export var call_string : String ## String this slider will send to the parent screen function if string is not empty
@export var call_function_name : String = "" ## Name of the function inside parent screen script this slider will call when change value

@export var parent_screen : MenuScreen = null ## Parent [MenuScreen] reference
var parent_menu : Menu = null ## Parent [Menu] instance

var is_selected : bool = false ## Is slider selected now by cursor
@export var is_off : bool = false ## Is slider disabled and cannot be selected
var input_hold : float = 0 ## How many seconds input is held


func _ready() -> void:
	# Slider must ignore focus to avoid double sliding bug
	focus_mode = FOCUS_NONE
	
	if not Engine.is_editor_hint():
		if parent_screen == null : parent_screen = Main.menu.current_screen
		if parent_menu == null : parent_menu = parent_screen.parent_menu
		
		add_to_group("sliders")

		_set_selectable(true)
		
		await get_tree().create_timer(0.01).timeout
		
		value_changed.connect(_work)
		mouse_entered.connect(_mouse_select)


## Sets this slider selectable state, making it either selectable or not
func _set_selectable(on : bool) -> void:
	if on and menu_position.y > -1 and menu_position.x > -1: 
		parent_screen.selectables[menu_position] = self
	elif not on:
		parent_screen.selectables.erase(menu_position)


## Called when hovered by mouse
func _mouse_select() -> void:
	if parent_menu.is_locked or parent_menu.current_screen_name != parent_screen.snake_case_name: 
		return
	
	parent_screen.cursor = menu_position
	parent_screen._move_cursor()


## Called when slider is selected
func _select() -> void:
	if parent_menu.is_locked or parent_menu.current_screen_name != parent_screen.snake_case_name: 
		return

	if not is_selected:
		is_selected = true

		# Lock left and right input, to allow changing slider value
		parent_screen.input_lock = [true,true,false,false]
		selected.emit()


## Called when slider is deseleted
func _deselect() -> void:
	if is_selected:
		is_selected = false
		
		parent_screen.input_lock = [false,false,false,false]
		deselected.emit()


## Sets slider disable state
func _set_disable(on : bool) -> void:
	is_off = on
	disable_toggled.emit(on)


## If slider is selected, player can use left and right arrow buttons to change value
func _input(event : InputEvent) -> void:
	if is_off or not is_selected or parent_menu.is_locked or parent_menu.current_screen_name != parent_screen.snake_case_name: 
		return

	if event.is_action_pressed("ui_right"): value += step
	elif event.is_action_pressed("ui_left"): value -= step


## Called when slider value changes and calls parent menu screen function if it is specified
func _work(changed_value : float) -> void:
	if is_off or parent_menu.is_locked or parent_menu.current_screen_name != parent_screen.snake_case_name: 
		return

	if call_function_name.is_empty(): return
	
	if call_string.is_empty(): parent_screen.call(call_function_name, changed_value)
	else: parent_screen.call(call_function_name, changed_value, call_string)


func _physics_process(delta : float) -> void:
	# If player holds button, value change would be quicker
	if is_selected and not parent_menu.is_locked:
		if Input.is_action_pressed("ui_right"):
			if input_hold > HOLD_BEFORE_INPUT_DASH: 
				value += step * input_dash_speed
			else: input_hold += 1 * delta
		
		elif Input.is_action_pressed("ui_left"):
			if input_hold > HOLD_BEFORE_INPUT_DASH: 
				value -= step * input_dash_speed
			else: input_hold += 1 * delta
		
		else:
			input_hold = 0
