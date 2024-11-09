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


extends Block

# Joker (Shuffle) block changes color every timeline pass

class_name Joker


func _ready() -> void:
	super()

	Data.game.timeline_started.connect(_joke)
	# Make it slightly darker, than other blocks so it can be distinguished
	self_modulate = Color.LIGHT_GRAY


# Changes block color to random one
func _joke() -> void:
	if not is_falling and not is_dying:
		var colors : Array[int] = []

		if Data.profile.config["gameplay"]["red"] : colors.append(BLOCK_COLOR.RED)
		if Data.profile.config["gameplay"]["white"] : colors.append(BLOCK_COLOR.WHITE)
		if Data.profile.config["gameplay"]["green"] : colors.append(BLOCK_COLOR.GREEN)
		if Data.profile.config["gameplay"]["purple"] : colors.append(BLOCK_COLOR.PURPLE)
		
		color = colors.pick_random()

		await physics_tick
		Data.game._square_check(Rect2i(grid_position.x - 2, grid_position.x + 2, grid_position.y - 2, grid_position.y + 2))
		
		var tween : Tween = create_tween()
		var tween_time : float = 60.0 / Data.game.skin.bpm / 4.0
		tween.tween_property(self, "modulate:a", 0.0, tween_time)
		tween.tween_callback(_render)
		tween.tween_property(self, "modulate:a", 1.0, tween_time)