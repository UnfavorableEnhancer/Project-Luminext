extends MenuScreen

func _ready() -> void:
	Data.game._end()
	Data.menu._remove_screen("foreground")
	_remove()
