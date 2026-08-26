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

extends EditorSubTree
##
## Shows all skin blocks and allows to edit them or add new ones
##
class_name SEBlocksSubTree

var block_data : SkinBlockData ## Currently displayed block data

var item_object_to_select : Variant ## Item with object specified here will be selected on next subtree rebuild


func build(new_data : Variant) -> bool:
	if not new_data is SkinBlockData : return false
	block_data = new_data
	
	var item_to_select : TreeItem = null
	
	for preset : SkinBlockData.SkinBlockPreset in block_data.blocks_presets.values():
		var preset_item_meta : EditorTreeItemMetadata = EditorTreeItemMetadata.new(SkinEditorTree.ITEM_TYPE.BLOCK_PRESET, self, preset)
		var preset_item_text : String = preset.id
		var preset_item  : TreeItem = _create_item(preset_item_text, SkinEditorTree.tree_icons[&"preset"], preset_item_meta, root)
		if preset == item_object_to_select : item_to_select = preset_item
		preset_item.set_editable(0, false)
		preset_item_meta.owner = preset_item
		
		var preset_blocks_ids : Array[StringName] = preset.blocks.keys()
		for block_uid : StringName in preset_blocks_ids:
			var preset_blocks_array : Array = preset.blocks[block_uid]
			for block : SkinBlockData.SkinBlock in preset_blocks_array:
				var block_item_meta : EditorTreeItemMetadata = EditorTreeItemMetadata.new(SkinEditorTree.ITEM_TYPE.BLOCK, self, block)
				var block_item_text : String = str(block.id + str(block.index + 1))
				var block_item_icon : Texture2D = SkinEditorTree.tree_icons[&"object"]
				
				if (block.frames_assets_uids.size() > 0):
					block_item_icon = block.sprite_frames.get_frame_texture(&"default", 0)
				
				var block_item : TreeItem = _create_item(block_item_text, block_item_icon, block_item_meta, preset_item)
				if block == item_object_to_select : item_to_select = block_item
				block_item.set_editable(0, false)
				block_item_meta.owner = block_item
	
	if item_to_select : 
		parent_tree.set_selected(item_to_select, 0)
		item_object_to_select = null
	
	return true

func rebuild() -> bool:
	if not block_data : return false
	_clear_item(root)
	return build(block_data)


func select_item(item : TreeItem) -> bool:
	if item == root : return true
	property_editor_manager.open_editor(item.get_metadata(0))
	return true

func edit_item_name(_item : TreeItem) -> bool:
	return false

func show_item_options(item : TreeItem, options_popup : PopupMenu, mouse_position : Vector2) -> bool:
	if item == root : 
		options_popup.full_clear()
		options_popup.add_option("Add new preset", _create_preset)
		
		options_popup.popup()
		options_popup.position = mouse_position
		return true
	
	var item_metadata : EditorTreeItemMetadata = item.get_metadata(0)
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK_PRESET:
		options_popup.full_clear()
		options_popup.add_option("Add new block", _create_block.bind(item_metadata.object.id))
		options_popup.add_option("Duplicate preset", duplicate_item.bind(item))
		options_popup.add_option("Delete preset", remove_item.bind(item))
		options_popup.add_separator()
		options_popup.add_option("Cut", copy_manager.cut_object.bind(remove_item.bind(item), item.get_metadata(0)))
		options_popup.add_option("Copy", copy_manager.copy_object.bind(item.get_metadata(0)))
		options_popup.add_option("Paste", paste_item.bind(item, copy_manager.get_paste_object(EditorCopyManager.COPY_TYPE.TREE_ITEM)))
		
		options_popup.popup()
		options_popup.position = mouse_position
		return true
	
	options_popup.full_clear()
	options_popup.add_option("Add new block", _create_block.bind(item_metadata.object.preset_id))
	options_popup.add_option("Duplicate block", duplicate_item.bind(item))
	options_popup.add_option("Delete block", remove_item.bind(item))
	options_popup.add_separator()
	options_popup.add_option("Cut", copy_manager.cut_object.bind(remove_item.bind(item), item.get_metadata(0)))
	options_popup.add_option("Copy", copy_manager.copy_object.bind(item.get_metadata(0)))
	options_popup.add_option("Paste", paste_item.bind(item, copy_manager.get_paste_object(EditorCopyManager.COPY_TYPE.TREE_ITEM)))
	
	options_popup.popup()
	options_popup.position = mouse_position
	return true


func _create_preset() -> void:
	var new_preset : SkinBlockData.SkinBlockPreset = SkinBlockData.SkinBlockPreset.new()
	new_preset.id = "Preset " + str(block_data.blocks_presets.size() + 1)
	block_data.blocks_presets[new_preset.id] = new_preset
	
	undo_manager.track(
		self,
		_remove_preset.bind(new_preset), 
		_create_preset
	)
	
	item_object_to_select = new_preset
	rebuild()

func _create_block(preset_id : String) -> void:
	if not block_data.blocks_presets.has(preset_id) : return
	
	var new_block : SkinBlockData.SkinBlock = SkinBlockData.SkinBlock.new()
	new_block.id = &"red"
	new_block.preset_id = preset_id
	new_block.index = block_data.blocks_presets[preset_id].blocks[&"red"].size()
	block_data.blocks_presets[preset_id].blocks[&"red"].append(new_block)
	
	undo_manager.track(
		self,
		_remove_block.bind(new_block), 
		_create_block.bind(preset_id)
	)
	
	item_object_to_select = new_block
	rebuild()

func _add_preset(preset : SkinBlockData.SkinBlockPreset) -> void:
	var preset_clone : SkinBlockData.SkinBlockPreset = SkinBlockData.SkinBlockPreset.clone(preset)
	if (block_data.blocks_presets.has(preset.id)) : preset.id = preset.id + "+"
	block_data.blocks_presets[preset.id] = preset_clone
	
	undo_manager.track(
		self,
		_remove_preset.bind(preset_clone), 
		_add_preset.bind(preset_clone)
	)
	
	item_object_to_select = preset
	rebuild()

func _add_block(block : SkinBlockData.SkinBlock, preset_id : String = "", rebuild_ : bool = true) -> void:
	if not preset_id : preset_id = block.preset_id
	if not block_data.blocks_presets.has(preset_id) : return
	
	var block_clone : SkinBlockData.SkinBlock = SkinBlockData.SkinBlock.clone(block)
	
	var target_blocks_array : Array = block_data.blocks_presets[preset_id].blocks[block_clone.id]
	target_blocks_array.insert(block_clone.index, block_clone)
	for i : int in range(block_clone.index, target_blocks_array.size()) : target_blocks_array[i].index = i
	block_clone.preset_id = preset_id
	
	undo_manager.track(
		self,
		_remove_block.bind(block_clone), 
		_add_block.bind(block_clone, preset_id)
	)
	
	item_object_to_select = block_clone
	if rebuild_ : rebuild()


func can_drop_item(dragged_item : TreeItem, target_item : TreeItem, drop_placement : DROP_PLACEMENT) -> bool:
	var dragged_item_metadata : EditorTreeItemMetadata = dragged_item.get_metadata(0)
	var target_item_metadata : EditorTreeItemMetadata = target_item.get_metadata(0)
	
	if dragged_item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK:
		if target_item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK_PRESET:
			if drop_placement == DROP_PLACEMENT.HERE : return true
			if drop_placement == DROP_PLACEMENT.INSIDE : return true
		if target_item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK:
			return true
	
	return false

func drop_item(dragged_item : TreeItem, target_item : TreeItem, _drop_placement : DROP_PLACEMENT) -> bool:
	var dragged_item_metadata : EditorTreeItemMetadata = dragged_item.get_metadata(0)
	var target_item_metadata : EditorTreeItemMetadata = target_item.get_metadata(0)
	
	if target_item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK_PRESET:
		var target_preset : SkinBlockData.SkinBlockPreset = target_item_metadata.object
		var this_block : SkinBlockData.SkinBlock = dragged_item_metadata.object
		
		_move_block(this_block, target_preset.id)
	
	if target_item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK:
		var target_block : SkinBlockData.SkinBlock = target_item_metadata.object
		var this_block : SkinBlockData.SkinBlock = dragged_item_metadata.object
		
		_move_block(this_block, target_block.preset_id)
	
	return true

## Moves passed skin block from one preset to another
func _move_block(block : SkinBlockData.SkinBlock, preset_id : StringName) -> void:
	var old_preset_id : StringName = block.preset_id
	var old_blocks_array : Array = block_data.blocks_presets[block.preset_id].blocks[block.id]
	old_blocks_array.remove_at(block.index)
	for i : int in range(block.index, old_blocks_array.size()) : old_blocks_array[i].index = i
	
	var new_blocks_array : Array = block_data.blocks_presets[preset_id].blocks[block.id]
	new_blocks_array.insert(block.index, block)
	for i : int in range(block.index, new_blocks_array.size()) : new_blocks_array[i].index = i
	block.preset_id = preset_id
	
	undo_manager.track(
		self,
		_move_block.bind(block, old_preset_id), 
		_move_block.bind(block, preset_id)
	)
	
	rebuild()


## Duplicates selected subtree item data.
func duplicate_item(item : TreeItem) -> bool:
	if item == root : return false
	var item_metadata : EditorTreeItemMetadata = item.get_metadata(0)
	
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK:
		var block : SkinBlockData.SkinBlock = item_metadata.object
		_duplicate_block(block)
	
	elif item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK_PRESET:
		if item_metadata.parent_subtree != self : return false
		var preset : SkinBlockData.SkinBlockPreset = item_metadata.object
		_duplicate_preset(preset)
	
	return true

func _duplicate_block(block : SkinBlockData.SkinBlock) -> void:
	var new_block : SkinBlockData.SkinBlock = SkinBlockData.SkinBlock.clone(block)
	new_block.index = block_data.blocks_presets[new_block.preset_id].blocks[new_block.id].size()
	block_data.blocks_presets[new_block.preset_id].blocks[new_block.id].append(new_block)
	
	undo_manager.track(
		self,
		_remove_block.bind(new_block), 
		_duplicate_block.bind(block)
	)
	
	item_object_to_select = new_block
	rebuild()

func _duplicate_preset(preset : SkinBlockData.SkinBlockPreset) -> void:
	var new_preset : SkinBlockData.SkinBlockPreset = SkinBlockData.SkinBlockPreset.clone(preset)
	new_preset.id = new_preset.id + "+"
	block_data.blocks_presets[new_preset.id] = new_preset
	
	undo_manager.track(
		self,
		_remove_preset.bind(new_preset), 
		_duplicate_preset.bind(preset)
	)
	
	item_object_to_select = new_preset
	rebuild()


## Removes item from this sub-tree and removes respective object from current skin sub-structure **data**.
func remove_item(item : TreeItem) -> bool:
	if item == root : return false
	var item_metadata : EditorTreeItemMetadata = item.get_metadata(0)
	
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK:
		var block : SkinBlockData.SkinBlock = item_metadata.object
		_remove_block(block)
	
	elif item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK_PRESET:
		if item_metadata.parent_subtree != self : return false
		var preset : SkinBlockData.SkinBlockPreset = item_metadata.object
		_remove_preset(preset)
	
	return true

func _remove_block(block : SkinBlockData.SkinBlock) -> void:
	var blocks_array : Array = block_data.blocks_presets[block.preset_id].blocks[block.id]
	blocks_array.remove_at(block.index)
	for i : int in range(block.index, blocks_array.size()) : blocks_array[i].index = i
	
	undo_manager.track(
		self,
		_add_block.bind(block), 
		_remove_block.bind(block)
	)
	
	rebuild()

func _remove_preset(preset : SkinBlockData.SkinBlockPreset) -> void:
	block_data.blocks_presets.erase(preset.id)
	undo_manager.track(
		self,
		_add_preset.bind(preset), 
		_remove_preset.bind(preset)
	)
	
	rebuild()


## Resolves pasted by copy manager item metadata to decide if item copy can be created
func paste_item(selected_item : TreeItem, item_metadata : EditorTreeItemMetadata) -> bool:
	if not item_metadata.parent_subtree == self : return false
	var selected_metadata : EditorTreeItemMetadata = selected_item.get_metadata(0)
	
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK:
		if selected_item == root : return false
		
		var block : SkinBlockData.SkinBlock = item_metadata.object
		var preset_id : String
		if selected_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK : preset_id = selected_metadata.object.preset_id
		elif selected_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK_PRESET : preset_id = selected_metadata.object.id
		
		_add_block(block, preset_id)
	
	elif item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK_PRESET:
		if item_metadata.parent_subtree != self : return false
		if selected_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK : return false
		
		var preset : SkinBlockData.SkinBlockPreset = item_metadata.object
		_add_preset(preset)
	
	return true
