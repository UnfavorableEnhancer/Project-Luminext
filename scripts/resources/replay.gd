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


extends Node

class_name Replay

@warning_ignore("unused_signal") # Ignored because is used via "call_deferred"
signal io_progress(progress : int)
signal replay_saved
signal replay_loaded
signal playback_finished
signal start_timers

const SCREENSHOT_TIME : float = 10.0
const TIMER_BUFFER_COUNT : int = 999

var replay_name : String = "Record"
var author : String = "MISSING_NO"
var date : String = "??:??:??"
var preview_image : Texture = null

var gamemode_settings : Dictionary = {} # Contains all gamemode info which is required to play replay back

var inputs : PackedStringArray = PackedStringArray() # All recorded action names
var input_lengths : PackedInt64Array = PackedInt64Array() # All recorded pressed input lenghts before release
var input_starts : PackedInt64Array = PackedInt64Array() # All recorded input press time stamps

var record_buffer : Dictionary = {} # Key = Action name : Press time stamp
var replay_start_time : int = 0 # When replay recording/playback started
var current_playback_position : int = 0

var pause_time : int = 0

var piece : Piece = null

var current_inputs : Dictionary = {
	&"move_left" : false,
	&"move_right" : false,
	&"quick_drop" : false
}

var is_playing : bool = false
var is_recording : bool = false
var is_paused : bool = false

var timers : Array[Timer] = []


func _ready() -> void:
	name = "Replay"


func _add_timer(time : float, function : Callable) -> Timer:
	if time < 0 : return

	var timer : Timer = Timer.new()
	timers.append(timer)

	timer.timeout.connect(function)
	timer.timeout.connect(timer.queue_free)
	timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	Data.game.paused.connect(timer.set_paused)
	
	timer.one_shot = true
	add_child(timer)
	start_timers.connect(timer.start.bind(time))

	return timer


func _clear_timers() -> void:
	while not timers.is_empty():
		var timer : Variant = timers.pop_back()
		if is_instance_valid(timer): timer.queue_free()


func _start_recording() -> void:
	record_buffer.clear()
	gamemode_settings.clear()

	inputs.clear()
	input_lengths.clear()
	input_starts.clear()

	current_playback_position = 0
	replay_start_time = 0
	
	_clear_timers()

	print("STARTED REPLAY RECORDING")

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
			_:
				print("ERROR! UNSUPPORTED GAMEMODE")
				return;

	author = Data.profile.name
	date = Time.get_datetime_string_from_system().replace("-",".")
	date = date.split("T")[1] + "  " + date.split("T")[0]

	preview_image = null
	
	_add_timer(SCREENSHOT_TIME + randf_range(-5.0,5.0), _take_screenshot)
	start_timers.emit()

	replay_start_time = Time.get_ticks_usec()
	is_recording = true


func _pause(on : bool) -> void:
	if on : pause_time = Time.get_ticks_usec()
	else : replay_start_time += Time.get_ticks_usec() - pause_time
	is_paused = on

	for timer : Variant in timers : 
		if is_instance_valid(timer) : timer.paused = on
  

func _stop_recording() -> void:
	is_recording = false
	is_paused = false
	
	print("STOPPED REPLAY RECORDING")
	_clear_timers()


func _record_action_press(action_name : StringName) -> void:
	if not is_recording or is_paused: return
	record_buffer[action_name] = Time.get_ticks_usec()


func _record_action_release(action_name : StringName) -> void:
	if not is_recording or is_paused: return
	
	var time_stamp : int = record_buffer.get(action_name, -1)
	if time_stamp == -1 : return

	inputs.append(action_name)
	input_starts.append(time_stamp - replay_start_time)
	input_lengths.append(Time.get_ticks_usec() - time_stamp)

	record_buffer.erase(action_name)
	current_playback_position += 1


func _record_timeline_start() -> void:
	if not is_recording or is_paused: return
	inputs.append("timeline")
	input_starts.append(Time.get_ticks_usec() - replay_start_time)
	input_lengths.append(-1)


func _take_screenshot() -> void:
	var image : Image = get_viewport().get_texture().get_image() # We get what our player sees
	image.resize(168, 96)
	var new_texture : ImageTexture = ImageTexture.create_from_image(image)
	preview_image = new_texture


func _press_action(action_name : StringName) -> void:
	if action_name == "timeline" :
		Data.game._start_timeline()
		return

	piece._emulate_press(action_name)
	current_inputs[action_name] = true


func _release_action(action_name : StringName) -> void:
	piece._emulate_release(action_name)
	current_inputs[action_name] = false


func _start_playback() -> void:
	print("STARTED REPLAY PLAYBACK")
	is_playing = true

	_clear_timers()

	current_playback_position = 0
	replay_start_time = Time.get_ticks_usec()

	for i : int in inputs.size():
		var action_name : String = inputs[i]
		var action_start : float = input_starts[i]  / 1000000.0
		var action_length : float = input_lengths[i] / 1000000.0
		_add_timer(action_start, _press_action.bind(action_name))
		_add_timer(action_start + action_length, _release_action.bind(action_name))
	
	start_timers.emit()


func _stop_playback() -> void:
	print("FINISHED REPLAY PLAYBACK")
	playback_finished.emit()
	is_playing = false

	_clear_timers()


func _save(save_name : String = "") -> int:
	replay_name = save_name

	print("REPLAY SAVING STARTED...")
	call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.SAVING_REPLAY)
	
	var path : String
	path = Data.REPLAYS_PATH + save_name + ".rec"
	path = path.replace(" ","_").to_lower()
	
	var file : FileAccess = FileAccess.open_compressed(path,FileAccess.WRITE,FileAccess.COMPRESSION_DEFLATE)
	if not file: 
		print("FILE ERROR! : ", error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()
	
	file.store_pascal_string(replay_name)
	file.store_pascal_string(author)
	file.store_pascal_string(date)
	file.store_var(preview_image,true)
	file.store_var(gamemode_settings,true)

	file.store_var(inputs,true)
	file.store_var(input_lengths,true)
	file.store_var(input_starts,true)

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
	
	replay_name = file.get_pascal_string()
	author = file.get_pascal_string()
	date = file.get_pascal_string()
	preview_image = file.get_var(true)
	gamemode_settings = file.get_var(true)

	inputs = file.get_var(true)
	input_lengths = file.get_var(true)
	input_starts = file.get_var(true)

	file.close()
	replay_loaded.emit()
	print("REPLAY LOADED!")

	return OK
