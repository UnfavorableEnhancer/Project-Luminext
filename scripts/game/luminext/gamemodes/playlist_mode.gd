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


extends Gamemode

##-----------------------------------------------------------------------
## Plays thru list of skins in playlist with player defined gamerules
## Single skin mode is also supported here
##-----------------------------------------------------------------------

class_name PlaylistMode

## Consts for adding score
enum SCORE_ADDITION_TYPE {SCORE, DELETED_SQUARES}

enum PLAYLIST_MODE_ERROR {
	OK,
	IN_SINGLE_SKIN_MODE, ## We are in single skin mode, so skin change isn't possible
	PLAYLIST_END, ## Hit playlist end
	PLAYLIST_EMPTY, ## Current playlist is empty
	INVALID_SKIN_DATA, ## Failed to retreive skin data from playlist
	SKIN_CHANGE_IS_BUSY, ## Game already changes skin to some other
	SKIN_CHANGE_FAILED, ## Game failed to change skin
	NO_COLORS_ENABLED, ## User ruleset doesnt have colors enabled
}

const COUNTER_GROW_SPEED : float = 0.75 ## How fast scoreboard counters change their number in seconds

var is_single_run : bool = false ## If true, game will be over after playlist end
var is_single_skin_mode : bool = false ## If true, makes current skin play endlessly, even if playlist exists
var is_playtest_mode : bool = false ## If true, causes return to the skin editor after game end

var current_playlist : SkinPlaylist = Data.skin_playlist ## Currently playing skin playlist
var playlist_pos : int = 0 ## Current position in skin playlist
var current_lap : int = 0 ## Current amount of loops in skin playlist

var menu_screen_to_return : String = "playlist_mode" ## Override for return menu screen after game end

var time : int = 0 ## Current play time
var score : int = 0 ## Current score
var deleted_squares : int = 0 ## Total deleted squares count

var combo : int = 0 ## Counts how many 4X bonuses were in row
var max_combo : int = 32 ## Max combo which can multiply incoming score
var bpm_multiplyer : float = 1.0 ## Multiplyer depending on current skin BPM

var rng_start_seed : int = -1 ## Seed which will be used by rng on game start if > 0

var level : int = 1 ## Current game level
var levels_per_skin : int = 4 ## Amount of levels required to pass before loading next skin in playlist
var next_level_requirement : int = 20 ## Amount of squares required to delete before level up
var left_before_level_up : int = 0 ## Current amount of squares left to delete before level up

var scoreboard : UIElement = null ## Scoreboard [UIElement] instance
var grid : UIElement = null ## Grid [UIElement] instance
var holder : UIElement = null ## Piece holder [UIElement] instance
var progress_bar : UIElement = null ## Progress bar [UIElement] instance
var combo_counter : UIElement = null ## Combo counter [UIElement] instance
var bonus_arrow : UIElement = null ## Bonus arrow [UIElement] instance

var time_timer : Timer = null ## Timer which counts current play **'time'**


func _ready() -> void:
	name = "PlaylistMode"
	gamemode_name = "playlist_mode"

	Console.command_entered.connect(_execute_console_command)

	ruleset._copy(Player.config.user_ruleset)

	game.pause_screen_name = "sandbox_pause"
	game.game_over_screen_name = "playlist_mode_gameover"
	game.menu_screen_to_return_name = menu_screen_to_return

	if game.is_playing_replay: 
		game.pause_screen_name = "general_pause"
		game.game_over_screen_name = "demo_gameover"
		game.menu_screen_to_return_name = "main_menu"

	game.timeline_started.connect(_connect_timeline)
	game.skin_change_ended.connect(_connect_skin)
	game.new_piece_is_given.connect(_connect_piece)

	_load_ui()

	ruleset.changed.connect(_sync_settings)
	_sync_settings()

	time_timer = Timer.new()
	time_timer.timeout.connect(_update_time)
	time_timer.one_shot = false
	add_child(time_timer) 


## Connects new timeline to this gamemode signals
func _connect_timeline() -> void:
	game.timeline.finished.connect(_check_4x_bonus)
	game.timeline.squares_deleted.connect(_on_squares_erased)
	game.timeline.blocks_deleted.connect(_on_blocks_erased)


## Connects new given piece to this gamemode signals
func _connect_piece() -> void:
	holder._connect_piece(game.piece)


## Connects new skin to this gamemode signals
func _connect_skin() -> void:
	game.skin.playback_state_changed.connect(grid._update_loop_mark)
	game.skin.sample_ended.connect(grid._on_skin_sample_ended.bind(game.skin.bpm))
	
	if ruleset.rules["classic_scoring"] : bpm_multiplyer = 1.0
	else : bpm_multiplyer = snapped((game.skin.bpm / 120.0) * (game.skin.bpm / 120.0), 0.05)
	
	if ruleset.params["force_bpm"] > 0 : game.skin.forced_bpm = ruleset.params["force_bpm"]


## Syncs game rules settings with current profile config
func _sync_settings() -> void:
	max_combo = int(ruleset.rules["max_combo"])

	levels_per_skin = int(ruleset.params["level_count"])
	next_level_requirement = int(ruleset.params["level_up_speed"])
	left_before_level_up = next_level_requirement
	
	progress_bar._change_progress(0.0)
	
	if game.skin != null:
		if ruleset.rules["classic_scoring"] : bpm_multiplyer = 1.0
		else : bpm_multiplyer = snapped((game.skin.bpm / 120.0) * (game.skin.bpm / 120.0), 0.05)
	
	if not ruleset.rules["combo_system"] : combo_counter._set_combo(-42) 
	
	if ruleset.params["seed"] > 0 and not game.is_playing_replay:
		rng_start_seed = ruleset.params["seed"]


## Initiates all needed for this gamemode [UIElements]
func _load_ui() -> void:
	foreground._reset()

	grid = foreground._add_ui_element("grid")
	game.piece_queue.piece_swap.connect(grid._swap)
	game.paused.connect(grid._on_pause)
	
	scoreboard = foreground._add_ui_element("scoreboard")
	scoreboard._enable_counter("level")
	scoreboard._enable_counter("time")
	scoreboard._enable_counter("score")
	scoreboard._enable_counter("deleted")

	progress_bar = foreground._add_ui_element("progress")
	holder = foreground._add_ui_element("holder")
	bonus_arrow = foreground._add_ui_element("bonus")
	combo_counter = foreground._add_ui_element("combo")

	if game.is_playing_replay : foreground._add_ui_element("replay_ui")


## Called on game reset before **_reset()** function and game objects clean up [br]
## Resets all scores
func _soft_reset() -> void:
	score = 0
	deleted_squares = 0
	combo = 0
	time = 0
	
	scoreboard._set_value(0,"time")
	scoreboard._set_value(0,"score")
	scoreboard._set_value(0,"deleted_squares")
	
	combo_counter._set_combo(-42)
	bonus_arrow._reset()
	
	if rng_start_seed > 0 : game.rng.seed = rng_start_seed
	else : game.rng.seed = randi()


## Called on game reset [br]
## Resets current playlist back to the beginning and loads first skin
func _reset() -> int:
	level = 1

	if current_playlist == null or current_playlist.skins_ids.is_empty():
		error_text = "Empty playlist"
		return PLAYLIST_MODE_ERROR.PLAYLIST_EMPTY

	var color_check : bool = false
	for color : String in ["red","white","green","purple"]:
		if ruleset.blocks[color] : color_check = true
	
	if not color_check:
		error_text = "No block colors are enabled!"
		return PLAYLIST_MODE_ERROR.PLAYLIST_EMPTY

	if not is_single_skin_mode or game.skin == null:
		playlist_pos = 0

		var skin_change_result : int = await _change_skin(0, true)
		if skin_change_result > 1:
			error_text = "Failed to load first skin in playlist"
			return skin_change_result

		main._toggle_loading(false)
		await get_tree().create_timer(0.5).timeout

	current_lap = 0 if is_single_run else 1
	if is_single_skin_mode : current_lap = -1
	scoreboard._set_value([1,1,current_lap],"level")

	time_timer.start(1.0)
	game.piece_queue._reset()
	game._give_new_piece()
	game.skin._start()
	
	return OK


## Changes current skin to the some position in current playlist. Returns true on success
## If **'quick'** is true, loads skin momentally
func _change_skin(position : int, quick : bool = false) -> int:
	if position > current_playlist.skins_ids.size() - 1 : return PLAYLIST_MODE_ERROR.PLAYLIST_END

	var skin_metadata : SkinMetadata = current_playlist._get_skin_metadata_in_position(playlist_pos)
	if skin_metadata == null : return PLAYLIST_MODE_ERROR.INVALID_SKIN_DATA

	var change_skin_result : int = await game._change_skin(skin_metadata, quick)
	match change_skin_result:
		GameCore.SKIN_CHANGE_ERROR.OK : 
			return OK
		GameCore.SKIN_CHANGE_ERROR.BUSY:
			return PLAYLIST_MODE_ERROR.SKIN_CHANGE_IS_BUSY
		_:
			return PLAYLIST_MODE_ERROR.SKIN_CHANGE_FAILED


## Called on game pause
func _pause(on : bool) -> void:
	time_timer.paused = on


## Called on game over
func _game_over() -> void:
	if game.is_playing_replay : return

	#game.replay.gamemode_settings["score"] = str(score)
	#game.replay.gamemode_settings["time"] = Main._to_time(time)
	#game.replay.inputs_anim.length = time + 1


## Called on game exit
func _end() -> void:
	Player._save_profile()


## Called on each time timer tick
func _update_time() -> void:
	time += 1
	scoreboard._set_value(Main._to_time(time),"time")

	Player.savedata.stats["total_play_time"] += 1
	Player.savedata._set_stats_top("top_time_spent_in_gameplay", time)


## Increases value smoothly for score and deleted squares/blocks count
func _increase_score_value(add : int, which : int) -> void:
	if add == 0 : return

	match which:
		SCORE_ADDITION_TYPE.SCORE: 
			score += add
			create_tween().tween_method(scoreboard._set_value.bind("score"), score - add, score, COUNTER_GROW_SPEED)
			Player.savedata.stats["total_score"] += add
			Player.savedata._set_stats_top("top_score_gain", add)

		SCORE_ADDITION_TYPE.DELETED_SQUARES:
			deleted_squares += add
			create_tween().tween_method(scoreboard._set_value.bind("deleted_squares"), deleted_squares - add, deleted_squares, COUNTER_GROW_SPEED)
			Player.savedata.stats["total_squares_erased"] += add
			Player.savedata._set_stats_top("top_square_group_erased", add)


## Sets current combo which multiplyes all incoming score
func _set_combo(amount : int) -> void:
	combo = amount
	combo_counter._set_combo(combo)


## Adds progress to current level
func _add_level_progress(progress : int) -> void:
	left_before_level_up -= progress
	if left_before_level_up < 0: _level_up()
	
	progress_bar._change_progress(1.0 - float(left_before_level_up) / float(next_level_requirement))


## Sets playlist position. Doesn't change current skin
func _set_playlist_position(pos : int) -> void:
	playlist_pos = pos
	scoreboard._set_value([playlist_pos, level, current_lap], "level")


## Sets current level, which affects current game difficulty
func _set_level(new_level : int) -> void:
	level = new_level
	left_before_level_up = next_level_requirement

	scoreboard._set_value([playlist_pos, level, current_lap], "level")
	progress_bar._level_up()

	var fall_speed : float = game.piece_fall_delay
	var fall_delay : float = game.piece_fall_start_delay
	var difficulty_factor : float = ruleset.params["difficulty_factor"]

	if fall_speed > 0.5: fall_speed -= 0.05 * difficulty_factor
	elif fall_speed > 0.25: fall_speed -= 0.025 * difficulty_factor
	elif fall_speed > 0.1: fall_speed -= 0.01 * difficulty_factor
	elif fall_speed > 0.05: fall_speed -= 0.005 * difficulty_factor
	elif fall_speed > 0.01: fall_speed -= 0.0025 * difficulty_factor
	elif fall_speed <= 0: fall_speed = 0
	
	if fall_delay > 1.0: fall_delay -= 0.05 * difficulty_factor
	elif fall_delay > 0.5: fall_delay -= 0.001 * difficulty_factor
	elif fall_delay > 0.25: fall_delay -= 0.0005 * difficulty_factor
	elif fall_delay > 0.1: fall_delay -= 0.00025 * difficulty_factor
	elif fall_delay <= 0.1: fall_delay = 0.1

	game.piece_fall_delay = fall_speed
	game.piece_fall_start_delay = fall_delay


## Raises game onto next level
func _level_up() -> void:
	game._add_sound("level_up", Vector2(960,540))
	_set_level(level + 1)
	
	if not is_single_skin_mode and level % levels_per_skin == 0:
		_next_skin()
	else:
		scoreboard._play_animation("levelup")


## Changes current skin in playlist to the next one [br]
## If playlist ends, loops back to the first skin or ends the game if **'is_single_run'** true
func _next_skin() -> void:
	scoreboard._play_animation("nextskin")
	_set_playlist_position(playlist_pos + 1)

	var is_end_of_playlist : bool = playlist_pos > current_playlist.skins_ids.size() - 1
	if is_end_of_playlist:
		if is_single_run:
			await game.timeline_started
			game._game_over()
			return
		else:
			current_lap += 1
			_set_playlist_position(0)
	
	_change_skin(playlist_pos)


## Called when blocks are erased by timeline [br]
## Counts total deleted blocks count
func _on_blocks_erased(deleted_blocks_count : int) -> void:
	if deleted_blocks_count == 0 : return

	_check_for_special_bonus(deleted_blocks_count)


## Called when squares are erased by timeline [br]
## Counts total deleted squares count + adds score and level progress depending on deleted squares count
func _on_squares_erased(deleted_squares_count : int) -> void:
	if deleted_squares_count == 0 : return
	_increase_score_value(deleted_squares_count, SCORE_ADDITION_TYPE.DELETED_SQUARES)
	
	_add_level_progress(deleted_squares_count)
	
	if not ruleset.rules["give_score_for_square"]: return

	var result_score : int = 0
	if ruleset.rules["classic_scoring"] :
		result_score = 40 * deleted_squares_count * clamp(combo, 1, max_combo) as int
	else:
		if deleted_squares_count > 31: result_score = 32 * 10 * deleted_squares_count * clamp(combo, 1, max_combo) as int
		elif deleted_squares_count > 15: result_score = 16 * 10 * deleted_squares_count * clamp(combo, 1, max_combo) as int
		elif deleted_squares_count > 3: result_score = 4 * 10 * deleted_squares_count * clamp(combo, 1, max_combo) as int
		elif deleted_squares_count > 0: result_score = 10 * deleted_squares_count * clamp(combo, 1, max_combo) as int
	
	var fx_pos : Vector2
	fx_pos.x = (game.timeline.last_scanned_square_pos.x + 1) * LuminextGame.CELL_SIZE + LuminextGame.FIELD_X_OFFSET
	fx_pos.y = (game.timeline.last_scanned_square_pos.y + 1) * LuminextGame.CELL_SIZE + LuminextGame.FIELD_Y_OFFSET

	game._add_fx("scorenum", fx_pos, [result_score, deleted_squares_count, clamp(combo, 0, max_combo)])
	_increase_score_value(result_score, SCORE_ADDITION_TYPE.SCORE)


## Checks total erased by timeline square count for 4X bonus
func _check_4x_bonus(deleted_squares_count : int = -1) -> void:
	if deleted_squares_count < 0:
		deleted_squares_count = game.timeline.total_deleted_squares_count
	
	Player.savedata._set_stats_top("top_square_per_sweep", deleted_squares_count)
	
	if not ruleset.rules["give_score_for_square"]:
		_add_level_progress(deleted_squares_count)

	if ruleset.rules["combo_system"]:
		if deleted_squares_count > 3 : 
			_set_combo(combo + 1)
			Player.savedata._set_stats_top("top_combo", combo)
		else : _set_combo(0)

	if deleted_squares_count > 3:
		Player.savedata.stats["total_4x_bonuses"] += 1
		_4x_bonus(deleted_squares_count)


## Triggers 4X bonus
func _4x_bonus(deleted_squares_count : int = -1) -> void:
	if Player.config.audio["sequential_sounds"]: 
		game._add_sound("bonus",Vector2(960,540),false,false,combo - 1)
	else: 
		game._add_sound("bonus",Vector2(960,540))

	var result_score : int 
	if ruleset.rules["classic_scoring"] : 
		result_score = 160 * deleted_squares_count * clamp(combo, 1, max_combo) as int
	else : 
		result_score = 100 * deleted_squares_count * clamp(combo, 1, max_combo) as int
	
	_increase_score_value(result_score, SCORE_ADDITION_TYPE.SCORE)

	bonus_arrow._bonus(combo, deleted_squares_count, result_score)
	game.skin._bonus(combo)


## Checks game field for any special bonuses
func _check_for_special_bonus(deleted_blocks_count : int) -> void:
	# Check for all clear bonus
	if game.blocks.is_empty():
		Player.savedata.stats["total_all_clears"] += 1
		_all_clear_bonus(deleted_blocks_count)
	
	# Check for single color bonus
	var color : int = -1; 
	
	for block : Block in game.blocks.values():
		if color == -1 : 
			color = block.color
			continue
		if block.color != color : return

	Player.savedata.stats["total_single_color_bonuses"] += 1
	_single_color_bonus(deleted_blocks_count)


## Triggers all clear special bonus
func _all_clear_bonus(deleted_blocks_count : int) -> void:
	var increase_amount : int
	if ruleset.rules["classic_scoring"]:
		increase_amount = 10000
		game._add_fx("special_message", Vector2(0,0), "ALL CLEAR BONUS : " + " : 10000 " + tr("PTS"))
	else:
		increase_amount = 12000 + 2000 * deleted_blocks_count * clamp(combo, 1, max_combo)
		game._add_fx("special_message", Vector2(0,0), "ALL CLEAR BONUS : " + " " + str(deleted_blocks_count) + " ™ : " + str(increase_amount) + " " + tr("PTS"))
	
	game._add_sound("special_bonus",Vector2(960,540))
	_increase_score_value(increase_amount, SCORE_ADDITION_TYPE.SCORE)


## Triggers single color special bonus
func _single_color_bonus(deleted_blocks_count : int) -> void:
	var increase_amount : int

	if ruleset.rules["classic_scoring"]:
		increase_amount = 1000
		game._add_fx("special_message", Vector2(0,0), "SINGLE COLOR BONUS : " + " : 1000 " + tr("PTS"))
		
	else:
		increase_amount = 2100 + 100 * deleted_blocks_count * clamp(combo, 1, max_combo)
		game._add_fx("special_message", Vector2(0,0), "SINGLE COLOR BONUS : " + " " + str(deleted_blocks_count) + " ™ : " + str(increase_amount) + " " + tr("PTS"))

	game._add_sound("special_bonus",Vector2(960,540))
	_increase_score_value(increase_amount, SCORE_ADDITION_TYPE.SCORE)


## Executes entered into Console command
func _execute_console_command(command : String, arguments : PackedStringArray) -> void:
	match command:
		# Prints current gamemode info
		"ginfo" : 
			Console._output("Playlist mode info")
			Console._output("WIP")

		# Prints all skins in playlist
		"playlist" :
			Console._output("Playlist name : " + current_playlist.name)
			Console._output("Playlist contents :")
			for i : int in current_playlist.skins_ids.size():
				var metadata : SkinMetadata = current_playlist._get_skin_metadata_in_position(0)
				if metadata == null: Console._output("Error! Invalid skin in position : " + str(i))
				Console._output(str(i) + " : " + metadata.name + " (" + metadata.album + " | " + str(metadata.number) + ") [" + str(metadata.id) + "] {" + metadata.metadata_hash + "}")
		
		# Loads next skin in playlist
		"nextskn" :
			if is_single_skin_mode : Console._output("Error! Game is currently in single skin mode. No playlist avaiable")
			_next_skin()
		
		# Loads skin from specified playlist position
		"selskn" :
			if arguments.size() < 1: Console._output("Error! Playlist position number is not entered"); return
			if is_single_skin_mode : Console._output("Error! Game is currently in single skin mode. No playlist avaiable")

			var pos : int = int(arguments[0])
			if pos > current_playlist.skins_ids.size() - 1 : 
				Console._output("Error! Entered number exceeds playlist size. Current playlist size is : " + str(current_playlist.skins_ids.size()))
				return

			_set_playlist_position(pos)
			_change_skin(pos)
		
		# Changes current playlist position
		"playpos" :
			if arguments.size() < 1: Console._output("Error! Playlist position number is not entered"); return
			if is_single_skin_mode : Console._output("Error! Game is currently in single skin mode. No playlist avaiable")

			var pos : int = int(arguments[0])
			if pos > current_playlist.skins_ids.size() - 1 : 
				Console._output("Error! Entered number exceeds playlist size. Current playlist size is : " + str(current_playlist.skins_ids.size()))
				return
			
			_set_playlist_position(pos)
		
		# Adds progress to the level bar
		"lvladd" :
			if arguments.size() < 1: Console._output("Error! Progress amount number is not entered"); return
			_add_level_progress(int(arguments[0]))
		
		# Sets current level to specified one
		"lvlset" :
			if arguments.size() < 1: Console._output("Error! Level number is not entered"); return
			_set_level(int(arguments[0]))
		
		# Triggers level up!
		"lvlup" :
			_level_up()
		
		# Adds score depending on entered square amount
		"sqradd" :
			if arguments.size() < 1: Console._output("Error! Square amount number is not entered"); return
			_on_squares_erased(int(arguments[0]))
		
		# Triggers specified bonus
		"bonus" :
			if arguments.size() < 1: Console._output("Error! Bonus type name is not entered"); return
			if arguments.size() < 2: Console._output("Error! Bonus value is not entered"); return
			
			match arguments[0]:
				"4x" : game.gamemode._4x_bonus(int(arguments[1]))
				"onecol" : game.gamemode._single_color_bonus(int(arguments[1]))
				"allclr" : game.gamemode._all_clear_bonus(int(arguments[1]))
				_: Console._output("Error! Invalid bonus type name. Try entering '4x', 'onecol', 'allclr' instead"); return
		
		# Sets specified score value
		"scoreset" :
			if arguments.size() < 1: Console._output("Error! Score type name is not entered"); return
			if arguments.size() < 2: Console._output("Error! Score value is not entered"); return
			
			var value : int = int(arguments[1])

			match arguments[0]:
				"time" : 
					time = value
					scoreboard._set_value(time, "time")
				"score" : 
					score = value
					scoreboard._set_value(score, "score")
				"delsqr" : 
					deleted_squares = value
					scoreboard._set_value(score, "deleted_squares")
				_: 
					Console._output("Error! Invalid score type name"); return

		# Changes specified score value
		"scoreadd" :
			if arguments.size() < 1: Console._output("Error! Score type name is not entered"); return
			if arguments.size() < 2: Console._output("Error! Score value is not entered"); return
			
			var value : int = int(arguments[1])

			match arguments[0]:
				"time" : time += value
				"score" : _increase_score_value(value,SCORE_ADDITION_TYPE.SCORE)
				"delsqr" : _increase_score_value(value,SCORE_ADDITION_TYPE.DELETED_SQUARES)
				_: Console._output("Error! Invalid score type name"); return
