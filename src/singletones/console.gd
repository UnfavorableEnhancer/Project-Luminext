extends Node

func space() -> void:
	print()

func log(message : String) -> void:
	print("%s <log> : %s" % [Time.get_ticks_msec(), message])

func error(message : String) -> void:
	push_error("%s <ERROR> : %s" % [Time.get_ticks_msec(), message])
