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

var swap_enabled : bool = true


func _change_style(_style : int,  skin_data : SkinData = null) -> void:
	$Stack.modulate = skin_data.textures["ui_color"]


func _ready() -> void:
	$Swaps/swap4.modulate.a = 0.0
	$Swaps/swap5.modulate.a = 0.0
	$Swaps/swap6.modulate.a = 0.0
	
	Data.game.piece_queue.swap_value_changed.connect(_set_swap)
	Data.game.piece_queue.piece_swap.connect(_use_swap)

	_set_swap(0)


func _hide_swaps() -> void:
	$Swaps.visible = false
	swap_enabled = false


func _show_swaps() -> void:
	$Swaps.visible = true
	swap_enabled = true


func _set_swap(swaps_amount : int) -> void:
	if not swap_enabled : return
	var tween :Tween = create_tween().set_parallel(true)

	for i : int in [1,2,3]:
		if swaps_amount == i - 1:
			tween.tween_property($Swaps.get_node("swap" + str(i + 3)), "scale", Vector2(1.5, 1.5), 0.5).from(Vector2(0.735, 0.735))
			tween.tween_property($Swaps.get_node("swap" + str(i + 3)), "modulate:a", 0.0, 0.5).from(1.0)
		
		if swaps_amount < i : tween.tween_property($Swaps.get_node("swap" + str(i)), "modulate", Color(1,1,1,0.5), 0.5)
		else : tween.tween_property($Swaps.get_node("swap" + str(i)), "modulate", Color(1,1,1,1), 0.5)
		

func _use_swap(swaps_amount : int) -> void:
	if not swap_enabled : return
	var tween :Tween = create_tween().set_parallel(true)

	for i : int in [1,2,3]:
		if swaps_amount < i : tween.tween_property($Swaps.get_node("swap" + str(i)), "modulate", Color(1,1,1,0.5), 0.5)
		else : tween.tween_property($Swaps.get_node("swap" + str(i)), "modulate", Color(1,1,1,1), 0.5)
