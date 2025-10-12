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

##-----------------------------------------------------------------------
## Single UI element handler
## Each [UIElement] must have [AnimationPlayer] node called *'A'*
##-----------------------------------------------------------------------

class_name UIElement

var anim_player : AnimationPlayer = get_node("A") if has_node("A") else null ## UI animation node


## Plays animation from [AnimationPlayer] node called *'A'*
func _play_animation(anim_name : String) -> void:
	if anim_player != null : anim_player.play(anim_name)


## Changes this [UIElement] design to match passed [SkinData]
func _change_style(_skin_data : SkinData = null) -> void:
	pass

