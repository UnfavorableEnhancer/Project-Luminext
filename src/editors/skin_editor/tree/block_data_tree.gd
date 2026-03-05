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

extends SkinEditorTree.SubTree
##
## Shows all skin blocks and allows to edit them or add new ones
##
class_name SkinBlockDataTree

var data : SkinBlockData

var variants : Dictionary[int, TreeItem] = {}


## Builds this sub-tree using passed skin sub-structure **data**.
func build_tree(new_data : Variant) -> bool:
	if not new_data is SkinBlockData : return false
	data = new_data
	
	for block_id : StringName in data.blocks.keys():
		var blocks : Array = data.blocks[block_id]
		
		for block : SkinBlockData.SkinBlock in blocks:
			var variant_item : TreeItem = variants.get(block.segment_id)
			if variant_item == null:
				variant_item = root.create_child()
				var variant_item_meta : SkinEditorTree.ItemMetadata = SkinEditorTree.ItemMetadata.new(SkinEditorTree.ITEM_TYPE.VARIANT, variant_item, self, block.variant_id)
				
				variant_item.set_text(0, "Variant " + str(block.variant_id))
				variant_item.set_metadata(0, variant_item_meta)
				variant_item.set_icon(0, SkinEditorTree.tree_icons[&"node"])
				
				variants[block.segment_id] = variant_item
			
			var block_item : TreeItem = variant_item.create_child()
			var block_item_meta : SkinEditorTree.ItemMetadata = SkinEditorTree.ItemMetadata.new(SkinEditorTree.ITEM_TYPE.BLOCK, block_item, self, block)
			
			block_item.set_text(0, block.uid + str(block.index + 1))
			block_item.set_metadata(0, block_item_meta)
			block_item.set_icon(0, SkinEditorTree.tree_icons[&"blocks"])
	
	return true


## Called by root tree when some item is selected.[br]
## Returns **true** if selected item exists in this sub-tree and selected successfully.
func select_item(item : TreeItem) -> bool:
	if not item in root.get_children() : return false
	
	return true


## Called by root tree when some item name is edited.[br]
## Returns **true** if selected item exists in this sub-tree and processed successfully.
func edit_item_name(item : TreeItem) -> bool:
	if not item in root.get_children() : return false
	
	return true


## Called by root tree when some item is right clicked.[br]
## Returns **true** if selected item exists in this sub-tree and options popup is built successfully.
func show_item_options(item : TreeItem) -> bool:
	if not item in root.get_children() : return false
	
	var options_popup : PopupMenu = skin_editor.options_popup
	
	
	return true


## Adds new item to this sub-tree and creates respective object for current skin sub-structure **data**.
func add_item() -> void:
	pass


## Removes item from this sub-tree and removes respective object from current skin sub-structure **data**.
func remove_item(item : TreeItem) -> void:
	pass


## Pastes item from parent skin editor copy buffer
func paste_item(item : TreeItem) -> void:
	var item_meta : SkinEditorTree.ItemMetadata = item.get_metadata(0)
	
	if item_meta.type == SkinEditorTree.ITEM_TYPE.BLOCK:
		pass
	
	if item_meta.type == SkinEditorTree.ITEM_TYPE.VARIANT:
		pass
