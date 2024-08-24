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


extends PlaylistMode

class_name SynthesiaMode

#-----------------------------------------------------------------------
# Synthesia mode gamemode script
# 
# Allows to play any music from user PC with cool visualizer background
#-----------------------------------------------------------------------

enum VISUALISER {SHOCKWAVE, SHOCKWAVE_SIMPLE, REZ}
enum SOUND_SET {DRUMS, BFXR, CALM, TECHNO}
enum COLOR_SCHEME {STANDARD, RED, BLUE, GREEN, YELLOW}

const PREPROCESS_MUSIC_FILE_SIZE : int = 512000 # Size of stripped music file for use in bpm calculation application

var visualiser : int = VISUALISER.SHOCKWAVE
var color_scheme : int = 0
var sound_set : int = 0

var music_file_path_to_load : String = "" # File path of music file to load
var music_stream : AudioStream = null # Music stream which we would be playing
var use_precise_bpm_calculation : bool = false # If true, doesn't strip music file allowing CLI aplication to process it fully and more accurately, but it takes MUCH more time
var bpm : float = 120.0


func _init() -> void:
	use_preprocess = true


# Called before game starts. Puts music into third-party BPM calculation programm.
func _preprocess() -> int:
	if not music_file_path_to_load.get_extension() in ["mp3","ogg","wav"]:
		error_text = "INVALID FILE EXTENSION! ONLY MP3, OGG AND WAV ARE SUPPORTED!"
		return ERR_FILE_UNRECOGNIZED

	var file : FileAccess
	var process_file_path : String = ""

	Data.main.call_deferred("_change_loading_message", Data.LOADING_STATUS.CALCULATING_BPM)
		
	if use_precise_bpm_calculation:
		process_file_path = music_file_path_to_load
	else:
		# We make stripped down version of our music file so it wouldn't take etenity to process
		file = FileAccess.open(music_file_path_to_load, FileAccess.READ)

		var buffer_file_path : String = Data.CACHE_PATH + "music." + music_file_path_to_load.get_extension()
		var buffer_file : FileAccess = FileAccess.open(buffer_file_path, FileAccess.WRITE)

		var buffer : PackedByteArray = file.get_buffer(PREPROCESS_MUSIC_FILE_SIZE)
		buffer_file.store_buffer(buffer)
		process_file_path = buffer_file.get_path_absolute()
		
		buffer_file.close()
		file.close()
	
	# Put our stripped music file into Essentia rhythm extractor CLI application (it was the easiest and fastest way to get it done)
	var shell_output : Array = []
	OS.execute("third_party/essentia_streaming_rhythmextractor_multifeature.exe", [process_file_path], shell_output)

	# Parse this shitload of text we got
	var shell_text : String = shell_output[0]

	var bpm_start_pos : int = shell_text.find("bpm", 40)

	var bpm_text : String = shell_text.substr(bpm_start_pos + 4, bpm_start_pos + 4 + 8)
	bpm = float(bpm_text)

	# In case this dumb programm fails, set BPM to standard 120
	if bpm < 1: bpm = 120.0

	# Load our full music file
	if music_file_path_to_load.ends_with(".ogg"): 
		music_stream = AudioStreamOggVorbis.load_from_file(music_file_path_to_load)
	elif music_file_path_to_load.ends_with(".mp3"): 
		file = FileAccess.open(music_file_path_to_load, FileAccess.READ)
		music_stream = AudioStreamMP3.new()
		music_stream.data = file.get_buffer(file.get_length())
		file.close()
	elif music_file_path_to_load.ends_with(".wav"): 
		var audio_loader : AudioLoader = AudioLoader.new()
		music_stream = audio_loader.loadfile(music_file_path_to_load)
	else: 
		music_stream = null
	
	preprocess_finished.emit()
	return OK


func _ready() -> void:
	name = "SynthesiaMode"
	gamemode_name = "synthesia_mode"
	
	game.pause_screen_name = "playlist_mode_pause"
	game.game_over_screen_name = "playlist_mode_gameover"
	game.menu_screen_to_return = "synthesia_mode"

	game.timeline_started.connect(_connect_timeline)
	_load_ui()

	Data.profile.settings_changed.connect(_sync_settings)
	_sync_settings()

	time_timer = Timer.new()
	time_timer.timeout.connect(_update_time)
	time_timer.one_shot = false
	add_child(time_timer)
	time_timer.start(1.0)
	
	# Inject our settings into blank skin data
	game.skin.skin_data.metadata.bpm = bpm
	game.skin.skin_data.metadata.name = music_file_path_to_load.get_file()
	game.skin.skin_data.metadata.artist = "BPM : " + str(bpm)
	game.skin.bpm = bpm
	game.skin.skin_data.stream["music"] = music_stream
	game.skin.skin_data.metadata["settings"]["no_shaking"] = true
	
	var scenery_path : String
	match visualiser:
		VISUALISER.SHOCKWAVE : scenery_path = "res://scenery/game/skin_scenes/shockwave_visualizer.tscn"
		VISUALISER.SHOCKWAVE_SIMPLE : scenery_path = "res://scenery/game/skin_scenes/shockwave_visualizer_simple.tscn"
		VISUALISER.REZ : scenery_path = "res://scenery/game/skin_scenes/rez_visualizer2.tscn"
	
	match sound_set:
		SOUND_SET.DRUMS:
			game.skin.skin_data.sounds = {
				# Multi-sounds, stored as Arrays which contain multiple AudioStreams, all Arrays must end with 'null'
				"bonus" : [null], # 4X Bonus
				"square" : [load("res://internal/sounds/drums/dec1.ogg"),load("res://internal/sounds/drums/dec2.ogg"),null], # Square creation
				"special" : [load("res://internal/sounds/drums/blast4.ogg"),null], # Special block erase
				"timeline" : [load("res://internal/sounds/drums/dec_lp.ogg"),null], # Timeline erasing blocks
				"blast" : [load("res://internal/sounds/drums/blast1.ogg"),load("res://internal/sounds/drums/blast2.ogg"),load("res://internal/sounds/drums/blast3.ogg"),null], # Square blast
				
				# Single sounds
				"move" : load("res://internal/sounds/drums/move.ogg"), # Piece move
				"rotate_left" : load("res://internal/sounds/drums/lrot.ogg"), # Piece left rotation
				"rotate_right" : load("res://internal/sounds/drums/rrot.ogg"), # Piece right rotation
				"left_dash" : load("res://internal/sounds/drums/dash.ogg"), # Piece left dash
				"right_dash" : load("res://internal/sounds/drums/dash.ogg"), # Piece right dash
				"drop" : load("res://internal/sounds/drums/drop.ogg"), # Piece drop
				"queue_shift" : load("res://internal/sounds/drums/shift.ogg"), # Queue shift
				"level_up" : null, # Level up
				"special_bonus" : null, # Single color/All clear bonus sound
				"ending" : null
			}
		
		SOUND_SET.BFXR:
			game.skin.skin_data.sounds = {
				# Multi-sounds, stored as Arrays which contain multiple AudioStreams, all Arrays must end with 'null'
				"bonus" : [load("res://internal/sounds/bfxr/bonus.ogg"),null], # 4X Bonus
				"square" : [load("res://internal/sounds/bfxr/square1.ogg"),load("res://internal/sounds/bfxr/square2.ogg"),load("res://internal/sounds/bfxr/square3.ogg"),null], # Square creation
				"special" : [load("res://internal/sounds/bfxr/special.ogg"),null], # Special block erase
				"timeline" : [load("res://internal/sounds/bfxr/scan.ogg"),null], # Timeline erasing blocks
				"blast" : [load("res://internal/sounds/bfxr/blast1.ogg"),load("res://internal/sounds/bfxr/blast2.ogg"),load("res://internal/sounds/bfxr/blast3.ogg"),load("res://internal/sounds/bfxr/blast4.ogg"),load("res://internal/sounds/bfxr/blast5.ogg"),null], # Square blast
				
				# Single sounds
				"move" : load("res://internal/sounds/bfxr/move.ogg"), # Piece move
				"rotate_left" : load("res://internal/sounds/bfxr/lrot.ogg"), # Piece left rotation
				"rotate_right" : load("res://internal/sounds/bfxr/rrot.ogg"), # Piece right rotation
				"left_dash" : load("res://internal/sounds/bfxr/dash.ogg"), # Piece left dash
				"right_dash" : load("res://internal/sounds/bfxr/dash.ogg"), # Piece right dash
				"drop" : load("res://internal/sounds/bfxr/on.ogg"), # Piece drop
				"queue_shift" : load("res://internal/sounds/bfxr/swap.ogg"), # Queue shift
				"level_up" : null, # Level up
				"special_bonus" : load("res://internal/sounds/bfxr/specialbonus.ogg"), # Single color/All clear bonus sound
				"ending" : null
			}

	var scenery : Node = load(scenery_path).instantiate()
	game.skin.get_node("Back").add_child(scenery)
	scenery.position = Vector2(-960,-540)
	game.skin.scene_player = scenery.get_node("A")
	scenery.get_node("A").assigned_animation = "main"
	scenery.get_node("A").speed_scale = bpm/120.0

	if is_single_run : game.skin.song_finished.connect(game._game_over)


# Called on game reset.
func _reset() -> void:
	level_count = 1
	score = 0
	deleted_squares = 0
	deleted_blocks = 0
	combo = 0
	time = 0
	time_timer.start(1.0)

	current_lap = -1
	
	scoreboard._set_value(0,"time")
	scoreboard._set_value([1,1,current_lap],"level")
	scoreboard._set_value(0,"score")
	scoreboard._set_value(0,"deleted")
	
	await get_tree().create_timer(0.01).timeout
	reset_complete.emit()


# Called on game retry.
func _retry() -> void:
	_reset()

	await get_tree().create_timer(0.01).timeout
	retry_complete.emit()
