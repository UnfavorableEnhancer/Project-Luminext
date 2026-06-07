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
## Contains all skin blocks which can be used by game field.[br]
## Each block contains unique animated sprite sheet.
##
class_name SkinBlockData

signal current_blocks_changed ## Emitted when current block set is updated

## All avaiable blocks.[br]
## This dictionary contains several "variants" (indicated by int), each containing own dictionary of blocks arrays.[br]
## Each blocks array in variant dictionary is assigned to specific block UID, which gives the game an idea when this block should be used.[br]
## If array has multiple blocks, game will select random one on spawn.[br]
## If on variant switch, there aren't any blocks of some type in next variant, game will keep working with previous variant blocks.
var blocks : Dictionary[int, Dictionary] = {
	0 : {
		&"red" : [], # Red block
		&"white" : [], # White block
		&"green" : [], # Green block
		&"purple" : [], # Purple block
		&"chain" : [], # Chain block overlay (chains and removes all adjacent same-colored blocks)
		&"merge" : [], # Merge block overlay (turns all blocks in area into own color)
		&"wipe" : [], # Wipe block overlay (removes all same-colored blocks in area)
		&"column" : [], # Column block overlay (turns all blocks on same column into own color)
		&"row" : [], # Row block overlay (turns all blocks on same row into own color)
		&"multi" : [], # Multi block (can be squared with any color)
		&"garbage" : [], # Garbage block (erased when adjacent blocks are erased)
		&"dark" : [], # Dark block (cannot be erased)
		&"ready" : [], # Ready to delete block overlay
		&"scan" : [], # Scanned by timeline block overlay
		&"erase" : [] # Block erase animation overlay
	}
}

## All currently used by the game blocks.
var current_blocks : Dictionary[StringName, Array] = {
	&"red" : [], 
	&"white" : [],
	&"green" : [],
	&"purple" : [],
	&"chain" : [],
	&"merge" : [],
	&"wipe" : [],
	&"column" : [],
	&"row" : [],
	&"multi" : [],
	&"garbage" : [],
	&"dark" : [],
	&"ready" : [],
	&"scan" : [],
	&"erase" : []
}

var currently_selected_variants : Array[int] = [0] ## Currently selected by [SkinSequenceData] block variants

## Blocks which will be used for UID's which are completely missing in **blocks** or special option is enabled in settings.[br]
## Each array contains two variants: standard (index 0) and colorblind-friendly (index 1)
# TODO : Put placeholders file paths here
static var placeholder_blocks : Dictionary[StringName, Array] = {
	&"red" : [],
	&"white" : [],
	&"green" : [],
	&"purple" : [],
	&"chain" : [],
	&"merge" : [],
	&"wipe" : [],
	&"column" : [],
	&"row" : [],
	&"multi" : [],
	&"garbage" : [],
	&"dark" : [],
	&"ready" : [],
	&"scan" : [],
	&"erase" : []
}

## Loads all blocks data from passed FileAccess, which has valid skin file opened
func load(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Saves all blocks data to passed FileAccess, which has valid skin file opened
func save(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Loads all blocks with assets from passed [SkinAssetData]
func load_assets(asset_data : SkinAssetData) -> void:
	for block_array : Array in blocks.values():
		for block : SkinBlock in block_array:
			block.load_assets(asset_data)


## Called by [SkinSequenceData] when selected block variants has changed, so current blocks would be switched with blocks prepared for specified variants.
func select_variants(variant_ids : Array[int]) -> void:
	var touched_ids : Array[StringName] = []
	
	for variant_id : int in variant_ids:
		var next_variant_blocks : Dictionary = blocks[variant_id]
		for block_id : String in next_variant_blocks.keys():
			var blocks_array : Array = next_variant_blocks[block_id]
			if blocks_array.is_empty() : continue
			
			# Reset current blocks array only if we found some new blocks in passed variant
			if not block_id in touched_ids : current_blocks[block_id] = []
			touched_ids.append(block_id)
			
			current_blocks[block_id].append_array(blocks_array)
	
	# Put blocks placeholders into still empty ID's
	for block_id : String in placeholder_blocks.keys():
		if not current_blocks.has(block_id) or current_blocks[block_id].is_empty():
			current_blocks[block_id] = placeholder_blocks[block_id]
	
	currently_selected_variants = variant_ids
	current_blocks_changed.emit()


class SkinBlock:
	var id : StringName = &"none" ## Block ID, used by game to determine when to use it
	var index : int = 0 ## Index inside array containing this block
	var variant_id : int = 0 ## Data variant number on which this block will be used
	
	var sprite_frames : SpriteFrames = SpriteFrames.new() ## SpriteFrames instance which game can use for block instance
	
	var animation_timing : Array[bool] = [false, false, false, false,
										false, false, false, false,
										false, false, false, false,
										false, false, false, false] ## Array of beats on which block animation should start playing
	var loop_animation : bool = false : set = _set_animation_loop ## If true, this block animation will run from start and loop infinitely
	var animation_fps : int = 30 : set = _set_animation_fps ## Animation frames per second
	
	## Contains all frames texture assets UID's used by this block sprite
	var frames : Array[StringName] = []
	
	func _set_animation_loop(value : bool) -> void:
		loop_animation = value
		if sprite_frames : sprite_frames.set_animation_loop(&"default", value)

	func _set_animation_fps(value : int) -> void:
		animation_fps = value
		if sprite_frames : sprite_frames.set_animation_speed(&"default", value)
	
	
	## Constructor. If texture path is passed, creates own texture assets from it and creates sprite
	## WARNING : Should be used only for placeholder blocks, as it doesn't put created texture assets into SkinAssetData
	func _init(texture_filepath : String = "") -> void:
		sprite_frames.set_animation_loop(&"default", false)
		sprite_frames.set_animation_speed(&"default", 30)
		
		if texture_filepath.is_empty() : return
		
		sprite_frames = SpriteFrames.new()
		
		var our_texture_assets : Array[ModdableAsset.TextureAsset] = AssetSerializer.process_spritesheet(texture_filepath)
		for texture_asset : ModdableAsset.TextureAsset in our_texture_assets:
			AssetLoader.load_texture(texture_asset)
			sprite_frames.add_frame(&"default", texture_asset.texture)
		
		sprite_frames.set_animation_speed(&"default", animation_fps)
		sprite_frames.set_animation_loop(&"default", loop_animation)


	## Copies all frames [TextureAssets] from passed [SkinAssetData]
	func load_assets(asset_data : SkinAssetData) -> void:
		sprite_frames = SpriteFrames.new()
		
		for texture_asset_uid : StringName in frames:
			# If some texture asset is missing, use placeholder block sprite instead
			if not asset_data.textures.has(texture_asset_uid): 
				if not SkinBlockData.placeholder_blocks.has(id) : return
				sprite_frames = SkinBlockData.placeholder_blocks[id][0].sprite_frames
				return
			
			var texture_asset : ModdableAsset.TextureAsset = asset_data.textures[texture_asset_uid]
			sprite_frames.add_frame(&"default", texture_asset.texture)
		
		sprite_frames.set_animation_speed(&"default", animation_fps)
		sprite_frames.set_animation_loop(&"default", loop_animation)


	## Loads block data from passed FileAccess, which has valid skin file opened
	func load(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK


	## Saves block data to passed FileAccess, which has valid skin file opened
	func save(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK
