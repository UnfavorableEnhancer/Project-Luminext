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

var dependencies : Dictionary[StringName, Variant] = {} ## Some additional dependencies required for some editors work

var _loaded_editors : Dictionary[EDITOR_TYPE, PropertyEditor] = {}

var currently_opened_editor : PropertyEditor = null


## Opens valid and loaded editor for passed object
func open_editor(object : Variant) -> bool :
	if currently_opened_editor != null : $Margin.remove_child(currently_opened_editor)
	currently_opened_editor = null
	
	var editor_type : EDITOR_TYPE
	var object_subtree : EditorSubTree = null
	
	if object is EditorTreeItemMetadata:
		object_subtree = object.parent_subtree
		object = object.object
		
		if object is SkinBlockData.SkinBlock : editor_type = EDITOR_TYPE.SKIN_BLOCK 
		else : return false
	else : return false
	
	if not _loaded_editors.has(editor_type) or _loaded_editors[editor_type] == null :
		if EDITOR_PATHS[editor_type].is_empty() : return false
		
		var editor : PropertyEditor = load(EDITOR_PATHS[editor_type]).instantiate()
		editor.copy_manager = copy_manager
		editor.undo_manager = undo_manager
		_loaded_editors[editor_type] = editor
		
	currently_opened_editor = _loaded_editors[editor_type]
	
	var display_viewport : SubViewportContainer = viewport_manager.get_display_viewport_for_object(object)
	if display_viewport == null : return false
	
	currently_opened_editor.dependencies = dependencies
	currently_opened_editor.file_browser = file_browser
	currently_opened_editor.copy_manager = copy_manager
	currently_opened_editor.undo_manager = undo_manager
	
	$Margin.add_child(currently_opened_editor)
	currently_opened_editor.open_object(object, display_viewport, object_subtree)
	return true


func close_editor() -> void:
	if currently_opened_editor != null : $Margin.remove_child(currently_opened_editor)
	currently_opened_editor = null
