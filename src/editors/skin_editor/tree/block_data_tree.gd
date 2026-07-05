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


## Builds this sub-tree using passed skin sub-structure **data**.
func build(new_data : Variant) -> bool:
	if not new_data is SkinBlockData : return false
	block_data = new_data
	
	var item_to_select : TreeItem = null
	
	for preset : SkinBlockData.SkinBlockPreset in block_data.blocks_presets.values():
		var preset_item_meta : EditorTreeItemMetadata = EditorTreeItemMetadata.new(SkinEditorTree.ITEM_TYPE.PRESET, self, preset)
		var preset_item_text : String = "Preset " + str(preset.id + 1)
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
				var block_item : TreeItem = _create_item(block_item_text, SkinEditorTree.tree_icons[&"object"], block_item_meta, preset_item)
				if block == item_object_to_select : item_to_select = block_item
				block_item.set_editable(0, false)
				block_item_meta.owner = block_item
	
	if item_to_select : 
		parent_tree.set_selected(item_to_select, 0)
		item_object_to_select = null
	
	return true


## Rebuilds tree using already existing block data
func rebuild() -> bool:
	if not block_data : return false
	_clear_item(root)
	return build(block_data)


## Called by root tree when some item is selected.[br]
## Returns **true** if selected item exists in this sub-tree and selected successfully.
func select_item(item : TreeItem) -> bool:
	if item == root : return true
	property_editor_manager.open_editor(item.get_metadata(0))
	return true


## Called by root tree when some item name is edited.[br]
## Returns **true** if selected item exists in this sub-tree and processed successfully.
func edit_item_name(_item : TreeItem) -> bool:
	return false


## Called by root tree when some item is right clicked.[br]
## Returns **true** if selected item exists in this sub-tree and options popup is built successfully.
func show_item_options(item : TreeItem, options_popup : PopupMenu, mouse_position : Vector2) -> bool:
	if item == root : 
		options_popup.full_clear()
		options_popup.add_option("Add new preset", _add_preset)
		
		options_popup.popup()
		options_popup.position = mouse_position
		return true
	
	var item_metadata : EditorTreeItemMetadata = item.get_metadata(0)
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.PRESET:
		options_popup.full_clear()
		options_popup.add_option("Add new block", _add_block.bind(item_metadata.object.id))
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
	options_popup.add_option("Add new block", _add_block.bind(item_metadata.object.preset_id))
	options_popup.add_option("Duplicate block", duplicate_item.bind(item))
	options_popup.add_option("Delete block", remove_item.bind(item))
	options_popup.add_separator()
	options_popup.add_option("Cut", copy_manager.cut_object.bind(remove_item.bind(item), item.get_metadata(0)))
	options_popup.add_option("Copy", copy_manager.copy_object.bind(item.get_metadata(0)))
	options_popup.add_option("Paste", paste_item.bind(item, copy_manager.get_paste_object(EditorCopyManager.COPY_TYPE.TREE_ITEM)))
	
	options_popup.popup()
	options_popup.position = mouse_position
	return true


## Adds new preset to this sub-tree and creates respective object for current skin sub-structure **data**.
func _add_preset() -> void:
	var new_preset : SkinBlockData.SkinBlockPreset = SkinBlockData.SkinBlockPreset.new()
	new_preset.id = block_data.blocks_presets.size()
	block_data.blocks_presets[new_preset.id] = new_preset
	
	item_object_to_select = new_preset
	rebuild()

## Adds new block to this sub-tree and creates respective object for current skin sub-structure **data**.
func _add_block(preset_id : int) -> void:
	if not block_data.blocks_presets.has(preset_id) : return
	
	var new_block : SkinBlockData.SkinBlock = SkinBlockData.SkinBlock.new()
	new_block.id = &"red"
	new_block.preset_id = preset_id
	new_block.index = block_data.blocks_presets[preset_id].blocks[&"red"].size()
	block_data.blocks_presets[preset_id].blocks[&"red"].append(new_block)
	
	item_object_to_select = new_block
	rebuild()


## Duplicates selected subtree item data.
func duplicate_item(item : TreeItem) -> bool:
	if item == root : return false
	var item_metadata : EditorTreeItemMetadata = item.get_metadata(0)
	
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK:
		var original_block : SkinBlockData.SkinBlock = item_metadata.object
		var new_block : SkinBlockData.SkinBlock = SkinBlockData.SkinBlock.clone(original_block)
		
		new_block.index = block_data.blocks_presets[new_block.preset_id].blocks[new_block.id].size()
		block_data.blocks_presets[new_block.preset_id].blocks[new_block.id].append(new_block)
		
		item_object_to_select = new_block
	
	elif item_metadata.type == SkinEditorTree.ITEM_TYPE.PRESET:
		if item_metadata.parent_subtree != self : return false
		
		var original_preset : SkinBlockData.SkinBlockPreset = item_metadata.object
		var new_preset : SkinBlockData.SkinBlockPreset = SkinBlockData.SkinBlockPreset.clone(original_preset)
		
		new_preset.id = block_data.blocks_presets.size()
		block_data.blocks_presets[new_preset.id] = new_preset
		
		item_object_to_select = new_preset
	
	rebuild()
	return true

## Removes item from this sub-tree and removes respective object from current skin sub-structure **data**.
func remove_item(item : TreeItem) -> bool:
	if item == root : return false
	var item_metadata : EditorTreeItemMetadata = item.get_metadata(0)
	
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK:
		var block : SkinBlockData.SkinBlock = item_metadata.object
		var blocks_array : Array = block_data.blocks_presets[block.preset_id].blocks[block.id]
		
		blocks_array.remove_at(block.index)
		for i : int in range(block.index, blocks_array.size()) : blocks_array[i].index = i
	
	elif item_metadata.type == SkinEditorTree.ITEM_TYPE.PRESET:
		if item_metadata.parent_subtree != self : return false
		
		var preset_id : int = item_metadata.object.id
		block_data.blocks_presets.erase(preset_id)
	
	rebuild()
	return true

## Resolves pasted by copy manager item metadata to decide if item copy can be created
func paste_item(selected_item : TreeItem, item_metadata : EditorTreeItemMetadata) -> bool:
	if not item_metadata.parent_subtree == self : return false
	var selected_metadata : EditorTreeItemMetadata = selected_item.get_metadata(0)
	
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK:
		if selected_item == root : return false
		
		var block_copy : SkinBlockData.SkinBlock = item_metadata.object
		var block_clone : SkinBlockData.SkinBlock = SkinBlockData.SkinBlock.clone(block_copy)
		
		var preset_id : int
		if selected_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK : preset_id = selected_metadata.object.preset_id
		elif selected_metadata.type == SkinEditorTree.ITEM_TYPE.PRESET : preset_id = selected_metadata.object.id
		
		block_clone.index = block_data.blocks_presets[preset_id].blocks[block_clone.id].size()
		block_data.blocks_presets[preset_id].blocks[block_clone.id].append(block_clone)
		
		item_object_to_select = block_clone
	
	elif item_metadata.type == SkinEditorTree.ITEM_TYPE.PRESET:
		if item_metadata.parent_subtree != self : return false
		if selected_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK : return false
		if selected_metadata.type == SkinEditorTree.ITEM_TYPE.PRESET : return false
		
		var preset_copy : SkinBlockData.SkinBlockPreset = item_metadata.object
		var preset_clone : SkinBlockData.SkinBlockPreset = SkinBlockData.SkinBlockPreset.clone(preset_copy)
		
		preset_clone.id = block_data.blocks_presets.size()
		block_data.blocks_presets[preset_clone.id] = preset_clone
		
		item_object_to_select = preset_clone
	
	rebuild()
	return true
