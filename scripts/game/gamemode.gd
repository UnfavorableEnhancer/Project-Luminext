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


# Resets gamemode to initial state 
func _reset() -> void:
	_load_ui()
	
	reset_complete.emit()


# Called on game over
func _game_over() -> void:
	pass


# Called on pause
func _pause(_on : bool) -> void:
	pass


# Called on game retry
func _retry() -> void:
	retry_complete.emit()

