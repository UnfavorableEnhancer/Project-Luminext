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
}

## All used in current sequence segment sounds.
var current_sound_effects : Dictionary[StringName, SkinSFX] = {
}

## Sounds which will be used for UID's which are completely missing in **sounds**.[br]
# TODO : Put placeholders file paths here
static var placeholder_sounds : Dictionary[StringName, SkinSFX] = {
	#&"level_up" : SkinSFX.new(),
}

## Loads sounds data from passed FileAccess **(must be used only by SkinData.load)**
func load(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Saves sounds data to passed FileAccess **(must be used only by SkinData.load)**
func save(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Loads all sounds with assets from passed [SkinAssetData]
func prepare(asset_data : SkinAssetData) -> void:
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
	
	
	## Constructor. If texture path is passed, creates own texture assets from it and creates sprite
	## NOTE : Should be used only for placeholder blocks
	func _init(audio_filepath : String = "") -> void:
		if audio_filepath.is_empty() : return
		
		var our_audio_asset : ModdableAsset.AudioAsset = AssetSerializer.process_audio(audio_filepath)
		AssetLoader.load_audio_stream(our_audio_asset)
		
		audio_assets[our_audio_asset.uid] = our_audio_asset
		streams.append(our_audio_asset.stream)
		volumes.append(0.0)
		pitches.append(0.0)


	## Copies all needed [AudioAssets] from passed [SkinAssetData]
	func load_assets(asset_data : SkinAssetData) -> void:
		for audio_asset_uid : StringName in audio_assets.keys():
			# If some audio asset is missing, use placeholder audio stream instead
			if not asset_data.audio.has(audio_asset_uid):
				if not SkinSFXData.placeholder_sounds.has(uid) : return
				streams = SkinSFXData.placeholder_sounds[uid].streams
				volumes = SkinSFXData.placeholder_sounds[uid].volumes
				pitches = SkinSFXData.placeholder_sounds[uid].pitches
				return
			
			audio_assets[audio_asset_uid] = asset_data.audio[audio_asset_uid]
		
		set_streams()


	## Creates proper audio streams
	func set_streams() -> void:
		streams.clear()
		for audio_asset : ModdableAsset.AudioAsset in audio_assets.values():
			streams.append(audio_asset.stream)


# TODO : Add function for passing streams in AudioBus
