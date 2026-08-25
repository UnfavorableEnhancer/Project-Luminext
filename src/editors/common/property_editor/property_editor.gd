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
extends ScrollContainer
##
## Interface for property editor.
##
class_name PropertyEditor

var copy_manager : EditorCopyManager = null ## Parent editor copy manager instance
var undo_manager : EditorHistoryManager = null ## Parent editor history manager instance
var file_browser : FileBrowser = null ## Parent editor file browser instance

var object_subtree : EditorSubTree ## Currently editing object subtree
var display_viewport : SubViewportContainer ## Sub-viewport where current object instance will be shown
var object_display_instance : Node = null ## Current object instance in shown sub-viewport


@abstract func open_object(new_object : Variant, new_display_viewport : SubViewportContainer, new_object_subtree : EditorSubTree = null, new_object_display_instance : Node = null) -> void
