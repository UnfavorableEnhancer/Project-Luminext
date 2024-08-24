extends Node2D


func _set_bpm(BPM : float) -> void:
	for i : int in 4:
		var butterfly_anim_node : AnimationPlayer = get_node("Butterfly" + str(i+1) + "/A")
		butterfly_anim_node.speed_scale = BPM / 120.0

func _start() -> void:
	for i : int in 4:
		var butterfly_anim_node : AnimationPlayer = get_node("Butterfly" + str(i+1) + "/A")
		butterfly_anim_node.play()
	$ScrollAnim.play()
