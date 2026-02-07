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

##
## Contains all frontend data which is shown to user when they select this skin in some browser.[br]
## Can be loaded and viewed separately from rest of the [SkinData] using it's static method *"get_metadata_from_file()"*.
##
class_name SkinMetadata

## All media assets stored as raw bytes (images, audio, and etc.)
enum ASSET_TYPE {
	COVER_ART,
	LABEL_ART,
	ANNOUNCE_SAMPLE,
	PREVIEW_SAMPLE
}

var skin_filepath : String = "" ## Path to the parent skin file path

var skin_uid : StringName ## Unique identifier of this skin (generated once)
var skin_hash : StringName = "" ## Current version hash of this skin (generates on each save)

var skin_name : String = "" ## Name of the skin
var music_name : String = "" ## Name of the music used in this skin
var music_artist : String = "" ## Name of the skin music artist
var visual_designer : String = "" ## Name of the skin visual designer
var bpm : float = 120.0 ## BPM of the skin music
var time_signature : String = "4/4" ## Time signature of the skin music

var skin_by : String = "" ## Name of the last person who edited this skin
var save_timestamp : float = 0.0 ## Latest timestamp when this skin was saved

var album_name : String = "" ## Name of the album which contains this skin
var album_number : int = 0 ## Number of the skin inside album

var info : String = "" ## Additional info about skin

#NOTE ModdableAssets stored here shouldn't be stored in [SkinAssetData] in order to be able to be loaded separately from it

var cover_art : ModdableAsset.TextureAsset = null ## Skin cover art texture (256x256)
var label_art : ModdableAsset.TextureAsset = null ## Skin label art texture (256x64)

var announce_sample : ModdableAsset.AudioAsset = null ## Skin name announce sample
var preview_sample : ModdableAsset.AudioAsset = null ## Skin music preview sample


## Loads metadata from passed FileAccess **(must be used only by SkinData.load)**
func load(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Saves metadata to passed FileAccess **(must be used only by SkinData.load)**
func save(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK


## Inserts asset from passed file path into metadata [ASSET_TYPE][br]
## Returns true on success.
func insert_asset(asset_type : ASSET_TYPE, asset_filepath : String) -> bool:
	match asset_type:
		ASSET_TYPE.COVER_ART:
			var texture_asset : ModdableAsset.TextureAsset
			
			if cover_art == null : texture_asset = AssetSerializer.process_texture(asset_filepath)
			else : texture_asset = AssetSerializer.process_texture(asset_filepath, cover_art)
			
			if texture_asset == null : return false
			cover_art = texture_asset
			
		ASSET_TYPE.LABEL_ART:
			var texture_asset : ModdableAsset.TextureAsset
			
			if label_art == null : texture_asset = AssetSerializer.process_texture(asset_filepath)
			else : texture_asset = AssetSerializer.process_texture(asset_filepath, label_art)
			
			if texture_asset == null : return false
			label_art = texture_asset
			
		ASSET_TYPE.ANNOUNCE_SAMPLE:
			var audio_asset : ModdableAsset.AudioAsset
			
			if announce_sample == null : audio_asset = AssetSerializer.process_audio(asset_filepath)
			else : audio_asset = AssetSerializer.process_audio(asset_filepath, announce_sample)
			
			if audio_asset == null : return false
			announce_sample = audio_asset
			
		ASSET_TYPE.PREVIEW_SAMPLE:
			var audio_asset : ModdableAsset.AudioAsset
			
			if preview_sample == null : audio_asset = AssetSerializer.process_audio(asset_filepath)
			else : audio_asset = AssetSerializer.process_audio(asset_filepath, preview_sample)
			
			if audio_asset == null : return false
			preview_sample = audio_asset
	
	return true


## Loads all metadata assets
func load_all_assets() -> void:
	@warning_ignore("return_value_discarded")
	for asset_type : ASSET_TYPE in ASSET_TYPE : load_asset(asset_type)

## Loads specified metadata asset
func load_asset(asset_type : ASSET_TYPE) -> bool:
	match asset_type:
		ASSET_TYPE.COVER_ART : return AssetLoader.load_texture(cover_art)
		ASSET_TYPE.LABEL_ART : return AssetLoader.load_texture(label_art)
		ASSET_TYPE.ANNOUNCE_SAMPLE : return AssetLoader.load_audio_stream(announce_sample)
		ASSET_TYPE.PREVIEW_SAMPLE : return AssetLoader.load_audio_stream(preview_sample)
	
	return false
