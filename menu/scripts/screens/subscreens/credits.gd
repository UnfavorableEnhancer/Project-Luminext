extends MenuScreen


func _ready() -> void:
	menu.screens["foreground"]._raise()
	
	await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_up") :
		$Content/Scroll.scroll_vertical = clamp($Content/Scroll.scroll_vertical - 10, 0, INF)
	if Input.is_action_pressed("ui_down") :
		$Content/Scroll.scroll_vertical = clamp($Content/Scroll.scroll_vertical + 10, 0, INF)
