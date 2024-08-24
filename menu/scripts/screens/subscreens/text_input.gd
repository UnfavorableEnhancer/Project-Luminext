extends MenuScreen

var desc_text : String = ""
var object_to_call : Variant
var call_function_name : String = ""
var cancel_function_name : String = ""


func _ready() -> void:
	menu.screens["foreground"]._raise()


func _start() -> void:
	$ColorRect/Label.text = desc_text
	await create_tween().tween_interval(0.5).finished
	
	$ColorRect/Name.grab_focus()
	await $ColorRect/Name.text_submitted
	
	var input : String = $ColorRect/Name.text
	
	if input.is_empty():
		Data.menu._sound("cancel")
		if not cancel_function_name.is_empty():
			object_to_call.call(cancel_function_name, $ColorRect/Name.text)
	else:
		Data.menu._sound("confirm3")
		object_to_call.call(call_function_name, $ColorRect/Name.text)
	
	_remove()


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_remove()
