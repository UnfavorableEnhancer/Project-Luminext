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

##-----------------------------------------------------------------------
## Contains all audio/video/control and etc. settings
##-----------------------------------------------------------------------

class_name Config


const AUDIO_BUS_MINIMUM_DB : float = -29 ## Minimum db value when bus is still on

## Avaiable announcer modes
enum ANNOUNCER_MODE {
	OFF, ## Announcer never talks
	MENU_ONLY, ## Announcer says only menu related samples
	GAME_ONLY, ## Announcer only announces next skin name
	FULL ## Announcer is active everywhere
}

enum EFFECTS_QUALITY {MINIMUM, LOW, MEDIUM, HIGH, BEAUTIFUL} ## Avaiable visual effects quality

## Avaiable piece assist levels
enum PIECE_ASSIST {
	NONE, ## Nothing assists piece placement
	RETICLE, ## Blue reticle shows current piece holder row
	SIMPLE, ## Block ghosts are displayed where piece is going to be landed
	COMPLEX ## Possible squares are shown where piece is going to be landed
}

## Avaiable block texture overrides
enum BLOCK_TEXTURE_OVERRIDE {
	NONE, ## Blocks use current skin data unique textures
	STANDARD, ## Blocks use only standard block textures
	COLORBLIND ## Blocks use only colorblind-friendly block textures
}

## Avaiable game field background options
enum FIELD_BACKGROUND {
	NONE, ## Nothing is put behind playfield
	SHADOW, ## Adds shadow to the game field
	DARKEN, ## Adds semi-transparent black background behind game field
	BLACK, ## Adds opacue black background behind game field
}

## Avaiable windowed resolutions
enum RESOLUTION {
	x1280x720, 
	x1360x768, 
	x1440x900, 
	x1600x900, 
	x1680x1050, 
	x1920x1080, 
	CUSTOM
}

signal changed ## Emitted after config is saved or loaded and some values has been changed

## Contains all audio related settings
var audio : Dictionary = {
	"sound_volume" : -7.0,
	"music_volume" : -7.0,
	"audio_device" : 0, # Currently used audio device (points to list of all detected audio devices)
	"spatial_sound" : true, # Makes game SFX playing from their sources positions in 2D space
	"sequential_sounds" : true, # Play some SFX (like blast SFX) in specific order
	"skin_preview" : true, # Enables skin preview when skin is selected in playlist mode menu
	"announcer" : ANNOUNCER_MODE.FULL, # Announcer mode (always off, only in game, only in menu, and always on)
}

## Contains all visuals related settings
var video : Dictionary = {
	"resolution_x" : 1280,
	"resolution_y" : 720,
	"fullscreen" : false, # Press F1 to toggle
	"max_fps" : 120, # FPS limit
	"fx_quality" : EFFECTS_QUALITY.MEDIUM, # Special effects quality
	"block_shadows" : true, # Enables shadow behind blocks
	"field_background" : FIELD_BACKGROUND.SHADOW, ## Adds background behind game field to improve readability
	"block_trail" : true, # Enables blocks trails
	"block_animations" : true, # Enables blocks animations
	"background_shaking" : true, # Enables background shaking (movement)
	"background_effects" : false, # Hides some special effects behind playfield
	"background_darkening" : false, # Makes skin background darker
	"blocks_replacement" : BLOCK_TEXTURE_OVERRIDE.NONE, # Forces standard or colorblind-friendly blocks in all skins
	"disable_video" : false, # Disables skin video
	"disable_scenery" : false, # Disables skin scenery
}

## Contains global game cores settings
var game : Dictionary = {
	## Luminext settings
	"luminext_piece_assist" : PIECE_ASSIST.RETICLE, # What piece placing assistance to use (none, reticle only, basic ghost, advanced ghost)
	"luminext_classic_bonus" : false, # Use bonus animation inspired by Lumines Puzzle Fusion bonus animation
	"luminext_eq_visual" : true, # Enables background audio visualizer like in Lumines Puzzle Fusion/Lumines Remastered
	"luminext_classic_sfx_system" : false, # Enables classic sfx system where absolutely every sound effect is tied to music beat
}

## Contains all control assigns
var control : Dictionary = {
	# Keyboard controls
	"move_left" : "Left", ## Moves piece in hand left
	"move_right" : "Right", ## Moves piece in hand right
	"rotate_left" : "Z", ## Rotates piece in hand left
	"rotate_right" : "X", ## Rotates piece in hand right
	"quick_drop" : "Down", ## Quickly drops down piece in hand
	"passive_ability" : "Shift", ## Actiavtes passive ability if possible
	"special_ability" : "Space", ## Activates special ability
	"quick_retry" : "R", ## Restarts the game quickly
	
	"ui_accept" : "Enter", ## UI accept action
	"ui_cancel" : "Escape", ## UI cancel action
	"ui_extra" : "Space", ## Extra UI action
	"ui_extra2" : "Shift", ## Second extra UI action

	"fps_counter" : "F1", ## Toggles FPS counter
	"screenshot" : "F2", ## Takes in-game screenshot
	"toggle_fullscreen" : "F11", ## Toogles fullscreen mode
	
	# Gamepad controls
	"move_left_pad" : "joy_14", # DPAD LEFT
	"move_right_pad" : "joy_15", # DPAD RIGHT
	"rotate_left_pad" : "joy_1", # B
	"rotate_right_pad" : "joy_2", # X
	"quick_drop_pad" : "joy_13", # DPAD DOWN
	"passive_ability_pad" : "joy_9", # L1
	"special_ability_pad" : "joy_10", # R1
	"quick_retry_pad" : "joy_4", # SELECT
	
	"ui_accept_pad" : "joy_0", # A
	"ui_cancel_pad" : "joy_1", # B
	"ui_extra_pad" : "joy_5", # R1
	"ui_extra2_pad" : "joy_9", # L1
}

## Contains all miscelenia settings
var misc : Dictionary = {
	"language" : "en", # Main game language
	"save_score_online" : true, # If false, disables saving records to online ranking

	"last_editor_dir" : OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP), # Last directory where skin editor file browser seeked for files
	"last_skins_dir" : "Skins/", # Last directory where skin editor file browser seeked for skins 
	"last_addons_dir" : "Addons/", # Last directory where addon editor file browser seeked for addons 
}

## Contains gamemode specific settings
var gamemode : Dictionary = {
	"ta_time_limit" : 60, # Selected time attack mode timelimit. Score ranking is avaiable only for 60, 120, 180, 300 and 600 secs
	"ta_ruleset" : TimeAttackMode.TIME_ATTACK_RULESET.STANDARD, ## Selected time attack mode ruleset (standard, classic, arcade, 3 color, hardcore)
	"ta_music_mix" : 0, # Selected time attack music mix (0 - random mix will be used) 
	"ta_skin" : "holding_patterns", # Selected time attack skin ID. Only 120 BPM skins can participate in online score ranking

	"sy_visualizer" : SynthesiaMode.VISUALISER.SHOCKWAVE, # Selected audio visualizer background scenery
	"sy_soundset" : SynthesiaMode.SOUND_SET.DRUMS, # Selected sound set
	"sy_endless_song" : false, # If true, plays selected sound endlessly
	"sy_precise_bpm" : false, # If true, calculates BPM by using full song length, not a 10 seconds part
}

var user_ruleset : Ruleset = Ruleset.new() ## Ruleset used for playlist/synthesia mode and which can be freely modified by player

var change_buffer : Dictionary = {} ## Stores original values of settings before any change


func _ready() -> void:
	name = "Config"


## Loads config from .json formatted file
func _load(path : String) -> int:
	Console._log("Loading config at path : " + path)
	
	if not FileAccess.file_exists(path):
		Console._log("ERROR! Config doesn't exist in this path.")
		return ERR_DOES_NOT_EXIST
		
	var file : FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		Console._log("ERROR! Failed to load profile config. Error code : " + error_string(FileAccess.get_open_error()))
		return ERR_CANT_OPEN
	
	var loaded_config : Variant = JSON.parse_string(file.get_as_text())
	if loaded_config == null or not loaded_config.has("audio"):
		Console._log("ERROR! Failed to parse profile config. Invalid format.")
		return ERR_CANT_OPEN

	for key : String in audio.keys() : if loaded_config["audio"].has(key) : audio[key] = loaded_config["audio"][key]
	for key : String in video.keys() : if loaded_config["video"].has(key) : video[key] = loaded_config["video"][key]
	for key : String in game.keys() : if loaded_config.has("game") : if loaded_config["game"].has(key) : game[key] = loaded_config["game"][key]
	for key : String in control.keys() : if loaded_config["controls"].has(key) : control[key] = loaded_config["controls"][key]
	for key : String in misc.keys() : if loaded_config["misc"].has(key) : misc[key] = loaded_config["misc"][key]
	for key : String in gamemode.keys() : if loaded_config["gamemode"].has(key) : gamemode[key] = loaded_config["gamemode"][key]

	# compatability with old config
	if loaded_config.has("gameplay"):
		for key : String in loaded_config["gameplay"] : 
			if user_ruleset.blocks.has(key) : user_ruleset.blocks[key] = loaded_config["gameplay"][key]
			if user_ruleset.rules.has(key) : user_ruleset.rules[key] = loaded_config["gameplay"][key]
			if user_ruleset.params.has(key) : user_ruleset.params[key] = loaded_config["gameplay"][key]
	else:
		for key : String in user_ruleset.blocks.keys() : 
			if loaded_config["user_ruleset"]["blocks"].has(key) : 
				user_ruleset.blocks[key] = loaded_config["user_ruleset"]["blocks"][key]
		for key : String in user_ruleset.rules.keys() : 
			if loaded_config["user_ruleset"]["rules"].has(key) : 
				user_ruleset.rules[key] = loaded_config["user_ruleset"]["rules"][key]
		for key : String in user_ruleset.params.keys() : 
			if loaded_config["user_ruleset"]["params"].has(key) : 
				user_ruleset.params[key] = loaded_config["user_ruleset"]["params"][key]

	file.close()
	
	_apply_setting("all")
	changed.emit()
	Console._log("Config loaded successfully!")

	return OK


## Saves config to .json formatted file
func _save(path : String) -> int:
	Console._log("Saving config to path : " + path)

	var ruleset_dict : Dictionary = {
		"blocks" : {},
		"rules" : {},
		"params" : {},
	}

	for key : String in user_ruleset.blocks.keys() : ruleset_dict["blocks"][key] = user_ruleset.blocks[key]
	for key : String in user_ruleset.rules.keys() : ruleset_dict["rules"][key] = user_ruleset.rules[key]
	for key : String in user_ruleset.params.keys() : ruleset_dict["params"][key] = user_ruleset.params[key]

	var json : Dictionary = {
		"audio" : audio,
		"video" : video,
		"game" : game,
		"controls" : control,
		"misc" : misc,
		"gamemode" : gamemode,
		"user_ruleset" : ruleset_dict
	}

	var file : FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		Console._log("ERROR! Failed to save profile config. Error code : " + error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()
	
	file.store_string(JSON.stringify(json, "\t"))
	file.close()

	if not change_buffer.is_empty():
		for key : String in change_buffer.keys() : _apply_setting(key)
		changed.emit()
		change_buffer.clear()
	
	Console._log("Config saved successfully!")
	return OK


## Sets specified setting value
func _set_setting(setting_name : String, value : Variant) -> void:
	if setting_name in audio.keys() : 
		if not change_buffer.has(setting_name) : change_buffer[setting_name] = audio[setting_name]
		audio[setting_name] = value
	
	elif setting_name == "resolution":
		if not change_buffer.has("resolution_x") : change_buffer["resolution_x"] = video["resolution_x"]
		if not change_buffer.has("resolution_y") : change_buffer["resolution_y"] = video["resolution_y"]
		
		match int(value):
			RESOLUTION.x1280x720 : 
				video["resolution_x"] = 1280
				video["resolution_y"] = 720
			RESOLUTION.x1360x768 : 
				video["resolution_x"] = 1360
				video["resolution_y"] = 768
			RESOLUTION.x1440x900 : 
				video["resolution_x"] = 1440
				video["resolution_y"] = 900
			RESOLUTION.x1600x900 : 
				video["resolution_x"] = 1600
				video["resolution_y"] = 900
			RESOLUTION.x1680x1050 : 
				video["resolution_x"] = 1680
				video["resolution_y"] = 1050
			RESOLUTION.x1920x1080 : 
				video["resolution_x"] = 1920
				video["resolution_y"] = 1080
	
	elif setting_name in video.keys() : 
		if not change_buffer.has(setting_name) : change_buffer[setting_name] = video[setting_name]
		video[setting_name] = value
	
	elif setting_name in game.keys() : 
		if not change_buffer.has(setting_name) : change_buffer[setting_name] = game[setting_name]
		game[setting_name] = value

	elif setting_name in misc.keys() : 
		if not change_buffer.has(setting_name) : change_buffer[setting_name] = misc[setting_name]
		misc[setting_name] = value

	elif setting_name in gamemode.keys() : 
		if not change_buffer.has(setting_name) : change_buffer[setting_name] = gamemode[setting_name]
		gamemode[setting_name] = value


## Resets specified config setting to previous value.[br]
## If **'to_default'** is true, sets setting to default value.[br]
## *'all', 'all_audio', 'all_video', 'all_controls', 'all_misc'* and *'all_gamemode'* can be passed to **'setting_name'** to reset all settings of specified category.
func _reset_setting(setting_name : String = "all", to_default : bool = false) -> void:
	var reset_config : Dictionary = change_buffer
	match setting_name:
		"all":
			_reset_setting("all_audio", to_default)
			_reset_setting("all_video", to_default)
			_reset_setting("all_game", to_default)
			_reset_setting("all_controls", to_default)
			_reset_setting("all_misc", to_default)
			_reset_setting("all_gamemode", to_default)

		"all_audio":
			if to_default : reset_config = Config.new().audio
			for setting : String in audio.keys():
				if reset_config.has(setting) : 
					audio[setting] = reset_config[setting]
					reset_config.erase(setting)

		"resolution":
			_reset_setting("resolution_x", to_default)
			_reset_setting("resolution_y", to_default)
			
		"all_video":
			if to_default : reset_config = Config.new().video
			for setting : String in video.keys():
				if reset_config.has(setting) : 
					video[setting] = reset_config[setting]
					reset_config.erase(setting)
		
		"all_game":
			if to_default : reset_config = Config.new().game
			for setting : String in game.keys():
				if reset_config.has(setting) : 
					game[setting] = reset_config[setting]
					reset_config.erase(setting)

		"all_controls":
			if to_default : reset_config = Config.new().control
			for setting : String in control.keys():
				if reset_config.has(setting) : 
					control[setting] = reset_config[setting]
					reset_config.erase(setting)

		"all_misc":
			if to_default : reset_config = Config.new().misc
			for setting : String in misc.keys():
				if reset_config.has(setting) : 
					misc[setting] = reset_config[setting]
					reset_config.erase(setting)

		"all_gamemode":
			if to_default : reset_config = Config.new().gamemode
			for setting : String in gamemode.keys():
				if reset_config.has(setting) : 
					gamemode[setting] = reset_config[setting]
					reset_config.erase(setting)

		_:
			if setting_name in audio.keys():
				if to_default : reset_config = Config.new().audio
				if reset_config.has(setting_name) : 
					audio[setting_name] = reset_config[setting_name]
					reset_config.erase(setting_name)

			elif setting_name in video.keys():
				if to_default : reset_config = Config.new().video
				if reset_config.has(setting_name) : 
					video[setting_name] = reset_config[setting_name]
					reset_config.erase(setting_name)
			
			elif setting_name in game.keys():
				if to_default : reset_config = Config.new().game
				if reset_config.has(setting_name) : 
					game[setting_name] = reset_config[setting_name]
					reset_config.erase(setting_name)

			elif setting_name in control.keys():
				if to_default : reset_config = Config.new().control
				if reset_config.has(setting_name) : 
					control[setting_name] = reset_config[setting_name]
					reset_config.erase(setting_name)

			elif setting_name in misc.keys():
				if to_default : reset_config = Config.new().misc
				if reset_config.has(setting_name) : 
					misc[setting_name] = reset_config[setting_name]
					reset_config.erase(setting_name)

			elif setting_name in gamemode.keys():
				if to_default : reset_config = Config.new().gamemode
				if reset_config.has(setting_name) : 
					gamemode[setting_name] = reset_config[setting_name]
					reset_config.erase(setting_name)


## Returns specified setting value
func _get_setting_value(setting_name : String) -> Variant:
	if setting_name in audio.keys() : return audio[setting_name]

	elif setting_name == "resolution":
		match int(video["resolution_x"]):
			1280 : return RESOLUTION.x1280x720
			1360 : return RESOLUTION.x1360x768
			1440 : return RESOLUTION.x1440x900
			1600 : return RESOLUTION.x1600x900
			1680 : return RESOLUTION.x1680x1050
			1920 : return RESOLUTION.x1920x1080
			_: return RESOLUTION.CUSTOM
	
	elif setting_name in video.keys() : return video[setting_name]
	elif setting_name in game.keys() : return game[setting_name]
	elif setting_name in misc.keys() : return misc[setting_name]
	elif setting_name in gamemode.keys() : return gamemode[setting_name]
	
	return null


## Returns string associated with specified setting value
func _get_setting_string(setting_name : String) -> String:
	var return_string : String = ""
	
	match setting_name:
		"music_volume" : return_string = str(round((audio["music_volume"] + 30) / 30 * 100)) + "%"
		"sound_volume" : return_string = str(round((audio["sound_volume"] + 30) / 30 * 100)) + "%"
		"audio_device" : return_string = AudioServer.get_output_device_list()[audio["audio_device"]]
		"announcer" :
			match int(audio["announcer"]):
				ANNOUNCER_MODE.OFF: return_string = tr("ANNOUNCER1")
				ANNOUNCER_MODE.MENU_ONLY: return_string = tr("ANNOUNCER2")
				ANNOUNCER_MODE.GAME_ONLY: return_string = tr("ANNOUNCER3")
				ANNOUNCER_MODE.FULL: return_string = tr("ANNOUNCER4")
		
		"resolution":
			return_string = str(video["resolution_x"]) + "x" + str(video["resolution_y"])
		"max_fps": 
			return_string = str(video["max_fps"]) + " FPS"
		"fx_quality":
			match int(video["fx_quality"]):
				EFFECTS_QUALITY.MINIMUM: return_string = tr("QUALITY_1")
				EFFECTS_QUALITY.LOW: return_string = tr("QUALITY_2")
				EFFECTS_QUALITY.MEDIUM: return_string = tr("QUALITY_3")
				EFFECTS_QUALITY.HIGH: return_string = tr("QUALITY_4")
				EFFECTS_QUALITY.BEAUTIFUL: return_string = tr("QUALITY_5")
		
		_ : return_string = str(_get_setting_value(setting_name))

	return return_string


## Applies specified setting, making it working[br]
## *'all', 'all_audio', 'all_video', 'all_controls'* and *'all_misc'* can be passed to **'setting_name'** to apply all settings of specified category.
func _apply_setting(setting_name : String = "all") -> void:
	match setting_name:
		"all":
			_apply_setting("all_audio")
			_apply_setting("all_video")
			_apply_setting("all_game")
			_apply_setting("all_controls")
			_apply_setting("all_misc")
		"all_audio":
			for i : String in ["music_volume","sound_volume","stereo_enhance"] : 
				_apply_setting(i)
		"all_video":
			for i : String in ["fullscreen","resolution","max_fps"] : 
				_apply_setting(i)
		"all_game":
			for i : String in ["luminext_eq_visual"] : 
				_apply_setting(i)
		"all_controls":
			for i : String in control.keys() : 
				_apply_input(i)
		"all_misc":
			for i : String in ["language"] : 
				_apply_setting(i)

		"music_volume":
			var volume : float = audio["music_volume"]
			AudioServer.set_bus_volume_db(3,volume)
			# Disable music bus if volume is too low
			if volume <= AUDIO_BUS_MINIMUM_DB : 
				AudioServer.set_bus_volume_db(3,-999)
		"sound_volume":
			var volume : float = audio["sound_volume"]
			AudioServer.set_bus_volume_db(2,volume)
			AudioServer.set_bus_volume_db(4,volume)
			# Disable sound & announcer bus if volume is too low
			if volume <= AUDIO_BUS_MINIMUM_DB : 
				AudioServer.set_bus_volume_db(2,-999)
				AudioServer.set_bus_volume_db(4,-999)
		"audio_device":
			var device_id : int = int(audio["audio_device"])
			AudioServer.output_device = AudioServer.get_output_device_list()[device_id]
		"resolution":
			get_window().size = Vector2(video["resolution_x"],video["resolution_y"])
			await get_tree().create_timer(0.1).timeout
			get_window().move_to_center()
		"max_fps":
			var fps_limit : int = int(video["max_fps"])
			Engine.max_fps = fps_limit
		"fullscreen":
			var fullscreen : bool = video["fullscreen"]
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (fullscreen) else Window.MODE_WINDOWED
			await get_tree().create_timer(0.1).timeout
			get_window().move_to_center()
		"eq_visual":
			var eq_enabled : bool = game[setting_name]
			AudioServer.set_bus_effect_enabled(0,0,eq_enabled) 
		"language":
			TranslationServer.set_locale(misc["language"])


## Sets [InputEvent] **'event'** for specified **'action'** name
func _set_input(action : String, event : InputEvent = null) -> void:
	if event == null : return

	if event is InputEventKey : control[action] = OS.get_keycode_string(event.keycode)
	elif event is InputEventJoypadButton : control[action + "_pad"] = "joy_" + str(event.button_index)


## Stores specified **'action'** events into [InputMap]
func _apply_input(action : String) -> void:
	if action.ends_with("_pad") : return
	InputMap.action_erase_events(action)
	
	var new_event : InputEvent = InputEventKey.new()
	new_event.keycode = OS.find_keycode_from_string(control[action])
	InputMap.action_add_event(action,new_event)
	
	# those actions are not avaiable for gamepad
	if action in ["fps_counter","screenshot","toggle_fullscreen"] : return
	
	new_event = InputEventJoypadButton.new()
	new_event.button_index = int(control[action + "_pad"].substr(4))
	InputMap.action_add_event(action,new_event)
