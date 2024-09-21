extends MenuScreen

const REPLAY_CARD : PackedScene = preload("res://menu/objects/replay_card.tscn")


func _ready() -> void:
	menu.screens["foreground"]._raise()
	
	cursor_selection_success.connect(_scroll)
	_load()


func _load() -> void:
	var replays : Array = Data._parse(Data.PARSE.REPLAYS)
	if replays.is_empty() : 
		$V/Text.text = "NO REPLAYS FOUND..."
		_assign_selectable($V/Menu/Exit, Vector2i(0,0))
		return
	
	var count : int = 0
	for replay_path : String in replays:
		var replay_card : MenuSelectableButton = REPLAY_CARD.instantiate()
		replay_card.replay_path = replay_path
		replay_card._load()
		if not replay_path.is_empty():
			replay_card.call_function_name = "_start_replay"
			replay_card.call_string = replay_path
			replay_card.press_sound_name = "enter"
			replay_card.modulate.a = 0.0
		
		replay_card.menu_position = Vector2(0,count)
		
		$V/Replays/V.add_child(replay_card)
		
		count += 1
	
	var tween : Tween = create_tween()
	tween.tween_interval(0.5)
	for i : Node in $V/Replays/V.get_children():
		tween.tween_property(i, "modulate:a", 1.0, 0.25).from(0.0) 
	
	$V/Replays.custom_minimum_size.y = clamp(count * 120, 120, 600)
	_assign_selectable($V/Menu/Exit, Vector2i(0, count))
	
	await get_tree().create_timer(0.1).timeout
	cursor = Vector2i(0,0)
	_move_cursor()


func _scroll(cursor_pos : Vector2) -> void:
	$V/Replays.scroll_vertical = clamp(cursor_pos.y * 120 ,0 ,INF)


func _start_replay(replay_path : String) -> void:
	if not Data.menu.is_locked and not replay_path.is_empty():
		var replay : Replay = Replay.new()
		replay._load(replay_path)

		Data.main._start_replay(replay)
