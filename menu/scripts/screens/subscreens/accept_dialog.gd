# Project Luminext - an advanced open-source Lumines spiritual successor
# Copyright (C) <2024> <unfavorable_enhancer>
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

signal closed(result : bool)

var desc_text : String = "" : 
	set(text) : $ColorRect/Dialog.text = text

var accept_function : Callable
var cancel_function : Callable
var is_accepted : bool = false


func _ready() -> void:
	menu.screens["foreground"]._raise()
	
	await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


func _cancel() -> void:
	if cancel_function : cancel_function.call()
	
	closed.emit(false)
	
	_remove()


func _accept() -> void:
	if accept_function : accept_function.call()
	
	closed.emit(true)
	
	_remove()
