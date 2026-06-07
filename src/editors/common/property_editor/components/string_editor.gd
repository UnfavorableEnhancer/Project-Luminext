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

extends VBoxContainer
##
## Edits String value
##
class_name TextPropertyEditor

signal value_changed(new_value : String)

var value : String


## Sets property name
func set_property_name(value_name : String) -> void:
	$Name.text = value_name

## Inserts value into editor for update
func insert(new_value : String) -> void:
	value = new_value
	$H/X.text = str(value)

func _on_input_text_changed(new_text: String) -> void:
	value = new_text
	value_changed.emit(value)
