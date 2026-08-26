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
## Allows to edit animation playback pattern, which is tied to music beats
##
class_name AnimatedTextureSequencePropertyEditor

signal pattern_changed(index : int, on : bool)

var current_pattern : Array[bool] = [false, false, false, false,
									false, false, false, false,
									false, false, false, false,
									false, false, false, false]

var _record : bool = true


## Sets text above editor
func set_label_text(value_name : String) -> void:
	$Name.text = value_name

## Sets beat pattern
func set_value(new_pattern : int) -> void:
	_record = false
	
	for i : int in range(16):
		current_pattern[i] = new_pattern & (1 << i)
		get_node("H/B" + str(i + 1)).button_pressed = current_pattern[i]
	
	_record = true

func _on_b_toggled(toggled_on : bool, index : int) -> void:
	if not _record : return
	
	current_pattern[index] = toggled_on
	pattern_changed.emit(index, toggled_on)
