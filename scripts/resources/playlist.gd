extends Resource

#-----------------------------------------------------------------------
# Skins playlist class
# 
# Stores skin album and number so it can be easily found in skin list, if its loaded.
#-----------------------------------------------------------------------

class_name SkinPlaylist
 
signal playlist_changed

var name : String = "" # Name of the playlist

var skins : Array = [] # [[1st_skin_path, 1st_skin_hash], [2nd_skin_path, 2nd_skin_hash], ...]
var missing_skins : Array = []


# Adds skin into playlist by its metadata hash
func _add_to_playlist(skin_path : String, skin_hash : StringName) -> void:
	skins.append([skin_path,skin_hash])
	playlist_changed.emit()


# Removes specified position inside playlist
func _remove_from_playlist(pos : int) -> void:
	skins.remove_at(pos)
	playlist_changed.emit()


# Swaps skins in playlist
func _swap_skins(first_skin_pos : int, second_skin_pos : int) -> void:
	var buf : Array = skins[first_skin_pos]
	skins[first_skin_pos] = skins[second_skin_pos]
	skins[second_skin_pos] = buf
	playlist_changed.emit()


# Tries to fix invalid entries in skins Array and if not possible removes them
func _fix_missing_data() -> void:
	var num : int = 0
	var path_links : Dictionary = Data.skin_list.path_links
	var hash_links : Dictionary = Data.skin_list.hash_links

	while num < skins.size():
		var skin_path : String = skins[num][0]
		var skin_hash : StringName = skins[num][1]

		if not path_links.has(skin_path):
			if not hash_links.has(skin_hash): 
				missing_skins.append(skin_path)
				skins.remove_at(num)
				num -= 1
			else:
				skin_path = Data.skin_list._get_skin_metadata_by_hash(skin_hash).path
				skins[num][0] = skin_path
				path_links[skin_path] = skin_hash
		else:
			if not hash_links.has(skin_hash):
				var skin_metadata : SkinMetadata = Data.skin_list._get_skin_metadata_by_file_path(skin_path)
				skin_hash = skin_metadata.metadata_hash
				skins[num][1] = skin_hash
				hash_links[skin_hash] = [skin_metadata.album, skin_metadata.number, skin_metadata.name]
				
		num += 1


# Saves playlist into '.ply' file
func _save(save_name : String = name) -> int:
	if save_name.is_empty() : return ERR_INVALID_DATA
	if skins.is_empty(): return ERR_INVALID_DATA
	
	name = save_name
	
	var file : FileAccess = FileAccess.open(Data.PLAYLISTS_PATH + name + ".ply", FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	
	for skin_entry : Array in skins:
		file.store_line(skin_entry[0])
		file.store_line(skin_entry[1])
	
	file.close()
	return OK


# Loads playlist from '.ply' file
func _load(path : String) -> int:
	skins.clear()
	missing_skins.clear()
	
	var file : FileAccess = FileAccess.open(path, FileAccess.READ)
	
	if file and path.ends_with(".ply"):
		name = path.get_file()
		
		while file.get_position() < file.get_length():
			skins.append([file.get_line(),file.get_line()])
		
		file.close()
		_fix_missing_data()
		return OK
	
	else:
		return FileAccess.get_open_error()
