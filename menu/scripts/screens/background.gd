extends MenuScreen

@onready var blob1 : TextureRect = $Shiny/Blob
@onready var blob2 : TextureRect = $Shiny/Blob2
@onready var blob3 : TextureRect = $Shiny/Blob3
@onready var blob4 : TextureRect = $Shiny/Blob4
@onready var background : ColorRect = $Back

func _change_gradient_colors(color_1 : Color, color_2 : Color, color_3 : Color, color_4 : Color, back_color : Color) -> void:
	var begin_color_1 : Color = blob1.texture.gradient.get_color(0)
	var begin_color_2 : Color = blob2.texture.gradient.get_color(0)
	var begin_color_3 : Color = blob3.texture.gradient.get_color(0)
	var begin_color_4 : Color = blob4.texture.gradient.get_color(0)
	
	var tween : Tween = create_tween().set_parallel(true)
	
	tween.tween_method(func(color : Color) -> void: blob1.texture.gradient.set_color(0,color), begin_color_1, color_1, 1.0)
	tween.tween_method(func(color : Color) -> void: blob3.texture.gradient.set_color(0,color), begin_color_3, color_3, 1.0)
	tween.tween_method(func(color : Color) -> void: blob4.texture.gradient.set_color(0,color), begin_color_4, color_4, 1.0)
	tween.tween_method(func(color : Color) -> void: blob2.texture.gradient.set_color(0,color), begin_color_2, color_2, 1.0)
	tween.tween_property(background, "color", back_color, 1.0)
