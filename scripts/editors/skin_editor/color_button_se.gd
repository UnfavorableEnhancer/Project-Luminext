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


extends TextureButton

#-----------------------------------------------------------------------
# This button is used to trigger ColorPicker node and send picked to color to desired entry in textures
#-----------------------------------------------------------------------

@onready var editor : MenuScreen = Data.menu.current_screen

@export var color_name : String = "" # Color entry name this button edits (in SkinData "textures" dictionary)
@export_multiline var description : String = "" # Description shown when button is hovered by mouse

var standard_color : Color # Color this button started with


func _ready() -> void:
	add_to_group("color_buttons")
	
	gui_input.connect(_on_press)
	mouse_entered.connect(_selected)
	
	standard_color = modulate


func _reset_color() -> void:
	modulate = standard_color
	editor.skin_data.textures[color_name] = standard_color


# Called on button press
func _on_press(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if editor.get_node("Hide/Fade2").modulate.a > 0.0 : return
				editor.get_node("A").play("color")
				editor.get_node("Hide/Fade2/ColorRect/ColorPicker").color = modulate
				
				await editor.get_node("Hide/Fade2/ColorRect/Done").pressed
				
				var color : Color = editor._edit_skn_color(color_name)
				editor.get_node("A").play_backwards("color")
				
				if color == null : return
				modulate = color
			
			MOUSE_BUTTON_RIGHT: _reset_color()


# Called when hovered by mouse
func _selected() -> void:
	editor._show_description(description)
