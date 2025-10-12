# Project Luminext - an ultimate block-stacking puzzle game
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

extends UIElement

##-----------------------------------------------------------------------
## Shows flashing "Demo" text at the bottom of the screen
##-----------------------------------------------------------------------

func _ready() -> void:
	var tween : Tween = create_tween().set_loops()
	tween.tween_property($text, "modulate", Color(0,0,0,0), 1.0)
	tween.tween_property($text, "modulate", Color.WHITE, 1.0)
