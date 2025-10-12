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
## Contains progress, statistic and other profile data which should be encrypted
##-----------------------------------------------------------------------

class_name Savedata


signal progress_changed ## Emitted when savedata was loaded
signal unlocked(unlockable_name : String) ## Emitted when something new has been unlocked
signal achievement_unlocked(achievement_name : String) ## Emitted when some achievement has been unlocked

## Contains progression results
var progress : Dictionary = {
	
}

## Contains currently unlocked content
var unlocks : Dictionary = {

}

## Unique profile indentifier
var user_id : String = "0451"

## Contains all awarded achievements
var achievements : Dictionary[String, bool] = {
	"999999_score" : false,
	"120_in_60_sec" : false,
	"speedrun" : false,
}

## Contains all profile statistics
var stats : Dictionary[String, int] = {
	# Game general
	"total_time" : 0,
	"total_play_time" : 0,
	"total_score" : 0,
	"total_squares_erased" : 0,
	"total_blocks_erased" : 0,
	"total_special_blocks_used" : 0,
	"total_piece_swaps" : 0,
	"total_4x_bonuses" : 0,
	"total_single_color_bonuses" : 0,
	"total_all_clears" : 0,
	"top_square_group_erased" : 0,
	"top_square_per_sweep" : 0,
	"top_combo" : 0,
	"top_score_gain" : 0,
	"top_time_spent_in_gameplay" : 0,
	"top_all_clears" : 0,
	"top_single_colors" : 0,

	# Time attack mode
	"ta_total_retry_count" : 0,
	"ta_top_retry_count" : 0,
	"ta_total_time" : 0,

	# Editors data
	"total_skin_editor_time" : 0,
	"total_skin_load_times" : 0
} 


func _ready() -> void:
	name = "Savedata"


## Loads savedata from path
func _load(path : String) -> int:
	Console._log("Loading savedata at path : " + path)
	
	if not FileAccess.file_exists(path):
		Console._log("ERROR! Savedata doesn't exist in this path.")
		return ERR_DOES_NOT_EXIST
	
	# Yeah I know that I just left encrypted file key in open-source project code. But it's intended to prevent regular user from changing the file, not a hacker ;)
	var file : FileAccess = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, "0451")
	if not file:
		Console._log("ERROR! Savedata loading failed. Error code : " + error_string(FileAccess.get_open_error()))
		return ERR_CANT_OPEN
	
	var loaded_data : Variant = file.get_var()
	if loaded_data == null or loaded_data is not Dictionary or not loaded_data.has("stats"): 
		Console._log("ERROR! Savedata parse failed. Invalid format")
		return ERR_CANT_ACQUIRE_RESOURCE
	
	# old format compatability
	if not loaded_data.has("top_all_clears"):
		user_id = loaded_data["misc"]["key"]
		
		for stat : String in loaded_data["stats"].keys():
			stats[stat] = int(loaded_data["stats"][stat])

	else:
		for key : String in stats.keys() : if loaded_data.has(key) : stats[key] = loaded_data[key]

		loaded_data = file.get_var()
		for key : String in progress.keys() : if loaded_data.has(key) : progress[key] = loaded_data[key]
		
		user_id = file.get_pascal_string()
		
		loaded_data = file.get_var()
		for key : String in achievements.keys() : if loaded_data.has(key) : achievements[key] = loaded_data[key]
	
	file.close()
	
	progress_changed.emit()
	Console._log("Savedata loaded successfully!")

	if user_id == "0451" : _generate_user_id(path)

	return OK


## Saves savedata to path
func _save(path : String) -> int:
	Console._log("Saving savedata to path : " + path)
	
	var file : FileAccess = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, "0451")
	if not file:
		Console._log("SAVEDATA SAVE ERROR : " + error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()

	if user_id == "0451" : _generate_user_id(path)

	file.store_var(stats)
	file.store_var(progress)
	file.store_pascal_string(user_id)
	file.store_var(achievements)
	file.close()

	Console._log("Savedata saved successfully!")

	return OK


## Generates unique user identifier
func _generate_user_id(path : String) -> void:
	user_id = str(hash(path) + randi_range(0, 2^24) + hash(OS.get_unique_id())).left(32)


## Sets top value in stats, if passed value is greater than current in stats
func _set_stats_top(stat_name : String, new_value : int) -> void:
	if not stats.has(stat_name): return
	if stats[stat_name] < new_value : 
		stats[stat_name] = new_value


## Sets some progress value
func _set_progress(parameter_name : String, value : Variant) -> void:
	progress[parameter_name] = value
	progress_changed.emit()


## Unlocks some unlockable
func _unlock(unlockable_name : String) -> void:
	if unlocks.has(unlockable_name) and not unlocks[unlockable_name]:
		unlocks[unlockable_name] = true
		unlocked.emit(unlockable_name)


## Unlocks achievement
func _unlock_achievement(achievement_name : String) -> void:
	achievements[achievement_name] = true
	achievement_unlocked.emit(achievement_name)
