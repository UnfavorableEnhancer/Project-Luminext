# Project Luminext - an ultimate block-stacking puzzle game
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


extends Control

##-----------------------------------------------------------------------
## Controls several debug windows, which show useful info about specific system
##-----------------------------------------------------------------------

const DEBUG_SCENE : PackedScene = preload("res://scenery/debug/debuger.tscn")

const DEBUG_PERIOD : float = 0.2 ## Period in which some debug info is updated

enum DEBUG_SCREEN {FPS, MENU, GAME, SKIN} ## All avaiable debug skins

var main : Main = null ## Main reference
var menu : Menu = null ## Menu reference
var skin : SkinPlayer = null ## Currently playing skin reference
var game : GameCore = null ## Currently playing game reference

var fps_counter : Control ## FPS counter instance
var menu_debug : Control ## Menu debugger instance
var game_debug : Control ## Game debugger instance
var skin_debug : Control ## Skin debugger instance

var debug_timer : Timer ## Timer which updates debug info with slower rate


func _ready() -> void:
	var debug_scene : Control = DEBUG_SCENE.instantiate()
	add_child(debug_scene)
	fps_counter = debug_scene.get_node("FPS")
	menu_debug = debug_scene.get_node("Menu")
	game_debug = debug_scene.get_node("Game")
	skin_debug = debug_scene.get_node("Skin")

	fps_counter.visible = false
	menu_debug.visible = false
	game_debug.visible = false
	skin_debug.visible = false

	debug_timer = Timer.new()
	debug_timer.wait_time = DEBUG_PERIOD
	debug_timer.timeout.connect(_debug_check)
	add_child(debug_timer)
	debug_timer.start()


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("fps_counter"): _toggle(DEBUG_SCREEN.FPS)


## Toggles specified debug window
func _toggle(what : int) -> void:
	match what:
		DEBUG_SCREEN.FPS : fps_counter.visible = !fps_counter.visible
		DEBUG_SCREEN.MENU : menu_debug.visible = !menu_debug.visible
		DEBUG_SCREEN.GAME : game_debug.visible = !game_debug.visible
		DEBUG_SCREEN.SKIN : skin_debug.visible = !skin_debug.visible


func _process(_delta : float) -> void:
	if fps_counter.visible: 
		fps_counter.get_node("Text").text = "FPS : " + str(Performance.get_monitor(Performance.TIME_FPS))
	
	if menu_debug.visible:
		if not is_instance_valid(menu) : return

		if is_instance_valid(menu.current_screen):
			menu_debug.get_node("V/Dash").text = "Input dash timer :" + str(menu.current_screen.input_hold)
	
	if game_debug.visible:
		if not is_instance_valid(game) : return

		if game is LuminextGame:
			if is_instance_valid(game.piece):
				var piece : Piece = game.piece
				game_debug.get_node("V/PPos").text = "Piece position : X = " + str(piece.grid_position.x) + ", Y = " + str(piece.grid_position.y)
				game_debug.get_node("V/FallSpd2").text = "Current piece fall timer : " + str(piece.fall_speed_left)
				game_debug.get_node("V/FallDelay2").text = "Current piece delay timer : " + str(piece.fall_delay)
				game_debug.get_node("V/DashT").text = "Piece dash timer : " + str(piece.dash_left)
				if piece.current_dash_side == -1: game_debug.get_node("V/Dash").text = "Piece dash state : DASH LEFT"
				elif piece.current_dash_side == 1: game_debug.get_node("V/Dash").text = "Piece dash state : DASH RIGHT"
				else: game_debug.get_node("V/Dash").text = "Piece dash state : NONE"
				game_debug.get_node("V/QDropT").text = "Piece quick drop timer : " + str(piece.quick_drop_delay)
				game_debug.get_node("V/QDrop").text = "Can quick drop piece : " + str(piece.can_be_quick_dropped)
			
			if is_instance_valid(game.timeline):
				var timeline : Timeline = game.timeline
				game_debug.get_node("V/TPos").text = "Timeline position : X = " + str(timeline.x_pos)
				game_debug.get_node("V/TSpeed").text = "Timeline speed : " + str(timeline.speed)
				game_debug.get_node("V/TSqr").text = "Current scanned squares count : " + str(timeline.scanned_squares.size())
				game_debug.get_node("V/TBlk").text = "Current scanned blocks count : " + str(timeline.scanned_blocks.size())
				game_debug.get_node("V/TTSqr").text = "Total scanned squares count : " + str(timeline.total_deleted_squares_count)
				game_debug.get_node("V/TGrp").text = "Current scanned square group size : " + str(timeline.current_square_group_size)
				game_debug.get_node("V/TBeat").text = "Is timeline doing beat : " + str(timeline.is_doing_beat)
			
			if is_instance_valid(game.gamemode):
				var gamemode : Gamemode = game.gamemode

				if gamemode is PlaylistMode:
					game_debug.get_node("V/Gamemode1").text = "CURRENT GAMEMODE : PLAYLIST MODE"
					game_debug.get_node("V/Gamemode2").text = "Seed : " + str(game.rng.seed)
					game_debug.get_node("V/Gamemode3").text = "Squares left for level up : " + str(gamemode.left_before_level_up)
					game_debug.get_node("V/Gamemode4").text = "Next level requirement : " + str(gamemode.next_level_req)
					if not gamemode.is_single_skin_mode:
						game_debug.get_node("V/Gamemode5").text = "Total level count per skin : " + str(gamemode.max_level_count)
						game_debug.get_node("V/Gamemode6").text = "Playlist position : " + str(gamemode.playlist_pos)
						game_debug.get_node("V/Gamemode7").text = "Current lap : " + str(gamemode.current_lap)
						game_debug.get_node("V/Gamemode8").text = "Single run : " + str(gamemode.is_single_run)
				
				if gamemode is SynthesiaMode:
					game_debug.get_node("V/Gamemode1").text = "CURRENT GAMEMODE : SYNTHESIA MODE"
					game_debug.get_node("V/Gamemode2").text = "Music file path : " + gamemode.music_file_path_to_load
					game_debug.get_node("V/Gamemode3").text = "Calculated BPM : " + gamemode.bpm
					game_debug.get_node("V/Gamemode4").text = "Seed : " + str(game.rng.seed)
					game_debug.get_node("V/Gamemode5").text = "Squares left for level up : " + str(gamemode.left_before_level_up)
					game_debug.get_node("V/Gamemode6").text = "Next level requirement : " + str(gamemode.next_level_req)
				
				if gamemode is TimeAttackMode:
					game_debug.get_node("V/Gamemode1").text = "CURRENT GAMEMODE : TIME ATTACK MODE"
					if gamemode.is_first_run:
						if gamemode.is_counting_time : game_debug.get_node("V/Gamemode2").text = "State : COUNTING [FIRST RUN]"
						else: game_debug.get_node("V/Gamemode2").text = "State : GAME OVER [FIRST RUN]"
					else:
						if gamemode.is_counting_time : game_debug.get_node("V/Gamemode2").text = "State : COUNTING"
						else: game_debug.get_node("V/Gamemode2").text = "State : GAME OVER"
					
					game_debug.get_node("V/Gamemode3").text = "Seed : " + str(game.rng.seed)
					game_debug.get_node("V/Gamemode4").text = "Attempt № : " + str(gamemode.current_attempt)
					game_debug.get_node("V/Gamemode5").text = "Statistics collect timer : " + str(gamemode.stat_timer.time_left)
					game_debug.get_node("V/Gamemode6").text = "Statistics collect stop timer : " + str(gamemode.stat_disable_timer.time_left)
					game_debug.get_node("V/Gamemode7").text = "Current music mix № : " + str(gamemode.current_mix)
				
				if gamemode is PracticeMode:
					game_debug.get_node("V/Gamemode1").text = "CURRENT GAMEMODE : PRACTICE MODE"
					game_debug.get_node("V/Gamemode2").text = "Seed : " + str(game.rng.seed)
					game_debug.get_node("V/Gamemode3").text = "Squares left for level up : " + str(gamemode.left_before_level_up)
					game_debug.get_node("V/Gamemode4").text = "Next level requirement : " + str(gamemode.next_level_req)
					var stage_text : String
					match gamemode.tutorial_stage:
						PracticeMode.TUTORIAL_STAGE.NONE : stage_text = "Tutorial stage : NONE"
						PracticeMode.TUTORIAL_STAGE.INTRO : stage_text = "Tutorial stage : INTRO"
						PracticeMode.TUTORIAL_STAGE.MOVE_PIECE : stage_text = "Tutorial stage : MOVE_PIECE"
						PracticeMode.TUTORIAL_STAGE.DASH_PIECE : stage_text = "Tutorial stage : DASH_PIECE"
						PracticeMode.TUTORIAL_STAGE.ROTATE_PIECE : stage_text = "Tutorial stage : ROTATE_PIECE"
						PracticeMode.TUTORIAL_STAGE.PIECE_FALLING : stage_text = "Tutorial stage : PIECE_FALLING"
						PracticeMode.TUTORIAL_STAGE.QUICK_DROP : stage_text = "Tutorial stage : QUICK_DROP"
						PracticeMode.TUTORIAL_STAGE.SQUARE_BUILDING : stage_text = "Tutorial stage : SQUARE_BUILDING"
						PracticeMode.TUTORIAL_STAGE.TIMELINE : stage_text = "Tutorial stage : TIMELINE"
						PracticeMode.TUTORIAL_STAGE.ADJACENCY : stage_text = "Tutorial stage : ADJACENCY"
						PracticeMode.TUTORIAL_STAGE.BONUS : stage_text = "Tutorial stage : BONUS"
						PracticeMode.TUTORIAL_STAGE.QUEUE_SHIFT : stage_text = "Tutorial stage : QUEUE_SHIFT"
						PracticeMode.TUTORIAL_STAGE.CHAIN_BLOCK : stage_text = "Tutorial stage : CHAIN_BLOCK"
						PracticeMode.TUTORIAL_STAGE.GAME_OVER : stage_text = "Tutorial stage : GAME_OVER"
					
					game_debug.get_node("V/Gamemode4").text = stage_text
	
	if skin_debug.visible:
		if not is_instance_valid(skin) : return

		skin_debug.get_node("V/Beat").text = "Current beat : " + str(skin.current_beat)
		skin_debug.get_node("V/HBeat").text = "Current half-beat : " + str(skin.current_half_beat)
		if skin.is_music_loaded : skin_debug.get_node("V/Pos").text = "Playback position : " + str(skin.music_player.get_playback_position())


## Called by DebugTimer with way lesser frequency than _process()
func _debug_check() -> void:
	if menu_debug.visible:
		if not is_instance_valid(menu) : menu_debug.get_node("V/Debug").text = "NO MENU IS CURRENTLY LOADED!"; return

		menu_debug.get_node("V/Debug").text = "MENU DEBUG"
		menu_debug.get_node("V/CurScr").text = "Current screen name : " + menu.current_screen_name
		menu_debug.get_node("V/Locked").text = "Is locked : true" if menu.is_locked else "Is locked : false"
		menu_debug.get_node("V/AddScr").text = "Currently adding screens amount : " + str(menu.currently_adding_screens_amount)
		menu_debug.get_node("V/RemScr").text = "Currently removing screens amount : " + str(menu.currently_removing_screens_amount)
		menu_debug.get_node("V/Music").text = "Current music sample name : " + menu.latest_music_sample_name
		
		if is_instance_valid(menu.current_screen):
			var screen : MenuScreen = menu.current_screen
			menu_debug.get_node("V/PrevScr").text = "Previous screen name : " + screen.previous_screen_name
			menu_debug.get_node("V/Cursor").text = "Cursor : X = " + str(screen.cursor.x) + ", Y = " + str(screen.cursor.y) 
			var directions : Array = ["HERE", "LEFT", "RIGHT", "UP", "DOWN"]
			menu_debug.get_node("V/LastCur").text = "Last cursor direction : " + directions[screen.last_cursor_dir]
			menu_debug.get_node("V/Lock").text = "Input lock : LEFT = " + str(int(screen.input_lock[0])) + ", RIGHT = " + str(int(screen.input_lock[1])) + ", UP = " + str(int(screen.input_lock[2])) + ", DOWN = " + str(int(screen.input_lock[3]))
			if is_instance_valid(screen.currently_selected):
				menu_debug.get_node("V/CurSel").text = "Currently selected : " + screen.currently_selected.name
			else:
				menu_debug.get_node("V/CurSel").text = "Currently selected : none"
			if is_instance_valid(screen.previously_selected):
				menu_debug.get_node("V/PreSel").text = "Previously selected : " + screen.previously_selected.name
			else:
				menu_debug.get_node("V/PreSel").text = "Previously selected : none"
			menu_debug.get_node("V/Cancel").text = "Cancel object position : X = " + str(screen.cancel_cursor_pos.x) + ", Y = " + str(screen.cancel_cursor_pos.y) 
	
	if game_debug.visible:
		if not is_instance_valid(game) : game_debug.get_node("V/Debug").text = "NO GAME IS CURRENTLY LOADED!"; return

		game_debug.get_node("V/Debug").text = "GAME DEBUG"
		
		if game.is_game_over : game_debug.get_node("V/State").text = "State : Gameover"
		elif game.is_paused : game_debug.get_node("V/State").text = "State : Paused"
		else : game_debug.get_node("V/State").text = "State : Playing"

		game_debug.get_node("V/SkinChg").text = "Is skin changing : " + str(game.is_changing_skin_now)
		game_debug.get_node("V/Sound").text = "Sounds in sound queue : " + str(game.sound_queue.size())
		game_debug.get_node("V/BlkCnt").text = "Total blocks amount : " + str(game.blocks.size())
		game_debug.get_node("V/SqrCnt").text = "Total squares amount : " + str(game.squares.size())
		game_debug.get_node("V/FallSpd").text = "Piece fall speed : " + str(game.piece_fall_speed)
		game_debug.get_node("V/FallDelay").text = "Piece fall delay : " + str(game.piece_fall_delay)
		game_debug.get_node("V/SpecDelay").text = "Before special block left : " + str(game.piece_queue.before_special_left)
	
	if skin_debug.visible:
		if not is_instance_valid(skin) : skin_debug.get_node("V/Debug").text = "NO SKIN IS CURRENTLY LOADED!"; return

		skin_debug.get_node("V/Debug").text = "SKIN DEBUG"
		skin_debug.get_node("V/Name").text = "Name : " + skin.skin_data.metadata.name
		skin_debug.get_node("V/ID").text = "ID : " + skin.skin_data.metadata.id
		if skin.is_paused: skin_debug.get_node("V/State").text = "State : Paused"
		else: 
			match skin.playback_state:
				SkinPlayer.PLAYBACK_STATE.PLAYING : skin_debug.get_node("V/State").text = "State : Playing"
				SkinPlayer.PLAYBACK_STATE.ADVANCING : skin_debug.get_node("V/State").text = "State : Advancing"
				SkinPlayer.PLAYBACK_STATE.LOOPING : skin_debug.get_node("V/State").text = "State : Looping"
			
		skin_debug.get_node("V/BPM").text = "BPM : " + str(skin.bpm)
		skin_debug.get_node("V/SMPos").text = "Last music sample start position : " + str(skin.music_sample_start_position)
