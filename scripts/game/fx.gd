# Project Luminext - an advanced open-source Lumines spiritual successor
# Copyright (C) <2024-2025> <unfavorable_enhancer>
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

class_name FX

##-----------------------------------------------------------------------
## Special effects are used to spice up various game events
## Each special effect must have AnimationPlayer called *'ANIM'*
##-----------------------------------------------------------------------

var game : GameCore

var start_animation : String = "start" ## Animtaion name which will be played on spawn
var is_persistent : bool = false ## If true, FX woundn't be deleted after finishing animation
var parameter : Variant ## Some additional custom parameter this FX can use


## Starts special effect animation
func _start() -> void:
	if not is_persistent : $ANIM.animation_finished.connect(_die)
	$ANIM.play(start_animation)


## Called at the end of animation
func _die(_a : String) -> void: 
	queue_free()
