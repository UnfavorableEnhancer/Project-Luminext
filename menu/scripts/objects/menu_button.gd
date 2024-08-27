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


@tool
extends MenuSelectableButton

enum MENU_BUTTON_LAYOUT{
	EMPTY,
	UP_DOWN_SELECT,
	SELECT,
	CHANGE_INPUT,
	SKIN_SELECT,
	PLAYLIST_SELECT,
	SLIDER,
	MAIN_MENU
}

@export_multiline var description : String = "" # Description shown on button select
@export var button_layout : MENU_BUTTON_LAYOUT = MENU_BUTTON_LAYOUT.UP_DOWN_SELECT # Button layout which user can use now
@export var button_color : Color


func _ready() -> void:
	super()
	
	if disabled:
		button_color = Color.GRAY
	
	selected.connect(_selected)
	deselected.connect(_deselected)
	
	$Label.text = tr(text)
	$Info.text = tr(description)
	$Icon.texture = icon


func _process(_delta : float) -> void:
	$Label.text = text
	$Icon.texture = icon
	$Back.color = button_color


func _work(silent : bool = false) -> void:
	if Data.menu.is_locked or Data.menu.current_screen_name != parent_screen.snake_case_name: 
		return
	
	create_tween().parallel().tween_property($Back/Glow,"modulate:a",0.0,0.5).from(1.0)
	if not silent and press_sound_name.begins_with("announce") : Data.menu._sound("confirm")
	
	super(silent)


func _selected() -> void:
	Data.menu._sound("select")

	var foreground_screen : MenuScreen = Data.menu.screens["foreground"]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(button_layout)
	
	var tween : Tween = create_tween()
	tween.tween_property($Back,"scale:y",1.0,0.1).from(0.5)
	tween.parallel().tween_property($Icon,"scale",Vector2(2.8,2.8),0.1)
	tween.parallel().tween_property($Back/Glow,"modulate:a",0.0,0.2).from(0.5)
	
	$Info.modulate.a = 1.0
	custom_minimum_size.y = 128


func _deselected() -> void:
	var tween : Tween = create_tween()
	tween.tween_property($Back,"scale:y",1.0,0.1).from(1.25)
	tween.parallel().tween_property($Icon,"scale",Vector2(1.0,1.0),0.1)
	
	$Info.modulate.a = 0.0
	custom_minimum_size.y = 56
