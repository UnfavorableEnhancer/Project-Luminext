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

const CONSOLE_ANIM_TIME : float = 0.4
const SCROLL_SPEED : float = 64

signal opened
signal closed

var is_opened : bool = false
var is_moving : bool = false

var binds : Dictionary = {} # All command binds {keycode : command string}

var command_buffer : PackedStringArray = PackedStringArray() # All previously entered commands buffer
var command_buffer_pos : int = 0 # Currently selected command in buffer 

@onready var log_node : RichTextLabel = $C/Log
@onready var log_scroll : VScrollBar = $C/Log.get_v_scroll_bar()


func _ready() -> void:
	_output("Welcome to the Project Luminext v" + Data.VERSION)
	_output("BUILD : " + Data.BUILD)
	_output("")


# Outputs text to console log and stores it in current log file
func _log(text_line : String, save_to_output : bool = false) -> void:
	log_node.text += "\n"
	log_node.text += text_line
	print(text_line)


# Outputs text to console log
func _output(text_line : String) -> void:
	log_node.text += "\n"
	log_node.text += text_line


func _input(event: InputEvent) -> void:
	if is_moving : return
	
	if event is InputEventKey and event.is_pressed():
		if not is_opened and binds.has(event.keycode):
			_command_input(binds[event.keycode])
		if is_opened:
			if event.keycode == KEY_UP and not event.shift_pressed:
				if command_buffer.size() < 1 : return
				if command_buffer_pos < command_buffer.size():
					command_buffer_pos += 1
				$C/LineEdit.text = command_buffer[command_buffer.size() - command_buffer_pos - 1]
			elif event.keycode == KEY_DOWN and not event.shift_pressed:
				if command_buffer.size() < 1 : return
				if command_buffer_pos > 0:
					command_buffer_pos -= 1
				$C/LineEdit.text = command_buffer[command_buffer.size() - command_buffer_pos - 1]
			elif event.keycode == KEY_UP and event.shift_pressed:
				log_scroll.value -= SCROLL_SPEED
			elif event.keycode == KEY_DOWN and event.shift_pressed:
				log_scroll.value += SCROLL_SPEED
	
	if event.is_action_pressed("console"):
		if not is_opened : _open()
		else: _close()


func _open() -> void:
	is_moving = true
	opened.emit()
	
	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property($C,"position:y",0.0,CONSOLE_ANIM_TIME).from(-760.0)
	tween.tween_property($C/Line,"scale:x",1.0,CONSOLE_ANIM_TIME).from(0.0)
	tween.tween_property($C/Line2,"scale:x",1.0,CONSOLE_ANIM_TIME).from(0.0)
	
	await tween.finished
	$C/LineEdit.grab_focus()
	is_opened = true
	is_moving = false

	_output("")
	_output("Enter 'help' to get list of all avaiable commands")


func _close() -> void:
	$C/LineEdit.release_focus()
	is_moving = true
	
	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property($C,"position:y",-760.0,CONSOLE_ANIM_TIME).from(0.0)
	tween.tween_property($C/Line,"scale:x",0.0,CONSOLE_ANIM_TIME).from(1.0)
	tween.tween_property($C/Line2,"scale:x",0.0,CONSOLE_ANIM_TIME).from(1.0)
	
	await tween.finished
	is_opened = false
	closed.emit()
	
	is_moving = false


func _command_input(text : String, silent : bool = false) -> void:
	if is_moving : return
	
	text = text.to_lower()
	var input : PackedStringArray = text.split(" ", false)
	if input.is_empty() : return
	
	var command : String = input[0]
	if not silent:
		_output(text)
		command_buffer.append(text)
	$C/LineEdit.text = ""
	
	match command:
		# General commands
		# Print list of all commands and how they work
		"help" : _help()
		# Prints an example of how command should be entered
		"ex" : 
			if input.size() < 2: _output("Error! Command is not entered"); return
			_example(input[1])
		# Binds command to a key
		"bind" :
			if input.size() < 2: _output("Error! Key is not entered"); return
			if input.size() < 3: _output("Error! Command is not entered"); return
			var key : String = input[1].to_upper()
			var command_to_bind : String = text.split(" ", false, 2)[2]
			_bind(key, command_to_bind)
		# Lists all currently existing command binds
		"bindlist" :
			if binds.is_empty():
				_output("Empty")
				return
			for bind_keycode : int in binds.keys():
				var key : String = OS.get_keycode_string(bind_keycode)
				_output(key + " : " + binds[bind_keycode])
		# Clears bind from key
		"unbind" :
			if input.size() < 2: _output("Error! Key is not entered"); return
			var key : String = input[1].to_upper()
			_unbind(key)
		# Clears log
		"clear" : log_node.text = ""
		# Resets the game completely
		"reset" : Data.main._reset()
		# Ends programm
		"exit" : Data.main._exit()
		
		# Profile/config commands
		# Switch to specified profile
		"profile" :
			if input.size() < 2: _output("Error! No profile name is entered"); return
			Data.profile._load_profile(input[1])
		# Lists all avaiable config parameters and their current values
		"cfglist" :
			for setting_category : String in Data.profile.config.keys():
				_output("")
				_output(setting_category.to_upper())
				_output("---------------------------------------------------")
				for setting_name : String in Data.profile.config[setting_category].keys():
					var value : Variant = Data.profile.config[setting_category][setting_name]
					var value_str : String = Data.profile._return_setting_value_string(setting_name, value)
					_output(setting_name + " : " + str(value) + " [" + value_str + "]")
		# Sets specified profile config parameter value
		"cfgset" :
			if input.size() < 2: _output("Error! No config setting name is entered"); return
			if input.size() < 3: _output("Error! No value is entered"); return
			var setting_name : String = input[1]
			var value : Variant = input[2]

			var setting_category : String = ""
			if setting_name in Data.profile.config["audio"] : setting_category = "audio"
			elif setting_name in Data.profile.config["video"] : setting_category = "video"
			elif setting_name in Data.profile.config["controls"] : setting_category = "controls"
			elif setting_name in Data.profile.config["misc"] : setting_category = "misc"
			elif setting_name in Data.profile.config["gameplay"] : setting_category = "gameplay"

			var real_value : Variant = Data.profile.config[setting_category][setting_name]
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

			Data.profile._assign_value_to_setting(setting_name,value)
			Data.profile._apply_setting(setting_name)
			Data.profile._apply_setting("all_gameplay")
		# Saves current profile config to file
		"cfgsave" :
			if input.size() > 1: Data.profile._save_config(input[1])
			else : Data.profile._save_config()
		# Loads profile config from file
		"cfgload" :
			if input.size() > 1: Data.profile._load_config(input[1])
			else : Data.profile._load_config()
		# Resets current profile config to standard values
		"cfgclr" :
			Data.profile._reset_setting()
			Data.profile._reset_setting("all_gameplay")
		# Lists all avaiable savedata (progress) parameters and their current values
		"savlist" :
			for progress_category : String in Data.profile.progress.keys():
				if progress_category == "misc" : continue
				_output("")
				_output(progress_category.to_upper())
				_output("---------------------------------------------------")
				for setting_name : String in Data.profile.progress[progress_category].keys():
					var value : Variant = Data.profile.progress[progress_category][setting_name]
					_output(setting_name + " : " + str(value))
		# Sets specified profile savedata parameter value
		"savset" :
			_output("WIP")
		# Saves current profile savedata to file
		"savsave" :
			if input.size() > 1: Data.profile._save_progress(input[1])
			else : Data.profile._save_progress()
		# Loads profile savedata from file
		"savload" :
			if input.size() > 1: Data.profile._load_progress(input[1])
			else : Data.profile._load_progress()
		# Clears current profile savedata removing all progress
		"savclr" :
			_output("WIP")
		
		# Menu commands
		# Toggles menu debug screen
		"mdebug" : $Debug._toggle(1)
		# Displays all avaiable menu screens/sounds/music
		"mlist" :
			if not is_instance_valid(Data.menu): _output("Error! Menu is not loaded"); return
			_output("")
			_output("Loaded menu screens")
			_output("---------------------------------------------------")
			for screen_name : String in Data.menu.loaded_screens_data.keys():
				var screen_path : String = Data.menu.loaded_screens_data[screen_name]
				_output(screen_name + " : " + screen_path)
			_output("")
			_output("Loaded menu music")
			_output("---------------------------------------------------")
			for music_name : String in Data.menu.loaded_music_data.keys():
				_output(music_name)
			_output("")
			_output("Loaded menu sound effects")
			_output("---------------------------------------------------")
			for sound_name : String in Data.menu.loaded_sounds_data.keys():
				_output(sound_name)
		# Displays all currently loaded screens
		"minfo" :
			if not is_instance_valid(Data.menu): _output("Error! Menu is not loaded"); return
			_output("")
			_output("Menu screens list")
			_output("---------------------------------------------------")
			for screen_name : String in Data.menu.screens.keys():
				_output(screen_name)
			_output("")
			_output("Custom menu data")
			_output("---------------------------------------------------")
			for key : String in Data.menu.custom_data.keys():
				var data : Variant = Data.menu.custom_data[key]
				_output(key + " : " + str(data))
		# Adds specified menu screen
		"madd" :
			if input.size() < 2: _output("Error! No menu screen name is entered"); return
			if not is_instance_valid(Data.menu): _output("Error! Menu is not loaded"); return
			if not input[1] in Data.menu.loaded_screens_data.keys(): 
				_output("Error! This menu screen doesn't exist in loaded menu screens list...")
				return
			Data.menu._add_screen(input[1])
		# Replaces current menu screen with specified one
		"msel" :
			if input.size() < 2: _output("Error! No menu screen name is entered"); return
			if not is_instance_valid(Data.menu): _output("Error! Menu is not loaded"); return
			if not input[1] in Data.menu.loaded_screens_data.keys(): 
				_output("Error! This menu screen doesn't exist in loaded menu screens list...")
				return
			Data.menu._change_screen(input[1])
		# Removes currently active menu screen
		"mrem" :
			if not is_instance_valid(Data.menu): _output("Error! Menu is not loaded"); return
			if not is_instance_valid(Data.menu.current_screen): _output("Error! Current menu screen is missing..."); return
			Data.menu.current_screen._remove()
		# Removes specified menu screen if it currently exists
		"mdel" :
			if input.size() < 2: _output("Error! No menu screen name is entered"); return
			if not is_instance_valid(Data.menu): _output("Error! Menu is not loaded"); return
			if not input[1] in Data.menu.screens.keys(): 
				_output("Error! This menu screen doesn't exist here...")
				return
			Data.menu._remove_screen(input[1])
		# Plays menu sound
		"msfx" :
			if input.size() < 2: _output("Error! No menu sound effect name is entered"); return
			if not is_instance_valid(Data.menu): _output("Error! Menu is not loaded"); return
			if not input[1] in Data.menu.loaded_sounds_data.keys(): 
				_output("Error! This menu sound effect doesn't exist in loaded sound effects list...")
				return
			Data.menu._sound(input[1])
		# Switches current menu music to specified one
		"mmus" :
			if input.size() < 2: _output("Error! No menu music name is entered"); return
			if not is_instance_valid(Data.menu): _output("Error! Menu is not loaded"); return
			if not input[1] in Data.menu.loaded_music_data.keys(): 
				_output("Error! This menu music doesn't exist in loaded music list...")
				return
			Data.menu._change_music(input[1])
		# Lists all selectables in current menu screen
		"msellist" :
			if not is_instance_valid(Data.menu): _output("Error! Menu is not loaded"); return
			if not is_instance_valid(Data.menu.current_screen): _output("Error! Current menu screen is missing..."); return
			for selectable_coords : Vector2i in Data.menu.current_screen.selectables.keys():
				var selectable : Control = Data.menu.current_screen.selectables[selectable_coords]
				_output(selectable.name + " : X = " + str(selectable_coords.x) + ", Y = " +  str(selectable_coords.y))
		# Moves menu cursor to specified position
		"cursor" :
			if input.size() < 2: _output("Error! X coordinate is not entered"); return
			if input.size() < 3: _output("Error! Y coordinate is not entered"); return
			if not is_instance_valid(Data.menu): _output("Error! Menu is not loaded"); return
			if not is_instance_valid(Data.menu.current_screen): _output("Error! Current menu screen is missing..."); return
			Data.menu.current_screen.cursor = Vector2i(int(input[1]), int(input[2]))
			Data.menu.current_screen._move_cursor()
		
		# Skin commands
		# Lists all loaded skins and their id's
		"sknlist" :
			for album : String in Data.skin_list.skins.keys():
				_output("")
				_output(album)
				_output("---------------------------------------------------")
				for skin_number : int in Data.skin_list.skins[album].keys():
					var skin_metadata : SkinMetadata = Data.skin_list.skins[album][skin_number]
					_output(str(skin_number) + " : " + skin_metadata.name + " (" + skin_metadata.path + ") [" + skin_metadata.id + "]")
		# Reloads skin list
		"sknlistreload" :
			Data.skin_list.was_parsed = false
			Data.skin_list._parse_threaded()
		# Prints current (or specified) skin metadata
		"skninfo" :
			var metadata : SkinMetadata
			if input.size() > 1:
				if input[1].is_relative_path():
					metadata = Data.skin_list._get_skin_metadata_by_file_path(input[1])
				else:
					metadata = Data.skin_list._get_skin_metadata_by_id(input[1])
			else:
				if not is_instance_valid(Data.game) or not is_instance_valid(Data.game.skin) : _output("Error! No skin is currently loaded"); return
				metadata = Data.game.skin.skin_data.metadata
			
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

		# Toggles skin debug screen
		"skndebug" : $Debug._toggle(3)
		# Pauses skin playback
		"sknstop" :
			if not is_instance_valid(Data.game) or not is_instance_valid(Data.game.skin) : _output("Error! Skin is not loaded"); return
			Data.game.skin._pause(true)
		# Continues skin playback
		"sknplay" :
			if not is_instance_valid(Data.game) or not is_instance_valid(Data.game.skin) : _output("Error! Skin is not loaded"); return
			Data.game.skin._pause(false)
		# Resets skin making it play from beginning
		"sknrst" :
			if not is_instance_valid(Data.game) or not is_instance_valid(Data.game.skin) : _output("Error! Skin is not loaded"); return
			Data.game.skin._reset()
		# Replaces current skin with specified one
		"sknload" :
			if input.size() < 2: _output("Error! Skin path or id is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if input[1].is_relative_path():
				Data.game._change_skin(input[1])
			else:
				var path : String = Data.skin_list._get_skin_metadata_by_id(input[1]).path
				Data.game._change_skin(path)
		# Set's current skin playback position to specified one
		"sknpos" : 
			_output("WIP")
		
		# Game commands
		# Prints current gamemode info
		"ginfo" : 
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			_output("Gamemode : " + Data.game.gamemode.gamemode_name)
			_output("WIP")
		# Toggles game debug screen
		"gdebug" : $Debug._toggle(2)
		# Lists all avaiable block types
		"blktypes" :
			_block_type_list()
		# Lists all blocks on the grid
		"blklist" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if Data.game.blocks.is_empty() : _output("Empty"); return

			for pos : Vector2i in Data.game.blocks:
				var block : Block = Data.game.blocks[pos]
				var color : String = ""
				match block.color:
					BlockBase.BLOCK_COLOR.RED : color = "Red"
					BlockBase.BLOCK_COLOR.WHITE : color = "White"
					BlockBase.BLOCK_COLOR.GREEN : color = "Green"
					BlockBase.BLOCK_COLOR.PURPLE : color = "Purple"
					BlockBase.BLOCK_COLOR.MULTI : color = "Multi"
					BlockBase.BLOCK_COLOR.GARBAGE : color = "Garbage"
					BlockBase.BLOCK_COLOR.DARK : color = "Dark"
					BlockBase.BLOCK_COLOR.SPECIAL : color = "Special"
					_ : color = "Unknown"
				var special : String = block.special
				_output("X = " + str(pos.x) + ",Y = " + str(pos.y) + " : " + color + " " + special)
		# Lists all squares on the grid
		"sqrlist" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if Data.game.squares.is_empty() : _output("Empty"); return
			
			for pos : Vector2i in Data.game.squares:
				var square : Square = Data.game.squares[pos]
				var blocks_array : String = ""
				for block : Block in square.squared_blocks:
					var color : String = ""
					match block.color:
						BlockBase.BLOCK_COLOR.RED : color = "Red"
						BlockBase.BLOCK_COLOR.WHITE : color = "White"
						BlockBase.BLOCK_COLOR.GREEN : color = "Green"
						BlockBase.BLOCK_COLOR.PURPLE : color = "Purple"
						BlockBase.BLOCK_COLOR.MULTI : color = "Multi"
						BlockBase.BLOCK_COLOR.GARBAGE : color = "Garbage"
						BlockBase.BLOCK_COLOR.DARK : color = "Dark"
						BlockBase.BLOCK_COLOR.SPECIAL : color = "Special"
						_ : color = "Unknown"
					var special : String = block.special
					blocks_array = blocks_array + color + " " + special + ", "
				_output("X = " + str(pos.x) + ",Y = " + str(pos.y) + " : " + blocks_array)
		# Lists all deletable blocks on the grid
		"dltlist" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if Data.game.delete.is_empty() : _output("Empty"); return

			for pos : Vector2i in Data.game.delete:
				var block : Block = Data.game.delete[pos]
				var color : String = ""
				match block.color:
					BlockBase.BLOCK_COLOR.RED : color = "Red"
					BlockBase.BLOCK_COLOR.WHITE : color = "White"
					BlockBase.BLOCK_COLOR.GREEN : color = "Green"
					BlockBase.BLOCK_COLOR.PURPLE : color = "Purple"
					BlockBase.BLOCK_COLOR.MULTI : color = "Multi"
					BlockBase.BLOCK_COLOR.GARBAGE : color = "Garbage"
					BlockBase.BLOCK_COLOR.DARK : color = "Dark"
					BlockBase.BLOCK_COLOR.SPECIAL : color = "Special"
					_ : color = "Unknown"
				var special : String = block.special
				_output("X = " + str(pos.x) + ",Y = " + str(pos.y) + " : " + color + " " + special)
		# Places specified block at specified position
		"plcblk" :
			if input.size() < 2: _output("Error! X coordinate is not entered"); return
			if input.size() < 3: _output("Error! Y coordinate is not entered"); return
			if input.size() < 4: _output("Error! Block type is not entered. Enter 'blktypes' to get list of all avaiable block types"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return

			var pos : Vector2i = Vector2i(int(input[1]), int(input[2]))
			var color : int = int(input[3].substr(0,2))
			if color > 5 : _output("Error! Invalid block type. Enter 'blktypes' to get list of all avaiable block types"); return

			var special : StringName = ""
			match int(input[3].substr(2)):
				1 : special = &"chain"
				2 : special = &"merge"
				3 : special = &"laser"
				4 : special = &"wipe"
				5 : special = &"joker"
				_: special = ""
			
			Data.game._add_block(pos, color, special)
		# Fills specified rectangle with blocks
		"rectblk" :
			if input.size() < 2: _output("Error! Rect origin X coordinate is not entered"); return
			if input.size() < 3: _output("Error! Rect origin Y coordinate is not entered"); return
			if input.size() < 4: _output("Error! Rect width is not entered"); return
			if input.size() < 5: _output("Error! Rect height is not entered"); return
			if input.size() < 6: _output("Error! Block type is not entered. Enter 'blktypes' to get list of all avaiable block types"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return

			var color : int = int(input[5].substr(0,2))
			if color > 5 : _output("Error! Invalid block type. Enter 'blktypes' to get list of all avaiable block types"); return

			var special : StringName = ""
			match int(input[5].substr(2)):
				1 : special = &"chain"
				2 : special = &"merge"
				3 : special = &"laser"
				4 : special = &"wipe"
				5 : special = &"joker"
				_: special = ""
			
			for x : int in int(input[3]):
				for y : int in int(input[4]):
					var pos : Vector2i = Vector2i(int(input[1]) + x, int(input[2]) + y)
					Data.game._add_block(pos, color, special)
		# Removes block from position
		"remblk" :
			if input.size() < 2: _output("Error! X coordinate is not entered"); return
			if input.size() < 3: _output("Error! Y coordinate is not entered"); return
			if input.size() < 4: _output("Error! Block type is not entered. Enter 'blktypes' to get list of all avaiable block types"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return

			var pos : Vector2i = Vector2i(int(input[1]), int(input[2]))
			if not Data.game.blocks.has(pos):
				_output("Error! Invalid position...")
				return
			Data.game.blocks[pos]._free()
		# Clears game field
		"fldclr" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			Data.game._clear_field()
		# Toggles paint mode, which allows to place blocks with your mouse!
		"paintmode" :
			_output("WIP")
		# Allows piece to pass thru blocks, but it still lands at field bottom
		"noclip" :
			_output("WIP")
		# Sets piece drop speed (overrides corresponding config parameter)
		"pspeed" :
			if input.size() < 2: _output("Error! Value is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			Data.game.piece_fall_speed = float(input[1])
		# Sets piece start delay (overrides corresponding config parameter)
		"pdelay" :
			if input.size() < 2: _output("Error! Value is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			Data.game.piece_fall_delay = float(input[1])
		# Deletes current timeline and spawns new one
		"tlreset" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			Data.game._create_timeline()
		# Stops current timeline
		"tlpause" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.timeline) : _output("Error! Timeline is not found"); return
			Data.game.timeline._pause(true)
		# Resumes current timeline
		"tlresume" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.timeline) : _output("Error! Timeline is not found"); return
			Data.game.timeline._pause(false)
		# Pauses timeline creation process
		"tlstop" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			Data.game.is_manual_timeline = !Data.game.is_manual_timeline
		# Changes current BPM (overrides corresponding config parameter)
		"setbpm" :
			if input.size() < 2: _output("Error! Value is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.skin) : _output("Error! Skin is not loaded"); return
			Data.game.skin.bpm = float(input[1])
		# Stops piece generation process
		"qstop" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			Data.game.is_adding_pieces_to_queue = false
		# Resumes piece generation process
		"qresume" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			Data.game.is_adding_pieces_to_queue = true
		# Resets piece queue removing all current pieces and making new ones
		"qreset" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			Data.game.piece_queue._reset()
		# Removes all pieces from the piece queue
		"qclear" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			Data.game.piece_queue._clear()
		# Appends specified piece to the piece queue
		"qappend" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if input.size() < 2: _output("Error! 1st block type is not entered. Enter 'blktypes' to get list of all avaiable block types"); return
			if input.size() < 3: _output("Error! 2nd block type is not entered. Enter 'blktypes' to get list of all avaiable block types"); return
			if input.size() < 4: _output("Error! 3rd block type is not entered. Enter 'blktypes' to get list of all avaiable block types"); return
			if input.size() < 5: _output("Error! 4th block type is not entered. Enter 'blktypes' to get list of all avaiable block types"); return
			
			var piece_data : PieceData = PieceData.new()
			var i : int = 1
			for block_pos : Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
				var color : int = int(input[i].substr(1,1))
				if color > 5 : _output("Error! Invalid block type. Enter 'blktypes' to get list of all avaiable block types"); return

				var special : StringName = ""
				match int(input[i].substr(0,1)):
					1 : special = &"chain"
					2 : special = &"merge"
					3 : special = &"laser"
					4 : special = &"wipe"
					5 : special = &"joker"
					_: special = ""

				piece_data.blocks[block_pos] = [color, special]
				i += 1
			Data.game.piece_queue._append_piece(piece_data)
		# Lists all avaiable special effects
		"fxlist" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.skin) : _output("Error! Skin is not loaded"); return
			for fx_name : String in Data.game.skin.skin_data.fx:
				_output(fx_name)
		# Spawns specified special effect at specified position
		"fxadd" :
			if input.size() < 2: _output("Error! X coordinate is not entered"); return
			if input.size() < 3: _output("Error! Y coordinate is not entered"); return
			if input.size() < 4: _output("Error! FX name is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.skin) : _output("Error! Skin is not loaded"); return

			var pos : Vector2 = Vector2(float(input[1]), float(input[2]))
			Data.game._add_fx(input[3], pos)
		# Lists all avaiable sound effects
		"sfxlist" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.skin) : _output("Error! Skin is not loaded"); return
			for sound_name : String in Data.game.skin.skin_data.sounds:
				if Data.game.skin.skin_data.sounds[sound_name] == null: 
					continue 
				if sound_name in ["bonus","square","special","timeline","blast"]:
					for i : int in Data.game.skin.skin_data.sounds[sound_name].size() - 1:
						_output(sound_name + str(i))
					continue
				_output(sound_name)
		# Spawns specified sound effect at specified position
		"sfxadd" :
			if input.size() < 2: _output("Error! X coordinate is not entered"); return
			if input.size() < 3: _output("Error! Y coordinate is not entered"); return
			if input.size() < 4: _output("Error! Sound name is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.skin) : _output("Error! Skin is not loaded"); return

			var pos : Vector2 = Vector2(float(input[1]), float(input[2]))
			var sound_name : String = input[3]
			var num : int = -1
			if sound_name.begins_with("bonus") : 
				num = int(sound_name.substr(5))
				sound_name = sound_name.left(5)
			elif sound_name.begins_with("square") :
				num = int(sound_name.substr(6))
				sound_name = sound_name.left(6)
			elif sound_name.begins_with("special") : 
				num = int(sound_name.substr(7))
				sound_name = sound_name.left(7)
			elif sound_name.begins_with("timeline") : 
				num = int(sound_name.substr(8))
				sound_name = sound_name.left(8)
			elif sound_name.begins_with("blast") : 
				num = int(sound_name.substr(5))
				sound_name = sound_name.left(5)

			if num == -1 : Data.game._add_sound(sound_name, pos, true, false)
			else : Data.game._add_sound(sound_name, pos, true, false, num)
		# Lists all avaiable UI designs
		"uilist" :
			_output("standard")
			_output("shinin")
			_output("square")
			_output("modern")
			_output("live")
			_output("pixel")
			_output("black")
			_output("comic")
			_output("clean")
			_output("vector")
			_output("techno")
		# Changes current UI design with specified one
		"uiset" : 
			if input.size() < 2: _output("Error! UI design name is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.skin) : _output("Error! Skin is not loaded"); return

			var ui_design : int = 0
			match input[1]:
				"standard" : ui_design = SkinData.UI_DESIGN.STANDARD
				"shinin" : ui_design = SkinData.UI_DESIGN.SHININ
				"square" : ui_design = SkinData.UI_DESIGN.SQUARE
				"modern" : ui_design = SkinData.UI_DESIGN.MODERN
				"live" : ui_design = SkinData.UI_DESIGN.LIVE
				"pixel" : ui_design = SkinData.UI_DESIGN.PIXEL
				"black" : ui_design = SkinData.UI_DESIGN.BLACK
				"comic" : ui_design = SkinData.UI_DESIGN.COMIC
				"clean" : ui_design = SkinData.UI_DESIGN.CLEAN
				"vector" : ui_design = SkinData.UI_DESIGN.VECTOR
				"techno" : ui_design = SkinData.UI_DESIGN.TECHNO
				_ : _output("Error! Invalid UI design name. Enter 'uilist' to get list of all avaiable UI designs"); return
			Data.game.foreground._change_style(ui_design, Data.game.skin.skin_data)
		# Changes specified UI element color
		"color" :
			if input.size() < 2: _output("Error! UI element name is not entered"); return
			if input.size() < 3: _output("Error! Red channel % value is not entered"); return
			if input.size() < 4: _output("Error! Green channel % value is not entered"); return
			if input.size() < 5: _output("Error! Blue channel % value is not entered"); return
			if input.size() < 6: _output("Error! Alpha channel % value is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.skin) : _output("Error! Skin is not loaded"); return
			var skin_data : SkinData = Data.game.skin.skin_data

			var color : Color = Color.WHITE
			color.r = color.r * (float(input[2]) / 100.0)
			color.g = color.g * (float(input[3]) / 100.0)
			color.b = color.b * (float(input[4]) / 100.0)
			color.a = color.a * (float(input[5]) / 100.0)

			match input[1]:
				"eq" : 
					skin_data.textures["eq_visualizer_color"] = color
					Data.game.foreground._change_style(skin_data.textures["ui_design"], skin_data)
				"ui" : 
					skin_data.textures["ui_color"] = color
					Data.game.foreground._change_style(skin_data.textures["ui_design"], skin_data)
				"timeline" : 
					skin_data.textures["timeline_color"] = color
					if is_instance_valid(Data.game.timeline):
						Data.game.timeline.get_node("Color").modulate = color
				_: _output("Error! Invalid UI element name. Try entering 'eq', 'ui', 'timeline' instead"); return
		# Triggers gameover
		"gover" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			Data.game._game_over()
		# Finishes the game and returns to main menu screen
		"back2menu" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			Data.game._end()
		
		# Playlist mode commands
		# Prints all skins in playlist
		"playlist" :
			_output("Playlist name : " + Data.playlist.name)
			_output("Playlist contents :")
			for skin_things : Array in Data.playlist.skins:
				_output(skin_things[0])
		# Loads next skin in playlist
		"nextskn" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.gamemode) : _output("Error! Gamemode is not loaded"); return
			if Data.game.gamemode is not PlaylistMode and Data.game.gamemode is not SynthesiaMode: _output("Error! Current gamemode is not playlist or synthesia mode"); return
			if Data.game.gamemode.is_single_skin_mode : _output("Error! Game is currently in single skin mode. No playlist avaiable")
			Data.game.gamemode._next_skin()
		# Loads skin from specified playlist position
		"selskn" :
			if input.size() < 2: _output("Error! Playlist position number is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.gamemode) : _output("Error! Gamemode is not loaded"); return
			if Data.game.gamemode is not PlaylistMode and Data.game.gamemode is not SynthesiaMode: _output("Error! Current gamemode is not playlist or synthesia mode"); return
			if Data.game.gamemode.is_single_skin_mode : _output("Error! Game is currently in single skin mode. No playlist avaiable")
			Data.game.gamemode.playlist_pos = int(input[1]) - 1
			Data.game.gamemode._next_skin()
		# Changes current playlist position
		"playpos" :
			if input.size() < 2: _output("Error! Playlist position number is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.gamemode) : _output("Error! Gamemode is not loaded"); return
			if Data.game.gamemode is not PlaylistMode and Data.game.gamemode is not SynthesiaMode: _output("Error! Current gamemode is not playlist or synthesia mode"); return
			if Data.game.gamemode.is_single_skin_mode : _output("Error! Game is currently in single skin mode. No playlist avaiable")
			Data.game.gamemode._set_playlist_position(int(input[1]))
		# Adds progress to the level bar
		"lvladd" :
			if input.size() < 2: _output("Error! Progress amount number is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.gamemode) : _output("Error! Gamemode is not loaded"); return
			if Data.game.gamemode is not PlaylistMode and Data.game.gamemode is not SynthesiaMode: _output("Error! Current gamemode is not playlist or synthesia mode"); return
			Data.game.gamemode._add_level_progress(int(input[1]))
		# Sets current level to specified one
		"lvlset" :
			if input.size() < 2: _output("Error! Level number is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.gamemode) : _output("Error! Gamemode is not loaded"); return
			if Data.game.gamemode is not PlaylistMode and Data.game.gamemode is not SynthesiaMode: _output("Error! Current gamemode is not playlist or synthesia mode"); return
			Data.game.gamemode._set_level(int(input[1]))
		# Triggers level up!
		"lvlup" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.gamemode) : _output("Error! Gamemode is not loaded"); return
			if Data.game.gamemode is not PlaylistMode and Data.game.gamemode is not SynthesiaMode: _output("Error! Current gamemode is not playlist or synthesia mode"); return
			Data.game.gamemode._level_up()
		# Adds score depending on entered square amount
		"sqradd" :
			if input.size() < 2: _output("Error! Square amount number is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.gamemode) : _output("Error! Gamemode is not loaded"); return
			if Data.game.gamemode is not PlaylistMode and Data.game.gamemode is not SynthesiaMode: _output("Error! Current gamemode is not playlist or synthesia mode"); return
			Data.game.gamemode._add_score_by_squares(int(input[1]))
		# Triggers specified bonus
		"bonus" :
			if input.size() < 2: _output("Error! Bonus type name is not entered"); return
			if input.size() < 3: _output("Error! Bonus value is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.gamemode) : _output("Error! Gamemode is not loaded"); return
			if Data.game.gamemode is not PlaylistMode and Data.game.gamemode is not SynthesiaMode: _output("Error! Current gamemode is not playlist or synthesia mode"); return
			match input[1]:
				"4x" : Data.game.gamemode._check_bonus(int(input[2]))
				"onecol" : Data.game.gamemode._check_for_special_bonus(int(input[2]))
				"allclr" : Data.game.gamemode._check_for_special_bonus(int(input[2]),true)
				_: _output("Error! Invalid bonus type name. Try entering '4x', 'onecol', 'allclr' instead"); return
		# Changes specified score value
		"scoreset" :
			if input.size() < 2: _output("Error! Score type name is not entered"); return
			if input.size() < 3: _output("Error! Score value is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.gamemode) : _output("Error! Gamemode is not loaded"); return
			if Data.game.gamemode is not PlaylistMode and Data.game.gamemode is not SynthesiaMode: _output("Error! Current gamemode is not playlist or synthesia mode"); return
			match input[1]:
				"time" : Data.game.gamemode.time = int(input[2])
				"score" : 
					Data.game.gamemode.score = int(input[2])
					Data.game.gamemode._increase_score_value(0,0)
				"delsqr" : 
					Data.game.gamemode.deleted_squares = int(input[2])
					Data.game.gamemode._increase_score_value(0,1)
				"delblk" : 
					Data.game.gamemode.deleted_blocks = int(input[2])
					Data.game.gamemode._increase_score_value(0,2)
				_: _output("Error! Invalid score type name"); return
		
		# Time attack mode commmands
		# Sets timer current time
		"tatime" :
			if input.size() < 2: _output("Error! Time value is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.gamemode) : _output("Error! Gamemode is not loaded"); return
			if Data.game.gamemode is not TimeAttackMode: _output("Error! Current gamemode is not time attack mode"); return
			Data.game.gamemode.time_attack_timer.time_left = float(input[1])
		# Sets current time attack attempt score
		"tascore" :
			if input.size() < 2: _output("Error! Score value is not entered"); return
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.gamemode) : _output("Error! Gamemode is not loaded"); return
			if Data.game.gamemode is not TimeAttackMode: _output("Error! Current gamemode is not time attack mode"); return
			Data.game.gamemode.score = int(input[1])
			Data.game.gamemode._increase_score_value(0)
		# Prints all collected current attempt statistics
		"tastats" :
			if not is_instance_valid(Data.game) : _output("Error! Game is not loaded"); return
			if not is_instance_valid(Data.game.gamemode) : _output("Error! Gamemode is not loaded"); return
			if Data.game.gamemode is not TimeAttackMode: _output("Error! Current gamemode is not time attack mode"); return
			_output("Total erased square count per timeline pass")
			_output("---------------------------------------------------")
			for i : int in Data.game.gamemode.statistics["square_cumulative"] : _output(str(i))
			_output("Square erased per timeline pass")
			_output("---------------------------------------------------")
			for i : int in Data.game.gamemode.statistics["square_per_sweep"] : _output(str(i))
			_output("Total used pieces count per timeline pass")
			_output("---------------------------------------------------")
			for i : int in Data.game.gamemode.statistics["pieces_used_count"] : _output(str(i))
			_output("All attempt scores")
			_output("---------------------------------------------------")
			for i : int in Data.game.gamemode.statistics["attempt_scores"] : _output(str(i))
		
		# Misc commands
		# Starts the skin debug with specified screen
		"skntest" :
			if is_instance_valid(Data.game) : _output("Error! Game is already loaded"); return
			if input.size() < 2: _output("Error! Skin path or id is not entered"); return

			var metadata : SkinMetadata
			if input[1].is_relative_path():
				metadata = Data.skin_list._get_skin_metadata_by_file_path(input[1])
			else:
				metadata = Data.skin_list._get_skin_metadata_by_id(input[1])
			Data.main._test_skin(metadata)
		# Starts specified replay
		"replay" :
			if is_instance_valid(Data.game) : _output("Error! Game is already loaded"); return
			if input.size() < 2: _output("Error! Replay path is not entered"); return

			var replay : Replay = Replay.new()
			replay._load(input[1])
			Data.main._start_replay(replay)
		
		_: _output("Unknown command...")


# Binds command to a key press
func _bind(key : String, command : String) -> void:
	if key.begins_with("N") and key.length() > 1: key = "KP_" + key.right(1)
	var keycode : int = OS.find_keycode_from_string(key)
	
	if keycode == KEY_NONE: _output("Bind error! Unknown keycode"); return
	if binds.has(keycode): _output("Bind warning! This key is already used and will be overwritten. Previously binded command : " + binds[keycode]); return
	
	binds[keycode] = command


func _unbind(key : String) -> void:
	if key.begins_with("N") and key.length() > 1: key = "KP_" + key.right(1)
	var keycode : int = OS.find_keycode_from_string(key)
	
	if keycode == KEY_NONE: _output("Unbind error! Unknown keycode"); return
	if not binds.has(keycode): _output("Unbind error! This key isn't used for any command bind"); return
	
	binds.erase(keycode)


func _block_type_list() -> void:
	_output("Block type is 4 digits number.")
	_output("First two digits define block color, last two digits define block special power")
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


# Prints example for given command
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
	_output("exit - Saves progress and ends this programm")
	_output("")
	_output("Profile commands")
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
	_output("setbpm - Changes current BPM (overrides corresponding config parameter)")
	_output("qstop - Stops piece generation process")
	_output("qresume - Resumes piece generation process")
	_output("qreset - Resets piece queue removing all current pieces and making new ones")
	_output("qclear - Removes all pieces from the piece queue")
	_output("qappend[1st blk type][2nd blk type][4rd blk type][4th blk type] - Appends specified piece to the piece queue (blocks are ordered from top left to bottom right)")
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
	_output("Playlist/Synthesia mode commands")
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
	_output("scoreset[time/score/delsqr/delblk][value] - Changes specified score value")
	_output("")
	_output("Time attack mode commands (Opening console invalidades time attack attempt)")
	_output("---------------------------------------------------")
	_output("tatime[seconds] - Sets timer current time")
	_output("tascore[value] - Sets current time attack attempt score")
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
