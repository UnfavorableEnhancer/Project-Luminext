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


func _set_bpm(BPM : float) -> void:
	for i : int in 4:
		var butterfly_anim_node : AnimationPlayer = get_node("Butterfly" + str(i+1) + "/A")
		butterfly_anim_node.speed_scale = BPM / 120.0

func _start() -> void:
	for i : int in 4:
		var butterfly_anim_node : AnimationPlayer = get_node("Butterfly" + str(i+1) + "/A")
		butterfly_anim_node.play()
	$ScrollAnim.play()
