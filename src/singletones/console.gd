# Project Luminext - an ultimate block-stacking puzzle game
# Copyright (C) <2024-2026> <unfavorable_enhancer>
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


extends Node

func space() -> void:
	print()

func log(message : String) -> void:
	print("%s <log> : %s" % [Time.get_ticks_msec(), message])

func debug(message : String) -> void:
	print("%s <dabug> : %s" % [Time.get_ticks_msec(), message])

func error(message : String) -> void:
	push_error("%s <ERROR> : %s" % [Time.get_ticks_msec(), message])
