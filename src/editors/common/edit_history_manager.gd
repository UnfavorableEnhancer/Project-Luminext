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

extends Node
##
## Keeps track of editor undo/redo actions
##
class_name EditorHistoryManager

var undo_buffer : Array[Callable] = [] ## Contains callables which can undo previously made by user actions
var redo_buffer : Array[Callable] = [] ## Contains callables which can redo previously undone actions
var current_buffer_index : int = 0 ## Current undo/redo buffers index position


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_undo"): undo()
	if event.is_action_pressed("ui_redo"): redo()

func track(undo_action : Callable, redo_action : Callable) -> void:
	var current_rewind_length : int = undo_buffer.size() - current_buffer_index
	if current_rewind_length > 0:
		for i : int in current_rewind_length: 
			undo_buffer.pop_back()
			redo_buffer.pop_back()
	
	undo_buffer.append(undo_action)
	redo_buffer.append(redo_action)
	current_buffer_index = undo_buffer.size()

func undo() -> void:
	if current_buffer_index == 0 : return
	current_buffer_index -= 1
	undo_buffer[current_buffer_index].call()

func redo() -> void:
	if current_buffer_index == undo_buffer.size() : return
	current_buffer_index += 1
	redo_buffer[current_buffer_index].call()
