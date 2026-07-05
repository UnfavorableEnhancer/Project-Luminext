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

signal current_blocks_changed ## Emitted when current block preset changes


## All avaiable blocks presets.
var blocks_presets : Dictionary[int, SkinBlockPreset] = {
	0 : SkinBlockPreset.new()
}

## Currently used by game blocks preset.
var current_blocks_preset : SkinBlockPreset = null

## Blocks which will be used for ID's which are completely missing in current blocks preset or when special option is enabled in settings.[br]
## Each array contains two presets: standard (index 0) and colorblind-friendly (index 1)
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

## Loads all blocks data from passed FileAccess, which has valid skin file opened.
func load(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Saves all blocks data to passed FileAccess, which has valid skin file opened.
func save(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Loads all blocks with assets from passed [SkinAssetData].
func load_assets(asset_data : SkinAssetData) -> void:
	for block_preset : SkinBlockPreset in blocks_presets.values():
		for block_array : Array in block_preset.blocks.values():
			for block : SkinBlock in block_array:
				block.load_assets(asset_data)


## Changes currently used blocks preset.
func select_preset(preset_id : int) -> void:
	current_blocks_preset = blocks_presets[preset_id]
	
	# Put blocks placeholders into still empty ID's
	for block_id : StringName in placeholder_blocks.keys():
		if current_blocks_preset.blocks[block_id].is_empty():
			current_blocks_preset.blocks[block_id].append(placeholder_blocks[block_id])
	
	current_blocks_changed.emit()


##
## Contains arrays of [SkinBlock]'s of different types, which are used by the game to spawn blocks.[br]
## A random block from array will be used on block spawn.
## 
class SkinBlockPreset:
	var id : int = 0 : set = _set_id
	var blocks : Dictionary[StringName, Array] = {
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
	
	func _set_id(value : int) -> void:
		id = value
		var block_ids_array : Array[StringName] = blocks.keys()
		for block_id : StringName in block_ids_array:
			var blocks_array : Array = blocks[block_id]
			for block : SkinBlock in blocks_array:
				block.preset_id = value
	
	
	## Creates a unique clone of this blocks preset data.
	func duplicate() -> SkinBlockPreset:
		return clone(self)
	
	## Creates a unique clone of passed blocks preset data.
	static func clone(blocks_preset : SkinBlockPreset) -> SkinBlockPreset:
		var clone_blocks_preset : SkinBlockPreset = SkinBlockPreset.new()
		clone_blocks_preset.id = blocks_preset.id
		
		var block_ids_array : Array[StringName] = blocks_preset.blocks.keys()
		for block_id : StringName in block_ids_array:
			var blocks_array : Array = blocks_preset.blocks[block_id]
			for block : SkinBlock in blocks_array:
				var block_clone : SkinBlock = SkinBlock.clone(block)
				block_clone.index = clone_blocks_preset.blocks[block_id].size()
				clone_blocks_preset.blocks[block_id].append(block_clone)
		
		return clone_blocks_preset

	## Loads blocks preset data from passed FileAccess, which has valid skin file opened
	func load(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK

	## Saves blocks preset data to passed FileAccess, which has valid skin file opened
	func save(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK


##
## Contains all graphics and animation settings for single block instance.
##
class SkinBlock:
	var id : StringName = &"none" ## Block identifier, which defines for what block types this block texture will be used
	var index : int = 0 ## Index inside array containing this block
	var preset_id : int = 0 ## Preset number on which this block will be used
	
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


	## Creates a unique clone of this block data.
	func duplicate() -> SkinBlock:
		return clone(self)

	
	## Creates a unique clone of passed block data.
	static func clone(block : SkinBlock) -> SkinBlock:
		var clone_block : SkinBlock = SkinBlock.new()
		clone_block.id = block.id
		clone_block.preset_id = block.preset_id
		clone_block.animation_timing = block.animation_timing
		
		clone_block.frames = block.frames
		clone_block.sprite_frames = SpriteFrames.new()
		
		for i : int in block.sprite_frames.get_frame_count(&"default"):
			clone_block.sprite_frames.add_frame(&"default", block.sprite_frames.get_frame_texture(&"default", i))
		
		clone_block.animation_fps = block.animation_fps
		clone_block.loop_animation = block.loop_animation
		
		return clone_block


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
