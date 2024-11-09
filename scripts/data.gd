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


extends Node

#-----------------------------------------------------------------------
# Game data singletone
# Contains all file paths, main nodes references, profile and skin list data and etc.
#
# Since it's singletone, it's accessible from any piece of code.
#-----------------------------------------------------------------------

signal input_method_changed # Called when input method changes from keyboard to gamepad, to mouse and etc.
signal total_timer_tick # Called by total time timer on each timeout

enum INPUT_MODE {KEYBOARD, MOUSE, GAMEPAD}
enum PROFILE_LOAD_STATE {SUCCESS, MISSING, EMPTY}

# Used for main loading screen
enum LOADING_STATUS {
	SKIN_SAVE_START,
	SKIN_LOAD_START,
	AUDIO_PREPARE,
	VIDEO_PREPARE,
	SCENE_PREPARE,
	METADATA_SAVE,
	AUDIO_SAVE,
	TEXTURES_SAVE,
	STREAM_SAVE,
	METADATA_LOAD,
	AUDIO_LOAD,
	TEXTURES_LOAD,
	STREAM_LOAD,
	CALCULATING_BPM,
	SAVING_REPLAY,
	FINISH
}

enum PARSE {PROFILES, PLAYLISTS, PRESETS, ADDONS, MODS, REPLAYS}

const VERSION : String = "0.1.1" # Current game version
const BUILD : String = "28.09.2024" # Latest build date

const SKINS_PATH : String = "skins/" # Path to the skins folder
const PLAYLISTS_PATH : String = "playlists/" # Path to the saved playlists folder
const ADDONS_PATH : String = "addons/" # Path to the addons folder (currently unused)
const PROFILES_PATH : String = "profiles/" # Path to the profiles folder
const PRESETS_PATH : String = "presets/" # Path to the game presets folder
const MODS_PATH : String = "mods/" # Path to the .pck mods folder
const SCREENSHOTS_PATH : String = "screenshots/" # Path to the game screenshots folder
const LOGS_PATH : String = "logs/" # Path to the game logs folder
const REPLAYS_PATH : String = "replays/" # Path to the game logs folder

const BUILD_IN_PATH : String = "res://internal/" # Path to the build-in game content (which is exported with entiere project)
const GLOBAL_DATA_PATH : String = "user://global.json" # Path to the global data json
const CACHE_PATH : String = "user://cache/" # Path to the skins data cache
const MENU_PATH : String = "res://menu" # Path to the menu files, where all menu assets and screens are expected to be

var main : Node # Main node, which holds everything
var game : Node2D # Currently playing game node
var menu : Control # Currently loaded menu node

var ranking_manager : Node = null

var skin_list : SkinList = SkinList.new() # All skins list
var playlist : SkinPlaylist = SkinPlaylist.new() # Skins playlist is stored here for ease access and to make it persistent
var profile : Profile = Profile.new()

var blank_skin : SkinData = null # Loaded on game boot and is meant to be cloned where needed to speed up loading times

var loaded_addons : Array = [] # Array of all loaded addons names

# Settings which are saved globally between profiles
var global_settings : Dictionary = {
	"last_used_profile" : "",
	"first_boot" : true,
	# Local score ranking
	"60sec_standard_ranking" : [["unfavorable_enhancer",120,777]], 
	"120sec_standard_ranking" : [["unfavorable_enhancer",250,777]],
	"180sec_standard_ranking" : [["unfavorable_enhancer",400,777]],
	"300sec_standard_ranking" : [["unfavorable_enhancer",700,777]],
	"600sec_standard_ranking" : [["unfavorable_enhancer",1300,777]],
	
	"60sec_classic_ranking" : [["unfavorable_enhancer",120,777]], 
	"120sec_classic_ranking" : [["unfavorable_enhancer",240,777]],
	"180sec_classic_ranking" : [["unfavorable_enhancer",360,777]],
	"300sec_classic_ranking" : [["unfavorable_enhancer",600,777]],
	"600sec_classic_ranking" : [["unfavorable_enhancer",1200,777]],
	
	"60sec_arcade_ranking" : [["unfavorable_enhancer",100,777]], 
	"120sec_arcade_ranking" : [["unfavorable_enhancer",200,777]],
	"180sec_arcade_ranking" : [["unfavorable_enhancer",300,777]],
	"300sec_arcade_ranking" : [["unfavorable_enhancer",500,777]],
	"600sec_arcade_ranking" : [["unfavorable_enhancer",1000,777]],
	
	"60sec_3color_ranking" : [["unfavorable_enhancer",60,777]], 
	"120sec_3color_ranking" : [["unfavorable_enhancer",120,777]],
	"180sec_3color_ranking" : [["unfavorable_enhancer",180,777]],
	"300sec_3color_ranking" : [["unfavorable_enhancer",300,777]],
	"600sec_3color_ranking" : [["unfavorable_enhancer",600,777]],
	
	"60sec_hardcore_ranking" : [["unfavorable_enhancer",60,777]], 
	"120sec_hardcore_ranking" : [["unfavorable_enhancer",120,777]],
	"180sec_hardcore_ranking" : [["unfavorable_enhancer",180,777]],
	"300sec_hardcore_ranking" : [["unfavorable_enhancer",300,777]],
	"600sec_hardcore_ranking" : [["unfavorable_enhancer",600,777]],
}

var use_second_cache : bool = false # If true game will use second name for caching video & scenery
var current_input_mode : int = INPUT_MODE.KEYBOARD


# Called by main on game boot
func _ready() -> void:
	PortableCompressedTexture2D.set_keep_all_compressed_buffers(true)
	_load_global_settings()

	for path : String in [SKINS_PATH, PLAYLISTS_PATH, PROFILES_PATH, PRESETS_PATH, CACHE_PATH, SCREENSHOTS_PATH, LOGS_PATH, REPLAYS_PATH]:
		if not DirAccess.dir_exists_absolute(path):
			DirAccess.make_dir_absolute(path)

	if global_settings["last_used_profile"].is_empty():
		if _parse(PARSE.PROFILES).size() > 0:
			profile.status = Profile.STATUS.GLOBAL_DATA_ERROR
		else:
			profile.status = Profile.STATUS.NO_PROFILES_EXIST
	else:
		profile._load_profile(global_settings["last_used_profile"])

	profile._apply_setting("all")

	if profile.status == Profile.STATUS.PROFILE_IS_MISSING:
		print("WARNING! LAST USED PROFILE IS MISSING! APPLYING STANDARD SETTINGS")
	
	if profile.status == Profile.STATUS.CONFIG_FAIL:
		print("WARNING! LAST PROFILE CONFIG DATA IS MISSING! APPLYING STANDARD SETTINGS")
	
	if profile.status == Profile.STATUS.PROGRESS_FAIL:
		print("WARNING! LAST PROFILE PROGRESS DATA IS MISSING!")
	
	skin_list._check_parse()
	skin_list._parse_threaded()

	blank_skin = SkinData.new()
	blank_skin._load_standard_textures()

	var total_time_timer : Timer = Timer.new()
	total_time_timer.timeout.connect(func() -> void : profile.progress["stats"]["total_time"] += 1)
	total_time_timer.timeout.connect(total_timer_tick.emit)
	add_child(total_time_timer)
	total_time_timer.start(1.0)

	await get_tree().create_timer(0.1).timeout
	ranking_manager = Node.new()
	ranking_manager.set_script(load("res://scripts/ranking_manager.gd"))
	add_child(ranking_manager)


# Converts int (secs) to (hh:mm:ss) time format
func _to_time(time : int) -> String:
	var hour : int = int(time / 3600.0)
	var hour_str : String = str(hour) + ":"
	if time < 3600 : hour_str = ""
	
	var minute : String = str(int(time / 60.0) - 60 * hour) + ":"
	if int(time / 60.0 - 60 * hour) < 10 : minute = "0" + str(int(time / 60.0) - 60 * hour) + ":"

	var secs : String = str(time % 60)
	if time % 60 < 10 : secs = "0" + str(time % 60)
	
	return hour_str + minute + secs


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
	if event.is_action_pressed("fullscreen"):
		if not profile.config["video"]["fullscreen"]:
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
			profile.config["video"]["fullscreen"] = true
		else:
			get_window().mode = Window.MODE_WINDOWED
			profile.config["video"]["fullscreen"] = false
	
	# Take screenshot
	if event.is_action_pressed("screenshot"):
		_take_screenshot()


# Helper function which centers game window
func _center_window() -> void:
	await get_tree().create_timer(0.01).timeout
	get_window().move_to_center()


# Takes screenshot and saves it as .png in SCREENSHOTS_PATH
func _take_screenshot() -> void:
	var prefix : String = "LUMINEXT"
	if game == null:
		if menu != null:
			prefix = menu.current_screen_name.to_upper().replace(" ","_")
	else:
		if game.gamemode != null:
			prefix = game.gamemode.gamemode_name.to_upper()

	var date : String = Time.get_date_string_from_system().replace(".","_") 
	var time : String = Time.get_time_string_from_system().replace(":","-")

	var screenshot_path : String = SCREENSHOTS_PATH + prefix + "_" + date + "_" + time + ".png"
	var image : Image = get_viewport().get_texture().get_image() # We get what our player sees
	image.save_png(screenshot_path)

	print("SAVED SCREENSHOT AT PATH : " + screenshot_path)


# Loads global settings, which are shared between all profiles
func _load_global_settings() -> int:
	print("LOADING GLOBAL DATA...")
	
	var file : FileAccess = FileAccess.open(Data.GLOBAL_DATA_PATH, FileAccess.READ)
	if not file:
		print("GLOBAL DATA LOAD ERROR : ", error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()

	var parse_result : Variant = JSON.parse_string(file.get_as_text())
	if parse_result == null:
		print("GLOBAL DATA PARSE ERROR")
		return ERR_CANT_ACQUIRE_RESOURCE
	
	for key : String in parse_result.keys():
		global_settings[key] = parse_result[key]
	
	print("FINISHED")
	return OK


# Saves global settings, which are shared between all profiles
func _save_global_settings() -> int:
	print("SAVING GLOBAL DATA...")
	
	var file : FileAccess = FileAccess.open(Data.GLOBAL_DATA_PATH, FileAccess.WRITE)
	if not file:
		print("GLOBAL DATA SAVE ERROR : ", error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()
	
	file.store_string(JSON.stringify(global_settings, "\t"))
	file.close()
	
	print("FINISHED")
	return OK


# Called on game exit
func _exit_tree() -> void:
	_save_global_settings()


# Parses specified content directory and returns its file paths array.
# - 'what' - What we should parse now, specified in "PARSE" enum
# - 'output_names' - Result Array will contain file names instead of file paths
func _parse(what : int, output_names : bool = false) -> Array:
	var output : Array = []
	var parse_directory : String
	var file_extension : String
	var has_build_in : bool
	
	match what:
		PARSE.PROFILES:
			print("PARSING PROFILES DIRECTORY...")
			parse_directory = PROFILES_PATH
			has_build_in = false
			file_extension = "dat"
		PARSE.PRESETS:
			print("PARSING PRESETS DIRECTORY...")
			parse_directory = PRESETS_PATH
			has_build_in = true
			file_extension = "json"
		PARSE.PLAYLISTS:
			print("PARSING PLAYLISTS DIRECTORY...")
			parse_directory = PLAYLISTS_PATH
			has_build_in = false
			file_extension = "ply"
		PARSE.ADDONS:
			print("PARSING ADDONS DIRECTORY...")
			parse_directory = ADDONS_PATH
			has_build_in = true
			file_extension = "add"
		PARSE.MODS:
			print("PARSING MODS DIRECTORY...")
			parse_directory = MODS_PATH
			has_build_in = false
			file_extension = "pck"
		PARSE.REPLAYS:
			print("PARSING REPLAYS DIRECTORY...")
			parse_directory = REPLAYS_PATH
			has_build_in = false
			file_extension = "rpl"
		_:
			print("UNKNOWN CONTENT TYPE SPECIFIED. PARSE DENIED")
			return []

	if not DirAccess.dir_exists_absolute(parse_directory):
		print("MISSING PATH : " + parse_directory)
		DirAccess.make_dir_absolute(parse_directory)
		return []

	var dir : DirAccess = DirAccess.open(parse_directory)
	if not dir:
		dir.make_dir(parse_directory)
		print("DIRECTORY ACCESS ERROR : ", error_string(DirAccess.get_open_error()))
		return []
	
	dir.list_dir_begin()
	var file_name : String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension() == file_extension:
			if output_names : output.append(file_name.get_basename())
			else : output.append(parse_directory + file_name)
			print("FOUND FILE : ", file_name)
		file_name = dir.get_next()
	
	# If current file type we parsing is present in game build-in directory, parse it too
	if has_build_in :
		dir = DirAccess.open(Data.BUILD_IN_PATH + parse_directory)
		if not dir:
			print("BUILD-IN DIRECTORY ACCESS ERROR : ", error_string(DirAccess.get_open_error()))
			return output
		
		dir.list_dir_begin()
		file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.get_extension() == file_extension:
				if output_names : output.append(file_name.get_basename())
				else : output.append(Data.BUILD_IN_PATH + parse_directory + file_name)
				print("FOUND BUILD-IN FILE : ", file_name)
			file_name = dir.get_next()
	
	print("PARSE COMPLETE!")
	return output
