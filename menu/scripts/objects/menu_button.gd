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

#-----------------------------------------------------------------------
# Button used in main menu screen for next menu screen selection
#-----------------------------------------------------------------------

## Avaiable to show button layouts when this button is selected
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

@export_multiline var description : String = "" ## Description shown when button is selected
@export_multiline var disabled_description : String = "" ## Description shown when button is disabled
@export var button_layout : MENU_BUTTON_LAYOUT = MENU_BUTTON_LAYOUT.UP_DOWN_SELECT ## Button layout foreground menu screen will show when this button is selected
@export var button_color : Color ## Selected button color


func _ready() -> void:
	super()
	
	if is_off:
		button_color = Color(0.5,0.5,0.5,1.0)
		$Info.text = tr(disabled_description)
	else:
		$Info.text = tr(description)
	
	selected.connect(_selected)
	deselected.connect(_deselected)
	disable_toggled.connect(_disabled)
	
	$Label.text = tr(text)
	$Icon.texture = icon


func _process(_delta : float) -> void:
	$Label.text = text
	$Icon.texture = icon
	$Back.color = button_color


## Called when button is pressed [br]
## **'silent'** - If true, no press sound will play
func _work(silent : bool = false) -> void:
	if parent_menu.is_locked or parent_menu.current_screen_name != parent_screen.snake_case_name: 
		return
	
	if is_off:
		var tween : Tween = create_tween()
		tween.tween_property(self,"modulate",Color.RED,0.1)
		tween.tween_property(self,"modulate",Color(0.5,0.5,0.5,1.0),0.1)
		parent_menu._play_sound("error")
		return
	
	create_tween().tween_property($Back/Glow,"modulate:a",0.0,0.5).from(1.0)
	if not silent and press_sound_name.begins_with("announce") : parent_menu._play_sound("confirm")
	
	super(silent)


## Called when this button is selected
func _selected() -> void:
	parent_menu._play_sound("select")

	var foreground_screen : MenuScreen = parent_menu.screens["foreground"]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(button_layout)
	
	var tween : Tween = create_tween()
	tween.tween_property($Back,"scale:y",1.0,0.1).from(0.5)
	tween.parallel().tween_property($Icon,"scale",Vector2(2.8,2.8),0.1)
	tween.parallel().tween_property($Back/Glow,"modulate:a",0.0,0.2).from(0.5)
	
	$Info.modulate.a = 1.0
	custom_minimum_size.y = 128


## Called when this button is deselected
func _deselected() -> void:
	var tween : Tween = create_tween()
	tween.tween_property($Back,"scale:y",1.0,0.1).from(1.25)
	tween.parallel().tween_property($Icon,"scale",Vector2(1.0,1.0),0.1)
	
	$Info.modulate.a = 0.0
	custom_minimum_size.y = 56


## Called when this button disabled state changes
func _disabled(on : bool) -> void:
	is_off = on
	if is_off : 
		modulate = Color(0.5,0.5,0.5,1.0)
		$Info.text = tr(disabled_description)
	else: 
		modulate = Color.WHITE
		$Info.text = tr(description)
