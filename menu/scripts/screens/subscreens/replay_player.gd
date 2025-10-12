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
## Loads and displays all avaiable replays list and allows to select any
##-----------------------------------------------------------------------

const REPLAY_CARD : PackedScene = preload("res://menu/objects/replay_card.tscn") ## Replay card instance


func _ready() -> void:
	parent_menu.screens["foreground"]._raise()
	
	cursor_selection_success.connect(_scroll)
	_load()


## Loads and displays replays list
func _load() -> void:
	var replays : Array[String] = Data._parse(Data.PARSE.REPLAYS, true)
	
	if replays.is_empty() : 
		$V/Text.text = "NO REPLAYS FOUND..."
		_set_selectable_position($V/Menu/Exit, Vector2i(0,0))
	
	else:
		var count : int = 0
		for replay_path : String in replays:
			var replay_card : MenuSelectableButton = REPLAY_CARD.instantiate()
			replay_card.replay_path = replay_path
			replay_card._load()
			if not replay_card.is_invalid:
				replay_card.call_function_name = "_start_replay"
				replay_card.call_string = replay_path
				replay_card.press_sound_name = "enter"
				replay_card.modulate.a = 0.0
			
			replay_card.menu_position = Vector2(0,count)
			replay_card.parent_menu = parent_menu
			replay_card.parent_screen = self
			
			$V/Replays/V.add_child(replay_card)
			
			count += 1
		
		var tween : Tween = create_tween()
		tween.tween_interval(0.5)
		for i : Node in $V/Replays/V.get_children():
			tween.tween_property(i, "modulate:a", 1.0, 0.1).from(0.0) 
		
		$V/Replays.custom_minimum_size.y = clamp(count * 120, 120, 600)
		_set_selectable_position($V/Menu/Exit, Vector2i(0, count))
	
	await parent_menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


## Scrolls replays list scroll bar
func _scroll(cursor_pos : Vector2) -> void:
	if main.current_input_mode == Main.INPUT_MODE.MOUSE: return

	$V/Replays.scroll_vertical = clamp(cursor_pos.y * 120 ,0 ,INF)


## Starts selected replay
func _start_replay(replay_path : String) -> void:
	if not parent_menu.is_locked and not replay_path.is_empty():
		var replay : Replay = Replay.new()
		replay._load(replay_path)

		main._start_replay(replay)
