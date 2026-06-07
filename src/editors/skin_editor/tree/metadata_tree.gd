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
## Used for skin metadata tree item
##
class_name SEMetadataSubTree

var metadata : SkinMetadata


## Builds this sub-tree using passed skin sub-structure **data**.
func build_tree(new_data : Variant) -> bool:
	if not new_data is SkinMetadata: return false
	metadata = new_data 
	return true


## Called by root tree when some item is selected.[br]
## Returns **true** if selected item exists in this sub-tree and selected successfully.
func select_item(item : TreeItem) -> bool:
	if item != root : return false
	
	# TODO : Request property editor here
	print(item.get_metadata(0).object)
	
	return true


## Called by root tree when some item name is edited.[br]
## Returns **true** if selected item exists in this sub-tree and processed successfully.
func edit_item_name(_item : TreeItem) -> bool:
	return false

## Called by root tree when some item is right clicked.[br]
## Returns **true** if selected item exists in this sub-tree and options popup is built successfully.
func show_item_options(item : TreeItem, _options_popup : PopupMenu, _mouse_position : Vector2) -> bool:
	if item == root : return true
	return false

## Duplicates selected subtree item data.
func duplicate_item(item : TreeItem) -> bool:
	if item == root : return true
	return false

## Removes item from this sub-tree and removes respective object from current skin sub-structure **data**.
func remove_item(item : TreeItem) -> bool:
	if item == root : return true
	return false

## Resolves pasted by copy manager item metadata to decide if item copy can be created
func paste_item(_selected_item : TreeItem, _item_metadata : EditorTreeItemMetadata) -> bool:
	return false
