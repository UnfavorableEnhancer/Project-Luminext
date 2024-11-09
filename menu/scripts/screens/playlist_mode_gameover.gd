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

	var replay_save_button : MenuSelectableButton = $Menu/REPLAY
	match Data.game.replay.is_valid:
		OK : pass
		Replay.INVALID.NON_STANDARD_SKIN :
			replay_save_button._disable(true)
			replay_save_button.description = "Play single standard skin to enable replay recording."
		Replay.INVALID.GAME_RULES_CHANGED :
			replay_save_button._disable(true)
			replay_save_button.description = "Game rules were changed during replay recording."
		Replay.INVALID.RECORD_TIME_EXCEEDED :
			replay_save_button._disable(true)
			replay_save_button.description = "Replay recording time exceeded."
		Replay.INVALID.UNSUPPORTED_GAMEMODE :
			replay_save_button._disable(true)
			replay_save_button.description = "This gamemode is not supported for replay recording."
		Replay.INVALID.UNSUPPORTED_PLAYLIST :
			replay_save_button._disable(true)
			replay_save_button.description = "Play single standard skin to enable replay recording."

	await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


func _setup(playlist_mode : PlaylistMode) -> void:
	%Score.text = str(playlist_mode.score)
	%SqrDel.text = "SQUARES : " + str(playlist_mode.deleted_squares)
	%BlckDel.text = "BLOCKS : " + str(playlist_mode.deleted_blocks)
	%Level.text = "LEVEL : " + str(playlist_mode.level_count)
	%Time.text = Data._to_time(playlist_mode.time)

	if playlist_mode.playlist_pos < 1 : %Stage.visible = false
	else : %Stage.text = "STAGE : " + str(playlist_mode.playlist_pos)

	if playlist_mode.current_lap < 1 : %Lap.visible = false
	else : %Lap.text = "LAP : " + str(playlist_mode.current_lap)


func _save_replay() -> void:
	var input : MenuScreen = Data.menu._add_screen("text_input")
	input.desc_text = "ENTER REPLAY NAME"
	input.accept_function = Data.game.replay._save


func _restart() -> void:
	Data.game._retry()
	Data.menu._remove_screen("foreground")
	_remove()


func _end() -> void:
	Data.game._end()
	Data.menu._remove_screen("foreground")
	_remove()
