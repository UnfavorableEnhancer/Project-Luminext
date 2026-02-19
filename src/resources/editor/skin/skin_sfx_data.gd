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
## Contains all skin sound effects which can be used by game events.
##
class_name SkinSFXData

## All avaiable sound types.[br]
## Each array can store multiple sounds effects under same UID, but they all must have different **segment ID**.
var sound_effects : Dictionary[StringName, Array] = {
	&"move_left" : [], # Played when piece moves left
	&"move_right" : [], # Played when piece moves right
	&"rotate_left" : [],  # Played when piece rotates left
	&"rotate_right" : [], # Played when piece rotates right
	&"dash_left" : [], # Played when piece dashes left
	&"dash_right" : [], # Played when piece dashes right
	&"land" : [], # Played when piece lands
	&"square_blast" : [], # Played when square is erased by timeline and explodes
	&"square_create" : [], # Played when square is created
	&"timeline_pass" : [], # Played when timeline passes thru blocks
	&"timeline_scan" : [], # Played when timeline scans erasable blocks
	&"4x_bonus" : [], # Played when 4x bonus occurs
	&"special_bonus" : [], # Played when some special bonus (all clear, single color) occurs
	&"level_up" : [] # Played when next level is reached
}

## All used in current sequence segment sound effects.
var current_sound_effects : Dictionary[StringName, SkinSFX] = {
	&"move_left" : null,
	&"move_right" : null,
	&"rotate_left" : null,
	&"rotate_right" : null,
	&"dash_left" : null,
	&"dash_right" : null,
	&"land" : null,
	&"square_blast" : null,
	&"square_create" : null,
	&"timeline_pass" : null,
	&"timeline_scan" : null,
	&"4x_bonus" : null,
	&"special_bonus" : null,
	&"level_up" : null
}


## Loads sounds data from passed FileAccess, which has valid skin file opened
func load(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Saves sounds data to passed FileAccess, which has valid skin file opened
func save(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Loads all sounds with assets from passed [SkinAssetData]
func load_assets(asset_data : SkinAssetData) -> void:
	for sound_effects_array : Array in sound_effects.values():
		for sound_effect : SkinSFX in sound_effects_array:
			sound_effect.load_assets(asset_data)


## Called by [SkinSequenceData] when segment changes, so current sound effects would be switched with sound effects prepared for specified segment.
func select_segment(segment_id : int) -> void:
	for uid : String in sound_effects.keys():
		for sound : SkinSFX in sound_effects[uid]:
			if sound.segment_id == segment_id:
				current_sound_effects[uid] = sound
				sound.set_streams()


class SkinSFX:
	var uid : StringName = &"none" ## Unique ID used by certain game events to make sound effect
	var segment_id : int = 0 ## Skin sequence segment on which this sound effect will be used
	
	## Contains all audio assets used by this sound effect
	var audio_assets : Dictionary[StringName, ModdableAsset.AudioAsset] = { 
		# audio_asset_uid : audio_asset
	}
	
	## All audio assets UID's, which streams this sound effect will use
	var streams : Array[StringName] = []
	## All streams volumes
	var volumes : Array[float] = []
	## All streams pitch scales
	var pitches : Array[float] = []


	## Copies all needed [AudioAsset] from passed [SkinAssetData]
	func load_assets(asset_data : SkinAssetData) -> void:
		for audio_asset_uid : StringName in audio_assets.keys():
			if not asset_data.audio.has(audio_asset_uid):
				return
			
			audio_assets[audio_asset_uid] = asset_data.audio[audio_asset_uid]
		
		set_streams()


	## Loads sound effect data from passed FileAccess, which has valid skin file opened
	func load(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK


	## Saves sound effect data to passed FileAccess, which has valid skin file opened
	func save(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK


	# TODO : Add function for passing streams in AudioBus
	func set_streams() -> void:
		pass
