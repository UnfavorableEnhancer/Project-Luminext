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
	$V.visible = false
	$ColorRect.visible = false
	$ColorRect2.visible = false
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
			if not $V.visible: set_process(false)
	
	# TODO : Disabled due to being too buggy
	
	#if event.is_action_pressed("debug_mode"):
		#if not $V.visible:
			#$V.visible = true
			#$ColorRect2.visible = true
			#set_process(true)
		#else:
			#$V.visible = false
			#$ColorRect2.visible = false
			#if not $FPS.visible: set_process(false)


func _process(_delta : float) -> void:
	if $FPS.visible:
		$FPS.text = "FPS : " + str(Performance.get_monitor(Performance.TIME_FPS))
	
	if $V.visible:
		if Data.menu != null:
			$V/MenuScr.text = "CURRENT MENU SCREEN : " + Data.menu.current_screen_name
			$V/PrevScr.text = "PREVIOUS MENU SCREEN : " + Data.menu.previous_screen_name
			$V/MenuLock.text = "MENU LOCKED : " + str(Data.menu.is_locked)
			$V/Cursor.text = "MENU CURSOR CORDS = X : " + str(Data.menu.current_screen.cursor.x) + " Y : " + str(Data.menu.current_screen.cursor.y)
			$V/CurrentSelect.text = "CURRENTLY SELECTED : " + str(Data.menu.currently_selected)
			$V/PrevSelect.text = "PREVIOUSLY SELECTED : " + str(Data.menu.previously_selected)
			$V/CursorDash.text = "CURSOR DASH TIMER : " + str(Data.menu.input_hold)
			$V/CursorLock.text = "CURSOR LOCK [LEFT,RIGHT,UP,DOWN] : " + str(Data.menu.input_lock)
			$V/ScreenAdd.text = "SCREENS CREATE QUEUE SIZE : " + str(Data.menu.currently_adding_screens_amount)
			$V/ScreenRem.text = "SCREENS REMOVE QUEUE SIZE : " + str(Data.menu.currently_removing_screens_amount)
		
		if Data.game != null:
			$V/Speed.text = "PIECE SPEED : " + str(Data.game.piece_fall_speed)
			$V/Delay.text = "PIECE DELAY : " + str(Data.game.piece_fall_delay)
			
			if Data.game.piece != null:
				$V/PiecePos.text = "PIECE POSITION = X : " + str(Data.game.piece.X) + " Y : " + str(Data.game.piece.Y)
				if is_instance_valid(Data.game.piece.fall_timer) : $V/FallTime.text = "PIECE FALL TIMER : " + str(Data.game.piece.fall_timer.time_left)
				if is_instance_valid(Data.game.piece.delay_timer) : $V/DelayTime.text = "PIECE DELAY TIMER : " + str(Data.game.piece.delay_timer.time_left)
				$V/Dash.text = "DASH TIMER : " + str(Data.game.piece.dash_timer.time_left)
			
			$V/Blocks.text = "BLOCKS COUNT : " + str(Data.game.blocks.size())
			$V/Squares.text = "SQUARES COUNT : " + str(Data.game.squares.size())
			$V/Erase.text = "ERASE BLOCKS COUNT : " + str(Data.game.delete.size())
			$V/Special.text = "NEXT SPECIAL : " + str(Data.game.piece_queue.before_special_left)
			$V/SkinChange.text = "CHANGING SKINS :" + str(Data.game.is_changing_skins_now)
			
			if Data.game.gamemode != null:
				$V/LevelUp.text = "LEVEL UP LEFT : " + str(Data.game.gamemode.left_before_level_up)
			
			
			
		
