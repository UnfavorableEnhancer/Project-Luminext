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


extends UIElement


func _ready() -> void:
	$Charge.scale.x = 0 


func _change_style(_style : int, skin_data : SkinData = null) -> void:
	create_tween().tween_property($Charge, "color", skin_data.textures["timeline_color"], 1.0)


func _level_up() -> void:
	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property($LevelUp, "modulate:a", 0.0, 1.0).from(1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property($LevelUp, "scale", Vector2($Charge.scale.x * 6,6), 1.0).from(Vector2($Charge.scale.x,1)).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func _change_progress(value : float) -> void:
	create_tween().tween_property($Charge, "scale:x", value, 1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

