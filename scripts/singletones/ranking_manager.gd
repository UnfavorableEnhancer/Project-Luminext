extends Node

##-----------------------------------------------------------------------
## Manages online and local ranking
##-----------------------------------------------------------------------

# const MAX_LEADERBOARD_SIZE : Dictionary = {
# 	&"60std" : 100,
# 	&"120std" : 50,
# 	&"180std" : 50,
# 	&"300std" : 50,
# 	&"600std" : 50,

# 	&"60cls" : 100,
# 	&"120cls" : 50,
# 	&"180cls" : 50,
# 	&"300cls" : 50,
# 	&"600cls" : 50,

# 	&"60arc" : 50,
# 	&"120arc" : 20,
# 	&"180arc" : 20,
# 	&"300arc" : 20,
# 	&"600arc" : 20,

# 	&"60thr" : 50,
# 	&"120thr" : 20,
# 	&"180thr" : 20,
# 	&"300thr" : 20,
# 	&"600thr" : 20,

# 	&"60hrd" : 50,
# 	&"120hrd" : 20,
# 	&"180hrd" : 20,
# 	&"300hrd" : 20,
# 	&"600hrd" : 20,
# }

# const MAX_REQUEST_RETRY : int = 5
# const REQUEST_RETRY_THRESHOLD : float = 1.0

# enum LOADING_RESULT {OK, REQUESTS_FAILED}

# signal score_saved
# signal scores_loaded

# var current_gamemode : String = "ta_"
# var is_loaded : bool = false

# var silent_wolf : Node = null

# var request_retry_count : int = 0
# var fail_reason : int = 0

# var online_ranking : Dictionary = {
# 	"ta_total" : {
# 		#"60std" : {
# 			#entry_name%entry_key : [name, key, score, timestamp, score_id, replay_bytes]
# 			#Revenant%129h291b2 : [Revenant, 129h291b2, 32, 120312939. SG2NASJ2193S, ...]
# 		#}
# 	},
# }

# var local_ranking : Dictionary = {
# 	"ta_total" : {
# 		#"60std" : {
# 			#entry_name%entry_key%timestamp : [name, key, score, timestamp, score_id, replay_bytes]
# 			#Revenant%129h291b2%8777887 : [Revenant, 129h291b2, 32, 120312939. SG2NASJ2193S, ...]
# 		#}
# 	},
# }


# func _ready() -> void:
# 	return
# 	_load_local_scores()

# 	Console._log("")
# 	Console._log("Initializing online score ranking...")

# 	if not FileAccess.file_exists("res://addons/silent_wolf/silent_wolf.gd"):
# 		Console._log("ERROR! PLUGIN IS MISSING")
# 		return
# 	if not FileAccess.file_exists("res://scripts/resources/api.txt"):
# 		Console._log("ERROR! API KEY IS MISSING")
# 		return

# 	silent_wolf = Node.new()
# 	silent_wolf.set_script(load("res://addons/silent_wolf/silent_wolf.gd"))
# 	add_child(silent_wolf)

# 	var file : FileAccess = FileAccess.open("res://scripts/resources/api.txt", FileAccess.READ)
# 	if FileAccess.get_open_error() > OK:
# 		Console._log("ERROR! API KEY LOADING FAILED : " + error_string(FileAccess.get_open_error()))
# 		return

# 	var key : String = file.get_line()
# 	var id : String = file.get_line()

# 	silent_wolf.config.api_key = key
# 	silent_wolf.config.game_id = id


# func _save_score(type : String, score : int, _replay : Replay = null, entry_name : String = "", entry_key : String = "") -> void:
# 	return
# 	Console._log("")
# 	Console._log("Saving score : " + type + " = " + str(score))
	
# 	var timestamp : float = Time.get_unix_time_from_system()
# 	var metadata : Dictionary = {"timestamp" : timestamp, "replay" : ""}

# 	if entry_name.is_empty() : entry_name = UserData.profile_name
# 	if entry_key.is_empty() : entry_key = UserData.savedata.vault_key
# 	var online_save_entry : String = type + "%" + entry_name + "%" + entry_key
	


# 	if type not in MAX_LEADERBOARD_SIZE.keys():
# 		Console._log("Unsupported score type for online ranking : " + type)
# 		score_saved.emit()
# 		return

# 	if silent_wolf == null : 
# 		Console._log("Failed saving score online. Online ranking manager is not initiated")
# 		score_saved.emit()
# 		return

# 	Console._log("Updating online ranking")
# 	await _load_online_scores()
# 	Console._log("")
	
# 	var total_size : int = 0
# 	if online_ranking["ta_total"].has(type) : total_size = online_ranking["ta_total"][type].size() 
	
# 	# If backend leaderboard is full
# 	if total_size == MAX_LEADERBOARD_SIZE[type]:
# 		Console._log("Ranking is full!")
# 		var scores : Array = online_ranking["ta_total"][type].values()
# 		var last_score : Array = scores[total_size - 1]
	
# 		if score > last_score[2]:
# 			Console._log("Pushing ranking")
# 			#await SilentWolf.Scores.delete_score(last_score[4], "main").sw_delete_score_complete
# 			#await SilentWolf.Scores.save_score(online_save_entry, score, "main", metadata).sw_save_score_complete
# 	else:
# 		Console._log("Appending to ranking")
# 		#await SilentWolf.Scores.save_score(online_save_entry, score, "main", metadata).sw_save_score_complete
	
# 	Console._log("Online ranking score is saved!")
# 	score_saved.emit()


# func _add_local_score(type : String, score : int, name : String, key : String, timestamp : float) -> void:
# 	return
# 	var local_save_entry : String = name + "%" + key + "%" + str(timestamp)
	
# 	if not local_ranking["ta_total"].has(type) : local_ranking["ta_total"][type] = {}
# 	local_ranking["ta_total"][type][local_save_entry] = [name, key, score, timestamp, ""]


# func _save_local_scores() -> bool:
# 	return true
# 	var file : FileAccess = FileAccess.open(Data.LOCAL_RANKING_PATH, FileAccess.WRITE)
# 	if not file:
# 		Console._log("ERROR! LOCAL RANKING LOAD FAILED : ", error_string(FileAccess.get_open_error()))
# 		return false
	
# 	file.store_string(JSON.stringify(local_ranking, "\t"))
# 	file.close()
# 	Console._log("Local ranking score is saved!")
# 	return true


# func _load_local_scores() -> bool:
# 	return true
# 	Console._log("Loading local score ranking...")
# 	var file : FileAccess = FileAccess.open(Data.LOCAL_RANKING_PATH, FileAccess.READ)
# 	if not file:
# 		Console._log("ERROR! LOCAL RANKING LOAD FAILED : ", error_string(FileAccess.get_open_error()))
# 		return false
	
# 	var loaded_json : Variant = JSON.parse_string(file.get_as_text())
# 	if loaded_json == null or not loaded_json.has("ta_total"):
# 		Console._log("ERROR! INVALID LOCAL RANKING FORMAT")
# 		return false

# 	local_ranking = loaded_json
# 	file.close()
# 	Console._log("Local score ranking is loaded!")
# 	return true


# func _load_online_scores() -> bool:
# 	return true
# 	Console._log("")
# 	Console._log("Loading online score ranking...")

# 	if silent_wolf == null : 
# 		Console._log("Failed loading online score ranking. Online ranking manager is not initiated")
# 		scores_loaded.emit()
# 		return false
	
# 	var unparsed_ranking : Dictionary = {}
# 	var parsed_ranking : Dictionary = {}
	
# 	var start_time : int = Time.get_ticks_msec()
# 	request_retry_count = 0
# 	Console._log("Requesting leaderboard : main")
# 	while true:
# 		request_retry_count += 1
# 		if request_retry_count > MAX_REQUEST_RETRY:
# 			Console._log("All requests failed! Try again in better times...")
# 			return false
		
# 		#unparsed_ranking = await SilentWolf.Scores.get_scores(0, "main").sw_get_scores_complete
		
# 		if not unparsed_ranking["success"]:
# 			Console._log("ERROR! REQUEST FAILED : ", unparsed_ranking["error"])
# 			await get_tree().create_timer(REQUEST_RETRY_THRESHOLD).timeout
# 			Console._log("Trying again...")
# 		else:
# 			Console._log("Success!")
# 			Console._log("Time elapsed:", (Time.get_ticks_msec() - start_time) / 1000.0)
# 			break
	
# 	for i : int in unparsed_ranking["scores"].size():
# 		var score_dict : Dictionary = unparsed_ranking["scores"][i]
		
# 		var entry : String = score_dict["player_name"]
# 		var info : PackedStringArray = entry.split("%",false)
		
# 		var score : int = score_dict["score"]
# 		var entry_type : String = info[0]
# 		var player_name : String = info[1]
# 		var player_key : String = info[2]
# 		var time : int = int(score_dict["metadata"]["timestamp"])
# 		var score_id : String = score_dict["score_id"]
# 		var replay_bytes : String = score_dict["metadata"]["replay"]
		
# 		if not parsed_ranking.has(entry_type):
# 			parsed_ranking[entry_type] = {}
# 		parsed_ranking[entry_type][player_name + "%" + player_key] = [player_name,player_key,score,time,score_id,replay_bytes]
	
# 	online_ranking["ta_total"] = parsed_ranking
# 	is_loaded = true
# 	scores_loaded.emit()
# 	return true


# func _delete_score(score_id : String) -> void:
# 	return
# 	#await SilentWolf.Scores.delete_score(score_id, "main").sw_delete_score_complete
