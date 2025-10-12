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


extends Node2D

##-----------------------------------------------------------------------
## Controls game UI which depends on currently played gamemode
##-----------------------------------------------------------------------

class_name Foreground

signal style_changed ## Emitted when GUI style is changed

var ui_elements : Dictionary[String, UIElement] ## All currently existing [UIElements]
var is_changing : bool = false ## True if GUI style is currently changing


## Removes all UI elements
func _reset() -> void:
	for element_name : String in ui_elements.keys():
		ui_elements[element_name].queue_free()
		ui_elements.erase(element_name)


## Adds new [UIElement] with name **'element_name'** and returns its instance
func _add_ui_element(element_name : String) -> UIElement:
	var element : UIElement = load("res://scenery/game/foreground/" + element_name + ".tscn").instantiate()
	ui_elements[element_name] = element
	add_child(element)
	return element


## Removes existing [UIElement] with name **'element_name'**
func _remove_ui_element(element_name : String) -> void:
	if ui_elements.has(element_name):
		ui_elements[element_name].queue_free()
		ui_elements.erase(element_name)


## Changes style of all UI elements with fade-out animation [br]
## - **'skin_data'** - [SkinData] which will be used to define UI elements visuals [br]
## - **'speed'** - defines speed factor of fade-out animation
func _change_style(skin_data : SkinData, transition_time : float = 1.0) -> void:
	if is_changing : return
	is_changing = true

	if transition_time < 0.01:
		for ui_element : UIElement in ui_elements.values(): 
			ui_element._change_style(skin_data)
		
		is_changing = false
		return

	var tween : Tween = create_tween()

	# Fade-out-in animation
	tween.tween_property(self, "modulate:a", 0.0, transition_time).from(1.0)
	tween.tween_property(self, "modulate:a", 1.0, transition_time)

	await tween.step_finished

	for ui_element : UIElement in ui_elements.values(): 
		ui_element._change_style(skin_data)

	await tween.step_finished

	style_changed.emit()
	is_changing = false
