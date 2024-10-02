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


extends Node

#-----------------------------------------------------------------------
# Base gamemode class
# 
# Defines game rules and how it would behave
#-----------------------------------------------------------------------

class_name Gamemode

signal retry_complete
signal reset_complete
signal preprocess_finished

enum RETRY_STATUS {OK, FAILED, SKIN_MISSING}

@onready var game : Node2D = get_parent() # Current game instance

var gamemode_name : String = ""

var use_preprocess : bool = false # Set to true to preprocess this gamemode

var error_text : String = "GAMEMODE ERROR!" # Custom error string that game will display if something wrong with gamemode 
var retry_status : int = 0 # Shows did gamemode succeed in retrying 


# Called on game boot and designed to lift heavy tasks which must be completed before game starts
func _preprocess() -> int:
	preprocess_finished.emit()
	return OK

# Called on game exit
func _end() -> void:
	pass


# Asks game foreground to load needed ui elements
func _load_ui() -> void:
	game.foreground._reset()


# Resets gamemode to initial state, called last in game reset function
func _reset() -> void:
	_load_ui()
	
	reset_complete.emit()


# Resets gamemode to initial state, called first in game reset function
func _prereset() -> void:
	pass


# Called on game over
func _game_over() -> void:
	pass


# Called on pause
func _pause(_on : bool) -> void:
	pass


# Called on game retry
func _retry() -> void:
	retry_complete.emit()

