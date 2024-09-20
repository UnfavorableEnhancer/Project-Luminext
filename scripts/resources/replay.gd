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

const SCREENSHOT_TIME : float = 10.0
const TIMER_BUFFER_COUNT : int = 400

var replay_name : String = "Record"
var author : String = "MISSING_NO"
var date : float = 0.0
var preview_image : Texture = null

var gamemode_settings : Dictionary = {}

var inputs : PackedStringArray = PackedStringArray() # All recorded action names
var input_lengths : PackedInt64Array = PackedInt64Array() #
var input_starts : PackedInt64Array = PackedInt64Array() #

var record_buffer : Dictionary = {} # Key = Action name : Time stamp
var replay_start_time : int = 0
var current_playback_position : int = 0
var latest_start_stamp : float = 0.0

var piece : Piece = null

var current_inputs : Dictionary = {
	"move_left" : false,
	"move_right" : false,
	"quick_drop" : false
}

var is_playing : bool = false
var is_recording : bool = false
var is_paused : bool = false

var timers : Array[Timer] = []


func _ready() -> void:
	name = "Replay"


func _connect_piece() -> void:
	piece = Data.game.piece
	piece.emulated_inputs = current_inputs


func _add_timer(time : float, function : Callable) -> Timer:
	var timer : Timer = Timer.new()
	timers.append(timer)

	timer.timeout.connect(function)
	timer.timeout.connect(timer.queue_free)
	
	timer.one_shot = true
	add_child(timer)
	timer.start(time)

	return timer


func _clear_timers() -> void:
	while not timers.is_empty():
		var timer : Variant = timers.pop_back()
		if is_instance_valid(timer): timer.queue_free()


func _start_recording() -> void:
	record_buffer.clear()
	gamemode_settings.clear()
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
	date = Time.get_unix_time_from_system()
	preview_image = null
	
	_clear_timers()

	inputs.clear()
	input_lengths.clear()
	input_starts.clear()

	_add_timer(SCREENSHOT_TIME , _take_screenshot) #+ randf_range(-5.0,5.0)

	replay_start_time = Time.get_ticks_msec()
	is_recording = true


func _pause(on : bool) -> void:
	is_paused = on
	for timer : Variant in timers : 
		if is_instance_valid(timer) : timer.paused = on
  

func _stop_recording() -> void:
	is_recording = false
	is_paused = false
	
	print("STOPPED REPLAY RECORDING")
	_clear_timers()


func _process(_delta : float) -> void:
	if not is_recording or is_paused : return

	var current_tick : int = Time.get_ticks_msec()

	for action_name : StringName in [&"move_left",&"move_right",&"rotate_left",&"rotate_right",&"quick_drop",&"side_ability"]:
		if Input.is_action_just_pressed(action_name):
			record_buffer[action_name] = current_tick
		
		if Input.is_action_just_released(action_name):
			var time_stamp : int = record_buffer.get(action_name, 0)
			if time_stamp == 0 : continue

			inputs.append(action_name)
			input_starts.append(time_stamp - replay_start_time)
			input_lengths.append(current_tick - time_stamp)

			record_buffer.erase(action_name)
			current_playback_position += 1


func _take_screenshot() -> void:
	var image : Image = get_viewport().get_texture().get_image() # We get what our player sees
	image.resize(168, 96)
	var new_texture : ImageTexture = ImageTexture.create_from_image(image)
	preview_image = new_texture


func _press_action(action_name : StringName) -> void:
	piece._emulate_press(action_name)
	current_inputs[action_name] = true


func _release_action(action_name : StringName) -> void:
	piece._emulate_release(action_name)
	current_inputs[action_name] = false


func _start_playback() -> void:
	print("STARTED REPLAY PLAYBACK")
	is_playing = true

	Data.game.is_input_locked = true
	Data.game.new_piece_is_given.connect(_connect_piece)
	piece = Data.game.piece

	_clear_timers()

	current_playback_position = 0
	replay_start_time = Time.get_ticks_msec()

	_playback()


func _playback() -> void:
	var action_start : float

	for i : int in TIMER_BUFFER_COUNT:
		if current_playback_position > inputs.size() - 1:
			return

		var action_name : String = inputs[current_playback_position]
		var action_length : float = input_lengths[current_playback_position] / 1000.0
		action_start = input_starts[current_playback_position] / 1000.0 - latest_start_stamp
		
		_add_timer(action_start, func x() -> void: _press_action(action_name); _add_timer(action_length, _release_action.bind(action_name)))
		current_playback_position += 1

	latest_start_stamp = input_starts[current_playback_position] / 1000.0 
	await get_tree().create_timer(action_start).timeout
	_playback()
	

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
	file.store_float(date)
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
	date = file.get_float()
	preview_image = file.get_var(true)
	gamemode_settings = file.get_var(true)

	inputs = file.get_var(true)
	input_lengths = file.get_var(true)
	input_starts = file.get_var(true)

	file.close()
	replay_loaded.emit()
	print("REPLAY LOADED!")

	return OK
