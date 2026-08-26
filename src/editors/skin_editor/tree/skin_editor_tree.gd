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

extends Tree
##
## Displays contents of parent [SkinEditor] skin data sub-structures and allows to select, edit and add new objects inside them.
##
class_name SkinEditorTree


## All possible items inside this tree
enum ITEM_TYPE {
	ROOT = 0, ## Links to sub-tree root # NOTE : Cannot be moved at all and cannot be copy/pasted
	BLOCK_PRESET, ## Links to skin blocks preset # NOTE : Cannot be moved at all. Can be copy/pasted.
	BLOCK, ## Links to skin block # NOTE : Can be moved/copy/pasted only to other blocks preset
	SFX_PRESET, ## Links to skin sfx preset # NOTE : Cannot be moved at all. Can be copy/pasted.
	SFX, ## Links to skin sound effect # NOTE : Can be moved/copy/pasted only to other sound effects preset
	EFFECT_PRESET, ## Links to skin effects preset # NOTE : Cannot be moved at all. Can be copy/pasted.
	EFFECT, ## Links to skin visual effect # NOTE : Can be moved/copy/pasted only to other visual effects preset
	EFFECT_ANIMATION, ## Links to skin visual effect animation # NOTE : Cannot be moved at all. Can be copy/pasted.
	EFFECT_SCENE_OBJECT, ## Links to skin visual effect scene object # NOTE : Can be moved/copy/pasted to any position in own scene, or to some other scene.
	GUI_MODIFIER_PRESET, ## Links to skin gui modifiers preset # NOTE : Cannot be moved at all. Can be copy/pasted.
	GUI_MODIFIER, ## Links to an GUI modifier object # NOTE : Can be moved/copy/pasted only to other GUI modifiers preset
	BACKGROUND_ANIMATION, ## Links to skin background scene animation # NOTE : Cannot be moved at all. Can be copy/pasted.
	BACKGROUND_SCENE_OBJECT ## Links to an skin background scene object # NOTE : Can be moved/copy/pasted to any position in own scene, or to some other scene
}

const TREE_ICON_SIZE : int = 16 ## Size of the icon (height and width) used in all tree items

static var _tree_icons_tex : Texture = null ## Texture used for tree items icons atlas

## Defines regions for cutting "_tree_icons_tex" atlas
var _tree_icons_regions : Dictionary[StringName, Rect2i] = {
	&"none" : Rect2i(TREE_ICON_SIZE * 4, TREE_ICON_SIZE * 4, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"preset" : Rect2i(TREE_ICON_SIZE * 0, TREE_ICON_SIZE * 4, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"object" : Rect2i(TREE_ICON_SIZE * 1, TREE_ICON_SIZE * 4, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"metadata" : Rect2i(TREE_ICON_SIZE * 0, TREE_ICON_SIZE * 0, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"camera" : Rect2i(TREE_ICON_SIZE * 1, TREE_ICON_SIZE * 0, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"blocks" : Rect2i(TREE_ICON_SIZE * 2, TREE_ICON_SIZE * 0, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"effects" : Rect2i(TREE_ICON_SIZE * 3, TREE_ICON_SIZE * 0, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"gui" : Rect2i(TREE_ICON_SIZE * 4, TREE_ICON_SIZE * 0, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"sfx" : Rect2i(TREE_ICON_SIZE * 0, TREE_ICON_SIZE * 1, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"animations" : Rect2i(TREE_ICON_SIZE * 1, TREE_ICON_SIZE * 1, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"background" : Rect2i(TREE_ICON_SIZE * 2, TREE_ICON_SIZE * 1, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"node" : Rect2i(TREE_ICON_SIZE * 3, TREE_ICON_SIZE * 1, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"sprite" : Rect2i(TREE_ICON_SIZE * 4, TREE_ICON_SIZE * 1, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"anim_sprite" : Rect2i(TREE_ICON_SIZE * 0, TREE_ICON_SIZE * 2, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"particles" : Rect2i(TREE_ICON_SIZE * 1, TREE_ICON_SIZE * 2, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"parralax" : Rect2i(TREE_ICON_SIZE * 2, TREE_ICON_SIZE * 2, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"video" : Rect2i(TREE_ICON_SIZE * 3, TREE_ICON_SIZE * 2, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"polygon" : Rect2i(TREE_ICON_SIZE * 4, TREE_ICON_SIZE * 2, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"line" : Rect2i(TREE_ICON_SIZE * 2, TREE_ICON_SIZE * 4, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"rect" : Rect2i(TREE_ICON_SIZE * 0, TREE_ICON_SIZE * 3, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"text" : Rect2i(TREE_ICON_SIZE * 1, TREE_ICON_SIZE * 3, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"gui_mod" : Rect2i(TREE_ICON_SIZE * 2, TREE_ICON_SIZE * 3, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"shader" : Rect2i(TREE_ICON_SIZE * 3, TREE_ICON_SIZE * 3, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"audio_sync" : Rect2i(TREE_ICON_SIZE * 4, TREE_ICON_SIZE * 3, TREE_ICON_SIZE, TREE_ICON_SIZE),
}

static var tree_icons : Dictionary[StringName, AtlasTexture] = {} ## Ready to use icons for tree items
static var _drag_and_drop_preview : PackedScene = null ## Preview for [TreeItem] drap & drop

var skin_data : SkinData = null ## Skin data to view and edit.

var metadata_tree : SEMetadataSubTree = SEMetadataSubTree.new() ## Contains skin metadata TreeItem
var blocks_tree : SEBlocksSubTree = SEBlocksSubTree.new() ## Contains TreeItem's related to skin blocks
var effects_tree : SEEffectsSubTree = SEEffectsSubTree.new() ## Contains TreeItem's related to skin visual effects
var sounds_tree : SESFXSubTree = SESFXSubTree.new() ## Contains TreeItem's related to skin sound effects
var gui_tree : SEGUIModifiersSubTree = SEGUIModifiersSubTree.new() ## Contains TreeItem's related to skin GUI modifiers
var animation_tree : SEAnimationsSubTree = SEAnimationsSubTree.new() ## Contains TreeItem's related to skin background scene animations
var background_tree : ModdableSceneSubTree = ModdableSceneSubTree.new() ## Contains TreeItem's related to skin background scene nodes

@export var property_editor_manager : PropertyEditorManager ## Used to edit objects represented by tree

@export var undo_manager : EditorHistoryManager ## Used to add undo/redo commands
@export var copy_manager : EditorCopyManager ## Used to handle TreeItem's copy/paste

@export var options_popup : PopupMenu ## Called on some TreeItem right mouse click and shows options to do with it
@export var confirm_dialog : Control ## Shows some confirmation message
@export var message_dialog : Control ## Shows some warning or error message


func _ready() -> void:
	load_assets()

## Loads skin tree icons and drag and drop preview node
func load_assets() -> void:
	if _tree_icons_tex == null : _tree_icons_tex = load("res://assets/textures/editors/skin_editor/tree_icons_80.png")
	if not tree_icons.is_empty(): return
	
	if _drag_and_drop_preview == null : _drag_and_drop_preview = load("res://src/editors/common/tree/tree_drop_preview.tscn")
	
	for icon_name : StringName in _tree_icons_regions.keys():
		var icon_region : Rect2i = _tree_icons_regions[icon_name]
		var atlas_tex : AtlasTexture = AtlasTexture.new()
		atlas_tex.atlas = _tree_icons_tex
		atlas_tex.region = icon_region
		tree_icons[icon_name] = atlas_tex

func _on_focus_entered() -> void:
	copy_manager.copy_requested.connect(_on_copy_requested)
	copy_manager.paste_requested.connect(_on_paste_requested)
	copy_manager.cut_requested.connect(_on_cut_requested)

func _on_focus_exited() -> void:
	copy_manager.copy_requested.disconnect(_on_copy_requested)
	copy_manager.paste_requested.disconnect(_on_paste_requested)
	copy_manager.cut_requested.disconnect(_on_cut_requested)


## Helper function to create TreeItem with specified text, icon, metadata and parent
func _create_item(text : String, icon_uid : StringName = &"none", metadata : EditorTreeItemMetadata = null, parent : TreeItem = null) -> TreeItem:
	var item : TreeItem = create_item(parent)
	item.set_text(0, text)
	item.set_icon(0, tree_icons[icon_uid])
	item.set_editable(0, false)
	
	if metadata != null : 
		metadata.owner = item
		item.set_metadata(0, metadata)
	
	return item


## Builds tree from scratch using passed skin data.
func build_tree(new_skin_data : SkinData) -> void:
	clear()
	skin_data = new_skin_data
	
	var skin_tree_root : TreeItem = _create_item("Skin")
	
	var subtrees_data : Dictionary[EditorSubTree, Array] = {
		metadata_tree :   ["Metadata",&"metadata",skin_data.metadata],
		blocks_tree :   ["Blocks",&"blocks",skin_data.blocks],
		effects_tree :   ["Effects",&"effects",skin_data.effects],
		sounds_tree :   ["SFX",&"sfx",skin_data.sfx],
		gui_tree :   ["GUI",&"gui",skin_data.gui],
		animation_tree :   ["Animations",&"animations",skin_data.animations],
		background_tree :   ["Background",&"background",skin_data.background_scene],
	}
	
	for subtree : EditorSubTree in subtrees_data.keys():
		var subtree_metadata : EditorTreeItemMetadata = EditorTreeItemMetadata.new(ITEM_TYPE.ROOT, subtree, null)
		var subtree_name : String = subtrees_data[subtree][0]
		var icon_uid : StringName = subtrees_data[subtree][1]
		var skin_subdata : Variant = subtrees_data[subtree][2]
		var subtree_root : TreeItem = _create_item(subtree_name, icon_uid, subtree_metadata, skin_tree_root)
		
		subtree.root = subtree_root
		subtree.parent_tree = self
		subtree.copy_manager = copy_manager
		subtree.undo_manager = undo_manager
		subtree.property_editor_manager = property_editor_manager
		
		subtree.build(skin_subdata)


## Called when some tree item is selected.
func _on_item_selected() -> void:
	var selected_item : TreeItem = get_selected()
	if selected_item == null : return
	var item_metadata : Variant = selected_item.get_metadata(0)
	if not item_metadata or item_metadata is not EditorTreeItemMetadata : return
	
	item_metadata.parent_subtree.select_item(selected_item)

## Called when some tree item name is changed.
func _on_item_edited() -> void:
	var selected_item : TreeItem = get_selected()
	if selected_item == null : return
	var item_metadata : Variant = selected_item.get_metadata(0)
	if not item_metadata or item_metadata is not EditorTreeItemMetadata : return
	
	item_metadata.parent_subtree.edit_item_name(selected_item)

## Called when mouse presses on some tree item.
func _on_item_mouse_selected(mouse_position : Vector2, mouse_button_index : int) -> void:
	if mouse_button_index != MOUSE_BUTTON_RIGHT : return
	
	var selected_item : TreeItem = get_selected()
	if selected_item == null : return
	var item_metadata : Variant = selected_item.get_metadata(0)
	if not item_metadata or item_metadata is not EditorTreeItemMetadata : return
	
	item_metadata.parent_subtree.show_item_options(selected_item, options_popup, mouse_position)

## Deletes currently selected tree item.
func _delete_selected_item() -> void:
	var selected_item : TreeItem = get_selected()
	if selected_item == null : return
	var item_metadata : Variant = selected_item.get_metadata(0)
	if not item_metadata or item_metadata is not EditorTreeItemMetadata : return
	
	item_metadata.parent_subtree.remove_item(selected_item)


## Drags [TreeItem] from some place of the tree
func _get_drag_data(at_position: Vector2) -> Variant:
	var selected_item : TreeItem = get_item_at_position(at_position)
	if selected_item == null : return null
	
	var selected_item_metadata : EditorTreeItemMetadata = selected_item.get_metadata(0)
	if not selected_item_metadata or selected_item_metadata is not EditorTreeItemMetadata : return null
	
	if selected_item_metadata.type == ITEM_TYPE.ROOT \
	or selected_item_metadata.type == ITEM_TYPE.BLOCK_PRESET \
	or selected_item_metadata.type == ITEM_TYPE.SFX_PRESET \
	or selected_item_metadata.type == ITEM_TYPE.EFFECT_PRESET \
	or selected_item_metadata.type == ITEM_TYPE.GUI_MODIFIER_PRESET \
	or selected_item_metadata.type == ITEM_TYPE.EFFECT_ANIMATION \
	or selected_item_metadata.type == ITEM_TYPE.BACKGROUND_ANIMATION : return null
	
	drop_mode_flags = DROP_MODE_INBETWEEN | DROP_MODE_ON_ITEM
	
	var drag_and_drop_preview_instance : ColorRect = _drag_and_drop_preview.instantiate()
	drag_and_drop_preview_instance.get_node("Icon").texture = selected_item.get_icon(0)
	drag_and_drop_preview_instance.get_node("Label").text = selected_item.get_text(0)
	set_drag_preview(drag_and_drop_preview_instance)
	
	return selected_item

## Checks if [TreeItem] can be dropped into position
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data is not TreeItem : return false
	var dragged_item : TreeItem = data
	
	var target_item : TreeItem = get_item_at_position(at_position)
	if dragged_item == target_item : return false
	
	var target_item_metadata : EditorTreeItemMetadata = target_item.get_metadata(0)
	if not target_item_metadata or target_item_metadata is not EditorTreeItemMetadata : return false
	
	return target_item_metadata.parent_subtree.can_drop_item(dragged_item, target_item, get_drop_section_at_position(at_position))

## Drops currently dragging [TreeItem]
func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data is not TreeItem : return
	var dragged_item : TreeItem = data
	
	var target_item : TreeItem = get_item_at_position(at_position)
	if dragged_item == target_item : return
	
	var target_item_metadata : EditorTreeItemMetadata = target_item.get_metadata(0)
	if not target_item_metadata or target_item_metadata is not EditorTreeItemMetadata : return
	
	target_item_metadata.parent_subtree.drop_item(dragged_item, target_item, get_drop_section_at_position(at_position))


func _input(event: InputEvent) -> void:
	if not has_focus() : return
	if event.is_action_pressed("ui_delete"): _delete_selected_item()


## Called by [EditorCopyManager] when object paste is requested
func _on_paste_requested() -> void:
	var selected_item : TreeItem = get_selected()
	if selected_item == null : return
	var item_metadata : Variant = selected_item.get_metadata(0)
	if not item_metadata or item_metadata is not EditorTreeItemMetadata : return
	
	var item_metadata_to_paste : Variant = copy_manager.get_paste_object(EditorCopyManager.COPY_TYPE.TREE_ITEM)
	if item_metadata_to_paste == null : return
	
	item_metadata.parent_subtree.paste_item(selected_item, item_metadata_to_paste)

## Called by [EditorCopyManager] when object copy is requested
func _on_copy_requested() -> void:
	var selected_item : TreeItem = get_selected()
	if selected_item == null : return
	var item_metadata : Variant = selected_item.get_metadata(0)
	if not item_metadata or item_metadata is not EditorTreeItemMetadata : return
	
	copy_manager.copy_object(item_metadata)

## Called by [EditorCopyManager] when object cut is requested
func _on_cut_requested() -> void:
	var selected_item : TreeItem = get_selected()
	if selected_item == null : return
	var item_metadata : Variant = selected_item.get_metadata(0)
	if not item_metadata or item_metadata is not EditorTreeItemMetadata : return
	
	copy_manager.cut_object(_delete_selected_item, item_metadata)
