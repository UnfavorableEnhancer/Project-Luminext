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

#-----------------------------------------------------------------------
# Skins list class
#
# Loads and caches all found skins metadata into single dictionary,
# which is structured like this:
# {
#	"album_name" : 
#	{
#		"skin_number" : SkinMetadata,
#		...
#	}
#	...
# }
#-----------------------------------------------------------------------


class_name SkinList

signal parsed

var was_parsed : bool = false
var currently_parsing : bool = false
var has_unlocked_skins : bool = false # True if some skin was just unlocked

# Parsed skins list. Each skin is within its own album, and sorted by skin album number
var skins : Dictionary = {
#	"skin_album" : {
#		skin_number : SkinMetadata()
#	}
} 

var files_amount : int = 0 # Total amount of skin files inside skin folder and all loaded addons
var skins_amount : int = 0 # Total amount of successfully parsed skin files

# List of all loaded skins MD5 hashes and their respective keys in 'skins' Dictionary. Used to easily get access to any loaded skin.
var hash_links : Dictionary = {
#	"skin_MD5_hash_StringName" : ["skin_album",skin_number,"skin_name"]
} 

# List of all loaded skins paths and their respective keys in 'skins' Dictionary. Used to easily get access to any loaded skin by playlists.
var path_links : Dictionary = {
#	"skin_path" : "skin_MD5_hash_StringName"
} 

# List of unlock conditions and their respectively locked skins names
var locked_skins : Dictionary = {
#	"skin_id" : "lock_condition"
} 

enum SKIN_LIST_PARSE_ERROR {
	MISSING_DIRECTORY,
	THREADING_FAIL,
	WAS_PARSED
}


# Checks if new parse is needed to update skin list
func _check_parse() -> bool:
	print("COUNTING SKINS")
	var test_count : int = _count_skin_files_amount()
	print("RESULT COUNT : ", test_count)
	print("CURRENT COUNT : ", files_amount)
	if test_count != files_amount:
		print("SKINS AMOUNT CHANGED RELOADING SKIN LIST")
		files_amount = test_count
		was_parsed = false
		return true
	return false


# Runs a thread to parse skin list via "_parse" function and returns parse error
func _parse_threaded() -> int:
	if was_parsed : 
		parsed.emit()
		return SKIN_LIST_PARSE_ERROR.WAS_PARSED
	
	var thread : Thread = Thread.new()
	var err : int = thread.start(Data.skin_list._parse)
	if err != OK : 
		parsed.emit()
		return SKIN_LIST_PARSE_ERROR.THREADING_FAIL
	
	await parsed
	var result : int = thread.wait_to_finish()

	print("THREAD RESULT : ", result)
	return OK


# Parses all skin files in Data.SKIN_PATH
func _parse() -> int:
	if was_parsed : 
		call_deferred("emit_signal", "parsed")
		return SKIN_LIST_PARSE_ERROR.WAS_PARSED
	
	currently_parsing = true
	skins.clear()
	hash_links.clear()
	path_links.clear()
	skins_amount = 0
	
	print()
	print("SKINS PARSING STARTED...")
	
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
	
	print("LOOKING INTO INTERNAL SKIN DIR")
	var dir : DirAccess = DirAccess.open(Data.BUILD_IN_PATH + Data.SKINS_PATH)
	if not dir:
		print("SKIN DIRECTORY LOADING ERROR! ", DirAccess.get_open_error())
	
	else:
		dir.list_dir_begin()
		var file_name : String = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".skn"):
				# Skip some internal skins here
				if file_name in ["blank.skn", "synthesia.skn"]: 
					file_name = dir.get_next()
					continue
				_process_file_skin(Data.BUILD_IN_PATH + Data.SKINS_PATH + file_name)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()

	print("LOOKING INTO SKIN DIR")
	dir = DirAccess.open(Data.SKINS_PATH)
	if not dir:
		print("SKIN DIRECTORY LOADING ERROR! ", DirAccess.get_open_error())
	
	else:
		dir.list_dir_begin()
		var file_name : String = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir(): 
				var sub_dir : DirAccess = DirAccess.open(Data.SKINS_PATH + file_name + "/")
				if sub_dir:
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

	print("FINISHED!")
	was_parsed = true
	currently_parsing = false
	
	call_deferred("emit_signal", "parsed")
	return OK


# Tries to unlock all locked skins and returns Array of succesfully unlocked skin metadata hashes
func _unlock_skins() -> Array:
	var unlocked_skins : Array = []

	for skin_metadata_hash : String in hash_links:
		if _unlock_addon_skin(skin_metadata_hash): 
			unlocked_skins.append(skin_metadata_hash)
			
	return unlocked_skins
		

# Checks lock condition of locked skin and unlocks it.
# Lock condition syntax:
# !challenge_name - Unlocked when found in challenge
# !challenge_name=level - Unlocked when reached some specific level in challenge
# %achievement_name - Unlocked when got an achievement
func _unlock_addon_skin(skin_metadata_hash : StringName) -> int:
	if not locked_skins.has(skin_metadata_hash) : return ERR_UNAVAILABLE
	var lock_condition : String = locked_skins[skin_metadata_hash]

	match lock_condition[0]:
		# Challenge locked
		'!':
			var level_condition : int = lock_condition.find('=')
			var challenge_name : String
			
			# Unlock skin if some stage was reached in challenge
			if level_condition != -1:
				challenge_name = lock_condition.substr(1,level_condition)

				var unlock_number : int = int(lock_condition.right(level_condition + 1))
				var challenge_progress : int = Data.profile.progress["challenges_hiscores"][challenge_name][1]
				
				if challenge_progress > unlock_number:
					locked_skins.erase(skin_metadata_hash)
					has_unlocked_skins = true
					return OK

		# Achievement locked
		'%':
			var achievement_condition : String = lock_condition.right(1)
			
			if Data.profile.progress["achievements"].get(achievement_condition, false):
				locked_skins.erase(skin_metadata_hash)
				has_unlocked_skins = true
				return OK
	
	return ERR_LOCKED


# Returns skin metadata by passed skin MD5 hash
func _get_skin_metadata_by_hash(MD5_hash_string : StringName) -> SkinMetadata:
	if not hash_links.has(MD5_hash_string): return null
	
	var album : String = hash_links[MD5_hash_string][0]
	var number : int = hash_links[MD5_hash_string][1]
	
	if not skins.has(album) : return null
	if not skins[album].has(number) : return null
	
	var metadata : SkinMetadata = skins[album][number]
	if not FileAccess.file_exists(metadata.path) : return null
	
	return metadata


func _get_skin_metadata_by_file_path(skin_file_path : String) -> SkinMetadata:
	if not path_links.has(skin_file_path): return null
	var skin_hash :StringName = path_links[skin_file_path]
	return _get_skin_metadata_by_hash(skin_hash)


# Adds skin metadata from given file 'path' into skin list. File must be .SKN formatted in order to be loaded.
# If 'force_album' is specified, skin metadata would be assigned to that album inside 'skins' list
func _process_file_skin(path : String, force_album : String = "") -> void:
	print("NEW SKIN FILE DETECTED: ", path)
	
	var file : FileAccess = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if not file:
		print("SKIN LOADING FAILED! FILE ERROR : ", FileAccess.get_open_error())
		return
	
	var skn_version : int = file.get_8()
	
	if skn_version < 7:
		print("DEPRECATED SKIN VERSION! LOADING DENIED")
		file.close()
		return
	
	var skin_metadata : SkinMetadata = SkinMetadata.new()
	skin_metadata._load(file)
	var skin_metadata_hash : StringName = StringName(skin_metadata._get_md5_hash_string())
	
	if hash_links.has(skin_metadata_hash):
		print("CONFLICTING SKIN HASH! THIS SKIN IS ALREADY LOADED")
		return
	
	skin_metadata.path = path
	skin_metadata.metadata_hash = skin_metadata_hash

	path_links[path] = skin_metadata_hash
	
	var album : String = force_album if force_album != "" else skin_metadata.album
	if not skins.has(album) : skins[album] = {}
	skin_metadata.album = album
	
	var number : int = skin_metadata.number
	if number == -1 or skins[album].has(number): 
		if skins.has(album) : number = 9999 - skins[album].size()
		else: number = 9999
	skin_metadata.number = number
	
	skins[album][number] = skin_metadata
	hash_links[skin_metadata_hash] = [album, number, skin_metadata.name]
	skins_amount += 1
	
	print("SKIN PARSED")
	file.close()


func _process_addon_skin(addon_path : String, skin_metadata : SkinMetadata) -> void:
	print("NEW ADDON SKIN DETECTED : ", skin_metadata.name)
	
	var skin_metadata_hash : StringName = StringName(skin_metadata._get_md5_hash_string())
	if hash_links.has(skin_metadata_hash):
		print("CONFLICTING SKIN HASH! THIS SKIN IS ALREADY LOADED")
		return

	skin_metadata.path = addon_path
	skin_metadata.metadata_hash = skin_metadata_hash
	
	var album : String = skin_metadata.album
	if not skins.has(album) : skins[album] = {}
	
	var number : int = skin_metadata.number
	if number == -1 or skins[album].has(number): 
		if skins.has(album) : number = 9999 - skins[album].size()
		else: number = 9999
	
	skins[album][number] = skin_metadata
	hash_links[skin_metadata_hash] = [album, number, skin_metadata.name]
	skins_amount += 1
	
	print("SKIN PARSED")


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


# Counts skin files and addon files amount. Used to determine if skin list needs an update.
func _count_skin_files_amount() -> int:
	var count : int = 0

	for path : String in [Data.BUILD_IN_PATH + Data.SKINS_PATH, Data.SKINS_PATH]:
		var dir : DirAccess = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file_name : String = dir.get_next()
			
			while file_name != "":
				if file_name.ends_with(".skn"): count += 1
				
				elif dir.current_is_dir(): 
					var sub_dir : DirAccess = DirAccess.open(path + file_name + "/")
					if sub_dir:
						sub_dir.list_dir_begin()
						var sub_file_name : String = sub_dir.get_next()
						
						while sub_file_name != "":
							if sub_file_name.ends_with(".skn"): count += 1
							sub_file_name = sub_dir.get_next()
						
						sub_dir.list_dir_end()
						
				file_name = dir.get_next()
			
			dir.list_dir_end()
	
	#count += Data._parse(Data.PARSE.ADDONS).size()
	
	return count
