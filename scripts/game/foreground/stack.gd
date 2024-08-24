extends UIElement

var swap_enabled : bool = true


func _change_style(_style : int,  skin_data : SkinData = null) -> void:
	$Stack.modulate = skin_data.textures["ui_color"]


func _ready() -> void:
	$Swaps/swap4.modulate.a = 0.0
	$Swaps/swap5.modulate.a = 0.0
	$Swaps/swap6.modulate.a = 0.0
	
	Data.game.piece_queue.swap_value_changed.connect(_set_swap)
	Data.game.piece_queue.piece_swap.connect(_use_swap)

	_set_swap(0)


func _hide_swaps() -> void:
	$Swaps.visible = false
	swap_enabled = false


func _show_swaps() -> void:
	$Swaps.visible = true
	swap_enabled = true


func _set_swap(swaps_amount : int) -> void:
	if not swap_enabled : return
	var tween :Tween = create_tween().set_parallel(true)

	for i : int in [1,2,3]:
		if swaps_amount == i - 1:
			tween.tween_property($Swaps.get_node("swap" + str(i + 3)), "scale", Vector2(1.5, 1.5), 0.5).from(Vector2(0.735, 0.735))
			tween.tween_property($Swaps.get_node("swap" + str(i + 3)), "modulate:a", 0.0, 0.5).from(1.0)
		
		if swaps_amount < i : tween.tween_property($Swaps.get_node("swap" + str(i)), "modulate", Color(1,1,1,0.5), 0.5)
		else : tween.tween_property($Swaps.get_node("swap" + str(i)), "modulate", Color(1,1,1,1), 0.5)
		

func _use_swap(swaps_amount : int) -> void:
	if not swap_enabled : return
	var tween :Tween = create_tween().set_parallel(true)

	for i : int in [1,2,3]:
		if swaps_amount < i : tween.tween_property($Swaps.get_node("swap" + str(i)), "modulate", Color(1,1,1,0.5), 0.5)
		else : tween.tween_property($Swaps.get_node("swap" + str(i)), "modulate", Color(1,1,1,1), 0.5)
