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

const MAX_REQUEST_RETRY : int = 5
const REQUEST_RETRY_THRESHOLD : float = 1.0

signal score_saved

var current_gamemode : String = "ta_"
var is_ready : bool = false

var request_retry_count : int = 0

var ranking : Dictionary = {
	"ta_total" : {
		#"60std" : {
			#entry_name%entry_key : [name, key, score, timestamp, score_id, replay_bytes]
			#Revenant%129h291b2 : [Revenant, 129h291b2, 32, 120312939. SG2NASJ2193S, ...]
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
	
	#await SilentWolf.Scores.save_score("TEST", 200, "main").sw_save_score_complete
	#await SilentWolf.Scores.delete_score("fc6c64d9-1770-496f-a6b0-3835e54523ba","ta_monthly").sw_delete_score_complete


func _save_score(type : String, score : int, replay : Replay = null, entry_name : String = "", entry_key : String = "") -> void:
	if not is_ready:
		return
	
	var metadata : Dictionary = {"timestamp" : Time.get_unix_time_from_system(), "replay" : ""}
	if replay != null:
		replay._save("temp",Data.CACHE_PATH,true)
		var replay_bytes : String = FileAccess.get_file_as_bytes(Data.CACHE_PATH + "temp.rpl").get_string_from_utf8()
		metadata["replay"] = replay_bytes
	
	if entry_name.is_empty() : entry_name = Data.profile.name
	if entry_key.is_empty() : entry_key = Data.profile.progress["key"]
	var save_entry : String = type + "%" + entry_name + "%" + entry_key
	
	print("Confirming scores...")
	await _load_scores()
	
	var total_size : int = 0
	if ranking["ta_total"].has(type) : total_size = ranking["ta_total"][type].size() 
	var monthly_size : int = 0
	if ranking["ta_monthly"].has(type) : monthly_size = ranking["ta_monthly"][type].size() 
	var weekly_size : int = 0
	if ranking["ta_weekly"].has(type) : weekly_size = ranking["ta_weekly"][type].size() 
	
	print("Saving score : ", type + "%" + entry_name)
	# If both backend leaderboards are full
	if total_size == MAX_LEADERBOARD_SIZE[type]:
		print("Total leaderboard is full!")
		var scores : Array = ranking["main"][type].values()
		var last_score : Array = scores[total_size - 1]
		var medium_score : Array = scores[roundi(total_size / 2.0) - 1]

		if score > medium_score[0]: # Medium score (last in "main" leaderboard)
			print("Pushing upper backend leaderboard")
			await SilentWolf.Scores.delete_score(medium_score[4], "main").sw_delete_score_complete
			await SilentWolf.Scores.delete_score(last_score[4], "ta_total2").sw_delete_score_complete
			
			# Move last entry from first backend leaderboard to second
			var medium_entry : String = medium_score[0] + "%" + medium_score[1]
			var medium_meta : Dictionary = {"timestamp" : medium_score[3], "replay" : medium_score[5]}
			await SilentWolf.Scores.save_score(medium_entry,  medium_score[2], "ta_total2", medium_meta).sw_save_score_complete
			
			await SilentWolf.Scores.save_score(save_entry, score, "main", metadata).sw_save_score_complete
		
		elif score > last_score[0]: # Last score (last in "ta_total2" leaderboard)
			print("Pushing lower backend leaderboard")
			await SilentWolf.Scores.delete_score(last_score[4], "ta_total2").sw_delete_score_complete
			await SilentWolf.Scores.save_score(save_entry, score, "ta_total2", metadata).sw_save_score_complete
	
	# If first backend leaderboard is full, but second isn't full yet
	elif total_size > int(MAX_LEADERBOARD_SIZE[type] / 2) and total_size < MAX_LEADERBOARD_SIZE[type]:
		print("Total leaderboard is half-full!")
		var scores : Array = ranking["main"][type].values()
		var medium_score : Array = scores[roundi(MAX_LEADERBOARD_SIZE[type] / 2.0) - 1]

		if score > medium_score[0]: # Medium score (last in "main" leaderboard)
			print("Pushing upper backend leaderboard")
			await SilentWolf.Scores.delete_score(medium_score[4], "main").sw_delete_score_complete
			
			# Move last entry from first backend leaderboard to second
			var medium_entry : String = medium_score[0] + "%" + medium_score[1]
			var medium_meta : Dictionary = {"timestamp" : medium_score[3], "replay" : medium_score[5]}
			await SilentWolf.Scores.save_score(medium_entry, medium_score[2], "ta_total2", medium_meta).sw_save_score_complete
			
			await SilentWolf.Scores.save_score(save_entry, score, "main", metadata).sw_save_score_complete
		
		else:
			print("Apending to lower backend leaderboard")
			await SilentWolf.Scores.save_score(save_entry, score, "ta_total2", metadata).sw_save_score_complete
	# If first backend leaderboard isn't full yet
	else:
		print("Apending to upper backend leaderboard")
		await SilentWolf.Scores.save_score(save_entry, score, "main", metadata).sw_save_score_complete
	
	print("")
	# If backend leaderboard is full
	if monthly_size == int(MAX_LEADERBOARD_SIZE[type] / 2):
		print("Monthly leaderboard is full!")
		var scores : Array = ranking["ta_monthly"][type].values()
		var last_score : Array = scores[monthly_size - 1]
	
		if score > last_score[0]: # Last score (last in "ta_total2" leaderboard)
			print("Pushing backend leaderboard")
			await SilentWolf.Scores.delete_score(last_score[2], "ta_monthly").sw_delete_score_complete
			await SilentWolf.Scores.save_score(save_entry, score, "ta_monthly", metadata).sw_save_score_complete
	else:
		print("Appending to backend leaderboard")
		await SilentWolf.Scores.save_score(save_entry, score, "ta_monthly", metadata).sw_save_score_complete
	
	print("")
	# If backend leaderboard is full
	if weekly_size == int(MAX_LEADERBOARD_SIZE[type] / 2):
		print("Weekly leaderboard is full!")
		var scores : Array = ranking["ta_weekly"][type].values()
		var last_score : Array = scores[weekly_size - 1]

		if score > last_score[0]: # Last score (last in "ta_total2" leaderboard)
			print("Pushing backend leaderboard")
			await SilentWolf.Scores.delete_score(last_score[2], "ta_weekly").sw_delete_score_complete
			await SilentWolf.Scores.save_score(save_entry, score, "ta_weekly", metadata).sw_save_score_complete
	else:
		print("Appending to backend leaderboard")
		await SilentWolf.Scores.save_score(save_entry, score, "ta_weekly", metadata).sw_save_score_complete
	
	score_saved.emit()


func _load_scores(leaderboard : String = "all") -> bool:
	if not is_ready : return false
	
	if leaderboard == "all":
		print("Loading all avaiable leaderboards")
		for i : String in ["ta_total","ta_monthly","ta_weekly"]:
			var success : bool
			success = await _load_scores(i)
			if not success: return false
		print("Success!")
		return true
	
	var unparsed_ranking : Dictionary = {}
	var parsed_ranking : Dictionary = {}
	
	match leaderboard:
		"ta_total" : 
			var start_time : int = Time.get_ticks_msec()
			request_retry_count = 0
			print("Requesting leaderboard : ta_total")
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
			
			var unparsed_ranking2 : Dictionary = {}
			start_time = Time.get_ticks_msec() 
			request_retry_count = 0
			print("Requesting leaderboard : ta_total2")
			
			while true:
				request_retry_count += 1
				if request_retry_count > MAX_REQUEST_RETRY:
					print("All requests failed! Try again in better times...")
					return false
				
				unparsed_ranking2 = await SilentWolf.Scores.get_scores(0, "ta_total2").sw_get_scores_complete
				
				if not unparsed_ranking["success"]:
					print("Error! Leaderboard request failed : ", unparsed_ranking["error"])
					await get_tree().create_timer(REQUEST_RETRY_THRESHOLD).timeout
					print("Trying again...")
				else:
					print("Success!")
					print("Time elapsed:", (Time.get_ticks_msec() - start_time) / 1000.0)
					break
			
			if unparsed_ranking2["scores"].size() > 0:
				unparsed_ranking["scores"].append_array(unparsed_ranking2["scores"])
		
		"ta_monthly" : 
			var start_time : int = Time.get_ticks_msec()
			request_retry_count = 0
			print("Requesting leaderboard : ta_monthly")
			while true:
				request_retry_count += 1
				if request_retry_count > MAX_REQUEST_RETRY:
					print("All requests failed! Try again in better times...")
					return false
				
				unparsed_ranking = await SilentWolf.Scores.get_scores(0, "ta_monthly").sw_get_scores_complete
				
				if not unparsed_ranking["success"]:
					print("Error! Leaderboard request failed : ", unparsed_ranking["error"])
					await get_tree().create_timer(REQUEST_RETRY_THRESHOLD).timeout
					print("Trying again...")
				else:
					print("Success!")
					print("Time elapsed:", (Time.get_ticks_msec() - start_time) / 1000.0)
					break
		"ta_weekly" : 
			var start_time : int = Time.get_ticks_msec()
			request_retry_count = 0
			print("Requesting leaderboard : ta_weekly")
			while true:
				request_retry_count += 1
				if request_retry_count > MAX_REQUEST_RETRY:
					print("All requests failed! Try again in better times...")
					return false
				
				unparsed_ranking = await SilentWolf.Scores.get_scores(0, "ta_weekly").sw_get_scores_complete
				
				if not unparsed_ranking["success"]:
					print("Error! Leaderboard request failed : ", unparsed_ranking["error"])
					await get_tree().create_timer(REQUEST_RETRY_THRESHOLD).timeout
					print("Trying again...")
				else:
					print("Success!")
					print("Time elapsed:", (Time.get_ticks_msec() - start_time) / 1000.0)
					break
		_: 
			print("ERROR! UNKNOWN LEADERBOARD : ", leaderboard)
			return false
	
	print("")
	
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
	
	ranking[leaderboard] = parsed_ranking
	return true


func _delete_score(score_id : String, leaderboard : String) -> void:
	if leaderboard == "ta_total":
		await SilentWolf.Scores.delete_score(score_id, "main").sw_delete_score_complete
		await SilentWolf.Scores.delete_score(score_id, "ta_total2").sw_delete_score_complete
		return
	
	await SilentWolf.Scores.delete_score(score_id, leaderboard).sw_delete_score_complete


func _get_time_left(leaderboard : String) -> int:
	return 99999
