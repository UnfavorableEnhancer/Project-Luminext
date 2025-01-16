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
class_name SkinMetadata

# Class intended for holding skin metadata

const ID_SIZE : int = 12

var version : int = SkinData.VERSION # Skin version

# This data is not saved and used when skin metadata is loaded
var path : String = "" # Path to the skin file or addon file which contains this skin
var metadata_hash : StringName = "" # MD5 hash of this skin used as indentifier
var id : StringName = "" # Indentifier string, unlike hash its made once, so skin can be easily found even after modification

var name : String = "" # Name of the skin
var artist : String = "" # Name of the artist who made the song
var skin_by : String = "" # Name of the last person who edited this skin
var save_date : float = 0.0 # Last date stamp when this skin was saved
var album : String = "" # Name of the album in which skin would be placed on load
var number : int = 0 # Number of the skin inside album
var info : String = "" # Additional info about skin

var cover_art : Texture = null # Skin cover art texture (256x256)
var label_art : Texture = null # Skin label art texture (256x64)

var announce : AudioStream = null # Skin name announce sample, used when skin is loaded and ready to be switched to
var preview : AudioStream = null # Music sample which would play when skin is selected

var bpm : float = 120.0 # BPM of the skin, affects gameplay speed
var time_signature : String = "4/4" # TODO (currently unimplemented since idk how to do it)

var settings : Dictionary = {
	"no_shaking" : false, # Force background shaking disable
	"zoom_background" : true, # Scales background up, when shaking is enabled
	"looping" : false, # If true, skin song will loop until square is erased
	"random_bonus" : false, # Makes scenery bonus animation play randomly
}


func _duplicate() -> SkinMetadata:
	var new_metadata : SkinMetadata = SkinMetadata.new()
	
	new_metadata.path = path
	new_metadata.metadata_hash = metadata_hash
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


# Loads skin metadata using passed FileAccess instance
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
	return OK


# Saves skin metadata using passed FileAccess instance
func _save(file : FileAccess) -> int:
	file.store_pascal_string(name)
	file.store_pascal_string(artist)
	file.store_pascal_string(album)
	file.store_pascal_string(skin_by)

	if id.is_empty() : _generate_id()
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


# Returns md5 hash string used as a unique indentifier to this skin
func _get_md5_hash_string() -> StringName:
	return StringName((name + artist + album + skin_by + str(save_date)).md5_text())


func _generate_id() -> void:
	if not id.is_empty(): return

	var hash_buffer : PackedByteArray = (name + artist + album + skin_by + str(save_date)).md5_buffer()
	for byte : int in hash_buffer:
		var mod_byte : float = byte * randf_range(0.1,10)
		id += str(roundi(mod_byte))
		if id.length() > ID_SIZE: break 
	
	id = id.left(ID_SIZE)
