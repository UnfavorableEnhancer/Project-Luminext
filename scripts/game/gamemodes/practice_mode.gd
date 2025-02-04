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

extends PlaylistMode

class_name PracticeMode


enum TUTORIAL_STAGE {
	NONE,
	INTRO,
	MOVE_PIECE,
	DASH_PIECE,
	ROTATE_PIECE,
	PIECE_FALLING,
	QUICK_DROP,
	SQUARE_BUILDING,
	TIMELINE,
	ADJACENCY,
	BONUS,
	QUEUE_SHIFT,
	CHAIN_BLOCK,
	GAME_OVER,
	OUTRO,
}

var practice_ui : UIElement = null
var start_tutorial : bool = false

var tutorial_stage : int = TUTORIAL_STAGE.NONE
var tutorial_progress : int = 0


func _ready() -> void:
	name = "PracticeMode"
	gamemode_name = "practice_mode"

	game.pause_screen_name = "practice_pause"
	game.game_over_screen_name = "playlist_mode_gameover"
	game.menu_screen_to_return = "main_menu"

	game.timeline_started.connect(_connect_timeline)

	is_single_skin_mode = true
	
	_load_ui()

	if custom_config_preset != null:
		config_backup = GameConfigPreset.new()
		config_backup._store_current_config()
		custom_config_preset._apply_preset()

	time_timer = Timer.new()
	time_timer.timeout.connect(_update_time)
	time_timer.one_shot = false
	add_child(time_timer)
	time_timer.start(1.0)


func _load_ui() -> void:
	var foreground : Node2D = game.foreground
	foreground._reset()

	foreground._add_ui_element("grid")
	foreground._add_ui_element("progress")
	foreground._add_ui_element("holder")
	foreground._add_ui_element("bonus")

	scoreboard = foreground._add_ui_element("scoreboard")
	scoreboard._enable_counter("level")
	scoreboard._enable_counter("time")
	scoreboard._enable_counter("score")
	scoreboard._enable_counter("deleted")

	foreground._add_ui_element("combo")
	practice_ui = foreground._add_ui_element("practice_ui")
	
	foreground._change_style(game.skin.skin_data.textures["ui_design"], game.skin.skin_data, 0.0)


func _reset() -> void:
	if start_tutorial:
		game.is_adding_pieces_to_queue = false
		game.is_manual_timeline = true

		game.piece_fall_speed = 9999.9
		game.piece_fall_delay = 9999.9

		game.input_lock = {
		&"move_left" : false,
		&"move_right" : false,
		&"rotate_left" : true,
		&"rotate_right" : true,
		&"quick_drop" : true,
		&"side_ability" : true
		}

		game.foreground.ui_elements["progress"].visible = false
		game.foreground.ui_elements["progress"].visible = false

		game.game_over_screen_name = "tutorial_gameover"

		_tutorial_sequence()

	else:
		tutorial_stage = TUTORIAL_STAGE.NONE
	
	time_timer.start(1.0)
	await get_tree().create_timer(0.01).timeout
	reset_complete.emit()


func _check_for_special_bonus(deleted_blocks_count : int, force_all_clear : bool = false) -> void:
	if tutorial_stage > 0 : return
	super(deleted_blocks_count, force_all_clear)


func _game_over() -> void:
	if tutorial_stage > 0 : return
	super()


func _tutorial_sequence() -> void:
	tutorial_stage = TUTORIAL_STAGE.INTRO
	await game.paused
	# It's easier to do this thru console in silent mode
	Data.console._command_input("qappend 00 01 00 01", true)
	Data.game.skin.is_music_looping = false

	practice_ui._show_intro()
	await practice_ui.intro_finished
	practice_ui._init_message()

	tutorial_stage = TUTORIAL_STAGE.MOVE_PIECE
	var current_piece : Piece = game.piece

	practice_ui._add_text_to_line(1, "Move your piece with  ")
	practice_ui._add_button_icon_to_line(1, "move_left")
	practice_ui._add_text_to_line(1, "and ")
	practice_ui._add_button_icon_to_line(1, "move_right")
	practice_ui._add_text_to_line(1, "buttons.")
	practice_ui._update_mission_text("Objective : Move piece in both directions")

	while true:
		var move_side : int = await current_piece.piece_moved_side
		if tutorial_progress == 0:
			if move_side == -1: practice_ui._update_mission_text("Objective : Move piece in right direction", 0.2)
			elif move_side == 1: practice_ui._update_mission_text("Objective : Move piece in left direction", 0.2)
			tutorial_progress = move_side
		else:
			if move_side != tutorial_progress: 
				practice_ui._highlight_mission("Good!")
				break
	
	await get_tree().create_timer(1.0).timeout
	practice_ui._close_mission()
	practice_ui._reset_message()
	await get_tree().create_timer(1.0).timeout

	tutorial_stage = TUTORIAL_STAGE.DASH_PIECE
	tutorial_progress = 0

	practice_ui._add_text_to_line(1, "Hold any of the move buttons to dash piece in corresponding direction.")
	practice_ui._update_mission_text("Objective : Dash piece in both directions")

	while true:
		var dash_side : int = await current_piece.piece_dashed
		if tutorial_progress == 0:
			if dash_side == -1: practice_ui._update_mission_text("Objective : Dash piece in right direction", 0.2)
			elif dash_side == 1: practice_ui._update_mission_text("Objective : Dash piece in left direction", 0.2)
			tutorial_progress = dash_side
		else:
			if dash_side != tutorial_progress: 
				practice_ui._highlight_mission("Nice!")
				break

	await get_tree().create_timer(1.0).timeout
	practice_ui._close_mission()
	practice_ui._reset_message()
	await get_tree().create_timer(1.0).timeout

	tutorial_stage = TUTORIAL_STAGE.ROTATE_PIECE
	tutorial_progress = 0
	game.input_lock[&"rotate_right"] = false
	game.input_lock[&"rotate_left"] = false

	practice_ui._add_text_to_line(1, "Rotate your piece clockwise and counterclockwise with  ")
	practice_ui._add_button_icon_to_line(1, "rotate_right")
	practice_ui._add_text_to_line(1, "and ")
	practice_ui._add_button_icon_to_line(1, "rotate_left")
	practice_ui._add_text_to_line(1, "buttons.")
	practice_ui._update_mission_text("Objective : Rotate piece in both directions")

	while true:
		var rotate_side : int = await current_piece.piece_rotated
		if tutorial_progress == 0:
			if rotate_side == -1: practice_ui._update_mission_text("Objective : Rotate piece clockwise", 0.2)
			elif rotate_side == 1: practice_ui._update_mission_text("Objective : Rotate piece counterclockwise", 0.2)
			tutorial_progress = rotate_side
		else:
			if rotate_side != tutorial_progress: 
				practice_ui._highlight_mission("Great!")
				break

	await get_tree().create_timer(1.0).timeout
	practice_ui._close_mission()
	practice_ui._reset_message()
	await get_tree().create_timer(1.0).timeout

	tutorial_stage = TUTORIAL_STAGE.PIECE_FALLING
	tutorial_progress = 0

	game.input_lock = {
		&"move_left" : true,
		&"move_right" : true,
		&"rotate_left" : true,
		&"rotate_right" : true,
		&"quick_drop" : true,
		&"side_ability" : true
		}
	game._add_block(Vector2i(8,9),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_block(Vector2i(8,8),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(8,7),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_block(Vector2i(8,6),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(8,5),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_block(Vector2i(8,4),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(8,3),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_block(Vector2i(8,2),BlockBase.BLOCK_COLOR.RED,"",true)
	
	await get_tree().create_timer(0.1).timeout
	current_piece.current_dash_side = 0
	current_piece.position = Vector2(8 * 68, -1 * 68 - 2)
	current_piece.grid_position = Vector2i(8, -1)
	current_piece.piece_moved.emit(Vector2(8 * 68, -1 * 68 - 2))

	practice_ui._add_text_to_line(1, "When you get new piece, it will start falling after some delay.")
	practice_ui._update_mission_text("Please wait...")
	current_piece.fall_delay = 1.0
	current_piece.fall_speed = 1.0
	game.piece_fall_speed = 1.0
	game.piece_fall_delay = 1.0

	await current_piece.piece_landed
	practice_ui._reset_message()
	await get_tree().create_timer(0.5).timeout
	practice_ui._add_text_to_line(1, "Piece lands when it's bottom hits floor or some other block.")
	practice_ui._add_text_to_line(2, "When piece lands, blocks which formed that piece will start falling by their own.")
	await get_tree().create_timer(5.0).timeout
	practice_ui._reset_message()
	await get_tree().create_timer(0.5).timeout
	
	game.piece_fall_speed = 0.1
	game.piece_fall_delay = 1.0
	Data.console._command_input("qappend 00 01 01 00", true)
	current_piece = game.piece
	
	practice_ui._add_text_to_line(1, "If piece is at top of the field and it hits just one block, it slides out.")
	await current_piece.piece_landed
	await get_tree().create_timer(2.0).timeout
	practice_ui._close_mission()
	practice_ui._reset_message()
	await get_tree().create_timer(1.0).timeout

	tutorial_stage = TUTORIAL_STAGE.QUICK_DROP
	game.input_lock = {
		&"move_left" : false,
		&"move_right" : false,
		&"rotate_left" : false,
		&"rotate_right" : false,
		&"quick_drop" : false,
		&"side_ability" : true
		}

	game.piece_fall_speed = 9999.9
	game.piece_fall_delay = 9999.9
	Data.console._command_input("qappend 00 01 01 00", true)
	await get_tree().create_timer(0.1).timeout
	current_piece = game.piece
	
	practice_ui._add_text_to_line(1, "You can drop piece faster by holding  ")
	practice_ui._add_button_icon_to_line(1, "quick_drop")
	practice_ui._add_text_to_line(1, " button.")
	practice_ui._update_mission_text("Objective : Quick drop this piece")
	
	await current_piece.piece_quick_drop
	practice_ui._highlight_mission("Good!")
	await get_tree().create_timer(1.0).timeout
	practice_ui._close_mission()
	practice_ui._reset_message()
	await get_tree().create_timer(1.0).timeout

	tutorial_stage = TUTORIAL_STAGE.SQUARE_BUILDING
	game._clear_field()

	game.piece_fall_speed = 2.0
	game.piece_fall_delay = 2.0
	Data.console._command_input("qappend 00 01 00 01", true)
	Data.console._command_input("qappend 00 01 00 01", true)

	game._add_ghost(Vector2i(8,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(8,8),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_ghost(Vector2i(8,7),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_ghost(Vector2i(8,6),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(9,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(9,8),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_ghost(Vector2i(9,7),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_ghost(Vector2i(9,6),BlockBase.BLOCK_COLOR.RED,"",true)

	practice_ui._add_text_to_line(1, "When same-colored blocks are placed in 2x2 pattern they form a square.")
	practice_ui._update_mission_text("Objective : Build one square by placing pieces like ghost blocks show")

	while true:
		await get_tree().create_timer(1.0).timeout
		
		if game.squares.size() > 0 :
			practice_ui._highlight_mission("Great!")
			await get_tree().create_timer(1.0).timeout
			break
		
		if game.piece_queue.queue.size() < 1 and not is_instance_valid(game.piece):
			practice_ui._highlight_mission("missed!", true)
			await get_tree().create_timer(2.0).timeout
		
			game._clear_field()
			Data.console._command_input("qappend 00 01 00 01", true)
			Data.console._command_input("qappend 00 01 00 01", true)
			practice_ui._update_mission_text("Objective : Build one square by placing pieces like ghost blocks show")
	
	tutorial_stage = TUTORIAL_STAGE.TIMELINE
	game._clear_ghosts()
	practice_ui._reset_message()
	practice_ui._update_mission_text("Please wait...")
	game.is_manual_timeline = false
	await game.skin.sample_ended
	practice_ui._close_mission()

	practice_ui._add_text_to_line(1, "This is timeline. It spawns and moves with rhythm of the music and erases all squares it passes.")
	practice_ui._add_text_to_line(2, "You gain score when any square is deleted by timeline.")
	
	await get_tree().create_timer(6.0).timeout
	game._clear_field()
	practice_ui._reset_message()
	await get_tree().create_timer(1.0).timeout

	tutorial_stage = TUTORIAL_STAGE.ADJACENCY
	game._add_ghost(Vector2i(7,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(8,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(9,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(10,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(7,8),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(8,8),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(9,8),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(10,8),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(9,7),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(10,7),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(9,6),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(10,6),BlockBase.BLOCK_COLOR.RED,"",true)

	Data.console._command_input("qappend 00 00 00 00", true)
	Data.console._command_input("qappend 00 00 00 00", true)
	Data.console._command_input("qappend 00 00 00 00", true)

	practice_ui._add_text_to_line(1, "Blocks inside square also can form new squares with adjacent same-colored blocks.")
	practice_ui._update_mission_text("Build 5 squares by placing 3 pieces like ghost blocks show. Watch for timeline movement!")

	while true:
		await get_tree().create_timer(1.0).timeout
		
		if game.squares.size() > 4 and game.timeline.scanned_blocks.size() == 0:
			game.timeline._end(false,false)
			practice_ui._highlight_mission("Awesome!")
			game._clear_ghosts()
			practice_ui._reset_message()
			await get_tree().create_timer(0.5).timeout
			practice_ui._update_mission_text("Please wait...")
			await game.skin.sample_ended
			break
		
		if (game.piece_queue.queue.size() < 1 and not is_instance_valid(game.piece)) or game.timeline.scanned_blocks.size() > 0:
			practice_ui._highlight_mission("ouch!", true)
			await get_tree().create_timer(2.0).timeout
		
			game._clear_field()
			Data.console._command_input("qappend 00 00 00 00", true)
			Data.console._command_input("qappend 00 00 00 00", true)
			Data.console._command_input("qappend 00 00 00 00", true)
			practice_ui._update_mission_text("Build 5 squares by placing 3 pieces like ghost blocks show. Watch for timeline movement!")
	
	tutorial_stage = TUTORIAL_STAGE.BONUS
	practice_ui._close_mission()

	practice_ui._add_text_to_line(1, "Timeline erases all squares on the way until there's nothing to delete.")
	practice_ui._add_text_to_line(2, "The more squares erased at once, the more score you will get!")
	
	await game.skin.sample_ended
	practice_ui._reset_message()
	await get_tree().create_timer(0.5).timeout

	practice_ui._add_text_to_line(1, "When timeline reaches end with 4 or more squares erased you get 4X bonus!")
	practice_ui._add_text_to_line(2, "Making multiple 4X bonuses increases your combo count, which multiplyes any score increase.")

	await get_tree().create_timer(6.0).timeout
	
	practice_ui._reset_message()
	await get_tree().create_timer(1.0).timeout

	tutorial_stage = TUTORIAL_STAGE.QUEUE_SHIFT
	game.input_lock[&"side_ability"] = false

	game._add_ghost(Vector2i(9,9),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_ghost(Vector2i(9,8),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_ghost(Vector2i(9,7),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_ghost(Vector2i(9,6),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(10,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(10,8),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_ghost(Vector2i(10,7),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_ghost(Vector2i(10,6),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(7,7),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_ghost(Vector2i(8,7),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_ghost(Vector2i(7,6),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_ghost(Vector2i(8,6),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(7,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(7,8),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(8,9),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_block(Vector2i(8,8),BlockBase.BLOCK_COLOR.WHITE,"",true)

	Data.console._command_input("qappend 00 01 00 01", true)
	Data.console._command_input("qappend 01 00 00 01", true)
	Data.console._command_input("qappend 01 01 01 00", true)

	practice_ui._add_text_to_line(1, "To build squares more efficiently, you can replace current piece with next in queue by pressing  ")
	practice_ui._add_button_icon_to_line(1, "side_ability")
	practice_ui._add_text_to_line(1, " button.")
	practice_ui._update_mission_text("Build 3 white squares by placing pieces like ghost blocks show.")

	while true:
		await get_tree().create_timer(1.0).timeout
		
		if game.squares.size() > 2 and game.timeline.scanned_blocks.size() == 0:
			game.timeline._end(false,false)
			practice_ui._highlight_mission("Excellent!")
			game._clear_ghosts()
			practice_ui._reset_message()
			await get_tree().create_timer(0.5).timeout
			practice_ui._update_mission_text("Please wait...")
			await game.skin.sample_ended
			break
		
		if (game.piece_queue.queue.size() < 1 and not is_instance_valid(game.piece)) or game.timeline.scanned_blocks.size() > 0:
			practice_ui._highlight_mission("oof!", true)
	
			if is_instance_valid(game.piece) : game.piece._end()
			game.piece_queue._clear()
			await get_tree().create_timer(2.0).timeout
		
			game._clear_field()
			Data.console._command_input("qappend 00 01 00 01", true)
			Data.console._command_input("qappend 01 00 00 01", true)
			Data.console._command_input("qappend 01 01 01 00", true)
			
			game._add_block(Vector2i(7,9),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(7,8),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(8,9),BlockBase.BLOCK_COLOR.WHITE,"",true)
			game._add_block(Vector2i(8,8),BlockBase.BLOCK_COLOR.WHITE,"",true)
			practice_ui._update_mission_text("Build 3 white squares by placing pieces like ghost blocks show.")
	
	practice_ui._add_text_to_line(1, "More squares you make, more opportunities for making new squares you'll find!")
	await get_tree().create_timer(4.5).timeout
	practice_ui._close_mission()
	practice_ui._reset_message()
	game._clear_field()
	game.is_manual_timeline = true
	game.timeline._end()
	await get_tree().create_timer(1.0).timeout

	tutorial_stage = TUTORIAL_STAGE.CHAIN_BLOCK

	practice_ui._add_text_to_line(1, "After some amount of pieces passes, next piece will have a special block, which makes unique effect when squared.")
	practice_ui._add_text_to_line(2, "This one is called 'Chain' block.")
	practice_ui._update_mission_text("Build a red square with chain block and see what happens!")

	Data.console._command_input("qappend 10 00 01 01", true)

	game._add_block(Vector2i(4,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(5,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(6,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(7,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(8,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(9,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(10,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(11,9),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(7,8),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(8,8),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_block(Vector2i(9,8),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_block(Vector2i(10,8),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_block(Vector2i(11,8),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_block(Vector2i(7,7),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(8,7),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(9,7),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(10,7),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(11,7),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(7,6),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(8,6),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_block(Vector2i(9,6),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_block(Vector2i(10,6),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_block(Vector2i(11,6),BlockBase.BLOCK_COLOR.WHITE,"",true)
	game._add_block(Vector2i(7,5),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(8,5),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(9,5),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(10,5),BlockBase.BLOCK_COLOR.RED,"",true)
	game._add_block(Vector2i(11,5),BlockBase.BLOCK_COLOR.RED,"",true)

	while true:
		await get_tree().create_timer(1.0).timeout
		
		if game.squares.size() > 0:
			practice_ui._highlight_mission("Cool!")
			practice_ui._reset_message()
			await get_tree().create_timer(0.5).timeout
			practice_ui._update_mission_text("Please wait...")
			game.is_manual_timeline = false
			await game.skin.sample_ended
			break
		
		if game.piece_queue.queue.size() < 1 and not is_instance_valid(game.piece):
			practice_ui._highlight_mission("bruh..", true)
		
			game._clear_field()
			Data.console._command_input("qappend 10 00 01 01", true)

			game._add_block(Vector2i(4,9),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(5,9),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(6,9),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(7,9),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(8,9),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(9,9),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(10,9),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(11,9),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(7,8),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(8,8),BlockBase.BLOCK_COLOR.WHITE,"",true)
			game._add_block(Vector2i(9,8),BlockBase.BLOCK_COLOR.WHITE,"",true)
			game._add_block(Vector2i(10,8),BlockBase.BLOCK_COLOR.WHITE,"",true)
			game._add_block(Vector2i(11,8),BlockBase.BLOCK_COLOR.WHITE,"",true)
			game._add_block(Vector2i(7,7),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(8,7),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(9,7),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(10,7),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(11,7),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(7,6),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(8,6),BlockBase.BLOCK_COLOR.WHITE,"",true)
			game._add_block(Vector2i(9,6),BlockBase.BLOCK_COLOR.WHITE,"",true)
			game._add_block(Vector2i(10,6),BlockBase.BLOCK_COLOR.WHITE,"",true)
			game._add_block(Vector2i(11,6),BlockBase.BLOCK_COLOR.WHITE,"",true)
			game._add_block(Vector2i(7,5),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(8,5),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(9,5),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(10,5),BlockBase.BLOCK_COLOR.RED,"",true)
			game._add_block(Vector2i(11,5),BlockBase.BLOCK_COLOR.RED,"",true)

			await get_tree().create_timer(1.0).timeout
			practice_ui._update_mission_text("Build a red square with chain block and see what happens!")
	
	
	practice_ui._close_mission()
	
	practice_ui._add_text_to_line(1, "When you build square with chain block.")
	practice_ui._add_text_to_line(2, "All adjacent same colored blocks are turned deletable and timeline erase them too!")
	await game.skin.sample_ended
	practice_ui._reset_message()
	game._clear_field()
	await get_tree().create_timer(1.0).timeout

	#game._add_block(Vector2i(8,9),BlockBase.BLOCK_COLOR.WHITE,&"merge",true)
	#game._add_block(Vector2i(10,9),BlockBase.BLOCK_COLOR.RED,"",true)
	#game._add_block(Vector2i(10,8),BlockBase.BLOCK_COLOR.RED,"",true)
	#game._add_block(Vector2i(10,7),BlockBase.BLOCK_COLOR.RED,"",true)
	#game._add_block(Vector2i(10,6),BlockBase.BLOCK_COLOR.RED,"",true)
	#game._add_block(Vector2i(10,5),BlockBase.BLOCK_COLOR.RED,"",true)
	#game._add_block(Vector2i(10,4),BlockBase.BLOCK_COLOR.WHITE,&"wipe",true)
	#game._add_block(Vector2i(12,9),BlockBase.BLOCK_COLOR.RED,"",true)
	#game._add_block(Vector2i(12,8),BlockBase.BLOCK_COLOR.RED,"",true)
	#game._add_block(Vector2i(12,7),BlockBase.BLOCK_COLOR.RED,"",true)
	#game._add_block(Vector2i(12,6),BlockBase.BLOCK_COLOR.RED,"",true)
	#game._add_block(Vector2i(12,5),BlockBase.BLOCK_COLOR.MULTI,"",true)
	#game._add_block(Vector2i(14,9),BlockBase.BLOCK_COLOR.WHITE,"",true)
	#game._add_block(Vector2i(14,8),BlockBase.BLOCK_COLOR.WHITE,"",true)
	#game._add_block(Vector2i(14,7),BlockBase.BLOCK_COLOR.GARBAGE,"",true)
#
	#practice_ui._add_text_to_line(1, "There's a lot more special blocks avaiable.")
	#practice_ui._add_text_to_line(2, "Can you find out what they do?")

	#await get_tree().create_timer(4.0).timeout
	#practice_ui._reset_message()
	#game._clear_field()
	#await get_tree().create_timer(1.0).timeout

	tutorial_stage = TUTORIAL_STAGE.GAME_OVER

	game.input_lock[&"move_left"] = true
	game.input_lock[&"move_right"] = true
	game.piece_fall_speed = 0.01
	game.piece_fall_delay = 0.01

	Data.console._command_input("qappend 00 01 01 00", true)
	Data.console._command_input("qappend 00 01 01 00", true)
	Data.console._command_input("qappend 00 01 01 00", true)
	Data.console._command_input("qappend 00 01 01 00", true)
	Data.console._command_input("qappend 00 01 01 00", true)
	Data.console._command_input("qappend 00 01 01 00", true)
	Data.console._command_input("qappend 00 01 01 00", true)
	Data.console._command_input("qappend 00 01 01 00", true)
	Data.console._command_input("qappend 00 01 01 00", true)
	
	await get_tree().create_timer(0.05).timeout
	current_piece = game.piece
	current_piece.position = Vector2(8 * 68, -1 * 68 - 2)
	current_piece.grid_position = Vector2i(8, -1)
	current_piece.piece_moved.emit(Vector2(8 * 68, -1 * 68 - 2))

	practice_ui._add_text_to_line(1, "Game is over when piece is placed on top of the game field.")
	practice_ui._add_text_to_line(2, "So to stay long and play good, you must build as many squares as possible!")
