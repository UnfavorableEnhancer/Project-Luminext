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

var desc_text : String = ""
var object_to_call : Variant
var call_function_name : String = ""
var cancel_function_name : String = ""


func _ready() -> void:
	menu.screens["foreground"]._raise()


func _start() -> void:
	$ColorRect/Label.text = desc_text
	await create_tween().tween_interval(0.5).finished
	
	$ColorRect/Name.grab_focus()
	await $ColorRect/Name.text_submitted
	
	var input : String = $ColorRect/Name.text
	
	if input.is_empty():
		Data.menu._sound("cancel")
		if not cancel_function_name.is_empty():
			object_to_call.call(cancel_function_name, $ColorRect/Name.text)
	else:
		Data.menu._sound("confirm3")
		object_to_call.call(call_function_name, $ColorRect/Name.text)
	
	_remove()


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_remove()
