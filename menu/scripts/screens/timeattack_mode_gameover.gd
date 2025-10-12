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


extends MenuScreen

##-----------------------------------------------------------------------
## Used for game over screen of [TimeAttackMode]
## Displays stats of current and previous time attack attempts
##-----------------------------------------------------------------------

var game : GameCore = null


func _ready() -> void:
	parent_menu.screens["foreground"].visible = true
	parent_menu.screens["foreground"]._raise()

	await parent_menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


## Creates statistics on given [TimeAttackMode] instance scores and other data
func _setup(ta_mode : TimeAttackMode) -> void:
	var square_cumulative : Array = ta_mode.statistics["square_cumulative"]
	var arrays_size : int = ta_mode.statistics["square_cumulative"].size()
	
	var square_per_sweep : Array = ta_mode.statistics["square_per_sweep"]

	if ta_mode.time_attack_timer.time_left > 0:
		$Top/Text.text = tr("TA_FAILED")

		$Results/Score.text = "DQ"
		$Results/Score.self_modulate = Color.RED

		arrays_size -= 1

		if arrays_size == 0: 
			for i : int in range(1,7):
				get_node("Results/Scores/" + str(i)).visible = false
				get_node("Results/Medium/" + str(i)).visible = false
				get_node("Results/Piece/" + str(i)).visible = false
	else:
		$Results/Score.text = str(ta_mode.score)
	
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
		var time_space : float = ta_mode.time_limit / 4.0
		
		for i : int in arrays_size:
			if i > 5 : break
			get_node("Stats/Cumulative/Graph" + str(i+1)).visible = true
			get_node("Stats/Legend/" + str(i+1)).visible = true
			get_node("Stats/Cumulative/Graph" + str(i+1)).points = _plot_graph(results_array[i], value_max)
		
		var value_mark : float = 0
		var time_mark : float = 0
		for i : int in 5:
			get_node("Stats/Cumulative/N/" + str(i+1)).text = str(int(value_mark))
			get_node("Stats/Cumulative/T/" + str(i+1)).text = str(int(time_mark))
			
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
			get_node("Stats/Sweep/Graph" + str(i+1)).visible = true
			get_node("Stats/Sweep/Graph" + str(i+1)).points = _plot_graph(results_array[i], value_max)
		
		value_mark = 0
		time_mark = 0
		
		for i : int in 5:
			get_node("Stats/Sweep/N/" + str(i+1)).text = str(int(value_mark))
			get_node("Stats/Sweep/T/" + str(i+1)).text = str(int(time_mark))
			
			value_mark += value_space
			time_mark += time_space
	
		var pieces_used : Array = ta_mode.statistics["pieces_used_count"]
		
		var value_sum : int = 0
		var y : int = 1
		for i : int in range(results_array.size() - 1, results_array.size() - 7, -1):
			value_sum = 0
			if i < 0:
				get_node("Results/Scores/" + str(y)).visible = false
				get_node("Results/Medium/" + str(y)).visible = false
				get_node("Results/Piece/" + str(y)).visible = false
			else:
				for x : int in results_array[results_array.size() - i - 1] : value_sum += x
				get_node("Results/Scores/" + str(y)).text = str(ta_mode.statistics["attempt_scores"][i])
				get_node("Results/Medium/" + str(y)).text = str(snapped(value_sum / float(results_array[i].size()), 0.1))
				get_node("Results/Piece/" + str(y)).text = str(pieces_used[i])
			y += 1
	
		value_sum = 0
		for x : int in ta_mode.statistics["attempt_scores"] : value_sum += x
	
		$Results/Average.text = str(round(value_sum / float(ta_mode.statistics["attempt_scores"].size())))
	
	var ruleset_string : String = ""
	match ta_mode.ruleset:
		TimeAttackMode.TIME_ATTACK_RULESET.STANDARD: ruleset_string = tr("TA_STANDARD")
		TimeAttackMode.TIME_ATTACK_RULESET.CLASSIC: ruleset_string = tr("TA_CLASSIC") 
		TimeAttackMode.TIME_ATTACK_RULESET.ARCADE: ruleset_string = tr("ARCADE") 
		TimeAttackMode.TIME_ATTACK_RULESET.COLOR_3: ruleset_string = tr("TA_3_COLOR") 
		TimeAttackMode.TIME_ATTACK_RULESET.HARDCORE: ruleset_string = tr("TA_HARDCORE")

	$Results/Detail4.text = str(ta_mode.time_limit) + tr("SEC") + " | " + ruleset_string + " | " + tr("TA_RESULTS")
	
	$Results/Attempts.text = str(ta_mode.current_attempt)
	$Results/Seed.text = tr("CURRENT_SEED") + " " + str(ta_mode.current_seed)


# graph line Y from -16 to 216
# graph line X from 0 to 392
## Returns array of Vector2 points which are used to plot a graph of values
func _plot_graph(points : Array, value_max : int) -> PackedVector2Array:
	var graph : PackedVector2Array = PackedVector2Array()
	var point_space : float = 392.0 / (points.size() - 1)
	
	var point_x : float = 0.0
	for point : int in points:
		var point_y : float = 232 * (1.0 - point / float(value_max)) - 16
		graph.append(Vector2(point_x, point_y))
		
		point_x += point_space
	
	return graph


## Displays new record animation
func _new_record() -> void:
	get_node("Results/NewRecord").visible = true
		
	var tween : Tween = create_tween().set_loops(20)
	tween.tween_property(get_node("Results/NewRecord"), "self_modulate:a", 1.0, 0.25).from(0.5)
	tween.tween_property(get_node("Results/NewRecord"), "self_modulate:a", 0.5, 0.25).from(1.0)


## Opens input dialog for replay save
func _save_replay() -> void:
	var input : MenuScreen = parent_menu._add_screen("text_input")
	input.desc_text = tr("SAVE_REPLAY_DIALOG")
	input.accept_function = game.replay._save


## Starts new time attack attempt
func _restart() -> void:
	game._retry()
	parent_menu._remove_screen("foreground")
	_remove()


# Finishes the game and returns to main menu
func _end() -> void:
	game._end()
	parent_menu._remove_screen("foreground")
	_remove()
