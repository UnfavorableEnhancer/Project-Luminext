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
## Handles event/error logging for this game
## Console can be opened during any point of the game to view current log and enter commands
## If in game mode, game will be automatically paused on console open
##-----------------------------------------------------------------------

const CONSOLE_SCENE : PackedScene = preload("res://scenery/debug/console.tscn") ## Console scene

const MAX_LOGS_SAVED : int = 5 ## How many logs must be saved on game exit
const CONSOLE_ANIM_TIME : float = 0.4 ## How fast console window slides down to cover screen
const SCROLL_SPEED : float = 64 ## How fast console lines are scrolled

signal opened ## Called when console opens
signal closed ## Called when console closes
signal command_entered(command : String, arguments : PackedStringArray) ## Called when console executes some command

var is_opened : bool = false ## True if console is currently opened
var is_moving : bool = false ## True if console window slide animation is still playing

var command_buffer : PackedStringArray = PackedStringArray() ## All previously entered commands buffer
var command_buffer_pos : int = 0 ## Currently selected command in buffer

var console_node : Control ## Main console node which holds eveyrthing
var input_node : LineEdit ## Node which displays console/log text
var log_node : RichTextLabel ## Node into which console commands are inputted
var log_scroll : VScrollBar ## Text display scroll bar node


func _ready() -> void:
	console_node = CONSOLE_SCENE.instantiate()
	add_child(console_node)

	log_node = get_node("Console/Log")
	input_node = get_node("Console/LineEdit")
	log_scroll = log_node.get_v_scroll_bar()


## Outputs text to the console log and stores it in the log file
func _log(text_line : String) -> void:
	log_node.text += "\n"
	log_node.text += str(Time.get_ticks_msec()) + " : " + text_line
	print(str(Time.get_ticks_msec()) + " : " + text_line)


## Stores empty line in the console log and in the log file
func _space() -> void:
	log_node.text += "\n"
	print("")


## Outputs text to the console log without saving to log
func _output(text_line : String) -> void:
	log_node.text += "\n"
	log_node.text += text_line


func _input(event: InputEvent) -> void:
	if is_moving : return
	
	if event is InputEventKey and event.is_pressed():
		# Enter binded command when console is closed
		var command_binds : Dictionary = Player.global.config["console_binds"]
		if not is_opened and command_binds.has(str(event.keycode)):
			_execute_command(command_binds[str(event.keycode)])
		
		if is_opened:
			# Select saved to buffer command
			if event.keycode == KEY_UP and not event.shift_pressed:
				_select_previous_command_from_buffer()
			elif event.keycode == KEY_DOWN and not event.shift_pressed:
				_select_next_command_from_buffer()
			
			# Scroll console log
			elif event.keycode == KEY_UP and event.shift_pressed:
				log_scroll.value -= SCROLL_SPEED
			elif event.keycode == KEY_DOWN and event.shift_pressed:
				log_scroll.value += SCROLL_SPEED
	
	if event.is_action_pressed("console"):
		if not is_opened : _open()
		else: _close()


## Opens the console
func _open() -> void:
	if is_moving : return
	is_moving = true
	opened.emit()
	
	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property(console_node,"position:y",0.0,CONSOLE_ANIM_TIME).from(-760.0)
	tween.tween_property(console_node.get_node("Line"),"scale:x",1.0,CONSOLE_ANIM_TIME).from(0.0)
	tween.tween_property(console_node.get_node("Line2"),"scale:x",1.0,CONSOLE_ANIM_TIME).from(0.0)
	
	await tween.finished
	input_node.grab_focus()
	is_opened = true
	is_moving = false

	_output("")
	_output("Press UP/DOWN keys to select between latest commands")
	_output("Hold 'Shift' and press UP/DOWN keys to scroll console log")
	_output("Enter 'help' to get list of all avaiable commands")


## Closes the console
func _close() -> void:
	if is_moving : return
	is_moving = true
	input_node.release_focus()

	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property(console_node,"position:y",-760.0,CONSOLE_ANIM_TIME).from(0.0)
	tween.tween_property(console_node.get_node("Line"),"scale:x",0.0,CONSOLE_ANIM_TIME).from(1.0)
	tween.tween_property(console_node.get_node("Line2"),"scale:x",0.0,CONSOLE_ANIM_TIME).from(1.0)
	
	await tween.finished
	is_opened = false
	closed.emit()
	
	is_moving = false


## Changes current console input to previous in buffer
func _select_previous_command_from_buffer() -> void:
	if command_buffer.size() < 1 : return
	if command_buffer_pos > 0 : command_buffer_pos -= 1
	input_node.text = command_buffer[command_buffer.size() - command_buffer_pos - 1]


## Changes current console input to next in buffer [br]
func _select_next_command_from_buffer() -> void:
	if command_buffer.size() < 1 : return
	if command_buffer_pos < command_buffer.size() : command_buffer_pos += 1
	input_node.text = command_buffer[command_buffer.size() - command_buffer_pos - 1]


# Binds command to a key press
func _bind(key : String, command : String) -> void:
	if key.begins_with("N") and key.length() > 1: key = "KP_" + key.right(1)
	var keycode : int = OS.find_keycode_from_string(key)
	
	if keycode == KEY_NONE: _output("Bind error! Unknown keycode"); return

	var command_binds : Dictionary[String, String] = Player.global.config["console_binds"]
	if command_binds.has(str(keycode)): _output("Bind warning! This key was already used and was overwritten. Previously binded command : " + command_binds[str(keycode)]); return
	
	command_binds[str(keycode)] = command


func _unbind(key : String) -> void:
	if key.begins_with("N") and key.length() > 1: key = "KP_" + key.right(1)
	var keycode : int = OS.find_keycode_from_string(key)
	
	if keycode == KEY_NONE: _output("Unbind error! Unknown keycode"); return

	var command_binds : Dictionary[String, String] = Player.global.config["console_binds"]
	if not command_binds.has(str(keycode)): _output("Unbind error! This key isn't used for any command bind"); return
	
	command_binds.erase(str(keycode))


## Copies logs from "user://logs" to Data.LOGS_PATH
func _copy_logs() -> void:
	Console._log("Saving logs")

	for log_file : String in DirAccess.get_files_at(Data.LOGS_PATH):
		DirAccess.remove_absolute(Data.LOGS_PATH + log_file)

	var count : int = 0
	for log_name : String in DirAccess.get_files_at("user://logs/"):
		var file : FileAccess = FileAccess.open("user://logs/" + log_name, FileAccess.READ)
		var log_text : String = file.get_as_text()
		file.close()

		file = FileAccess.open(Data.LOGS_PATH + log_name, FileAccess.WRITE)
		file.store_string(log_text)
		file.close()

		count += 1
		if count >= MAX_LOGS_SAVED : break

	Console._log("Logs saved")


func _execute_command(text : String, silent : bool = false) -> void:
	if is_moving : return
	
	text = text.to_lower()
	var input : PackedStringArray = text.split(" ", false)
	if input.is_empty() : return
	
	var command : String = input[0]
	var arguments : PackedStringArray = input.slice(1)

	if not silent:
		_output(text)
		command_buffer.append(text)
	input_node.text = ""
	
	match command:
		# General commands
		# =========================================================================
		# Print list of all commands and how they work
		"help" : _help()
		
		# Prints an example of how command should be entered
		"ex" : 
			if arguments.size() < 1: _output("Error! Command is not entered"); return
			_example(input[0])
		
		# Binds command to a key
		"bind" :
			if input.size() < 2: _output("Error! Key is not entered"); return
			if input.size() < 3: _output("Error! Command is not entered"); return
			var key : String = input[1].to_upper()
			var command_to_bind : String = text.split(" ", false, 2)[2]
			_bind(key, command_to_bind)
		
		# Lists all currently existing command binds
		"bindlist" :
			var command_binds : Dictionary[String, String] = Player.global.config["console_binds"]
			if command_binds.is_empty():
				_output("Empty")
				return
			for bind_keycode : String in command_binds.keys():
				var key : String = OS.get_keycode_string(int(bind_keycode))
				_output(key + " : " + command_binds[bind_keycode])
		
		# Clears bind from key
		"unbind" :
			if arguments.size() < 1: _output("Error! Key is not entered"); return
			var key : String = arguments[0].to_upper()
			_unbind(key)

		# Clears log
		"clear" : log_node.text = ""
		
		
		# Config/config commands
		# =========================================================================
		# Switch to specified profile
		"profile" :
			if arguments.size() < 1: _output("Error! No profile name is entered"); return
			Player._load_profile(arguments[0])

		# Lists all avaiable config parameters and their current values
		"cfglist" :
			_output("")
			_output("Audio settings")
			_output("---------------------------------------------------")
			for setting_name : String in Player.config.audio.keys():
				var value : Variant = Player.config.audio[setting_name]
				var value_str : String = Player._return_setting_value_string(setting_name, value)
				_output(setting_name + " : " + str(value) + " [" + value_str + "]")
			_output("")
			_output("Video settings")
			_output("---------------------------------------------------")
			for setting_name : String in Player.config.video.keys():
				var value : Variant = Player.config.video[setting_name]
				var value_str : String = Player._return_setting_value_string(setting_name, value)
				_output(setting_name + " : " + str(value) + " [" + value_str + "]")
			_output("")
			_output("Controls")
			_output("---------------------------------------------------")
			for setting_name : String in Player.config.control.keys():
				var value : Variant = Player.config.control[setting_name]
				var value_str : String = Player._return_setting_value_string(setting_name, value)
				_output(setting_name + " : " + str(value) + " [" + value_str + "]")
			_output("")
			_output("Misc. settings")
			_output("---------------------------------------------------")
			for setting_name : String in Player.config.misc.keys():
				var value : Variant = Player.config.misc[setting_name]
				var value_str : String = Player._return_setting_value_string(setting_name, value)
				_output(setting_name + " : " + str(value) + " [" + value_str + "]")
			_output("")
			_output("Gamemode settings")
			_output("---------------------------------------------------")
			for setting_name : String in Player.config.gamemode.keys():
				var value : Variant = Player.config.gamemode[setting_name]
				var value_str : String = Player._return_setting_value_string(setting_name, value)
				_output(setting_name + " : " + str(value) + " [" + value_str + "]")
			_output("")
			_output("Luminext user ruleset : Block types")
			_output("---------------------------------------------------")
			for setting_name : String in Player.user_gamerule.blocks.keys():
				var value : Variant = Player.user_gamerule.blocks[setting_name]
				var value_str : String = Player.user_gamerule._return_setting_value_string(setting_name, value)
				_output(setting_name + " : " + str(value) + " [" + value_str + "]")
			_output("")
			_output("Luminext user ruleset : Game rules")
			_output("---------------------------------------------------")
			for setting_name : String in Player.user_gamerule.rules.keys():
				var value : Variant = Player.user_gamerule.rules[setting_name]
				var value_str : String = Player.user_gamerule._return_setting_value_string(setting_name, value)
				_output(setting_name + " : " + str(value) + " [" + value_str + "]")
			_output("")
			_output("Luminext user ruleset : Game parameters")
			_output("---------------------------------------------------")
			for setting_name : String in Player.user_gamerule.params.keys():
				var value : Variant = Player.user_gamerule.params[setting_name]
				var value_str : String = Player.user_gamerule._return_setting_value_string(setting_name, value)
				_output(setting_name + " : " + str(value) + " [" + value_str + "]")
			
		# Sets specified profile config parameter value
		"cfgset" :
			if arguments.size() < 1: _output("Error! No config setting name is entered"); return
			if arguments.size() < 2: _output("Error! No value is entered"); return
			var setting_name : String = arguments[0]
			var value : Variant = arguments[1]

			var real_value : Variant = Player._get_config_value(setting_name)
			if real_value is bool:
				if value == "1" : value = true
				elif value == "1" : value = true
				elif value == "0" : value = true
				elif value == "true" : value = true
				else:
					_output("Entered value is invalid! Please enter 0, 1, false or true to change this setting properly");
					return
			elif real_value is int:
				value = value.to_int()
			elif real_value is float:
				value = value.to_float()
			else:
				value = str(value)

			Player._set_config_value(setting_name,value)
			Player.user_gamerule._set_config_value(setting_name,value)
			Player._apply_config_setting(setting_name)
			Player.user_gamerule._apply_config_setting(setting_name)
		
		# Saves current profile config to file
		"cfgsave" :
			if arguments.size() > 0: Player._save_config(arguments[0])
			else : Player._save_config()
		
		# Loads profile config from file
		"cfgload" :
			if arguments.size() > 0: Player._load_config(arguments[0])
			else : Player._load_config()
		
		# Resets current profile config to standard values
		"cfgclr" :
			Player._reset_setting("all", true)
			Player.user_gamerule._reset_setting("all", true)
		
		# Lists all avaiable savedata parameters and their current values
		"savlist" :
			_output("")
			_output("Progress")
			_output("---------------------------------------------------")
			for setting_name : String in Player.progress.keys():
				var value : Variant = Player.progress[setting_name]
				_output(setting_name + " : " + str(value))
			_output("")
			_output("Achievements")
			_output("---------------------------------------------------")
			for setting_name : String in Player.achievements.keys():
				var value : Variant = Player.achievements[setting_name]
				_output(setting_name + " : " + str(value))
			_output("")
			_output("Statistics")
			_output("---------------------------------------------------")
			for setting_name : String in Player.savedata.stats.keys():
				var value : Variant = Player.savedata.stats[setting_name]
				_output(setting_name + " : " + str(value))
		
		# Sets specified profile savedata parameter value
		"savset" :
			_output("WIP")
		
		# Saves current profile savedata to file
		"savsave" :
			if arguments.size() > 0: Player._save_savedata(arguments[0])
			else : Player._save_savedata()
		
		# Loads profile savedata from file
		"savload" :
			if arguments.size() > 0: Player._load_savedata(arguments[0])
			else : Player._load_savedata()
		
		# Clears current profile savedata removing all progress
		"savclr" :
			_output("WIP")
		
		# Skin commands
		# =========================================================================
		# Lists all loaded skins and their id's
		"sknlist" :
			for album : String in Data.skin_list.skins.keys():
				_output("")
				_output(album)
				_output("---------------------------------------------------")
				for skin_number : int in Data.skin_list.skins[album].keys():
					var skin_metadata : SkinMetadata = Data.skin_list.skins[album][skin_number]
					_output(skin_metadata.name + " (" + album + " | " + str(skin_number) + ") [" + str(skin_metadata.id) + "] {" + skin_metadata.metadata_hash + "}")
		
		# Reloads skin list
		"sknlistreload" :
			Data.skin_list._parse_threaded()
		
		# Prints specified skin metadata
		"skninfo" :
			var metadata : SkinMetadata
			if arguments.size() < 1 : return
			if arguments[0].is_relative_path():
				metadata = Data.skin_list._get_skin_by_path(arguments[0])
				if metadata == null: _output("Error! This skin doesn't exist"); return
			else:
				metadata = Data.skin_list._get_skin_by_id(arguments[0])
				if metadata == null: _output("Error! This skin doesn't exist"); return
			
			_output("Name : " + metadata.name)
			_output("Album : " + metadata.album)
			_output("Number in album : " + str(metadata.number))
			_output("Id : " + metadata.id)
			_output("Artist : " + metadata.artist)
			_output("Last edited by : " + metadata.skin_by)
			_output("Save date : " + Time.get_datetime_string_from_unix_time(int(metadata.save_date)).replace("T", " "))
			_output("BPM : " + str(metadata.bpm))
			_output("SKN format version : " + str(metadata.version))
			_output("Info : ")
			_output(metadata.info)
		
		# Misc commands
		# =========================================================================
		# Lists all avaiable block types
		"blktypes" :
			_block_type_list()
		
		_: 
			command_entered.emit(command, arguments)
		

## Outputs all avaiable block types codes
func _block_type_list() -> void:
	_output("Block type is 4 digits number.")
	_output("First two digits define block color (type), last two digits define block special power")
	_output("ex : 0101 - White chain block")
	_output("---------------------------------------------------")
	_output("AVAIABLE BLOCK COLORS :")
	_output("00 - Red")
	_output("01 - White")
	_output("02 - Green")
	_output("03 - Purple")
	_output("04 - Multi")
	_output("05 - Garbage")
	_output("---------------------------------------------------")
	_output("AVAIABLE BLOCK SPECIALS :")
	_output("00 - No special")
	_output("01 - Chain")
	_output("02 - Merge")
	_output("03 - Laser")
	_output("04 - Wipe")
	_output("05 - Chaos")


## Prints example for given command
func _example(command : String) -> void:
	match command:
		"ex" : _output("Example : ex plcblk")
		"bind" : 
			_output("Example : bind x cursor 1 2")
			_output("or : bind f3 lvlup (Binds 'lvlup' command to F3 key)")
			_output("or : bind n4 tlreset (Binds 'tlreset' command to numpad 4 key)")
		"unbind" : 
			_output("Example : unbind z")
			_output("or : unbind f5 (Removes command bind from F5 key)")
			_output("or : unbind n0 (Removes command bind from numpad 0 key)")
		"profile" : _output("Example : profile futuo")
		"cfgset" : _output("Example : cfgset sound_volume -3.0")
		"cfgsave" : _output("Example : cfgsave profiles/newconfig.json")
		"cfgload" : _output("Example : cfgload profiles/greatconfig.json")
		"prosave" : _output("Example : prosave profiles/newsave.dat")
		"proload" : _output("Example : proload profiles/coolsave.dat")
		"madd" : _output("Example : menuadd time_attack_mode")
		"msel" : _output("Example : menusel playlist_mode")
		"mdel" : _output("Example : menudel main_menu")
		"msfx" : _output("Example : menusfx select")
		"mmus" : _output("Example : menumus login1")
		"cursor" : _output("Example : cursor 2 5 (Will move cursor to position 2,5 if selectable button exists there)")
		"skninfo" : 
			_output("Example : skninfo content/skins/awesome_skin.skn")
			_output("or : skninfo 4780920")
		"sknload" : 
			_output("Example : sknload content/skins/awesome_skin.skn")
			_output("or : sknload 4780920")
		"sknpos" : _output("Example : sknpos 12.56")
		"plcblk" : _output("Example : plcblk 10 5 0 (Will create red block at 10,5 grid position)")
		"rectblk" : _output("Example : rectblk 5 2 4 3 1 (Will create 4x3 rectangle of white blocks at 5,5 grid position)")
		"pspeed" : _output("Example : pspeed 0.52")
		"pdelay" : _output("Example : pdelay 1.13")
		"pdash" : _output("Example : pdash 0.33")
		"qappend" : _output("Example : qappend 00 01 01 00 (Will append checkered red-white piece)")
		"lvladd" : _output("Example : lvladd 20")
		"lvlset" : _output("Example : lvlset 14")
		"bonus" : 
			_output("Example : bonus 4x 10")
			_output("or : bonus allclr 120")
		"fxadd" : _output("Example : fxadd 606 444.4 blast")
		"sfxadd" : _output("Example : sfxadd 1240 805.65 square1")
		"uiset" : _output("Example : uiset standard")
		"color" : 
			_output("Example : color timeline #FFC500FF")
			_output("or : color ui #AA00AA55")
		"scoreset" : 
			_output("Example : scoreset score 999999")
			_output("or : scoreset delsqr 1425")
		"skin" :
			_output("Example : skin content/skins/awesome_skin.skn")
			_output("or : skin 4780920")
		"replay" : _output("Example : replay export/replays/wow.rpl")
		_ : _output("Example : " + command)


# Displays help...
func _help() -> void:
	_output("General commands")
	_output("---------------------------------------------------")
	_output("help - Prints list of all commands and how they work")
	_output("ex[command] - Prints an example of how command should be entered")
	_output("bind[key][command][...] - Binds command to a key")
	_output("bindlist - Lists all currently existing command binds")
	_output("unbind[key] - Clears bind from key")
	_output("clear - Clears console log")
	_output("reset - Resets the game completely")
	_output("exit - Closes the game")
	_output("")
	_output("Config commands")
	_output("---------------------------------------------------")
	_output("profile[profile name] - Switch to the specified profile")
	_output("cfglist - Lists all avaiable config settings")
	_output("cfgset[config setting name][value] - Sets specified config setting value")
	_output("cfgsave(save path) - Saves current profile config to file (if path isn't entered it saves to standard path)")
	_output("cfgload(load path) - Loads profile config from file (if path isn't entered it saves to standard path)")
	_output("cfgclr - Resets current profile config to standard values")
	_output("savlist - Lists all avaiable savedata (progress) parameters and their current values")
	_output("savset - Sets specified profile savedata parameter value")
	_output("savsave(save path) - Saves current profile savedata to file (if path isn't entered it saves to standard path)")
	_output("savload(load path) - Loads profile savedata from file (if path isn't entered it saves to standard path)")
	_output("savclr - Clears current profile savedata removing all progress")
	_output("")
	_output("Menu commands")
	_output("---------------------------------------------------")
	_output("mdebug - Toggles menu debug screen")
	_output("mlist - Displays all avaiable menu screens/sounds/music")
	_output("minfo - Displays all currently loaded screens")
	_output("madd[menu screen name] - Adds specified menu screen")
	_output("msel[menu screen name] - Replaces current menu screen with specified one")
	_output("mrem - Removes currently active menu screen")
	_output("mdel[menu screen name] - Removes specified menu screen if it currently exists")
	_output("msfx[menu sound name] - Plays menu sound")
	_output("mmus[menu music name] - Switches current menu music to specified one (enter 'nothing' as music name to turn off menu music)")
	_output("cursor[x][y] - Moves menu cursor to specified position")
	_output("msellist - Lists all selectable by cursor objects in current menu screen")
	_output("")
	_output("Skin commands")
	_output("---------------------------------------------------")
	_output("sknlist - Lists all loaded skins and their id's")
	_output("sknlistreload - Reloads skin list")
	_output("skninfo(skin file path or id) - Prints current (or specified) skin metadata")
	_output("skndebug - Toggles skin debug screen")
	_output("sknstop - Pauses skin playback")
	_output("sknplay - Continues skin playback")
	_output("sknrst - Resets skin making it play from beginning")
	_output("sknload[skin file path or id] - Replaces current skin with specified one")
	_output("sknpos[seconds] - Set's current skin playback position to specified one")
	_output("")
	_output("Game commands")
	_output("---------------------------------------------------")
	_output("ginfo - Prints current gamemode info")
	_output("gdebug - Toggles game debug screen")
	_output("greset - Resets current game")
	_output("gsoft - Soft resets game (only clears game field and score)")
	_output("fxlist - Lists all avaiable special effects")
	_output("fxadd[x][y][fx name] - Spawns specified special effect at specified absolute position")
	_output("sfxlist - Lists all avaiable sound effects")
	_output("sfxadd[x][y][sound name] - Spawns specified sound effect at specified absolute position")
	_output("uilist - Lists all avaiable UI designs")
	_output("uiset[ui design name] - Changes current UI design with specified one")
	_output("color[ui/eq/timeline][Red %][Green %][Blue %][Alpha %] - Changes specified UI element color")
	_output("gover - Triggers gameover")
	_output("back2menu - Finishes the game and returns to main menu screen")
	_output("")
	_output("Luminext game commands")
	_output("---------------------------------------------------")
	_output("blktypes - Prints all avaiable block types")
	_output("blklist - Lists all blocks on the grid")
	_output("sqrlist - Lists all squares on the grid")
	_output("dltlist - Lists all soon to delete blocks on the grid")
	_output("plcblk[x][y][block type] - Places specified block at specified grid position, replaces already present block if its found on same position")
	_output("rectblk[x][y][width][height][block type] - Fills specified rectangle with blocks")
	_output("fldclr - Clears game field")
	_output("paintmode - Toggles paint mode, which allows to place blocks on grid with your mouse!")
	_output("noclip - Allows piece to pass thru blocks, but it still lands at field bottom")
	_output("pspeed[seconds] - Sets piece drop speed (overrides corresponding config parameter)")
	_output("pdelay[seconds] - Sets piece start delay (overrides corresponding config parameter)")
	_output("tlreset - Deletes current timeline and spawns new one")
	_output("tlpause - Stops current timeline")
	_output("tlresume - Resumes current timeline")
	_output("tlstop - Pauses timeline creation process")
	_output("tlcont - Resumes timeline creation process")
	_output("setbpm - Changes current BPM (overrides corresponding config parameter)")
	_output("qstop - Stops piece generation process")
	_output("qresume - Resumes piece generation process")
	_output("qreset - Resets piece queue removing all current pieces and making new ones")
	_output("qclear - Removes all pieces from the piece queue")
	_output("qappend[1st blk type][2nd blk type][4rd blk type][4th blk type] - Appends specified piece to the piece queue (blocks are ordered from top left to bottom right)")
	_output("")
	_output("Playlist mode commands")
	_output("---------------------------------------------------")
	_output("playlist - Prints all skins in playlist")
	_output("nextskn - Loads next skin in playlist")
	_output("selskn[number in playlist] - Loads skin from specified playlist position")
	_output("playpos[number] - Changes current playlist position")
	_output("lvladd[value] - Adds progress to the level bar")
	_output("lvlset[value] - Sets current level to specified one")
	_output("lvlup - Triggers level up!")
	_output("sqradd[squares amount] - Adds score depending on entered square amount")
	_output("bonus[4x/onecol/allclr][amount of blocks/squares] - Triggers specified bonus")
	_output("scoreadd[time/score/delsqr/delblk][value] - Adds value to specified score value")
	_output("scoreset[time/score/delsqr/delblk][value] - Changes specified score value")
	_output("")
	_output("Synthesia mode commands")
	_output("---------------------------------------------------")
	_output("lvladd[value] - Adds progress to the level bar")
	_output("lvlset[value] - Sets current level to specified one")
	_output("lvlup - Triggers level up!")
	_output("sqradd[squares amount] - Adds score depending on entered square amount")
	_output("bonus[4x/onecol/allclr][amount of blocks/squares] - Triggers specified bonus")
	_output("scoreadd[time/score/delsqr/delblk][value] - Adds value to specified score value")
	_output("scoreset[time/score/delsqr/delblk][value] - Changes specified score value")
	_output("")
	_output("Time attack mode commands")
	_output("Warning! Opening console or executing any command thru bind invalidades current attempt!")
	_output("---------------------------------------------------")
	_output("tatime[seconds] - Sets time attack timer current time")
	_output("tascore[value] - Sets current attempt score")
	_output("tastats - Prints all collected current attempt statistics")
	_output("")
	_output("Misc commands")
	_output("---------------------------------------------------")
	_output("skntest[skin file path or id] - Starts the skin player with specified skin")
	_output("replay[replay file path] - Starts specified replay")
	_output("")
	_output("---------------------------------------------------")
	_output("Command parameters in round/square brackets '()'/'[]' must be entered after pressing space")
	_output("Example: ex plcblk")
	_output("Command parameters in round brackets '()' are optional")
	_output("")
	_output("If slash symbol '/' is present inside bracket, that means that only listed between slashes values can be used")
	_output("Example: color timeline #FFC500FF")
	_output("")
	_output("You can scroll console log by pressing up and down arrow keys")
