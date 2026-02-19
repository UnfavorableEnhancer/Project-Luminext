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
## Each array can store multiple sounds under same UID. If multiple sounds have same UID and segment ID, game will pick random one of those
var sound_effects : Dictionary[StringName, Array] = {
	&"move_left" : [],
	&"move_right" : [],
	&"rotate_left" : [],
	&"rotate_right" : [],
	&"dash_left" : [],
	&"dash_right" : [],
	&"drop" : [],
	&"square_blast" : [],
	&"square_create" : [],
	&"timeline_pass" : [],
	&"timeline_scan" : [],
	&"4x_bonus" : [],
	&"special_bonus" : [],
	&"level_up" : []
}

## All used in current sequence segment sounds.
var current_sound_effects : Dictionary[StringName, SkinSFX] = {
	&"move_left" : null,
	&"move_right" : null,
	&"rotate_left" : null,
	&"rotate_right" : null,
	&"dash_left" : null,
	&"dash_right" : null,
	&"drop" : null,
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


## Called by [SkinSequenceData] when segment changes, so current blocks would be switched with blocks prepared for specified segment.
func select_segment(segment_id : int) -> void:
	var changed_uids : Array[StringName] = []
	
	for uid : String in sound_effects.keys():
		for sound : SkinSFX in sound_effects[uid]:
			if sound.segment_id == segment_id:
				if not uid in changed_uids and current_sound_effects.has(uid): 
					changed_uids.append(uid)
					current_sound_effects.erase(uid)
				
				if not current_sound_effects.has(uid):
					changed_uids.append(uid)
				
				current_sound_effects[uid] = sound


class SkinSFX:
	var uid : StringName = &"none" ## Unique ID used by certain game events to make sound effect
	var segment_id : int = 0 ## Skin sequence segment on which this sound effect will be used
	
	## Contains all audio assets used by this sound effect
	var audio_assets : Dictionary[StringName, ModdableAsset.AudioAsset] = { 
		# audio_asset_uid : audio_asset
	}
	
	## All audio streams which this sound effect can use
	var streams : Array[AudioStream] = []
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


	## Creates proper audio streams
	func set_streams() -> void:
		streams.clear()
		for audio_asset : ModdableAsset.AudioAsset in audio_assets.values():
			streams.append(audio_asset.stream)


	## Loads sound effect data from passed FileAccess, which has valid skin file opened
	func load(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK


	## Saves sound effect data to passed FileAccess, which has valid skin file opened
	func save(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK

# TODO : Add function for passing streams in AudioBus
