extends UIElement

const Y_OFFSET : int = 156
const X_OFFSET : int = 392

var arrow_texture : Texture = null


func _ready() -> void:
	Data.game.new_piece_is_given.connect(_connect_piece)
	Data.profile.settings_changed.connect(_sync_settings)
	_sync_settings()


func _sync_settings() -> void:
	if Data.profile.config["video"]["block_trail"]:
		$Thing/Holder/Trail.emitting = true
	else:
		$Thing/Holder/Trail.emitting = false


func _change_style(style : int = 0, _skin_data : SkinData = null) -> void:
	var folder_name : String = ""
	
	match style:
		SkinData.UI_DESIGN.STANDARD: folder_name = "standard"
		SkinData.UI_DESIGN.SHININ: folder_name = "square"
		SkinData.UI_DESIGN.SQUARE: folder_name = "square"
		SkinData.UI_DESIGN.MODERN: folder_name = "modern"
		SkinData.UI_DESIGN.LIVE: folder_name = "live"
		SkinData.UI_DESIGN.PIXEL: folder_name = "pixel"
		SkinData.UI_DESIGN.BLACK: folder_name = "black"
		SkinData.UI_DESIGN.COMIC: folder_name = "comic"
		SkinData.UI_DESIGN.CLEAN: folder_name = "clean"
		SkinData.UI_DESIGN.VECTOR: folder_name = "vector"
		SkinData.UI_DESIGN.TECHNO: folder_name = "techno"
		_: return
	
	arrow_texture = load("res://images/game/foreground/holder/" + folder_name + "/arrow.png")
	var holder_tex : Texture = load("res://images/game/foreground/holder/" + folder_name + "/holder.png")

	$Thing/Arrow.texture = arrow_texture
	$Thing/Arrow2.texture = arrow_texture

	$Thing/Next.texture = load("res://images/game/foreground/holder/" + folder_name + "/next.png")

	$Thing/Holder.texture = holder_tex
	$Thing/Holder/Trail.texture = holder_tex


func _connect_piece() -> void:
	var piece : Piece = Data.game.piece
	piece.piece_moved.connect(_move)
	piece.piece_rotated.connect(_rotate)

	position.x = piece.position.x + X_OFFSET
	position.y = Y_OFFSET


func _move(pos : Vector2) -> void:
	if position.x == pos.x + X_OFFSET : return
	
	var tween : Tween = create_tween().set_parallel(true)
	
	$Thing/Arrow.rotation_degrees = 0
	$Thing/Arrow2.rotation_degrees = 0

	var fx_sprite : Sprite2D = Sprite2D.new()
	fx_sprite.texture = arrow_texture

	if position.x < pos.x + X_OFFSET: 
		fx_sprite.position = Vector2(112.0,0.0)
		$Thing.add_child(fx_sprite)

		tween.tween_property(fx_sprite,"position:x",156.0,0.25).from(112.0)
		tween.tween_property(fx_sprite,"modulate:a",0.0,0.25).from(1.0)
		tween.tween_callback(fx_sprite.queue_free).set_delay(0.25)
	else: 
		fx_sprite.position = Vector2(-112.0,0.0)
		fx_sprite.flip_h = true
		$Thing.add_child(fx_sprite)

		tween.tween_property(fx_sprite,"position:x",-156.0,0.25).from(-112.0)
		tween.tween_property(fx_sprite,"modulate:a",0.0,0.25).from(1.0)
		tween.tween_callback(fx_sprite.queue_free).set_delay(0.25)
	
	position.x = pos.x + X_OFFSET
	position.y = Y_OFFSET


func _rotate(side : int) -> void:
	var tween : Tween = create_tween().set_parallel(true)

	var fx_sprite : Sprite2D = Sprite2D.new()
	fx_sprite.texture = arrow_texture
	var fx_sprite2 : Sprite2D = Sprite2D.new()
	fx_sprite2.texture = arrow_texture
	
	if side == Piece.MOVE.RIGHT: 
		$Thing/Arrow.rotation_degrees = 90
		$Thing/Arrow2.rotation_degrees = 90
		fx_sprite.rotation_degrees = 90
		fx_sprite.position = Vector2(112.0,0.0)
		fx_sprite2.rotation_degrees = 90
		fx_sprite2.position = Vector2(-112.0,0.0)

		$Thing.add_child(fx_sprite)
		$Thing.add_child(fx_sprite2)
		
		tween.tween_property(fx_sprite,"position:y",50.0,0.25).from(0.0)
		tween.tween_property(fx_sprite,"modulate:a",0.0,0.25).from(1.0)
		tween.tween_callback(fx_sprite.queue_free).set_delay(0.25)
		tween.tween_property(fx_sprite2,"position:y",-50.0,0.25).from(0.0)
		tween.tween_property(fx_sprite2,"modulate:a",0.0,0.25).from(1.0)
		tween.tween_callback(fx_sprite2.queue_free).set_delay(0.25)
	else: 
		$Thing/Arrow.rotation_degrees = 270
		$Thing/Arrow2.rotation_degrees = 270
		fx_sprite.rotation_degrees = 270
		fx_sprite.position = Vector2(112.0,0.0)
		fx_sprite2.rotation_degrees = 270
		fx_sprite2.position = Vector2(-112.0,0.0)

		$Thing.add_child(fx_sprite)
		$Thing.add_child(fx_sprite2)
		
		tween.tween_property(fx_sprite,"position:y",-50.0,0.25).from(0.0)
		tween.tween_property(fx_sprite,"modulate:a",0.0,0.25).from(1.0)
		tween.tween_callback(fx_sprite.queue_free).set_delay(0.25)
		tween.tween_property(fx_sprite2,"position:y",50.0,0.25).from(0.0)
		tween.tween_property(fx_sprite2,"modulate:a",0.0,0.25).from(1.0)
		tween.tween_callback(fx_sprite2.queue_free).set_delay(0.25)
