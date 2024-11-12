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


extends MenuScreen

const RANKING_BAR : PackedScene = preload("res://menu/objects/ranking_bar.tscn")

var selected_time : int = 60
var selected_ruleset : int = TimeAttackMode.TIME_ATTACK_RULESET.STANDARD
var selected_ranking : String = "local"
var ranking_time_left : int = 0

var random_mixes : bool = true


func _ready() -> void:
	Data.menu.screens["background"]._change_gradient_colors(Color("46083e"),Color("291239"),Color("1c0610"),Color("1b1b1b"),Color("0b0205"))
	_select_time(str(Data.profile.config["misc"]["TA_time_limit"]))
	_select_ruleset(Data.profile.config["misc"]["TA_ruleset"])
	$Setup/RandomMixes._set_toggle_by_data(Data.profile.config)
	
	if not Data.menu.is_music_playing:
		Data.menu._change_music("menu_theme")
		if Data.menu.custom_data.has("last_music_pos"):
			Data.menu.music_player.seek(Data.menu.custom_data["last_music_pos"])
	
	Data.total_timer_tick.connect(_count_reset)
	
	await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()
	

func _select_time(time : String) -> void:
	match time:
		"60":
			$Setup/Time/Select.position = Vector2(232,48)
		"120":
			$Setup/Time/Select.position = Vector2(520,48)
		"180":
			$Setup/Time/Select.position = Vector2(808,48)
		"300":
			$Setup/Time/Select.position = Vector2(232,128)
		"600":
			$Setup/Time/Select.position = Vector2(520,128)
		"-42": # Custom sec special variable
			var input : MenuScreen = Data.menu._add_screen("text_input")
			input.desc_text = "Enter your own time limit (from 1 to 9999 secs)"
			input.accept_function = _set_custom_time
			return
		_:
			_set_custom_time(time)

	selected_time = int(time)
	create_tween().tween_property($Setup/Time/Select/Glow,"modulate:a",0.0,0.2).from(1.0)

	Data.profile.config["misc"]["TA_time_limit"] = selected_time
	_show_stats()
	_display_ranking(selected_ranking)


func _count_reset() -> void:
	if ranking_time_left > 0:
		ranking_time_left -= 1
		$Ranking/Timer.text = tr("TA_RESET_IN") + " " + Data._to_time(ranking_time_left)


func _exit_tree() -> void:
	Data._save_global_settings()
	Data.profile._save_config()


func _set_custom_time(time : String) -> void:
	selected_time = clampi(int(time),1,9999)
	Data.profile.config["misc"]["TA_time_limit"] = selected_time
	
	$Setup/Time/Select.position = Vector2(808,128)
	create_tween().tween_property($Setup/Time/Select/Glow,"modulate:a",0.0,0.2).from(1.0)
	$Setup/Time/CUSTOM/Time.text = str(selected_time)

	if selected_time > 999 : $Setup/Time/CUSTOM/Time.label_settings.font_size = 42
	elif selected_time > 1999 : $Setup/Time/CUSTOM/Time.label_settings.font_size = 36
	else: $Setup/Time/CUSTOM/Time.label_settings.font_size = 56
	
	_show_stats()
	_display_ranking(selected_ranking)


func _show_stats() -> void:
	if not selected_time in [60,120,180,300,600]:
		$Playerdata/Hiscore.text = "???"
		$Playerdata/Average.text = "???"
		return

	var entry_string : String
	match selected_ruleset:
		TimeAttackMode.TIME_ATTACK_RULESET.STANDARD: entry_string = str(selected_time) + "sec_standard" 
		TimeAttackMode.TIME_ATTACK_RULESET.CLASSIC: entry_string = str(selected_time) + "sec_classic" 
		TimeAttackMode.TIME_ATTACK_RULESET.ARCADE: entry_string = str(selected_time) + "sec_arcade" 
		TimeAttackMode.TIME_ATTACK_RULESET.COLOR_3: entry_string = str(selected_time) + "sec_3color" 
		TimeAttackMode.TIME_ATTACK_RULESET.HARDCORE: entry_string = str(selected_time) + "sec_hardcore" 
	
	if Data.profile.progress["time_attack_hiscore"].has(entry_string) and Data.profile.progress["time_attack_hiscore"][entry_string] > 0:
		$Playerdata/Hiscore.text = str(Data.profile.progress["time_attack_hiscore"][entry_string])
	else:
		$Playerdata/Hiscore.text = "---"

	var average_count : int = 0
	var total : int = 0
	for i : Array in Data.global_settings[entry_string + "_ranking"]:
		if i[0] == Data.profile.name:
			average_count += 1
			total += i[1]
	
	if average_count > 0:
		$Playerdata/Average.text = str(roundi(float(total) / average_count))
	else:
		$Playerdata/Average.text = "---"


func _display_ranking(type : String) -> void:
	selected_ranking = type

	for i : Node in $Ranking/S/V.get_children():
		i.queue_free()
	
	if not selected_time in [60,120,180,300,600]:
		$Ranking/Deny.visible = true
		return
	$Ranking/Deny.visible = false
	$Ranking/Timer.visible = false

	var entry_string : String
	match selected_ruleset:
		TimeAttackMode.TIME_ATTACK_RULESET.STANDARD: entry_string = str(selected_time) + "std" 
		TimeAttackMode.TIME_ATTACK_RULESET.CLASSIC: entry_string = str(selected_time) + "cls" 
		TimeAttackMode.TIME_ATTACK_RULESET.ARCADE: entry_string = str(selected_time) + "arc" 
		TimeAttackMode.TIME_ATTACK_RULESET.COLOR_3: entry_string = str(selected_time) + "thr" 
		TimeAttackMode.TIME_ATTACK_RULESET.HARDCORE: entry_string = str(selected_time) + "hrd" 
	
	match type:
		"local" :
			match selected_ruleset:
				TimeAttackMode.TIME_ATTACK_RULESET.STANDARD: entry_string = str(selected_time) + "sec_standard" 
				TimeAttackMode.TIME_ATTACK_RULESET.CLASSIC: entry_string = str(selected_time) + "sec_classic" 
				TimeAttackMode.TIME_ATTACK_RULESET.ARCADE: entry_string = str(selected_time) + "sec_arcade" 
				TimeAttackMode.TIME_ATTACK_RULESET.COLOR_3: entry_string = str(selected_time) + "sec_3color" 
				TimeAttackMode.TIME_ATTACK_RULESET.HARDCORE: entry_string = str(selected_time) + "sec_hardcore" 

			var local_ranking : Array = Data.global_settings[entry_string + "_ranking"]
			local_ranking.sort_custom(func(a : Array, b : Array) -> bool: return a[1] > b[1])

			# Calculate current user average and display leaderboard
			var count : int = 0
			for i : Array in local_ranking:
				count += 1
				var rank : MenuSelectableButton = RANKING_BAR.instantiate()
				rank.pos = count
				rank.author = i[0]
				rank.score = i[1]
				rank.datetime = i[2]
				$Ranking/S/V.add_child(rank)
				_assign_selectable(rank,Vector2i(3,count))
			
			$Ranking/Detail4.text = "LOCAL SCORE RANKING"
			var tween : Tween = create_tween().set_parallel(true)
			tween.tween_property($Ranking/Back, "color", Color("cab45c1a"), 0.1)
			tween.tween_property($Ranking/Detail4, "visible_ratio", 1.0, 0.1).from(0.0)
			
		"total" :
			$Ranking/Detail4.text = "ONLINE SCORE RANKING"
			var tween : Tween = create_tween().set_parallel(true)
			tween.tween_property($Ranking/Back, "color", Color("ca5fcd1a"), 0.1)
			tween.tween_property($Ranking/Detail4, "visible_ratio", 1.0, 0.1).from(0.0)
			return
			
			var success : bool = Data.ranking_manager._load_score("ta_total")
			if not success : return
			
			var current_ranking : Dictionary = Data.ranking_manager.ranking["ta_total"][entry_string]

			var count : int = 0
			for player_name : String in current_ranking:
				count += 1
				var data : Array = current_ranking[player_name]
				var rank : MenuSelectableButton = RANKING_BAR.instantiate()
				rank.pos = count
				rank.author = player_name.get_slice("_",0)
				rank.score = data[0]
				rank.datetime = data[1]
				rank.call_function_name = "_start_replay"
				rank.call_string = data[4]
				$Ranking/S/V.add_child(rank)
				_assign_selectable(rank,Vector2i(3,count))
			
		"monthly" :
			$Ranking/Detail4.text = "MONTHLY SCORE RANKING"
			var tween : Tween = create_tween().set_parallel(true)
			tween.tween_property($Ranking/Back, "color", Color("dd54541a"), 0.1)
			tween.tween_property($Ranking/Detail4, "visible_ratio", 1.0, 0.1).from(0.0)
			
			ranking_time_left = Data.ranking_manager._get_time_left("ta_monthly")
			$Ranking/Timer.visible = true
			return
			
			Data.ranking_manager._load_score("ta_monthly")
			var current_ranking : Dictionary = Data.ranking_manager.ranking["ta_monthly"][entry_string]

			var count : int = 0
			for player_name : String in current_ranking:
				count += 1
				var data : Array = current_ranking[player_name]
				var rank : MenuSelectableButton = RANKING_BAR.instantiate()
				rank.pos = count
				rank.author = player_name.get_slice("_",0)
				rank.score = data[0]
				rank.datetime = data[1]
				rank.replay_bytes = data[4]
				$Ranking/S/V.add_child(rank)
				_assign_selectable(rank,Vector2i(3,count))
			
		"weekly" :
			$Ranking/Detail4.text = "WEEKLY SCORE RANKING"
			var tween : Tween = create_tween().set_parallel(true)
			tween.tween_property($Ranking/Back, "color", Color("5cca991a"), 0.1)
			tween.tween_property($Ranking/Detail4, "visible_ratio", 1.0, 0.1).from(0.0)
			
			ranking_time_left = Data.ranking_manager._get_time_left("ta_weekly")
			$Ranking/Timer.visible = true
			return
			
			Data.ranking_manager._load_score("ta_weekly")
			var current_ranking : Dictionary = Data.ranking_manager.ranking["ta_weekly"][entry_string]

			var count : int = 0
			for player_name : String in current_ranking:
				count += 1
				var data : Array = current_ranking[player_name]
				var rank : MenuSelectableButton = RANKING_BAR.instantiate()
				rank.pos = count
				rank.author = player_name.get_slice("_",0)
				rank.score = data[0]
				rank.datetime = data[1]
				rank.replay_bytes = data[4]
				$Ranking/S/V.add_child(rank)
				_assign_selectable(rank,Vector2i(3,count))


func _select_ruleset(value : float) -> void:
	selected_ruleset = int(value)
	$Setup/Rulesets/Slider.value = value

	match int(value):
		TimeAttackMode.TIME_ATTACK_RULESET.STANDARD: 
			$Setup/Rulesets/Slider/Power.text = tr("TA_STANDARD") 
			$Setup/Rulesets/Slider.description = tr("TA_STANDARD_DESC")
			$Desc/Desc.text = tr("TA_STANDARD_DESC")
		TimeAttackMode.TIME_ATTACK_RULESET.CLASSIC: 
			$Setup/Rulesets/Slider/Power.text = tr("TA_CLASSIC")
			$Setup/Rulesets/Slider.description = tr("TA_CLASSIC_DESC")
			$Desc/Desc.text = tr("TA_CLASSIC_DESC")
		TimeAttackMode.TIME_ATTACK_RULESET.ARCADE: 
			$Setup/Rulesets/Slider/Power.text = tr("TA_ARCADE") 
			$Setup/Rulesets/Slider.description = tr("TA_ARCADE_DESC")
			$Desc/Desc.text = tr("TA_ARCADE_DESC")
		TimeAttackMode.TIME_ATTACK_RULESET.COLOR_3: 
			$Setup/Rulesets/Slider/Power.text = tr("TA_3_COLOR")
			$Setup/Rulesets/Slider.description = tr("TA_3_COLOR_DESC")
			$Desc/Desc.text = tr("TA_3_COLOR_DESC")
		TimeAttackMode.TIME_ATTACK_RULESET.HARDCORE: 
			$Setup/Rulesets/Slider/Power.text = tr("TA_EXPERT")
			$Setup/Rulesets/Slider.description = tr("TA_EXPERT_DESC")
			$Desc/Desc.text = tr("TA_EXPERT_DESC")
	
	Data.profile.config["misc"]["TA_ruleset"] = selected_ruleset
	_show_stats()
	_display_ranking(selected_ranking)


func _start_game() -> void:
	var ta_skin_metadata : SkinMetadata = SkinMetadata.new()
	if selected_time < 300:
		ta_skin_metadata.path = Data.BUILD_IN_PATH + Data.SKINS_PATH + "grandmother_clock.skn"
	if selected_time >= 300:
		ta_skin_metadata.path = Data.BUILD_IN_PATH + Data.SKINS_PATH + "the_years_will_pass.skn"
	
	if Data.menu.is_music_playing:
		Data.menu.custom_data["last_music_pos"] = Data.menu.music_player.get_playback_position()
	
	var sound_delay : float = 0.75
	var sec_sound : AudioStreamPlayer = null
	match selected_time:
		60 : sec_sound = menu._sound("announce_60sec",null,false)
		120 : sec_sound = menu._sound("announce_120sec",null,false); sound_delay = 0.8
		180 : sec_sound = menu._sound("announce_180sec",null,false)
		300 : sec_sound = menu._sound("announce_300sec",null,false); sound_delay = 0.95
		600 : sec_sound = menu._sound("announce_600sec",null,false); sound_delay = 0.95
		_: sec_sound = menu._sound("announce_custom_sec",null,false)
	
	var mode_sound : AudioStreamPlayer = null
	match selected_ruleset:
		TimeAttackMode.TIME_ATTACK_RULESET.STANDARD: mode_sound = menu._sound("announce_standard",null,false)
		TimeAttackMode.TIME_ATTACK_RULESET.CLASSIC: mode_sound = menu._sound("announce_classic",null,false)
		TimeAttackMode.TIME_ATTACK_RULESET.ARCADE: mode_sound = menu._sound("announce_arcade",null,false)
		TimeAttackMode.TIME_ATTACK_RULESET.COLOR_3: mode_sound = menu._sound("announce_3color",null,false)
		TimeAttackMode.TIME_ATTACK_RULESET.HARDCORE: mode_sound = menu._sound("announce_expert",null,false)
	
	get_tree().create_timer(sound_delay).timeout.connect(mode_sound.play)
	sec_sound.play()
	
	var gamemode : TimeAttackMode = TimeAttackMode.new()
	gamemode.time_limit = selected_time
	gamemode.ruleset = selected_ruleset
	gamemode.random_mixes = Data.profile.config["misc"]["TA_random_mixes"]
	
	Data.main._start_game(ta_skin_metadata, gamemode)


func _start_replay(replay_data : String) -> void:
	var dialog : MenuScreen = menu._add_screen("accept_dialog")
	dialog.desc_text = tr("TA_REPLAY_DIALOG")
	var accepted : bool = await dialog.closed

	if not accepted : return
	
	var temp_file : FileAccess = FileAccess.open(Data.CACHE_PATH + "temp.rpl", FileAccess.WRITE)
	if FileAccess.get_open_error() != OK:
		print("ERROR! Opening online replay failed...")
		return

	var buffer : PackedByteArray = replay_data.to_utf8_buffer()
	temp_file.store_buffer(buffer)

	var replay : Replay = Replay.new()
	replay._load(Data.CACHE_PATH + "temp.rpl")
	Data.main._start_replay(replay)
