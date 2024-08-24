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

class_name GameConfigPreset

#-----------------------------------------------------------------------
# Gameplay config preset class
# 
# Used to store gameplay settings and load them all into profile
# Could be saved or loaded from .json file
# Also used in challenge mode to modify skin behaviours on the fly
#-----------------------------------------------------------------------


signal preset_applyed

var settings : Dictionary = {} 
var name : String = "" # Name of the preset


# Saves preset into '.json' file
func _save(save_name : String = name) -> int:
	if save_name.is_empty() : return ERR_INVALID_DATA
	
	name = save_name
	
	var json : String = JSON.stringify(settings, "\t")
	var file : FileAccess = FileAccess.open(Data.PRESETS_PATH + name + ".json", FileAccess.WRITE)
	if not file:
		file.close()
		print("PRESET SAVE ERROR! : ", FileAccess.get_open_error())
		return FileAccess.get_open_error()
	
	file.store_string(json)
	file.close()

	return OK


# Loads preset from '.json' file
func _load(path : String) -> int:
	if not path.ends_with(".json"): return ERR_INVALID_DATA
	var file : FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		file.close()
		return FileAccess.get_open_error()

	var buff : Dictionary = JSON.parse_string(file.get_as_text())
	for key : String in buff.keys():
		settings[key] = buff[key]

	file.close()
	return OK


# Loads all gameplay settings from current profile
func _store_current_config() -> void:
	var config : Dictionary = Data.profile.config
	var params_list : Array = config["gameplay"].keys()
	
	for param : String in params_list:
		settings[param] = config["gameplay"][param]


# Applies own gameplay settings into current profile
func _apply_preset() -> void:
	var config : Dictionary = Data.profile.config
	var params_list : Array = config["gameplay"].keys()
	for param : String in params_list:
		if settings.has(param):
			config["gameplay"][param] = settings[param]
	
	preset_applyed.emit()
