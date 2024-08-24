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

signal accepted
signal canceled
signal closed

var desc_text : String = ""
var object_to_call : Variant = null

var call_function_name : String = ""
var cancel_function_name : String = ""
var call_function_argument : Variant = null
var cancel_function_argument : Variant = null


func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	$ColorRect/Dialog.text = desc_text
	
	menu.screens["foreground"]._raise()
	
	await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


func _cancel() -> void:
	if not cancel_function_name.is_empty() and object_to_call != null:
		if cancel_function_argument == null: object_to_call.call(cancel_function_name)
		else: object_to_call.call(cancel_function_name,cancel_function_argument)
	
	canceled.emit()
	closed.emit()
	_remove()


func _accept() -> void:
	if not call_function_name.is_empty() and object_to_call != null:
		if call_function_argument == null: object_to_call.call(call_function_name)
		else: object_to_call.call(call_function_name,call_function_argument)
	
	accepted.emit()
	closed.emit()
	_remove()
