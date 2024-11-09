extends Node

const MAX_LEADERBOARD_SIZE : Dictionary = {
	&"60std" : 200,
	&"120std" : 100,
	&"180std" : 100,
	&"300std" : 100,
	&"600std" : 100,

	&"60cls" : 200,
	&"120cls" : 100,
	&"180cls" : 100,
	&"300cls" : 100,
	&"600cls" : 100,

	&"60arc" : 100,
	&"120arc" : 50,
	&"180arc" : 50,
	&"300arc" : 30,
	&"600arc" : 30,

	&"60thr" : 100,
	&"120thr" : 50,
	&"180thr" : 50,
	&"300thr" : 30,
	&"600thr" : 30,

	&"60hrd" : 100,
	&"120hrd" : 50,
	&"180hrd" : 50,
	&"300hrd" : 30,
	&"600hrd" : 30,
}

signal all_scores_loaded
signal score_loaded(leaderboard : String)
signal score_saved

var current_gamemode : String = "time_attack_mode"
var is_ready : bool = false

var ranking : Dictionary = {
	"ta_total" : {
		#"60std" : {
			#entry_name : [score, time]
			#Revenant : [32, 120312939]
		#}
	},
	"ta_monthly" : {},
	"ta_weekly" : {}
}


func _ready() -> void:
	var file : FileAccess = FileAccess.open("res://scripts/resources/api.txt", FileAccess.READ)
	if FileAccess.get_open_error() > 0:
		print("Online ranking initialization failed! API key is missing...")
		return

	var key : String = file.get_line()
	var id : String = file.get_line()

	SilentWolf.config.api_key = key
	SilentWolf.config.game_id = id

	is_ready = true


func _save_score(type : String, score : int, replay : Replay) -> void:
	if not is_ready:
		return

	replay._save("temp",Data.CACHE_PATH,true)
	var replay_bytes : String = FileAccess.get_file_as_bytes(Data.CACHE_PATH + "temp.rpl").get_string_from_utf8()
	var metadata : Dictionary = {"replay" : replay_bytes}

	var entry_name : String = type + "_" + Data.profile.name + "_" + Data.profile.progress["key"]

	_load_score()
	
	var total_size : int = ranking["ta_total"][type].size() 
	var monthly_size : int = ranking["ta_monthly"][type].size() 
	var weekly_size : int = ranking["ta_weekly"][type].size() 

	if total_size == MAX_LEADERBOARD_SIZE[type]:
		var scores : Array = ranking["ta_total"][type].values()
		var last_score : Array = scores[total_size - 1]
		var medium_score : Array = scores[total_size / 2.0 - 1]

		if score > medium_score[0]: # Medium score (last in "main" leaderboard)
			await SilentWolf.Scores.delete_score(medium_score[2], "ta_total").sw_delete_score_complete
			await SilentWolf.Scores.delete_score(last_score[2], "ta_total2").sw_delete_score_complete
			await SilentWolf.Scores.save_score(medium_score[3], score, "ta_total2", {"replay" : medium_score[5]}).sw_save_score_complete
			await SilentWolf.Scores.save_score(entry_name, score, "ta_total", metadata).sw_save_score_complete
		elif score > last_score[0]: # Last score (last in "ta_total2" leaderboard)
			await SilentWolf.Scores.delete_score(last_score[2], "ta_total2").sw_delete_score_complete
			await SilentWolf.Scores.save_score(entry_name, score, "ta_total2", metadata).sw_save_score_complete
	
	elif total_size > MAX_LEADERBOARD_SIZE[type] / 2 and total_size < MAX_LEADERBOARD_SIZE[type]:
		var scores : Array = ranking["ta_total"][type].values()
		var medium_score : Array = scores[MAX_LEADERBOARD_SIZE[type] / 2 - 1]

		if score > medium_score[0]: # Medium score (last in "main" leaderboard)
			await SilentWolf.Scores.delete_score(medium_score[2], "ta_total").sw_delete_score_complete
			await SilentWolf.Scores.save_score(medium_score[3], score, "ta_total2", {"replay" : medium_score[5]}).sw_save_score_complete
			await SilentWolf.Scores.save_score(entry_name, score, "ta_total", metadata).sw_save_score_complete
		else:
			await SilentWolf.Scores.save_score(entry_name, score, "ta_total2", metadata).sw_save_score_complete
	
	else:
		await SilentWolf.Scores.save_score(entry_name, score, "ta_total", metadata).sw_save_score_complete


	if monthly_size == MAX_LEADERBOARD_SIZE[type] / 2:
		var scores : Array = ranking["ta_monthly"][type].values()
		var last_score : Array = scores[monthly_size - 1]

		if score > last_score[0]: # Last score (last in "ta_total2" leaderboard)
			await SilentWolf.Scores.delete_score(last_score[2], "ta_monthly").sw_delete_score_complete
			await SilentWolf.Scores.save_score(entry_name, score, "ta_monthly", metadata).sw_save_score_complete
	
	if weekly_size == MAX_LEADERBOARD_SIZE[type] / 2:
		var scores : Array = ranking["ta_weekly"][type].values()
		var last_score : Array = scores[weekly_size - 1]

		if score > last_score[0]: # Last score (last in "ta_total2" leaderboard)
			await SilentWolf.Scores.delete_score(last_score[2], "ta_weekly").sw_delete_score_complete
			await SilentWolf.Scores.save_score(entry_name, score, "ta_weekly", metadata).sw_save_score_complete


	score_saved.emit()


func _load_score(leaderboard : String = "all") -> bool:
	if not is_ready:
		return false

	if leaderboard == "all":
		_load_score("ta_total")
		_load_score("ta_mothly")
		_load_score("ta_weekly")
		all_scores_loaded.emit()
	
	var unparsed_ranking : Dictionary
	var parsed_ranking : Dictionary = {}
	
	match leaderboard:
		"ta_total" : 
			unparsed_ranking = await SilentWolf.Scores.get_scores(0, "main").sw_get_scores_complete
			var unparsed_ranking2 : Dictionary = await SilentWolf.Scores.get_scores(0, "ta_total2").sw_get_scores_complete
			if unparsed_ranking2["scores"].size > 0:
				unparsed_ranking["scores"].append_array(unparsed_ranking2["scores"])
			
		"ta_monthly" : unparsed_ranking = await SilentWolf.Scores.get_scores(0, "ta_monthly").sw_get_scores_complete
		"ta_weekly" : unparsed_ranking = await SilentWolf.Scores.get_scores(0, "ta_weekly").sw_get_scores_complete
	
	for i : int in unparsed_ranking["scores"].size():
		var score_dict : Dictionary = unparsed_ranking["scores"][i]
		
		var entry : String = score_dict["player_name"]
		var info : PackedStringArray = entry.split("_",false)
		
		var score : int = score_dict["score"]
		var entry_type : String = info[0]
		var player_name : String = info[1]
		var player_key : String = info[2]
		var time : int = int(score_dict["timestamp"])
		var score_id : String = score_dict["score_id"]
		var replay_bytes : String = score_dict["metadata"]["replay"]
		
		parsed_ranking[entry_type][player_name + "_" + player_key] = [score,time,score_id,entry,replay_bytes]
	
	ranking[leaderboard] = parsed_ranking
	score_loaded.emit(leaderboard)
	return true


func _get_time_left(leaderboard : String) -> int:
	return 99999
