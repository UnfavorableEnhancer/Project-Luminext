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

extends Control
##
## Allows to edit any passed [SkinData] with special GUI.
##
class_name SkinEditor

var skin_data : SkinData = SkinData.new() ## Currently editing [SkinData] instance. By default a standrad

@onready var skin_data_tree : SkinEditorTree = %SkinTree ## Contains all objects of the [SkinData] sub-structures and allows to select, edit or add new objects

var editor_options_panel ## Contains general editor options (save skin, start playtest, exit the editor and etc.)

@onready var viewport_manager : EditorViewportManager = %ViewportManager ## Shows currently selected in skin tree object (block, effect or scenery element)
@onready var property_editor : PropertyEditorManager = %PropertyEditorManager ## Shows properties of currently selected object

var playback_panel ## Contains playback related options (play, pause and etc.), allows to set skin BPM and shows current playback position
var sequence_editor ## Allows to edit skin sequence, which defines what background animations and music would be played
var animation_editor ## Allows to edit selected animation

@onready var options_popup : PopupMenu = $OptionsPopup ## Called on some object right mouse click and shows options to do with it
@onready var file_browser : FileDialog = $FileBrowser ## Called when some file is requested to be selected from user file system
@onready var confirm_dialog : Control = $Center/ConfirmDialog ## Shows some confirmation message
@onready var message_dialog : Control = $Center/MessageDialog ## Shows some warning or error message




func _ready() -> void:
	property_editor.dependencies[&"skin_data"] = skin_data
	skin_data_tree.build_tree(skin_data)
	
	pass


func load_from_path(file_path : String) -> void:
	pass

func save_to_path(file_path : String) -> void:
	pass
