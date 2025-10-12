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


extends Node

#-----------------------------------------------------------------------
# Contains game replay data, which allows to recreate all actions and events player has made during gameplay
#-----------------------------------------------------------------------

class_name Replay

signal saved ## Emitted when replay save finished
signal loaded ## Emitted when replay load finished

## Enum of all possible replay save errors
enum REPLAY_ERROR {
	OK, 
	UNSUPPORTED_SKIN, ## Currently playing skin is not allowed
	NOT_IN_SINGLE_SKIN, ## Not in single skin mode
	UNSUPPORTED_ADVENTURE, ## Currently playing adventure is not supported
	UNSUPPORTED_GAMEMODE, ## Currently playing gamemode is not supported
	RULESET_CHANGED, ## Ruleset was changed during playlist/synthesia mode gameplay
	SOFT_RESET_OCCURED, ## Game was soft resetted
	RECORD_TIME_EXCEEDED, ## Record time has exceeded
}

## All bits stored into first replay byte
enum REPLAY_BYTE1{
	MOVE_LEFT = 0x01,
	MOVE_RIGHT = 0x02,
	QUICK_DROP = 0x04,
	INSTANT_DROP = 0x08,
	ROTATE_LEFT = 0x10,
	ROTATE_RIGHT = 0x20,
	SPECIAL_ABILITY1 = 0x40,
	SPECIAL_ABILITY2 = 0x80,
}

## All bits stored into second replay byte
enum REPLAY_BYTE2{
	MUSIC_BEAT = 0x01,
	SPECIAL_ABILITY3 = 0x02,
	SPECIAL_ABILITY4 = 0x04,
	RESERVED1 = 0x08,
	RESERVED2 = 0x10,
	RESERVED3 = 0x20,
	RESERVED4 = 0x40,
	RESERVED5 = 0x80,
}

const SCREENSHOT_TIME : float = 10.0 ## Amount of time before replay screenshot is taken

## Replay is allowed to be saved only when skins listed here are played
const ALLOWED_SKINS : Array[String] = [
	"grandmother clock", 
	"The Years Will Pass", 
	"Jades", 
	"Panya Malathai", 
	"Protocol", 
	"Disk Sector",
	"holding patterns",
	"Spiteless Mind",
]

var game : GameCore ## Game core instance

var game_version : String = "" ## Stores game version on which this replay was recorded
var replay_name : String = "Record" ## Replay name
var author : String = "MISSING_NO" ## Profile name of one who recorded the replay
var date : String = "??:??:??" ## Replay save date
var preview_image : Texture = null ## Replay preview screenshot
var game_info : Dictionary = {} ## Contains all game info which is required for replay playback

var screenshot_timer : Timer = null ## Timer which makes replay preview screenshot

var first_replay_array : PackedByteArray ## Contains all recorded replay bytes which contain input presses and game events
var second_replay_array : PackedByteArray ## Second replay bytes array
var latest_first_replay_byte : int = 0
var latest_second_replay_byte : int = 0

var current_tick : int = 0 ## Current replay playback/record tick

var error_code : int = 0 ## Replay error code

var is_recording : bool = false ## True if replay is currently recording
var is_playing : bool = false ## True if replay is currently playing
var is_paused : bool = false ## True if replay recording is paused


func _ready() -> void:
	name = "Replay"


# Starts replay recording [br]
# Works only in [TimeAttackMode] and in [PlaylistMode] if [b]'single_skin_mode'[/b] is true
func _start_recording() -> void:
	Console._log("Starting replay recording")

	game_info["gamecore"] = game.gamecore_name

	var gamemode : Gamemode = game.gamemode
	match gamemode.gamemode_name:
		"time_attack_mode" :
			game_info["gamemode"] = "time_attack_mode"
			game_info["time_limit"] = gamemode.time_limit
			game_info["ruleset"] = gamemode.ruleset
			game_info["mix"] = gamemode.current_mix
			game_info["seed"] = gamemode.current_seed
			game_info["score"] = 0

		"playlist_mode":
			game_info["gamemode"] = "playlist_mode"
			game_info["seed"] = gamemode.rng_start_seed

			if not gamemode.is_single_skin_mode: 
				Console._log("Replay recording failed. Not in single skin mode.")
				error_code = REPLAY_ERROR.NOT_IN_SINGLE_SKIN
				return
			
			game_info["skin_id"] = game.skin.skin_data.metadata.id
			
			if not game.skin.skin_data.metadata.name in ALLOWED_SKINS:
				Console._log("Replay recording failed. Loaded skin isn't standard.")
				error_code = REPLAY_ERROR.UNSUPPORTED_SKIN
				return
			
			game_info["blocks"] = Player.config.user_ruleset.blocks
			game_info["rules"] = Player.config.user_ruleset.rules
			game_info["params"] = Player.config.user_ruleset.params
			Player.config.user_ruleset.changed.connect(func() -> void: error_code = REPLAY_ERROR.RULESET_CHANGED)
		_:
			error_code = REPLAY_ERROR.UNSUPPORTED_GAMEMODE
			Console._log("Replay recording failed. This gamemode is not supported.")
			return;

	author = Player.profile_name
	date = Time.get_datetime_string_from_system().replace("-",".")
	date = date.split("T")[1] + "  " + date.split("T")[0]

	preview_image = null
	screenshot_timer = Timer.new()
	screenshot_timer.timeout.connect(_take_screenshot)
	screenshot_timer.timeout.connect(screenshot_timer.queue_free)
	game.paused.connect(screenshot_timer.set_paused)
	screenshot_timer.one_shot = true
	add_child(screenshot_timer)
	screenshot_timer.start(SCREENSHOT_TIME + randf_range(-5.0,5.0))

	current_tick = 0
	
	is_recording = true


## Starts replay playback
func _start_playback() -> void:
	Console._log("Started replay playback")
	current_tick = 0
	is_playing = true


## Pauses replay playback/recording
func _pause(on : bool) -> void:
	is_paused = on
 

## Resets replay playback/recording to the beginning
func _reset_replay() -> void:
	if is_recording:
		first_replay_array.clear()
		second_replay_array.clear()
		latest_first_replay_byte = 0
		latest_second_replay_byte = 0
		is_recording = false
	
	is_playing = false
	is_paused = false
	
	if is_instance_valid(screenshot_timer): screenshot_timer.queue_free()
	
	current_tick = 0
	error_code = OK


## Stops replay recording
func _stop_recording() -> void:
	is_recording = false
	Console._log("Finished replay recording.")


## Stops replay playback
func _stop_playback() -> void:
	is_playing = false
	Console._log("Finished replay playback")


## Takes low resolution game screenshot for preview image
func _take_screenshot() -> void:
	var image : Image = get_viewport().get_texture().get_image() # We get what our player sees
	image.resize(168, 96)
	var new_texture : ImageTexture = ImageTexture.create_from_image(image)
	preview_image = new_texture


## Processes replay playback or recording
func _tick() -> void:
	if is_paused : return

	current_tick += 1
	if is_recording:
		var new_first_input_byte : int = latest_first_replay_byte
		var new_second_input_byte : int = latest_second_replay_byte

		if Input.is_action_just_pressed("move_left") : new_first_input_byte = new_first_input_byte | REPLAY_BYTE1.MOVE_LEFT
		if Input.is_action_just_pressed("move_right") : new_first_input_byte = new_first_input_byte | REPLAY_BYTE1.MOVE_RIGHT
		if Input.is_action_just_pressed("quick_drop") : new_first_input_byte = new_first_input_byte | REPLAY_BYTE1.QUICK_DROP
		if Input.is_action_just_pressed("rotate_left") : new_first_input_byte = new_first_input_byte | REPLAY_BYTE1.ROTATE_LEFT
		if Input.is_action_just_pressed("rotate_right") : new_first_input_byte = new_first_input_byte | REPLAY_BYTE1.ROTATE_RIGHT
		if Input.is_action_just_pressed("side_ability") : new_first_input_byte = new_first_input_byte | REPLAY_BYTE1.SPECIAL_ABILITY1

		if game.skin.beat_was_passed : new_second_input_byte = new_second_input_byte | REPLAY_BYTE2.MUSIC_BEAT

		if Input.is_action_just_released("move_left") : new_first_input_byte = new_first_input_byte & (~REPLAY_BYTE1.MOVE_LEFT)
		if Input.is_action_just_released("move_right") : new_first_input_byte = new_first_input_byte & (~REPLAY_BYTE1.MOVE_RIGHT)
		if Input.is_action_just_released("quick_drop") : new_first_input_byte = new_first_input_byte & (~REPLAY_BYTE1.QUICK_DROP)
		if Input.is_action_just_released("rotate_left") : new_first_input_byte = new_first_input_byte & (~REPLAY_BYTE1.ROTATE_LEFT)
		if Input.is_action_just_released("rotate_right") : new_first_input_byte = new_first_input_byte & (~REPLAY_BYTE1.ROTATE_RIGHT)
		if Input.is_action_just_released("side_ability") : new_first_input_byte = new_first_input_byte & (~REPLAY_BYTE1.SPECIAL_ABILITY1)

		latest_first_replay_byte = new_first_input_byte
		latest_second_replay_byte = new_second_input_byte

		first_replay_array.append(new_first_input_byte)
		second_replay_array.append(new_second_input_byte)
	
	if is_playing:
		var current_first_input_byte : int = first_replay_array[current_tick]
		var current_second_input_byte : int = second_replay_array[current_tick]

		for bit : int in REPLAY_BYTE1:
			var input_name : StringName
			match bit:
				REPLAY_BYTE1.MOVE_LEFT : input_name = &"move_left"
				REPLAY_BYTE1.MOVE_RIGHT : input_name = &"move_right"
				REPLAY_BYTE1.QUICK_DROP : input_name = &"quick_drop"
				#REPLAY_BYTE1.INSTANT_DROP : input_name = &"instant_drop"
				REPLAY_BYTE1.ROTATE_LEFT : input_name = &"rotate_left"
				REPLAY_BYTE1.ROTATE_RIGHT : input_name = &"rotate_right"
				REPLAY_BYTE1.SPECIAL_ABILITY1 : input_name = &"side_ability"
				#REPLAY_BYTE1.SPECIAL_ABILITY2 : input_name = &"special_ability"
			
			if (current_first_input_byte & bit == bit) : game.current_input[input_name] = true
			else : game.current_input[input_name] = false
		
		if (current_second_input_byte & REPLAY_BYTE2.MUSIC_BEAT == REPLAY_BYTE2.MUSIC_BEAT) : game.skin._emulate_beat()


## Saves replay to .rpl formatted file [br]
## If [b]'path'[/b] is passed, uses it instead of creating own path from [b]'save_name'[/b] [br]
## If [b]'raw_data'[/b] is true, doesn't save metadata
func _save(save_name : String = "", path : String = "", raw_data : bool = false) -> int:
	replay_name = save_name

	if path.is_empty():
		path = Data.REPLAYS_PATH + save_name + ".rpl"
		path = path.replace(" ","_").to_lower()
	else:
		path = path + save_name + ".rpl"
	
	Console._log("Saving replay to path : " + path)
	game_version = Data.VERSION

	var file : FileAccess = FileAccess.open_compressed(path,FileAccess.WRITE,FileAccess.COMPRESSION_FASTLZ)
	if not file: 
		Console._log("ERROR! Failed to save replay. File open error : " + error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()
	
	if raw_data:
		file.store_8(0xFF)
		file.store_64(first_replay_array.size())
		file.store_buffer(first_replay_array)
		file.store_64(second_replay_array.size())
		file.store_buffer(second_replay_array)
	
	else:
		file.store_8(0x00)
		file.store_pascal_string(game_version)
		file.store_pascal_string(replay_name)
		file.store_pascal_string(author)
		file.store_pascal_string(date)
		file.store_var(preview_image,true)
		file.store_var(game_info,true)
		file.store_64(first_replay_array.size())
		file.store_buffer(first_replay_array)
		file.store_64(second_replay_array.size())
		file.store_buffer(second_replay_array)

	file.close()
	saved.emit()
	Console._log("Replay saved")

	return OK


## Loads only replay metadata from .rec formatted file
static func _load_metadata(path : String = "") -> Dictionary:
	Console._log("Loading replay metadata from path : " + path)
	
	var file : FileAccess = FileAccess.open_compressed(path,FileAccess.READ,FileAccess.COMPRESSION_FASTLZ)
	if not file: 
		Console._log("ERROR! Failed to load replay. File open error : " + error_string(FileAccess.get_open_error()))
		return {}

	var replay_metadata : Dictionary = {}

	var is_raw_data : bool = file.get_8() == 0xFF
	if is_raw_data : return {}

	replay_metadata["version"] = file.get_pascal_string()
	replay_metadata["name"] = file.get_pascal_string()
	replay_metadata["author"] = file.get_pascal_string()
	replay_metadata["date"] = file.get_pascal_string()

	replay_metadata["image"] = file.get_var(true)
	replay_metadata["game_info"] = file.get_var(true)

	return replay_metadata



## Loads replay from .rec formatted file
func _load(path : String = "") -> int:
	Console._log("Loading replay from path : " + path)
	
	var file : FileAccess = FileAccess.open_compressed(path,FileAccess.READ,FileAccess.COMPRESSION_FASTLZ)
	if not file: 
		Console._log("ERROR! Failed to load replay. File open error : " + error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()
	
	game_version = file.get_pascal_string()
	replay_name = file.get_pascal_string()
	author = file.get_pascal_string()
	date = file.get_pascal_string()

	preview_image = file.get_var(true)
	game_info = file.get_var(true)

	var first_array_size : int = file.get_64()
	first_replay_array = file.get_buffer(first_array_size)

	var second_array_size : int = file.get_64()
	second_replay_array = file.get_buffer(second_array_size)

	file.close()
	loaded.emit()
	Console._log("Replay loaded")

	return OK
