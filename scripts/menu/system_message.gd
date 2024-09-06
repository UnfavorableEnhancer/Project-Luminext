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


extends Control

func _ready() -> void:
	$Center/Text.modulate.a = 0

# Shows system message which overlays everything
func _show_message(text : String) -> void:
	$Center/Text.text = text
	
	var tween : Tween = create_tween().set_parallel(true)
	
	# Animate appearance
	tween.tween_property($Center/Text,"modulate:a",1.0,1.0).from(0.0)
	tween.tween_property($Center/Text/Cover,"scale:x",1.0,0.5).from(0.0)
	tween.tween_interval(5.0)
	tween.chain().tween_property($Center/Text,"modulate:a",0.0,0.5)
	tween.tween_property($Center/Text/Cover,"scale:x",0.0,1.0).from(0.5)
	
