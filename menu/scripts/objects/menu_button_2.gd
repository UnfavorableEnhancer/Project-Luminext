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
# Button used in main menu screen for category selection
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
	MAIN_MENU
}

var main_color : Color ## Base button color

@export var desc_node_path : NodePath ## Path to the description [Label] node
@export var label_node_path : NodePath ## Path to the outer [Label] node to display text onto
@export var label_color : Color ## Color of the outer [Label] node when this button is selected

@export var description : String = "" ## Description shown when button is selected
@export var button_layout : MENU_BUTTON_LAYOUT = MENU_BUTTON_LAYOUT.UP_DOWN_SELECT ## Button layout foreground menu screen will show when this button is selected


func _ready() -> void:
	super()
	
	main_color = modulate
	selected.connect(_selected)
	disable_toggled.connect(_disabled)
	$Icon.texture = icon

	if is_off : modulate = Color(0.5,0.5,0.5,1.0)


func _process(_delta : float) -> void:
	$Icon.texture = icon
	$Back.color = label_color


## Called when button is pressed [br]
## **'silent'** - If true, no press sound will play
func _work(silent : bool = false) -> void:
	if is_off:
		var tween : Tween = create_tween()
		tween.tween_property(self,"modulate",Color.RED,0.1)
		tween.tween_property(self,"modulate",Color(0.5,0.5,0.5,1.0),0.1)
		parent_menu._play_sound("error")
		return
	
	super(silent)


## Called when this button is selected
func _selected() -> void:
	parent_menu._play_sound("select")

	var foreground_screen : MenuScreen = parent_menu.screens["foreground"]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(button_layout)
	
	var tween : Tween = create_tween()
	tween.tween_property($Back,"scale",Vector2(1.0,1.5),0.1)
	tween.parallel().tween_property($Back/Glow,"modulate:a",0.0,0.2).from(1.0)
	tween.parallel().tween_property($Icon,"position:y",72,0.1)
	
	get_node(desc_node_path).text = tr(description)

	get_node(label_node_path).get_node("Text").text = tr(text)
	get_node(label_node_path).modulate = label_color


## Called when this button is deselected
func _deselected() -> void:
	var tween : Tween = create_tween()
	tween.tween_property($Back,"scale",Vector2(1.0,1.0),0.1)
	tween.parallel().tween_property($Icon,"position:y",24,0.1)


## Called when this button disabled state changes
func _disabled(on : bool) -> void:
	is_off = on
	if is_off : modulate = Color(0.5,0.5,0.5,1.0)
	else: modulate = Color.WHITE
