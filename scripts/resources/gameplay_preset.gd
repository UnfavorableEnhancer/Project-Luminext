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
