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


extends Gamemode

class_name PlaylistMode

#-----------------------------------------------------------------------
# Playlist mode gamemode script
# 
# Features standard luminext game with skins playlist playing through.
# Single skin mode is also supported here.
#-----------------------------------------------------------------------

enum SCORE_ADDITION_TYPE {SCORE, DELETED_SQUARES, DELETED_BLOCKS}

const COUNTER_GROW_SPEED : float = 0.75 # How fast scoreboard counters would change their number

var is_single_run : bool = false # If true, do gameover after playlist end
var is_single_skin_mode : bool = false # Makes current skin play infinitely, even if playlist exists
var is_playtest_mode : bool = false # Is this gamemode used for skin editor or addon editor playtest

var current_playlist : SkinPlaylist = null
var playlist_pos : int = 0 # Current position in skin playlist
var current_lap : int = 0 # Current amount of loops in skin playlist

var menu_screen_to_return : String = "playlist_mode"

var custom_config_preset : GameConfigPreset = null
var config_backup : GameConfigPreset = null

var time : int = 0 
var score : int = 0 
var deleted_squares : int = 0 # Total deleted squares count
var deleted_blocks : int = 0 # Total deleted blocks count
var combo : int = 0 # Counts how many 4X bonuses were in row
var max_combo : int = 32 # Max combo which can multiply incoming score

var bpm_multiplyer : float = 1.0 # Multiplyer used to balance score gain with defferent BPMs (Formula : (BPM/120)^2) (For now unused)

var rng_start_seed : int = -1 # Seed which will be used by rng on game start
var used_rng_seed : int = -1  # Currently used rng seed value

var level_count : int = 1 
var max_level_count : int = 4
var left_before_level_up : int = 0 # Current amount of squares required to delete before level up
var next_level_req : int = 20 # Absolute amount of squares required to delete before level up

var scoreboard : UIElement = null
var time_timer : Timer = null


func _ready() -> void:
	name = "PlaylistMode"
	gamemode_name = "playlist_mode"

	game.pause_screen_name = "sandbox_pause"
	game.game_over_screen_name = "playlist_mode_gameover"
	game.menu_screen_to_return = menu_screen_to_return

	if game.is_playing_replay: 
		game.pause_screen_name = "general_pause"
		game.game_over_screen_name = "demo_gameover"
		game.menu_screen_to_return = "main_menu"

	game.timeline_started.connect(_connect_timeline)
	
	_load_ui()

	if custom_config_preset != null:
		config_backup = GameConfigPreset.new()
		config_backup._store_current_config()
		custom_config_preset._apply_preset()

	Data.profile.gameplay_config_changed.connect(_sync_settings)

	time_timer = Timer.new()
	time_timer.timeout.connect(_update_time)
	time_timer.one_shot = false
	add_child(time_timer)
	time_timer.start(1.0)


# Updates gamemode settings and variables to match current profile config
func _sync_settings() -> void:
	max_combo = Data.profile.config["gameplay"]["max_combo"]
	max_level_count = int(Data.profile.config["gameplay"]["level_count"])
	
	next_level_req = Data.profile.config["gameplay"]["level_up_speed"]
	left_before_level_up = next_level_req
	game.foreground.ui_elements["progress"]._change_progress(0.0)

	if Data.profile.config["gameplay"]["classic_scoring"] : bpm_multiplyer = 1.0
	else : bpm_multiplyer = snapped((game.skin.bpm / 120.0) * (game.skin.bpm / 120.0), 0.05)

	if not Data.profile.config["gameplay"]["combo_system"] : game.foreground.ui_elements["combo"]._set_combo(-42) 
	
	if Data.profile.config["gameplay"]["seed"] > 0 and not game.is_playing_replay:
		rng_start_seed = Data.profile.config["gameplay"]["seed"]


func _prereset() -> void:
	level_count = 1
	score = 0
	deleted_squares = 0
	deleted_blocks = 0
	combo = 0
	time = 0

	if is_single_skin_mode : current_lap = -1
	elif is_single_run : current_lap = 0
	else : current_lap = 1
	
	scoreboard._set_value(0,"time")
	scoreboard._set_value([1,1,current_lap],"level")
	scoreboard._set_value(0,"score")
	scoreboard._set_value(0,"deleted_squares")
	scoreboard._set_value(0,"deleted_blocks")
	
	game.foreground.ui_elements["combo"]._set_combo(-42)
	game.foreground.ui_elements["bonus"]._reset()
	
	_sync_settings()
	
	if rng_start_seed > 0 : used_rng_seed = rng_start_seed
	else : used_rng_seed = randi()
	
	game.rng.seed = used_rng_seed


# Called on game reset
func _reset() -> void:
	time_timer.start(1.0)
	
	# Delay is needed so game can properly receive reset complete signal
	await get_tree().create_timer(0.01).timeout
	reset_complete.emit()


# Called on game pause
func _pause(on : bool) -> void:
	time_timer.paused = on


# Called on game over
func _game_over() -> void:
	if game.is_playing_replay : return
	var gameover_screen : MenuScreen = Data.menu.screens["playlist_mode_gameover"]
	gameover_screen._setup(self)

	game.replay.gamemode_settings["score"] = str(score)
	game.replay.gamemode_settings["time"] = Data._to_time(time)
	game.replay.inputs_anim.length = time + 1


func _end() -> void:
	if config_backup != null : config_backup._apply_preset()
	Data.profile._save_progress()


# Loads game ui
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
	if game.is_playing_replay : foreground._add_ui_element("replay_ui")
	
	foreground._change_style(game.skin.skin_data.textures["ui_design"], game.skin.skin_data, 0.0)


# Called on game retry. Returns to first skin in playlist and loads it
func _retry() -> void:
	if not current_playlist == null and not current_playlist.skins.is_empty() and not is_single_skin_mode:
		playlist_pos = 0
		var first_skin_path : String = current_playlist.skins[0][0]

		if not FileAccess.file_exists(first_skin_path): 
			print("SKIN CHANGE FAILED! FIRST SKIN IS MISSING")
			Data.main._display_system_message("ERROR! FIRST SKIN IS MISSING")
			retry_status = RETRY_STATUS.SKIN_MISSING
			retry_complete.emit()
			return

		Data.main._toggle_loading(true)
		game._change_skin(first_skin_path, true)
		await game.skin_change_ended
		Data.main._toggle_loading(false)
		
		if game.skin_change_status == game.SKIN_CHANGE_STATUS.FAILED:
			print("SKIN CHANGE FAILED! LOADING ERROR")
			Data.main._display_system_message("ERROR! SKIN CHANGE FAILED")
			retry_status = RETRY_STATUS.FAILED
			retry_complete.emit()
			return
	
	await get_tree().create_timer(0.01).timeout
	_reset()
	retry_complete.emit()


# Starts skin change sequence and loads next skin
func _next_skin() -> void:
	if is_single_skin_mode or current_playlist == null:
		return
	
	_set_playlist_position(playlist_pos + 1)

	var is_playlist_ended : bool = playlist_pos > current_playlist.skins.size() - 1

	if is_playlist_ended:
		if is_single_run:
			await game.timeline_started
			game._game_over()
			return
		else:
			playlist_pos = 0
			current_lap += 1
	
	var metadata : SkinMetadata = Data.skin_list._get_skin_metadata_by_hash(Data.playlist.skins[playlist_pos][1])
	if metadata == null: return
	
	game._change_skin(metadata.path)


# Connects new timeline to this gamemode signals
func _connect_timeline() -> void:
	game.timeline.finished.connect(_check_bonus)
	game.timeline.blocks_deleted.connect(_check_for_special_bonus)

	if Data.profile.config["gameplay"]["give_score_for_square"]:
		game.timeline.squares_deleted.connect(_add_score_by_squares)
		game.timeline.blocks_deleted.connect(_add_score_by_blocks)


# Called on each time timer tick
func _update_time() -> void:
	time += 1
	scoreboard._set_value(Data._to_time(time),"time")
	Data.profile.progress["stats"]["total_play_time"] += 1
	
	if time > Data.profile.progress["stats"]["top_time_spent_in_gameplay"]:
		Data.profile.progress["stats"]["top_time_spent_in_gameplay"] = time


# Checks game field for any special bonuses (single color, all clear)
func _check_for_special_bonus(deleted_blocks_count : int, force_all_clear : bool = false) -> void:
	# All clear bonus
	if game.blocks.is_empty() or force_all_clear:
		var increase_amount : int

		if Data.profile.config["gameplay"]["classic_scoring"]:
			increase_amount = 10000
			game._add_fx("special_message", Vector2(0,0), "ALL CLEAR BONUS : " + " : 10000 " + tr("PTS"))
			Data.profile.progress["stats"]["total_all_clears"] += 1
		else:
			increase_amount = 12000 + 2000 * deleted_blocks_count * clamp(combo, 1, max_combo)
			game._add_fx("special_message", Vector2(0,0), "ALL CLEAR BONUS : " + " " + str(deleted_blocks_count) + " ™ : " + str(increase_amount) + " " + tr("PTS"))
			Data.profile.progress["stats"]["total_all_clears"] += 1
		
		game._add_sound("special_bonus",Vector2(960,540))
		_increase_score_value(increase_amount, SCORE_ADDITION_TYPE.SCORE)
		return
	
	# Single color bonus
	var color : int = BlockBase.BLOCK_COLOR.NULL; 
	
	for block : Block in game.blocks.values():
		if color == BlockBase.BLOCK_COLOR.NULL: 
			color = block.color
			continue
		if block.color != color:
			color = 42
			break
		color = block.color

	if color != 42: 
		var increase_amount : int

		if Data.profile.config["gameplay"]["classic_scoring"]:
			increase_amount = 1000
			game._add_fx("special_message", Vector2(0,0), "SINGLE COLOR BONUS : " + " : 1000 " + tr("PTS"))
			Data.profile.progress["stats"]["total_single_color_bonuses"] += 1
		else:
			increase_amount = 2100 + 100 * deleted_blocks_count * clamp(combo, 1, max_combo)
			game._add_fx("special_message", Vector2(0,0), "SINGLE COLOR BONUS : " + " " + str(deleted_blocks_count) + " ™ : " + str(increase_amount) + " " + tr("PTS"))
			Data.profile.progress["stats"]["total_single_color_bonuses"] += 1
		
		game._add_sound("special_bonus",Vector2(960,540))
		_increase_score_value(increase_amount, SCORE_ADDITION_TYPE.SCORE)


# Adds score by blocks erased
func _add_score_by_blocks(deleted_blocks_count : int) -> void:
	if deleted_blocks_count == 0 : return
	
	_increase_score_value(deleted_blocks_count, SCORE_ADDITION_TYPE.DELETED_BLOCKS)


# Adds score by squares erased
func _add_score_by_squares(deleted_squares_count : int) -> void:
	if deleted_squares_count == 0 : return

	_increase_score_value(deleted_squares_count, SCORE_ADDITION_TYPE.DELETED_SQUARES)
	
	_add_level_progress(deleted_squares_count)
	
	var result_score : int = 0
	if Data.profile.config["gameplay"]["classic_scoring"] :
		result_score = 40 * deleted_squares_count * clamp(combo, 1, max_combo) as int
	else:
		if deleted_squares_count > 31: result_score = 32 * 10 * deleted_squares_count * clamp(combo, 1, max_combo) as int
		elif deleted_squares_count > 15: result_score = 16 * 10 * deleted_squares_count * clamp(combo, 1, max_combo) as int
		elif deleted_squares_count > 3: result_score = 4 * 10 * deleted_squares_count * clamp(combo, 1, max_combo) as int
		elif deleted_squares_count > 0: result_score = 10 * deleted_squares_count * clamp(combo, 1, max_combo) as int
	
	game._add_fx("scorenum", game.timeline.last_scanned_square_pos, [result_score, deleted_squares_count, clamp(combo, 0, max_combo)])
	_increase_score_value(result_score, SCORE_ADDITION_TYPE.SCORE)


func _add_level_progress(progress : int) -> void:
	left_before_level_up -= progress
	if left_before_level_up < 0: _level_up()
	
	game.foreground.ui_elements["progress"]._change_progress(1.0 - float(left_before_level_up) / float(next_level_req))


func _set_level(level : int) -> void:
	level_count = level
	scoreboard._set_value([playlist_pos, level_count, current_lap], "level")


func _set_playlist_position(pos : int) -> void:
	playlist_pos = pos
	scoreboard._set_value([pos, level_count, current_lap], "level")


# Called on each timeline pass. Checks if >4 squares was erased so 4x bonus could be triggered.
func _check_bonus(deleted_squares_count : int = -1) -> void:
	if deleted_squares_count < 0:
		deleted_squares_count = game.timeline.total_deleted_squares_count
	
	if deleted_squares_count > Data.profile.progress["stats"]["top_square_per_sweep"]:
		Data.profile.progress["stats"]["top_square_per_sweep"] = deleted_squares_count
	
	if not Data.profile.config["gameplay"]["give_score_for_square"]:
		_add_level_progress(deleted_squares_count)

	if Data.profile.config["gameplay"]["combo_system"]:
		if deleted_squares_count < 4: combo = 0
		else: 
			combo += 1
			if combo > Data.profile.progress["stats"]["top_combo"]:
				Data.profile.progress["stats"]["top_combo"] = combo
		
		game.foreground.ui_elements["combo"]._set_combo(combo)

	if deleted_squares_count > 3:
		if Data.profile.config["audio"]["sequential_sounds"]: game._add_sound("bonus",Vector2(960,540),false,false,combo - 1)
		else: game._add_sound("bonus",Vector2(960,540))

		var result_score : int 
		if Data.profile.config["gameplay"]["classic_scoring"] : result_score = 160 * deleted_squares_count * clamp(combo, 1, max_combo) as int
		else : result_score = 100 * deleted_squares_count * clamp(combo, 1, max_combo) as int
		
		_increase_score_value(result_score, SCORE_ADDITION_TYPE.SCORE)
		
		Data.profile.progress["stats"]["total_4x_bonuses"] += 1

		game.foreground.ui_elements["bonus"]._bonus(combo, deleted_squares_count, result_score)
		game.skin._bonus(combo)


# Raises game onto next level, increasing piece falling speed
func _level_up() -> void:
	game._add_sound("level_up", Vector2(960,540))
	
	level_count += 1
	left_before_level_up = next_level_req
	
	var fall_speed : float = game.piece_fall_speed
	var fall_delay : float = game.piece_fall_delay
	var difficulty_factor : float = Data.profile.config["gameplay"]["difficulty_factor"]

	# Increase game speed
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

	game.piece_fall_speed = fall_speed
	game.piece_fall_delay = fall_delay

	scoreboard._set_value([playlist_pos + 1, level_count, current_lap], "level")
	
	if not is_single_skin_mode and level_count % max_level_count == 0:
		game.foreground.ui_elements["progress"]._level_up()
		scoreboard._play_animation("nextskin")
		_next_skin()
	else:
		game.foreground.ui_elements["progress"]._level_up()
		scoreboard._play_animation("levelup")


# Does smooth value increase. Only "score" and "deleted" values increase is supported
func _increase_score_value(add : int, which : int) -> void:
	if add == 0: return

	match which:
		SCORE_ADDITION_TYPE.SCORE : 
			score += add
			create_tween().tween_method(scoreboard._set_value.bind("score"), score - add, score, COUNTER_GROW_SPEED)
			Data.profile.progress["stats"]["total_score"] += add
			
			if add > Data.profile.progress["stats"]["top_score_gain"]:
				Data.profile.progress["stats"]["top_score_gain"] = add

		SCORE_ADDITION_TYPE.DELETED_SQUARES :
			deleted_squares += add
			create_tween().tween_method(scoreboard._set_value.bind("deleted_squares"), deleted_squares - add, deleted_squares, COUNTER_GROW_SPEED)
			Data.profile.progress["stats"]["total_squares_erased"] += add

			if add > Data.profile.progress["stats"]["top_square_group_erased"]:
				Data.profile.progress["stats"]["top_square_group_erased"] = add
		
		SCORE_ADDITION_TYPE.DELETED_BLOCKS :
			deleted_blocks += add
			create_tween().tween_method(scoreboard._set_value.bind("deleted_blocks"), deleted_blocks - add, deleted_blocks, COUNTER_GROW_SPEED)
			Data.profile.progress["stats"]["total_blocks_erased"] += add
