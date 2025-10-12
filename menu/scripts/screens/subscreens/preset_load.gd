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


extends MenuScreen

##-----------------------------------------------------------------------
## Loads and displays all avaiable gamerule presets list and allows to select any
##-----------------------------------------------------------------------

const PRESET_BUTTON : PackedScene = preload("res://menu/objects/regular_button.tscn") ## Gamerule preset button instance


func _ready() -> void:
	parent_menu.screens["foreground"]._raise()
	
	cursor_selection_success.connect(_scroll)
	_load()


## Loads and displays gamerule presets list
func _load() -> void:
	var presets : Array[String] = Data._parse(Data.PARSE.RULESETS)
	if presets.is_empty() : 
		$Label.text = tr("NO_PRESETS")
		_set_selectable_position($BACK, Vector2i(0,0))
		
	else:
		var count : int = 0
		for preset_path : String in presets:
			var button : MenuSelectableButton = PRESET_BUTTON.instantiate()

			button.call_function_name = "_load_preset"
			button.call_string = preset_path
			button.text = preset_path.get_file().get_basename()
			button.press_sound_name = "confirm"
			button.glow_color = Color("27a1a3")
			button.custom_minimum_size = Vector2(1104,48)
			button.menu_position = Vector2(0,count)

			button.parent_screen = self
			button.parent_menu = parent_menu
			
			$Scroll/V.add_child(button)
			count += 1
		
		_set_selectable_position($BACK, Vector2i(0, count))
	
	cursor = Vector2i(0,0)
	_move_cursor()


## Scrolls gamerule presets list scroll bar
func _scroll(cursor_pos : Vector2) -> void:
	$Scroll.scroll_vertical = clamp(cursor_pos.y * 208 ,0 ,INF)


## Loads gamerule preset
func _load_preset(preset_path : String) -> void:
	Player.user_gamerule._load(preset_path)
	parent_menu.screens["config.game"]._load_settings()
	_remove()
