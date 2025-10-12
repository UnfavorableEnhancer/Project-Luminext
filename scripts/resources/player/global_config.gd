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
## Contains settings which should be shared between all profiles
##-----------------------------------------------------------------------

class_name GlobalConfig


## Global settings shared between all profiles
var config : Dictionary = {
	"last_used_profile" : "", ## Filename of the last used profile
	"first_boot" : true, ## True if the game was booted for the first ever time
	"console_binds" : { ## All console bindings
		"4194334" : "mdebug",
		"4194335" : "gdebug",
		"4194336" : "skndebug",
	}
}


func _ready() -> void:
	name = "GlobalConfig"


## Loads global config from Data.GLOBAL_DATA_PATH
func _load() -> int:
	Console._space()
	Console._log("Loading global config")
	
	var file : FileAccess = FileAccess.open(Data.GLOBAL_DATA_PATH, FileAccess.READ)
	if not file:
		Console._log("ERROR! Failed to load global config. Error code : " + error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()

	var parse_result : Variant = JSON.parse_string(file.get_as_text())
	if parse_result == null:
		Console._log("ERROR! Failed to parse global config.")
		return ERR_CANT_ACQUIRE_RESOURCE
	
	for key : String in config.keys():
		# compatability with old config (TODO)
		# if key.begins_with("60"):
		# 	for entry : Array in parse_result[key]:
		# 		var name = entry[0]
		# 		var score = entry[1]
		# 		var timestamp = entry[2]
		# 		#if key.contains("standard") : ranking_manager.local_ranking["60std"][] 

		if parse_result.has(key) : config[key] = parse_result[key]
	
	Console._log("Global config loaded successfully!")
	return OK


## Saves global config to Data.GLOBAL_DATA_PATH
func _save() -> int:
	Console._space()
	Console._log("Saving global config")
	
	var file : FileAccess = FileAccess.open(Data.GLOBAL_DATA_PATH, FileAccess.WRITE)
	if not file:
		Console._log("ERROR! Failed to save global config. Error code : " + error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()
	
	file.store_string(JSON.stringify(config, "\t"))
	file.close()
	
	Console._log("Global config saved successfully!")
	return OK

