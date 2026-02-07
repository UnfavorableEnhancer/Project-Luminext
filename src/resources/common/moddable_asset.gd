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
## Describes all moddable media resources (textures, audio, video and font) 
## for use in various moddable data structures ([SkinAssetData], [SkinMetadata] and etc.)[br]
## All assets can be serialized into byte array + format byte + uid objects by [AssetSerializer]
## for future saving/loading in moddable data structure,[br]
## and then be deserialized into correct Godot resources by [AssetLoader].
##
class_name ModdableAsset

enum ASSET_TYPE {
	TEXTURE,
	AUDIO,
	VIDEO,
	FONT
}

class TextureAsset:
	## Enum of supported image formats
	enum FORMAT {
		UNKNOWN,
		PNG,
		JPEG,
		BMP
	}
	
	var texture : Texture = null
	var raw_bytes : PackedByteArray
	var format : FORMAT = FORMAT.UNKNOWN
	var uid : StringName = &""

class AudioAsset:
	## Enum of supported audio stream formats
	enum FORMAT {
		UNKNOWN,
		WAV,
		OGG,
		MP3
	}
	
	var stream : AudioStream = null
	var raw_bytes : PackedByteArray
	var format : FORMAT = FORMAT.UNKNOWN
	var uid : StringName = &""

class VideoAsset:
	## Enum of supported video stream formats
	enum FORMAT {
		UNKNOWN,
		WEBM,
		MP4
	}
	
	var stream : FFmpegVideoStream = null
	var raw_bytes : PackedByteArray
	var format : FORMAT = FORMAT.UNKNOWN
	var uid : StringName = &""

class FontAsset:
	## Enum of supported font formats
	enum FORMAT {
		UNKNOWN,
		TTF,
		OTF
	}
	
	var font : FontFile = null
	var raw_bytes : PackedByteArray
	var format : FORMAT = FORMAT.UNKNOWN
	var uid : StringName = &""
