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


extends Node2D

##-----------------------------------------------------------------------
## Base class for all block-stacking puzzle games
##-----------------------------------------------------------------------

class_name GameCore

signal reset_started ## Emitted when game reset is started
signal reset_ended ## Emitted when game reset is finished

signal paused(on : bool) ## Emitted when game pause state is changed and returns new state
signal game_over ## Emitted when game is over

signal skin_change_started ## Emitted when skin change starts
signal skin_change_ended ## Emitted when skin change is completed

## Avaiable skin change routine error codes
enum SKIN_CHANGE_ERROR {
	OK, 
	BUSY, ## Skin change is still going on
	INVALID_PATH_OR_ID, ## Provided skin has invalid path or id
	FAILED_TO_START_THREAD, ## Skin load thread failed to start 
	FAILED_TO_LOAD_FILE, ## Skin file failed to load 
	INVALID_DATA ## Loaded skin data is corrupt
}

const PAUSE_BACK_Z_INDEX : int = -50
const FOREGROUND_Z_INDEX : int = -100
const EFFECTS_Z_INDEX : int = -200
const GAMEFIELD_Z_INDEX : int = -500
const SKIN_Z_INDEX : int = -1000

const TICK : float = 1 / 120.0 ## Single game physics tick

var main : Main ## Main instance
var menu : Menu ## Menu instance

var gamecore_name : String = "default" ## Name of the gamecore

var menu_screen_to_return_name : String = "main_menu" ## Name of the menu screen created after game exit
var pause_screen_name : String = "playlist_mode_pause" ## Name of the menu screen created on game pause
var game_over_screen_name : String = "playlist_mode_gameover" ## Name of the menu screen created on game over

var is_physics_active : bool = true ## If true, game ticks are processed by engine physics thread
var is_resetting : bool = false ## If true, game is currently resetting
var is_paused : bool = false ## If true, the game is paused and nothing happens
var is_game_over : bool = false ## If true, the game is over and needs restart
var is_changing_skin_now : bool = false ## If true, the game currently changes skin

## What inputs are currently locked and cannot be pressed
var input_lock : Dictionary[StringName, bool] = {
	&"move_left" : false,
	&"move_right" : false,
	&"rotate_left" : false,
	&"rotate_right" : false,
	&"quick_drop" : false,
	&"side_ability" : false
}

## Latest action inputs states (true - pressed, false - released)
var latest_input : Dictionary[StringName, bool] = {
	&"move_left" : false,
	&"move_right" : false,
	&"rotate_left" : false,
	&"rotate_right" : false,
	&"quick_drop" : false,
	&"side_ability" : false,
	&"pause" : false,
}

## Current action inputs states (true - pressed, false - released)
var current_input : Dictionary[StringName, bool] = {
	&"move_left" : false,
	&"move_right" : false,
	&"rotate_left" : false,
	&"rotate_right" : false,
	&"quick_drop" : false,
	&"side_ability" : false,
	&"pause" : false
}

var gamemode : Gamemode = null ## Current gamemode, defines game rules and goals

var replay : Replay = null ## Replay reference
var is_playing_replay : bool = false ## If true, currently plays prerecorded replay, else replay is currently recoring

var skin : SkinPlayer = null ## Current skin, defines game visuals and music
var old_skin_data : SkinData = null ## Old skin data which is stored during skin transition
var is_skin_transition_now : bool = false ## If true, skin transition is happening now
var skin_transition_start_time : int = 0 ## Time in msecs since engine boot when skin transition animation started

var rng : RandomNumberGenerator = RandomNumberGenerator.new() ## Used to generate randomized pieces and other events with defined seed

var pause_background : ColorRect ## ColorRect which covers game screen when its paused
var announce_timer : Timer ## Timer which starts next skin announce sample

var gamefield : Node2D ## Contains all game entities which do all fancy and gamey stuff
var foreground : Node2D ## Contains all game GUI which is controlled by current gamemode
var effects : Node2D ## Contains all game special effects

var sounds : Node2D ## Contains all game sound effects
var sound_queue : Array[AudioStreamPlayer2D] = [] ## All queued sounds which gonna be played on next music beat
var playing_sounds : Dictionary[String, AudioStreamPlayer2D] = {} ## All currently played sounds


func _ready() -> void:
	gamefield = Node2D.new()
	gamefield.name = "Gamefield"
	gamefield.z_as_relative = false
	gamefield.z_index = GAMEFIELD_Z_INDEX
	add_child(gamefield)

	sounds = Node2D.new()
	sounds.name = "Sounds"
	add_child(sounds)

	effects = Node2D.new()
	effects.name = "Effects"
	effects.z_as_relative = false
	effects.z_index = EFFECTS_Z_INDEX
	add_child(effects)

	foreground = Foreground.new()
	foreground.name = "Foreground"
	foreground.z_as_relative = false
	foreground.z_index = FOREGROUND_Z_INDEX
	add_child(foreground)

	pause_background = ColorRect.new()
	pause_background.name = "PauseBack"
	pause_background.color = Color.BLACK
	pause_background.size = Vector2(1920, 1080)
	pause_background.modulate.a = 0.0
	pause_background.z_as_relative = false
	pause_background.z_index = PAUSE_BACK_Z_INDEX
	add_child(pause_background)

	announce_timer = Timer.new()
	announce_timer.name = "Announce"
	announce_timer.one_shot = true
	add_child(announce_timer)

	if gamemode != null:
		gamemode.game = self
		gamemode.foreground = foreground
		gamemode.main = main
		add_child(gamemode)

	if replay == null:
		replay = Replay.new()
		add_child(replay)
	else:
		is_playing_replay = true

	replay.game = self

	Console.opened.connect(_pause.bind(true,false))
	Console.closed.connect(_pause.bind(false,false))
	Console.command_entered.connect(_execute_console_command)

	Debug.game = self

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


## Resets game to the initial state and starts it
func _reset() -> void:
	if is_resetting : return
	is_resetting = true

	Console._log("Resetting the game")
	is_physics_active = false

	gamemode._soft_reset()
	reset_started.emit()
	
	replay._reset_replay()

	while not sound_queue.is_empty() : sound_queue.pop_back().free()
	playing_sounds.clear()
	
	for effect : FX in effects.get_children(): effect.queue_free()

	if is_playing_replay: 
		for action : StringName in input_lock.keys() : input_lock[action] = true

	var error_code : int = await gamemode._reset()
	if error_code != OK:
		Console._log("ERROR! Gamemode failed to reset : " + gamemode.error_text)
		main._display_system_message("ERROR!\n" + gamemode.error_text)
		main._toggle_loading(false)
		await get_tree().create_timer(3.0).timeout
		_end()
		return

	is_game_over = false
	_pause(false, false)

	if is_playing_replay : replay._start_playback()
	else : replay._start_recording()

	reset_ended.emit()
	is_physics_active = true

	Console._log("Game reset complete")
	
	main._toggle_loading(false)
	main._toggle_darken(false)
	is_resetting = false


## Resets only game field and gamemode progress data, doesn't affect currently playing skin [br]
## Stops replay playback/recoring until full reset
func _soft_reset() -> void:
	Console._log("Soft resetting game")

	gamemode._soft_reset()
	reset_started.emit()

	if is_playing_replay: 
		replay._stop_playback()
		for i : StringName in input_lock.keys() : input_lock[i] = false
	else: 
		replay._stop_recording()
		replay.error_code = Replay.REPLAY_ERROR.RULESET_CHANGED

	is_game_over = false
	reset_ended.emit()

	Console._log("Game soft reset complete")


## Restarts the game
func _retry() -> void:
	if menu.screens.size() > 0 : menu._exit()
	
	main._toggle_darken(true)
	main._toggle_loading(true)
	await get_tree().create_timer(1.0).timeout

	_reset()


## Finishes the game and adds predefined in **'menu_screen_to_return'** menu screen
func _end() -> void:
	Console._log("Game is finished")
	gamemode._end()
	if menu.screens.size() > 0 : menu._exit()

	main._toggle_darken(true)
	await get_tree().create_timer(1.0).timeout
	
	menu._return_from_game(menu_screen_to_return_name)
	queue_free()


## Ends the game and adds game over menu screen as predefined in **'game_over_screen_name'**
func _game_over() -> void:
	Console._log("Game over!")
	if is_playing_replay :  replay._stop_playback()
	else : replay._stop_recording()

	is_game_over = true
	_pause(true,false)

	while not sound_queue.is_empty() : sound_queue.pop_back().free()

	menu._add_screen("foreground")
	var gameover_screen : MenuScreen = menu._add_screen(game_over_screen_name)
	gameover_screen._setup(self)
	
	game_over.emit()
	gamemode._game_over()


## Sets pause state to **'on'** value[br]
## - **'pause_screen'** - If true, adds menu screen as predefined in **'pause_screen_name'** if 'on' is true and waits for its closure if 'on' is false
func _pause(on : bool = true, use_pause_screen : bool = true) -> void:
	if use_pause_screen and not on: 
		menu._remove_screen("foreground")
		menu._remove_screen(pause_screen_name)
		await menu.all_screens_removed
	
	if on : Console._log("Game paused")
	else : Console._log("Game unpaused")

	is_paused = on
	announce_timer.paused = on

	if skin != null : skin._pause(on)
	gamemode._pause(on)
	replay._pause(on)
	paused.emit(on)

	if on : create_tween().tween_property(pause_background, "modulate:a", 0.8, 1.0).from(0.0)
	else : create_tween().tween_property(pause_background, "modulate:a", 0.0, 1.0).from(0.8)
		
	if on and use_pause_screen:
		menu._add_screen("foreground")
		var pause_screen : MenuScreen = menu._add_screen(pause_screen_name)
		pause_screen._setup(self)

		menu._play_sound("confirm4")


## Tests is input pressed in current physics frame and updates input state
func _is_action_pressed(action : StringName) -> bool:
	if current_input[action] and not latest_input[action]:
		latest_input[action] = current_input[action]
		return true
	
	return false


## Tests is input released in current physics frame and updates input state
func _is_action_released(action : StringName) -> bool:
	if not current_input[action] and latest_input[action]:
		latest_input[action] = current_input[action]
		return true
	
	return false


## Processes single game tick
func _tick(delta : float = TICK) -> void:
	for action : StringName in current_input.keys():
		if (action != &"pause" and input_lock[action] == true) : continue
		if Input.is_action_just_pressed(action) : current_input[action] = true
		if Input.is_action_just_released(action) : current_input[action] = false

	if _is_action_pressed("pause") : 
		if not is_paused : _pause(true)
		else : _pause(false)

	for action : StringName in current_input.keys():
		latest_input[action] = current_input[action]

	if is_paused : return

	skin._physics(delta)


func _physics_process(delta: float) -> void:
	if not is_physics_active : return
	_tick(delta)


## Changes current skin to new one specified in **'new_skin'** with special transition animation[br]
## Returns [SKIN_CHANGE_ERROR] error code [br]
## - **'new_skin'** - Can be either skin ID, either path to skin file, either loaded [SkinData][br]
## - **'quick'** - If true, skips skin transition animation and loads new skin instantly
func _change_skin(new_skin : Variant, quick : bool = false) -> int:
	Console._space()
	Console._log("Changing current game skin")
	
	if is_changing_skin_now : 
		Console._log("ERROR! Skin is already changing!")
		return SKIN_CHANGE_ERROR.BUSY
	
	var skin_data : SkinData = null
	var skin_metadata : SkinMetadata = null

	is_changing_skin_now = true
	skin_change_started.emit()

	if new_skin is String:
		skin_data = SkinData.new()
		skin_metadata = Data.skin_list._get_skin_metadata_by_id(new_skin)
		if skin_metadata != null : Console._log("Next skin ID : " + new_skin)
		else :
			skin_metadata = Data.skin_list._get_skin_metadata_by_path(new_skin)
			if skin_metadata != null : Console._log("Next skin file path : " + new_skin)
			else:
				Console._log("ERROR! Invalid skin ID or path : " + new_skin)
				is_changing_skin_now = false
				skin_change_ended.emit()
				return SKIN_CHANGE_ERROR.INVALID_PATH_OR_ID
	elif new_skin is SkinMetadata:
		Console._log("Next skin ID : " + new_skin.id)
		skin_metadata = new_skin
	elif new_skin is SkinData:
		Console._log("Next skin ID : " + new_skin.metadata.id)
		skin_data = new_skin
	else:
		Console._log("ERROR! Invalid skin data : " + str(new_skin))
		is_changing_skin_now = false
		skin_change_ended.emit()
		return SKIN_CHANGE_ERROR.INVALID_DATA
	
	if skin_data == null:
		skin_data = SkinData.new()
		skin_data.io_progress.connect(main._set_loading_message)

		var load_thread : Thread = Thread.new()
		var err : int = load_thread.start(skin_data._load_from_path.bind(skin_metadata.path))
		if err != OK:
			Console._log("ERROR! Failed to start skin loading thread. Error code : " + error_string(err))
			is_changing_skin_now = false
			skin_change_ended.emit()
			return SKIN_CHANGE_ERROR.FAILED_TO_START_THREAD
		
		await skin_data.skin_loaded
		await get_tree().create_timer(0.01).timeout
		var result : int = load_thread.wait_to_finish()
		if result != OK:
			Console._log("ERROR! Failed to load new skin.")
			is_changing_skin_now = false
			skin_change_ended.emit()
			return SKIN_CHANGE_ERROR.FAILED_TO_LOAD_FILE

	if quick:
		if skin != null:
			skin.half_beat.disconnect(_on_skin_half_beat)
			skin.beat.disconnect(_on_skin_beat)
			skin.sample_ended.disconnect(_on_skin_sample_ended)
			skin.queue_free()
		
		_set_skin(skin_data)

		foreground._change_style(skin_data, 0.0)
		get_tree().call_group("entity", "_render")

		await get_tree().create_timer(0.1).timeout

		is_changing_skin_now = false
		is_skin_transition_now = false
		
		skin_change_ended.emit()
		Console._log("Skin changed successfully!")
		return OK

	await skin.sample_ended
	skin._play_ending()

	# Turn music volume down
	if skin.music_player != null:
		create_tween().tween_property(skin.music_player, "volume_db", -40.0, 60.0 / skin.bpm * 8.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
 
	var transition_time : float = 60.0 / skin.bpm * 6.0 # 3 beats
	announce_timer.start(transition_time)

	await $Announce.timeout
	_play_announce(skin_data)
	
	await skin.sample_ended

	skin.half_beat.disconnect(_on_skin_half_beat)
	skin.beat.disconnect(_on_skin_beat)
	skin.sample_ended.disconnect(_on_skin_sample_ended)

	old_skin_data = skin.skin_data
	is_skin_transition_now = true
	skin_transition_start_time = Time.get_ticks_msec()

	skin._end(transition_time)
	_set_skin(skin_data)
	create_tween().tween_property(skin, "modulate:a", 1.0, transition_time).from(0.0)
	skin._start()

	foreground._change_style(skin_data, transition_time)
	get_tree().call_group("entity", "_update_render", transition_time)

	# Raise music volume up
	if skin.music_player != null:
		create_tween().tween_property(skin.music_player, "volume_db", 0.0, transition_time).from(-40.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(transition_time).timeout

	old_skin_data.free()
	old_skin_data = null
	is_changing_skin_now = false
	is_skin_transition_now = false
	skin_change_ended.emit()
	Console._log("Skin changed successfully")
	return OK


## Creates skin instance from passed [SkinData] and connects it to the game, replacing old skin
func _set_skin(skin_data : SkinData) -> void:
	if skin != null:
		skin.half_beat.disconnect(_on_skin_half_beat)
		skin.beat.disconnect(_on_skin_beat)
		skin.sample_ended.disconnect(_on_skin_sample_ended)
	
	var new_skin : SkinPlayer = SkinPlayer.new()
	new_skin.skin_data = skin_data
	skin = new_skin

	skin.half_beat.connect(_on_skin_half_beat)
	skin.beat.connect(_on_skin_beat)
	skin.sample_ended.connect(_on_skin_sample_ended)

	skin.z_as_relative = false
	skin.z_index = SKIN_Z_INDEX

	Debug.skin = skin

	add_child(new_skin)

	get_tree().call_group("entity","_refresh_render")


## Plays next skin announce sound from passed [SkinData]
func _play_announce(skin_data : SkinData) -> void:
	if Player.config.audio["announcer"] == Config.ANNOUNCER_MODE.OFF: return
	
	var announce : AudioStreamPlayer = AudioStreamPlayer.new()
	announce.stream = skin_data.metadata.announce
	announce.finished.connect(announce.queue_free)
	announce.bus = "Announce"
	sounds.add_child(announce)
	announce.play()


## Adds visual effect to the game and returns its instance
## - **'fx_name** - Name of the effect in [SkinData.effects]
## - **'fx_position** - New effect absolute position
## - **'fx_parameter** - Custom variable this effect might use
func _add_fx(fx_name : StringName, fx_position : Vector2, fx_parameter : Variant = null) -> FX:
	var fx_data : Variant = skin.skin_data.effects[fx_name]
	var fx : FX
	
	if fx_data is String : fx = load(fx_data).instantiate()
	elif fx_data is PackedScene : fx = fx_data.instantiate()
	else : return

	fx.position = fx_position
	fx.parameter = fx_parameter
	fx.game = self
	
	effects.add_child(fx)
	return fx


## Adds sound effect from currently playing skin and returns its instance[br]
## - **'sound_name'** - Name of the entry inside [SkinData.sounds][br]
## - **'sound_pos'** - Sound absolute position in 2D space[br]
## - **'play_once'** - If true, only one instance of sound can be played at once[br]
## - **'sync_to_beat'** - If true, sound will be put into queue and be played only on next skin music beat[br]
## - **'sound_id'** - Defines index inside multisound array from which sound will be taken[br] 
## + - if == -1 random sound will be selected[br]
## + - if == -2 random even index will be taken[br]
## + - if == -3 random uneven index will be taken
func _add_sound(sound_name : StringName, sound_position : Vector2, play_once : bool = false, sync_to_beat : bool = true, sound_id : int = -1) -> AudioStreamPlayer2D:
	if play_once and playing_sounds.has(sound_name) : return null

	if not skin.skin_data.sounds.has(sound_name) : 
		Console._log("ERROR! Missing sound effect : " + sound_name)
		return null

	var sample : AudioStream = null
	var entry : Variant = skin.skin_data.sounds[sound_name]

	if entry is AudioStream : sample = entry

	elif entry is Array :
		if entry.is_empty() : return null
		if entry[0] == null : return null

		if sound_id == -1:
			var rand_index : int = randi_range(0, entry.size() - 2)
			sample = entry[rand_index]
		elif sound_id == -2:
			var even_index_array : Array = range(0, entry.size() - 1, 2)
			sample = entry[even_index_array.pick_random()]
		elif sound_id == -3:
			if entry.size() < 3 : sample = entry[0]
			else:
				var uneven_index_array : Array = range(1, entry.size() - 1, 2)
				sample = entry[uneven_index_array.pick_random()]
		else:
			if sound_id > (entry.size() - 1) : sample = entry[0]
			else : sample = entry[sound_id]
	else:
		return null
	
	while playing_sounds.has(sound_name):
		sound_name += str(randi_range(10,100000000))

	var sound_player : AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	sound_player.name = sound_name
	sound_player.stream = sample
	sound_player.position = sound_position if Player.config.audio["spatial_sound"] else Vector2(960,540)
	sound_player.bus = "Sound"
	sound_player.finished.connect(sound_player.queue_free)
	sound_player.finished.connect(_sound_finished.bind(sound_name))
	playing_sounds[sound_name] = sound_player
	
	if sync_to_beat: 
		sound_queue.append(sound_player)
	else:
		sounds.add_child(sound_player)
		sound_player.play()
	
	return sound_player


func _sound_finished(sound_name : String) -> void:
	playing_sounds.erase(sound_name)


## Plays all queued sounds *(connected to skin music beat signal)*
func _play_queued_sounds() -> void:
	while not sound_queue.is_empty():
		var sound_player : AudioStreamPlayer2D = sound_queue.pop_back()
		sounds.add_child(sound_player)
		sound_player.play()


## Called on each skin music half-beat
func _on_skin_half_beat() -> void:
	_play_queued_sounds()


## Called on each skin music beat
func _on_skin_beat() -> void:
	pass


## Called on each skin music sample end
func _on_skin_sample_ended() -> void:
	pass


## Executes entered into Console command
func _execute_console_command(command : String, arguments : PackedStringArray) -> void:
	match command:
		# Toggles skin debug screen
		"skndebug" : 
			Debug._toggle(Debug.DEBUG_SCREEN.SKIN)

		# Prints current skin metadata
		"skninfo" :
			var metadata : SkinMetadata
			if arguments.size() > 0 : return
			if skin != null : metadata = skin.skin_data.metadata
			
			Console._output("Name : " + metadata.name)
			Console._output("Album : " + metadata.album)
			Console._output("Number in album : " + str(metadata.number))
			Console._output("Id : " + metadata.id)
			Console._output("Artist : " + metadata.artist)
			Console._output("Last edited by : " + metadata.skin_by)
			Console._output("Save date : " + Time.get_datetime_string_from_unix_time(int(metadata.save_date)).replace("T", " "))
			Console._output("BPM : " + str(metadata.bpm))
			Console._output("SKN format version : " + str(metadata.version))
			Console._output("Info : ")
			Console._output(metadata.info)
		
		# Pauses skin playback
		"sknstop" :
			if skin == null : Console._output("Error! Skin is not loaded"); return
			skin._pause(true)
		
		# Continues skin playback
		"sknplay" :
			if skin == null : Console._output("Error! Skin is not loaded"); return
			skin._pause(false)
		
		# Resets skin making it play from beginning
		"sknrst" :
			if skin == null : Console._output("Error! Skin is not loaded"); return
			skin._start()
		
		# Replaces current skin with specified one
		"sknload" :
			if arguments.size() < 1: Console._output("Error! Skin path or id is not entered"); return
			if skin == null : Console._output("Error! Skin is not loaded"); return

			if arguments[0].is_relative_path():
				_change_skin(arguments[0])
			else:
				var metadata : SkinMetadata = Data.skin_list._get_skin_by_id(arguments[0])
				if metadata == null: Console._output("Error! This skin doesn't exist"); return
				_change_skin(metadata.path)
		
		# Set's current skin playback position to specified one
		"sknpos" : 
			if arguments.size() < 1: Console._output("Error! Time in seconds is not entered"); return
			if skin == null : Console._output("Error! Skin is not loaded"); return
			skin._rewind(float(arguments[0]))
		
		# Lists all avaiable special effects
		"fxlist" :
			if skin == null : Console._output("Error! Skin is not loaded"); return
			for fx_name : String in skin.skin_data.fx : Console._output(fx_name)
		
		# Spawns specified special effect at specified position
		"fxadd" :
			if arguments.size() < 1: Console._output("Error! X coordinate is not entered"); return
			if arguments.size() < 2: Console._output("Error! Y coordinate is not entered"); return
			if arguments.size() < 3: Console._output("Error! FX name is not entered"); return

			if skin == null : Console._output("Error! Skin is not loaded"); return

			var pos : Vector2 = Vector2(float(arguments[0]), float(arguments[1]))
			_add_fx(arguments[2], pos)
		
		# Lists all avaiable sound effects
		"sfxlist" :
			if skin == null : Console._output("Error! Skin is not loaded"); return

			for sound_name : String in skin.skin_data.sounds:
				if skin.skin_data.sounds[sound_name] == null: 
					continue 
				if sound_name in ["bonus","square","special","timeline","blast"]:
					for i : int in skin.skin_data.sounds[sound_name].size() - 1:
						Console._output(sound_name + str(i))
					continue
				Console._output(sound_name)
		
		# Spawns specified sound effect at specified position
		"sfxadd" :
			if arguments.size() < 1: Console._output("Error! X coordinate is not entered"); return
			if arguments.size() < 2: Console._output("Error! Y coordinate is not entered"); return
			if arguments.size() < 3: Console._output("Error! Sound name is not entered"); return

			if skin == null : Console._output("Error! Skin is not loaded"); return

			var pos : Vector2 = Vector2(float(arguments[0]), float(arguments[1]))
			var sound_name : String = arguments[2]

			var num : int = -1
			if sound_name.begins_with("bonus") : 
				num = int(sound_name.substr(5))
				sound_name = sound_name.left(5)
			elif sound_name.begins_with("square") :
				num = int(sound_name.substr(6))
				sound_name = sound_name.left(6)
			elif sound_name.begins_with("special") : 
				num = int(sound_name.substr(7))
				sound_name = sound_name.left(7)
			elif sound_name.begins_with("timeline") : 
				num = int(sound_name.substr(8))
				sound_name = sound_name.left(8)
			elif sound_name.begins_with("blast") : 
				num = int(sound_name.substr(5))
				sound_name = sound_name.left(5)

			if num == -1 : _add_sound(sound_name, pos, true, false)
			else : _add_sound(sound_name, pos, true, false, num)

		# Lists all avaiable UI designs
		"uilist" :
			Console._output("standard")
			Console._output("shinin")
			Console._output("square")
			Console._output("modern")
			Console._output("live")
			Console._output("pixel")
			Console._output("black")
			Console._output("comic")
			Console._output("clean")
			Console._output("vector")
			Console._output("techno")
		
		# Changes current UI design with specified one
		"uiset" : 
			if arguments.size() < 1: Console._output("Error! UI design name is not entered"); return
			if skin == null : Console._output("Error! Skin is not loaded"); return

			var ui_design : int = 0
			match arguments[0]:
				"standard" : ui_design = SkinData.UI_DESIGN.STANDARD
				"shinin" : ui_design = SkinData.UI_DESIGN.SHININ
				"square" : ui_design = SkinData.UI_DESIGN.SQUARE
				"modern" : ui_design = SkinData.UI_DESIGN.MODERN
				"live" : ui_design = SkinData.UI_DESIGN.LIVE
				"pixel" : ui_design = SkinData.UI_DESIGN.PIXEL
				"black" : ui_design = SkinData.UI_DESIGN.BLACK
				"comic" : ui_design = SkinData.UI_DESIGN.COMIC
				"clean" : ui_design = SkinData.UI_DESIGN.CLEAN
				"vector" : ui_design = SkinData.UI_DESIGN.VECTOR
				"techno" : ui_design = SkinData.UI_DESIGN.TECHNO
				_ : Console._output("Error! Invalid UI design name. Enter 'uilist' to get list of all avaiable UI designs"); return
			
			skin.skin_data.textures["ui_design"] = ui_design
			foreground._change_style(skin.skin_data)
		
		# Changes specified UI element color
		"color" :
			if arguments.size() < 1: Console._output("Error! UI element name is not entered"); return
			if arguments.size() < 2: Console._output("Error! Red channel % value is not entered"); return
			if arguments.size() < 3: Console._output("Error! Green channel % value is not entered"); return
			if arguments.size() < 4: Console._output("Error! Blue channel % value is not entered"); return
			if arguments.size() < 5: Console._output("Error! Alpha channel % value is not entered"); return

			if skin == null : Console._output("Error! Skin is not loaded"); return

			var color : Color = Color.WHITE
			color.r = color.r * (float(arguments[1]) / 100.0)
			color.g = color.g * (float(arguments[2]) / 100.0)
			color.b = color.b * (float(arguments[3]) / 100.0)
			color.a = color.a * (float(arguments[4]) / 100.0)

			match arguments[0]:
				"eq" : 
					skin.skin_data.textures["eq_visualizer_color"] = color
					foreground._change_style(skin.skin_data)
				"ui" : 
					skin.skin_data.textures["ui_color"] = color
					foreground._change_style(skin.skin_data)
				"timeline" : 
					skin.skin_data.textures["timeline_color"] = color
				_: 
					Console._output("Error! Invalid UI element name. Try entering 'eq', 'ui', 'timeline' instead"); return
		
		# Toggles game debug screen
		"gdebug" :  
			Debug._toggle(Debug.DEBUG_SCREEN.GAME)

		# Resets game
		"greset" :
			_reset()

		# Soft-resets game
		"gsoft" :
			_soft_reset()

		# Triggers gameover
		"gover" :
			_game_over()
		
		# Finishes the game and returns to main menu screen
		"back2menu" :
			_end()
