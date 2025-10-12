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


extends Node

class_name Main

##-----------------------------------------------------------------------
## Boots up the game and loads all needed systems
##-----------------------------------------------------------------------

enum INPUT_MODE {KEYBOARD, MOUSE, GAMEPAD}

signal total_time_tick  ## Emitted on each total time timer timeout
signal input_method_changed ## Emitted when input method changes from keyboard to gamepad, to mouse and etc.

const DARKEN_Z_INDEX : int = 1000
const LOADING_Z_INDEX : int = 1001
const SYSTEM_MESSAGE_Z_INDEX : int = 1002

var menu : Menu ## Menu instance
var game : GameCore ## Game instance

static var current_input_mode : int = INPUT_MODE.KEYBOARD ## Current input device

@onready var darken : ColorRect = $CanvasLayer/Darken ## Dark overlay node used to cover everything
@onready var loading_screen : LoadingScreen = $CanvasLayer/LoadingScreen ## Loading screen overlay node used to cover everything
@onready var system_messager : SystemMessager = $CanvasLayer/SystemMessager ## SystemMessager

@export var start_menu_screen : String = "" ## Menu screen name which will be loaded instead of going thru standard boot sequence
@export var start_single_skin_path : String = "" ## Path to the skin which must be started with playlist mode on game boot
@export var start_skin_player_path : String = "" ## Path to the skin which must be started with skin player on game boot
@export var start_replay_path : String = "" ## Path to the replay which must be started with replay player on game boot


## Called on boot
func _ready() -> void:
	get_window().move_to_center()
	await get_tree().create_timer(0.1).timeout

	$TotalTime.timeout.connect(total_time_tick.emit)
	$TotalTime.start(1.0)
	
	PortableCompressedTexture2D.set_keep_all_compressed_buffers(true)
	Console.command_entered.connect(_execute_console_command)

	darken.modulate.a = 0.0
	loading_screen._load()

	darken.z_as_relative = false
	darken.z_index = DARKEN_Z_INDEX
	loading_screen.z_as_relative = false
	loading_screen.z_index = LOADING_Z_INDEX
	system_messager.z_as_relative = false
	system_messager.z_index = SYSTEM_MESSAGE_Z_INDEX
	
	menu = Menu.new()
	menu.main = self
	menu.name = "Menu"
	add_child(menu)
	move_child(menu,0) # Move menu node to top of the tree to make it overlayable by other things
	
	_parse_start_arguments()
	
	_reset()


## Parse command line arguments
func _parse_start_arguments() -> void:
	var start_arguments : Dictionary
	for argument : String in OS.get_cmdline_args():
		if argument.contains("="):
			var key_value : PackedStringArray = argument.split("=")
			start_arguments[key_value[0].trim_prefix("--")] = key_value[1]
		else:
			start_arguments[argument.trim_prefix("--")] = ""
	
	if start_arguments.has("menuboot") : start_menu_screen = start_arguments["startscreen"]
	if start_arguments.has("playtest") : start_single_skin_path = start_arguments["playtest"]
	if start_arguments.has("skintest") : start_skin_player_path = start_arguments["skintest"]
	if start_arguments.has("replay") : start_replay_path = start_arguments["replay"]


## Resets game and starts boot sequence
func _reset() -> void:
	if game != null: game.queue_free()
	Data.use_second_cache = false
	
	Data._load()

	Player.global._load()
	Player._load_latest()

	menu._load()

	if not start_single_skin_path.is_empty():
		var playlist : SkinPlaylist = SkinPlaylist.new()
		playlist._add_path_to_playlist(start_single_skin_path)

		var gamecore : LuminextGame = LuminextGame.new()
	
		var gamemode : Gamemode = PlaylistMode.new()
		gamemode.is_single_skin_mode = true
		gamemode.is_single_run = false
		gamemode.current_playlist = playlist

		_start_game(gamecore, gamemode)

	elif not start_skin_player_path.is_empty():
		var gamecore : GameCore = GameCore.new()
	
		# TODO
		#var gamemode : Gamemode = PlaylistMode.new()
		#gamemode.is_single_skin_mode = true
		#gamemode.is_single_run = false
		#gamemode.current_playlist = playlist

		#_start_game(gamecore, gamemode)
	
	elif not start_replay_path.is_empty():
		var replay : Replay = Replay.new()

	else:
		menu._boot(start_menu_screen)


## Plays passed replay (TODO)
func _start_replay(replay : Replay) -> void:
	Console._log("Starting the replay playback")
	pass


## Starts the passed gamecore with passed gamemode
func _start_game(gamecore : GameCore, gamemode : Gamemode) -> void:
	Console._space()
	Console._log("Starting the game")
	Console._log("Gamecore name : " + gamecore.gamecore_name)
	Console._log("Gamemode name : " + gamemode.gamemode_name)

	_toggle_darken(true)
	_toggle_loading(true)

	menu._exit()
	await get_tree().create_timer(1.0).timeout

	if menu.currently_removing_screens_amount > 0:
		await menu.all_screens_removed

	game = gamecore
	game.gamemode = gamemode
	
	game.menu = menu
	game.main = self

	add_child(game)
	move_child(game,0) # Move game node to top of the tree to make it overlayable by menu and other things
	game._reset()


func _input(event : InputEvent) -> void:
	# Determine current input mode
	if event is InputEventMouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if current_input_mode != INPUT_MODE.GAMEPAD:
			current_input_mode = INPUT_MODE.MOUSE
			input_method_changed.emit()
	elif event is InputEventJoypadButton:
		current_input_mode = INPUT_MODE.GAMEPAD
		input_method_changed.emit()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	elif event is InputEventKey:
		current_input_mode = INPUT_MODE.KEYBOARD
		input_method_changed.emit()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Toggle fullscreen
	if event.is_action_pressed("toggle_fullscreen"):
		if not Player.config.video["fullscreen"]:
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
			Player.config.video["fullscreen"] = true
		else:
			get_window().mode = Window.MODE_WINDOWED
			await get_tree().create_timer(0.1).timeout
			get_window().move_to_center()
			Player.config.video["fullscreen"] = false
	
	# Take screenshot
	if event.is_action_pressed("screenshot"):
		_take_screenshot()


## Takes screenshot and saves it as .png in SCREENSHOTS_PATH
func _take_screenshot() -> void:
	var prefix : String = "LUMINEXT"

	if game == null : prefix = menu.current_screen_name.to_upper().replace(" ","_")
	else : prefix = game.gamemode.gamemode_name.to_upper()

	var date : String = Time.get_date_string_from_system().replace(".","_") 
	var time : String = Time.get_time_string_from_system().replace(":","-")

	var screenshot_path : String = Data.SCREENSHOTS_PATH + prefix + "_" + date + "_" + time + ".png"
	var image : Image = get_viewport().get_texture().get_image() # We get what our player sees
	image.save_png(screenshot_path)

	Console._log("Saved screenshot at path : " + screenshot_path)


## Converts int (secs) to (hh:mm:ss) time format
static func _to_time(time : int) -> String:
	var hour : int = int(time / 3600.0)
	var hour_str : String = str(hour) + ":"
	if time < 3600 : hour_str = ""
	
	var minute : String = str(int(time / 60.0) - 60 * hour) + ":"
	if int(time / 60.0 - 60 * hour) < 10 : minute = "0" + str(int(time / 60.0) - 60 * hour) + ":"

	var secs : String = str(time % 60)
	if time % 60 < 10 : secs = "0" + str(time % 60)
	
	return hour_str + minute + secs


## Sets dark overlay opacity
func _toggle_darken(on : bool) -> void:
	if on : create_tween().tween_property(darken, "modulate:a", 1.0, 1.0)
	else : create_tween().tween_property(darken, "modulate:a", 0.0, 1.0)


## Toggles loading screen
func _toggle_loading(on : bool) -> void:
	loading_screen._toggle_loading(on)


## Sets loading screen message type to one from [LoadingScreen.LOADING_STATUS]
func _set_loading_message(message_type : int) -> void:
	loading_screen._set_message(message_type)


## Displays some system message which overlays everything
func _display_system_message(text : String) -> void:
	system_messager._show_message(text)


func _notification(what : int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_exit(true)


## Cleans cache to free user memory
func _clean_skn_cache() -> void:
	Console._log("Clearing cache")
	
	for cached_file : String in DirAccess.get_files_at(Data.CACHE_PATH):
		DirAccess.remove_absolute(Data.CACHE_PATH + cached_file)

	Console._log("Cache cleared!")


## Finishes all processes, saves all nessesary things and closes the game[br]
## If [b]'quick'[/b] is true closes game immidiately, without blackout animation
func _exit(quick : bool = false) -> void:
	Console._space()
	Console._log("Closing the game...")
	Console._log("Have a nice day!")
	Console._copy_logs()

	_clean_skn_cache()
	
	Player.global._save()
	Player._save()
	
	if not quick:
		create_tween().tween_property(darken,"color",Color(0,0,0,1),1.0)

		menu.is_locked = true
		if menu.is_music_playing:
			create_tween().tween_property(menu.music_player,"volume_db",-99.0,1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)

		await get_tree().create_timer(1.25).timeout
		
	
	get_tree().quit()


## Executes entered into Console command
func _execute_console_command(command : String, arguments : PackedStringArray) -> void:
	match command:
		# Resets the game completely
		"reset" : 
			_reset()
		
		# Ends game
		"exit" : 
			_exit()
		
		# Starts the skin debug with specified screen
		"skntest" :
			if arguments.size() < 1: Console._output("Error! Skin path or id is not entered"); return
			if is_instance_valid(game) : Console._output("Error! Game is already loaded"); return
			
			var metadata : SkinMetadata
			if arguments[0].is_relative_path() : metadata = Data.skin_list._get_skin_by_path(arguments[0])
			else : metadata = Data.skin_list._get_skin_by_id(arguments[0])
			
			if metadata == null: Console._output("Error! This skin doesn't exist"); return
			
			# TODO
			#_start_game()
		
		# Starts specified replay
		"replay" :
			if arguments.size() < 1: Console._output("Error! Replay path is not entered"); return
			if is_instance_valid(game) : Console._output("Error! Game is already loaded"); return

			var replay : Replay = Replay.new()
			replay._load(arguments[0])

			# TODO
			#_start_game()
