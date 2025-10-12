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

extends FX

func _ready() -> void:
	name = "sn" + str(position.x + 10) + str(position.y + 10)
	
	if parameter[2] > 1:
		$NUM.text = "X" + str(parameter[2]) + " +" + str(parameter[0])
	else:
		$NUM.text = "+" + str(parameter[0])
	
	if parameter[1] > 31:
		$NUM.self_modulate = Color.GOLD
	elif parameter[1] > 15:
		$NUM.self_modulate = Color.FUCHSIA
	elif parameter[1] > 3:
		$NUM.self_modulate = Color.CYAN
	else:
		$NUM.self_modulate = Color.GRAY
	
	_start()
