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

const DEBUG_TIMER : float = 0.2

var is_fps_active : bool = false
var is_game_debug_active : bool = false
var is_menu_debug_active : bool = false
var is_skin_debug_active : bool = false

enum DEBUG {FPS, MENU, GAME, SKIN}


func _ready() -> void:
	$FPS.visible = false
	$Menu.visible = false
	$Game.visible = false
	$Skin.visible = false
	
	$DebugTimer.wait_time = DEBUG_TIMER
	$DebugTimer.start()


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("fps_output"): _toggle(DEBUG.FPS)
	elif event.is_action_pressed("menu_debug"): _toggle(DEBUG.MENU)
	elif event.is_action_pressed("game_debug"): _toggle(DEBUG.GAME)
	elif event.is_action_pressed("skin_debug"): _toggle(DEBUG.SKIN)


func _toggle(what : int) -> void:
	match what:
		DEBUG.FPS:
			if not is_fps_active:
				$FPS.visible = true
				is_fps_active = true
			else:
				$FPS.visible = false
				is_fps_active = false
		DEBUG.MENU:
			if not is_menu_debug_active:
				$Menu.visible = true
				is_menu_debug_active = true
			else:
				$Menu.visible = false
				is_menu_debug_active = false
		DEBUG.GAME:
			if not is_game_debug_active:
				$Game.visible = true
				is_game_debug_active = true
			else:
				$Game.visible = false
				is_game_debug_active = false
		DEBUG.SKIN:
			if not is_skin_debug_active:
				$Skin.visible = true
				is_skin_debug_active = true
			else:
				$Skin.visible = false
				is_skin_debug_active = false


func _process(_delta : float) -> void:
	if is_fps_active: $FPS/Text.text = "FPS : " + str(Performance.get_monitor(Performance.TIME_FPS))
	if is_menu_debug_active:
		if Data.menu == null : return
		if is_instance_valid(Data.menu.current_screen):
			$Menu/V/Dash.text = "Input dash timer :" + str(Data.menu.current_screen.input_hold)
	if is_game_debug_active:
		if Data.game == null : return
		if is_instance_valid(Data.game.piece):
			var piece : Piece = Data.game.piece
			$Game/V/PPos.text = "Piece position : X = " + str(piece.grid_position.x) + ", Y = " + str(piece.grid_position.y)
			$Game/V/FallSpd2.text = "Current piece fall timer : " + str(piece.fall_speed_left)
			$Game/V/FallDelay2.text = "Current piece delay timer : " + str(piece.fall_delay)
			$Game/V/DashT.text = "Piece dash timer : " + str(piece.dash_left)
			if piece.current_dash_side == -1: $Game/V/Dash.text = "Piece dash state : DASH LEFT"
			elif piece.current_dash_side == 1: $Game/V/Dash.text = "Piece dash state : DASH RIGHT"
			else: $Game/V/Dash.text = "Piece dash state : NONE"
			$Game/V/QDropT.text = "Piece quick drop timer : " + str(piece.quick_drop_delay)
			$Game/V/QDrop.text = "Can quick drop piece : " + str(piece.can_be_quick_dropped)
		if is_instance_valid(Data.game.timeline):
			var timeline : Node2D = Data.game.timeline
			$Game/V/TPos.text = "Timeline position : X = " + str(timeline.x_pos)
			$Game/V/TSpeed.text = "Timeline speed : " + str(timeline.speed)
			$Game/V/TSqr.text = "Current scanned squares count : " + str(timeline.scanned_squares.size())
			$Game/V/TBlk.text = "Current scanned blocks count : " + str(timeline.scanned_blocks.size())
			$Game/V/TTSqr.text = "Total scanned squares count : " + str(timeline.total_deleted_squares_count)
			$Game/V/TGrp.text = "Current scanned square group size : " + str(timeline.current_square_group_size)
			$Game/V/TBeat.text = "Is timeline doing beat : " + str(timeline.is_doing_beat)
		
		if is_instance_valid(Data.game.gamemode):
			var gamemode : Gamemode = Data.game.gamemode
			if gamemode is PlaylistMode:
				$Game/V/Gamemode1.text = "CURRENT GAMEMODE : PLAYLIST MODE"
				$Game/V/Gamemode2.text = "Seed : " + str(Data.game.rng.seed)
				$Game/V/Gamemode3.text = "Squares left for level up : " + str(gamemode.left_before_level_up)
				$Game/V/Gamemode4.text = "Next level requirement : " + str(gamemode.next_level_req)
				if not gamemode.is_single_skin_mode:
					$Game/V/Gamemode5.text = "Total level count per skin : " + str(gamemode.max_level_count)
					$Game/V/Gamemode6.text = "Playlist position : " + str(gamemode.playlist_pos)
					$Game/V/Gamemode7.text = "Current lap : " + str(gamemode.current_lap)
					$Game/V/Gamemode8.text = "Single run : " + str(gamemode.is_single_run)
			if gamemode is SynthesiaMode:
				$Game/V/Gamemode1.text = "CURRENT GAMEMODE : SYNTHESIA MODE"
				$Game/V/Gamemode2.text = "Music file path : " + gamemode.music_file_path_to_load
				$Game/V/Gamemode3.text = "Calculated BPM : " + gamemode.bpm
				$Game/V/Gamemode4.text = "Seed : " + str(Data.game.rng.seed)
				$Game/V/Gamemode5.text = "Squares left for level up : " + str(gamemode.left_before_level_up)
				$Game/V/Gamemode6.text = "Next level requirement : " + str(gamemode.next_level_req)
			if gamemode is TimeAttackMode:
				$Game/V/Gamemode1.text = "CURRENT GAMEMODE : TIME ATTACK MODE"
				if gamemode.is_first_run:
					if gamemode.is_counting_time : $Game/V/Gamemode2.text = "State : COUNTING [FIRST RUN]"
					else: $Game/V/Gamemode2.text = "State : GAME OVER [FIRST RUN]"
				else:
					if gamemode.is_counting_time : $Game/V/Gamemode2.text = "State : COUNTING"
					else: $Game/V/Gamemode2.text = "State : GAME OVER"
				
				$Game/V/Gamemode3.text = "Seed : " + str(Data.game.rng.seed)
				$Game/V/Gamemode4.text = "Attempt № : " + str(gamemode.current_attempt)
				$Game/V/Gamemode5.text = "Statistics collect timer : " + str(gamemode.stat_timer.time_left)
				$Game/V/Gamemode6.text = "Statistics collect stop timer : " + str(gamemode.stat_disable_timer.time_left)
				$Game/V/Gamemode7.text = "Current music mix № : " + str(gamemode.current_mix)
			if gamemode is PracticeMode:
				$Game/V/Gamemode1.text = "CURRENT GAMEMODE : PRACTICE MODE"
				$Game/V/Gamemode2.text = "Seed : " + str(Data.game.rng.seed)
				$Game/V/Gamemode3.text = "Squares left for level up : " + str(gamemode.left_before_level_up)
				$Game/V/Gamemode4.text = "Next level requirement : " + str(gamemode.next_level_req)
				match gamemode.tutorial_stage:
					PracticeMode.TUTORIAL_STAGE.NONE : $Game/V/Gamemode5.text = "Tutorial stage : NONE"
					PracticeMode.TUTORIAL_STAGE.INTRO : $Game/V/Gamemode5.text = "Tutorial stage : INTRO"
					PracticeMode.TUTORIAL_STAGE.MOVE_PIECE : $Game/V/Gamemode5.text = "Tutorial stage : MOVE_PIECE"
					PracticeMode.TUTORIAL_STAGE.DASH_PIECE : $Game/V/Gamemode5.text = "Tutorial stage : DASH_PIECE"
					PracticeMode.TUTORIAL_STAGE.ROTATE_PIECE : $Game/V/Gamemode5.text = "Tutorial stage : ROTATE_PIECE"
					PracticeMode.TUTORIAL_STAGE.PIECE_FALLING : $Game/V/Gamemode5.text = "Tutorial stage : PIECE_FALLING"
					PracticeMode.TUTORIAL_STAGE.QUICK_DROP : $Game/V/Gamemode5.text = "Tutorial stage : QUICK_DROP"
					PracticeMode.TUTORIAL_STAGE.SQUARE_BUILDING : $Game/V/Gamemode5.text = "Tutorial stage : SQUARE_BUILDING"
					PracticeMode.TUTORIAL_STAGE.TIMELINE : $Game/V/Gamemode5.text = "Tutorial stage : TIMELINE"
					PracticeMode.TUTORIAL_STAGE.ADJACENCY : $Game/V/Gamemode5.text = "Tutorial stage : ADJACENCY"
					PracticeMode.TUTORIAL_STAGE.BONUS : $Game/V/Gamemode5.text = "Tutorial stage : BONUS"
					PracticeMode.TUTORIAL_STAGE.QUEUE_SHIFT : $Game/V/Gamemode5.text = "Tutorial stage : QUEUE_SHIFT"
					PracticeMode.TUTORIAL_STAGE.CHAIN_BLOCK : $Game/V/Gamemode5.text = "Tutorial stage : CHAIN_BLOCK"
					PracticeMode.TUTORIAL_STAGE.GAME_OVER : $Game/V/Gamemode5.text = "Tutorial stage : GAME_OVER"
	
	if is_skin_debug_active:
		if not is_instance_valid(Data.game) or not is_instance_valid(Data.game.skin) : return
		var skin : Node2D = Data.game.skin
		$Skin/V/Beat.text = "Current beat : " + str(skin.current_beat)
		$Skin/V/HBeat.text = "Current half-beat : " + str(skin.current_half_beat)
		if is_instance_valid(skin.music_player):
			$Skin/V/Pos.text = "Playback position : " + str(skin.music_player.get_playback_position())
		$Skin/V/Loop.text = "Is currently looping : " + str(skin.is_music_looping)


func _debug_check() -> void:
	if is_menu_debug_active:
		if Data.menu == null : $Menu/V/Debug.text = "NO MENU IS CURRENTLY LOADED!"; return
		$Menu/V/Debug.text = "MENU DEBUG"
		$Menu/V/CurScr.text = "Current screen name : " + Data.menu.current_screen_name
		$Menu/V/Locked.text = "Is locked : true" if Data.menu.is_locked else "Is locked : false"
		$Menu/V/AddScr.text = "Currently adding screens amount : " + str(Data.menu.currently_adding_screens_amount)
		$Menu/V/RemScr.text = "Currently removing screens amount : " + str(Data.menu.currently_removing_screens_amount)
		$Menu/V/Music.text = "Current music sample name : " + Data.menu.current_music_sample_name
		
		if is_instance_valid(Data.menu.current_screen):
			var screen : MenuScreen = Data.menu.current_screen
			$Menu/V/PrevScr.text = "Previous screen name : " + screen.previous_screen_name
			$Menu/V/Cursor.text = "Cursor : X = " + str(screen.cursor.x) + ", Y = " + str(screen.cursor.y) 
			var directions : Array = ["HERE", "LEFT", "RIGHT", "UP", "DOWN"]
			$Menu/V/LastCur.text = "Last cursor direction : " + directions[screen.last_cursor_dir]
			$Menu/V/Lock.text = "Input lock : LEFT = " + str(int(screen.input_lock[0])) + ", RIGHT = " + str(int(screen.input_lock[1])) + ", UP = " + str(int(screen.input_lock[2])) + ", DOWN = " + str(int(screen.input_lock[3]))
			if is_instance_valid(screen.currently_selected):
				$Menu/V/CurSel.text = "Currently selected : " + screen.currently_selected.name
			else:
				$Menu/V/CurSel.text = "Currently selected : none"
			if is_instance_valid(screen.previously_selected):
				$Menu/V/PreSel.text = "Previously selected : " + screen.previously_selected.name
			else:
				$Menu/V/PreSel.text = "Previously selected : none"
			$Menu/V/Cancel.text = "Cancel object position : X = " + str(screen.cancel_cursor_pos.x) + ", Y = " + str(screen.cancel_cursor_pos.y) 
	
	if is_game_debug_active:
		if Data.game == null : $Game/V/Debug.text = "NO GAME IS CURRENTLY LOADED!"; return
		$Game/V/Debug.text = "GAME DEBUG"
		if Data.game.is_game_over : $Game/V/State.text = "State : Gameover"
		elif Data.game.is_paused : $Game/V/State.text = "State : Paused"
		else : $Game/V/State.text = "State : Playing"
		$Game/V/SkinChg.text = "Is skin changing : " + str(Data.game.is_changing_skins_now)
		$Game/V/Sound.text = "Sounds in sound queue : " + str(Data.game.sound_queue.size())
		$Game/V/BlkCnt.text = "Total blocks amount : " + str(Data.game.blocks.size())
		$Game/V/SqrCnt.text = "Total squares amount : " + str(Data.game.squares.size())
		$Game/V/DelCnt.text = "Total soon to delete blocks amount : " + str(Data.game.delete.size())
		$Game/V/FallSpd.text = "Piece fall speed : " + str(Data.game.piece_fall_speed)
		$Game/V/FallDelay.text = "Piece fall delay : " + str(Data.game.piece_fall_delay)
		$Game/V/SpecDelay.text = "Before special block left : " + str(Data.game.piece_queue.before_special_left)
	
	if is_skin_debug_active:
		if not is_instance_valid(Data.game) or not is_instance_valid(Data.game.skin) : $Skin/V/Debug.text = "NO SKIN IS CURRENTLY LOADED!"; return
		var skin : Node2D = Data.game.skin
		$Skin/V/Debug.text = "SKIN DEBUG"
		$Skin/V/Name.text = "Name : " + skin.skin_data.metadata.name
		if skin.is_paused: $Skin/V/State.text = "State : Paused"
		else: $Skin/V/State.text = "State : Playing"
		$Skin/V/BPM.text = "BPM : " + str(skin.bpm)
		$Skin/V/SMPos.text = "Last music sample start position : " + str(skin.music_sample_start_position)
		$Skin/V/SSPos.text = "Last scene sample start position : " + str(skin.scene_sample_start_position)
