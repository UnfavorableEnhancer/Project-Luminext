extends MenuScreen

const PLAYLIST_CARD : PackedScene = preload("res://menu/objects/playlist_card.tscn")


func _ready() -> void:
	menu.screens["foreground"]._raise()
	
	cursor_selection_success.connect(_scroll)
	_load()


func _load() -> void:
	var playlists : Array = Data._parse(Data.PARSE.PLAYLISTS)
	if playlists.is_empty() : 
		$Label.text = "NO PLAYLISTS FOUND"
		_assign_selectable($BACK, Vector2i(0,0))
		if menu.is_locked : await menu.all_screens_added
		cursor = Vector2i(0,0)
		_move_cursor()
		return
	
	var count : int = 0
	for playlist_path : String in playlists:
		var playlist_card : MenuSelectableButton = PLAYLIST_CARD.instantiate()
		playlist_card._load(playlist_path)
		playlist_card.menu_position = Vector2i(0,count)
		
		$Scroll/V.add_child(playlist_card)
		count += 1
	
	_assign_selectable($BACK, Vector2i(0,count))
	
	if menu.is_locked : await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


func _scroll(cursor_pos : Vector2i) -> void:
	$Scroll.scroll_vertical = clamp(cursor_pos.y * 144 - 144 ,0 ,INF)
