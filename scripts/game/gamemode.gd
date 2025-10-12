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


extends Node

##-----------------------------------------------------------------------
## Base class for all gamemodes
## Each gamemode defines unique game behaviour and goals
##-----------------------------------------------------------------------

class_name Gamemode

var main : Main ## Main instance
var game : GameCore ## Game instance
var foreground : Foreground ## Foreground instance

var gamemode_name : String = "" ## Name of the gamemode
var ruleset : Ruleset = Ruleset.new() ## Used by the gamemode ruleset

var error_text : String = "GAMEMODE ERROR!" ## Error string that will be displayed by the system message on gamemode reset failure


## Initiates all needed for this gamemode [UIElements]
func _load_ui() -> void:
	foreground._reset()


## Called on game soft reset and regular reset
func _soft_reset() -> void:
	pass


## Called on game reset
func _reset() -> int:
	_load_ui()
	
	await get_tree().create_timer(1.0).timeout
	return OK


## Called on game pause
func _pause(_on : bool) -> void:
	pass


## Called on game over
func _game_over() -> void:
	pass


## Called on game exit
func _end() -> void:
	pass

