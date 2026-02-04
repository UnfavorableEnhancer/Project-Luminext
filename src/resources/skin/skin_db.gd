# Project Luminext - an ultimate block-stacking puzzle game
# Copyright (C) <2024-2026> <unfavorable_enhancer>
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


class_name SkinDB

## All possible database states
enum STATE
{
	LOADED, ## Database is loaded
	NOT_LOADED, ## Database hasn't been loaded
	IS_LOADING, ## Database is still loading by some thread
	MISSING_DIRECTORY, ## Skins directory defined by Consts.SKIN_DIR is missing
	THREAD_FAILURE ## Database load failed due to thread error
}

signal loading_finished ## Emitted when database loading is finised

var state : STATE = STATE.NOT_LOADED # Current database state

var skin_files_amount : int = 0 ## Total amount of skin files. Used to check if new skins were added.
var skins_amount : int = 0 ## Total amount of successfully loaded skins

## Loaded skins dictionary.[br]Contains album names as keys and dictionaries of skin number : SkinMetadata pairs as values.
var skins : Dictionary[String, Dictionary] = {
#	"skin_album" : {
#		skin_number : SkinMetadata()
#	}
} 

## Dictionary with skins UID's as keys and SkinMetadata's as values.[br]Can be used to easily access SkinMetadata by it's UID.
var uid_links : Dictionary[StringName, SkinMetadata] = {
#	"skin_uid" : SkinMetadata()
} 

## Dictionary with skins hashes as keys and SkinMetadata's as values.[br]Can be used to easily access SkinMetadata by it's hash.
var hash_links : Dictionary[StringName, SkinMetadata] = {
#	"skin_uid" : SkinMetadata()
} 

## Dictionary with skins path's as keys and SkinMetadata's as values.[br]Can be used to easily access SkinMetadata by it's file path.
var filepath_links : Dictionary[String, SkinMetadata] = {
#	"skin_path" : SkinMetadata()
} 

## Dictionary of skins UID's as keys and their respective lock conditions array's as values.[br]Locked skins cannot be played or used from menus.
var locked_skins : Dictionary[StringName, Array] = {
#	"skin_uid" : ["lock_condition"]
} 


## Starts a thread to load database via *load_database()* function.[br]Returns loading state (error).
func load_database_threaded() -> STATE:
	if state == STATE.IS_LOADING : return state
	
	var thread : Thread = Thread.new()
	var err : int = thread.start(load_database)
	if err != OK : 
		loading_finished.emit()
		state = STATE.THREAD_FAILURE
		return state
	
	await loading_finished
	var result : STATE = thread.wait_to_finish()
	return result


## Loads database with skin files metadata in [Consts.SKIN_DIR].[br]Returns loading state (error).
func load_database() -> STATE:
	if state == STATE.IS_LOADING : return state
	state = STATE.IS_LOADING
	
	Console.space.call_deferred()
	Console.log.call_deferred("Loading skin database...")
	
	var skin_file_paths : PackedStringArray = get_skin_files()
	var current_skin_files_count : int = skin_file_paths.size()
	Console.log.call_deferred("Found: %s skin files" % current_skin_files_count)
	
	if current_skin_files_count == skin_files_amount:
		Console.log.call_deferred("No new skins.")
		loading_finished.emit.call_deferred()
		return STATE.LOADED
	
	skin_files_amount = current_skin_files_count
	skins_amount = 0
	skins.clear()
	uid_links.clear()
	filepath_links.clear()
	locked_skins.clear()
	
	for file_path : String in skin_file_paths : add_file_skin(file_path)
	
	return STATE.LOADED


## Adds [SkinMetadata] from given skin file **path** into database.
func add_file_skin(path : String) -> void:
	Console.log.call_deferred("Adding skin to database with path : " + path)
	var skin_metadata : SkinMetadata = SkinData.get_metadata_from_file(path)
	
	var album_name : String = skin_metadata.album_name
	var album_number : int = skin_metadata.album_number
	if album_number < 0 or (skins.has(album_name) and skins[album_name].has(album_number)): 
		if skins.has(album_name) : album_number = 9999 - skins[album_name].size()
		else: album_number = 9999
	skin_metadata.album_number = album_number
	skin_metadata.skin_filepath = path
	
	var skin_uid : StringName = skin_metadata.skin_uid
	var skin_hash : StringName = skin_metadata.skin_hash
	
	if uid_links.has(skin_uid):
		Console.log.call_deferred("This skin UID already exists in database. Resolving...")
		var stored_skin_metadata : SkinMetadata = uid_links[skin_uid]

		if stored_skin_metadata.save_timestamp < skin_metadata.save_timestamp:
			uid_links[skin_uid] = skin_metadata
			hash_links[skin_hash] = stored_skin_metadata
			Console.log.call_deferred("Found newer version skin. Older version skin now can be accessed only by its hash.")

		if stored_skin_metadata.save_timestamp == skin_metadata.save_timestamp:
			Console.log.call_deferred("Found duplicate skin. Ignoring.")
			skin_metadata.free()
			return
		else:
			hash_links[skin_hash] = skin_metadata
			Console.log.call_deferred("Found older version skin. Older version skin can be accessed only by its hash.")
	else:
		uid_links[skin_uid] = skin_metadata
	
	Console.log.call_deferred("Added skin : %s (%s | %s) [%s | %s]" % [skin_metadata.name, album_name, album_number, skin_uid, skin_hash])
	
	filepath_links[path] = skin_metadata
	if not skins.has(album_name) : skins[album_name] = {}
	skins[album_name][album_number] = skin_metadata
	
	skins_amount += 1


## Returns [SkinMetadata] by passed skin **album name** and **album number**
func get_metadata_by_album(album_name : String, album_number : int) -> SkinMetadata:
	if state == STATE.IS_LOADING : return null
	if not skins.has(album_name): return null
	if not skins[album_name].has(album_number): return null
	return skins[album_name][album_number]

## Returns [SkinMetadata] by passed skin **uid**
func get_metadata_by_uid(skin_uid : StringName) -> SkinMetadata:
	if state == STATE.IS_LOADING : return null
	return uid_links[skin_uid]

## Returns [SkinMetadata] by passed skin **hash**
func get_metadata_by_hash(skin_hash : StringName) -> SkinMetadata:
	if state == STATE.IS_LOADING : return null
	return hash_links[skin_hash]

## Returns [SkinMetadata] by provided skin file **path**
func get_metadata_by_path(skin_filepath : String) -> SkinMetadata:
	if state == STATE.IS_LOADING : return null
	return filepath_links[skin_filepath]


## Get shuffled [SkinMetadata] array from database.[br] 
## If **'amount'** == -1 it will return all avaiable [SkinMetadata] shuffled.
func get_random_skins_metadata(amount : int = -1) -> Array[SkinMetadata]:
	if state == STATE.IS_LOADING : return []
	
	if amount == -1 or amount > skins_amount: amount = skins_amount
	if amount == 0: return []

	var randomized_skins : Array[SkinMetadata] = []
	var all_skins_uids : Array[StringName] = uid_links.keys()

	for i : int in amount:
		var rand : int = randi_range(0, all_skins_uids.size() - 1)
		randomized_skins.append(get_metadata_by_uid(all_skins_uids[rand]))
		all_skins_uids.remove_at(rand)

	return randomized_skins


## Returns skin files paths array.
func get_skin_files() -> PackedStringArray:
	var skin_file_paths : PackedStringArray = PackedStringArray()
	
	var search_func : Callable
	search_func = func(path : String) -> void:
		var dir : DirAccess = DirAccess.open(path)
		if not dir : return
		
		if (dir.list_dir_begin() != OK): return
		var entry : String = dir.get_next()
		
		while entry != "":
			if entry.ends_with(".skn") : skin_file_paths.append(entry)
			elif dir.current_is_dir() : search_func.call(entry)
			entry = dir.get_next()
		
		dir.list_dir_end()
	
	search_func.call(Consts.SKIN_DIR)
	return skin_file_paths
