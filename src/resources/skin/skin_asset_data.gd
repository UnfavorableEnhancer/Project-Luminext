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
## Contains all skin assets (textures, audio, video and fonts) which are then used by several [SkinData] 
## sub-data structures (ex. [SkinBlockData] or [SkinSceneData]).[br]
## Each asset is stored as raw bytes in .skn formatted file under own uid's 
## (which are created from asset type prefix + asset file MD5 hash).[br]
## When skin is being loaded, all assets are serialized into respective Godot resources and then can be used by anyone.
##
class_name SkinAssetData

var textures : Dictionary[StringName, ModdableAsset.TextureAsset] = {} ## Contains texture assets
var audio : Dictionary[StringName, ModdableAsset.AudioAsset] = {} ## Contains audio assets
var video : Dictionary[StringName, ModdableAsset.VideoAsset] = {} ## Contains video assets
var fonts : Dictionary[StringName, ModdableAsset.FontAsset] = {} ## Contains font assets


## Destructor
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		clear_video_cache()


## Loads assets data from passed FileAccess **(must be used only by SkinData.load)**
func load(_file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK


## Saves assets data to passed FileAccess **(must be used only by SkinData.load)**
func save(_file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK


## Inserts passed texture file into texture assets dictionary
## and returns serialized and loaded [ModdableAsset.TextureAsset].[br]
## If **"current_texture_asset"** is passed, will update it's texture and uid.
func insert_texture(texture_filepath : String, current_texture_asset : ModdableAsset.TextureAsset = null) -> ModdableAsset.TextureAsset:
	# Uid must be saved until being overwritten by AssetSerializer
	var current_texture_asset_uid : StringName 
	if current_texture_asset != null : current_texture_asset_uid = current_texture_asset.uid
	
	var texture_asset : ModdableAsset.TextureAsset = AssetSerializer.process_texture(texture_filepath, current_texture_asset)
	if texture_asset == null : return null
	
	# If this texture is already inserted or exactly same, reuse it
	if texture_asset.uid in textures:
		return textures[texture_asset.uid]
	
	# If existing texture asset was updated with new texture, update its uid in textures dict
	if current_texture_asset != null:
		textures.erase(current_texture_asset_uid)
	
	textures[texture_asset.uid] = texture_asset
	AssetLoader.load_texture(texture_asset)
	return texture_asset


## Inserts passed audio stream file into audio assets dictionary
## and returns serialized and loaded [ModdableAsset.AudioAsset].[br]
## If **"current_audio_asset"** is passed, will update it's audio stream and uid.
func insert_audio(audio_stream_filepath : String, current_audio_asset : ModdableAsset.AudioAsset = null) -> ModdableAsset.AudioAsset:
	# Uid must be saved until being overwritten by AssetSerializer
	var current_audio_asset_uid : StringName 
	if current_audio_asset != null : current_audio_asset_uid = current_audio_asset.uid
	
	var audio_asset : ModdableAsset.AudioAsset = AssetSerializer.process_audio(audio_stream_filepath, current_audio_asset)
	if audio_asset == null : return null
	
	# If this texture is already inserted or exactly same, reuse it
	if audio_asset.uid in audio:
		return audio[audio_asset.uid]
	
	# If existing texture asset was updated with new texture, update its uid in textures dict
	if current_audio_asset != null:
		audio.erase(current_audio_asset_uid)
	
	audio[audio_asset.uid] = audio_asset
	AssetLoader.load_audio_stream(audio_asset)
	return audio_asset


## Inserts passed video stream file into video assets dictionary.
## and returns serialized and loaded [ModdableAsset.VideoAsset].[br]
## If **"current_video_asset"** is passed, will update it's texture and uid.
func insert_video(video_stream_filepath : String, current_video_asset : ModdableAsset.VideoAsset = null) -> ModdableAsset.VideoAsset:
	# Uid must be saved until being overwritten by AssetSerializer
	var current_video_asset_uid : StringName 
	if current_video_asset != null : current_video_asset_uid = current_video_asset.uid
	
	var video_asset : ModdableAsset.VideoAsset = AssetSerializer.process_video(video_stream_filepath, current_video_asset)
	if video_asset == null : return null
	
	# If this texture is already inserted or exactly same, reuse it
	if video_asset.uid in video:
		return video[video_asset.uid]
	
	# If existing texture asset was updated with new texture, update its uid in textures dict
	if current_video_asset != null:
		textures.erase(current_video_asset_uid)
	
	video[video_asset.uid] = video_asset
	AssetLoader.load_video_stream(video_asset)
	return video_asset


## Inserts passed texture file into texture assets dictionary.
## and returns serialized and loaded [ModdableAsset.AudioAsset].[br]
## If **"current_texture_asset"** is passed, will update it's texture and uid.
func insert_font(font_filepath : String, current_font_asset : ModdableAsset.FontAsset = null) -> ModdableAsset.FontAsset:
	# Uid must be saved until being overwritten by AssetSerializer
	var current_font_asset_uid : StringName 
	if current_font_asset != null : current_font_asset_uid = current_font_asset.uid
	
	var font_asset : ModdableAsset.FontAsset = AssetSerializer.process_font(font_filepath, current_font_asset)
	if font_asset == null : return null
	
	# If this texture is already inserted or exactly same, reuse it
	if font_asset.uid in textures:
		return fonts[font_asset.uid]
	
	# If existing texture asset was updated with new texture, update its uid in textures dict
	if current_font_asset != null:
		textures.erase(current_font_asset_uid)
	
	fonts[font_asset.uid] = font_asset
	AssetLoader.load_font(font_asset)
	return font_asset


## Loads all assets from raw bytes into ready to use Godot resources
func load_all_assets() -> void:
	for texture_asset : ModdableAsset.TextureAsset in textures.values() : AssetLoader.load_texture(texture_asset)
	for audio_asset : ModdableAsset.AudioAsset in audio.values() : AssetLoader.load_audio_stream(audio_asset)
	for video_asset : ModdableAsset.VideoAsset in video.values() : AssetLoader.load_video_stream(video_asset)
	for font_asset : ModdableAsset.FontAsset in fonts.values() : AssetLoader.load_font(font_asset)

## Removes all loaded video files from cache
func clear_video_cache() -> void:
	for video_asset : ModdableAsset.VideoAsset in video.values():
		if video_asset.stream != null:
			DirAccess.remove_absolute(video_asset.stream.file)
