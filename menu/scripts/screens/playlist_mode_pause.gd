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
## Used for game pause screen
##-----------------------------------------------------------------------

var parent_game : GameCore ## Game instance


func _ready() -> void:
	parent_menu.screens["foreground"].visible = true
	parent_menu.screens["foreground"]._raise()

	await parent_menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


## Setups game instance
func _setup(game : GameCore) -> void:
	parent_game = game


## Continues the game
func _continue() -> void:
	parent_game._pause(false,true)


## Restarts game from beginning
func _restart() -> void:
	parent_game._retry()


## Finishes the game and returns to main menu
func _end() -> void:
	parent_game._end()
