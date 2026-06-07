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
## Shows all objects from inserted [ModdableScene] and allows to edit them or add new ones.
##
class_name ModdableSceneSubTree

var moddable_scene : ModdableScene


## Builds this sub-tree using passed [ModdableScene].
func build_tree(new_data : Variant) -> bool:
	if not new_data is ModdableScene : return false
	moddable_scene = new_data
	
	return true


## Called by parent tree when some [TreeItem] is selected.[br]
## Returns **true** if selected [TreeItem] exists in this sub-tree and selected successfully.
func select_item(item : TreeItem) -> bool:
	if item == root : return true
	if not _is_item_inside(item): return false
	
	# TODO : Request property editor here
	print(item.get_metadata(0).object)
	
	return true


## Called by parent tree when some [TreeItem] name is edited.[br]
## Returns **true** if selected [TreeItem] exists in this sub-tree and processed successfully.
func edit_item_name(_item : TreeItem) -> bool:
	# TODO : Change linked object name
	return false


## Called by parent tree when some [TreeItem] is right clicked.[br]
## Returns **true** if selected [TreeItem] exists in this sub-tree and options popup is built successfully.
func show_item_options(item : TreeItem, options_popup : PopupMenu, mouse_position : Vector2) -> bool:
	if item == root : 
		options_popup.full_clear()
		options_popup.add_option("Add node", _add_node)
		options_popup.add_option("Add sprite", _add_sprite)
		options_popup.add_option("Add animated sprite", _add_anim_sprite)
		options_popup.add_option("Add particles", _add_particles)
		options_popup.add_option("Add video player", _add_video)
		options_popup.add_option("Add rectangle", _add_rect)
		options_popup.add_option("Add text", _add_text)
		options_popup.add_option("Add shader", _add_shader)
		
		options_popup.popup()
		options_popup.position = mouse_position
		return true
	
	if not _is_item_inside(item): return false
	
	options_popup.full_clear()
	options_popup.add_option("Add child node", _add_node)
	options_popup.add_option("Add child sprite", _add_sprite)
	options_popup.add_option("Add child animated sprite", _add_anim_sprite)
	options_popup.add_option("Add child particles", _add_particles)
	options_popup.add_option("Add child video player", _add_video)
	options_popup.add_option("Add child rectangle", _add_rect)
	options_popup.add_option("Add child text", _add_text)
	options_popup.add_option("Add child shader", _add_shader)
	options_popup.add_option("Duplicate object", duplicate_item.bind(item))
	options_popup.add_option("Delete object", remove_item.bind(item))
	options_popup.add_separator()
	options_popup.add_option("Cut", copy_manager.cut_object.bind(remove_item.bind(item), item))
	options_popup.add_option("Copy", copy_manager.insert_object_to_copy.bind(item))
	options_popup.add_option("Paste", paste_item.bind(item, copy_manager.get_paste_object(EditorCopyManager.COPY_TYPE.SE_TREE_ITEM)))
	
	options_popup.popup()
	options_popup.position = mouse_position
	return true


## Duplicates selected subtree [TreeItem].
func duplicate_item(item : TreeItem) -> bool:
	return false


## Adds new node to this subtree and creates respective object for current [ModdableScene].
func _add_node(parent_item : TreeItem) -> void:
	pass

## Adds new sprite to this subtree and creates respective object for current [ModdableScene].
func _add_sprite(parent_item : TreeItem) -> void:
	pass

## Adds new animated sprite to this subtree and creates respective object for current [ModdableScene].
func _add_anim_sprite(parent_item : TreeItem) -> void:
	pass

## Adds new particles to this subtree and creates respective object for current [ModdableScene].
func _add_particles(parent_item : TreeItem) -> void:
	pass

## Adds new video player to this subtree and creates respective object for current [ModdableScene].
func _add_video(parent_item : TreeItem) -> void:
	pass

## Adds new color rect to this subtree and creates respective object for current [ModdableScene].
func _add_rect(parent_item : TreeItem) -> void:
	pass

## Adds new text to this subtree and creates respective object for current [ModdableScene].
func _add_text(parent_item : TreeItem) -> void:
	pass

## Adds new shader to this subtree and creates respective object for current [ModdableScene].
func _add_shader(parent_item : TreeItem) -> void:
	pass


## Removes [TreeItem] from this subtree and removes respective object from [ModdableScene] that [TreeItem] was linked to.
func remove_item(item : TreeItem) -> bool:
	return false


## Resolves pasted by copy manager [TreeItem] metadata to decide if [TreeItem] copy can be inserted.
func paste_item(selected_item : TreeItem, item_metadata : EditorTreeItemMetadata) -> bool:
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK:
		pass
	
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.VARIANT:
		pass
	
	return false
