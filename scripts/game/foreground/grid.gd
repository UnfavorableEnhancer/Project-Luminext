extends UIElement

enum MUSIC_LOOP {NONE, PLAYING, REPEAT}
var is_music_loop : int = MUSIC_LOOP.NONE

var grid_shine_enabled : bool = false


func _ready() -> void:
	Data.profile.settings_changed.connect(_sync_settings)
	_sync_settings()

	Data.game.timeline_started.connect(_update)
	Data.game.piece_queue.piece_swap.connect(_swap)
	
	if Data.game.skin.is_music_looping: 
		is_music_loop = MUSIC_LOOP.REPEAT
		$Repeat.visible = true


func _swap() -> void:
	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property($Stack/swap1, "position:y", 350.0, 0.25).from(0.0)
	tween.tween_property($Stack/swap2, "position:y", -350.0, 0.25).from(0.0)
	tween.tween_property($Stack/swap1, "modulate:a", 0.0, 0.25).from(0.8)
	tween.tween_property($Stack/swap2, "modulate:a", 0.0, 0.25).from(0.8)


func _sync_settings() -> void:
	if Data.profile.config["video"]["fx_quality"] >= Profile.EFFECTS_QUALITY.MEDIUM: grid_shine_enabled = true
	else: grid_shine_enabled = false


func _change_style(style : int, skin_data : SkinData = null) -> void:
	$name.text = skin_data.metadata.name + " / " + skin_data.metadata.artist
	$Field.modulate = skin_data.textures["ui_color"]
	$EQVisualizer.modulate = skin_data.textures["eq_visualizer_color"]
	
	var file_name : String = ""
	match style:
		SkinData.UI_DESIGN.STANDARD: file_name = "standard"
		SkinData.UI_DESIGN.SHININ: file_name = "shinin"
		SkinData.UI_DESIGN.SQUARE: file_name = "square"
		SkinData.UI_DESIGN.MODERN: file_name = "modern"
		SkinData.UI_DESIGN.LIVE: file_name = "live"
		SkinData.UI_DESIGN.PIXEL: file_name = "pixel"
		SkinData.UI_DESIGN.BLACK: file_name = "black"
		SkinData.UI_DESIGN.COMIC: file_name = "comic"
		SkinData.UI_DESIGN.CLEAN: file_name = "clean"
		SkinData.UI_DESIGN.VECTOR: file_name = "vector"
		SkinData.UI_DESIGN.TECHNO: file_name = "techno"
		_: return
	
	$Stack.texture = load("res://images/game/foreground/stack/" + file_name + ".png")
	$Stack.modulate = skin_data.textures["ui_color"]


func _update_loop_mark(_pass : int) -> void:
	if is_music_loop == MUSIC_LOOP.REPEAT:
		$Repeat.visible = false
		$Playing.visible = true
		is_music_loop = MUSIC_LOOP.PLAYING


func _update() -> void:
	Data.game.timeline.squares_deleted.connect(_update_loop_mark)
	
	if is_music_loop == MUSIC_LOOP.PLAYING:
		$Repeat.visible = true
		$Playing.visible = false
		is_music_loop = MUSIC_LOOP.REPEAT

	if grid_shine_enabled : create_tween().tween_property($Field/GridShine,"material:shader_parameter/offset",3.0,60.0 / Data.game.skin.bpm * 8.0).from(-1.5)
	create_tween().tween_property($Field/Beatcount,"size:x",1084.0,60.0 / Data.game.skin.bpm * 8.0).from(0.0)
