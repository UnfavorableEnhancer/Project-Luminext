# Project Luminext - an ultimate block-stacking puzzle game
# Copyright (C) <2024-2026> <unfavorable_enhancer>
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

extends ColorRect
##
## Contains all possible property editors scenes paths and decides which property editor to use for passed object.
##
class_name PropertyEditorManager

enum EDITOR_TYPE {
	NONE,
	VARIANT,
	SKIN_METADATA,
	SKIN_BLOCK,
	SKIN_SFX,
	SKIN_EFFECT,
	SKIN_GUI_MODIFIER,
	SKIN_CAMERA,
	ANIMATION,
	SCENERY_NODE,
	SCENERY_SPRITE,
	SCENERY_ANIM_SPRITE,
	SCENERY_PARTICLES,
	SCENERY_VIDEO,
	SCENERY_RECT,
	SCENERY_TEXT,
	SCENERY_SHADER
}

## Contains paths to all avaiable property editors
const EDITOR_PATHS : Dictionary[EDITOR_TYPE, String] = {
	EDITOR_TYPE.NONE : "",
	EDITOR_TYPE.VARIANT : "",
	EDITOR_TYPE.SKIN_METADATA : "",
	EDITOR_TYPE.SKIN_BLOCK : "res://src/editors/skin_editor/property_editor/block_property_editor.tscn",
	EDITOR_TYPE.SKIN_SFX : "",
	EDITOR_TYPE.SKIN_EFFECT : "",
	EDITOR_TYPE.SKIN_GUI_MODIFIER : "",
	EDITOR_TYPE.SKIN_CAMERA : "",
	EDITOR_TYPE.ANIMATION : "",
	EDITOR_TYPE.SCENERY_NODE : "",
	EDITOR_TYPE.SCENERY_SPRITE : "",
	EDITOR_TYPE.SCENERY_ANIM_SPRITE : "",
	EDITOR_TYPE.SCENERY_PARTICLES : "",
	EDITOR_TYPE.SCENERY_VIDEO : "",
	EDITOR_TYPE.SCENERY_TEXT : "",
	EDITOR_TYPE.SCENERY_RECT : "",
	EDITOR_TYPE.SCENERY_SHADER : "",
}

@export var copy_manager : EditorCopyManager  = null ## Parent editor copy manager instance
@export var undo_manager : EditorHistoryManager = null ## Parent editor history manager instance

@export var viewport_manager : EditorViewportManager = null ## Parent editor viewport manager, where currently editing object will be shown
@export var file_browser : FileBrowser = null ## Parent editor file browser

var required_editor_types : Array[EDITOR_TYPE]
var dependencies : Dictionary[StringName, Variant] = {} ## Some additional dependencies required for some editors work

var _loaded_editors : Dictionary[EDITOR_TYPE, PropertyEditor] = {}

var currently_opened_editor : PropertyEditor = null


## Loads all required editors
func load_assets() -> void:
	for i : EDITOR_TYPE in required_editor_types:
		if EDITOR_PATHS[i].is_empty() : continue
		
		var editor : PropertyEditor = load(EDITOR_PATHS[i]).instantiate()
		editor.copy_manager = copy_manager
		editor.undo_manager = undo_manager
		_loaded_editors[i] = editor


## Opens valid and loaded editor for passed object
func open_editor(object : Variant) -> bool :
	if currently_opened_editor != null : $Margin.remove_child(currently_opened_editor)
	currently_opened_editor = null
	
	var editor_type : EDITOR_TYPE
	var tree_item : TreeItem = null
	if object is EditorTreeItemMetadata:
		tree_item = object.owner
		object = object.object
		
		if object is SkinBlockData.SkinBlock : editor_type = EDITOR_TYPE.SKIN_BLOCK 
		else : return false
	else : return false
	
	if not _loaded_editors.has(editor_type) or _loaded_editors[editor_type] == null : return false
	currently_opened_editor = _loaded_editors[editor_type]
	
	match editor_type:
		EDITOR_TYPE.SKIN_BLOCK : 
			if not dependencies.has(&"skin_data") : return false
			currently_opened_editor.block_data = dependencies[&"skin_data"].blocks
			currently_opened_editor.asset_data = dependencies[&"skin_data"].assets
	
	var display_viewport : SubViewportContainer = viewport_manager.get_display_viewport_for_object(object)
	if display_viewport == null : return false
	
	currently_opened_editor.file_browser = file_browser
	currently_opened_editor.copy_manager = copy_manager
	currently_opened_editor.undo_manager = undo_manager
	
	$Margin.add_child(currently_opened_editor)
	currently_opened_editor.open_object(object, display_viewport, tree_item)
	return true
