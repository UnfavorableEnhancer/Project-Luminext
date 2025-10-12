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

extends Control

func _play() -> void:
	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property(%Progress,"modulate:a",1.0,0.5).from(0.0)
	tween.tween_property(%TextBack,"scale:x",1.0,0.5).from(0.0)
	
	$A.play("loading")


func _stop() -> void:
	$A.stop()


func _set_text(new_text : String) -> void:
	%Progress.text = new_text
