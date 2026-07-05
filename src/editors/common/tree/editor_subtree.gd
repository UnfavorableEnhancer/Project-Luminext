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

@abstract 
##
## Interface for making some editor tree sub-trees
##
class_name EditorSubTree

var root : TreeItem = null ## Root TreeItem of this sub-tree
var parent_tree : Tree = null ## Parent tree instance.

var copy_manager : EditorCopyManager
var undo_manager : EditorHistoryManager

var property_editor_manager : PropertyEditorManager

## Helper function to create TreeItem with specified text, icon, metadata and parent
func _create_item(text : String, icon : Texture2D, metadata : EditorTreeItemMetadata = null, parent : TreeItem = null) -> TreeItem:
	var item : TreeItem = parent_tree.create_item(parent)
	item.set_text(0, text)
	item.set_icon(0, icon)
	
	if metadata != null : 
		metadata.owner = item
		item.set_metadata(0, metadata)
	
	return item

## Helper function, which returns **true** if item exists in this sub-tree
func _is_item_inside(item : TreeItem) -> bool:
	if item == root : return true 
	
	var scan_func : Callable
	scan_func = func(item_to_scan : TreeItem, item_to_check : TreeItem, rec_scan_func : Callable) -> bool:
		if item_to_scan == item_to_check : return true
		if item_to_scan.get_child_count() == 0 : return false
		
		var success : bool = false
		for subitem : TreeItem in item_to_scan.get_children():
			success = rec_scan_func.call(subitem, item_to_check, rec_scan_func)
			if success : break
		
		return success
	
	return scan_func.call(root, item, scan_func)

## Helper function, which recursively deletes all childs of an passed [TreeItem], except passed item itself.
func _clear_item(item : TreeItem) -> void:
	var clear_func : Callable
	clear_func = func(item_to_clear : TreeItem, rec_clear_func : Callable) -> void:
		var children : Array[TreeItem] = item_to_clear.get_children()
		
		if not children.is_empty():
			for child : TreeItem in children:
				rec_clear_func.call(child, rec_clear_func)
		
		item_to_clear.free()
	
	var item_children : Array[TreeItem] = item.get_children()
	for child : TreeItem in item_children:
		clear_func.call(child, clear_func)


## Builds this sub-tree using passed skin sub-structure **data**.
@abstract func build(new_data : Variant) -> bool
## Rebuilds tree using already existing data.
@abstract func rebuild() -> bool

## Called by parent tree when some [TreeItem] is selected.[br]
## Returns **true** if selected [TreeItem] exists in this sub-tree and selected successfully.
@abstract func select_item(item : TreeItem) -> bool
## Called by parent tree when some [TreeItem] name is edited.[br]
## Returns **true** if selected [TreeItem] exists in this sub-tree and processed successfully.
@abstract func edit_item_name(item : TreeItem) -> bool
## Called by parent tree when some [TreeItem] is right clicked.[br]
## Returns **true** if selected [TreeItem] exists in this subtree and options popup is built successfully.
@abstract func show_item_options(item : TreeItem, options_popup : PopupMenu, mouse_position : Vector2) -> bool

## Duplicates selected subtree [TreeItem].
@abstract func duplicate_item(item : TreeItem) -> bool
## Removes [TreeItem] from this subtree and removes respective object from data structure that [TreeItem] was linked to.
@abstract func remove_item(item : TreeItem) -> bool
## Resolves pasted by copy manager [TreeItem] metadata to decide if [TreeItem] copy can be inserted.
@abstract func paste_item(selected_item : TreeItem, item_metadata : EditorTreeItemMetadata) -> bool
