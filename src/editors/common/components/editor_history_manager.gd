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

var _instance_buffer : Array[RefCounted] = [] ## Contains references to object instances, at which undo/redo functions must be called.
var _undo_buffer : Array[Callable] = [] ## Contains callables which can undo previously made by user actions.
var _redo_buffer : Array[Callable] = [] ## Contains callables which can redo previously undone actions.

var _current_undo_index : int = -1 ## Pointer to latest made action to undo
var _current_redo_index : int = -1 ## Pointer to latest undone action to redo

var _is_tracking : bool = true ## If false, actions wouldn't be tracked
var is_tracking : bool = true ## If false, actions wouldn't be tracked


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_redo") : redo()
	elif event.is_action_pressed("ui_undo") : undo()

func track(object : RefCounted, undo_action : Callable, redo_action : Callable) -> void:
	if not is_tracking or not _is_tracking: return
	
	for i : int in range(_current_undo_index, _undo_buffer.size() - 1):
		_undo_buffer.pop_back()
		_redo_buffer.pop_back()
		_instance_buffer.pop_back()
	
	_instance_buffer.append(object)
	_undo_buffer.append(undo_action)
	_redo_buffer.append(redo_action)
	_current_undo_index += 1
	_current_redo_index = -1

func undo() -> void:
	if _undo_buffer.is_empty() or _current_undo_index < 0: return
	
	_is_tracking = false
	_undo_buffer[_current_undo_index].call()
	_is_tracking = true
	
	_current_redo_index = _current_undo_index
	_current_undo_index -= 1

func redo() -> void:
	if _redo_buffer.is_empty() or _current_redo_index < 0 or _current_redo_index >= _redo_buffer.size(): return
	
	_is_tracking = false
	_redo_buffer[_current_redo_index].call()
	_is_tracking = true
	
	_current_redo_index += 1
	_current_undo_index += 1
