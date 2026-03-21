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
	ROOT, ## Links to sub-tree root # NOTE : Cannot be moved at all and cannot be copy/pasted
	VARIANT, ## Links to any skin sub-structure data (blocks, effects, sfx, gui) variant # NOTE : Cannot be moved at all
	BLOCK, ## Links to skin block # NOTE : Can be moved only inside own variant or to other blocks variant
	SFX, ## Links to skin sound effect # NOTE : Can be moved only inside own variant or to other sound effects variant
	EFFECT, ## Links to skin visual effect # NOTE : Can be moved only inside own variant or to other visual effects variant
	GUI_MODIFIER, ## Links to an GUI modifier object # NOTE : Can be moved only inside own variant or to other GUI modifiers variant
	SCENE_OBJECT ## Links to an skin background or visual effect scene object # NOTE : Can be moved only inside scene
}

const TREE_ICON_SIZE : int = 16 ## Size of the icon (height and width) used in all tree items

static var _tree_icons_tex : Texture = null ## Texture used for tree items icons atlas

## Defines regions for cutting "_tree_icons_tex" atlas
var _tree_icons_regions : Dictionary[StringName, Rect2i] = {
	&"none" : Rect2i(TREE_ICON_SIZE * 4, TREE_ICON_SIZE * 4, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"variant" : Rect2i(TREE_ICON_SIZE * 0, TREE_ICON_SIZE * 4, TREE_ICON_SIZE, TREE_ICON_SIZE),
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

var skin_data : SkinData = null ## Skin data to view and edit.

var metadata_tree : SEMetadataTree = SEMetadataTree.new() ## Contains skin metadata TreeItem
var blocks_tree : SEBlocksTree = SEBlocksTree.new() ## Contains TreeItem's related to skin blocks
var effects_tree : SEEffectsTree = SEEffectsTree.new() ## Contains TreeItem's related to skin visual effects
var sounds_tree : SESFXTree = SESFXTree.new() ## Contains TreeItem's related to skin sound effects
var gui_tree : SEGUIModifiersTree = SEGUIModifiersTree.new() ## Contains TreeItem's related to skin GUI modifiers
var animation_tree : SEAnimationsTree = SEAnimationsTree.new() ## Contains TreeItem's related to skin background scene animations
var background_tree : SEBackgroundSceneTree = SEBackgroundSceneTree.new() ## Contains TreeItem's related to skin background scene nodes

@export var undo_manager : EditorHistoryManager ## Used to add undo/redo commands
@export var copy_manager : EditorCopyManager ## Used to handle TreeItem's copy/paste

@export var options_popup : PopupMenu ## Called on some TreeItem right mouse click and shows options to do with it
@export var confirm_dialog : Control ## Shows some confirmation message
@export var message_dialog : Control ## Shows some warning or error message


func _ready() -> void:
	if _tree_icons_tex == null : _tree_icons_tex = load("res://assets/textures/editors/skin_editor/tree_icons_80.png")
	if not tree_icons.is_empty(): return
	
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
func _create_item(text : String, icon_uid : StringName = &"none", metadata : ItemMetadata = null, parent : TreeItem = null) -> TreeItem:
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
	
	var subtrees_data : Dictionary[SubTree, Array] = {
		metadata_tree :   ["Metadata",&"metadata",skin_data.metadata],
		blocks_tree :   ["Blocks",&"blocks",skin_data.blocks],
		effects_tree :   ["Effects",&"effects",skin_data.effects],
		sounds_tree :   ["SFX",&"sfx",skin_data.sfx],
		gui_tree :   ["GUI",&"gui",skin_data.gui],
		animation_tree :   ["Animations",&"animations",skin_data.animations],
		background_tree :   ["Background",&"background",skin_data.background_scene],
	}
	
	for subtree : SubTree in subtrees_data.keys():
		var subtree_metadata : ItemMetadata = ItemMetadata.new(ITEM_TYPE.ROOT, subtree, null)
		var subtree_name : String = subtrees_data[subtree][0]
		var icon_uid : StringName = subtrees_data[subtree][1]
		var skin_subdata : Variant = subtrees_data[subtree][2]
		var subtree_root : TreeItem = _create_item(subtree_name, icon_uid, subtree_metadata, skin_tree_root)
		
		subtree.root = subtree_root
		subtree.skin_tree = self
		subtree.asset_data = skin_data.assets
		subtree.copy_manager = copy_manager
		subtree.undo_manager = undo_manager
		
		subtree.build_tree(skin_subdata)


## Called when some tree item name is changed.
func _on_item_edited() -> void:
	var selected_item : TreeItem = get_selected()
	if selected_item == null : return
	
	for subtree : SubTree in [metadata_tree, blocks_tree, effects_tree, sounds_tree, gui_tree, animation_tree, background_tree]:
		if subtree.edit_item_name(selected_item) : break

## Called when some tree item is selected.
func _on_item_selected() -> void:
	var selected_item : TreeItem = get_selected()
	if selected_item == null : return
	
	for subtree : SubTree in [metadata_tree, blocks_tree, effects_tree, sounds_tree, gui_tree, animation_tree, background_tree]:
		if subtree.select_item(selected_item) : break

## Called when mouse presses on some tree item.
func _on_item_mouse_selected(mouse_position : Vector2, mouse_button_index : int) -> void:
	if mouse_button_index != MOUSE_BUTTON_RIGHT : return
	
	var selected_item : TreeItem = get_selected()
	if selected_item == null : return
	
	for subtree : SubTree in [metadata_tree, blocks_tree, effects_tree, sounds_tree, gui_tree, animation_tree, background_tree]:
		if subtree.show_item_options(selected_item, options_popup, mouse_position) : break

func _delete_selected_item() -> void:
	var selected_item : TreeItem = get_selected()
	if selected_item == null : return
	
	for subtree : SubTree in [metadata_tree, blocks_tree, effects_tree, sounds_tree, gui_tree, animation_tree, background_tree]:
		if subtree.remove_item(selected_item) : break


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_delete"): _delete_selected_item()


func _on_paste_requested() -> void:
	var selected_item : TreeItem = get_selected()
	if selected_item == null : return
	
	var item_metadata : Variant = copy_manager.get_paste_object(EditorCopyManager.COPY_TYPE.SE_TREE_ITEM)
	if item_metadata == null : return
	
	for subtree : SubTree in [metadata_tree, blocks_tree, effects_tree, sounds_tree, gui_tree, animation_tree, background_tree]:
		@warning_ignore("unsafe_call_argument")
		if subtree.paste_item(selected_item, item_metadata) : break

func _on_copy_requested() -> void:
	var selected_item : TreeItem = get_selected()
	if selected_item == null : return
	
	var item_metadata : Variant = selected_item.get_metadata(0)
	if item_metadata == null : return
	
	copy_manager.insert_object_to_copy(item_metadata)

func _on_cut_requested() -> void:
	var selected_item : TreeItem = get_selected()
	if selected_item == null : return
	
	var item_metadata : Variant = selected_item.get_metadata(0)
	if item_metadata == null : return
	
	copy_manager.cut_object(_delete_selected_item, item_metadata)


## Interface for making sub-trees, each representing own skin data sub-structure (ex. [SkinBlockData] or [SkinEffectData])
@abstract class SubTree:
	var asset_data : SkinAssetData = null ## Skin sub-structure which contains all assets (images, audio, video and etc.)
	
	var root : TreeItem = null ## Root TreeItem of this sub-tree
	var skin_tree : SkinEditorTree = null ## Parent skin editor tree instance.
	
	var copy_manager : EditorCopyManager
	var undo_manager : EditorHistoryManager

	## Helper function to create TreeItem with specified text, icon, metadata and parent
	func _create_item(text : String, icon_uid : StringName = &"none", metadata : ItemMetadata = null, parent : TreeItem = null) -> TreeItem:
		var item : TreeItem = skin_tree.create_item(parent)
		item.set_text(0, text)
		item.set_icon(0, SkinEditorTree.tree_icons[icon_uid])
		
		if metadata != null : 
			metadata.owner = item
			item.set_metadata(0, metadata)
		
		return item

	## Helper function, which returns **true** if item exists in this sub-tree
	func _is_item_valid(item : TreeItem) -> bool:
		if item == root : return true 
		
		var scan_func : Callable
		scan_func = func(item_to_scan : TreeItem, target : TreeItem, rec_scan_func : Callable) -> bool:
			var success : bool = false
			if item_to_scan == target : return true
			if item_to_scan.get_child_count() == 0 : return false
				
			for subitem : TreeItem in item_to_scan.get_children():
				if subitem == target : return true
				success = rec_scan_func.call(subitem, target, rec_scan_func)
			
			return success
		
		return scan_func.call(root, item, scan_func)


	## Builds this sub-tree using passed skin sub-structure **data**.
	@abstract func build_tree(new_data : Variant) -> bool
	
	## Called by root tree when some item is selected.[br]
	## Returns **true** if selected item exists in this sub-tree and selected successfully.
	@abstract func select_item(item : TreeItem) -> bool
	## Called by root tree when some item name is edited.[br]
	## Returns **true** if selected item exists in this sub-tree and processed successfully.
	@abstract func edit_item_name(item : TreeItem) -> bool
	## Called by root tree when some item is right clicked.[br]
	## Returns **true** if selected item exists in this sub-tree and options popup is built successfully.
	@abstract func show_item_options(item : TreeItem, options_popup : PopupMenu, mouse_position : Vector2) -> bool
	
	## Adds new item to this sub-tree and creates respective object for current skin sub-structure **data**.
	#@abstract func _add_item() -> void
	## Duplicates selected subtree item data.
	@abstract func duplicate_item(item : TreeItem) -> bool
	## Removes item from this sub-tree and removes respective object from current skin sub-structure **data**.
	@abstract func remove_item(item : TreeItem) -> bool
	## Resolves pasted by copy manager item metadata to decide if item copy can be created
	@abstract func paste_item(selected_item : TreeItem, item_metadata : ItemMetadata) -> bool


## Container for all [SubTree] items metadata
class ItemMetadata:
	var type : ITEM_TYPE ## Type of this ItemTree
	var owner : TreeItem ## Owner ItemTree instance
	var parent_subtree : SubTree ## Parent [SubTree]
	var object : Variant ## Object this item represents

	func _init(input_type : ITEM_TYPE, input_subtree : SubTree, input_object : Variant) -> void:
		type = input_type
		parent_subtree = input_subtree
		object = input_object
	
	## Returns correct copy of this ItemMetadata
	func duplicate() -> ItemMetadata:
		if type == ITEM_TYPE.ROOT : return null
		var copy : ItemMetadata = ItemMetadata.new(type, parent_subtree, null)
		copy.owner = null
		
		if type in [ITEM_TYPE.BLOCK, ITEM_TYPE.SFX, ITEM_TYPE.EFFECT, ITEM_TYPE.GUI_MODIFIER, ITEM_TYPE.SCENE_OBJECT]:
			copy.object = object.duplicate() # TODO : Implement duplicate for all ModdableAssets
		
		return copy
