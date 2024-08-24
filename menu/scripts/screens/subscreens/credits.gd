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
	menu.screens["foreground"]._raise()
	
	await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


func _process(_delta: float) -> void:
	if Input.is_action_pressed("ui_up") :
		$Content/Scroll.scroll_vertical = clamp($Content/Scroll.scroll_vertical - 10, 0, INF)
	if Input.is_action_pressed("ui_down") :
		$Content/Scroll.scroll_vertical = clamp($Content/Scroll.scroll_vertical + 10, 0, INF)
