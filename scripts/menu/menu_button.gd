extends Button

# Base class for all buttons used in current Menu API
# 
# Button is connected to the parent screen 'selectables', which allows cursor to select it
# When pressed button does an action specified by 'work_mode'.

class_name MenuSelectableButton

signal selected # Emitted when button is selected
signal deselected # Emitted when button is deselected
signal selection_toggled(is_toggled : bool) # Emitted when button is toggled

# What this button does when pressed
enum WORK_MODE {
	CALL, # Button calls a function specified in "call_function" with "call_string" as argument
	CHANGE_SCREEN, # Button changes menu screen to specified in "call_string"
	ADD_SCREEN, # Button adds new menu screen specified in "call_string"
	REMOVE_SCREEN, # Button removes existing menu screen specified in "call_string"
	TOGGLE, # Button toggles a function specified in "call_function"
	RETURN_TO_PREVIOUS_SCREEN, # Button makes menu to return to previous screen
	CALL_WHEN_SELECTED, # Button calls a function specified in "call_function" with "call_string" as argument, when selected
	KILL_THIS_SCREEN, # Button removes current menu screen
	SPECIAL # Button does some unique function which must be coded manually
	}

@export var menu_position : Vector2i = Vector2i(0,0) # Button position in current screen, used for selection by menu cursor
@export var work_mode: WORK_MODE = WORK_MODE.CALL # What button will do when pressed
@export var press_sound_name : String = '' # Button press sound name
@export var is_cancel_button : bool = false # If true this button would be triggered by cancel input

@export var call_string : String # String this button will send to the function
@export var call_function_name : String = "" # Function inside screen script this button would call

var parent_screen : MenuScreen = null

var is_selected : bool = false # Is button selected now by menu cursor
@export var is_toggled : bool = false # Is button toggled


func _ready() -> void:
	focus_mode = FOCUS_NONE
	
	if parent_screen == null : parent_screen = Data.menu.current_screen
	if work_mode == WORK_MODE.TOGGLE: add_to_group("toggle_buttons")
	
	Data.menu.screen_add_started.connect(_deselect)
	mouse_entered.connect(_mouse_select)
	pressed.connect(_work)
	
	# Make this button selectable by cursor if its in right position
	if menu_position.y > -1 and menu_position.x > -1: 
		parent_screen.selectables[menu_position] = self
	
	if is_cancel_button: 
		parent_screen.cancel_cursor_pos = menu_position
	
	if disabled:
		modulate = Color(0.5,0.5,0.5,1.0)


# Toggles this button selectable state, making it either selectable or not
func _set_selectable(on : bool) -> void:
	if on and menu_position.y > -1 and menu_position.x > -1: 
		parent_screen.selectables[menu_position] = self
	elif not on:
		parent_screen.selectables.erase(menu_position)


# Called when selected by mouse
func _mouse_select() -> void:
	if Data.menu.is_locked or Data.menu.current_screen_name != parent_screen.snake_case_name: 
		return

	parent_screen.cursor = menu_position
	parent_screen._move_cursor()


# Called when button is selected
func _select() -> void:
	if Data.menu.is_locked or Data.menu.current_screen_name != parent_screen.snake_case_name: 
		return

	if not is_selected:
		if work_mode == WORK_MODE.CALL_WHEN_SELECTED: 
			_work(true)
		
		is_selected = true
		selected.emit()


# Called when button is deseleted
func _deselect() -> void:
	if is_selected: 
		is_selected = false
		deselected.emit()


func _disable(on : bool) -> void:
	disabled = on
	if on : modulate = Color(0.5,0.5,0.5,1.0)
	else : modulate = Color.WHITE


# Called when button is pressed 
# "silent" - If true, no press sound will play
func _work(silent : bool = false) -> void:
	if Data.menu.is_locked or Data.menu.current_screen_name != parent_screen.snake_case_name: 
		return
	
	if disabled:
		var tween : Tween = create_tween()
		tween.tween_property(self,"modulate",Color.RED,0.1)
		tween.tween_property(self,"modulate",Color.GRAY,0.1)
		Data.menu._sound("error")
		return

	if not silent : Data.menu._sound(press_sound_name)
	
	match work_mode:
		WORK_MODE.CHANGE_SCREEN : Data.menu._change_screen(call_string)
		WORK_MODE.RETURN_TO_PREVIOUS_SCREEN : Data.menu._change_screen(parent_screen.previous_screen_name)
		WORK_MODE.KILL_THIS_SCREEN : parent_screen._remove()
		WORK_MODE.ADD_SCREEN : Data.menu._add_screen(call_string)
		WORK_MODE.REMOVE_SCREEN : Data.menu._remove_screen(call_string)
		WORK_MODE.TOGGLE : _toggle()
		WORK_MODE.CALL, WORK_MODE.CALL_WHEN_SELECTED : 
			if call_function_name.is_empty(): return
			
			if call_string.is_empty(): parent_screen.call(call_function_name)
			else: parent_screen.call(call_function_name, call_string)


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and is_selected:
		_work()


# Called by every press if button 'work_mode' is TOGGLE 
func _toggle() -> void:
	is_toggled = !is_toggled
	
	if not call_function_name.is_empty():
		if call_string.is_empty(): parent_screen.call(call_function_name, is_toggled)
		else: parent_screen.call(call_function_name, is_toggled, call_string)
	
	selection_toggled.emit(is_toggled)
