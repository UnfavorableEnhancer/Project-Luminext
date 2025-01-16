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


extends AnimationPlayer

class_name Replay

signal replay_saved
signal replay_loaded

const SCREENSHOT_TIME : float = 10.0
const TICK : float = 1.0 / 120.0
const ALLOWED_SKINS : Array[String] = ["grandmother clock", 
"The Years Will Pass", "Jades", "Panya Malathai", "Protocol", "Disk Sector"]
const MAX_RECORD_TIME : float = 14400 # 4 Hours

enum INVALID {OK, NON_STANDARD_SKIN, UNSUPPORTED_PLAYLIST, GAME_RULES_CHANGED, RECORD_TIME_EXCEEDED, UNSUPPORTED_GAMEMODE}

var game_version : String = ""
var replay_name : String = "Record"
var author : String = "MISSING_NO"
var date : String = "??:??:??"
var preview_image : Texture = null
var gamemode_settings : Dictionary = {} # Contains all gamemode info which is required to play replay back

var screenshot_timer : Timer = null

var emulated_inputs : Dictionary = {
	&"move_left" : false,
	&"move_right" : false,
	&"quick_drop" : false
}
var inputs_anim : Animation = null
var is_valid : int = 0
var current_tick : int = 0

var piece : Piece = null
var queue_shift_call : Callable
var timeline_call : Callable
var music_sync_call : Callable

var is_recording : bool = false
var is_paused : bool = false
var is_playback : bool = false


func _ready() -> void:
	name = "Replay"
	animation_finished.connect(_stop_playback)


func _start_recording() -> void:
	print("STARTED REPLAY RECORDING")
	inputs_anim = Animation.new()
	for idx : int in 7:
		inputs_anim.add_track(Animation.TYPE_METHOD)
		inputs_anim.track_set_path(idx, "Replay")
	
	if Data.game.gamemode != null:
		var gamemode : Gamemode = Data.game.gamemode
		match gamemode.gamemode_name:
			"time_attack_mode" :
				gamemode_settings["name"] = "time_attack_mode"
				gamemode_settings["time_limit"] = gamemode.time_limit
				gamemode_settings["ruleset"] = gamemode.ruleset
				gamemode_settings["mix"] = gamemode.current_mix
				gamemode_settings["seed"] = gamemode.current_seed
				gamemode_settings["state"] = Data.game.rng.state
				gamemode_settings["score"] = 0

				inputs_anim.length = gamemode.time_limit + 1.0
			"playlist_mode":
				if not gamemode.is_single_skin_mode: 
					print("REPLAY RECORDING FAILED! ONLY SINGLE SKIN MODE IS SUPPORTED")
					is_valid = INVALID.UNSUPPORTED_PLAYLIST
					return

				var metadata : SkinMetadata = Data.game.skin.skin_data.metadata
				gamemode_settings["skin_name"] = metadata.name
				gamemode_settings["skin_path"] = metadata.path
				
				if not gamemode_settings["skin_name"] in ALLOWED_SKINS:
					print("REPLAY RECORDING FAILED! NON STANDARD SKIN")
					is_valid = INVALID.NON_STANDARD_SKIN
					return

				gamemode_settings["name"] = "playlist_mode"

				var rules : GameConfigPreset = GameConfigPreset.new()
				rules._store_current_config()
				gamemode_settings["ruleset"] = rules
				Data.profile.gameplay_config_changed.connect(func() -> void: is_valid = INVALID.GAME_RULES_CHANGED)

				gamemode_settings["score"] = 0
				gamemode_settings["time"] = 0
				gamemode_settings["seed"] = gamemode.used_rng_seed

				inputs_anim.length = MAX_RECORD_TIME
			_:
				is_valid = INVALID.UNSUPPORTED_GAMEMODE
				print("ERROR! UNSUPPORTED GAMEMODE")
				return;

	author = Data.profile.name
	date = Time.get_datetime_string_from_system().replace("-",".")
	date = date.split("T")[1] + "  " + date.split("T")[0]

	preview_image = null

	screenshot_timer = Timer.new()
	screenshot_timer.timeout.connect(_take_screenshot)
	screenshot_timer.timeout.connect(screenshot_timer.queue_free)
	Data.game.paused.connect(screenshot_timer.set_paused)
	screenshot_timer.one_shot = true
	add_child(screenshot_timer)
	screenshot_timer.start(SCREENSHOT_TIME + randf_range(-5.0,5.0))
	is_recording = true


func _pause(on : bool) -> void:
	if is_playback:
		if on : pause()
		else : play()
	
	is_paused = on
 

func _reset_replay() -> void:
	is_recording = false
	is_playback = false
	is_paused = false
	
	if is_instance_valid(screenshot_timer): screenshot_timer.queue_free()
	
	seek(0)
	
	emulated_inputs = {
		&"move_left" : false,
		&"move_right" : false,
		&"quick_drop" : false
	}
	current_tick = 0
	piece = null


func _stop_recording() -> void:
	if current_tick > MAX_RECORD_TIME * 120 : is_valid = INVALID.RECORD_TIME_EXCEEDED

	is_recording = false
	is_paused = false
	print("STOPPED REPLAY RECORDING")


func _record_action_press(action_name : StringName) -> void:
	if not is_recording or is_paused: return

	var idx : int
	match action_name:
		&"move_left": idx = 0
		&"move_right": idx = 1
		&"quick_drop": idx = 4
		&"rotate_left": idx = 2
		&"rotate_right": idx = 3
		&"side_ability": idx = 5

	inputs_anim.track_insert_key(idx, current_tick * TICK, {"args": [action_name], "method": &"_press_action"})


func _record_action_release(action_name : StringName) -> void:
	if not is_recording or is_paused: return

	var idx : int
	match action_name:
		&"move_left": idx = 0
		&"move_right": idx = 1
		&"quick_drop": idx = 4

	inputs_anim.track_insert_key(idx, current_tick * TICK, {"args": [action_name], "method": &"_release_action"})


func _record_side_ability() -> void:
	if not is_recording or is_paused: return 
	inputs_anim.track_insert_key(5, current_tick * TICK, {"args": [], "method": &"_queue_shift"})


func _record_timeline_start() -> void:
	if not is_recording or is_paused: return
	inputs_anim.track_insert_key(6, current_tick * TICK, {"args": [], "method": &"_spawn_timeline"})


func _take_screenshot() -> void:
	var image : Image = get_viewport().get_texture().get_image() # We get what our player sees
	image.resize(168, 96)
	var new_texture : ImageTexture = ImageTexture.create_from_image(image)
	preview_image = new_texture


func _spawn_timeline() -> void:
	timeline_call.call()
	music_sync_call.call(current_animation_position)


func _queue_shift() -> void:
	queue_shift_call.call()


func _press_action(action_name : StringName) -> void:
	emulated_inputs[action_name] = true
	piece._emulate_press(action_name)


func _release_action(action_name : StringName) -> void:
	emulated_inputs[action_name] = false
	piece._emulate_release(action_name)


func _start_playback() -> void:
	print("STARTED REPLAY PLAYBACK")
	queue_shift_call = Data.game.piece_queue._shift_queue
	timeline_call = Data.game._create_timeline
	music_sync_call = Data.game.skin._sync_music
	get_animation_library("").add_animation("replay", inputs_anim)
	play("replay")
	is_playback = true


func _stop_playback() -> void:
	stop()
	is_playback = false
	print("FINISHED REPLAY PLAYBACK")


func _save(save_name : String = "", path : String = "", raw_data : bool = false) -> int:
	replay_name = save_name

	print("REPLAY SAVING STARTED...")

	if path.is_empty():
		path = Data.REPLAYS_PATH + save_name + ".rpl"
		path = path.replace(" ","_").to_lower()
	else:
		path = path + save_name + ".rpl"
	
	game_version = Data.VERSION

	var file : FileAccess = FileAccess.open_compressed(path,FileAccess.WRITE,FileAccess.COMPRESSION_DEFLATE)
	if not file: 
		print("FILE ERROR! : ", error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()
	
	file.store_pascal_string(game_version)
	file.store_pascal_string(replay_name)
	file.store_pascal_string(author)
	file.store_pascal_string(date)
	if not raw_data : file.store_var(preview_image,true)
	else : file.store_var(null)
	file.store_var(gamemode_settings,true)
	file.store_var(inputs_anim,true)

	file.close()
	replay_saved.emit()
	print("REPLAY SAVED!")

	return OK


func _load(path : String = "") -> int:
	print("REPLAY LOADING STARTED...")
	
	var file : FileAccess = FileAccess.open_compressed(path,FileAccess.READ,FileAccess.COMPRESSION_DEFLATE)
	if not file: 
		print("FILE ERROR! : ", error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()
	
	game_version = file.get_pascal_string()
	replay_name = file.get_pascal_string()
	author = file.get_pascal_string()
	date = file.get_pascal_string()
	preview_image = file.get_var(true)
	gamemode_settings = file.get_var(true)
	inputs_anim = file.get_var(true)

	file.close()
	replay_loaded.emit()
	print("REPLAY LOADED!")

	return OK
