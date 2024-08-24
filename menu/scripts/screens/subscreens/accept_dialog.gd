extends MenuScreen

signal accepted
signal canceled
signal closed

var desc_text : String = ""
var object_to_call : Variant = null

var call_function_name : String = ""
var cancel_function_name : String = ""
var call_function_argument : Variant = null
var cancel_function_argument : Variant = null


func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	$ColorRect/Dialog.text = desc_text
	
	menu.screens["foreground"]._raise()
	
	await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


func _cancel() -> void:
	if not cancel_function_name.is_empty() and object_to_call != null:
		if cancel_function_argument == null: object_to_call.call(cancel_function_name)
		else: object_to_call.call(cancel_function_name,cancel_function_argument)
	
	canceled.emit()
	closed.emit()
	_remove()


func _accept() -> void:
	if not call_function_name.is_empty() and object_to_call != null:
		if call_function_argument == null: object_to_call.call(call_function_name)
		else: object_to_call.call(call_function_name,call_function_argument)
	
	accepted.emit()
	closed.emit()
	_remove()
