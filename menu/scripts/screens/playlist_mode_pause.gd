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

func _restart() -> void:
	Data.game._retry()
	Data.menu._remove_screen("foreground")
	_remove()

func _end() -> void:
	Data.game._end()
	Data.menu._remove_screen("foreground")
	_remove()
