extends Node2D

#-----------------------------------------------------------------------
# Skin playback class
#
# Controls animated background and music playback and synchronization 
# This class music sync signals are used to trigger some gameplay events
# 
# Also currently loaded SkinData lives here, so you must access it from here
#-----------------------------------------------------------------------


signal beat # Emitted when music beat reached
signal half_beat # Emitted when music half beat reached
signal sample_ended # Emitted when current music sample has finished (sample = 2 bars)

signal initiated # Emitted when skin is initiated and is ready to be played
signal song_finished # Emitted when song has finished

# Music syncing consts
const LOOP_COMPENSATE_SECS : float = 0.001
const COMPENSATE_FRAMES : int = 2
const COMPENSATE_HZ : float = 60.0

var skin_data : SkinData = null

var color_animation : Dictionary = {} # Stores times when to animate specific colored blocks and squares

var bpm : float = 120.0 # Current beats per minute, mainly used in music synchronization system
var force_beater : bool = false # If true, music sync would be emulated by speical timer called "beater"

var current_beat : int = 0
var current_half_beat : int = 0
var sample_was_passed : bool = false # Used to ensure that sample was passed just once

var music_player : AudioStreamPlayer = null
var current_music_position : float = 0 # Used to resume music after pause

var beater : Timer = null # "Beater" emulates music playback if skin has no music

var video_player : VideoStreamPlayer = null # Loaded video player
var scene_player : AnimationPlayer = null # Loaded scenery animation player

var music_sample_start_position : float = 0 # Used for looping, last music sample playback position
var scene_sample_start_position : float = 0 # Used for looping, last scenery part playback position

var is_initiated : bool = false
var is_paused : bool = false
var is_music_playing : bool = false
var is_music_looping : bool = false # If this is true, current music sample will loop


func _initiate() -> void:
	Data.profile.settings_changed.connect(_sync_settings)
	_sync_settings()
	
	video_player = $Back/Video

	$Back/Background.texture = skin_data.textures["back"]
	
	_load_godot_scene()
	_load_video()
	
	half_beat.connect(_animate_colors)
	sample_ended.connect(_sync)

	if skin_data.metadata.settings["looping"] : 
		sample_ended.connect(_loop_music)
		is_music_looping = true

	initiated.emit()
	is_initiated = true


func _sync_settings() -> void:
	# Scale background up, to make sure that background shaking wouldn't move background out of bounds
	if Data.profile.config["video"]["background_shaking"] and not skin_data.metadata.settings["no_shaking"] and skin_data.metadata.settings["zoom_background"]: 
		$Back.scale = Vector2(1.2,1.2)
	else:
		$Back.scale = Vector2(1.0,1.0)
		$Back.position = Vector2(960,540)


# Loads video from skin data
func _load_video() -> void:
	if not skin_data.video_is_cached: return

	var extension : String = skin_data.stream["video_format"]
	var cached_video_name : String
	if Data.use_second_cache: cached_video_name = "video2." + skin_data.stream["video_format"]
	else: cached_video_name = "video." + skin_data.stream["video_format"]
	
	var stream : VideoStream
	if extension == "ogv" : stream = VideoStreamTheora.new()
	else : stream = FFmpegVideoStream.new()

	stream.file = Data.CACHE_PATH + cached_video_name
	video_player.stream = stream
	
	print("VIDEO LOADED!")


# Loads packed Godot scenery stored in skin data
func _load_godot_scene() -> void:
	if not skin_data.scenery_is_cached: return
	
	var cached_scene_name : String
	if Data.use_second_cache: cached_scene_name = "scene2." + skin_data.stream["scene_format"]
	else: cached_scene_name = "scene." + skin_data.stream["scene_format"]
	
	var success : bool = ProjectSettings.load_resource_pack(Data.CACHE_PATH + cached_scene_name)

	if not success: 
		print("SCENE PACK LOAD ERROR!")
		return

	if not ResourceLoader.exists("res://" + skin_data.stream["scene_path"]): 
		print("SCENE LOAD FAILED! MISSING PATH! ", skin_data.stream["scene_path"])
		return

	var scene : Node = load("res://" + skin_data.stream["scene_path"]).instantiate()

	scene.name = "Scene"
	scene.position = Vector2(-960,-540) # Center scene
	$Back.add_child(scene)
	scene_player = $Back/Scene/A
	scene_player.current_animation = "main"

	print("SCENE LOADED!")


# Resets skin back to beginning
func _reset() -> void:
	if music_player != null: 
		music_player.stop()
		music_player.queue_free()
		music_player = null
	
	if beater != null: 
		beater.free()
		beater = null
	
	is_music_playing = false
	set_physics_process(false)
	
	if Data.profile.config["video"]["disable_scenery"] and scene_player != null:
		scene_player.get_parent().queue_free()
		scene_player = null
	elif scene_player == null:
		_load_godot_scene()
	
	if Data.profile.config["video"]["disable_video"] and video_player.stream != null:
		video_player.stream = null
	elif video_player.stream == null:
		_load_video()
	
	if Data.profile.config["gameplay"]["force_bpm"] > 0 : 
		bpm = Data.profile.config["gameplay"]["force_bpm"]
		force_beater = true
	else : 
		bpm = skin_data.metadata.bpm
		force_beater = false

	if scene_player != null:
		scene_player.seek(0, true)
		scene_player.stop()

	music_sample_start_position = 0
	scene_sample_start_position = 0
	
	if skin_data.metadata.settings["looping"] : is_music_looping = true


# Starts skin from beginning
func _start() -> void:
	if not is_initiated: _initiate()
	_reset()
	is_paused = false
	
	_setup_block_animation_timers()
	_play_video()
	if scene_player != null: scene_player.play()
	_start_music()


# Set pause state
func _pause(on : bool) -> void:
	if on:
		is_paused = true
		
		if scene_player != null: scene_player.pause()
		if beater != null : beater.paused = true
		video_player.paused = true

		if music_player != null:
			current_music_position = music_player.get_playback_position()
			music_player.stop()
			is_music_playing = false
	else:
		is_paused = false
		
		if scene_player != null: 
			scene_player.play()
			#scene_player.seek(scene_player.current_animation_position, true)
		
		if beater != null : beater.paused = false
		video_player.paused = false

		if music_player != null : 
			music_player.play(current_music_position)
			is_music_playing = true


# Start scenery bonus animation
func _bonus(number : int) -> void:
	if scene_player == null : return
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
	
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
	elif anim_player.has_animation("bonus"):
		anim_player.play("bonus")


# Starts music from beginning
func _start_music() -> void:
	if is_paused: return
	
	current_half_beat = 0
	current_beat = 0
	music_sample_start_position = 0
	scene_sample_start_position = 0
	is_music_playing = false
	set_physics_process(false)

	if music_player != null:
		music_player.stop()
		music_player.queue_free()
		song_finished.emit()
		music_player = null

	if Data.game != null and Data.game.is_game_over : return
	
	# If skin has no music, emulate music syncing by creating special timer called "Beater"
	if (skin_data.stream["music"] == null or force_beater) and beater == null: 
		beater = Timer.new()
		beater.name = "Beater"
		beater.wait_time = 30.0 / bpm
		beater.timeout.connect(_emulate_beat)
		add_child(beater)
		beater.start()
	
	else:
		music_player = AudioStreamPlayer.new()
		music_player.stream = skin_data.stream["music"]
		music_player.bus = "Music"
		music_player.name = "Music"
		
		add_child(music_player)
		music_player.play()
		
		music_player.finished.connect(_start_music)
		is_music_playing = true
		set_physics_process(true)
	
	sample_ended.emit()
	beat.emit()
	half_beat.emit()


# This physics process handles music synchronization
func _physics_process(_delta : float) -> void:
	if not is_music_playing : return
	if is_paused : return
	
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
		half_beat.emit()


# Syncs scenery playback position to music
func _sync() -> void:
	if is_paused: return
	if music_player == null: return
	var music_position : float = music_player.get_playback_position()

	if scene_player != null:
		scene_player.seek(wrapf(music_position, 0, scene_player.current_animation_length) ,true)


# Used by "beater" to emulate beat signals callback
func _emulate_beat() -> void:
	current_half_beat += 1
	
	if current_half_beat == 16:
		sample_ended.emit()
		current_beat = 0
		current_half_beat = 0
	
	if current_half_beat % 2 == 0:
		current_beat += 1
		beat.emit()
	
	half_beat.emit()


# Called on sample end and loops music back to the beginning of that sample if allowed to
func _loop_music() -> void:
	if not is_music_playing: return
	
	if not is_music_looping:
		music_sample_start_position = music_player.get_playback_position() + LOOP_COMPENSATE_SECS
		if scene_player != null:
			scene_sample_start_position = scene_player.current_animation_position + LOOP_COMPENSATE_SECS
		is_music_looping = true
	else: 
		music_player.seek(music_sample_start_position)
		#if has_node("Back/Scene"):
			#$Back/Scene/A.seek(scene_sample_start_position)


# Plays video from beginning
func _play_video() -> void:
	video_player.paused = false
	video_player.play()


# Quickly shakes background to some position
func _shake_background(to_position : Vector2) -> void:
	if not Data.profile.config["video"]["background_shaking"] or Data.profile.config["video"]["disable_scenery"]:
		$Back.position = Vector2(960,540)
		$Back.scale = Vector2(1.0,1.0)
		return
	
	var new_pos : Vector2 = Vector2(1159 - round(to_position.x / 3),540 - round(to_position.y  / 8))
	
	create_tween().tween_property($Back,"position",new_pos,0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func _play_ending() -> void:
	if skin_data.sounds["ending"] == null : return
	if music_player != null : music_player.volume_db = -99

	var player : AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = skin_data.sounds["ending"]
	player.name = "Ending"
	player.bus = "Music"
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


# Removes the skin with fade-out animation, usually to replace by new one 
func _end(end_anim_time : float) -> void:
	if music_player != null: music_player.stop()
	
	create_tween().tween_property(self, "modulate", Color("00000000"), end_anim_time)
	await get_tree().create_timer(end_anim_time).timeout
	
	queue_free()


# Setups half-beat values for each color array, defining on which half-beats current color blocks and squares animations should play
func _setup_block_animation_timers() -> void:
	if not Data.profile.config["video"]["block_animations"] : return
	
	# Start constant looping animation
	if skin_data.textures["red_anim"][1] == 0:
		get_tree().call_group("blocks","set","is_animation_looping",true)
		get_tree().call_group("blocks","play")
		return
	
	var color_anim_entries : Array[String] = ["red_anim","white_anim","green_anim","purple_anim"]
	for color : int in [BlockBase.BLOCK_COLOR.RED, BlockBase.BLOCK_COLOR.WHITE, BlockBase.BLOCK_COLOR.GREEN, BlockBase.BLOCK_COLOR.PURPLE]:
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


# Called on each half-beat, and turns on colored blocks and squares animation
func _animate_colors() -> void:
	if not Data.profile.config["video"]["block_animations"] : return

	for color : int in color_animation:
		if color_animation[color][current_half_beat] == 1:
			get_tree().call_group("blocks","_play",color)
			get_tree().call_group("squares","_play",color)
		
		if current_half_beat == 8:
			get_tree().call_group("blocks","_play","special")
