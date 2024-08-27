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
	$FPS.visible = false
	$ColorRect.visible = false
	set_process(false)


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("fps_output"):
		if not $FPS.visible:
			$FPS.visible = true
			$ColorRect.visible = true
			set_process(true)
		else:
			$FPS.visible = false
			$ColorRect.visible = false
			set_process(false)


func _process(_delta : float) -> void:
	if $FPS.visible:
		$FPS.text = "FPS : " + str(Performance.get_monitor(Performance.TIME_FPS))
