extends MenuScreen

signal finish


func _ready() -> void:
	await get_tree().create_timer(20.0).timeout
	Data.global_settings["first_boot"] = false
	finish.emit()


func _input(event : InputEvent) -> void:
	if Data.global_settings["first_boot"] : return
	
	# When we press "start" button, disclaimer is skipped and next screen loads
	if event.is_action_pressed("ui_accept"): 
		finish.emit()
	
	if event is InputEventMouseButton and event.pressed:
		finish.emit()
