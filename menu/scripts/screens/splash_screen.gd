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
## Game splash screen animation
##-----------------------------------------------------------------------

var is_exiting : bool = true ## True if game is currently exiting


func _ready() -> void:
	parent_menu.screens["foreground"].visible = false
	$Foreground/Info/VER.text = tr("VERSION") + " " + Data.VERSION
	$Foreground/Info/BUILD.text = tr("BUILD") + " " + Data.BUILD
	$Foreground/Info/EDITION.text = tr("POWERED_BY") + "\nGODOT ENGINE"
	
	main.input_method_changed.connect(_label)
	_label()
	
	await get_tree().create_timer(2.0).timeout
	
	$LogoAnim.play("start")
	$GlassAnim.play("start")
	is_exiting = false


## Sets start game label depending on current input type
func _label() -> void:
	if main.current_input_mode == Main.INPUT_MODE.GAMEPAD: $Foreground/ENTER.text = tr("PRESS_START")
	else: $Foreground/ENTER.text = tr("PRESS_ENTER")


func _input(event : InputEvent) -> void:
	# Press "start" button to proceed to menu screen
	if not is_exiting:
		if event.is_action_pressed("ui_enter"):
			is_exiting = true 
			
			parent_menu._play_sound("enter")
			main._toggle_darken(true)
			
			if Player.profile_status != OK : parent_menu._change_screen("login")
			else : parent_menu._change_screen("main_menu")
	
	# Exit the game
	if event.is_action_pressed("ui_exit"):
		if is_exiting : return
		is_exiting = true
		main._exit()
