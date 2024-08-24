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
	
	#_show_selected_stats()
	
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
			input.object_to_call = self
			input.call_function_name = "_set_custom_time"
			input._start()
			return
		_:
			_set_custom_time(time)

	selected_time = int(time)
	create_tween().tween_property($Setup/Time/Select/Glow,"modulate:a",0.0,0.2).from(1.0)

	Data.profile.config["misc"]["TA_time_limit"] = selected_time
	_show_selected_stats()


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
	
	_show_selected_stats()


func _show_selected_stats() -> void:
	for i : Node in $Ranking/S/V.get_children():
		i.queue_free()
	
	if not selected_time in [60,120,180,300,600]:
		$Playerdata/Hiscore.text = "???"
		$Playerdata/Average.text = "???"
		$Ranking/Deny.visible = true
		return
	
	$Ranking/Deny.visible = false
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

	var local_ranking : Array = Data.global_settings[entry_string + "_ranking"]
	local_ranking.sort_custom(func(a : Array, b : Array) -> bool: return a[1] > b[1])

	# Calculate current user average and display leaderboard
	var count : int = 0
	var average_count : int = 0
	var total : int = 0
	for i : Array in local_ranking:
		count += 1
		if i[0] == Data.profile.name:
			average_count += 1
			total += i[1]

		var rank : MenuSelectableButton = RANKING_BAR.instantiate()
		rank.pos = count
		rank.author = i[0]
		rank.score = i[1]
		rank.datetime = i[2]
		rank.menu_position = Vector2i(-1,-1)
		$Ranking/S/V.add_child(rank)
	
	if average_count > 0:
		$Playerdata/Average.text = str(roundi(float(total) / average_count))
	else:
		$Playerdata/Average.text = "---"
	

func _select_ruleset(value : float) -> void:
	selected_ruleset = int(value)
	$Setup/Rulesets/Slider.value = value

	match int(value):
		TimeAttackMode.TIME_ATTACK_RULESET.STANDARD: 
			$Setup/Rulesets/Slider/Power.text = "STANDARD" 
			$Setup/Rulesets/Slider.description = "Standard Luminext time attack rules. Features piece position saving, piece swapping, and only merge special block is avaiable."
			$Desc/Desc.text = "Standard Luminext time attack rules. Features piece position saving, piece swapping, and only merge special block is avaiable."
		TimeAttackMode.TIME_ATTACK_RULESET.CLASSIC: 
			$Setup/Rulesets/Slider/Power.text = "CLASSIC" 
			$Setup/Rulesets/Slider.description = "Classic Lumines time attack rules. No position saving, piece swapping, and only chain special block is avaiable."
			$Desc/Desc.text = "Classic Lumines time attack rules. No position saving, piece swapping, and only chain special block is avaiable."
		TimeAttackMode.TIME_ATTACK_RULESET.ARCADE: 
			$Setup/Rulesets/Slider/Power.text = "ARCADE" 
			$Setup/Rulesets/Slider.description = "Same as standard, but all 4 main special blocks + multi block are avaiable and appear frequently."
			$Desc/Desc.text = "Same as standard, but all 4 main special blocks + multi block are avaiable and appear frequently."
		TimeAttackMode.TIME_ATTACK_RULESET.COLOR_3: 
			$Setup/Rulesets/Slider/Power.text = "3 COLOR" 
			$Setup/Rulesets/Slider.description = "Same as standard but features 3 block colors instead of 2. Also multi and wipe special blocks are avaiable."
			$Desc/Desc.text = "Same as standard but features 3 block colors instead of 2. Also only wipe special block is avaiable."
		TimeAttackMode.TIME_ATTACK_RULESET.HARDCORE: 
			$Setup/Rulesets/Slider/Power.text = "EXPERT" 
			$Setup/Rulesets/Slider.description = "Hard rules featuring garbage and chaos blocks. Also only laser special block is avaiable."
			$Desc/Desc.text = "Hard rules featuring garbage and chaos blocks. Also only laser special block is avaiable."
	
	Data.profile.config["misc"]["TA_ruleset"] = selected_ruleset
	_show_selected_stats()


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
