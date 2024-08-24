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


extends Control

#-----------------------------------------------------------------------
# Menu screen class
#
# Each "screen" node should have an AnimationPlayer node called 'A'
# 'A' must contain "start" and "end" titled animations in order to work, but can have more animations if needed
# Then you can do anything you want inside menu screen and code stuff.
#-----------------------------------------------------------------------

class_name MenuScreen

@warning_ignore("unused_signal")
signal remove_started # Emitted when this menu screen is going to be removed

signal cursor_move_try # Called when cursor is moved
signal cursor_selection_success(cursor : Vector2) # Called on any successfull cursor movement, and returns new cursor position
signal cursor_selection_fail(cursor : Vector2, direction : int) # Called on any failure cursor selection (useful for setuping screen unique cursor movement rules)

enum CURSOR_DIRECTION {HERE,LEFT,RIGHT,UP,DOWN} # Movement sides for cursor

const CURSOR_DASH_DELAY : float = 0.2 # How many ticks wait before cursor dash
var BUTTON_SEARCH_SPREAD : Array = [-1,0,1] # Spread in which we try to find selectable button
var BUTTON_SEARCH_DISTANCE : int = 5 # How far we search for far away selectable, when cursor tries to move into void

@onready var menu : Control = Data.menu

var last_cursor_dir : int = CURSOR_DIRECTION.HERE # Latest direction cursor tried to move

var previous_screen_name : String = "" # Name of the screen from which this screen was opened

var currently_selected : Control = null # Currently selected by cursor selectable node
var previously_selected : Control = null # Previously selected by cursor selectable node

var input_hold : float = 0.0 # How many ticks input button is held
#                         [LEFT, RIGHT,  UP ,DOWN]
var input_lock : Array = [false,false,false,false] # Lock specific directions for cursor, so it can't move there

var snake_case_name : String = "" # Menu screen snake_case name
var cursor : Vector2i = Vector2i(0,0) # Current cursor position

# Avaiable selectables by cursor nodes
var selectables : Dictionary = {
	# Vector2i(x,y) : Selectable_node
} 

var visited_cursor_positions : Dictionary = {} # Storage for last cursor positions
var cancel_cursor_pos : Vector2i = Vector2i(0,0) # A position of selectable object, which would be triggered by cancel input

@onready var animation_player : AnimationPlayer = get_node("A") if has_node("A") else null # Menu screen animation node


# Removes this screen
func _remove(anim_name : String = "end") -> void:
	if menu.screens.has(previous_screen_name):
		menu.current_screen_name = previous_screen_name
		menu.current_screen = menu.screens[previous_screen_name]
		menu.current_screen._move_cursor()

	menu._remove_screen(snake_case_name, anim_name)


# Assigns selectable to given position coordinates (old selectable position will be removed)
func _assign_selectable(selectable : Control, to_position : Vector2i) -> void:
	if selectables.has(to_position):
		selectables[to_position].menu_position = Vector2i(-1,-1)
		selectables.erase(to_position)

	if selectables.has(selectable.menu_position) and selectables[selectable.menu_position].name == selectable.name:
		selectables.erase(selectable.menu_position)
	
	selectable.menu_position = to_position
	selectables[to_position] = selectable
	
	if selectable is MenuSelectableButton and selectable.is_cancel_button : cancel_cursor_pos = to_position


# Moves cursor into "direction" and selects selectable to use
# "oneshot" - Set true if you don't want cursor to seek for far away selectables, if cursor moved into nothing
func _move_cursor(direction : int = CURSOR_DIRECTION.HERE, one_shot : bool = false) -> bool:
	if menu.is_locked : return false
	if selectables.is_empty() : return false
	if menu.current_screen_name != snake_case_name: return false

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
		
		elif selectables.has(Vector2i(cursor.x, 0)):
			cursor = Vector2i(cursor.x, 0)
			_move_cursor()
			return true
		
	if direction == CURSOR_DIRECTION.UP or direction == CURSOR_DIRECTION.DOWN:
		# If there's no selectable object at this coordinates, try to select first element in row
		if selectables.has(Vector2i(0,cursor.y)):
			cursor = Vector2i(0,cursor.y)
			_move_cursor()
			return true
	
	for i : int in BUTTON_SEARCH_SPREAD:
		if direction == CURSOR_DIRECTION.RIGHT or direction == CURSOR_DIRECTION.LEFT:
			cursor.y += i
		elif direction == CURSOR_DIRECTION.UP or direction == CURSOR_DIRECTION.DOWN:
			cursor.x += i
		# Try to find selectable object in that direction, by recursing current function
		for ii : int in BUTTON_SEARCH_DISTANCE:
			if _move_cursor(direction,true) == true : return true
	
	# If failed to find any button at all, turn cursor back
	cursor = old_cursor_position
	cursor_selection_fail.emit(cursor, direction)
	return false


# Resets cursor to position (0,0) and resets previosly selected node
func _reset_cursor() -> void:
	currently_selected = null
	previously_selected = null
	cursor = Vector2(0,0)
	_move_cursor()


func _input(event : InputEvent) -> void:
	if menu.is_locked : return

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
	if menu.is_locked: return

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
