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
## Used for game over screen of [PlaylistMode]
## Displays stats of current game scores and stats
##-----------------------------------------------------------------------

var parent_game : GameCore ## Game instance

func _ready() -> void:
	parent_menu.screens["foreground"].visible = true
	parent_menu.screens["foreground"]._raise()
	
	await parent_menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


## Setups game instance and displays its score and other data
func _setup(game : LuminextGame) -> void:
	parent_game = game
	
	if game.gamemode is PlaylistMode :
		%Score.text = str(game.gamemode.score) +  " | " + str(game.gamemode.deleted_squares) + " ™"
		%Level.text = tr("END_LEVEL") + " : " + str(game.gamemode.level)
		%Time.text = Main._to_time(game.gamemode.time)
		
		if game.gamemode.is_single_skin_mode : %Stage.visible = false
		else : %Stage.text = tr("STAGE") + " : " + str(game.gamemode.playlist_pos)
		
		if game.gamemode.is_single_skin_mode : %Lap.visible = false
		else : %Lap.text = tr("LAP") + " : " + str(game.gamemode.current_lap)
	
	var replay_save_button : MenuSelectableButton = $Menu/REPLAY
	match game.replay.is_valid:
		OK : pass
		Replay.REPLAY_ERROR.UNSUPPORTED_SKIN :
			replay_save_button.disabled_description = "SAVE_REPLAY_ERROR1"
			replay_save_button._set_disable(true)
		Replay.REPLAY_ERROR.RULESET_CHANGED :
			replay_save_button.disabled_description = "SAVE_REPLAY_ERROR2"
			replay_save_button._set_disable(true)
		Replay.REPLAY_ERROR.RECORD_TIME_EXCEEDED :
			replay_save_button.disabled_description = "SAVE_REPLAY_ERROR3"
			replay_save_button._set_disable(true)
		Replay.REPLAY_ERROR.UNSUPPORTED_GAMEMODE :
			replay_save_button.disabled_description = "SAVE_REPLAY_ERROR4"
			replay_save_button._set_disable(true)
		Replay.REPLAY_ERROR.UNSUPPORTED_ADVENTURE :
			replay_save_button.disabled_description = "SAVE_REPLAY_ERROR1"
			replay_save_button._set_disable(true)


## Opens replay save input dialog
func _save_replay() -> void:
	var input : MenuScreen = parent_menu._add_screen("text_input")
	input.desc_text = tr("SAVE_REPLAY_DIALOG")
	input.accept_function = parent_game.replay._save


## Restarts game from beginning
func _restart() -> void:
	parent_game._retry()


## Finishes the game and returns to main menu
func _end() -> void:
	parent_game._end()
