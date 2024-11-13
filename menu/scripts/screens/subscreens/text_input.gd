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
signal closed_text(text : String)

var desc_text : String = "" :
	set(text) : $ColorRect/Label.text = text

var accept_function : Callable
var cancel_function : Callable


func _ready() -> void:
	menu.screens["foreground"]._raise()

	await menu.all_screens_added
	$ColorRect/Name.grab_focus()

	await $ColorRect/Name.text_submitted
	var input : String = $ColorRect/Name.text

	if input.is_empty():
		Data.menu._sound("cancel")
		if cancel_function : cancel_function.call(input)
		closed.emit(false)
		closed_text.emit("")
	else:
		Data.menu._sound("confirm3")
		if accept_function : accept_function.call(input)
		closed.emit(true)
		closed_text.emit(input)
	
	_remove()


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if cancel_function : cancel_function.call("")
		closed.emit(false)
		closed_text.emit("")
		_remove()
