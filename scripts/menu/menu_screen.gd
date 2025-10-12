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


extends Control

##-----------------------------------------------------------------------
## Each menu screen should have an AnimationPlayer node called **'A'**
## **'A'** must contain *'start'* and *'end'* named animations in order to work, but can have more animations if needed
## Then you can do anything you want inside menu screen and code stuff.
##-----------------------------------------------------------------------

class_name MenuScreen

signal remove_started ## Called when screen is going to be removed

signal cursor_move_try ## Called when cursor is moved
signal cursor_selection_success(cursor : Vector2) ## Called on any successfull cursor movement and returns new cursor position
signal cursor_selection_fail(cursor : Vector2, direction : int) ## Called on any failed cursor movement and returns tried cursor position and direction

enum CURSOR_DIRECTION {HERE,LEFT,RIGHT,UP,DOWN} ## Movement sides for cursor

const CURSOR_DASH_DELAY : float = 0.2 ## How many seconds wait before cursor dash
var BUTTON_SEARCH_RANGE : Array = [-2,-1,1,2] ## Range in which we try to find selectable [MenuSelectableButton]/[MenuSelectableSlider], when cursor fails to select one
var BUTTON_SEARCH_DISTANCE : int = 5 ## Distance in which we try to find selectable [MenuSelectableButton]/[MenuSelectableSlider], when cursor fails to select one

var main : Main = null
var parent_menu : Menu = null ## Parent [Menu] instance

var snake_case_name : String = "" ## Menu screen snake_case name
var previous_screen_name : String = "" ## Name of the previous menu screen, which was focused before this menu screen was added

var cursor : Vector2i = Vector2i(0,0) ## Current cursor position
var last_cursor_dir : int = CURSOR_DIRECTION.HERE ## Latest direction cursor tried to move

var input_hold : float = 0.0 ## How many seconds input button is held
var input_lock : Array[bool] = [false,false,false,false] ## Lock specific directions for cursor, so it can't move there [br] Uses four bool indexes : [LEFT, RIGHT,  UP ,DOWN]

## Avaiable buttons/sliders in this menu screen[br]
## [Vector2i(x,y)] : [MenuSelectableButton]/[MenuSelectableSlider]
var selectables : Dictionary = {} 

var currently_selected : Control = null ## Currently selected by cursor [MenuSelectableButton]/[MenuSelectableSlider]
var previously_selected : Control = null ## Previously selected by cursor [MenuSelectableButton]/[MenuSelectableSlider]

var visited_cursor_positions : Dictionary = {} ## Storage of last visited cursor positions for each X coordinate [br] [Cursor X] : [Cursor Y]
var cancel_cursor_pos : Vector2i = Vector2i(0,0) ## A position of button, which would be triggered by cancel input

@onready var animation_player : AnimationPlayer = get_node("A") if has_node("A") else null ## Menu screen animation node


## Removes this screen and automatically focuses previous menu screen if it still exists
func _remove(anim_name : String = "end") -> void:
	parent_menu._remove_screen(snake_case_name, anim_name)


## Sets selectable [MenuSelectableButton]/[MenuSelectableSlider] to given position[br]
## If some selectable was already assigned to this possition, removes it from selectable dictionary
func _set_selectable_position(selectable : Control, to_position : Vector2i) -> void:
	if selectables.has(to_position):
		if is_instance_valid(selectables[to_position]): 
			selectables[to_position].menu_position = Vector2i(-1,-1)
		selectables.erase(to_position)

	# Remove old selectable position
	if selectables.has(selectable.menu_position) and selectables[selectable.menu_position].name == selectable.name:
		selectables.erase(selectable.menu_position)
	
	selectable.menu_position = to_position
	selectables[to_position] = selectable
	
	if selectable is MenuSelectableButton and selectable.is_cancel_button : cancel_cursor_pos = to_position


## Moves cursor into **'direction'** and selects avaiable [MenuSelectableButton]/[MenuSelectableSlider][br]
## **'oneshot'** - Set true if you don't want cursor to search for selectables, if cursor failed to select
func _move_cursor(direction : int = CURSOR_DIRECTION.HERE, one_shot : bool = false) -> bool:
	if parent_menu.is_locked : return false
	if selectables.is_empty() : return false
	if parent_menu.current_screen_name != snake_case_name : return false 

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

	if direction == CURSOR_DIRECTION.RIGHT or direction == CURSOR_DIRECTION.LEFT:
		# If there's no selectable object at this coordinates, try to select last selected on that column
		if visited_cursor_positions.has(cursor.x):
			var close_position : Vector2i = Vector2i(cursor.x, visited_cursor_positions[cursor.x])
			
			if selectables.has(close_position):
				cursor = Vector2i(close_position)
				_move_cursor()
				return true
		
		#elif selectables.has(Vector2i(cursor.x, 0)):
			#cursor = Vector2i(cursor.x, 0)
			#_move_cursor()
			#return true
		
	#if direction == CURSOR_DIRECTION.UP or direction == CURSOR_DIRECTION.DOWN:
		## If there's no selectable object at this coordinates, try to select first element in row
		#if selectables.has(Vector2i(0,cursor.y)):
			#cursor = Vector2i(0,cursor.y)
			#_move_cursor()
			#return true
	
	var origin_position : Vector2i = cursor
	for i : int in BUTTON_SEARCH_RANGE:
		cursor = origin_position
		
		if direction == CURSOR_DIRECTION.RIGHT or direction == CURSOR_DIRECTION.LEFT:
			cursor.y += i
		elif direction == CURSOR_DIRECTION.UP or direction == CURSOR_DIRECTION.DOWN:
			cursor.x += i
			
		if _move_cursor(CURSOR_DIRECTION.HERE,true) == true : return true
		
		# Try to find selectable object in that direction, by recursing current function
		for ii : int in BUTTON_SEARCH_DISTANCE:
			if _move_cursor(direction,true) == true : return true
	
	# If failed to find any button at all, turn cursor back
	cursor = old_cursor_position
	cursor_selection_fail.emit(cursor, direction)
	return false


## Resets cursor to position (0,0)
func _reset_cursor() -> void:
	cursor = Vector2(0,0)
	_move_cursor()


func _input(event : InputEvent) -> void:
	if parent_menu.is_locked : return

	# Cursor movement
	if event.is_action_pressed("ui_up") and not input_lock[2]: _move_cursor(CURSOR_DIRECTION.UP)
	elif event.is_action_pressed("ui_down") and not input_lock[3]: _move_cursor(CURSOR_DIRECTION.DOWN)
	elif event.is_action_pressed("ui_right") and not input_lock[1]: _move_cursor(CURSOR_DIRECTION.RIGHT)
	elif event.is_action_pressed("ui_left") and not input_lock[0]: _move_cursor(CURSOR_DIRECTION.LEFT)
	
	# Pressing cancel button exits current menu screen
	elif event.is_action_pressed("ui_cancel"):
		if selectables.has(cancel_cursor_pos):
			selectables[cancel_cursor_pos]._work()


# Used to "dash" input when hold input button too long
func _physics_process(delta : float) -> void:
	if parent_menu.is_locked : return

	if Input.is_action_pressed("ui_right") and not input_lock[1]:
		if input_hold > CURSOR_DASH_DELAY: _move_cursor(CURSOR_DIRECTION.RIGHT)
		else: input_hold += 1 * delta
	
	elif Input.is_action_pressed("ui_left") and not input_lock[0]:
		if input_hold > CURSOR_DASH_DELAY: _move_cursor(CURSOR_DIRECTION.LEFT)
		else: input_hold += 1 * delta
	
	elif Input.is_action_pressed("ui_up") and not input_lock[2]:
		if input_hold > CURSOR_DASH_DELAY: _move_cursor(CURSOR_DIRECTION.UP)
		else: input_hold += 1 * delta
	
	elif Input.is_action_pressed("ui_down") and not input_lock[3]:
		if input_hold > CURSOR_DASH_DELAY: _move_cursor(CURSOR_DIRECTION.DOWN)
		else: input_hold += 1 * delta
	
	else:
		input_hold = 0
