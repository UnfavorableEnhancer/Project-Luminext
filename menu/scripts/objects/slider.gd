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


extends MenuSelectableSlider

#-----------------------------------------------------------------------
# Slider used in every menu screen
#-----------------------------------------------------------------------

@export var description_node : Node = null ## Description [Label] node reference

@export_multiline var description : String = "" ## Description shown when slider is selected
@export_multiline var disabled_description : String = "" ## Description shown when slider is disabled
@export var button_layout : int = 5 ## Button layout foreground menu screen will show when this slider is selected

@export var is_setting_slider : bool = true ## Is this slider used for setting profile config values
@export var is_setting_gamerule : bool = false ## Is this slider used for setting gamerule config values

var current_description : String = description ## Description this slider currently displays when selected


func _ready() -> void:
	super()
	
	selected.connect(_selected)
	deselected.connect(_deselected)
	disable_toggled.connect(_disabled)
	
	await create_tween().tween_interval(0.1).finished
	value_changed.connect(_on_value_changed)
	
	if is_off:
		modulate = Color(0.5,0.5,0.5,1.0)
		current_description = disabled_description
	else:
		current_description = description

	if is_setting_slider: $Power.text = Player._get_config_value_string(call_string, value)
	if is_setting_gamerule: $Power.text = Player.config.user_ruleset._get_config_value_string(call_string, value)


## Called when this slider is selected
func _selected() -> void:
	parent_menu._play_sound("select")

	var foreground_screen : MenuScreen = parent_menu.screens["foreground"]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(button_layout)
	
	if description_node != null:
		description_node.text = description
	
	$Select.visible = true

	create_tween().tween_property($Glow,"modulate:a",0.0,0.2).from(1.0)


## Called when this slider is deselected
func _deselected() -> void:
	$Select.visible = false


## Called when this slider value changes
func _on_value_changed(to_value : float) -> void:
	parent_menu._play_sound("select")
	if is_setting_slider: $Power.text = Player._get_config_value_string(call_string, to_value)
	if is_setting_gamerule: $Power.text = Player.config.user_ruleset._get_config_value_string(call_string, to_value)


## Sets slider value to its corresponing profile/gamerule setting value
func _set_value_by_data() -> void:
	var data : Variant 
	if is_setting_slider : data = Player._get_config_value(call_string)
	if is_setting_gamerule : data = Player.config.user_ruleset._get_config_value(call_string)
	
	if data == null : 
		Console._log("ERROR! Invalid config setting : " + call_string)
		modulate = Color.RED
		return
	
	value = data
	if is_setting_slider : $Power.text = Player._get_config_value_string(call_string, value)
	if is_setting_gamerule : $Power.text = Player.config.user_ruleset._get_config_value_string(call_string, value)


## Called when this slider disabled state changes
func _disabled(on : bool) -> void:
	if on : 
		modulate = Color(0.5,0.5,0.5,1.0)
		current_description = tr(disabled_description)
	else: 
		modulate = Color.WHITE
		current_description = tr(description)
