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


extends MenuScreen

##-----------------------------------------------------------------------
## Starts on boot and shows several disclaimers. 
## If game is booted for the first time ever cannot be skipped.
##-----------------------------------------------------------------------

signal finish


func _ready() -> void:
	await get_tree().create_timer(20.0).timeout
	Player.global.config["first_boot"] = false
	finish.emit()


func _input(event : InputEvent) -> void:
	if Player.global.config["first_boot"] : return
	
	# When we press "start" button, disclaimer is skipped and next screen loads
	if event.is_action_pressed("ui_accept"): 
		finish.emit()
	
	if event is InputEventMouseButton and event.pressed:
		finish.emit()
