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
## Shows all skin visual effects and allows to edit them or add new ones
##
class_name SEEffectsSubTree

var effect_data : SkinEffectData

var variant_items : Dictionary[int, TreeItem] = {}


## Builds this sub-tree using passed skin sub-structure **data**.
func build(new_data : Variant) -> bool:
	return false


func rebuild() -> bool:
	return false


## Builds this sub-tree using passed skin sub-structure **data**.
func build_tree(new_data : Variant) -> bool:
	if not new_data is SkinEffectData : return false
	effect_data = new_data
	
	for variant_id : int in effect_data.effects.keys():
		var variant_item_meta : EditorTreeItemMetadata = EditorTreeItemMetadata.new(SkinEditorTree.ITEM_TYPE.BLOCK_PRESET, self, variant_id)
		var variant_item  : TreeItem = _create_item("Variant " + str(variant_id), SkinEditorTree.tree_icons[&"variant"], variant_item_meta, root)
		variant_item_meta.owner = variant_item
		variant_items[variant_id] = variant_item
		variant_item.set_editable(0, false)
		
		var variant_effects : Dictionary = effect_data.effects[variant_id]
		for effect_uid : StringName in variant_effects:
			for effect : SkinEffectData.SkinEffect in variant_effects[effect_uid]:
				var effect_item_meta : EditorTreeItemMetadata = EditorTreeItemMetadata.new(SkinEditorTree.ITEM_TYPE.EFFECT, self, effect)
				var effect_item : TreeItem = _create_item(effect.uid + str(effect.index + 1), SkinEditorTree.tree_icons[&"object"], effect_item_meta, variant_item)
				effect_item.set_editable(0, false)
				effect_item_meta.owner = effect_item
	
	return true

func can_drag_item(item : TreeItem) -> bool:
	return false

func can_drop_item(item : TreeItem, drop_position : TreeItem, drop_section : int) -> bool:
	return false

func drop_item(item : TreeItem, drop_position : TreeItem, drop_section : int) -> bool:
	return false


## Called by root tree when some item is selected.[br]
## Returns **true** if selected item exists in this sub-tree and selected successfully.
func select_item(item : TreeItem) -> bool:
	if item == root : return true
	if not _is_item_inside(item): return false
	
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
	
	if not _is_item_inside(item): return false
	
	var item_meta : EditorTreeItemMetadata = item.get_metadata(0)
	if item_meta.type == SkinEditorTree.ITEM_TYPE.BLOCK_PRESET:
		options_popup.full_clear()
		options_popup.add_option("Add new effect", _add_effect.bind(item_meta.object))
		options_popup.add_option("Duplicate variant", duplicate_item.bind(item))
		options_popup.add_option("Delete variant", remove_item.bind(item))
		options_popup.add_separator()
		options_popup.add_option("Cut", copy_manager.cut_object.bind(remove_item.bind(item), item))
		options_popup.add_option("Copy", copy_manager.insert_object_to_copy.bind(item))
		options_popup.add_option("Paste", paste_item.bind(item, copy_manager.get_paste_object(EditorCopyManager.COPY_TYPE.TREE_ITEM)))
		
		options_popup.popup()
		options_popup.position = mouse_position
		return true
	
	options_popup.full_clear()
	options_popup.add_option("Add new effect", _add_effect.bind(item_meta.object.variant_id))
	options_popup.add_option("Duplicate effect", duplicate_item.bind(item))
	options_popup.add_option("Delete effect", remove_item.bind(item))
	options_popup.add_separator()
	options_popup.add_option("Cut", copy_manager.cut_object.bind(remove_item.bind(item), item))
	options_popup.add_option("Copy", copy_manager.insert_object_to_copy.bind(item))
	options_popup.add_option("Paste", paste_item.bind(item, copy_manager.get_paste_object(EditorCopyManager.COPY_TYPE.TREE_ITEM)))
	
	options_popup.popup()
	options_popup.position = mouse_position
	return true


## Duplicates selected subtree item data.
func duplicate_item(item : TreeItem) -> bool:
	return false

## Adds new variant to this sub-tree and creates respective object for current skin sub-structure **data**.
func _add_variant() -> void:
	var variant_id : int = effect_data.effects.size()
	effect_data.effects[variant_id] = {}
	effect_data.effects[variant_id][&"red_square"] = []
	
	var variant_item_meta : EditorTreeItemMetadata = EditorTreeItemMetadata.new(SkinEditorTree.ITEM_TYPE.BLOCK_PRESET, self, variant_id)
	var variant_item  : TreeItem = _create_item("Variant " + str(variant_id), SkinEditorTree.tree_icons[&"variant"], variant_item_meta, root)
	variant_item_meta.owner = variant_item
	variant_items[variant_id] = variant_item
	variant_item.set_editable(0, false)

## Adds new effect to this sub-tree and creates respective object for current skin sub-structure **data**.
func _add_effect(variant_id : int) -> void:
	if not effect_data.effects.has(variant_id) : return
	
	var new_effect : SkinEffectData.SkinEffect = SkinEffectData.SkinEffect.new()
	new_effect.uid = &"red_square"
	new_effect.variant_id = variant_id
	
	# TODO : Build base scene here and add animation item
	
	new_effect.index = effect_data.effects[variant_id][&"red_square"].size()
	effect_data.effects[variant_id][&"red_square"].append(new_effect)
	
	var effect_item_meta : EditorTreeItemMetadata = EditorTreeItemMetadata.new(SkinEditorTree.ITEM_TYPE.EFFECT, self, new_effect)
	var effect_item : TreeItem = _create_item(new_effect.uid + str(new_effect.index + 1), SkinEditorTree.tree_icons[&"object"], effect_item_meta, variant_items[variant_id])
	effect_item.set_editable(0, false)
	effect_item_meta.owner = effect_item

## Removes item from this sub-tree and removes respective object from current skin sub-structure **data**.
func remove_item(item : TreeItem) -> bool:
	return false


## Resolves pasted by copy manager item metadata to decide if item copy can be created
func paste_item(selected_item : TreeItem, item_metadata : EditorTreeItemMetadata) -> bool:
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.EFFECT:
		pass
	
	if item_metadata.type == SkinEditorTree.ITEM_TYPE.BLOCK_PRESET:
		pass
	
	return false
