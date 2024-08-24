# Project Luminext - an advanced open-source Lumines spiritual successor
# Copyright (C) <2024> <unfavorable_enhancer>
# Contact : <random.likes.apes@gmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.


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
