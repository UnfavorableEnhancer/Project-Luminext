class_name SkinMetadata

var skin_filepath : String = "" ## Path to the parent skin file path

var skin_uid : StringName ## Unique identifier of this skin (generated once)
var skin_hash : StringName = "" ## Current version hash of this skin (generates on each save)

var name : String = "" ## Name of the skin
var artist : String = "" ## Name of the skin music artist
var bpm : float = 120.0 ## BPM of the skin music
var time_signature : String = "4/4" ## Time signature of the skin music

var skin_by : String = "" ## Name of the last person who edited this skin
var save_timestamp : float = 0.0 ## Latest timestamp when this skin was saved

var album_name : String = "" ## Name of the album which contains this skin
var album_number : int = 0 ## Number of the skin inside album

var info : String = "" ## Additional info about skin

var cover_art : Texture = null ## Skin cover art texture (256x256)
var cover_art_raw : PackedByteArray ## Raw cover art image bytes
var cover_art_format : Consts.SUPPORTED_IMAGE_FORMATS ## Raw cover art image format

var label_art : Texture = null ## Skin label art texture (256x64)
var label_art_raw : PackedByteArray ## Raw label art image bytes
var label_art_format : Consts.SUPPORTED_IMAGE_FORMATS ## Raw label art image format

var announce_sample : AudioStream = null ## Skin name announce sample
var announce_sample_raw : PackedByteArray ## Raw announce sample bytes
var announce_sample_format : Consts.SUPPORTED_AUDIO_FORMATS ## Raw announce sample format

var preview_sample : AudioStream = null ## Skin music preview sample
var preview_sample_raw : PackedByteArray ## Raw music preview sample bytes
var preview_sample_format : Consts.SUPPORTED_AUDIO_FORMATS ## Raw music preview sample format


## Loads metadata from passed FileAccess **(must be used only by SkinData.load)**
func load(file : FileAccess) -> bool:
	return true

## Saves metadata to passed FileAccess **(must be used only by SkinData.load)**
func save(file : FileAccess) -> bool:
	return true

## Loads raw images and audio samples metadata contains
func load_raw_media() -> void:
	pass
