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

extends PopupMenu
##
## This script allows to bind Callables to each of PopupMenu buttons
##
class_name EditorOptionsPopup

## Contains callables which are going to be called when specific button id is pressed
var binds : Dictionary[int, Callable] = {
	
}


## Clears popup menu and its bindings
func full_clear() -> void:
	clear()
	binds.clear()

## Adds new option with callable assigned to it
func add_option(text : String, callable : Callable) -> void:
	var id : int = binds.size() + 1
	add_item(text, id)
	binds[id] = callable

## Called when some button is pressed
func _on_id_pressed(id: int) -> void:
	if binds.has(id) : binds[id].call()
