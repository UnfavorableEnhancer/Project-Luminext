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


@tool
extends MenuSelectableButton

@export var foreground_screen_name : String = "foreground" ## Used foreground menu screen name
@export var glow_color : Color ## Selected button color
@export var button_layout : int = 0 ## Button layout foreground menu screen will show when this button is selected


func _ready() -> void:
	$Label.text = tr(text)
	$Icon.texture = icon


func _process(_delta : float) -> void:
	$Icon.texture = icon


func _select() -> void:
	super._select()
	
	var foreground_screen : MenuScreen = parent_menu.screens[foreground_screen_name]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(button_layout)
	
	modulate = glow_color


func _deselect() -> void:
	super._deselect()
	
	modulate = Color.WHITE
