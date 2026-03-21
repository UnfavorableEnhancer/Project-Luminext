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

## All avaiable sound effects.[br]
## This dictionary contains several "variants" (indicated by int), each containing own dictionary of sounds arrays.[br]
## Each sounds array in variant dictionary is assigned to specific sound UID, which gives the game an idea when this sound effect should be used.[br]
## If array has multiple sounds, game will select random one on spawn.[br]
## If on variant switch, there aren't any sounds of some type in next variant, game will keep working with previous variant sound effects.
var sounds : Dictionary[int, Dictionary] = {
	0 : {
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
}

## All used in current sequence segment sound effects.
var current_sounds : Dictionary[StringName, Array] = {
	&"move_left" : [],
	&"move_right" : [],
	&"rotate_left" : [],
	&"rotate_right" : [],
	&"dash_left" : [],
	&"dash_right" : [],
	&"land" : [],
	&"square_blast" : [],
	&"square_create" : [],
	&"timeline_pass" : [],
	&"timeline_scan" : [],
	&"4x_bonus" : [],
	&"special_bonus" : [],
	&"level_up" : []
}


## Loads sounds data from passed FileAccess, which has valid skin file opened
func load(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Saves sounds data to passed FileAccess, which has valid skin file opened
func save(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Loads all sounds with assets from passed [SkinAssetData]
func load_assets(asset_data : SkinAssetData) -> void:
	for sounds_array : Array in sounds.values():
		for sound : SkinSFX in sounds_array:
			sound.load_assets(asset_data)


## Called by [SkinSequenceData] when variant changes, so current sound effects would be switched with sounds prepared for specified variant.
func select_variant(variant_id : int) -> void:
	var next_variant_sounds : Dictionary = sounds[variant_id]
	for uid : String in next_variant_sounds.keys():
		var sounds_array : Array = next_variant_sounds[uid]
		if sounds_array.is_empty() : continue
		
		current_sounds[uid] = sounds_array


class SkinSFX:
	var uid : StringName = &"none" ## Unique ID used by certain game events to make sound effect
	var index : int = 0 ## Index inside array containing this sound effect
	var variant_id : int = 0 ## Data variant number on which this sound effect will be used
	
	var audio_asset : ModdableAsset.AudioAsset = null ## Used audio asset
	var audio_asset_uid : StringName = &"" ## Used audio asset UID
	var volume : float = 0.0 ## Audio stream volume
	var pitch : float = 0.0 ## Audio stream pitch


	## Copies all needed [AudioAsset] from passed [SkinAssetData]
	func load_assets(asset_data : SkinAssetData) -> void:
		if not asset_data.audio.has(audio_asset_uid) : return
		
		# TODO : Add function for passing streams into AudioBus


	## Loads sound effect data from passed FileAccess, which has valid skin file opened
	func load(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK


	## Saves sound effect data to passed FileAccess, which has valid skin file opened
	func save(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK
