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
## Singletone containing all currently loaded profile audio/video/controls/etc. settings and savedata.
##-----------------------------------------------------------------------

class_name Profile

## Profile loading statuses
enum PROFILE_STATUS {
	OK, 
	PROGRESS_FAIL, ## Progress loading/saving failed
	PROGRESS_MISSING, ## Progress file is missing
	CONFIG_FAIL, ## Config file loading/saving failed
	CONFIG_MISSING, ## Config file is missing
	PROFILE_IS_MISSING, # Whole profile is missing
	GLOBAL_DATA_ERROR, ## Last profile name was lost
	NO_PROFILES_EXIST ## Profile directory is empty
}

signal profile_loaded ## Emitted when profile is loaded
signal profile_saved ## Emitted when profile is saved

var profile_name : String = "guest" ## Name of the loaded profile
var profile_status : int = PROFILE_STATUS.OK ## Profile loading status

var config : Config = Config.new() ## Profile config
var savedata : Savedata = Savedata.new() ## Profile savedata
var global : GlobalConfig = GlobalConfig.new() ## Global config


func _ready() -> void:
	name = "Player"
	add_child(config)
	add_child(savedata)
	add_child(global)


## Loads profile with specified filename.[br] 
## Config and savedata files with same filename must be inside [constant Data.PROFILES_PATH] to load profile.
func _load(filename : String) -> int:
	Console._space()
	Console._log("Loading profile : " + filename)

	profile_name = filename
	profile_status = PROFILE_STATUS.OK
	
	var err : int  = config._load(Data.PROFILES_PATH + filename + ".json")
	if err == ERR_DOES_NOT_EXIST : 
		profile_status = PROFILE_STATUS.CONFIG_MISSING
		Console._log("WARNING! This profile config is missing! Standard settings will be used.")
	elif err == ERR_CANT_OPEN :
		profile_status = PROFILE_STATUS.CONFIG_FAIL
		Console._log("WARNING! This profile config cannot be loaded! Standard settings will be used.")

	err = savedata._load(Data.PROFILES_PATH + filename + ".dat")
	if err == ERR_DOES_NOT_EXIST : 
		profile_status = PROFILE_STATUS.PROGRESS_MISSING
		Console._log("ERROR! This profile savedata is missing!")
	if err == ERR_CANT_OPEN : 
		profile_status = PROFILE_STATUS.PROGRESS_FAIL
		Console._log("ERROR! This profile savedata is cannot be loaded!")

	global.config["last_used_profile"] = profile_name

	profile_loaded.emit()
	Console._log("Profile load finished!")
	
	return profile_status


## Loads last used profile as saved in [b]'global'[/b]
func _load_latest() -> void:
	Console._space()
	Console._log("Loading latest used profile")

	if global.config["last_used_profile"].is_empty():
		if Data._parse(Data.PARSE.PROFILES).size() > 0:
			Console._log("ERROR! Failed loading global config. Latest used profile is unknown.")
			profile_status = PROFILE_STATUS.GLOBAL_DATA_ERROR
		else:
			Console._log("No profiles exist.")
			profile_status = PROFILE_STATUS.NO_PROFILES_EXIST
	else:
		_load(global.config["last_used_profile"])
	
	if profile_status == OK:
		Console._log("Successfully loaded latest used profile")


## Saves current profile to [constant Data.PROFILES_PATH]
func _save() -> int:
	Console._space()
	Console._log("Saving profile : " + profile_name)

	config._save(Data.PROFILES_PATH + profile_name + ".json")
	savedata._save(Data.PROFILES_PATH + profile_name + ".dat")

	profile_saved.emit()
	Console._log("Profile save finished!")
	
	return OK


## Creates new blank profile with standard config and empty savedata
func _create(new_profile_name : String) -> int:
	Console._space()
	Console._log("Creating profile : " + new_profile_name)
	profile_name = new_profile_name

	savedata._reset_setting("all", true)
	var err : int = savedata._save(Data.PROFILES_PATH + new_profile_name + ".dat")
	if err != OK:
		Console._log("ERROR! Failed to save fresh savedata.")
		return err

	config._reset_setting("all", true)
	err = config._save(Data.PROFILES_PATH + new_profile_name + ".json")
	if err != OK:
		Console._log("ERROR! Failed to save fresh config.")
		return err

	global.config["last_used_profile"] = new_profile_name

	profile_loaded.emit()
	Console._log("Profile creation finished!")

	return OK


## Deletes profile config and savedata completely
func _delete(delete_name : String) -> void:
	Console._space()
	Console._log("Deleting profile : " + delete_name)

	if FileAccess.file_exists(Data.PROFILES_PATH + delete_name + ".json"):
		if DirAccess.remove_absolute(Data.PROFILES_PATH + delete_name + ".json") == OK:
			Console._log("Config deleted.")
		else:
			Console._log("ERROR! Failed to delete config. Error code : " + error_string(DirAccess.get_open_error()))

	if FileAccess.file_exists(Data.PROFILES_PATH + delete_name + ".dat"):
		if DirAccess.remove_absolute(Data.PROFILES_PATH + delete_name + ".dat") == OK:
			Console._log("Savedata deleted.")
		else:
			Console._log("ERROR! Failed to delete savedata. Error code : " + error_string(DirAccess.get_open_error()))
