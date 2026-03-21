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
## Shows all skin background animations and allows to edit them or add new ones
##
class_name SEAnimationsTree

var anim_data : SkinAnimationData


## Builds this sub-tree using passed skin sub-structure **data**.
func build_tree(new_data : Variant) -> bool:
	if not new_data is SkinAnimationData : return false
	anim_data = new_data
	
	return true


## Called by root tree when some item is selected.[br]
## Returns **true** if selected item exists in this sub-tree and selected successfully.
func select_item(item : TreeItem) -> bool:
	if item == root : return true
	if not _is_item_valid(item): return false
	
	# TODO : Request property editor here
	print(item.get_metadata(0).object)
	
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
		options_popup.add_option("Add new animation", _add_animation)
		
		options_popup.popup()
		options_popup.position = mouse_position
		return true
	
	if not _is_item_valid(item): return false
	
	options_popup.full_clear()
	options_popup.add_option("Add new animation", _add_animation)
	options_popup.add_option("Duplicate animation", duplicate_item.bind(item))
	options_popup.add_option("Delete animation", remove_item.bind(item))
	options_popup.add_separator()
	options_popup.add_option("Cut", copy_manager.cut_object.bind(remove_item.bind(item), item))
	options_popup.add_option("Copy", copy_manager.insert_object_to_copy.bind(item))
	options_popup.add_option("Paste", paste_item.bind(item, copy_manager.get_paste_object(EditorCopyManager.COPY_TYPE.SE_TREE_ITEM)))
	
	options_popup.popup()
	options_popup.position = mouse_position
	return true


## Duplicates selected subtree item data.
func duplicate_item(item : TreeItem) -> bool:
	return false

## Adds new animation to this sub-tree and creates respective object for current skin sub-structure **data**.
func _add_animation() -> void:
	return


## Removes item from this sub-tree and removes respective object from current skin sub-structure **data**.
func remove_item(item : TreeItem) -> bool:
	return false


## Resolves pasted by copy manager item metadata to decide if item copy can be created
func paste_item(selected_item : TreeItem, item_metadata : ItemMetadata) -> bool:
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK:
		pass
	
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.VARIANT:
		pass
	
	return false
