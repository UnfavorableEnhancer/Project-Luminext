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


extends Resource

class_name Profile

#-----------------------------------------------------------------------
# PLayer profile class
# 
# Contains all game settings and player progress (achievements, records and etc.)
# Stored as two files: "config.json" - is used to store settings and can me modified externally
# and "progress.dat" - is used to store progress data and is encrypted to not allow average user open it
#-----------------------------------------------------------------------


signal setting_changed(setting_name : String)
signal settings_changed
signal progress_changed

signal profile_loaded


enum STATUS {
	OK, 
	PROGRESS_FAIL, # Progress loading/saving failed
	PROGRESS_MISSING, # Progress file is missing
	CONFIG_FAIL, # Config file loading/saving failed
	CONFIG_MISSING, # Config file is missing
	PROFILE_IS_MISSING, # Whole profile is missing
	GLOBAL_DATA_ERROR, # Last profile name was lost
	NO_PROFILES_EXIST # Profile directory is empty
}

enum SETTING_TYPE {UNKNOWN, ALL, AUDIO, VIDEO, CONTROLS, MISC, GAMEPLAY}

enum ANNOUNCER_MODE {OFF, MENU_ONLY, GAME_ONLY, FULL}

enum EFFECTS_QUALITY {MINIMUM, LOW, MEDIUM, HIGH, BEAUTIFUL}
enum SQUARES_QUALITY {MINIMUM, MEDIUM, HIGH}

const AUDIO_BUS_MINIMUM_DB : float = -29 # Minimum db value when bus is still on

var name : String = "guest"
var status : int = STATUS.OK
var is_guest_profile : bool = true # Guest profiles are quite limited, they cannot save data and participate in leaderboards

var has_changes_in_config : bool = false
var has_changes_in_progress : bool = false

var config : Dictionary = {
	"audio" : {
		"sound_volume" : -7.0,
		"music_volume" : -7.0,
		"audio_device" : 0, # Currently used audio device
		"spatial_sound" : true, # Makes game sounds playing from their sources positions in 2D space
		"stereo_enhance" : false, # Enables "stereo enhance" audio effect 
		"sequential_sounds" : true, # Play some sounds in specific order, or randomly
		"skin_preview" : true, # Enables skin preview when skin is selected
		"announcer" : ANNOUNCER_MODE.FULL, # Announcer mode (off, only game, only menu, and on)
	},
	"video" : {
		"resolution_x" : 1280,
		"resolution_y" : 720,
		"fullscreen" : false, # Press F1 to toggle
		"max_fps" : 120,
		"display_device" : 0, # Currently used screen display
		"fx_quality" : EFFECTS_QUALITY.MEDIUM, # Special effects quality
		"square_quality" : SQUARES_QUALITY.MEDIUM, # Square visuals quality
		"block_trail" : true, # Enables block and piece trail
		"block_animations" : true, # Enables blocks animations
		"classic_bonus_animation" : false, # Use bonus animation like in LPF
		"EQ_visual" : true, # Enables audio visualizer like in LPF
		"show_score_calc" : false, # Enables score calculation showcase
		"background_shaking" : true, # Enables background shaking (movement)
		"background_effects" : false, # Hides square blast effects behind playfield
		"force_standard_blocks" : false, # Forces standard blocks, regardless of current skin
		"disable_video" : false, # Disables skin video
		"disable_scenery" : false, # Disables skin scenery
	},
	"controls" : {
		# Keyboard controls
		"move_left" : "Left",
		"move_right" : "Right",
		"rotate_left" : "Z",
		"rotate_right" : "X",
		"quick_drop" : "Down",
		"side_ability" : "Shift",
		"ui_accept" : "Enter",
		"ui_cancel" : "Escape",
		"ui_extra" : "Space",
		# Gamepad controls
		"move_left_pad" : "joy_14", # DPAD LEFT
		"move_right_pad" : "joy_15", # DPAD RIGHT
		"rotate_left_pad" : "joy_1", # B
		"rotate_right_pad" : "joy_2", # X
		"quick_drop_pad" : "joy_13", # DPAD DOWN
		"side_ability_pad" : "joy_4", # L1
		"ui_accept_pad" : "joy_0", # A
		"ui_cancel_pad" : "joy_1", # B
		"ui_extra_pad" : "joy_5", # R1
	},
	"misc" : {
		"last_editor_dir" : OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP), # Last directory where skin editor file browser seeked for files
		"last_skins_dir" : "Skins/", # Last directory where skin editor file browser seeked for skins 
		"last_addons_dir" : "Addons/", # Last directory where addon editor file browser seeked for addons 

		"TA_time_limit" : 60,
		"TA_ruleset" : TimeAttackMode.TIME_ATTACK_RULESET.STANDARD,
		"TA_random_mixes" : true,

		"SY_visualizer" : SynthesiaMode.VISUALISER.SHOCKWAVE,
		"SY_soundset" : SynthesiaMode.SOUND_SET.DRUMS,
		"SY_endless_song" : false,
		"SY_precise_bpm" : false,

		"language" : "en", # Selected language (Avaiable : en, ja)
	},
	"gameplay" : {
		# Enabled block colors
		"red" : true,
		"white" : true,
		"green" : false,
		"purple" : false,

		"multi" : false, # Combines with any color
		"garbage" : false, # Erases only when adjacent block was erased too
		"joker" : false, # Changes color each timeline pass

		"chain" : true, # Chains all same colored adjacent blocks, making them erasable by timeline
		"merge" : true, # Turns all blocks in 5x5 grid into same color
		"laser" : false, # Erases all blocks on horizontal, vertical and diagonal sight
		"wipe" : false, # Erases all same colored blocks in 7x7 grid

		"instant_special" : false, # Enables special block activating immidiately on piece drop
		"piece_swaping" : true, # Enables piece queue shifting, which allow to swap current piece in hand with next in queue
		"save_holder_position" : true, # When piece is spawned, holder doesn't reset and stay in same position
		"give_score_for_square" : true, # Gives score when square is exploded
		"combo_system" : true, # Each 4x bonus fills combo meter, which multiplies all upcoming score
		"max_combo" : 32, # Max combo multiplyer
		"classic_scoring" : false, # Use classic scoring system which is much smaller in values

		"seed" : 0, # Randomization seed, randomizes piece queue
		"piece_fall_speed" : 1.0, # Piece fall speed in seconds
		"piece_fall_delay" : 1.0, # Piece fall delay in seconds
		"piece_dash_speed" : 1.0, # Piece dash speed multiplyer
		"piece_dash_delay" : 0.2, # Amount of time player needs to hold button, until piece does dash in seconds
		"block_gravity" : 1.0, # Individual block fall speed multiplyer
		"quick_drop_speed" : 1.0, # Piece quick drop speed multiplyer
		"difficulty_factor" : 1.0, # Fall speed increase multiplyer
		"level_up_speed" : 16, # Amount of squares required to delete for level up
		"level_count" : 4, # Amount of levels needed to progress to the next skin
		"force_bpm" : 0, # Forced skin BPM
		"special_block_delay" : 72, # Amount of pieces before new special block appears
	}
}

var progress : Dictionary = {
	"challenges" : {
		# "some_custom_challenge_name" : [hiscore, level progress]
		# ...
	},

	"time_attack_hiscore" : {
		"60sec_standard" : 0,
		"120sec_standard" : 0,
		"180sec_standard" : 0,
		"300sec_standard" : 0,
		"600sec_standard" : 0,

		"60sec_classic" : 0,
		"120sec_classic" : 0,
		"180sec_classic" : 0,
		"300sec_classic" : 0,
		"600sec_classic" : 0,

		"60sec_arcade" : 0,
		"120sec_arcade" : 0,
		"180sec_arcade" : 0,
		"300sec_arcade" : 0,
		"600sec_arcade" : 0,

		"60sec_3color" : 0,
		"120sec_3color" : 0,
		"180sec_3color" : 0,
		"300sec_3color" : 0,
		"600sec_3color" : 0,

		"60sec_hardcore" : 0,
		"120sec_hardcore" : 0,
		"180sec_hardcore" : 0,
		"300sec_hardcore" : 0,
		"600sec_hardcore" : 0,
	},
	
	"achievements":
	{
		"999999_score" : false,
		"120_in_60_sec" : false,
		"speedrun" : false,
	},
	
	"stats":
	{
		# Game general
		"total_time" : 0,
		"total_play_time" : 0,
		"total_score" : 0,
		"total_squares_erased" : 0,
		"total_blocks_erased" : 0,
		"total_special_blocks_used" : 0,
		"total_piece_swaps" : 0,
		"top_square_group_erased" : 0,
		"top_square_per_sweep" : 0,
		"top_combo" : 0,
		"top_score_gain" : 0,
		"top_time_spent_in_gameplay" : 0,
		"total_4x_bonuses" : 0,
		"total_single_color_bonuses" : 0,
		"total_all_clears" : 0,

		# Time attack mode
		"ta_total_retry_count" : 0,
		"ta_top_retry_count" : 0,
		"ta_total_time" : 0,
	
		# Editors data
		"total_skin_editor_time" : 0,
		"total_skin_load_times" : 0
	}
}


# Loads whole profile with its config and progress files
func _load_profile(profile_name : String) -> int:
	print("")
	print("LOADING PROFILE ", profile_name)
	name = profile_name
	status = STATUS.OK
	is_guest_profile = false

	_load_config()
	_load_progress()
	
	# Store this profile as last used in global variables file
	Data.global_settings["last_used_profile"] = profile_name
	Data._save_global_settings()

	profile_loaded.emit()
	print("PROFILE LOADED!")
	
	return OK


# Creates new blank profile with standard settings
func _create_profile(profile_name : String) -> int:
	print("")
	print("CREATING PROFILE WITH NAME ", profile_name)
	name = profile_name
	is_guest_profile = false

	var err : int = _save_progress()
	if err != OK:
		print("PROFILE CREATION FAILED!")
		return err

	err = _save_config()
	if err != OK:
		print("PROFILE CREATION FAILED!")
		return err
	
	# Store this profile as last used in global variables file
	Data.global_settings["last_used_profile"] = profile_name
	Data._save_global_settings()

	profile_loaded.emit()
	print("PROFILE CREATED!")

	return OK


func _delete_profile(profile_name : String) -> void:
	if FileAccess.file_exists(Data.PROFILES_PATH + profile_name + ".json"):
		print("DELETED CONFIG OF PROFILE : ", profile_name)
		DirAccess.remove_absolute(Data.PROFILES_PATH + profile_name + ".json")
	
	if FileAccess.file_exists(Data.PROFILES_PATH + profile_name + ".dat"):
		print("DELETED SAVE DATA OF PROFILE : ", profile_name)
		DirAccess.remove_absolute(Data.PROFILES_PATH + profile_name + ".dat")


# Loads progress file
func _load_progress() -> int:
	print("LOADING PROGRESS")
	
	if not FileAccess.file_exists(Data.PROFILES_PATH + name + ".dat"):
		print("ERROR! PROGRESS IS MISSING AT PATH : ", Data.PROFILES_PATH + name + ".dat")
		status = STATUS.PROGRESS_MISSING
		return STATUS.PROGRESS_MISSING
	
	# Yeah I know that I just left encrypted file key in open-source project code. But it's intended to prevent regular user from changing the file, not a hacker ;)
	var file : FileAccess = FileAccess.open_encrypted_with_pass(Data.PROFILES_PATH + name + ".dat", FileAccess.READ, "0451")
	if not file:
		file.close()
		print("PROGRESS FILE LOAD ERROR! : ", FileAccess.get_open_error())
		status = STATUS.PROGRESS_FAIL
		return STATUS.PROGRESS_FAIL
	
	var loaded_progress : Variant = file.get_var()
	if loaded_progress == null or loaded_progress is not Dictionary or not loaded_progress.has("time_attack_hiscore"): 
		file.close()
		print("PROGRESS FILE PARSE ERROR! INVALID FORMAT")
		status = STATUS.PROGRESS_FAIL
		return STATUS.PROGRESS_FAIL
	
	# Load entries from loaded progress, so it woudn't break if something is missing in loaded progress
	for category : String in progress.keys():
		if loaded_progress.has(category):
			for key : String in progress[category].keys():
				if loaded_progress[category].has(key):
					progress[category][key] = loaded_progress[category][key]

	file.close()
	
	progress_changed.emit()
	print("OK")

	return OK


# Saves progress to an encrypted .dat file
func _save_progress() -> int:
	if is_guest_profile : return ERR_DOES_NOT_EXIST

	print("SAVING PROGRESS")
	
	var file : FileAccess = FileAccess.open_encrypted_with_pass(Data.PROFILES_PATH + name + ".dat", FileAccess.WRITE, "0451")
	if not file:
		file.close()
		print("PROGRESS FILE SAVE ERROR! : ", FileAccess.get_open_error())
		return FileAccess.get_open_error()

	file.store_var(progress)
	file.close()

	has_changes_in_progress = false
	print("OK")

	return OK


# Loads config file and setup all settings
func _load_config() -> int:
	print("LOADING CONFIG")
	
	if not FileAccess.file_exists(Data.PROFILES_PATH + name + ".json"):
		print("ERROR! CONFIG IS MISSING AT PATH : ", Data.PROFILES_PATH + name + ".json")
		status = STATUS.CONFIG_MISSING
		return STATUS.CONFIG_MISSING
		
	var file : FileAccess = FileAccess.open(Data.PROFILES_PATH + name + ".json", FileAccess.READ)
	if not file:
		print("CONFIG FILE LOAD ERROR! : ", FileAccess.get_open_error())
		status = STATUS.CONFIG_FAIL
		return STATUS.CONFIG_FAIL
	
	var parse_result : Variant = JSON.parse_string(file.get_as_text())
	if parse_result == null:
		print("CONFIG FILE READ ERROR! UNKNOWN FORMAT")
		status = STATUS.CONFIG_FAIL
		return STATUS.CONFIG_FAIL

	# Load entries from loaded config, so it woudn't break if something is missing in loaded config
	for category : String in config.keys():
		if parse_result.has(category):
			for key : String in config[category].keys():
				if parse_result[category].has(key):
					config[category][key] = parse_result[category][key]
	
	file.close()
	
	_apply_setting("all")
	settings_changed.emit()
	print("OK")

	return OK


# Saves config to an .json file
func _save_config() -> int:
	if is_guest_profile : return ERR_DOES_NOT_EXIST
	settings_changed.emit()

	print("SAVING CONFIG")
	
	var file : FileAccess = FileAccess.open(Data.PROFILES_PATH + name + ".json", FileAccess.WRITE)
	if not file:
		file.close()
		print("CONFIG SAVE ERROR! : ", FileAccess.get_open_error())
		return FileAccess.get_open_error()
	
	file.store_string(JSON.stringify(config, "\t"))
	file.close() 
	
	has_changes_in_config = false
	print("OK")
	return OK


# Reset settings with specified SETTING_TYPE
func _reset_setting(setting_name : String = "all", setting_category : int = SETTING_TYPE.UNKNOWN, reset_config : Dictionary = Profile.new().config) -> void:	
	if setting_category == SETTING_TYPE.UNKNOWN:
		match setting_name:
			"all":
				_reset_setting("all_audio")
				_reset_setting("all_video")
				_reset_setting("all_controls")
				_reset_setting("all_misc")
			"all_audio":
				for setting : String in reset_config["audio"].keys():
					config["audio"][setting] = reset_config["audio"][setting]
				_apply_setting("all_audio")
			"all_video":
				for setting : String in reset_config["video"].keys():
					config["video"][setting] = reset_config["video"][setting]
				_apply_setting("all_video")
			"all_controls":
				for setting : String in reset_config["controls"].keys():
					config["controls"][setting] = reset_config["controls"][setting]
				_apply_setting("all_controls")
			"all_misc":
				for setting : String in reset_config["misc"].keys():
					config["misc"][setting] = reset_config["misc"][setting]
				_apply_setting("all_misc")
			"all_gameplay":
				for setting : String in reset_config["gameplay"].keys():
					config["gameplay"][setting] = reset_config["gameplay"][setting]
	
	elif setting_category == SETTING_TYPE.AUDIO or setting_name in reset_config["audio"].keys():
		config["audio"][setting_name] = reset_config["audio"][setting_name]
	elif setting_category == SETTING_TYPE.VIDEO or setting_name in reset_config["video"].keys():
		config["video"][setting_name] = reset_config["video"][setting_name]
	elif setting_category == SETTING_TYPE.CONTROLS or setting_name in reset_config["controls"].keys():
		config["controls"][setting_name] = reset_config["controls"][setting_name]
	elif setting_category == SETTING_TYPE.MISC or setting_name in reset_config["misc"].keys():
		config["misc"][setting_name] = reset_config["misc"][setting_name]
	elif setting_category == SETTING_TYPE.GAMEPLAY or setting_name in reset_config["gameplay"].keys():
		config["gameplay"][setting_name] = reset_config["gameplay"][setting_name]
	_apply_setting(setting_name)
	
	has_changes_in_config = true
	settings_changed.emit()


# Returns string which describes some config setting value. Used in options menus
func _return_setting_value_string(setting_name : String, value : Variant) -> String:
	var return_string : String = ""
	
	match setting_name:
		"music_volume" : return_string = str(round((value + 30) / 30 * 100)) + "%"
		"sound_volume" : return_string = str(round((value + 30) / 30 * 100)) + "%"
		
		"audio_device" : return_string = AudioServer.get_output_device_list()[value]
		"announcer" :
			match value:
				0.0: return_string = "OFF"
				1.0: return_string = "MENU_ONLY"
				2.0: return_string = "GAME_ONLY"
				3.0: return_string = "ON"
		
		"resolution":
			return_string = str(config["video"]["resolution_x"]) + "x" + str(config["video"]["resolution_y"])
		"max_fps": 
			return_string = str(value) + " FPS"
		"fx_quality":
			match value:
				0.0: return_string = "MINIMUM"
				1.0: return_string = "LOW"
				2.0: return_string = "MEDIUM"
				3.0: return_string = "MAX"
				4.0: return_string = "BEAUTY"
		"square_quality":
			match value:
				0.0: return_string = "MINIMUM"
				1.0: return_string = "MEDIUM"
				2.0: return_string = "MAX"
		"bonus_style" :
			match value:
				0.0: return_string = "STANDARD"
				1.0: return_string = "BIG ARROW"
				2.0: return_string = "CLASSIC"
		_ :
			return_string = str(value)
	
	return return_string


# Assigns some value to specified setting name in corresponing config sub-category
func _assign_setting(setting_name : String, value : Variant, setting_category : int = SETTING_TYPE.UNKNOWN) -> void:
	if setting_category == SETTING_TYPE.GAMEPLAY or setting_name in config["gameplay"].keys():
		config["gameplay"][setting_name] = value
	elif setting_category == SETTING_TYPE.AUDIO or setting_name in config["audio"].keys():
		config["audio"][setting_name] = value
	elif setting_name == "resolution":
		match value:
				0.0 : 
					config["video"]["resolution_x"] = 1280
					config["video"]["resolution_y"] = 720
				1.0 : 
					config["video"]["resolution_x"] = 1360
					config["video"]["resolution_y"] = 768
				2.0 : 
					config["video"]["resolution_x"] = 1440
					config["video"]["resolution_y"] = 900
				3.0 : 
					config["video"]["resolution_x"] = 1600
					config["video"]["resolution_y"] = 900
				4.0 : 
					config["video"]["resolution_x"] = 1680
					config["video"]["resolution_y"] = 1050
				5.0 : 
					config["video"]["resolution_x"] = 1920
					config["video"]["resolution_y"] = 1080
	elif setting_category == SETTING_TYPE.VIDEO or setting_name in config["video"].keys():
		config["video"][setting_name] = value
	elif setting_category == SETTING_TYPE.MISC or setting_name in config["misc"].keys():
		config["misc"][setting_name] = value
	
	has_changes_in_config = true
	setting_changed.emit(setting_name)


# Applies specified config setting
func _apply_setting(setting_name : String = "all") -> void:
	match setting_name:
		"all":
			_apply_setting("all_audio")
			_apply_setting("all_video")
			_apply_setting("all_controls")
			_apply_setting("all_misc")
		"all_audio":
			for i : String in ["music_volume","sound_volume","stereo_enhance"] : 
				_apply_setting(i)
		"all_video":
			for i : String in ["fullscreen","resolution","max_fps","EQ_visual"] : 
				_apply_setting(i)
		"all_controls":
			for i : String in ["rotate_right","rotate_left","move_right","move_left","quick_drop","side_ability","ui_accept","ui_cancel","ui_extra"] : 
				_update_input_config(i)
		"all_misc":
			for i : String in ["language"] : 
				_apply_setting(i)

		"music_volume":
			var value : float = config["audio"][setting_name]
			AudioServer.set_bus_volume_db(3,value)
			# Disable music bus if volume is too low
			if value <= AUDIO_BUS_MINIMUM_DB : 
				AudioServer.set_bus_volume_db(3,-100)
		"sound_volume":
			var value : float = config["audio"][setting_name]
			AudioServer.set_bus_volume_db(2,value)
			AudioServer.set_bus_volume_db(4,value)
			# Disable sound & announcer bus if volume is too low
			if value <= AUDIO_BUS_MINIMUM_DB : 
				AudioServer.set_bus_volume_db(2,-100)
				AudioServer.set_bus_volume_db(4,-100)
		"audio":
			var value : int = config["audio"][setting_name]
			AudioServer.output_device = AudioServer.get_output_device_list()[value]
		"stereo_enhance":
			var value : float = config["audio"][setting_name]
			AudioServer.set_bus_effect_enabled(0,2,value)
		"resolution":
			Data.get_window().size = Vector2(config["video"]["resolution_x"],config["video"]["resolution_y"])
		"max_fps":
			var value : int = config["video"][setting_name]
			Engine.max_fps = value
		"fullscreen":
			var value : bool = config["video"][setting_name]
			Data.get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (value) else Window.MODE_WINDOWED
			if not value : Data._center_window()
		"EQ_visual":
			var value : float = config["video"][setting_name]
			AudioServer.set_bus_effect_enabled(0,0,value) 
			
		"language":
			TranslationServer.set_locale(config["misc"]["language"])


# Updates InputMap in desired 'action', by removing current events and loading new ones from config
func _update_input_config(action : String, event : InputEvent = null, apply : bool = true) -> void:
	if event != null:
		if event is InputEventKey:
			Data.profile.config["controls"][action] = OS.get_keycode_string(event.keycode)
		elif event is InputEventJoypadButton:
			Data.profile.config["controls"][action + "_pad"] = "joy_" + str(event.button_index)

	if apply:
		InputMap.action_erase_events(action)
		
		var new_event : InputEvent = InputEventJoypadButton.new()
		new_event.button_index = int(config["controls"][action + "_pad"].substr(4))
		InputMap.action_add_event(action,new_event)
		
		new_event = InputEventKey.new()
		new_event.keycode = OS.find_keycode_from_string(config["controls"][action])
		InputMap.action_add_event(action,new_event)
