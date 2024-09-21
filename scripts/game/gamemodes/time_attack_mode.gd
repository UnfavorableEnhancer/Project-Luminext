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

class_name TimeAttackMode

#-----------------------------------------------------------------------
# Time attack mode gamemode script
# 
# Time attack mode features several time limits in which player must get as much
# score as possible
#-----------------------------------------------------------------------

enum TIME_ATTACK_RULESET {STANDARD, CLASSIC, ARCADE, COLOR_3, HARDCORE}

var time_limit : int = 0
var ruleset : int = TIME_ATTACK_RULESET.STANDARD
var random_mixes : bool = false # Allows this gamemode to change skin animation and music mix on each retry
var current_mix : int = -1

var time_attack_timer : Timer
var stat_timer : Timer
var stat_disable_timer : Timer
var time_attack_ui : UIElement

var config_backup : GameConfigPreset

var statistics : Dictionary = {
	"square_cumulative" : [],
	"square_per_sweep" : [], 
	"pieces_used_count" : [], 
	"attempt_scores" : [],
}

var current_attempt : int = 0
var current_seed : int = 451
var rng_start_state : int = 0

var replay : Replay = null
var replay_mode : bool = false

var hiscore_entry_string : String

var is_counting_time : bool = false
var is_game_over : bool = false
var is_first_run : bool = true

var score : int = 0 
var hiscore : int = 0 
var old_hiscore : int = 0
var current_sqr_count : int = 0


func _ready() -> void:
	name = "TimeAttackMode"
	gamemode_name = "time_attack_mode"
	
	game.pause_screen_name = "general_pause"
	game.game_over_screen_name = "timeattack_mode_gameover"
	game.menu_screen_to_return = "time_attack_mode"

	game.timeline_started.connect(_connect_timeline)
	game.new_piece_is_given.connect(_count_pieces)

	config_backup = GameConfigPreset.new()
	config_backup._store_current_config()

	var ruleset_string : String = ""
	match ruleset:
		TIME_ATTACK_RULESET.STANDARD: ruleset_string = "_standard" 
		TIME_ATTACK_RULESET.CLASSIC: ruleset_string = "_classic" 
		TIME_ATTACK_RULESET.ARCADE: ruleset_string = "_arcade" 
		TIME_ATTACK_RULESET.COLOR_3: ruleset_string = "_3color" 
		TIME_ATTACK_RULESET.HARDCORE: ruleset_string = "_hardcore" 
	
	hiscore_entry_string = str(time_limit) + "sec" + ruleset_string
	if Data.profile.progress["time_attack_hiscore"].has(hiscore_entry_string): 
		hiscore = Data.profile.progress["time_attack_hiscore"][hiscore_entry_string] 
		old_hiscore = hiscore

	_load_ruleset()

	stat_timer = Timer.new()
	stat_timer.timeout.connect(_count_squares)
	stat_timer.one_shot = false
	add_child(stat_timer)

	stat_disable_timer = Timer.new()
	stat_disable_timer.timeout.connect(stat_timer.stop)
	stat_disable_timer.one_shot = true
	add_child(stat_disable_timer)

	time_attack_timer = Timer.new()
	time_attack_timer.timeout.connect(game._game_over)
	time_attack_timer.one_shot = true
	add_child(time_attack_timer)

	var time_timer : Timer = Timer.new()
	time_timer.timeout.connect(func() -> void: Data.profile.progress["stats"]["ta_total_time"] += 1; Data.profile.progress["stats"]["total_play_time"] += 1)
	time_timer.one_shot = false
	add_child(time_timer)
	time_timer.start(1.0)

	game.piece_fall_speed = Data.profile.config["gameplay"]["piece_fall_speed"]
	game.piece_fall_delay = Data.profile.config["gameplay"]["piece_fall_delay"]

	if replay != null : 
		game.game_over_screen_name = "demo_gameover"
		game.menu_screen_to_return = "main_menu"
		replay_mode = true
	else : 
		current_seed = randi()
	
	game.rng.seed = current_seed

	_load_ui()


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("debug_end_timer") : time_attack_timer.start(3.0)


func _reset() -> void:
	time_attack_ui._stop()
	time_attack_ui._set_time(float(time_limit))
	
	if not replay_mode:
		replay = Replay.new()
	add_child(replay)

	score = 0
	time_attack_ui._set_hiscore(hiscore)
	time_attack_ui._set_score(score)
	
	# Pause grid ui element so beat counter animation wont play until countdown sequence finishes
	var grid : UIElement = game.foreground.ui_elements["grid"]
	
	grid.process_mode = Node.PROCESS_MODE_DISABLED
	grid.get_node("Field/Beatcount").size.x = 0.0
	
	var gamerule_string : String
	match ruleset:
		TIME_ATTACK_RULESET.STANDARD: gamerule_string = "Standard"
		TIME_ATTACK_RULESET.CLASSIC: gamerule_string = "Classic"
		TIME_ATTACK_RULESET.ARCADE: gamerule_string = "Arcade"
		TIME_ATTACK_RULESET.COLOR_3: gamerule_string = "3 Color"
		TIME_ATTACK_RULESET.HARDCORE: gamerule_string = "Hardcore"

	if time_limit < 300:
		grid.get_node("name").text = "grandmother clock/W3Rn1ckz | " + str(time_limit) +  " sec | " + gamerule_string
	else:
		grid.get_node("name").text = "The Years Will Pass/W3Rn1ckz | " + str(time_limit) +  " sec | " + gamerule_string
	
	# Inject our own special music mixes with some randomization
	# First mix will always play on start of time attack grinding
	if time_limit in [60,120,180,300,600]:
		if random_mixes and Data.profile.progress["time_attack_hiscore"][hiscore_entry_string] > 0:
			var i : Array[int] = [1,2,3,4,5]
			if time_limit > 60 : i.pop_back()
			if time_limit > 120 : i.pop_back()
			if time_limit > 180 : i.pop_back()
			if time_limit > 300 : i.pop_back()
			# Exclude previously played mix
			if current_mix > 0 : i.remove_at(current_mix - 1)
			current_mix = i.pick_random()
		else:
			if current_mix == -1 : current_mix = 1
	
	game.skin.skin_data.stream["music"] = load("res://internal/music/" + str(time_limit) + "sec_ta_mix" + str(current_mix) + ".ogg")
	game.skin.scene_player.assigned_animation = str(time_limit) + "sec" + str(current_mix)
	game.skin.scene_player.play(str(time_limit) + "sec" + str(current_mix))
	await get_tree().create_timer(0.01).timeout
	game.skin.scene_player.pause()

	game.foreground.ui_elements["grid"].process_mode = Node.PROCESS_MODE_INHERIT
	
	if not is_game_over:
		statistics["square_cumulative"].pop_back()
		statistics["square_per_sweep"].pop_back()
		statistics["pieces_used_count"].pop_back()
	is_game_over = false
	
	statistics["square_cumulative"].append([])
	statistics["square_per_sweep"].append([])
	statistics["pieces_used_count"].append(0)
	
	current_sqr_count = 0
	
	current_attempt += 1

	time_attack_ui.get_node("Start/StartAnim").stop()
	if is_first_run:
		time_attack_ui.get_node("Start/StartAnim").play("start")
		await get_tree().create_timer(3.0).timeout
	else:
		time_attack_ui.get_node("Start/StartAnim").play("startfast")
		await get_tree().create_timer(1.0).timeout

	Data.profile.progress["stats"]["ta_total_retry_count"] += 1

	time_attack_timer.start(time_limit)
	stat_timer.start(4.0)
	stat_disable_timer.start(time_limit - 1.0)
	is_counting_time = true

	reset_complete.emit()
	time_attack_ui._start()

	if replay_mode : replay._start_playback()
	else : replay._start_recording()


# Connects new timeline to this gamemode signals
func _connect_timeline() -> void:
	game.timeline.squares_deleted.connect(_add_score_by_squares)


func _count_pieces() -> void:
	var pieces_used : Array = statistics["pieces_used_count"]
	if pieces_used.size() > 0:
		pieces_used[pieces_used.size() - 1] += 1


func _load_ruleset() -> void:
	var ruleset_preset : GameConfigPreset = GameConfigPreset.new()
	match ruleset:
		TIME_ATTACK_RULESET.STANDARD: ruleset_preset._load("res://internal/presets/standard.json")
		TIME_ATTACK_RULESET.CLASSIC: ruleset_preset._load("res://internal/presets/classic.json")
		TIME_ATTACK_RULESET.ARCADE: ruleset_preset._load("res://internal/presets/arcade.json")
		TIME_ATTACK_RULESET.COLOR_3: ruleset_preset._load("res://internal/presets/3color.json")
		TIME_ATTACK_RULESET.HARDCORE: ruleset_preset._load("res://internal/presets/hardcore.json")

	ruleset_preset._apply_preset()

	if ruleset == TIME_ATTACK_RULESET.STANDARD:
		Data.profile.config["gameplay"]["chain"] = false

	if ruleset != TIME_ATTACK_RULESET.COLOR_3:
		if time_limit == 120 or time_limit == 600:
			Data.profile.config["gameplay"]["red"] = false
			Data.profile.config["gameplay"]["green"] = true
		if time_limit == 180:
			Data.profile.config["gameplay"]["red"] = false
			Data.profile.config["gameplay"]["purple"] = true


func _load_ui() -> void:
	var foreground : Node2D = game.foreground
	foreground._reset()

	foreground._add_ui_element("grid")
	foreground._add_ui_element("holder")

	time_attack_ui = foreground._add_ui_element("time_attack")
	time_attack_ui._set_hiscore(hiscore)

	if replay_mode : foreground._add_ui_element("replay_ui")

	# Load holder arrow textures
	foreground.ui_elements["holder"]._change_style()


func _process(_delta : float) -> void:
	if is_counting_time and time_attack_ui != null: time_attack_ui._set_time(time_attack_timer.time_left)


func _pause(on : bool) -> void:
	if replay != null: replay._pause(on)
	time_attack_timer.paused = on
	stat_disable_timer.paused = on
	stat_timer.paused = on
	is_counting_time = !on


func _game_over() -> void:
	is_game_over = true
	
	if replay_mode : 
		replay._stop_playback()
		return
	else : 
		replay._stop_recording()

	var gameover_screen : MenuScreen = Data.menu.screens["timeattack_mode_gameover"]
	
	var square_cumulative : Array = statistics["square_cumulative"]
	var arrays_size : int = statistics["square_cumulative"].size()
	
	var square_per_sweep : Array = statistics["square_per_sweep"]
	
	if time_attack_timer.time_left > 0:
		gameover_screen.get_node("Top/Text").text = "TIME ATTACK FAILED!"

		gameover_screen.get_node("Results/Score").text = "DQ"
		gameover_screen.get_node("Results/Score").self_modulate = Color.RED

		statistics["square_cumulative"].pop_back()
		statistics["square_per_sweep"].pop_back()
		statistics["pieces_used_count"].pop_back()

		arrays_size -= 1

		if arrays_size == 0: 
			for i : int in range(1,7):
				gameover_screen.get_node("Results/Scores/" + str(i)).visible = false
				gameover_screen.get_node("Results/Medium/" + str(i)).visible = false
				gameover_screen.get_node("Results/Piece/" + str(i)).visible = false
	else:
		square_cumulative[arrays_size - 1].append(score)
		square_per_sweep[arrays_size - 1].append(current_sqr_count)
		statistics["attempt_scores"].append(score)

		if Data.global_settings.has(hiscore_entry_string + "_ranking"):
			Data.global_settings[hiscore_entry_string + "_ranking"].append([Data.profile.name, score, Time.get_unix_time_from_system()])

		gameover_screen.get_node("Results/Score").text = str(score)
	
	var value_max : int
	var results_array : Array = []
	var max_array : Array = []
	
	if arrays_size > 0: 
		results_array.append(square_cumulative[arrays_size - 1])
		max_array.append(square_cumulative[arrays_size - 1].max())
	if arrays_size > 1: 
		results_array.append(square_cumulative[arrays_size - 2])
		max_array.append(square_cumulative[arrays_size - 2].max())
	if arrays_size > 2: 
		results_array.append(square_cumulative[arrays_size - 3])
		max_array.append(square_cumulative[arrays_size - 3].max())
	if arrays_size > 3: 
		results_array.append(square_cumulative[arrays_size - 4])
		max_array.append(square_cumulative[arrays_size - 4].max())
	if arrays_size > 4: 
		results_array.append(square_cumulative[arrays_size - 5])
		max_array.append(square_cumulative[arrays_size - 5].max())
	if arrays_size > 5: 
		results_array.append(square_cumulative[arrays_size - 6])
		max_array.append(square_cumulative[arrays_size - 6].max())
	
	if arrays_size > 0: 
		value_max = max_array.max()
		var value_space : float = value_max / 4.0
		var time_space : float = time_limit / 4.0
		
		for i : int in arrays_size:
			if i > 5 : break
			gameover_screen.get_node("Stats/Cumulative/Graph" + str(i+1)).visible = true
			gameover_screen.get_node("Stats/Legend/" + str(i+1)).visible = true
			gameover_screen.get_node("Stats/Cumulative/Graph" + str(i+1)).points = _plot_graph(results_array[i], value_max)
		
		var value_mark : float = 0
		var time_mark : float = 0
		for i : int in 5:
			gameover_screen.get_node("Stats/Cumulative/N/" + str(i+1)).text = str(int(value_mark))
			gameover_screen.get_node("Stats/Cumulative/T/" + str(i+1)).text = str(int(time_mark))
			
			value_mark += value_space
			time_mark += time_space
		
		results_array.clear()
		max_array.clear()
		
		results_array.append(square_per_sweep[arrays_size - 1])
		max_array.append(square_per_sweep[arrays_size - 1].max())
		if arrays_size > 1: 
			results_array.append(square_per_sweep[arrays_size - 2])
			max_array.append(square_per_sweep[arrays_size - 2].max())
		if arrays_size > 2: 
			results_array.append(square_per_sweep[arrays_size - 3])
			max_array.append(square_per_sweep[arrays_size - 3].max())
		if arrays_size > 3: 
			results_array.append(square_per_sweep[arrays_size - 4])
			max_array.append(square_per_sweep[arrays_size - 4].max())
		if arrays_size > 4: 
			results_array.append(square_per_sweep[arrays_size - 5])
			max_array.append(square_per_sweep[arrays_size - 5].max())
		if arrays_size > 5: 
			results_array.append(square_per_sweep[arrays_size - 6])
			max_array.append(square_per_sweep[arrays_size - 6].max())
		
		value_max = max_array.max()
		value_space = value_max / 4.0
		
		for i : int in arrays_size:
			if i > 5 : break
			gameover_screen.get_node("Stats/Sweep/Graph" + str(i+1)).visible = true
			gameover_screen.get_node("Stats/Sweep/Graph" + str(i+1)).points = _plot_graph(results_array[i], value_max)
		
		value_mark = 0
		time_mark = 0
		
		for i : int in 5:
			gameover_screen.get_node("Stats/Sweep/N/" + str(i+1)).text = str(int(value_mark))
			gameover_screen.get_node("Stats/Sweep/T/" + str(i+1)).text = str(int(time_mark))
			
			value_mark += value_space
			time_mark += time_space
	
		var pieces_used : Array = statistics["pieces_used_count"]
		
		var value_sum : int = 0
		var y : int = 1
		for i : int in range(results_array.size() - 1, results_array.size() - 7, -1):
			value_sum = 0
			if i < 0:
				gameover_screen.get_node("Results/Scores/" + str(y)).visible = false
				gameover_screen.get_node("Results/Medium/" + str(y)).visible = false
				gameover_screen.get_node("Results/Piece/" + str(y)).visible = false
			else:
				for x : int in results_array[results_array.size() - i - 1] : value_sum += x
				gameover_screen.get_node("Results/Scores/" + str(y)).text = str(statistics["attempt_scores"][i])
				gameover_screen.get_node("Results/Medium/" + str(y)).text = str(snapped(value_sum / float(results_array[i].size()), 0.1))
				gameover_screen.get_node("Results/Piece/" + str(y)).text = str(pieces_used[i])
			y += 1
	
		value_sum = 0
		for x : int in statistics["attempt_scores"] : value_sum += x
	
		gameover_screen.get_node("Results/Average").text = str(round(value_sum / float(statistics["attempt_scores"].size())))

		is_first_run = false
	
	var ruleset_string : String = ""
	match ruleset:
		TIME_ATTACK_RULESET.STANDARD: ruleset_string = "STANDARD" 
		TIME_ATTACK_RULESET.CLASSIC: ruleset_string = "CLASSIC" 
		TIME_ATTACK_RULESET.ARCADE: ruleset_string = "ARCADE" 
		TIME_ATTACK_RULESET.COLOR_3: ruleset_string = "3 COLOR" 
		TIME_ATTACK_RULESET.HARDCORE: ruleset_string = "HARDCORE" 
	gameover_screen.get_node("Results/Detail4").text = str(time_limit) + " sec | " + ruleset_string + " | RESULTS"
	
	if hiscore > old_hiscore and time_attack_timer.time_left < 0.01:
		old_hiscore = hiscore
		gameover_screen.get_node("Results/NewRecord").visible = true
		
		var tween : Tween = create_tween().set_loops(20)
		tween.tween_property(gameover_screen.get_node("Results/NewRecord"), "self_modulate:a", 1.0, 0.25).from(0.5)
		tween.tween_property(gameover_screen.get_node("Results/NewRecord"), "self_modulate:a", 0.5, 0.25).from(1.0)
		
		if Data.profile.progress["time_attack_hiscore"].has(hiscore_entry_string):
			if score > Data.profile.progress["time_attack_hiscore"][hiscore_entry_string]: Data.profile.progress["time_attack_hiscore"][hiscore_entry_string] = score
	else:
		gameover_screen.get_node("Results/NewRecord").visible = false
	
	gameover_screen.get_node("Results/Attempts").text = str(current_attempt)
	gameover_screen.get_node("Results/Seed").text = "CURRENT ATTEMPT SEED: " + str(current_seed)

	if not replay_mode : current_seed = randi()
	game.rng.seed = current_seed

	replay.gamemode_settings["score"] = score


# graph line Y from -16 to 216
# graph line X from 0 to 392
func _plot_graph(points : Array, value_max : int) -> PackedVector2Array:
	var graph : PackedVector2Array = PackedVector2Array()
	var point_space : float = 392.0 / (points.size() - 1)
	
	var point_x : float = 0.0
	for point : int in points:
		var point_y : float = 232 * (1.0 - point / float(value_max)) - 16
		graph.append(Vector2(point_x, point_y))
		
		point_x += point_space
	
	return graph

func _end() -> void:
	if current_attempt > Data.profile.progress["stats"]["ta_top_retry_count"]:
		Data.profile.progress["stats"]["ta_top_retry_count"] = current_attempt

	config_backup._apply_preset()
	Data.profile._save_progress()
	Data._save_global_settings()


func _retry() -> void:
	if not replay_mode : 
		print("RANDOM")
		current_seed = randi()
	game.rng.seed = current_seed

	await get_tree().create_timer(0.01).timeout
	retry_complete.emit()


# Add score depending on 'deleted_squares_count', and display bonus message if removed enough squares
func _add_score_by_squares(deleted_squares_count : int) -> void:
	current_sqr_count += deleted_squares_count
	
	if deleted_squares_count > 0:
		_increase_score_value(deleted_squares_count)


func _count_squares() -> void:
	var size : int = statistics["square_cumulative"].size()
	statistics["square_cumulative"][size - 1].append(score)
	statistics["square_per_sweep"][size - 1].append(current_sqr_count)
	current_sqr_count = 0


# Does smooth value increase
func _increase_score_value(add : int) -> void:
	if add == 0: return
	var tween : Tween = create_tween().set_parallel(true)

	score += add
	tween.tween_method(time_attack_ui._set_score, score - add, score, 0.25)
	
	if score >= hiscore:
		tween.tween_method(time_attack_ui._set_hiscore, score - add, score, 0.25)
		hiscore = score
