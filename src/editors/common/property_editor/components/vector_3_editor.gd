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
## Edits Vector3 value
##
class_name Vector3PropertyEditor

signal value_changed(new_value : Vector3)

var value : Vector3


## Sets text above editor
func set_label_text(value_name : String) -> void:
	$Name.text = value_name

## Sets value into editor
func set_value(new_value : Vector3) -> void:
	value = new_value
	$H/X.text = str(value.x)
	$H/Y.text = str(value.y)
	$H/Z.text = str(value.z)

func _on_x_value_changed(new_value : float) -> void:
	value.x = new_value
	value_changed.emit(value)

func _on_y_value_changed(new_value : float) -> void:
	value.y = new_value
	value_changed.emit(value)

func _on_z_value_changed(new_value : float) -> void:
	value.z = new_value
	value_changed.emit(value)
