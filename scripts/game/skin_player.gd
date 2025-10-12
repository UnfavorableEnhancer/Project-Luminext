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

class_name SkinPlayer

##-----------------------------------------------------------------------
## Controls animated background and music playback and synchronization 
## This class music sync signals are used to trigger some gameplay events
## Also currently loaded SkinData lives here, so you must access it from here
##-----------------------------------------------------------------------

signal beat ## Emitted when next music beat reached
signal half_beat ## Emitted when next music half beat reached
signal sample_ended ## Emitted when current music sample has finished (sample = 2 bars)

signal playback_state_changed(state : int) ## Emitted when current music sample playback state changes

# Music syncing consts
const LOOP_COMPENSATE_SECS : float = 0.01 ## Compensate seconds for saving next music loop position
const COMPENSATE_FRAMES : int = 2
const COMPENSATE_HZ : float = 60.0

const BASE_BPM : float = 120.0 ## Base BPM for 4/4 measure

## All possible music playback states
enum PLAYBACK_STATE {
	PLAYING, ## Music is playing continously
	ADVANCING, ## Music is advancing to next sample
	LOOPING ## Music is looping in current sample
}

var skin_data : SkinData = null ## Currently playing [SkinData]

var color_animation : Dictionary[StringName, Array] = {} ## Stores times when to animate specific colored blocks and squares

var bpm : float = 120.0 ## Current beats per minute value
var forced_bpm : float = 0.0 ## Forced beats per minute value, if set music sync will be disabled

var single_beat : float = 1.0 ## Duration of single music beat in seconds
var single_half_beat : float = 0.5 ## Duration of single music half-beat in seconds

var sync_music : bool = true ## If false, music sync signals (beat, half-beat, etc.) aren't processed or emulated in physics thread and must be called manually
var emulate_beats : bool = false ## If true, music sync will be emulated
var beat_left : float = 0 ## Time left before next beat should be emulated

var is_sending_beat_signals : bool = true ## If true emits music sync related signals *('beat', 'half_beat', and 'sample_ended')*
var current_beat : int = 0 ## Current music beat
var current_half_beat : int = 0 ## Current music half-beat
var sample_was_passed : bool = false ## Used to ensure that current sample was passed
var beat_was_passed : bool = false ## True if hit next music beat on current physics frame

var playback_state : int = PLAYBACK_STATE.PLAYING ## Current playback state which affects currently playing music sample

var is_music_loaded : bool = false ## True is music is currently playing
var music_player : AudioStreamPlayer = null ## Current music player instance
var current_music_position : float = 0 ## Current music playback position (used for restoring after pause)
var music_sample_start_position : float = 0 ## Last music sample playback position

var background : Node2D = null ## Root background node
var background_image : TextureRect = null ## Static image background

var video_player : VideoStreamPlayer = null ## Video player instance
var is_video_loaded : bool = false ## Is video player loaded or not

var scene_player : AnimationPlayer = null ## Godot scenery animation player instance
var is_scene_loaded : bool = false ## Is scene animation player loaded or not

var darken : ColorRect = null ## Dark overlay which can be enabled by player

var is_paused : bool = false ## True if skin playback is paused


func _ready() -> void:
	name = "Skin"

	background = Node2D.new()
	background.name = "Background"
	add_child(background)

	background_image = TextureRect.new()
	background_image.size = Vector2(1920,1080)
	background_image.position = Vector2(-960,-540)
	background_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_image.name = "Image"
	background_image.texture = skin_data.textures["back"]
	background_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(background_image)

	video_player = VideoStreamPlayer.new()
	video_player.volume_db = -99
	video_player.size = Vector2(1920,1080)
	video_player.position = Vector2(-960,-540)
	video_player.expand = true
	video_player.name = "Video"
	video_player.loop = true
	video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(video_player)

	darken = ColorRect.new()
	darken.size = Vector2(1920,1080)
	darken.color = Color(0.0,0.0,0.0,0.5)
	darken.name = "Darken"
	darken.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(darken)

	Player.config.changed.connect(_sync_settings)
	_sync_settings()

	if not Player.config.video["disable_scenery"] : _load_godot_scene()
	if not Player.config.video["disable_video"] : _load_video()

	_load_music()

	_setup_block_animation_timers()
	half_beat.connect(_animate_colors)


## Syncs everything with current profile settings
func _sync_settings() -> void:
	# Scale background up, to make sure that background shaking wouldn't move background out of bounds
	if Player.config.video["background_shaking"] and not skin_data.metadata.settings["no_shaking"] and skin_data.metadata.settings["zoom_background"]: 
		background.scale = Vector2(1.2,1.2)
	else:
		background.scale = Vector2(1.0,1.0)
		background.position = Vector2(960,540)
	
	if Player.config.video["background_darkening"] : darken.visible = true
	else : darken.visible = false


## Loads video from currently playing [SkinData]
func _load_video() -> void:
	if not skin_data.video_is_cached: return
	if is_video_loaded : return

	var cached_video_name : String
	if Data.use_second_cache: cached_video_name = "video2." + skin_data.stream["video_format"]
	else: cached_video_name = "video." + skin_data.stream["video_format"]
	
	var stream : VideoStream
	stream = FFmpegVideoStream.new()

	stream.file = Data.CACHE_PATH + cached_video_name
	video_player.stream = stream

	Console._log("Skin has loaded video")
	is_video_loaded = true

	video_player.stream_position = 0
	video_player.stop()


## Loads custom Godot scenery from currently playing [SkinData]
func _load_godot_scene() -> void:
	if not skin_data.scenery_is_cached: return
	if is_scene_loaded : return

	if not ResourceLoader.exists("res://" + skin_data.stream["scene_path"]): 
		Console._log("ERROR! Custom scenery loading failed. Missing path to the main scene : " + skin_data.stream["scene_path"])
		return

	var scene : Node = load("res://" + skin_data.stream["scene_path"]).instantiate()
	scene.name = "Scene"
	scene.position = Vector2(-960,-540) # Center scene
	background.add_child(scene)

	scene_player = scene.get_node("A")
	#scene_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	scene_player.current_animation = "main"

	Console._log("Skin has loaded custom godot scenery")
	is_scene_loaded = true

	scene_player.seek(0, true)
	scene_player.stop()


## Loads music stream from currently playing [SkinData]
func _load_music() -> void:
	if (skin_data.stream["music"] == null):
		emulate_beats = true
		return

	music_player = AudioStreamPlayer.new()
	music_player.stream = skin_data.stream["music"]
	music_player.bus = "Music"
	music_player.name = "Music"
	
	add_child(music_player)
	music_player.finished.connect(_start)

	sample_ended.connect(_advance_playback)

	Console._log("Skin has loaded music stream")
	is_music_loaded = true

	music_sample_start_position = 0
	music_player.seek(0)
	music_player.stop()
		

## Starts skin playback from beginning
func _start() -> void:
	_rewind(0.0)

	current_half_beat = 0
	current_beat = 0
	beat_left = 0
	music_sample_start_position = 0
	sample_was_passed = false

	if forced_bpm > 0.0:
		bpm = forced_bpm
		single_beat = 60.0 / bpm
		single_half_beat = single_beat / 2.0
		beat_left = single_half_beat
		emulate_beats = true
	else:
		bpm = skin_data.metadata.bpm
		single_beat = 60.0 / bpm
		single_half_beat = single_beat / 2.0
		beat_left = single_half_beat
		if is_music_loaded : emulate_beats = false
	
	sample_ended.emit()
	beat.emit()
	half_beat.emit()

	_pause(false)
	if is_music_loaded: 
		music_player.play()
		if skin_data.metadata.settings["looping"] : _set_playback_state(PLAYBACK_STATE.LOOPING)
	
	if is_video_loaded: video_player.play()
	if is_scene_loaded: scene_player.play()


## Sets current skin playback position
func _rewind(to_position : float) -> void:
	if emulate_beats:
		beat_left = wrapf(to_position, 0, 30.0 / bpm)

	if is_music_loaded:
		var music_position : float = wrapf(to_position, 0, music_player.stream.get_length())
		music_player.seek(music_position)
	if is_scene_loaded:
		var scene_position : float = wrapf(to_position, 0, scene_player.current_animation_length)
		scene_player.seek(scene_position)
	if is_video_loaded:
		var video_position : float = wrapf(to_position, 0, video_player.get_stream_length())
		video_player.stream_position = video_position


## Called by physics tick and handles music sync
func _physics(delta : float) -> void:
	beat_was_passed = false

	if is_paused : return
	if not sync_music : return

	if emulate_beats:
		beat_left -= delta
		if beat_left <= 0:
			beat_left = 30.0 / bpm
			_emulate_beat()
		
		return

	if not is_music_loaded : return
	
	var time : float = music_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency() + (1 / COMPENSATE_HZ) * COMPENSATE_FRAMES
	
	var beats_total : int = int(time * bpm / 60.0)
	var half_beats_total : int = int(time * bpm / 30.0)
	
	if beats_total % 8 == 0 and current_beat == 7 and not sample_was_passed:
		sample_was_passed = true
		sample_ended.emit()
	
	if current_beat == 4:
		sample_was_passed = false
	
	if beats_total % 8 != current_beat : 
		current_beat = beats_total % 8
		beat.emit()
		
	if half_beats_total % 16 != current_half_beat: 
		current_half_beat = half_beats_total % 16
		beat_was_passed = true
		half_beat.emit()


## Emulates next music beat and emits corresponding signals
func _emulate_beat() -> void:
	current_half_beat += 1
	
	if current_half_beat == 16:
		sample_ended.emit()
		current_beat = 0
		current_half_beat = 0
	
	if current_half_beat % 2 == 0:
		current_beat += 1
		beat.emit()
	
	beat_was_passed = true
	half_beat.emit()


## Changes current music sample playback state
func _set_playback_state(state : int) -> void:
	if not is_music_loaded: return

	playback_state = state
	playback_state_changed.emit(state)


## Advances playback to the next sample depending on current playback state
func _advance_playback() -> void:
	if not is_music_loaded : return

	match playback_state:
		PLAYBACK_STATE.PLAYING:
			_rewind(music_player.get_playback_position())
		PLAYBACK_STATE.LOOPING:
			_rewind(music_sample_start_position)
		PLAYBACK_STATE.ADVANCING:
			music_sample_start_position = music_player.get_playback_position() + LOOP_COMPENSATE_SECS
			_set_playback_state(PLAYBACK_STATE.LOOPING)
			

## Sets pause state to **'on'** value
func _pause(on : bool) -> void:
	is_paused = on
	if is_video_loaded : 
		video_player.paused = on
	if is_music_loaded :
		music_player.stream_paused = on
	if is_scene_loaded :
		if on : scene_player.pause()
		else : scene_player.play()


## Start custom scenery bonus animation [br]
## Custom scene must have [AnimationPLayer] node called *"A2"* and have animations named: "bonus", "bonus2", "bonus3" and "bonus4" in order to work
func _bonus(number : int) -> void:
	if not is_scene_loaded : return
	if not has_node("Back/Scene/A2") : return
	
	var anim_name : String = "bonus"
	var anim_player : AnimationPlayer = $Back/Scene/A2
	
	if skin_data.metadata.settings["random_bonus"]:
		var anim_amount : int = anim_player.get_animation_list().size()
		anim_name = "bonus" + str(round(randf_range(0,anim_amount - 1)))
		if anim_name[5] == '0': anim_name = "bonus"
	else:
		if number == 1: anim_name = "bonus2"
		if number == 2: anim_name = "bonus3"
		if number > 2: anim_name = "bonus4"
	
	if anim_player.has_animation(anim_name) : anim_player.play(anim_name)
	elif anim_player.has_animation("bonus") : anim_player.play("bonus")


## Moves background to position
func _shake_background(to_position : Vector2) -> void:
	if not Player.config.video["background_shaking"] or Player.config.video["disable_scenery"]:
		background.position = Vector2(960,540)
		background.scale = Vector2(1.0,1.0)
		return
	
	var new_pos : Vector2 = Vector2(1159 - round(to_position.x / 3),540 - round(to_position.y  / 8))
	
	create_tween().tween_property(background,"position",new_pos,0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


## Plays skin ending sample
func _play_ending() -> void:
	if skin_data.sounds["ending"] == null : return
	if is_music_loaded : music_player.volume_db = -99

	var ending_player : AudioStreamPlayer = AudioStreamPlayer.new()
	ending_player.stream = skin_data.sounds["ending"]
	ending_player.name = "Ending"
	ending_player.bus = "Music"
	ending_player.finished.connect(ending_player.queue_free)
	add_child(ending_player)
	ending_player.play()


## Removes the skin with fade-out animation in **'end_anim_time'** seconds (used for replacing by new one)
func _end(end_anim_time : float) -> void:
	if is_music_loaded: music_player.stop()
	
	create_tween().tween_property(self, "modulate", Color("00000000"), end_anim_time)
	await get_tree().create_timer(end_anim_time).timeout
	
	queue_free()


## Setups blocks and squares animation timings
func _setup_block_animation_timers() -> void:
	color_animation.clear()
	
	# If "looping" animation is set for this skin
	if skin_data.textures["red_anim"][1] == 0:
		color_animation[&"red"] = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
		color_animation[&"white"] = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
		color_animation[&"green"] = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
		color_animation[&"purple"] = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
		return
	
	var color_anim_entries : Dictionary[StringName, String] = {
		&"red" : "red_anim",
		&"white" : "white_anim",
		&"green" : "green_anim",
		&"purple" : "purple_anim",
	}

	for color : StringName in [&"red", &"white", &"green", &"purple"]:
		var skin_anim_data_entry : String = color_anim_entries[color]
		var anim_data_entry_offset : int = skin_data.textures[skin_anim_data_entry][0]
		var anim_data_entry_beat : int = skin_data.textures[skin_anim_data_entry][1]

		var counter : int = 0
		var anim_array : Array[int] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

		# Add offset
		counter += anim_data_entry_offset
		
		# Place 1 where block must play animation, and 0 where dont
		# Each bit represents single half-beat, so there's 16 bits
		while true:
			counter += anim_data_entry_beat
			
			if counter > 15 : counter -= 16
			if anim_array[counter] == 1 : break
			anim_array[counter] = 1
		
		color_animation[color] = anim_array


## Called on each half-beat and starts blocks and squares animation
func _animate_colors() -> void:
	if not Player.config.video["block_animations"] : return
	if color_animation.is_empty() : return

	for color : StringName in color_animation:
		if color_animation[color][current_half_beat] == 1:
			get_tree().call_group("entity","_play",color)
		
		if current_half_beat == 8:
			get_tree().call_group("entity","_play",&"special")
