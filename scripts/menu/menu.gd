# Project Luminext - an ultimate block-stacking puzzle game
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
## Controls all menu screens.
## Each menu screen node must inherit [MenuScreen] class and feature an [AnimationPlayer] node called [b]'A'[/b].
## [b]'A'[/b] must contain [b]'start'[/b] and [b]'end'[/b] named animations in order to work, but can have more animations if needed
## Then you can do and code anything you want inside menu screen.
##-----------------------------------------------------------------------

class_name Menu

signal screen_remove_started ## Called when menu screen remove started
signal screen_removed(name : String) ## Called when menu screen is removed, and returns removed screen name
signal all_screens_removed ## Called when all menu screens in queue were removed

signal screen_add_started ## Called when new menu screen creation started
signal screen_added(name : String) ## Called when menu screen is added, and returns added screen name
signal all_screens_added ## Called when all menu screens in queue were added

const BUTTONS_ICONS_TEX : Texture = preload("res://images/menu/key_graphics.png") ## Build-in buttons icons atlas texture
const BUTTON_KEY_SCENE : PackedScene = preload("res://scenery/menu/button_key.tscn") ## Used when key is not in [constant BUTTONS_ICONS_TEX]

const BACKGROUND_SCREEN_Z_INDEX : int = -1500
const FOREGROUND_SCREEN_Z_INDEX : int = 500

var main : Main ## Main node reference

var is_locked : bool = false ## If true nothing could be done with menu and its screens
var is_fully_locked : bool = false ## Same as *'is_locked'* but this is used by console only
var keep_locked : bool = false ## If true menu won't unlock after all menu screens are added/removed, so menu can be unlocked manually later

var is_loading_assets : bool = false ## If true menu currently loads all its assets
var loaded_screens_data : Dictionary = {} ## All avaiable menu screens (stored as paths to .tscn files)
var loaded_music_data : Dictionary = {} ## All avaiable menu music (stored as paths to .mp3 or .ogg)
var loaded_sounds_data : Dictionary = {} ## All avaiable system sounds (stored as loaded .mp3 or .ogg instances)

var screens : Dictionary = {} ## All currently alive menu screens dictionary
var current_screen : MenuScreen = null ## Currently focused menu screen instance
var current_screen_name : String = "" ## Currently focused menu screen name (in snake_case)
var currently_adding_screens_amount : int = 0 ## Number of currently adding menu screens
var currently_removing_screens_amount : int = 0 ## Number of currently removing menu screens

var is_music_playing : bool = false ## Is menu music playing currently
var music_player : AudioStreamPlayer = null ## Menu music player node
var latest_music_sample_name : String = "" ## Name of latest playing menu music sample 
var last_music_position : float = 0.0 ## Latest menu music playback position

var foreground : MenuScreen = null ## Foreground menu screen, which always overlay other screens
var background : MenuScreen = null ## Background menu screen, which is always behind other screens

var custom_data : Dictionary = {} ## Some shared custom data which could be used freely by all menu screens


func _ready() -> void:
	name = "Menu"

	Console.opened.connect(func() -> void: is_fully_locked = true)
	Console.closed.connect(func() -> void: is_fully_locked = false)
	Console.command_entered.connect(_execute_console_command)

	Debug.menu = self


## Resets menu to its initial state
func _reset() -> void:
	for node : Node in get_children(): node.queue_free()
	
	# Reset all vars
	is_locked = false
	keep_locked = false
	currently_adding_screens_amount = 0
	currently_removing_screens_amount = 0
	current_screen = null
	current_screen_name = ""

	loaded_screens_data.clear()
	loaded_music_data.clear()
	loaded_sounds_data.clear()
	screens.clear()
	custom_data.clear()

	latest_music_sample_name = ""
	last_music_position = 0.0
	is_music_playing = false
	music_player = null


## Loads menu assets from *'res://menu'*
func _load() -> void:
	if is_loading_assets : return
	is_loading_assets = true
	
	_reset()

	Console._space()
	Console._log("Started menu loading.")
	
	if not DirAccess.dir_exists_absolute("res://menu"):
		main._display_system_message("""ERROR!\n\n"menu.pck" is missing!\nPlease make sure that you have it inside mods folder""")
		await get_tree().create_timer(5.0).timeout
		get_tree().quit()
		return
	
	Console._log("Loading menu screens...")
	
	var dir : DirAccess = DirAccess.open("res://menu/screens")
	if not dir:
		main._display_system_message("""ERROR!\n\nFailed to load provided "menu.pck".\n"res://menu/screens" directory is failed to open.\n""" + error_string(DirAccess.get_open_error()))
		await get_tree().create_timer(5.0).timeout
		get_tree().quit()
		return
	
	dir.list_dir_begin()
	var file_name : String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			var dir2 : DirAccess = DirAccess.open("res://menu/screens/" + file_name)
			if not dir2:
				Console._log("ERROR! Failed to open directory : res://menu/screens/" + file_name + " - " + error_string(DirAccess.get_open_error()))
				continue
			
			dir2.list_dir_begin()
			var file_name2 : String = dir2.get_next()
			
			while file_name2 != "":
				if not dir2.current_is_dir() and (file_name2.ends_with("tscn.remap") or file_name2.ends_with("tscn")):
					Console._log("Found menu screen : " + file_name2)

					var screen_name : String = file_name2.get_slice(".", 0)
					loaded_screens_data[screen_name] = "res://menu/screens/" + file_name + "/" + screen_name + ".tscn"
				
				file_name2 = dir2.get_next()
		
		elif file_name.ends_with("tscn.remap") or file_name.ends_with("tscn"):
			Console._log("Found menu screen : " + file_name)

			var screen_name : String = file_name.get_slice(".", 0)
			loaded_screens_data[screen_name] = "res://menu/screens/" + screen_name + ".tscn"
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# List internal menu screens here
	loaded_screens_data["skin_editor"] = "res://scenery/menu/skin_editor.tscn"
	loaded_screens_data["addon_editor"] = "res://scenery/menu/addon_editor.tscn"
	loaded_screens_data["startup"] = "res://scenery/menu/startup.tscn"
	loaded_screens_data["gameplay_edit"] = "res://scenery/menu/gameplay_edit.tscn"
	
	Console._log("All menu screens are loaded!")
	
	Console._log("Loading menu music...")
	
	dir = DirAccess.open("res://menu/music") 
	if dir:
		dir.list_dir_begin()
		file_name = dir.get_next()
		
		while file_name != "":
			# We use String.slice() to get file extension since sound data inside .pck file is present as .import files
			var file_type : String = file_name.get_slice(".", 1)
			
			if not dir.current_is_dir() and file_type in ["mp3","ogg","wav"]:
				Console._log("Found menu music : " + file_name)

				var music_name : String = file_name.get_slice(".", 0)
				loaded_music_data[music_name] = load("res://menu/music/" + music_name + "." + file_type)
			
			file_name = dir.get_next()
	else:
		Console._log("ERROR! Failed to open directory : res://menu/music" + " - " + error_string(DirAccess.get_open_error()))
	
	dir.list_dir_end()
	Console._log("All menu music files are loaded!")
	
	Console._log("Loading menu sound effects...")
	
	dir = DirAccess.open("res://menu/sounds") 
	if dir:
		dir.list_dir_begin()
		file_name = dir.get_next()
		
		while file_name != "":
			# We use String.slice() to get file extension since sound data inside .pck file is present as .import files
			var file_type : String = file_name.get_slice(".", 1)
			
			if not dir.current_is_dir() and file_type in ["ogg","wav","mp3"]:
				Console._log("Found menu sound effect : " + file_name)

				var sound_name : String = file_name.get_slice(".", 0)
				loaded_sounds_data[sound_name] = load("res://menu/sounds/" + sound_name + "." + file_type)
			
			file_name = dir.get_next()
	else:
		Console._log("ERROR! Failed to open directory : res://menu/sounds" + " - " + error_string(DirAccess.get_open_error()))
	
	dir.list_dir_end()
	Console._log("All menu sound effects are loaded!")
	
	Console._log("Menu loading completed!")
	is_loading_assets = false
	
	background = _add_screen("background", "null")
	background.z_as_relative = false
	background.z_index = BACKGROUND_SCREEN_Z_INDEX
	foreground = _add_screen("foreground", "null")
	foreground.z_as_relative = false
	foreground.z_index = FOREGROUND_SCREEN_Z_INDEX


## Starts intro sequence and loads first screens [br]
## If **'start_screen'** is passed, menu will skip intro and immidiately load passed screen
func _boot(start_screen : String = "") -> void:
	if not start_screen.is_empty():
		_add_screen(start_screen)
		return
	
	var startup_screen : MenuScreen = _add_screen("startup")
	await startup_screen.finish
	_remove_screen("startup")
	
	await get_tree().create_timer(1.0).timeout
	_add_screen("splash_screen")


## Adds new [MenuScreen] and sets it as current. Returns added menu screen reference[br]
## - **'screen_name'** - Name of the menu screen to add, which links to one of the screens avaiable in **'loaded_screens_data'**[br]
## - **'screen_anim'** - New menu screen starting animation name (enter "null" to skip animation)
func _add_screen(screen_name : String, screen_anim : String = "start") -> MenuScreen:
	if not screen_name in loaded_screens_data.keys(): 
		Console._log("Cannot add menu screen. Name not found: " + screen_name)
		return null
	
	Console._log("Adding menu screen : " + screen_name)
	is_locked = true
	currently_adding_screens_amount += 1
	screen_add_started.emit()
	
	var new_screen : MenuScreen = load(loaded_screens_data[screen_name]).instantiate()
	screens[screen_name] = new_screen
	
	new_screen.previous_screen_name = current_screen_name
	new_screen.snake_case_name = screen_name
	new_screen.parent_menu = self
	new_screen.main = main

	current_screen_name = screen_name
	current_screen = new_screen
	
	add_child(new_screen)
	
	_process_added_screen(new_screen,screen_anim)
	return new_screen

## Helper function which starts added menu screen appear animation and waits until it ends to unlock menu[br]
## So previous funciton can return [MenuScreen] instance without waiting 
func _process_added_screen(new_screen : MenuScreen, screen_anim : String) -> void:
	# We expect that screen will show its appear animation, so we wait until it ends
	if new_screen.animation_player != null and new_screen.animation_player.has_animation(screen_anim):
		new_screen.animation_player.play(screen_anim)
		await new_screen.animation_player.animation_finished
	
	screen_added.emit(new_screen.snake_case_name)
	currently_adding_screens_amount -= 1
	
	# Make sure that no other screen add/removal is queued
	if currently_adding_screens_amount == 0:
		if currently_removing_screens_amount == 0 and not keep_locked: 
			is_locked = false
		
		all_screens_added.emit()


## Removes screen from menu[br]
## - **'screen_name'** - Name of the menu screen to remove[br]
## - **'screen_anim'** - Removing menu screen ending animation (enter "null" to skip animation)
func _remove_screen(screen_name : String, screen_anim : String = "end") -> void:
	if not screens.has(screen_name): 
		Console._log("Cannot remove menu screen. Name not found: " + screen_name)
		return

	Console._log("Removing menu screen : " + screen_name)
	is_locked = true
	screen_remove_started.emit()
	
	var old_screen : MenuScreen = screens[screen_name]
	old_screen.remove_started.emit()

	if screens.has(old_screen.previous_screen_name):
		current_screen_name = old_screen.previous_screen_name
		current_screen = screens[old_screen.previous_screen_name]
		current_screen._move_cursor()

	screens.erase(screen_name)
	currently_removing_screens_amount += 1
	
	if old_screen.animation_player != null and old_screen.animation_player.has_animation(screen_anim):
		old_screen.animation_player.play(screen_anim)
		await old_screen.animation_player.animation_finished
	
	old_screen.queue_free()
	screen_removed.emit(screen_name)
	currently_removing_screens_amount -= 1
	
	# Make sure that no other screen add/removal is queued
	if currently_removing_screens_amount == 0:
		if currently_adding_screens_amount == 0: 
			if not keep_locked:
				is_locked = false

		all_screens_removed.emit()


## Replaces current menu screen with new one and removes it. Returns new [MenuScreen] reference[br]
## - **'new_screen_name'** - Name of the new menu screen which will replace current[br]
## - **'new_screen_anim'** - New menu screen starting animation (you can enter "null" to skip animation)[br]
## - **'old_screen_anim'** - Old menu screen ending animation (you can enter "null" to skip animation)
func _change_screen(new_screen_name : String, new_screen_anim : String = "start", old_screen_anim : String = "end") -> Control:
	if currently_adding_screens_amount > 0 : await all_screens_added
	if currently_removing_screens_amount > 0 : await all_screens_removed
	await get_tree().create_timer(0.01).timeout
	
	var old_screen_name : String = current_screen_name
	_remove_screen(current_screen_name, old_screen_anim)
	await all_screens_removed
	var new_screen : MenuScreen = _add_screen(new_screen_name, new_screen_anim)
	new_screen.previous_screen_name = old_screen_name
	
	return new_screen


## Reloads menu after game is over and adds menu screen with passed **'screen_name'**
func _return_from_game(screen_name : String = "main_menu") -> void:
	add_child(background)
	add_child(foreground)
	
	main._toggle_darken(false)

	# If we started game in skin playtest mode, return into skin editor.
	if screen_name == "skin_editor":
		current_screen = screens["skin_editor"]
		current_screen_name = "skin_editor"
		current_screen._end_playtest_skn()
		return

	_add_screen(screen_name)
	_change_music(latest_music_sample_name)
	if music_player != null : music_player.seek(last_music_position)


## Closes all menu screens (except "skin_editor")
func _exit() -> void:
	current_screen_name = ""
	is_locked = true
	
	# Fade-out menu music
	if music_player != null: 
		last_music_position = music_player.get_playback_position()
		
		var tween : Tween = create_tween()
		tween.tween_property(music_player,"volume_db",-99.0,1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
		tween.tween_callback(music_player.queue_free)
		is_music_playing = false
	
	for screen_name : String in screens.keys():
		# Skin editor is exception here, since it can run game in skin playtest mode. So we should have opportunity to come back.
		if screen_name == "skin_editor" : continue
		
		_remove_screen(screen_name)
	
	await all_screens_removed
	is_locked = false


## Plays one of the avaiable in **'loaded_sounds_data'** sounds. Returns reference to created for sound playback [AudioStreamPlayer][br]
## Sound files inside "menu/sound" should be "ogg" or "mp3" with **'looping'** set to false[br]
## Announcer samples should have prefix "announce_" to work correctly[br]
## - **'sound_name'** - Name of the sound sample in **'loaded_sounds_data'**[br]
## - **'stream'** - If passed, played instead of sound specified by previous parameter[br]
## - **'start_immidiately'** - Starts sound playback immidiately
func _play_sound(sound_name : String, stream : AudioStream = null, start_immidiately : bool = true) -> AudioStreamPlayer:
	if sound_name == "" : return
	if not loaded_sounds_data.has(sound_name) and stream == null: 
		Console._log("No loaded menu sound found with name : " + sound_name)
		return
	
	var player : AudioStreamPlayer = AudioStreamPlayer.new()
	
	if sound_name.begins_with("announce_"):
		if Player.config.audio["announcer"] == Config.ANNOUNCER_MODE.OFF or Player.config.audio["announcer"] == Config.ANNOUNCER_MODE.GAME_ONLY: return
		player.bus = 'Announce'
	else:
		player.bus = 'Sound'
	
	if stream != null: player.stream = stream
	else: player.stream = loaded_sounds_data[sound_name]
	
	player.finished.connect(player.queue_free)
	
	add_child(player)
	if start_immidiately : player.play()
	return player


## Changes currently playing music sample
func _change_music(music_sample_name : String = "") -> void:
	if latest_music_sample_name == music_sample_name:
		return
	
	if music_sample_name != "null" and not loaded_music_data.has(music_sample_name):
		Console._log("No loaded menu music sample found with name : " + music_sample_name)
		music_player = null
		return
	
	if music_player != null: 
		var tween : Tween = create_tween()
		tween.tween_property(music_player,"volume_db",-99.0,1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
		tween.tween_callback(music_player.queue_free)
		is_music_playing = false
		music_player = null
	
	latest_music_sample_name = music_sample_name

	if music_sample_name == "null":
		return
	
	if current_screen_name == "":
		return
	
	var music_sample : AudioStream = loaded_music_data[music_sample_name]
	
	var player : AudioStreamPlayer = AudioStreamPlayer.new()
	player.volume_db = -40.0
	player.stream = music_sample
	player.bus = "Music"
	music_player = player
	create_tween().tween_property(music_player,"volume_db",0.0,1.0).from(-99.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	is_music_playing = true
	
	player.finished.connect(player.play)
	add_child(player)
	player.play()


## Executes entered into Console command
func _execute_console_command(command : String, arguments : PackedStringArray) -> void:
	match command:
		# Toggles menu debug screen
		"mdebug" : 
			Debug._toggle(Debug.DEBUG_SCREEN.MENU)

		# Displays all avaiable menu screens/sounds/music assets
		"mlist" :
			Console._output("")
			Console._output("Loaded menu screens")
			Console._output("---------------------------------------------------")
			for screen_name : String in loaded_screens_data.keys():
				var screen_path : String = loaded_screens_data[screen_name]
				Console._output(screen_name + " : " + screen_path)
			Console._output("")
			Console._output("Loaded menu music")
			Console._output("---------------------------------------------------")
			for music_name : String in loaded_music_data.keys():
				Console._output(music_name)
			Console._output("")
			Console._output("Loaded menu sound effects")
			Console._output("---------------------------------------------------")
			for sound_name : String in loaded_sounds_data.keys():
				Console._output(sound_name)
		
		# Displays all currently loaded screens
		"minfo" :
			Console._output("")
			Console._output("Menu screens list")
			Console._output("---------------------------------------------------")
			for screen_name : String in screens.keys():
				Console._output(screen_name)
			Console._output("")
			Console._output("Custom menu data")
			Console._output("---------------------------------------------------")
			for key : String in custom_data.keys():
				var data : Variant = custom_data[key]
				Console._output(key + " : " + str(data))
		
		# Adds specified menu screen
		"madd" :
			if arguments.size() < 1: Console._output("Error! No menu screen name is entered"); return
			if not arguments[1] in loaded_screens_data.keys(): 
				Console._output("Error! This menu screen doesn't exist in loaded menu screens list...")
				return
			_add_screen(arguments[0])
		
		# Replaces current menu screen with specified one
		"msel" :
			if arguments.size() < 1: Console._output("Error! No menu screen name is entered"); return
			if not arguments[1] in loaded_screens_data.keys(): 
				Console._output("Error! This menu screen doesn't exist in loaded menu screens list...")
				return
			_change_screen(arguments[0])
		
		# Removes currently active menu screen
		"mrem" :
			if not is_instance_valid(current_screen) : Console._output("Error! Current menu screen is missing..."); return
			current_screen._remove()

		# Removes specified menu screen if it currently exists
		"mdel" :
			if arguments.size() < 1: Console._output("Error! No menu screen name is entered"); return
			if not arguments[1] in screens.keys(): 
				Console._output("Error! This menu screen doesn't exist here...")
				return
			_remove_screen(arguments[0])
		
		# Plays menu sound effect
		"msfx" :
			if arguments.size() < 1: Console._output("Error! No menu screen name is entered"); return
			if not arguments[1] in loaded_sounds_data.keys(): 
				Console._output("Error! This menu sound effect doesn't exist in loaded sound effects list...")
				return
			_play_sound(arguments[0])
		
		# Switches current menu music to specified one
		"mmus" :
			if arguments.size() < 1: Console._output("Error! No menu screen name is entered"); return
			if not arguments[1] in loaded_music_data.keys(): 
				Console._output("Error! This menu music doesn't exist in loaded music list...")
				return
			_change_music(arguments[0])
		
		# Lists all selectables in current menu screen
		"msellist" :
			if not is_instance_valid(current_screen) : Console._output("Error! Current menu screen is missing..."); return
			for selectable_coords : Vector2i in current_screen.selectables.keys():
				var selectable : Control = current_screen.selectables[selectable_coords]
				Console._output(selectable.name + " : X = " + str(selectable_coords.x) + ", Y = " +  str(selectable_coords.y))
		
		# Moves menu cursor to specified position
		"cursor" :
			if arguments.size() < 1: Console._output("Error! X coordinate is not entered"); return
			if arguments.size() < 2: Console._output("Error! Y coordinate is not entered"); return
			if not is_instance_valid(current_screen) : Console._output("Error! Current menu screen is missing..."); return
			current_screen.cursor = Vector2i(int(arguments[0]), int(arguments[1]))
			current_screen._move_cursor()


## Creates and returns a button icon node, which is useful for buttons layout display
static func _create_button_icon(action : String, button_size : Vector2 = Vector2(42,42)) -> TextureRect:
	var action_index : int
	
	match action:
		# D-pad or keyboard movement actions id's
		"all_arrows" : 
			action_index = 1001 if Main.current_input_mode == Main.INPUT_MODE.GAMEPAD else 3001
		"up_down" : 
			action_index = 1002 if Main.current_input_mode == Main.INPUT_MODE.GAMEPAD else 3002
		"left_right" : 
			action_index = 1003 if Main.current_input_mode == Main.INPUT_MODE.GAMEPAD else 3003
		"all_arrows2" : 
			action_index = 3004
		"up_down2" : 
			action_index = 3005
		"left_right2" : 
			action_index = 3006
		
		# Mouse buttons actions id's
		"mouse_left": action_index = 2001
		"mouse_right": action_index = 2002
		"mouse_middle": action_index = 2003
		
		"backspace": action_index = KEY_BACKSPACE
		
		# Any else action
		_:
			if Main.current_input_mode == Main.INPUT_MODE.GAMEPAD : 
				var gamepad_action_name : String = Player.config.control[action + "_pad"]
				action_index = int(gamepad_action_name.substr(4))
			else:
				action_index = OS.find_keycode_from_string(Player.config.control[action])
	
	var atlas_region : Rect2 = Rect2(128,128,128,128)
	var atlas_position : Vector2 = Vector2(0,0)
	var icon : TextureRect
	
	match action_index:
		# Gamepad
		JOY_BUTTON_A : atlas_position = Vector2(0,0) # XBOX A
		JOY_BUTTON_B: atlas_position = Vector2(1,0) # XBOX B
		JOY_BUTTON_X: atlas_position = Vector2(2,0) # XBOX X
		JOY_BUTTON_Y: atlas_position = Vector2(3,0) # XBOX Y
		1001:atlas_position = Vector2(5,0) # ALL ARROWS
		1002: atlas_position = Vector2(1,1) # UPDOWN
		1003: atlas_position = Vector2(0,1) # LEFTRIGHT
		JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_DPAD_DOWN : atlas_position = Vector2(4,0) # SINGLE ARROW
		JOY_BUTTON_RIGHT_SHOULDER: atlas_position = Vector2(2,1) # R1
		JOY_BUTTON_LEFT_SHOULDER: atlas_position = Vector2(3,1) # L1
		JOY_AXIS_TRIGGER_RIGHT: atlas_position = Vector2(4,1) # R2
		JOY_AXIS_TRIGGER_LEFT: atlas_position = Vector2(5,1) # L2
		JOY_BUTTON_START: atlas_position = Vector2(0,2) # START
		JOY_BUTTON_GUIDE: atlas_position = Vector2(1,2) # SELECT
		
		# Keyboard
		KEY_ENTER: atlas_position = Vector2(2,2) # ENTER
		KEY_SHIFT: atlas_position = Vector2(3,2) # SHIFT
		KEY_ESCAPE: atlas_position = Vector2(5,2) # ESC
		KEY_SPACE: atlas_position = Vector2(4,2) # SPACE
		KEY_BACKSPACE: atlas_position = Vector2(0,3) # BACKSPACE
		KEY_UP,KEY_DOWN,KEY_RIGHT,KEY_LEFT : atlas_position = Vector2(5,3)
		3001: atlas_position = Vector2(2,3) # WASD
		3002: atlas_position = Vector2(4,3) # WS
		3003: atlas_position = Vector2(3,3) # AD
		3004: atlas_position = Vector2(3,4) # ALL ARROWS
		3005: atlas_position = Vector2(5,4) # LEFT-RIGHT ARROWS
		3006: atlas_position = Vector2(4,4) # UP-DOWN ARROWS
		
		# Mouse
		2001: atlas_position = Vector2(0,4) # LEFT CLICK
		2002: atlas_position = Vector2(1,4) # RIGHT CLICK
		2003: atlas_position = Vector2(2,4) # MIDDLE CLICK

		# If no button in atlas found, this button is threated as keyboard button and special object is created and used
		_: 
			atlas_region = Rect2(128,384,128,128)
			icon = load("res://scenery/menu/button_key.tscn").instantiate()
			icon.get_node("Label").text = OS.get_keycode_string(action_index)
			return icon
	
	atlas_region.position = atlas_position * 128

	icon = TextureRect.new()
	var tex : AtlasTexture = AtlasTexture.new()
	tex.atlas = BUTTONS_ICONS_TEX
	tex.region = atlas_region
	icon.texture = tex
	# Center TextureRect
	icon.pivot_offset = Vector2(button_size.x / 2,button_size.y / 2)
	icon.custom_minimum_size = button_size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# If its single arrow button, rotate it depending on direction
	match action_index:
		JOY_BUTTON_DPAD_DOWN, KEY_DOWN, 1003 : icon.rotation_degrees = 90
		JOY_BUTTON_DPAD_LEFT, KEY_LEFT : icon.flip_h = true
		JOY_BUTTON_DPAD_UP, KEY_UP : icon.rotation_degrees = 270
	
	return icon
