# Project Luminext - an advanced open-source Lumines spiritual successor
# Copyright (C) <2024-2025> <unfavorable_enhancer>
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


extends MenuScreen

##-----------------------------------------------------------------------
## Special dialog for confirming various player actions
##-----------------------------------------------------------------------

signal closed(result : bool) ## Emitted when dialog is closed and returns true if player confirmed action, otherwise returns false

var desc_text : String = "" : ## Dialog description text
	set(text) : $ColorRect/Dialog.text = text

var accept_function : Callable ## Function will will be called on confirmation accept
var cancel_function : Callable ## Function will will be called on confirmation cancel


func _ready() -> void:
	parent_menu.screens["foreground"]._raise()
	
	await parent_menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


## Cancels confirmation
func _cancel() -> void:
	if cancel_function : cancel_function.call()
	closed.emit(false)
	_remove()


## Accepts confirmation
func _accept() -> void:
	if accept_function : accept_function.call()
	closed.emit(true)
	_remove()
