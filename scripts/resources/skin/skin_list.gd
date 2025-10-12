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


extends Resource

##-----------------------------------------------------------------------
## Loads and caches all found skins metadata into dictionary.
##-----------------------------------------------------------------------

class_name SkinList

## Skins filenames which must be skipped when parsing all avaiable skins
const SKINS_TO_SKIP : Array[String] = ["blank.skn","synthesia.skn","colorblind.skn"]

## All possible skin list parse errors
enum SKIN_LIST_PARSE_ERROR {
	OK,
	IS_PARSING_NOW, ## Skin list is already parsing
	MISSING_DIRECTORY, ## Skins directory is missing
	THREADING_FAIL, ## Parse thread failed to init
}

signal parsed

var is_parsing : bool = false ## True if skin list parse is currently going
var has_unlocked_skins : bool = false ## True if some new skin was unlocked

## Parsed skins list. Each skin is within its own album, and sorted by skin album number
var skins : Dictionary = {
#	"skin_album" : {
#		skin_number : SkinMetadata()
#	}
} 

var files_amount : int = 0 ## Total amount of skin and addon files. Used to check if new skins were added
var parsed_skins_amount : int = 0 ## Total amount of successfully parsed skins
var skins_amount : int = 0 ## Actual amount of loaded skins

## List of all loaded skins id's and their respective links to [b]'skins'[/b] dictionary.[br]Used to easily get access to any loaded skin metadata.
var id_links : Dictionary = {
#	"skin_id" : ["skin_album", "skin_number"]
} 

## List of all loaded skins paths and their respective links to [b]'skins'[/b] dictionary.[br]Used to easily get access to any loaded skin metadata.
var path_links : Dictionary = {
#	"skin_path" : ["skin_album", "skin_number"]
} 

## List of unlock conditions and their respectively locked skins ID's
var locked_skins : Dictionary = {
#	"skin_id" : "lock_condition"
} 


## Runs a thread to parse skin list via '_parse()' function and returns parse error
func _parse_threaded() -> int:
	if is_parsing : return SKIN_LIST_PARSE_ERROR.IS_PARSING_NOW

	var thread : Thread = Thread.new()
	var err : int = thread.start(_parse)
	if err != OK : 
		parsed.emit()
		return SKIN_LIST_PARSE_ERROR.THREADING_FAIL
	
	await parsed
	var result : int = thread.wait_to_finish()
	return result


# Parses all skin files in Data.SKIN_PATH
func _parse() -> int:
	if is_parsing : return SKIN_LIST_PARSE_ERROR.IS_PARSING_NOW
	is_parsing = true
	
	Console._space.call_deferred()
	Console._log.call_deferred("Started skin list parsing...")

	var test_count : int = _count_skin_files_amount()
	if test_count == files_amount:
		Console._log.call_deferred("Skins amount hasn't changed! Parse stopped")
		call_deferred("emit_signal", "parsed")
		is_parsing = false
		return OK
	
	files_amount = test_count

	skins.clear()
	id_links.clear()
	path_links.clear()
	skins_amount = 0
	parsed_skins_amount = 0
	
	#print("LOOKING FOR ADDONS")
	#var addons : Array = Data._parse(Data.PARSE.ADDONS)
	#if addons.is_empty():
		#print("NO ADDONS FOUND")
	#else:
		#for addon_path : String in addons:
			#files_amount += 1
			#var addon : AddonPack = AddonPack.new()
			#print("PARSING ADDON ", addon_path)
			#
			#var err : int = addon._load(addon_path)
			#if err != OK: continue
			#
			#locked_skins.merge(addon.internal_data["locked_skins"], true)
			#for skin_name : String in addon.internal_data["skins"]:
				#var skin_metadata : SkinMetadata = addon.internal_data["skins"][skin_name][1]
				#_process_addon_skin(addon_path, skin_metadata)
				#_unlock_addon_skin(skin_metadata.name)
	
	Console._log.call_deferred("----------------------------------")
	Console._log.call_deferred("Parsing build-in skins directory")
	var dir : DirAccess = DirAccess.open(Data.BUILD_IN_PATH + Data.SKINS_PATH)
	if not dir:
		Console._log.call_deferred("ERROR! Failed to open build-in skins directory. Error code : " + error_string(DirAccess.get_open_error()))
	
	else:
		dir.list_dir_begin()
		var file_name : String = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".skn") and not file_name in SKINS_TO_SKIP: 
				_process_file_skin(Data.BUILD_IN_PATH + Data.SKINS_PATH + file_name)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()

	Console._log.call_deferred("----------------------------------")
	Console._log.call_deferred("Parsing user skins directory")
	dir = DirAccess.open(Data.SKINS_PATH)
	if not dir:
		Console._log.call_deferred("ERROR! Failed to open user skins directory. Error code : " + error_string(DirAccess.get_open_error()))
	
	else:
		dir.list_dir_begin()
		var file_name : String = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir(): 
				Console._log.call_deferred("Found sub-directory : " + file_name)
				var sub_dir : DirAccess = DirAccess.open(Data.SKINS_PATH + file_name + "/")
				if not sub_dir:
					Console._log.call_deferred("ERROR! Failed to open user skins sub-directory. Error code : " + error_string(DirAccess.get_open_error()))
					file_name = dir.get_next()
					continue
				
				sub_dir.list_dir_begin()
				var sub_file_name : String = sub_dir.get_next()
				
				while sub_file_name != "":
					if sub_file_name.ends_with(".skn"): 
						_process_file_skin(Data.SKINS_PATH + file_name + "/" + sub_file_name, file_name)
					sub_file_name = sub_dir.get_next()
				
				sub_dir.list_dir_end()
			
			elif file_name.ends_with(".skn"): 
				_process_file_skin(Data.SKINS_PATH + file_name)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()

	Console._log.call_deferred("Skin list parse finished!")
	is_parsing = false
	
	call_deferred("emit_signal", "parsed")
	return OK


# Tries to unlock all locked skins and returns Array of succesfully unlocked skin metadata hashes
# func _unlock_skins() -> Array:
# 	var unlocked_skins : Array = []

# 	for skin_metadata_hash : String in hash_links:
# 		if _unlock_addon_skin(skin_metadata_hash): 
# 			unlocked_skins.append(skin_metadata_hash)
			
# 	return unlocked_skins
		

# Checks lock condition of locked skin and unlocks it.
# Lock condition syntax:
# !challenge_name - Unlocked when found in challenge
# !challenge_name=level - Unlocked when reached some specific level in challenge
# %achievement_name - Unlocked when got an achievement
# func _unlock_addon_skin(skin_metadata_hash : StringName) -> int:
# 	if not locked_skins.has(skin_metadata_hash) : return ERR_UNAVAILABLE
# 	var lock_condition : String = locked_skins[skin_metadata_hash]

# 	match lock_condition[0]:
# 		# Challenge locked
# 		'!':
# 			var level_condition : int = lock_condition.find('=')
# 			var challenge_name : String
			
# 			# Unlock skin if some stage was reached in challenge
# 			if level_condition != -1:
# 				challenge_name = lock_condition.substr(1,level_condition)

# 				var unlock_number : int = int(lock_condition.right(level_condition + 1))
# 				var challenge_progress : int = UserData.savedata.hiscores["challenges"][challenge_name][1]
				
# 				if challenge_progress > unlock_number:
# 					locked_skins.erase(skin_metadata_hash)
# 					has_unlocked_skins = true
# 					return OK

# 		# Achievement locked
# 		'%':
# 			var achievement_condition : String = lock_condition.right(1)
			
# 			if UserData.savedata.achievements.get(achievement_condition, false):
# 				locked_skins.erase(skin_metadata_hash)
# 				has_unlocked_skins = true
# 				return OK
	
# 	return ERR_LOCKED


## Adds skin metadata from given file [b]'path'[/b] into skin list. File must be .skn formatted in order to be loaded.[br]
## If [b]'force_album'[/b] is specified, skin metadata would be assigned to that album inside skin list
func _process_file_skin(path : String, force_album : String = "") -> void:
	Console._log.call_deferred("Adding skin with path : " + path)
	
	var file : FileAccess = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if not file:
		Console._log.call_deferred("ERROR! Skin metadata loading error. Error code : " + error_string(FileAccess.get_open_error()))
		return
	
	var skn_version : int = file.get_8()
	
	if skn_version < 7:
		Console._log.call_deferred("ERROR! Deprecated skin version")
		file.close()
		return
	
	var skin_metadata : SkinMetadata = SkinMetadata.new()
	skin_metadata._load(file)
	
	var album : String = force_album if force_album != "" else skin_metadata.album
	if not skins.has(album) : skins[album] = {}
	skin_metadata.album = album
	
	var number : int = skin_metadata.number
	if number == -1 or skins[album].has(number): 
		if skins.has(album) : number = 9999 - skins[album].size()
		else: number = 9999
	skin_metadata.number = number

	skin_metadata.path = path
	
	var id : StringName = skin_metadata.id
	var metadata_hash : StringName = skin_metadata.metadata_hash
	# If there's already skin with same ID in skin list
	if id_links.has(id):
		Console._log.call_deferred("This skin ID is already used. Resolving")
		var stored_skin_metadata : SkinMetadata = skins[id_links[id][0]][id_links[id][1]]

		if stored_skin_metadata.save_date < skin_metadata.save_date:
			id_links[id] = [album, number]
			id_links[stored_skin_metadata.metadata_hash] = [stored_skin_metadata.album, stored_skin_metadata.number]
			Console._log.call_deferred("Found never version skin : " + skin_metadata.name + " (" + album + " | " + str(number) + ") [" + str(id) + "] {" + metadata_hash + "}")
			Console._log.call_deferred("Previously stored skin metadata is now : " + stored_skin_metadata.name + " (" + stored_skin_metadata.album + " | " + str(stored_skin_metadata.number) + ") [" + str(stored_skin_metadata.id) + "] {" + stored_skin_metadata.metadata_hash + "}")
		if stored_skin_metadata.save_date == skin_metadata.save_date:
			Console._log.call_deferred("Found duplicate skin. Ignoring.")
			skin_metadata.free()
			parsed_skins_amount += 1
			file.close()
			return
		else:
			id_links[metadata_hash] = [album, number]
			Console._log.call_deferred("Found older version skin : " + skin_metadata.name + " (" + album + " | " + str(number) + ") [" + str(id) + "] {" + metadata_hash + "}")
	else:
		id_links[id] = [album, number]
		Console._log.call_deferred("Skin parsed : " + skin_metadata.name + " (" + album + " | " + str(number) + ") [" + str(id) + "] {" + metadata_hash + "}")
	
	path_links[path] = [album, number]
	skins[album][number] = skin_metadata

	skins_amount += 1
	parsed_skins_amount += 1
	file.close()


# func _process_addon_skin(addon_path : String, skin_metadata : SkinMetadata) -> void:
# 	print("NEW ADDON SKIN DETECTED : ", skin_metadata.name)
	
# 	var skin_metadata_hash : StringName = StringName(skin_metadata._get_md5_hash_string())
# 	if hash_links.has(skin_metadata_hash):
# 		print("CONFLICTING SKIN HASH! THIS SKIN IS ALREADY LOADED")
# 		return

# 	skin_metadata.path = addon_path
# 	skin_metadata.metadata_hash = skin_metadata_hash
	
# 	var album : String = skin_metadata.album
# 	if not skins.has(album) : skins[album] = {}
	
# 	var number : int = skin_metadata.number
# 	if number == -1 or skins[album].has(number): 
# 		if skins.has(album) : number = 9999 - skins[album].size()
# 		else: number = 9999
	
# 	skins[album][number] = skin_metadata
# 	hash_links[skin_metadata_hash] = [album, number, skin_metadata.name]
# 	skins_amount += 1
	
# 	print("SKIN PARSED")


#func _parse_challenges() -> Array:
	#var challenges_array : Array = []
	#
	#var addons : Array = Data._parse(Data.PARSE.ADDONS)
	#if addons.is_empty(): 
		#return []
	#
	#for addon_path : String in addons:
		#var addon : AddonPack = AddonPack.new()
		#var err : int = addon._load(addon_path)
		#if err != OK: continue
	#
		#for challenge_name : String in addon.internal_data["challenges"]:
			#var challenge : ChallengeData = addon.internal_data["challenges"][challenge_name]
			#challenges_array.append(challenge)
		#
	#return challenges_array


## Returns [SkinMetadata] by provided skin **'album'** name and position in album **'number'**
func _get_skin_metadata_by_album(album : String, number : int) -> SkinMetadata:
	if is_parsing : return

	if not skins.has(album): return null
	if not skins[album].has(number): return null
	return skins[album][number]


## Returns [SkinMetadata] by provided skin **'id'** or hash
func _get_skin_metadata_by_id(id : StringName) -> SkinMetadata:
	if is_parsing : return

	if not id_links.has(id): return null
	var album : String = id_links[id][0]
	var number : int = id_links[id][1]
	return skins[album][number]


## Returns [SkinMetadata] by provided skin file **'path'**
func _get_skin_metadata_by_path(path : String) -> SkinMetadata:
	if is_parsing : return

	if not path_links.has(path): return null
	var album : String = path_links[path][0]
	var number : int = path_links[path][1]
	return skins[album][number]


## Get random skins array from skin list [br] 
## If **'amount'** = -1 it will return all avaiable skins in random order
func _get_random_skin_metadata(amount : int) -> Array[SkinMetadata]:
	if is_parsing : return []

	if amount == -1 or amount > skins_amount: amount = skins_amount
	if amount == 0: return []

	var randomized_skins_array : Array[SkinMetadata] = []
	var all_skins_ids_array : Array = id_links.keys()

	for i : int in amount:
		var rand : int = randi_range(0, all_skins_ids_array.size() - 1)
		randomized_skins_array.append(_get_skin_metadata_by_id(all_skins_ids_array[rand]))
		all_skins_ids_array.remove_at(rand)

	return randomized_skins_array


## Counts skin files and addon files amount. Used to determine if skin list needs an update.
func _count_skin_files_amount() -> int:
	Console._log.call_deferred("Counting total skin files amount")
	var count : int = 0

	for path : String in [Data.BUILD_IN_PATH + Data.SKINS_PATH, Data.SKINS_PATH]:
		var dir : DirAccess = DirAccess.open(path)
		if not dir : return count

		dir.list_dir_begin()
		var file_name : String = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".skn"): count += 1
			
			elif dir.current_is_dir(): 
				var sub_dir : DirAccess = DirAccess.open(path + file_name + "/")
				if not sub_dir :
					file_name = dir.get_next()
					continue
				
				sub_dir.list_dir_begin()
				var sub_file_name : String = sub_dir.get_next()
				
				while sub_file_name != "":
					if sub_file_name.ends_with(".skn"): count += 1
					sub_file_name = sub_dir.get_next()
				
				sub_dir.list_dir_end()
					
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	#count += Data._parse(Data.PARSE.ADDONS).size()
	
	Console._log.call_deferred("Real amount : " + str(count))
	Console._log.call_deferred("Currently loaded : " + str(files_amount))

	return count
