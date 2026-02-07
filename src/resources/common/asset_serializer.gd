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
## Turns passed asset (texture, audio, video or font) into [ModdableAsset] sub-class.
##
class_name AssetSerializer


## Serializes passed texture file into [ModdableAsset.TextureAsset].[br]
## Can serialise into existing passed [ModdableAsset.TextureAsset] for asset replacement.
static func process_texture(texture_filepath : String, texture_asset : ModdableAsset.TextureAsset = null) -> ModdableAsset.TextureAsset:
	var texture_file : FileAccess = FileAccess.open(texture_filepath, FileAccess.READ)
	if texture_file == null : return null
	
	if texture_asset == null : texture_asset = ModdableAsset.TextureAsset.new()
	
	texture_asset.raw_bytes = texture_file.get_buffer(texture_file.get_length())
	match texture_filepath.get_extension():
		"png" : texture_asset.format = ModdableAsset.TextureAsset.FORMAT.PNG
		"jpg", "jpeg" : texture_asset.format = ModdableAsset.TextureAsset.FORMAT.JPEG
		"bmp" : texture_asset.format = ModdableAsset.TextureAsset.FORMAT.BMP
	
	texture_asset.uid = StringName("t" + FileAccess.get_md5(texture_filepath))
	return texture_asset


## Serializes passed audio stream file into [ModdableAsset.AudioAsset].[br]
## Can serialise into existing passed [ModdableAsset.AudioAsset] for asset replacement.
static func process_audio(audio_stream_filepath : String, audio_asset : ModdableAsset.AudioAsset = null) -> ModdableAsset.AudioAsset:
	var audio_file : FileAccess = FileAccess.open(audio_stream_filepath, FileAccess.READ)
	if audio_file == null : return null
	
	if audio_asset == null : audio_asset = ModdableAsset.AudioAsset.new()
	
	audio_asset.raw_bytes = audio_file.get_buffer(audio_file.get_length())
	match audio_stream_filepath.get_extension():
		"ogg" : audio_asset.format = ModdableAsset.AudioAsset.FORMAT.OGG
		"mp3" : audio_asset.format = ModdableAsset.AudioAsset.FORMAT.MP3
		"wav" : audio_asset.format = ModdableAsset.AudioAsset.FORMAT.WAV
	
	audio_asset.uid = StringName("a" + FileAccess.get_md5(audio_stream_filepath))
	return audio_asset


## Serializes passed video stream file into [ModdableAsset.VideoAsset].[br]
## Can serialise into existing passed [ModdableAsset.VideoAsset] for asset replacement.
static func process_video(video_stream_filepath : String, video_asset : ModdableAsset.VideoAsset = null) -> ModdableAsset.VideoAsset:
	var video_file : FileAccess = FileAccess.open(video_stream_filepath, FileAccess.READ)
	if video_file == null : return null
	
	if video_asset == null : video_asset = ModdableAsset.VideoAsset.new()
	
	video_asset.raw_bytes = video_file.get_buffer(video_file.get_length())
	match video_stream_filepath.get_extension():
		"webm" : video_asset.format = ModdableAsset.VideoAsset.FORMAT.WEBM
		"mp4" : video_asset.format = ModdableAsset.VideoAsset.FORMAT.MP4
	
	video_asset.uid = StringName("v" + FileAccess.get_md5(video_stream_filepath))
	return video_asset


## Serializes passed font file into [ModdableAsset.FontAsset].[br]
## Can serialise into existing passed [ModdableAsset.FontAsset] for asset replacement.
static func process_font(font_filepath : String, font_asset : ModdableAsset.FontAsset = null) -> ModdableAsset.FontAsset:
	var font_file : FileAccess = FileAccess.open(font_filepath, FileAccess.READ)
	if font_file == null : return null
	
	if font_asset == null : font_asset = ModdableAsset.FontAsset.new()
	
	font_asset.raw_bytes = font_file.get_buffer(font_file.get_length())
	match font_filepath.get_extension():
		"ttf" : font_asset.format = ModdableAsset.FontAsset.FORMAT.TTF
		"otf" : font_asset.format = ModdableAsset.FontAsset.FORMAT.OTF
	
	font_asset.uid = StringName("f" + FileAccess.get_md5(font_filepath))
	return font_asset
