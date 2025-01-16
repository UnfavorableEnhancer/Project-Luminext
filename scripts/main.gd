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
# Main game script
# 
# Initiates the game, loads menu from .pck file, toggles loading animation
# could display some system message which overlay everything.
#-----------------------------------------------------------------------


@onready var messager : Control = $SysMes # System message display node
@onready var black : ColorRect = $Black # Black overlay node

var is_loading : bool = false # True when loading something
var loading_screen : MenuScreen = null # Active loading screen reference

@export_category("Debug")
@export var menu_starting_screen_name : String = "" # Screen from which menu will boot, leave empty to start standard menu boot sequence
@export var playtest_skin_path : String = "" # Path to the skin for quick playtest (relative to Data.SKINS_PATH), leave empty to load into menu instead


# Called on game boot. This is where game starts...
func _ready() -> void:
	print(OS.get_cmdline_args())
	get_window().move_to_center()

	await get_tree().create_timer(0.1).timeout

	# Store node references into Data singletone, to allow acessing them in any script file
	Data.main = self
	Data.menu = $Menu
	Data.console = $Console

	_load_mods()
	
	var start_boot_seq : bool = playtest_skin_path.is_empty()
	_load_menu(start_boot_seq, menu_starting_screen_name)
	
	if not playtest_skin_path.is_empty():
		var gamemode : Gamemode = PlaylistMode.new()
		gamemode.is_single_run = false
		gamemode.is_single_skin_mode = true
		gamemode.current_playlist = Data.playlist
		
		var skin_meta : SkinMetadata = SkinMetadata.new()
		skin_meta.path = (Data.SKINS_PATH + playtest_skin_path + ".skn").to_lower()
		_start_game(skin_meta, gamemode)


func _reset() -> void:
	is_loading = false
	if is_instance_valid(loading_screen):
		loading_screen.queue_free()
		loading_screen = null

	if Data.game != null: Data.game.queue_free()
	Data.use_second_cache = false
	
	_load_menu(true)


# Loads all .pck files stored in Data.MODS_PATH
func _load_mods() -> void:
	var mods_paths : Array = Data._parse(Data.PARSE.MODS)
	for path : String in mods_paths:
		print("LOADING MOD : " + path)
		var success : bool = ProjectSettings.load_resource_pack(path)
		if success: print("SUCCESS!")
		else: print("FAILED!")


# Loads menu assets from Data.MENU_PATH
# - 'boot_sequence' - set to true to start menu boot sequence after loading is finished
# - 'load_from_folder' - set to true to load menu from "menu" folder inside project root dir
# - 'start_screen_name' - menu screen name which menu will enter on boot
func _load_menu(boot_sequence : bool = true, start_screen_name : String = "") -> void:
	if is_loading : return
	is_loading = true
	
	Data.menu._reset()
	
	print("")
	print("MENU LOADING STARTED!")
	
	if not DirAccess.dir_exists_absolute(Data.MENU_PATH):
		_display_system_message("""ERROR!\n\n"menu.pck" is missing!\nPlease make sure that you have it inside game folder""")
		await get_tree().create_timer(4.0).timeout
		get_tree().quit()
		return
	
	print("LOADING SCREENS...")
	
	var dir : DirAccess = DirAccess.open("res://menu/screens")
	if not dir:
		_display_system_message("""MENU LOADING ERROR!\n\nINVALID FOLDER STRUCTURE\nPLEASE REPLACE THIS "menu.pck" """)
		await get_tree().create_timer(4.0).timeout
		get_tree().quit()
		return
	
	dir.list_dir_begin()
	var file_name : String = dir.get_next()
	while file_name != "":
		print(file_name)
		
		if dir.current_is_dir():
			var dir2 : DirAccess = DirAccess.open("res://menu/screens/" + file_name)
			if not dir2:
				print("DIR OPEN ERROR : ", error_string(DirAccess.get_open_error()))
				continue
			
			dir2.list_dir_begin()
			var file_name2 : String = dir2.get_next()
			
			while file_name2 != "":
				print(file_name2)
				
				if not dir2.current_is_dir() and file_name2.get_slice(".", 1) == "tscn":
					print("SCREEN FOUND : " + file_name2)
					var screen_name : String = file_name2.get_slice(".", 0)
					Data.menu.loaded_screens_data[screen_name] = "res://menu/screens/" + file_name + "/" + screen_name + ".tscn"
				
				file_name2 = dir2.get_next()
		
		elif file_name.ends_with("tscn.remap"):
			print("SCREEN FOUND : " + file_name)
			var screen_name : String = file_name.get_slice(".", 0)
			Data.menu.loaded_screens_data[screen_name] = "res://menu/screens/" + screen_name + ".tscn"
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Force some of the screens so they would be loaded anyway
	Data.menu.loaded_screens_data["skin_editor"] = "res://scenery/menu/skin_editor.tscn"
	Data.menu.loaded_screens_data["addon_editor"] = "res://scenery/menu/addon_editor.tscn"
	Data.menu.loaded_screens_data["startup"] = "res://scenery/menu/startup.tscn"
	Data.menu.loaded_screens_data["gameplay_edit"] = "res://scenery/menu/gameplay_edit.tscn"
	
	print("DONE")
	
	print("LOADING MENU MUSIC...")
	
	dir = DirAccess.open("res://menu/music") 
	if dir:
		dir.list_dir_begin()
		file_name = dir.get_next()
		
		while file_name != "":
			print(file_name)
			
			# We use String.slice() to get file extension since sound data inside .pck file is present as .import files
			var file_type : String = file_name.get_slice(".", 1)
			
			if not dir.current_is_dir() and file_type in ["mp3","ogg","wav"]:
				print("MUSIC FOUND : " + file_name)
				var music_name : String = file_name.get_slice(".", 0)
				Data.menu.loaded_music_data[music_name] = load("res://menu/music/" + music_name + "." + file_type)
			
			file_name = dir.get_next()
	else:
		print("FAILED")
	
	dir.list_dir_end()
	print("DONE")
	
	print("LOADING SYSTEM SOUNDS...")
	
	dir = DirAccess.open("res://menu/sounds") 
	if dir:
		dir.list_dir_begin()
		file_name = dir.get_next()
		
		while file_name != "":
			print(file_name)
			
			# We use String.slice() to get file extension since sound data inside .pck file is present as .import files
			var file_type : String = file_name.get_slice(".", 1)
			
			if not dir.current_is_dir() and file_type in ["ogg","wav","mp3"]:
				print("SOUND FOUND : " + file_name)
				var sound_name : String = file_name.get_slice(".", 0)
				Data.menu.loaded_sounds_data[sound_name] = load("res://menu/sounds/" + sound_name + "." + file_type)
			
			file_name = dir.get_next()
	else:
		print("FAILED")
	
	dir.list_dir_end()
	print("DONE")
	
	print("MENU LOADING FINISHED!")
	is_loading = false
	
	# Make black overlay invisible
	black.color = Color(0,0,0,0)
	
	# Start intro sequence if desired
	if boot_sequence: Data.menu._boot(start_screen_name)


func _start_replay(replay : Replay) -> void:
	var gamemode : Gamemode = null
	var first_skin_metadata : SkinMetadata = SkinMetadata.new()
	var gamemode_settings : Dictionary = replay.gamemode_settings

	if not gamemode_settings.has("name"):
		print("INVALID REPLAY LOADING")
		_display_system_message("REPLAY LOADING FAILED!")
		return
	
	match gamemode_settings["name"]:
		"time_attack_mode":
			gamemode = TimeAttackMode.new()

			var selected_time : int = gamemode_settings["time_limit"]
			if selected_time < 300:
				first_skin_metadata.path = Data.BUILD_IN_PATH + Data.SKINS_PATH + "grandmother_clock.skn"
			if selected_time >= 300:
				first_skin_metadata.path = Data.BUILD_IN_PATH + Data.SKINS_PATH + "the_years_will_pass.skn"
			
			gamemode.time_limit = selected_time
			gamemode.ruleset = gamemode_settings["ruleset"]
			gamemode.current_mix = gamemode_settings["mix"]
			gamemode.random_mixes = false
			gamemode.current_seed = gamemode_settings["seed"]
			
		"playlist_mode":
			gamemode = PlaylistMode.new()
			gamemode.custom_config_preset = gamemode_settings["ruleset"]
			first_skin_metadata.path = gamemode_settings["skin_path"]
			gamemode.rng_start_seed = gamemode_settings["seed"]
		
		_: 
			print("INVALID REPLAY GAMEMODE")
			_display_system_message("INVALID REPLAY!")
			return
	
	_start_game(first_skin_metadata, gamemode, replay)


# Starts the game of LUMINEXT
func _start_game(first_skin : Variant, gamemode : Gamemode, replay : Replay = null) -> void:
	# Check if at least one color is enabled
	var color_check : bool = false
	for color : String in ["red","white","green","purple"]:
		if Data.profile.config["gameplay"][color]: color_check = true; break

	if not color_check:
		print("NO COLORS AVAIABLE!")
		_display_system_message("WARNING! NO BLOCK COLORS ENABLED!\nPLEASE TOGGLE ON SOME COLORS IN GAME CONFIGURATION")
		return
	
	if first_skin == null:
		print("SKIN LOADING ERROR! NO SKIN SPECIFIED!") 
		_display_system_message("SKIN LOADING ERROR!\nNO SKIN SPECIFIED!")
		return

	if gamemode == null:
		print("SKIN LOADING ERROR! NO GAMEMODE LOADED!") 
		_display_system_message("SKIN LOADING ERROR!\nINVALID GAMEMODE!")
		return
	
	if is_loading : return
	is_loading = true

	print("")
	print("STARTING GAME...")

	Data.menu._exit()

	# Start "blackout" and loading animations
	create_tween().tween_property(black,"color",Color(0,0,0,1),1.0)
	_toggle_loading(true)
	
	var skin_data : SkinData

	if first_skin is SkinMetadata: 
		if not FileAccess.file_exists(first_skin.path):
			print("SKIN LOADING ERROR! INVALID SKIN PATH : ", first_skin.path) 
			_display_system_message("SKIN LOADING ERROR!\nINVALID SKIN PATH:\n\n" + first_skin.path)
			return
		skin_data = SkinData.new()

		var thread : Thread = Thread.new()
		var err : int = 0
		
		# If skin is inside addon file (which extension is "add"), to load it we must use different function
		if first_skin.path.get_extension() == "add":
			err = thread.start(skin_data._load_from_addon.bind(first_skin))
		else:
			err = thread.start(skin_data._load_from_path.bind(first_skin.path))
		
		await skin_data.skin_loaded
		await get_tree().create_timer(0.01).timeout
		var result : int = thread.wait_to_finish()
		
		if result != OK or err != OK:
			print("THREAD ERROR : " + error_string(err))
			print("SKIN LOADING ERROR : " + error_string(result))
			_display_system_message("SKIN LOADING ERROR!\n" + error_string(result) + "\n" + first_skin.path)
			
			await get_tree().create_timer(2).timeout
			
			# Return to menu
			create_tween().tween_property(black,"color",Color(0,0,0,0),1.0)
			_toggle_loading(false)
			Data.menu._return_from_game()
			return
	
	elif first_skin is SkinData: 
		skin_data = first_skin
	else:
		print("SKIN LOADING ERROR! UNKNOWN SKIN FORMAT") 
		_display_system_message("SKIN LOADING ERROR!\nUNKNOWN SKIN FORMAT")
		return

	# Allow gamemode to preprocess some heavy stuff if it has such
	if gamemode.use_preprocess:
		var thread : Thread = Thread.new()
		var err : int = thread.start(gamemode._preprocess)
		await gamemode.preprocess_finished
		await get_tree().create_timer(0.01).timeout
		var result : int = thread.wait_to_finish()

		if result != OK or err != OK:
			print("GAMEMODE PREPROCESS ERROR CODE : " + str(err))
			_display_system_message(gamemode.error_text)
			
			await get_tree().create_timer(2).timeout
			
			# Return to menu
			create_tween().tween_property(black,"color",Color(0,0,0,0),1.0)
			_toggle_loading(false)
			Data.menu._return_from_game()
			return
	
	if Data.menu.currently_removing_screens_amount > 0:
		await Data.menu.all_screens_removed
	
	await get_tree().create_timer(0.25).timeout

	var game : Node2D = load("res://scenery/game/game.tscn").instantiate()
	Data.game = game
	game.gamemode = gamemode
	game._add_skin(skin_data)
	
	add_child(game)
	if replay != null : 
		game.replay.inputs_anim = replay.inputs_anim
		game.is_playing_replay = true
	game.add_child(gamemode)
	# Move game node up to make it overlayable by menu
	move_child(game,0)
	
	_toggle_loading(false)
	print("GAME BOOT FINISHED!")
	
	game._reset()
	
	create_tween().tween_property(black,"color",Color(0,0,0,0),1.0)
	is_loading = false


# Starts the skin debug test
func _test_skin(skin_metadata : SkinMetadata) -> void:
	# Check if at least one color is enabled
	if skin_metadata == null or not FileAccess.file_exists(skin_metadata.path):
		print("SKIN LOADING ERROR! INVALID SKIN PATH!" + skin_metadata.path) 
		_display_system_message("SKIN LOADING ERROR!\nINVALID SKIN PATH!\n\n" + skin_metadata.path)
		return
	
	if is_loading : return
	is_loading = true

	print("")
	print("STARTING SKIN TEST...")

	Data.menu._exit()

	# Start "blackout" and loading animations
	create_tween().tween_property(black,"color",Color(0,0,0,1),1.0)
	_toggle_loading(true)
	
	var skin_data : SkinData

	skin_data = Data.blank_skin._clone()
	skin_data.io_progress.connect(_change_loading_message)

	var thread : Thread = Thread.new()
	var err : int = 0

	# If skin is inside addon file (which extension is "add"), to load it we must use different function
	if skin_metadata.path.get_extension() == "add":
		err = thread.start(skin_data._load_from_addon.bind(skin_metadata))
	else:
		err = thread.start(skin_data._load_from_path.bind(skin_metadata.path))
	
	await skin_data.skin_loaded
	await get_tree().create_timer(0.01).timeout
	var result : int = thread.wait_to_finish()
	
	if result != OK or err != OK:
		print("THREAD ERROR : " + error_string(err))
		print("SKIN LOADING ERROR : " + error_string(result))
		_display_system_message("SKIN LOADING ERROR!\n" + error_string(result) + "\n" + skin_metadata.path)
		
		await get_tree().create_timer(2).timeout
		
		# Return to menu
		create_tween().tween_property(black,"color",Color(0,0,0,0),1.0)
		_toggle_loading(false)
		Data.menu._return_from_game()
		return
	
	if Data.menu.currently_removing_screens_amount > 0:
		await Data.menu.all_screens_removed
	
	await get_tree().create_timer(0.25).timeout
	
	var skin_test : Node2D = load("res://scenery/debug/skin_test.tscn").instantiate()
	
	skin_test._add_skin(skin_data)
	add_child(skin_test)
	print("SKIN TEST BOOT FINISHED!")
	
	_toggle_loading(false)
	create_tween().tween_property(black,"color",Color(0,0,0,0),1.0)
	is_loading = false


# Toggles loading animation. Menu must be loaded first in order to work.
func _toggle_loading(on : bool) -> void:
	if Data.menu.loaded_screens_data.has("loading"):
		if on and loading_screen == null:
			loading_screen = load(Data.menu.loaded_screens_data["loading"]).instantiate()
			add_child(loading_screen)
			loading_screen.get_node("A").play("start")
		elif not on and loading_screen != null:
			loading_screen.get_node("A").play("end")
			await loading_screen.get_node("A").animation_finished
			loading_screen.queue_free()
			loading_screen = null


func _change_loading_message(message : int) -> void:
	if not loading_screen: return

	var message_text : String = ""

	match message:
		Data.LOADING_STATUS.SKIN_LOAD_START: message_text = "LOADING SKIN..."
		Data.LOADING_STATUS.SKIN_SAVE_START: message_text = "SAVING SKIN..."
		Data.LOADING_STATUS.METADATA_LOAD: message_text = "LOADING METADATA..."
		Data.LOADING_STATUS.METADATA_SAVE: message_text = "SAVING METADATA..."
		Data.LOADING_STATUS.AUDIO_PREPARE: message_text = "PREPARING MUSIC..."
		Data.LOADING_STATUS.AUDIO_LOAD: message_text = "LOADING SOUNDS..."
		Data.LOADING_STATUS.AUDIO_SAVE: message_text = "SAVING SOUNDS..."
		Data.LOADING_STATUS.TEXTURES_LOAD: message_text = "LOADING TEXTURES..."
		Data.LOADING_STATUS.TEXTURES_SAVE: message_text = "SAVING TEXTURES..."
		Data.LOADING_STATUS.STREAM_LOAD: message_text = "LOADING SCENERY/VIDEO & MUSIC..."
		Data.LOADING_STATUS.STREAM_SAVE: message_text = "SAVING SCENERY/VIDEO & MUSIC..."
		Data.LOADING_STATUS.VIDEO_PREPARE: message_text = "PREPARING VIDEO..."
		Data.LOADING_STATUS.SCENE_PREPARE: message_text = "PREPARING SCENERY..."
		Data.LOADING_STATUS.CALCULATING_BPM: message_text = "CALCULATING SONG BPM..."
		Data.LOADING_STATUS.SAVING_REPLAY: message_text = "SAVING REPLAY..."
		Data.LOADING_STATUS.FINISH: message_text = "PLEASE WAIT"

	loading_screen._set_text(message_text)


# Shows system message which overlays everything
func _display_system_message(text : String) -> void:
	messager._show_message(text)


# Cleans cache to free user memory
func _clean_skn_cache() -> void:
	print("CLEANING UP CACHE")
	var dir : DirAccess = DirAccess.open(Data.CACHE_PATH)
	
	if dir:
		dir.list_dir_begin()
		
		var path : String = dir.get_next()
		while path != "":
			print("CLEANING : ", path)
			if not dir.current_is_dir(): dir.remove(path)
			path = dir.get_next()
		
		dir.list_dir_end()

	print("CACHE CLEANED!")


# Copies logs from "user://logs" to Data.LOGS_PATH
func _copy_logs() -> void:
	print("COPYING LOGS")
	var log_names : PackedStringArray = DirAccess.get_files_at("user://logs/")

	for log_name : String in log_names:
		print(log_name)
		var file : FileAccess = FileAccess.open("user://logs/" + log_name, FileAccess.READ)
		var log_text : String = file.get_as_text()
		file.close()
		file = FileAccess.open(Data.LOGS_PATH + log_name, FileAccess.WRITE)
		file.store_string(log_text)
		file.close()

	print("LOGS SAVED")



func _notification(what : int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_exit(true)


# This function ends this programm properly.
func _exit(quick : bool = false) -> void:
	print("")
	print("EXITING...")

	_clean_skn_cache()
	_copy_logs()
	
	if not quick:
		create_tween().tween_property(black,"color",Color(0,0,0,1),1.0)

		Data.menu.is_locked = true
		if Data.menu.is_music_playing:
			create_tween().tween_property(Data.menu.music_player,"volume_db",-40.0,1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)

		await get_tree().create_timer(1.25).timeout
		get_tree().quit()
	
