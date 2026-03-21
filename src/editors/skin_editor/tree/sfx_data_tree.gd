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
## Shows all skin sound effects and allows to edit them or add new ones
##
class_name SESFXTree

var sfx_data : SkinSFXData

var variant_items : Dictionary[int, TreeItem] = {}


## Builds this sub-tree using passed skin sub-structure **data**.
func build_tree(new_data : Variant) -> bool:
	if not new_data is SkinSFXData : return false
	sfx_data = new_data
	
	for variant_id : int in sfx_data.sounds.keys():
		var variant_item_meta : SkinEditorTree.ItemMetadata = SkinEditorTree.ItemMetadata.new(SkinEditorTree.ITEM_TYPE.VARIANT, self, variant_id)
		var variant_item  : TreeItem = _create_item("Variant " + str(variant_id), &"variant", variant_item_meta, root)
		variant_item_meta.owner = variant_item
		variant_items[variant_id] = variant_item
		variant_item.set_editable(0, false)
		
		var variant_sounds : Dictionary = sfx_data.sounds[variant_id]
		for sound_uid : StringName in variant_sounds:
			for sound : SkinSFXData.SkinSFX in variant_sounds[sound_uid]:
				var sound_item_meta : SkinEditorTree.ItemMetadata = SkinEditorTree.ItemMetadata.new(SkinEditorTree.ITEM_TYPE.SFX, self, sound)
				var sound_item : TreeItem = _create_item(sound.uid + str(sound.index + 1), &"object", sound_item_meta, variant_item)
				sound_item.set_editable(0, false)
				sound_item_meta.owner = sound_item
	
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
		options_popup.add_option("Add new variant", _add_variant)
		
		options_popup.popup()
		options_popup.position = mouse_position
		return true
	
	if not _is_item_valid(item): return false
	
	var item_meta : ItemMetadata = item.get_metadata(0)
	if item_meta.type == ITEM_TYPE.VARIANT:
		options_popup.full_clear()
		options_popup.add_option("Add new sound", _add_sound.bind(item_meta.object))
		options_popup.add_option("Duplicate variant", duplicate_item.bind(item))
		options_popup.add_option("Delete variant", remove_item.bind(item))
		options_popup.add_separator()
		options_popup.add_option("Cut", copy_manager.cut_object.bind(remove_item.bind(item), item))
		options_popup.add_option("Copy", copy_manager.insert_object_to_copy.bind(item))
		options_popup.add_option("Paste", paste_item.bind(item, copy_manager.get_paste_object(EditorCopyManager.COPY_TYPE.SE_TREE_ITEM)))
		
		options_popup.popup()
		options_popup.position = mouse_position
		return true
	
	options_popup.full_clear()
	options_popup.add_option("Add new sound", _add_sound.bind(item_meta.object.variant_id))
	options_popup.add_option("Duplicate sound", duplicate_item.bind(item))
	options_popup.add_option("Delete sound", remove_item.bind(item))
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

## Adds new variant to this sub-tree and creates respective object for current skin sub-structure **data**.
func _add_variant() -> void:
	var variant_id : int = sfx_data.sounds.size()
	sfx_data.sounds[variant_id] = {}
	sfx_data.sounds[variant_id][&"move_left"] = []
	
	var variant_item_meta : SkinEditorTree.ItemMetadata = SkinEditorTree.ItemMetadata.new(SkinEditorTree.ITEM_TYPE.VARIANT, self, variant_id)
	var variant_item  : TreeItem = _create_item("Variant " + str(variant_id), &"variant", variant_item_meta, root)
	variant_item_meta.owner = variant_item
	variant_items[variant_id] = variant_item
	variant_item.set_editable(0, false)

## Adds new sound to this sub-tree and creates respective object for current skin sub-structure **data**.
func _add_sound(variant_id : int) -> void:
	if not sfx_data.sounds.has(variant_id) : return
	
	var new_sound : SkinSFXData.SkinSFX = SkinSFXData.SkinSFX.new()
	new_sound.uid = &"move_left"
	new_sound.variant_id = variant_id
	new_sound.index = sfx_data.sounds[variant_id][&"move_left"].size()
	
	sfx_data.sounds[variant_id][&"move_left"].append(new_sound)
	
	var sound_item_meta : SkinEditorTree.ItemMetadata = SkinEditorTree.ItemMetadata.new(SkinEditorTree.ITEM_TYPE.SFX, self, new_sound)
	var sound_item : TreeItem = _create_item(new_sound.uid + str(new_sound.index + 1), &"object", sound_item_meta, variant_items[variant_id])
	sound_item.set_editable(0, false)
	sound_item_meta.owner = sound_item

## Removes item from this sub-tree and removes respective object from current skin sub-structure **data**.
func remove_item(item : TreeItem) -> bool:
	return false


## Resolves pasted by copy manager item metadata to decide if item copy can be created
func paste_item(selected_item : TreeItem, item_metadata : ItemMetadata) -> bool:
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.SFX:
		pass
	
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.VARIANT:
		pass
	
	return false
