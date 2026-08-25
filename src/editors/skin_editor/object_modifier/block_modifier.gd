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
## Contains all functions to edit SkinBlock instance, identified by passed preset ID, ID and index
##
class_name SEBlockModifier

signal id_changed
signal values_changed
signal animation_changed

var preset_id : String = &"none"
var id : StringName = ""
var index : int = 0

var asset_data : SkinAssetData = null
var block_data : SkinBlockData = null
var undo_manager : EditorHistoryManager = null


func _init(new_preset_id : String, new_id : StringName, new_index : int, new_block_data : SkinBlockData) -> void:
	preset_id = new_preset_id
	id = new_id
	index = new_index
	block_data = new_block_data
	
	_find_block()

## Returns currently active block instance at current preset ID, ID and index.
func _find_block() -> SkinBlockData.SkinBlock:
	return block_data.blocks_presets[preset_id].blocks[id][index]


## Changes block ID and it's index in corresponding array inside current block preset.[br]
## If index == -1, block will be moved to the end of new array inside current block preset.
func set_id_and_index(new_id : StringName, new_index : int = -1) -> void:
	var block : SkinBlockData.SkinBlock = _find_block()
	if block.id == new_id : return
	
	undo_manager.track(
		self,
		set_id_and_index.bind(id, index),
		set_id_and_index.bind(new_id)
	)
	
	var new_blocks_array : Array = block_data.blocks_presets[preset_id].blocks[new_id]
	if new_index == -1 : new_index = new_blocks_array.size()
	
	var original_blocks_array : Array = block_data.blocks_presets[preset_id].blocks[id]
	original_blocks_array.remove_at(index)
	for i : int in range(index, original_blocks_array.size()) : original_blocks_array[i].index = i
	
	block.id = new_id
	id = new_id
	block.index = new_index
	index = new_index
	new_blocks_array.insert(new_index, block)
	for i : int in range(new_index, new_blocks_array.size()) : new_blocks_array[i].index = i
	
	id_changed.emit()

## Sets value at given index 'at' at block animation pattern array
func set_animation_pattern(at : int, on : bool) -> void:
	var block : SkinBlockData.SkinBlock = _find_block()
	if block.animation_timing[at] == on : return
	
	var old_value : bool = block.animation_timing[at]
	undo_manager.track(
		self,
		set_animation_pattern.bind(at, old_value),
		set_animation_pattern.bind(at, on)
	)
	block.animation_timing[at] = on
	
	values_changed.emit()

## Sets block animation loop state
func set_animation_loop(new_state : bool) -> void:
	var block : SkinBlockData.SkinBlock = _find_block()
	if block.loop_animation == new_state : return
	
	var old_value : bool = block.loop_animation
	undo_manager.track(
		self,
		set_animation_loop.bind(old_value),
		set_animation_loop.bind(new_state)
	)
	block.loop_animation = new_state
	
	values_changed.emit()

## Sets block animation FPS value
func set_animation_fps(new_value : int) -> void:
	var block : SkinBlockData.SkinBlock = _find_block()
	if block.animation_fps == new_value : return
	
	var old_value : int = block.animation_fps
	undo_manager.track(
		self,
		set_animation_fps.bind(old_value),
		set_animation_fps.bind(new_value)
	)
	block.animation_fps = new_value
	
	values_changed.emit()

## Adds frames to block animation
func add_animation_frames(texture_asset_uids : Array[StringName]) -> void:
	var block : SkinBlockData.SkinBlock = _find_block()
	
	for texture_uid : StringName in texture_asset_uids:
		block.frames.append(texture_uid)
		block.sprite_frames.add_frame(&"default", asset_data.textures[texture_uid].texture)
	
	undo_manager.track(
		self,
		remove_animation_frames.bind(range(block.frames.size() - 1, block.frames.size() - texture_asset_uids.size() - 1, -1)), 
		add_animation_frames.bind(texture_asset_uids)
	)
	
	animation_changed.emit()

## Inesrts frame to block animation at given position 'at'
func insert_animation_frame(at : int, texture_asset_uid : StringName) -> void:
	var block : SkinBlockData.SkinBlock = _find_block()
	
	block.frames.insert(at, texture_asset_uid)
	block.sprite_frames.add_frame(&"default", asset_data.textures[texture_asset_uid].texture, 1.0, at)
	
	animation_changed.emit()

## Replaces existing frame of block animation at given position 'at'
func replace_animation_frame(at : int, texture_asset_uid : StringName) -> void:
	var block : SkinBlockData.SkinBlock = _find_block()
	
	var original_texture_asset_uid : StringName = block.frames[at]
	undo_manager.track(
		self,
		replace_animation_frame.bind(at, original_texture_asset_uid), 
		replace_animation_frame.bind(at, texture_asset_uid)
	)
	
	block.frames[at] = texture_asset_uid
	block.sprite_frames.set_frame(&"default", at, asset_data.textures[texture_asset_uid].texture)
	
	animation_changed.emit()

## Move frame of block animation from one position to other
func move_animation_frame(from : int, to : int) -> void:
	var block : SkinBlockData.SkinBlock = _find_block()
	
	var texture_buff : Texture2D = block.sprite_frames.get_frame_texture(&"default", to)
	var texture_uid_buff : StringName = block.frames[to]
	
	block.sprite_frames.set_frame(&"default", to, block.sprite_frames.get_frame_texture(&"default", from))
	block.sprite_frames.set_frame(&"default", from, texture_buff)
	
	block.frames[to] = block.frames[from]
	block.frames[from] = texture_uid_buff
	
	undo_manager.track(
		self,
		move_animation_frame.bind(to, from), 
		move_animation_frame.bind(from, to)
	)
	
	animation_changed.emit()

## Removes frame of block animation in given position 'at'
func remove_animation_frame(at : int) -> void:
	var block : SkinBlockData.SkinBlock = _find_block()
	
	var frame_texture_asset_uid : StringName = block.frames[at]
	
	block.frames.remove_at(at)
	block.sprite_frames.remove_frame(&"default", at)
	
	undo_manager.track(
		self,
		insert_animation_frame.bind(at, frame_texture_asset_uid),
		remove_animation_frame.bind(at)
	)
	
	animation_changed.emit()

## Removes frames of block animation in given 'range_'
func remove_animation_frames(range_ : Array) -> void:
	var block : SkinBlockData.SkinBlock = _find_block()
	
	for i : int in range_: 
		block.frames.remove_at(i)
		block.sprite_frames.remove_frame(&"default", i)
	
	animation_changed.emit()

## Removes all frames of block animation
func remove_all_animation_frames() -> void:
	var block : SkinBlockData.SkinBlock = _find_block()
	
	var frame_texture_asset_uids : Array[StringName] = block.frames
	
	block.frames.clear()
	block.sprite_frames.clear(&"default")
	
	undo_manager.track(
		self,
		add_animation_frames.bind(frame_texture_asset_uids),
		remove_all_animation_frames
	)
	
	animation_changed.emit()
