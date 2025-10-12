# Project Luminext - an advanced open-source Lumines spiritual successor
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
## Contains all base game parameters and rules and can be used in any gamemode
##-----------------------------------------------------------------------

class_name Ruleset


signal changed ## Emitted after ruleset is saved, copied or loaded and some values has been changed

## Contains all avaiable block types
var blocks : Dictionary = {
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
}

## Contains all gameplay rules
var rules : Dictionary = {
	"instant_special" : false, # Special blocks works instantly on land
	"piece_swaping" : true, # Allow player to swap current piece in hand with next in queue
	"save_holder_position" : true, # If false, piece holder will reset to the center of game field on each piece drop
	"give_score_for_square" : true, # Give score for each individual square group erase
	"combo_system" : true, # Count 4x bonuses and multiply all incoming score for gained combo
	"max_combo" : 32, # Max combo which multiply score
	"special_block_delay" : 72, # Pieces left before giving special block
	"classic_scoring" : false, # Use classic scoring system
}

## Contains all gameplay parameters
var params : Dictionary = {
	"seed" : 0, # Piece queue seed. If set to 0 its always random.
	"piece_fall_speed" : 0.75, # Seconds before piece automatically falls down one cell
	"piece_fall_delay" : 1.5, # Seconds before piece starts falling automatically
	"piece_dash_speed" : 1.0, # Dash speed factor
	"piece_dash_delay" : 0.2, # Seconds since move button hold, before dash starts working
	"block_gravity" : 1.0, # Block falling speed factor
	"quick_drop_speed" : 1.0, # Quick drop speed factor
	"difficulty_factor" : 1.0, # Piece auto fall speed increase factor
	"level_up_speed" : 24, # Squares before level up occurs
	"level_count" : 4, # Levels before loading next skin
	"force_bpm" : 0, # Forces specific timeline movement speed (usually leads to music desync)
}

var change_buffer : Dictionary = {} ## Stores original values of settings before any change


## Loads ruleset from .json formatted file
func _load(path : String) -> int:
	Console._log("Loading ruleset at path : " + path)
	
	if not FileAccess.file_exists(path):
		Console._log("ERROR! Ruleset doesn't exist in this path.")
		return ERR_DOES_NOT_EXIST
		
	var file : FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		Console._log("ERROR! Failed loading ruleset. Error code : " + error_string(FileAccess.get_open_error()))
		return ERR_CANT_OPEN
	
	var loaded_config : Variant = JSON.parse_string(file.get_as_text())
	if loaded_config == null:
		Console._log("ERROR! Failed parsing ruleset. Invalid format")
		return ERR_CANT_ACQUIRE_RESOURCE

	# compatability with old config
	if loaded_config.has("red"):
		for key : String in loaded_config : 
			if blocks.has(key) : blocks[key] = loaded_config[key]
			if rules.has(key) : rules[key] = loaded_config[key]
			if params.has(key) : params[key] = loaded_config[key]
	else:
		for key : String in blocks.keys() : if loaded_config["blocks"].has(key) : blocks[key] = loaded_config["blocks"][key]
		for key : String in rules.keys() : if loaded_config["rules"].has(key) : rules[key] = loaded_config["rules"][key]
		for key : String in params.keys() : if loaded_config["params"].has(key) : params[key] = loaded_config["params"][key]
	
	file.close()
	Console._log("Ruleset loaded successfully!")
	changed.emit()
	return OK


## Saves ruleset to .json formatted file
func _save(path : String) -> int:
	Console._log("Saving gamerules preset to path : " + path)

	var file : FileAccess = FileAccess.open(path, FileAccess.READ_WRITE)
	if not file:
		Console._log("ERROR! Failed saving gamerules. File open error : " + error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()
	
	var ruleset_dict : Dictionary = {
		"blocks" : {},
		"rules" : {},
		"params" : {},
	}
	for key : String in blocks.keys(): ruleset_dict["blocks"][key] = blocks[key]
	for key : String in rules.keys(): ruleset_dict["rules"][key] = rules[key]
	for key : String in params.keys(): ruleset_dict["params"][key] = params[key]

	file.store_string(JSON.stringify(ruleset_dict, "\t"))
	file.close() 

	if not change_buffer.is_empty():
		for key : String in change_buffer.keys() : _apply_setting(key)
		changed.emit()
		change_buffer.clear()
	
	Console._log("Gamerules preset saved successfully!")
	return OK


## Copies all data from another [Ruleset] object
func _copy(ruleset : Ruleset) -> void:
	blocks = ruleset.blocks.duplicate(true)
	rules = ruleset.rules.duplicate(true)
	params = ruleset.params.duplicate(true)

	changed.emit()


## Sets specified setting value
func _set_setting(setting_name : String, value : Variant) -> void:
	if setting_name in blocks.keys() : 
		if not change_buffer.has(setting_name) : change_buffer[setting_name] = blocks[setting_name]
		blocks[setting_name] = value
	elif setting_name in rules.keys() : 
		if not change_buffer.has(setting_name) : change_buffer[setting_name] = rules[setting_name]
		rules[setting_name] = value
	elif setting_name in params.keys() : 
		if not change_buffer.has(setting_name) : change_buffer[setting_name] = params[setting_name]
		params[setting_name] = value


## Resets specified config setting to previous value.[br]
## If **'to_default'** is true, sets setting to default value.[br]
## *'all', 'all_blocks', 'all_rules', and *'all_params'* can be passed to **'setting_name'** to reset all settings of specified category.
func _reset_setting(setting_name : String = "all", to_default : bool = false) -> void:	
	var reset_config : Dictionary = change_buffer
	match setting_name:
		"all":
			_reset_setting("all_blocks", to_default)
			_reset_setting("all_rules", to_default)
			_reset_setting("all_params", to_default)

		"all_blocks":
			if to_default : reset_config = Ruleset.new().blocks
			for setting : String in blocks.keys():
				if reset_config.has(setting) : 
					blocks[setting] = reset_config[setting]
					reset_config.erase(setting)

		"all_rules":
			if to_default : reset_config = Ruleset.new().rules
			for setting : String in blocks.keys():
				if reset_config.has(setting) : 
					rules[setting] = reset_config[setting]
					reset_config.erase(setting)

		"all_params":
			if to_default : reset_config = Ruleset.new().params
			for setting : String in blocks.keys():
				if reset_config.has(setting) : 
					params[setting] = reset_config[setting]
					reset_config.erase(setting)

		_:
			if setting_name in blocks.keys():
				if to_default : reset_config = Ruleset.new().blocks
				if reset_config.has(setting_name) : blocks[setting_name] = reset_config[setting_name]

			elif setting_name in rules.keys():
				if to_default : reset_config = Ruleset.new().rules
				if reset_config.has(setting_name) : rules[setting_name] = reset_config[setting_name]

			elif setting_name in params.keys():
				if to_default : reset_config = Ruleset.new().params
				if reset_config.has(setting_name) : params[setting_name] = reset_config[setting_name]


## Returns specified setting value
func _get_setting_value(setting_name : String) -> Variant:
	if setting_name in blocks.keys() : return blocks[setting_name]
	elif setting_name in rules.keys() : return rules[setting_name]
	elif setting_name in params.keys() : return params[setting_name]

	return null


## Returns string associated with specified setting value
func _get_setting_string(setting_name : String) -> String:
	var return_string : String = ""
	
	match setting_name:
		_ : return_string = str(_get_setting_value(setting_name))
	
	return return_string


## Applies specified setting, making it working
func _apply_setting(_setting_name : String = "all") -> void:
	return
