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
var time_timer : Timer

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

	if game.is_playing_replay: 
		game.game_over_screen_name = "demo_gameover"
		game.menu_screen_to_return = "main_menu"

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
	_load_ui()

	var grid : UIElement = game.foreground.ui_elements["grid"]
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

	time_timer = Timer.new()
	time_timer.timeout.connect(func() -> void: Data.profile.progress["stats"]["ta_total_time"] += 1; Data.profile.progress["stats"]["total_play_time"] += 1)
	time_timer.one_shot = false
	add_child(time_timer)
	time_timer.start(1.0)


func _prereset() -> void:
	time_attack_ui._stop()
	time_attack_ui._set_time(float(time_limit))

	score = 0
	time_attack_ui._set_hiscore(hiscore)
	time_attack_ui._set_score(score)

	current_sqr_count = 0
	current_attempt += 1
	Data.profile.progress["stats"]["ta_total_retry_count"] += 1

	if not game.is_playing_replay : current_seed = randi()
	game.rng.seed = current_seed

	if not is_game_over:
		statistics["square_cumulative"].pop_back()
		statistics["square_per_sweep"].pop_back()
		statistics["pieces_used_count"].pop_back()
	is_game_over = false
	
	statistics["square_cumulative"].append([])
	statistics["square_per_sweep"].append([])
	statistics["pieces_used_count"].append(0)


func _reset() -> void:
	# Pause grid ui element so beat counter animation wont play until countdown sequence finishes
	var grid : UIElement = game.foreground.ui_elements["grid"]
	
	grid.process_mode = Node.PROCESS_MODE_DISABLED
	grid.get_node("Field/Beatcount").size.x = 0.0

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
		game.skin.scene_player.play(str(time_limit) + "sec" + str(current_mix))
	else:
		game.skin.scene_player.play("main")

	await get_tree().create_timer(0.05).timeout
	game.skin.scene_player.pause()

	time_attack_ui.get_node("Start/StartAnim").stop()
	if is_first_run:
		time_attack_ui.get_node("Start/StartAnim").play("start")
		await get_tree().create_timer(3.0).timeout
	else:
		time_attack_ui.get_node("Start/StartAnim").play("startfast")
		await get_tree().create_timer(1.0).timeout

	grid.process_mode = Node.PROCESS_MODE_INHERIT

	time_attack_timer.start(time_limit)
	stat_timer.start(4.0)
	stat_disable_timer.start(time_limit - 1.0)
	is_counting_time = true
	
	reset_complete.emit()
	time_attack_ui._start()


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
	
	game.piece_fall_speed = Data.profile.config["gameplay"]["piece_fall_speed"]
	game.piece_fall_delay = Data.profile.config["gameplay"]["piece_fall_delay"]


func _load_ui() -> void:
	var foreground : Node2D = game.foreground
	foreground._reset()

	foreground._add_ui_element("grid")
	foreground._add_ui_element("holder")

	time_attack_ui = foreground._add_ui_element("time_attack")
	time_attack_ui._set_hiscore(hiscore)

	if game.is_playing_replay : foreground._add_ui_element("replay_ui")

	# Load holder arrow textures
	foreground.ui_elements["holder"]._change_style()


func _process(_delta : float) -> void:
	if is_counting_time and time_attack_ui != null: time_attack_ui._set_time(time_attack_timer.time_left)


func _pause(on : bool) -> void:
	time_attack_timer.paused = on
	stat_disable_timer.paused = on
	stat_timer.paused = on
	time_timer.paused = on
	is_counting_time = !on


func _game_over() -> void:
	is_game_over = true
	if game.is_playing_replay : return

	game.replay.gamemode_settings["score"] = str(score)

	var arrays_size : int = statistics["square_cumulative"].size()
	if time_attack_timer.time_left > 0:
		statistics["square_cumulative"].pop_back()
		statistics["square_per_sweep"].pop_back()
		statistics["pieces_used_count"].pop_back()
	else:
		statistics["square_cumulative"][arrays_size - 1].append(score)
		statistics["square_per_sweep"][arrays_size - 1].append(current_sqr_count)
		statistics["attempt_scores"].append(score)
		
		if Data.global_settings.has(hiscore_entry_string + "_ranking"):
			Data.global_settings[hiscore_entry_string + "_ranking"].append([Data.profile.name, score, Time.get_unix_time_from_system()])
		
		if Data.ranking_manager != null and Data.profile.config["misc"]["save_score_online"] and time_limit in [60,120,180,300,600]:
			var online_string : String = str(time_limit)
			match ruleset:
				TIME_ATTACK_RULESET.STANDARD: online_string += "std" 
				TIME_ATTACK_RULESET.CLASSIC: online_string += "cls" 
				TIME_ATTACK_RULESET.ARCADE: online_string += "arc" 
				TIME_ATTACK_RULESET.COLOR_3: online_string += "thr" 
				TIME_ATTACK_RULESET.HARDCORE: online_string += "hrd" 
			
			Data.ranking_manager._save_score(online_string, score)
		
		is_first_run = false

	var gameover_screen : MenuScreen = Data.menu.screens["timeattack_mode_gameover"]
	gameover_screen._setup(self)

	if hiscore > old_hiscore and not time_attack_timer.time_left > 0:
		old_hiscore = hiscore
		gameover_screen._new_record()
		
		if Data.profile.progress["time_attack_hiscore"].has(hiscore_entry_string):
			if score > Data.profile.progress["time_attack_hiscore"][hiscore_entry_string]: 
				Data.profile.progress["time_attack_hiscore"][hiscore_entry_string] = score


func _end() -> void:
	if current_attempt > Data.profile.progress["stats"]["ta_top_retry_count"]:
		Data.profile.progress["stats"]["ta_top_retry_count"] = current_attempt

	config_backup._apply_preset()
	Data.profile._save_progress()
	Data._save_global_settings()


func _retry() -> void:
	await get_tree().create_timer(0.01).timeout
	retry_complete.emit()


# Add score depending on 'deleted_squares_count'
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
	tween.tween_method(time_attack_ui._set_score, score - add, score, 0.15)
	
	if score >= hiscore:
		tween.tween_method(time_attack_ui._set_hiscore, score - add, score, 0.15)
		hiscore = score
