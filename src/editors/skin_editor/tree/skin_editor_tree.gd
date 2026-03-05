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
	METADATA, ## Links to current skin metadata # NOTE : Cannot be moved at all
	VARIANT, ## Links to any skin sub-structure data (blocks, effects, sfx, gui) variant # NOTE : Cannot be moved at all
	BLOCK, ## Links to skin block # NOTE : Can be moved only inside own variant or to other blocks variant
	SFX, ## Links to skin sound effect # NOTE : Can be moved only inside own variant or to other sound effects variant
	EFFECT, ## Links to skin visual effect # NOTE : Can be moved only inside own variant or to other visual effects variant
	GUI_MODIFIER, ## Links to an GUI modifier object # NOTE : Can be moved only inside own variant or to other GUI modifiers variant
	SCENE_OBJECT ## Links to an skin background or visual effect scene object # NOTE : Can be moved only inside scene
}

const TREE_ICON_SIZE : int = 32 ## Size of the icon (height and width) used in all tree items

static var _tree_icons_tex : Texture = null ## Texture used for tree items icons atlas

## Defines regions for cutting "_tree_icons_tex" atlas
var _tree_icons_regions : Dictionary[StringName, Rect2i] = {
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
	&"rect" : Rect2i(TREE_ICON_SIZE * 0, TREE_ICON_SIZE * 3, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"text" : Rect2i(TREE_ICON_SIZE * 1, TREE_ICON_SIZE * 3, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"gui_mod" : Rect2i(TREE_ICON_SIZE * 2, TREE_ICON_SIZE * 3, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"shader" : Rect2i(TREE_ICON_SIZE * 3, TREE_ICON_SIZE * 3, TREE_ICON_SIZE, TREE_ICON_SIZE),
	&"audio_sync" : Rect2i(TREE_ICON_SIZE * 4, TREE_ICON_SIZE * 3, TREE_ICON_SIZE, TREE_ICON_SIZE),
}

static var tree_icons : Dictionary[StringName, AtlasTexture] = {} ## Ready to use icons for tree items

var skin : SkinData = null ## Skin data to view and edit.

var metadata_tree
var blocks_tree : SkinBlockDataTree
var effects_tree
var sounds_tree
var gui_tree
var animation_tree
var background_tree

@export var options_popup : PopupMenu ## Called on some object right mouse click and shows options to do with it
@export var confirm_dialog : Control ## Shows some confirmation message
@export var message_dialog : Control ## Shows some warning or error message


func _ready() -> void:
	if _tree_icons_tex == null : _tree_icons_tex = load("res://assets/textures/editors/skin_editor/tree_icons.png")
	if not tree_icons.is_empty(): return
	
	for icon_name : StringName in _tree_icons_regions.keys():
		var icon_region : Rect2i = _tree_icons_regions[icon_name]
		var atlas_tex : AtlasTexture = AtlasTexture.new()
		atlas_tex.atlas = _tree_icons_tex
		atlas_tex.region = icon_region
		tree_icons[icon_name] = atlas_tex


## Builds tree from scratch using passed skin data.
func build_tree(skin_data : SkinData) -> void:
	clear()
	
	

## Called when some tree item name is changed.
func _on_item_edited() -> void:
	pass # Replace with function body.

## Called when some tree item is selected.
func _on_item_selected() -> void:
	pass # Replace with function body.

## Called when mouse presses on some tree item.
func _on_item_mouse_selected(mouse_position : Vector2, mouse_button_index : int) -> void:
	pass # Replace with function body.


## Interface for making sub-trees, each representing own skin data sub-structure (ex. [SkinBlockData] or [SkinEffectData])
@abstract class SubTree:
	var root : TreeItem = null ## Used for creating own children
	
	var skin_editor : SkinEditor = null ## Parent skin editor instance.
	var skin_tree : SkinEditorTree = null ## Parent skin editor tree instance.
	
	func _init(new_root : TreeItem) -> void : root = new_root
	
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
	@abstract func show_item_options(item : TreeItem) -> bool
	
	## Adds new item to this sub-tree and creates respective object for current skin sub-structure **data**.
	@abstract func add_item() -> void
	## Removes item from this sub-tree and removes respective object from current skin sub-structure **data**.
	@abstract func remove_item(item : TreeItem) -> void
	
	## Pastes item from parent skin editor copy buffer
	@abstract func paste_item(item : TreeItem) -> void


## Container for all [SubTree] items metadata
class ItemMetadata:
	var type : ITEM_TYPE ## Type of this ItemTree
	var owner : TreeItem ## Owner ItemTree instance
	var parent_subtree : SubTree ## Parent [SubTree]
	var object : Variant ## Object this item represents

	func _init(input_type : ITEM_TYPE, input_owner : TreeItem, input_subtree : SubTree, input_object : Variant) -> void:
		type = input_type
		owner = input_owner
		parent_subtree = input_subtree
		object = input_object
