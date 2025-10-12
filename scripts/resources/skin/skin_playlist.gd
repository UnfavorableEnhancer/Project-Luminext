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


extends Resource

##-----------------------------------------------------------------------
## Stores series of skins ID's and hashes for playing them in order
## When loading it first tries to load skin metadata by its hash, but if its not present in skin list, then its tries to load by it's id
## It allows to store multiple versions of same skin inside one playlist and also fix itself if user suddenly has only skin of newer version
##-----------------------------------------------------------------------

class_name SkinPlaylist
 
signal playlist_changed ## Emitted when playlist was changed

var name : String = "" ## Name of the playlist

var skins_ids : Array[StringName] = [] ## Array of skins id's used in this playlist
var skins_hashes : Array[StringName] = [] ## Array of skins hashes used in this playlist
var skins_names : Array[String] = [] ## Array of skins names, used in case skin is missing so player can indentify it
var skins_paths : Array[String] = [] ## Array of skins paths, used as last option of getting skin in position and is not saved into playlist file


## Returns current playlist size
func _get_size() -> int:
	return skins_ids.size()


## Returns skin metadata stored in specified position inside playlist [br]
## Returns **null** if skin isn't loaded into skin list
func _get_skin_metadata_in_position(pos : int) -> SkinMetadata:
	if pos > skins_hashes.size() : return null
	
	var skin_metadata : SkinMetadata = Data.skin_list._get_skin_metadata_by_id(skins_hashes[pos])
	
	if skin_metadata == null : 
		skin_metadata = Data.skin_list._get_skin_metadata_by_id(skins_ids[pos])
	
	if skin_metadata == null :
		if skins_paths[pos].is_empty() : return null

		skin_metadata = SkinMetadata.new()
		if skin_metadata._load_from_path(skins_paths[pos]) != OK:
			return null

	return skin_metadata


## Adds passed skin metadata into playlist. [br]
## If [b]'emit'[/b] is true, emits [b]'playlist_changed'[/b] signal
func _add_to_playlist(skin_metadata : SkinMetadata, emit : bool = true) -> void:
	skins_ids.append(skin_metadata.id)
	skins_hashes.append(skin_metadata.metadata_hash)
	skins_names.append(skin_metadata.name + "/" + skin_metadata.artist + "/" + skin_metadata.skin_by)
	skins_paths.append(skin_metadata.path)
	if emit : playlist_changed.emit()


## Adds passed skin path into playlist[br]
## This method only adds skin path, ignoring skin id and hash, playlist without that data cannot be saved
func _add_path_to_playlist(skin_path : String) -> bool:
	skins_ids.append("")
	skins_hashes.append("")
	skins_names.append(skin_path)
	skins_paths.append(skin_path)
	
	return true


## Removes specified position inside playlist
## If [b]'emit'[/b] is true, emits [b]'playlist_changed'[/b] signal
func _remove_from_playlist(pos : int, emit : bool = true) -> void:
	skins_ids.remove_at(pos)
	skins_hashes.remove_at(pos)
	skins_names.remove_at(pos)
	skins_paths.remove_at(pos)
	if emit : playlist_changed.emit()


## Clears playlist and removes all skins
func _clear() -> void:
	skins_ids.clear()
	skins_hashes.clear()
	skins_names.clear()
	skins_paths.clear()
	name = ""


## Swaps two skins positions in playlist
func _swap_skins(first_skin_pos : int, second_skin_pos : int) -> void:
	var buf : StringName = skins_ids[first_skin_pos]
	skins_ids[first_skin_pos] = skins_ids[second_skin_pos]
	skins_ids[second_skin_pos] = buf

	buf = skins_hashes[first_skin_pos]
	skins_hashes[first_skin_pos] = skins_hashes[second_skin_pos]
	skins_hashes[second_skin_pos] = buf

	buf = skins_names[first_skin_pos]
	skins_names[first_skin_pos] = skins_names[second_skin_pos]
	skins_names[second_skin_pos] = buf

	buf = skins_paths[first_skin_pos]
	skins_paths[first_skin_pos] = skins_paths[second_skin_pos]
	skins_paths[second_skin_pos] = buf

	playlist_changed.emit()


## Saves playlist with specified name into [constant Data.PLAYLISTS_PATH]
func _save_with_name(playlist_name : String) -> void:
	name = playlist_name
	_save(Data.PLAYLISTS_PATH + playlist_name + ".ply")


## Saves playlist into '.ply' formatted file
func _save(path : String) -> int:
	Console._log("Saving skin playlist to path : " + path)

	if skins_ids.is_empty() or skins_hashes.is_empty() :
		Console._log("ERROR! Playlist is empty")
		return ERR_INVALID_DATA

	if skins_ids[0].is_empty():
		Console._log("ERROR! Playlist is invalid")
		return ERR_INVALID_DATA

	var file : FileAccess = FileAccess.open_compressed(path, FileAccess.WRITE, FileAccess.COMPRESSION_DEFLATE)
	if not file:
		Console._log("ERROR! Failed saving playlist. File open error : " + error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()
	
	file.store_32(skins_ids.size())
	for skin_id : StringName in skins_ids:
		file.store_line(skin_id)
	for skin_hash : StringName in skins_hashes:
		file.store_line(skin_hash)
	for skin_name : StringName in skins_names:
		file.store_line(skin_name)
	
	file.close()
	return OK


## Loads playlist from '.ply' formatted file
func _load(path : String) -> int:
	Console._log("Loading skin playlist from path : " + path)
	
	if path.ends_with(".ply"):
		Console._log("ERROR! Failed loading playlist. Invalid format")
		return FileAccess.get_open_error()

	var file : FileAccess = FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_DEFLATE)
	if not file:
		Console._log("ERROR! Failed loading playlist. File open error : " + error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()
	
	skins_ids.clear()
	skins_hashes.clear()
	skins_names.clear()

	name = path.get_file()
	
	var skins_amount : int = file.get_32()

	for i : int in skins_amount:
		if file.get_position() > file.get_length():
			Console._log("ERROR! Failed loading playlist. File is damaged")
			return ERR_FILE_CORRUPT
		skins_ids.append(file.get_line())

	for i : int in skins_amount:
		if file.get_position() > file.get_length():
			Console._log("ERROR! Failed loading playlist. File is damaged")
			return ERR_FILE_CORRUPT
		skins_hashes.append(file.get_line())

	for i : int in skins_amount:
		if file.get_position() > file.get_length():
			Console._log("ERROR! Failed loading playlist. File is damaged")
			return ERR_FILE_CORRUPT
		skins_names.append(file.get_line())
		skins_paths.append("")
	
	file.close()
	return OK


## Validates this playlist by checking are all included skins available [br]
## Returns list of corrupted or missing skins. If list is empty then playlist is fully valid
func _validate() -> Array[String]:
	var invalid_skins : Array[String] = []

	for pos : int in skins_ids.size():
		if _get_skin_metadata_in_position(pos) == null : invalid_skins.append(skins_names[pos])
	
	return invalid_skins