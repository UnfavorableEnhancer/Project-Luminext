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


extends MenuScreen


func _ready() -> void:
	menu.screens["foreground"].visible = true
	menu.screens["foreground"]._raise()

	await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()

func _continue() -> void:
	Data.game._pause(false,true)
	Data.menu._remove_screen("foreground")
	_remove()

func _save_replay() -> void:
	var replay : Replay = Data.game.gamemode.replay
	
	var input : MenuScreen = Data.menu._add_screen("text_input")
	input.desc_text = "ENTER REPLAY NAME"
	input.object_to_call = replay
	input.call_function_name = "_save"
	input._start()

func _restart() -> void:
	Data.game._retry()
	Data.menu._remove_screen("foreground")
	_remove()

func _end() -> void:
	Data.game._end()
	Data.menu._remove_screen("foreground")
	_remove()
