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

@export var description_node : Node = null # Text node which will show this slider description

# This variables are shown on button selection
@export_multiline var description : String = "" # Description shown on button select
@export var button_layout : int = 5 # Button layout which user can use now

@export var is_setting_slider : bool = true # Is this slider used for setting profile config values


func _ready() -> void:
	super()
	
	selected.connect(_selected)
	deselected.connect(_deselected)
	
	await create_tween().tween_interval(0.1).finished
	value_changed.connect(_on_value_changed)
	
	if is_setting_slider:
		$Power.text = Data.profile._return_setting_value_string(call_string, value)


func _selected() -> void:
	Data.menu._sound("select")

	var foreground_screen : MenuScreen = Data.menu.screens["foreground"]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(6)
	
	if description_node != null:
		description_node.text = description
	
	$Select.visible = true

	create_tween().tween_property($Glow,"modulate:a",0.0,0.2).from(1.0)


func _deselected() -> void:
	$Select.visible = false


func _on_value_changed(to_value : float) -> void:
	Data.menu._sound("select")
	if is_setting_slider:
		$Power.text = Data.profile._return_setting_value_string(call_string, to_value)


func _set_value_by_data(data_dict : Dictionary) -> void:
	if not is_setting_slider: return
	var new_value : float 

	if call_string == "resolution":
		match data_dict["video"]["resolution_x"]:
			1280.0: 
				value = 0
				$Power.text = Data.profile._return_setting_value_string(call_string, 0)
			1360.0:
				value = 1
				$Power.text = Data.profile._return_setting_value_string(call_string, 1)
			1440.0:
				value = 2
				$Power.text = Data.profile._return_setting_value_string(call_string, 2)
			1600.0:
				value = 3
				$Power.text = Data.profile._return_setting_value_string(call_string, 3)
			1680.0:
				value = 4
				$Power.text = Data.profile._return_setting_value_string(call_string, 4)
			1920.0:
				value = 5
				$Power.text = Data.profile._return_setting_value_string(call_string, 5)
			_:
				value = 0
				$Power.text = Data.profile._return_setting_value_string(call_string, 0)
		return

	for category : String in ["audio","video","controls","misc","gameplay"]:
		if data_dict[category].has(call_string): 
			new_value = data_dict[category][call_string]

			value = new_value
			$Power.text = Data.profile._return_setting_value_string(call_string, new_value)
			break
