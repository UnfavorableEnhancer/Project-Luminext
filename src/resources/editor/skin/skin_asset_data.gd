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
## sub-structures (ex. [SkinBlockData] or [SkinSceneData]).[br]
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
		_clear_video_cache()


## Saves assets data to passed FileAccess **(must be used only by SkinData.load)**
func save(_file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Loads assets data from passed FileAccess **(must be used only by SkinData.load)**
func load(_file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Loads all assets from raw bytes into ready to use Godot resources
func _load_all_assets() -> void:
	for texture_asset : ModdableAsset.TextureAsset in textures.values() : AssetLoader.load_texture(texture_asset)
	for audio_asset : ModdableAsset.AudioAsset in audio.values() : AssetLoader.load_audio_stream(audio_asset)
	for video_asset : ModdableAsset.VideoAsset in video.values() : AssetLoader.load_video_stream(video_asset)
	for font_asset : ModdableAsset.FontAsset in fonts.values() : AssetLoader.load_font(font_asset)


## Inserts passed texture file into texture assets dictionary and returns serialized and loaded [ModdableAsset.TextureAsset].[br]
## Returns **null** on failure.
func insert_texture(texture_filepath : String) -> ModdableAsset.TextureAsset:
	var texture_asset : ModdableAsset.TextureAsset = AssetSerializer.process_texture(texture_filepath)
	if texture_asset == null : return null
	
	# If this texture is already inserted or exactly same, reuse it
	if texture_asset.uid in textures : return textures[texture_asset.uid]
	
	textures[texture_asset.uid] = texture_asset
	AssetLoader.load_texture(texture_asset)
	return texture_asset


## Inserts passed spritesheet file into texture assets dictionary and returns array of serialized and loaded [ModdableAsset.TextureAsset].[br]
## Returns **empty array** on failure.
func insert_spritesheet(texture_filepath : String) -> Array[ModdableAsset.TextureAsset]:
	var texture_assets : Array[ModdableAsset.TextureAsset] = AssetSerializer.process_spritesheet(texture_filepath)
	if texture_assets.is_empty() : return []
	
	for texture_asset : ModdableAsset.TextureAsset in texture_assets:
		if texture_asset.uid in textures: continue
		
		textures[texture_asset.uid] = texture_asset
		AssetLoader.load_texture(texture_asset)
	
	return texture_assets


## Inserts passed audio stream file into audio assets dictionary and returns serialized and loaded [ModdableAsset.AudioAsset].[br]
## Returns **null** on failure.
func insert_audio(audio_stream_filepath : String) -> ModdableAsset.AudioAsset:
	var audio_asset : ModdableAsset.AudioAsset = AssetSerializer.process_audio(audio_stream_filepath)
	if audio_asset == null : return null
	
	# If this texture is already inserted or exactly same, reuse it
	if audio_asset.uid in audio : return audio[audio_asset.uid]
	
	audio[audio_asset.uid] = audio_asset
	AssetLoader.load_audio_stream(audio_asset)
	return audio_asset


## Inserts passed video stream file into video assets dictionary and returns serialized and loaded [ModdableAsset.VideoAsset].[br]
## Returns **null** on failure.
func insert_video(video_stream_filepath : String) -> ModdableAsset.VideoAsset:
	var video_asset : ModdableAsset.VideoAsset = AssetSerializer.process_video(video_stream_filepath)
	if video_asset == null : return null
	
	# If this texture is already inserted or exactly same, reuse it
	if video_asset.uid in video : return video[video_asset.uid]
	
	video[video_asset.uid] = video_asset
	AssetLoader.load_video_stream(video_asset)
	return video_asset


## Inserts passed texture file into texture assets dictionary and returns serialized and loaded [ModdableAsset.FontAsset].[br]
## Returns **null** on failure.
func insert_font(font_filepath : String) -> ModdableAsset.FontAsset:
	var font_asset : ModdableAsset.FontAsset = AssetSerializer.process_font(font_filepath)
	if font_asset == null : return null
	
	# If this font is already inserted or exactly same, reuse it
	if font_asset.uid in fonts : return fonts[font_asset.uid]
	
	fonts[font_asset.uid] = font_asset
	AssetLoader.load_font(font_asset)
	return font_asset


## Removes all loaded video files from cache
func _clear_video_cache() -> void:
	for video_asset : ModdableAsset.VideoAsset in video.values():
		if video_asset.stream != null:
			DirAccess.remove_absolute(video_asset.stream.file)
