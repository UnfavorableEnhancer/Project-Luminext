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


extends MenuScreen

func _ready() -> void:
	Data.menu._remove_screen("foreground")
	var tween : Tween = create_tween()
	
	$Outro.modulate.a = 0.0
	$Outro/Text1.modulate.a = 0.0
	$Outro/Text2.modulate.a = 0.0
	$Outro/Text3.modulate.a = 0.0
	$Outro/Text4.modulate.a = 0.0
	tween.tween_property($Outro, "modulate:a", 1.0, 1.0).from(0.0).set_ease(Tween.EASE_IN)
	tween.tween_interval(0.7)
	tween.tween_property(get_node("Outro/Text1"), "modulate:a", 1.0, 1.32).from(0.0).set_ease(Tween.EASE_IN)
	tween.tween_interval(1.32)
	tween.tween_property(get_node("Outro/Text2"), "modulate:a", 1.0, 1.32).from(0.0).set_ease(Tween.EASE_IN)
	tween.tween_interval(1.32)
	tween.tween_property(get_node("Outro/Text3"), "modulate:a", 1.0, 1.32).from(0.0).set_ease(Tween.EASE_IN)
	tween.tween_interval(1.32)
	tween.tween_property(get_node("Outro/Text4"), "modulate:a", 1.0, 1.32).from(0.0).set_ease(Tween.EASE_IN)
	tween.tween_interval(1.32)
	tween.tween_property(get_node("Outro/Text1"), "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(get_node("Outro/Text2"), "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(get_node("Outro/Text3"), "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(get_node("Outro/Text4"), "modulate:a", 0.0, 0.5)
	
	await tween.finished
	
	Data.game._end()
	_remove()
