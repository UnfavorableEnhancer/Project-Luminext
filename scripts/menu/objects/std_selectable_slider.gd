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


extends MenuSelectableSlider

# warning-ignore-all:return_value_discarded

@export var desc_node_path : NodePath
@export var description : String = '' # Description shown on button select

@export var value_text_path : NodePath


func _ready() -> void:
	connect("selected", Callable(self, "_selected"))
	connect("deselected", Callable(self, "_deselected"))

	await create_tween().tween_interval(0.1).finished

	connect("value_changed", Callable(self, "_on_value_changed"))


func _selected():
	if not desc_node_path.is_empty():
		get_node(desc_node_path).text = description
	
	$Light3D.visible = true


func _deselected():
	$Light3D.visible = false


func _on_value_changed(value):
	get_node(value_text_path).text = Data.profile._return_setting_value_string(call_string, value)
