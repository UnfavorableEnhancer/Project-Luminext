extends UIElement

var classic_animation : bool = false

var arrow_1_tex : Texture = null
var arrow_2_tex : Texture = null
var arrow_3_tex : Texture = null
var arrow_4_tex : Texture = null


func _ready() -> void:
	Data.profile.settings_changed.connect(_sync_settings)
	_sync_settings()


func _reset() -> void:
	$BigArrow/ANIM.seek(0,true)
	$BigArrow/ANIM.stop()
	$Classic/ANIM.seek(0,true)
	$Classic/ANIM.stop()


func _change_style(_style : int, skin_data : SkinData = null) -> void:
	$BigArrow/number/two.texture = skin_data.textures["2_tex"]
	$BigArrow/number/three.texture = skin_data.textures["3_tex"]
	$BigArrow/number/four.texture = skin_data.textures["4_tex"]
	
	arrow_1_tex = skin_data.textures["arrow_1"]
	arrow_2_tex = skin_data.textures["arrow_2"]
	arrow_3_tex = skin_data.textures["arrow_3"]
	arrow_4_tex = skin_data.textures["arrow_4"]
	
	$Bonus/line5.color = skin_data.textures["timeline_color"]


func _sync_settings() -> void:
	if Data.profile.config["video"]["classic_bonus_animation"]: 
		classic_animation = true
		$Classic.visible = true
		$BigArrow.visible = false
	else:
		classic_animation = false
		$Classic.visible = false
		$BigArrow.visible = true


func _bonus(combo : int, deleted_squares_count : int, result_score : int) -> void:
	$Bonus/squares.text = str(deleted_squares_count) + "x"
	$Bonus/score.text = "+" + str(result_score)

	if classic_animation: $Classic/ANIM.play("start")
	else: 
		if combo % 4 == 1 : 
			$BigArrow/number/two.visible = false
			$BigArrow/number/three.visible = false
			$BigArrow/number/four.visible = false
			$BigArrow/arrow.texture = arrow_1_tex
			$BigArrow/arrow2.texture = arrow_1_tex
		if combo % 4 == 2 : 
			$BigArrow/number/two.visible = true
			$BigArrow/number/three.visible = false
			$BigArrow/number/four.visible = false
			$BigArrow/arrow.texture = arrow_2_tex
			$BigArrow/arrow2.texture = arrow_2_tex
		if combo % 4 == 3 : 
			$BigArrow/number/two.visible = false
			$BigArrow/number/three.visible = true
			$BigArrow/number/four.visible = false
			$BigArrow/arrow.texture = arrow_3_tex
			$BigArrow/arrow2.texture = arrow_3_tex
		if combo > 0 and combo % 4 == 0 : 
			$BigArrow/number/two.visible = false
			$BigArrow/number/three.visible = false
			$BigArrow/number/four.visible = true
			$BigArrow/arrow.texture = arrow_4_tex
			$BigArrow/arrow2.texture = arrow_4_tex
		
		$BigArrow/ANIM.play("start")
