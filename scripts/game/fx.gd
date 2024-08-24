extends Node2D

#-----------------------------------------------------------------------
# FX (Effect) class
#
# Used for creating special effects which spawns on certain actions
# Each special effect must have AnimationPlayer called "ANIM"
#-----------------------------------------------------------------------

class_name FX

var anim : String = "start" # Animtaion FX will play on creation
var is_persistent : bool = false # If true, FX woundn't be destroyed after finishing animation
var use_field_coordinates : bool = true # FX would use game field coords system, instead of absolute one

var parameter : Variant # Some additional custom parameter this FX can use


# Called by FX when it's ready to work
func _start() -> void:
	if not is_persistent : $ANIM.animation_finished.connect(_die)
	if use_field_coordinates : position = Vector2(position.x * 68.0, (position.y + 1.0) * 68.0)
	else:
		position.x -= 392
		position.y -= 232
	
	$ANIM.play(anim)


# Called at the end of animation
func _die(_a : String) -> void: 
	queue_free()
