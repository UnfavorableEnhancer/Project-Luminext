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

##-----------------------------------------------------------------------
## Time attack mode features several time limits + ruleset combinations 
## with which player must get as much score as possible
##-----------------------------------------------------------------------

class_name TimeAttackMode

## All avaiable time attack rulesets
enum TIME_ATTACK_RULESET {
	STANDARD, ## Standard luminext ruleset
	CLASSIC, ## Ruleset which mimics lumines remastered gameplay
	ARCADE, ## Ruleset featuring all sorts of gimmicks
	COLOR_3, ## Ruleset featuring 3 colors instead of 2
	HARDCORE ## Ruleset featuring faster gameplay and dark blocks
}

var skin_metadata : SkinMetadata = null ## Skin used for this gamemode metadata

var time_limit : int = 0 ## Selected time limit
var selected_ruleset : int = TIME_ATTACK_RULESET.STANDARD ## Selected ruleset type
var random_mixes : bool = false ## If true, music mix will be randomly selected on each attempt
var current_mix : int = -1 ## Currently playing music mix

var hiscore_entry_string : String ## String representing selected time limit + ruleset combination, used for ranking manager
var frontend_entry_string : String ## String representing selected time limit + ruleset combination, used for time attack UI

var is_cheater : bool = false ## True if player cheated XD

var time_attack_timer : Timer ## Timer counting time limit
var time_attack_ui : UIElement ## Main time attack [UI Element]

## Stores latest 5 attempts statistics graph data
var statistics : Dictionary = {
	"score" : [], ## All scores per sweep
	"squares_per_sweep" : [], ## Amount of squares erased per sweep
	"blocks_left_on_field" : [], ## Amount of blocks left on field per sweep
	"used_pieces_count" : [], ## Used pieces per sweep
}

var current_attempt : int = 0 ## Current attempt number
var current_seed : int = 451 ## Current seed

var score : int = 0 ## Current amount of deleted squares
var hiscore : int = 0 ## Overall hi-score

var current_used_pieces_count : int = 0 ## Amount of pieces used in current timeline sweep
var total_used_pieces_count : int = 0 ## Total amount of pieces used


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
	game.new_piece_is_given.connect(_on_new_piece_is_given)

	main.total_time_tick.connect(func() -> void : Player.savedata.stats["ta_total_time"] += 1; Player.savedata.stats["total_play_time"] += 1)

	Console.opened.connect(func() -> void : is_cheater = true)
	Console.command_entered.connect(_execute_console_command)
	
	# TODO
	# if UserData.savedata.hiscores["time_attack_hiscore"].has(hiscore_entry_string): 
	# 	hiscore = UserData.savedata.hiscores["time_attack_hiscore"][hiscore_entry_string] 
	# 	old_hiscore = hiscore

	_load_ui()
	_load_ruleset()

	time_attack_timer = Timer.new()
	time_attack_timer.timeout.connect(game._game_over)
	time_attack_timer.one_shot = true
	add_child(time_attack_timer)


## Initiates all needed for this gamemode [UIElements]
func _load_ui() -> void:
	foreground._reset()

	var grid : UIElement = foreground._add_ui_element("grid")
	game.timeline_started.connect(grid._update)
	game.piece_queue.piece_swap.connect(grid._swap)
	if game.skin.is_music_looping : game.music_playback_state = 2
	
	foreground._add_ui_element("holder")

	time_attack_ui = foreground._add_ui_element("time_attack")

	if game.is_playing_replay : foreground._add_ui_element("replay_ui")

	# Load holder arrow textures
	foreground.ui_elements["holder"]._change_style()


## Called on game reset before **_reset()** function and game objects clean up
func _soft_reset() -> void:
	_load_hiscore()

	time_attack_ui._stop()
	time_attack_ui._set_time(float(time_limit))

	score = 0
	time_attack_ui._set_hiscore(hiscore)
	time_attack_ui._set_score(score)

	_new_attempt()


## Called on game reset
func _reset() -> int:
	if game.skin == null:
		var skin_change_result : int = await game._change_skin(skin_metadata, true)
		if skin_change_result > 1:
			error_text = "Failed to load time attack skin"
			return skin_change_result
		
		main._toggle_loading(false)
		await get_tree().create_timer(0.5).timeout
		
	if skin_metadata.name == "grandfather clock" or skin_metadata.name == "The Years Will Pass" : _load_music_mix()

	game.piece_queue._reset()
	main._toggle_darken(false)

	var is_first_run : bool = current_attempt == 1
	await time_attack_ui._intro(is_first_run)

	time_attack_timer.start(time_limit)
	time_attack_ui._start()
	game._give_new_piece()
	game.skin._start()

	return OK


## Starts new time attack attempt
func _new_attempt() -> void:
	current_attempt += 1
	Player.savedata.stats["ta_total_retry_count"] += 1

	if not game.is_playing_replay : current_seed = randi()
	game.rng.seed = current_seed
	
	# If we ended previous attempt mid-game or cheated, remove its stats data
	if time_attack_timer.time_left > 0 or is_cheater:
		statistics["square_cumulative"].pop_front()
		statistics["square_per_sweep"].pop_front()
		statistics["blocks_left_on_field"].pop_front()
		statistics["pieces_used_count"].pop_front()
		statistics["attempt_scores"].pop_front()

	is_cheater = false

	statistics["square_cumulative"].append([])
	statistics["square_per_sweep"].append([])
	statistics["blocks_left_on_field"].append([])
	statistics["pieces_used_count"].append(0)
	statistics["attempt_scores"].append(0)


## Loads selected ruleset and builds appropriate time_limit + ruleset combination strings
func _load_ruleset() -> void:
	var ruleset_string : String = ""
	var frontend_ruleset_string : String = ""

	match selected_ruleset:
		TIME_ATTACK_RULESET.STANDARD: 
			ruleset._load("res://internal/presets/standard.json")
			ruleset_string = "_standard" 
			frontend_ruleset_string = "Standard" 
		TIME_ATTACK_RULESET.CLASSIC: 
			ruleset._load("res://internal/presets/classic.json")
			ruleset_string = "_classic" 
			frontend_ruleset_string = "Classic" 
		TIME_ATTACK_RULESET.ARCADE: 
			ruleset._load("res://internal/presets/arcade.json")
			ruleset_string = "_arcade" 
			frontend_ruleset_string = "Arcade" 
		TIME_ATTACK_RULESET.COLOR_3: 
			ruleset._load("res://internal/presets/3color.json")
			ruleset_string = "_3color" 
			frontend_ruleset_string = "3 Color" 
		TIME_ATTACK_RULESET.HARDCORE: 
			ruleset._load("res://internal/presets/hardcore.json")
			ruleset_string = "_hardcore" 
			frontend_ruleset_string = "Hardcore" 

	hiscore_entry_string = str(time_limit) + ruleset_string

	if time_limit < 300 : frontend_entry_string = "grandmother clock/W3Rn1ckz | " + str(time_limit) +  " sec | " + frontend_ruleset_string
	else : frontend_entry_string = str(time_limit) + "The Years Will Pass/W3Rn1ckz | " + str(time_limit) +  " sec | " + frontend_ruleset_string
	foreground.ui_elements["grid"].get_node("text").text = frontend_entry_string

	if selected_ruleset != TIME_ATTACK_RULESET.COLOR_3:
		if time_limit == 120 or time_limit == 600:
			ruleset.blocks["red"] = false
			ruleset.blocks["green"] = true
		if time_limit == 180:
			ruleset.blocks["red"] = false
			ruleset.blocks["purple"] = true


## Loads from ranking manager a hi-score to current time_limit + ruleset combination
func _load_hiscore() -> void:
	hiscore = 0
	time_attack_ui._set_hiscore(hiscore)


## Injects current music mix into game skin player
func _load_music_mix() -> void:
	if time_limit in [60,120,180,300,600]:
		if random_mixes:
			var i : Array[int] = [1,2,3,4,5]
			if time_limit > 60 : i.pop_back()
			if time_limit > 120 : i.pop_back()
			if time_limit > 180 : i.pop_back()
			if time_limit > 300 : i.pop_back()
			# Exclude previously played mix
			if current_mix > 0 and time_limit != 600: i.remove_at(current_mix - 1)
			current_mix = i.pick_random()
		else:
			if current_mix == -1 : current_mix = 1
	
		game.skin.skin_data.stream["music"] = load("res://internal/music/" + str(time_limit) + "sec_ta_mix" + str(current_mix) + ".ogg")
		game.skin.scene_player.play(str(time_limit) + "sec" + str(current_mix))
	else:
		game.skin.scene_player.play("main")

	await get_tree().create_timer(0.05).timeout
	game.skin.scene_player.pause()


func _process(_delta : float) -> void:
	if time_attack_ui != null: 
		time_attack_ui._set_time(time_attack_timer.time_left)


## Called on game pause
func _pause(on : bool) -> void:
	time_attack_timer.paused = on


## Called on game over
func _game_over() -> void:
	if game.is_playing_replay : return

	game.replay.game_info["score"] = str(score)

	var gameover_screen : MenuScreen = game.menu.screens["timeattack_mode_gameover"]
	gameover_screen._setup(self)

	if time_attack_timer.time_left > 0 or is_cheater : return

	# TODO
	# if Data.ranking_manager != null and UserData.config.misc["save_score_online"] and time_limit in [60,120,180,300,600]:
	# 	var online_string : String = str(time_limit)
	# 	match ruleset:
	# 		TIME_ATTACK_RULESET.STANDARD: online_string += "std" 
	# 		TIME_ATTACK_RULESET.CLASSIC: online_string += "cls" 
	# 		TIME_ATTACK_RULESET.ARCADE: online_string += "arc" 
	# 		TIME_ATTACK_RULESET.COLOR_3: online_string += "thr" 
	# 		TIME_ATTACK_RULESET.HARDCORE: online_string += "hrd" 
		
	# 	Data.ranking_manager._save_score(online_string, score)

	# if hiscore == score and not time_attack_timer.time_left > 0:
	# 	gameover_screen._new_record()


## Called on game end
func _end() -> void:
	Player.savedata._set_stats_top("ta_top_retry_count", current_attempt)
	Player._save_profile()


# Connects new timeline to this gamemode signals
func _connect_timeline() -> void:
	game.timeline.squares_deleted.connect(_add_score_by_squares)
	game.timeline.finished.connect(_record_statistics)


## Called on timeline death and stores statistics values for current timeline pass
func _record_statistics() -> void:
	var attempts_stored : int = statistics["square_cumulative"].size()

	statistics["score"][attempts_stored - 1].append(score)
	statistics["square_per_sweep"][attempts_stored - 1].append(game.timeline.total_deleted_squares_count)
	statistics["blocks_left_on_field"][attempts_stored - 1].append(game.blocks.size())
	statistics["used_pieces_count"][attempts_stored - 1].append(current_used_pieces_count)

	current_used_pieces_count = 0


## Called when new piece is given
func _on_new_piece_is_given() -> void:
	current_used_pieces_count += 1
	total_used_pieces_count += 1


## Add score depending on 'deleted_squares_count'
func _add_score_by_squares(deleted_squares_count : int) -> void:
	if deleted_squares_count == 0 : return
	var tween : Tween = create_tween().set_parallel(true)

	score += deleted_squares_count
	tween.tween_method(time_attack_ui._set_score, score - deleted_squares_count, score, 0.15)
	
	if score >= hiscore:
		tween.tween_method(time_attack_ui._set_hiscore, score - deleted_squares_count, score, 0.15)
		hiscore = score


## Executes entered into Console command
func _execute_console_command(command : String, arguments : PackedStringArray) -> void:
	is_cheater = true

	match command:
		# Time attack mode commmands
		# Sets timer current time
		"tatime" :
			if arguments.size() < 1: Console._output("Error! Time value is not entered"); return
			time_attack_timer.start(float(arguments[0]))
		
		# Sets current time attack attempt score
		"tascore" :
			if arguments.size() < 1: Console._output("Error! Score value is not entered"); return
			score = int(arguments[0])
			time_attack_ui._set_score(score)
		
		# Prints all collected current attempt statistics
		"tastats" :
			for stat : String in ["score", "squares_per_sweep", "blocks_left_on_field", "used_pieces_count"]:
				match stat:
					"score" : Console._output("Score")
					"squares_per_sweep" : Console._output("Squares erased per timeline pass")
					"blocks_left_on_field" : Console._output("Blocks left on game field")
					"used_pieces_count" : Console._output("Used pieces count")

				Console._output("=================================================")

				for attempt : int in statistics[stat].size():
					Console._output("Attempt : " + str(attempt))
					Console._output("---------------------------------------------------")

					var data : Array[int] = statistics[stat][attempt]
					for i : int in data.size():
						Console._output(str(i) + " : " + str(data[i]))