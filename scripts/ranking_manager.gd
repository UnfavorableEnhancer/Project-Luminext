extends Node

const MAX_LEADERBOARD_SIZE : Dictionary = {
	&"60std" : 100,
	&"120std" : 50,
	&"180std" : 50,
	&"300std" : 50,
	&"600std" : 50,

	&"60cls" : 100,
	&"120cls" : 50,
	&"180cls" : 50,
	&"300cls" : 50,
	&"600cls" : 50,

	&"60arc" : 50,
	&"120arc" : 20,
	&"180arc" : 20,
	&"300arc" : 20,
	&"600arc" : 20,

	&"60thr" : 50,
	&"120thr" : 20,
	&"180thr" : 20,
	&"300thr" : 20,
	&"600thr" : 20,

	&"60hrd" : 50,
	&"120hrd" : 20,
	&"180hrd" : 20,
	&"300hrd" : 20,
	&"600hrd" : 20,
}

const MAX_REQUEST_RETRY : int = 5
const REQUEST_RETRY_THRESHOLD : float = 1.0

enum LOADING_RESULT {OK, REQUESTS_FAILED}

signal score_saved

var current_gamemode : String = "ta_"
var is_ready : bool = false
var is_loaded : bool = false

var request_retry_count : int = 0
var fail_reason : int = 0

var ranking : Dictionary = {
	"ta_total" : {
		#"60std" : {
			#entry_name%entry_key : [name, key, score, timestamp, score_id, replay_bytes]
			#Revenant%129h291b2 : [Revenant, 129h291b2, 32, 120312939. SG2NASJ2193S, ...]
		#}
	},
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


func _save_score(type : String, score : int, replay : Replay = null, entry_name : String = "", entry_key : String = "") -> void:
	if not is_ready:
		return
	
	var metadata : Dictionary = {"timestamp" : Time.get_unix_time_from_system(), "replay" : ""}
	if replay != null:
		replay._save("temp", Data.CACHE_PATH, true)
		var replay_bytes : String = FileAccess.get_file_as_bytes(Data.CACHE_PATH + "temp.rpl").get_string_from_utf8()
		metadata["replay"] = replay_bytes
	
	if entry_name.is_empty() : entry_name = Data.profile.name
	if entry_key.is_empty() : entry_key = Data.profile.progress["misc"]["key"]
	var save_entry : String = type + "%" + entry_name + "%" + entry_key
	
	print("Confirming scores...")
	await _load_scores()
	
	var total_size : int = 0
	if ranking["ta_total"].has(type) : total_size = ranking["ta_total"][type].size() 
	
	print("")
	# If backend leaderboard is full
	if total_size == MAX_LEADERBOARD_SIZE[type]:
		print("Leaderboard is full!")
		var scores : Array = ranking["ta_total"][type].values()
		var last_score : Array = scores[total_size - 1]
	
		if score > last_score[2]:
			print("Pushing backend leaderboard")
			await SilentWolf.Scores.delete_score(last_score[4], "main").sw_delete_score_complete
			await SilentWolf.Scores.save_score(save_entry, score, "main", metadata).sw_save_score_complete
	else:
		print("Appending to backend leaderboard")
		await SilentWolf.Scores.save_score(save_entry, score, "main", metadata).sw_save_score_complete
	
	score_saved.emit()


func _load_scores() -> bool:
	if not is_ready : return false
	
	var unparsed_ranking : Dictionary = {}
	var parsed_ranking : Dictionary = {}
	
	var start_time : int = Time.get_ticks_msec()
	request_retry_count = 0
	print("Requesting leaderboard : main")
	while true:
		request_retry_count += 1
		if request_retry_count > MAX_REQUEST_RETRY:
			print("All requests failed! Try again in better times...")
			return false
		
		unparsed_ranking = await SilentWolf.Scores.get_scores(0, "main").sw_get_scores_complete
		
		if not unparsed_ranking["success"]:
			print("Error! Leaderboard request failed : ", unparsed_ranking["error"])
			await get_tree().create_timer(REQUEST_RETRY_THRESHOLD).timeout
			print("Trying again...")
		else:
			print("Success!")
			print("Time elapsed:", (Time.get_ticks_msec() - start_time) / 1000.0)
			break
	
	for i : int in unparsed_ranking["scores"].size():
		var score_dict : Dictionary = unparsed_ranking["scores"][i]
		
		var entry : String = score_dict["player_name"]
		var info : PackedStringArray = entry.split("%",false)
		
		var score : int = score_dict["score"]
		var entry_type : String = info[0]
		var player_name : String = info[1]
		var player_key : String = info[2]
		var time : int = int(score_dict["metadata"]["timestamp"])
		var score_id : String = score_dict["score_id"]
		var replay_bytes : String = score_dict["metadata"]["replay"]
		
		if not parsed_ranking.has(entry_type):
			parsed_ranking[entry_type] = {}
		parsed_ranking[entry_type][player_name + "%" + player_key] = [player_name,player_key,score,time,score_id,replay_bytes]
	
	ranking["ta_total"] = parsed_ranking
	is_loaded = true
	return true


func _delete_score(score_id : String) -> void:
	await SilentWolf.Scores.delete_score(score_id, "main").sw_delete_score_complete
