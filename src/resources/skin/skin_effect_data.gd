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
## Contains all effects which are spawned by game on certain events (ex. square creation or timeline scan).
##
class_name SkinEffectData

## All avaiable visual effects.[br]
## This dictionary contains several "presets" (indicated by int), each containing own dictionary of effects arrays.[br]
## Each effects array in presets dictionary is assigned to specific effect ID, which defines when this effect should be used.[br]
## If array has multiple effects, game will select random one on spawn.[br]
## If on preset change, there aren't any effects of some type in the next preset, game will keep working with previous preset effects.
var effects : Dictionary[int, Dictionary] = {
	0 : {
		&"red_square" : [], # Red square
		&"white_square" : [], # White square
		&"green_square" : [], # Green square
		&"purple_square" : [], # Purple square
		&"square_blast" : [], # Spawned when timeline erases square
		&"square_scan" : [], # Spawned when timeline scans square
		&"4x_bonus_1" : [], # Spawned on 4X bonus
		&"4x_bonus_2" : [], # Spawned on 4X bonus (when combo == 2)
		&"4x_bonus_3" : [], # Spawned on 4X bonus (when combo == 3) 
		&"4x_bonus_4" : [], # Spawned on 4X bonus (when combo >= 4)
		&"rotate_left" : [], # Spawned when piece rotates left
		&"rotate_right" : [], # Spawned when piece rotates right
		&"move_left" : [], # Spawned when piece moves left
		&"move_right" : [], # Spawned when piece moves right
		&"dash_left" : [], # Spawned when piece dashes left
		&"dash_right" : [], # Spawned when piece dashes right
		&"piece_land" : [] # Spawned when piece lands
	}
}

## All used in current sequence segment effects.
var current_effects : Dictionary[StringName, Array] = {
	&"red_square" : [],
	&"white_square" : [],
	&"green_square" : [],
	&"purple_square" : [],
	&"square_blast" : [],
	&"square_scan" : [],
	&"4x_bonus_1" : [],
	&"4x_bonus_2" : [],
	&"4x_bonus_3" : [],
	&"4x_bonus_4" : [],
	&"rotate_left" : [],
	&"rotate_right" : [],
	&"move_left" : [],
	&"move_right" : [],
	&"dash_left" : [],
	&"dash_right" : [],
	&"piece_land" : []
}

## Loads effects data from passed FileAccess, which has valid skin file opened
func load(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Saves effects data to passed FileAccess, which has valid skin file opened
func save(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Loads all effects with assets from passed [SkinAssetData]
func load_assets(asset_data : SkinAssetData) -> void:
	for effects_array : Array in effects.values():
		for effect : SkinEffect in effects_array:
			effect.load_assets(asset_data)


## Called by [SkinSequenceData] when preset changes, so current visual effects would be switched with effects prepared for specified preset.
func select_preset(preset_id : int) -> void:
	var next_preset_effects : Dictionary = effects[preset_id]
	for effect_id : String in next_preset_effects.keys():
		var effects_array : Array = next_preset_effects[effect_id]
		if effects_array.is_empty() : continue
		
		current_effects[effect_id] = effects_array


class SkinEffect:
	var id : StringName = &"none" ## Visual effect identifier, which defines when and how this effect will be spawned
	var index : int = 0 ## Index inside array containing this effect
	var preset_id : int = 0 ## Preset number on which this visual effect will be used
	
	var scene : ModdableScene = ModdableScene.new()
	var animation : Animation = Animation.new()


	## Copies all needed for effect scene [ModdableAsset] from passed [SkinAssetData]
	func load_assets(asset_data : SkinAssetData) -> void:
		if not scene.load_assets(asset_data) : 
			scene.queue_free()
			scene = null


	## Prepares effect scenery for being cloned by game and used
	func _prepare_scenery() -> void:
		scene.build()
		
		var animation_player : AnimationPlayer = AnimationPlayer.new()
		animation_player.name = "Animation"
		animation_player.get_animation_library(&"").add_animation("start", animation)
		
		scene.add_child(animation_player)


	## Loads effect data from passed FileAccess, which has valid skin file opened
	func load(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK


	## Saves effect data to passed FileAccess, which has valid skin file opened
	func save(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK
