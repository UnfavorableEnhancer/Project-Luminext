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


@tool # TODO : Remove when building release build
extends MenuSelectableButton

enum MENU_BUTTON_LAYOUT{
	EMPTY,
	UP_DOWN_SELECT,
	SELECT,
	CHANGE_INPUT,
	SKIN_SELECT,
	PLAYLIST_SELECT,
	SLIDER,
	MAIN_MENU,
	TOGGLE_UP_DOWN,
	TOGGLE,
	SYNTHESIA_SONG,
	TA_TIME,
	PROFILE,
	LOGIN_PROFILE,
	LOGIN,
	SCROLL,
	SOUND_REPLAY,
	PAUSE,
	GAMEOVER,
}

@export var description_node : Node # Text node which will show this button description

@export var glow_color : Color

@export_multiline var description : String = "" # Description shown on button select
@export var button_layout : MENU_BUTTON_LAYOUT = MENU_BUTTON_LAYOUT.UP_DOWN_SELECT # Button layout which user can use now

@export var is_setting_button : bool = false # Is this slider used for setting profile config values


func _ready() -> void:
	super()
	
	selected.connect(_selected)
	deselected.connect(_deselected)
	if work_mode == WORK_MODE.TOGGLE : selection_toggled.connect(_toggled)

	$Label.text = tr(text)
	

func _process(_delta : float) -> void:
	$Label.text = text


func _selected() -> void:
	Data.menu._sound("select")

	var foreground_screen : MenuScreen = Data.menu.screens["foreground"]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(button_layout)
	
	if not description_node == null:
		description_node.text = description
	
	$Back.color = glow_color
	$Back.color.a = 0.75
	create_tween().tween_property($Back/Glow,"modulate:a",0.0,0.2).from(0.5)


func _deselected() -> void:
	$Back.color = Color(0.24,0.24,0.24,0.75)


func _toggled(on : bool) -> void:
	$IO.text = tr("ON") if is_toggled else tr("OFF")

	if is_setting_button:
		Data.profile._assign_setting(call_string, on)
	

func _set_toggle_by_data(data_dict : Dictionary) -> void:
	is_toggled = false
	for category : String in ["audio","video","controls","misc","gameplay"]:
		if data_dict[category].has(call_string) : 
			is_toggled = data_dict[category][call_string]
			break

	$IO.text = tr("ON") if is_toggled else tr("OFF")
