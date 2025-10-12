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

class_name SkinMetadata

##-----------------------------------------------------------------------
## Stores all skin metadata, which is intended to be loaded first and quickly from .skn file
##-----------------------------------------------------------------------

const ID_SIZE : int = 10 ## Unique skin identifier size

var version : int = SkinData.VERSION ## Skin file version

var path : String = "" ## Path to the skin file or addon file which contains this skin (can only be loaded)
var metadata_hash : StringName = "" ## MD5 hash of this skin used as version indentifier
var id : StringName = "" ## Indentifier string, unlike hash its made once, so skin can be easily found even after modification

var name : String = "" ## Name of the skin
var artist : String = "" ## Name of the artist who made the skin music
var skin_by : String = "" ## Name of the last person who edited this skin
var save_date : float = 0.0 ## Latest date stamp when this skin was saved
var album : String = "" ## Name of the album which contains this skin
var number : int = 0 ## Number of the skin inside album
var info : String = "" ## Additional info about skin

var cover_art : Texture = null ## Skin cover art texture (256x256)
var label_art : Texture = null ## Skin label art texture (256x64)

var announce : AudioStream = null ## Skin name announce sample, used when skin is loaded and ready to be switched to
var preview : AudioStream = null ## Music preview sample which would play when skin is selected

var bpm : float = 120.0 ## BPM of the skin, affects gameplay speed
var time_signature : String = "4/4" ## TODO (currently unimplemented since idk how to do it)

## Skin playback settings
var settings : Dictionary = {
	"no_shaking" : false, # Disable background shaking (movement) for this skin
	"zoom_background" : true, # Scale up background, so background wont go out of bounds when moving
	"looping" : false, # Latest skin music sample will be looped until square is erased
	"random_bonus" : false, # Makes scenery bonus animation play randomly, instead of sequentially
}


## Returns a copy of this [SkinMetadata]
func _duplicate() -> SkinMetadata:
	var new_metadata : SkinMetadata = SkinMetadata.new()
	
	new_metadata.path = path
	new_metadata.hash = hash
	new_metadata.id = id
	new_metadata.name = name
	new_metadata.artist = artist
	new_metadata.skin_by = skin_by
	new_metadata.save_date = save_date
	new_metadata.album = album
	new_metadata.number = number
	new_metadata.info = info
	new_metadata.cover_art = cover_art.duplicate(true) if cover_art != null else null
	new_metadata.label_art = label_art.duplicate(true) if label_art != null else null
	new_metadata.announce = announce.duplicate(true) if announce != null else null
	new_metadata.preview = preview.duplicate(true) if preview != null else null
	new_metadata.bpm = bpm
	new_metadata.time_signature = time_signature

	return new_metadata


## Loads skin metadata using passed [FileAccess] instance
func _load(file : FileAccess) -> int:
	name = file.get_pascal_string()
	artist = file.get_pascal_string()
	album = file.get_pascal_string()
	skin_by = file.get_pascal_string()

	id = file.get_pascal_string()
	if id.length() > ID_SIZE : id = id.left(ID_SIZE)
	save_date = file.get_double()

	# Since store_16 is unable to store signed numbers, we use number 65500 to represent -1 and below (its gonna be loaded somewhere at the end of album anyway)
	number = file.get_16()
	if number == 65500 : number = -1

	info = file.get_pascal_string()

	cover_art = file.get_var(true)
	label_art = file.get_var(true)
	announce = file.get_var(true)
	preview = file.get_var(true)

	bpm = file.get_double()
	time_signature = file.get_pascal_string()
	settings = file.get_var()

	metadata_hash = _generate_id()
	return OK


## Loads skin metadata from provided '.skn' file path
func _load_from_path(file_path : String) -> int:
	var file : FileAccess = FileAccess.open_compressed(file_path, FileAccess.READ, FileAccess.COMPRESSION_DEFLATE)
	if not file: 
		print("ERROR! Failed to open skin file. File open error : " + error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()
	
	file.get_8()
	_load(file)
	path = file_path

	return OK


## Saves skin metadata using passed [FileAccess] instance
func _save(file : FileAccess) -> int:
	file.store_pascal_string(name)
	file.store_pascal_string(artist)
	file.store_pascal_string(album)
	file.store_pascal_string(skin_by)

	if id.is_empty() : id = _generate_id()
	file.store_pascal_string(id)
	file.store_double(save_date)

	# Since store_16 is unable to store signed numbers, we use number 65500 to represent -1 and below (its gonna be loaded somewhere at the end of album anyway)
	if number < 0 : file.store_16(65500)
	else : file.store_16(number)

	file.store_pascal_string(info)
	
	file.store_var(cover_art,true)
	file.store_var(label_art,true)
	file.store_var(announce,true)
	file.store_var(preview,true)

	file.store_double(bpm)
	file.store_pascal_string(time_signature)
	file.store_var(settings)
	return OK


## Generates unique ID for this skin
func _generate_id() -> StringName:
	var hash_buffer : PackedByteArray = (name + artist + album + skin_by + str(save_date)).md5_buffer()
	return StringName("10" + hash_buffer.get_string_from_ascii().left(ID_SIZE))
