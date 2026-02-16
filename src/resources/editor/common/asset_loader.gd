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
## Loads passed [ModdableAsset] sub-class into correct Godot resource in order to be used by engine.
##
class_name AssetLoader


## Deserializes raw texture asset into [PortableCompressedTexture2D], which is then stored in **texture_asset.texture** variable.[br]
## Returns true on success.
static func load_texture(texture_asset : ModdableAsset.TextureAsset) -> bool:
	var image : Image = Image.new()
	var image_loader : Callable
	
	match texture_asset.format:
		ModdableAsset.TextureAsset.FORMAT.UNKNOWN : return false
		ModdableAsset.TextureAsset.FORMAT.PNG : image_loader = image.load_png_from_buffer
		ModdableAsset.TextureAsset.FORMAT.JPEG : image_loader = image.load_jpg_from_buffer
		ModdableAsset.TextureAsset.FORMAT.BMP : image_loader = image.load_bmp_from_buffer
	
	image_loader.call(texture_asset.raw_bytes)
	image.fix_alpha_edges()
	
	if texture_asset.texture == null : texture_asset.texture = PortableCompressedTexture2D.new()
	texture_asset.texture.create_from_image(image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
	return true


## Deserializes raw audio stream asset into [AudioStream], which is then stored in **audio_asset.stream** variable.[br]
## Returns true on success.
static func load_audio_stream(audio_asset : ModdableAsset.AudioAsset) -> bool:
	var audio_stream : AudioStream
	match audio_asset.format:
		ModdableAsset.AudioAsset.FORMAT.UNKNOWN : return false
		ModdableAsset.AudioAsset.FORMAT.WAV : audio_stream = AudioStreamWAV.new()
		ModdableAsset.AudioAsset.FORMAT.OGG : audio_stream = AudioStreamOggVorbis.new()
		ModdableAsset.AudioAsset.FORMAT.MP3 : audio_stream = AudioStreamMP3.new()
	
	audio_asset.stream = audio_stream
	audio_asset.stream.load_from_buffer(audio_stream.raw_audio)
	return true


## Deserializes raw video stream asset into [FFmpegVideoStream], which is then stored in **video_asset.stream** variable.[br]
## Also creates video file in Consts.CACHE_DIR for playback.[br]
## Returns true on success.
static func load_video_stream(video_asset : ModdableAsset.VideoAsset) -> bool:
	var format_extension : String
	match video_asset.format:
		ModdableAsset.VideoAsset.FORMAT.UNKNOWN : return false
		ModdableAsset.VideoAsset.FORMAT.WEBM : format_extension = ".webm"
		ModdableAsset.VideoAsset.FORMAT.MP4 : format_extension = ".mp4"
	
	var video_file_path : String = Consts.CACHE_DIR + video_asset.uid + format_extension
	var video_file : FileAccess = FileAccess.open(video_file_path, FileAccess.WRITE)
	if not video_file.store_buffer(video_asset.raw_bytes) : return false
	video_file.close()
	
	video_asset.stream = FFmpegVideoStream.new()
	video_asset.stream.file = video_file_path
	return true


## Deserializes raw font asset into [FontFile], which is then stored in **font_asset.font** variable.[br]
## Returns true on success.
static func load_font(font_asset : ModdableAsset.FontAsset) -> bool:
	var format_extension : String
	match font_asset.format:
		ModdableAsset.FontAsset.FORMAT.UNKNOWN : return false
		ModdableAsset.FontAsset.FORMAT.TTF : format_extension = ".ttf"
		ModdableAsset.FontAsset.FORMAT.OTF : format_extension = ".otf"
	
	var font_file_path : String = Consts.CACHE_DIR + font_asset.uid + format_extension
	var font_file : FileAccess = FileAccess.open(font_file_path, FileAccess.WRITE)
	if not font_file.store_buffer(font_asset.raw_bytes) : return false
	
	if font_asset.font == null : font_asset.font = FontFile.new()
	if font_asset.font.load_dynamic_font(font_file_path) != OK : return false
	
	font_file.close()
	@warning_ignore("return_value_discarded")
	DirAccess.remove_absolute(font_file_path)
	
	return true
