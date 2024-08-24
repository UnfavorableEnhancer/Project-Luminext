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


extends MenuSelectableButton

# warning-ignore-all:return_value_discarded

@export var desc_node_path : NodePath
@export var description : String = "" # Description shown on button select


func _ready():
	connect("selected", Callable(self, "_selected"))
	connect("deselected", Callable(self, "_deselected"))

	if work_mode == WORK_MODE.TOGGLE:
		connect("selection_toggled", Callable(self, "_toggled"))
	else:
		if has_node("IO"):
			$IO.visible = false


func _selected():
	if not desc_node_path.is_empty():
		get_node(desc_node_path).text = description
	
	modulate = Color.CYAN


func _deselected():
	modulate = Color.WHITE


func _toggled(is_toggled):
	$IO.text = tr("ON") if is_toggled else tr("OFF")
