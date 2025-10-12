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


extends UIElement

const combo_colors : Dictionary[int, Color] = {
	0 : Color(1.0, 0.0, 0.0, 0.0),
	2 : Color(1.0, 1.0, 1.0),
	3 : Color(1.0, 0.8, 0.457),
	4 : Color(0.301, 1.0, 0.738),
	8 : Color(1.0, 0.398, 0.821),
	16 : Color(1.0, 0.285, 0.285),
	24 : Color(0.318, 0.572, 0.969),
	32 : Color(0.594, 0.41, 1.0),
}

var is_shown : bool = false

##-----------------------------------------------------------------------
## Shows current combo amount
##-----------------------------------------------------------------------

func _ready() -> void:
	modulate = combo_colors[0]
	is_shown = false


## Displays passed combo value
func _set_combo(value : int) -> void:
	if value > 1: 
		$H/combo.text = str(value)
		if combo_colors.has(value) : create_tween().tween_property(self, "modulate", combo_colors[value], 0.5)
		is_shown = true
	
	elif value == 0:
		if not is_shown : return
		is_shown = false
		create_tween().tween_property(self, "modulate", combo_colors[0], 0.5)
	
	else : 
		if not is_shown : return
		is_shown = false
		modulate = combo_colors[0]
