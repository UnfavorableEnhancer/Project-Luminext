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


extends CheckButton

#-----------------------------------------------------------------------
# This check button is used to toggle some entries
#-----------------------------------------------------------------------

@export var editor : MenuScreen = null ## Skin editor reference

@export var entry_name : String = "" ## Data entry name inside [SkinData] this button edits
@export_multiline var description : String = "" ## Description shown when button is hovered by mouse


func _ready() -> void:
	toggled.connect(_toggle)
	mouse_entered.connect(_selected)
	
	if text == "ON" : set_pressed_no_signal(true) 


## Called when button is toggled 
func _toggle(on : bool) -> void:
	editor._toggle_skn_data(entry_name, on)
	text = "ON" if on else "OFF"


## Called when hovered by mouse
func _selected() -> void:
	editor._show_description(description)
