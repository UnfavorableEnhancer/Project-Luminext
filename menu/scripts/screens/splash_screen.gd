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

var is_exiting : bool = true

func _ready() -> void:
	Data.menu.screens["foreground"].visible = false
	$Info/VER.text = "VER " + Data.VERSION
	$Info/BUILD.text = "BUILD " + Data.BUILD
	
	Data.input_method_changed.connect(_label)
	_label()
	
	await get_tree().create_timer(2.0).timeout
	
	$LogoAnim.play("start")
	$StarAnim.play("start")
	is_exiting = false


func _label() -> void:
	if Data.current_input_mode == Data.INPUT_MODE.GAMEPAD: $ENTER.text = tr("PRESS START TO ENTER THE GAME")
	else: $ENTER.text = tr("PRESS ENTER TO START THE GAME")


func _input(event : InputEvent) -> void:
	# Press "start" button to proceed to menu screen
	if not is_exiting:
		if event.is_action_pressed("ui_enter"):
			is_exiting = true 
			
			Data.menu._sound("enter")
			
			if Data.profile.status != OK:
				Data.menu._change_screen("login")
			else:
				Data.menu._change_screen("main_menu")
	
	# Exit the game
	if event.is_action_pressed("ui_exit"):
		Data.main._exit()


func _catch_phrase() -> void:
	var catch : Array[String] = [
	"Life is music",
	"Stack the music",
	"yet another Lumines clone...",
	"hey! you read this message", 
	"welcome to the club",
	"puzzle excellence",
	"luminext system",
	"Lumines love letter", 
	"bean edition", 
	"have a nice day!", 
	"aka. tetris with great music, funky visuals and weird rules", 
	"thank you PSP",
	"Square dance", 
	"thank you for participating",
	"this feature is inspired by minecraft splash texts", 
	"ROCK IS DEAD", 
	"i love hearing the music in my soul", 
	"powered by Godot Engine 4.2.1",
	"Lunyaes was first", 
	"Block challenge", 
	"Puzzle X Music", 
	"Puzzle Fusion", 
	"insert funny splash text here", 
	"this game will xplode your computer!",  
	"ogv sux", 
	"cloning Lumines...", 
	"fan made spiritual successor remake remastered revision edition",  
	"An advanced Lumines clone",
	"Try out Lumines Remastered™ too next time!",
	"pizza time"]
	
	$Info/EDITION.text = catch.pick_random()
