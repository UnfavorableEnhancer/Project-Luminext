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


extends PlaylistMode

class_name SynthesiaMode

##-----------------------------------------------------------------------
## Synthesia mode
## Allows to play any provided music file with cool visualizer background
##-----------------------------------------------------------------------

enum SYNTHESIA_MODE_ERROR {
	OK,
	FAILED_TO_CALCULATE_BPM, ## We are in single skin mode, so skin change isn't possible
	FAILED_TO_LOAD_MUSIC, ## Hit playlist end
	FAILED_TO_LOAD_SCENE, ## Current playlist is empty
	FAILED_TO_LOAD_SFX, ## Failed to retreive skin data from playlist
}

enum VISUALISER {SHOCKWAVE, SHOCKWAVE_SIMPLE, REZ} ## Avaiable background visualizers
enum SOUND_SET {DRUMS, BFXR, CALM, TECHNO} ## Avaiable soundsets

const BPM_CALCULATE_MUSIC_FILE_SIZE : int = 512000 ## Size of stripped music file for use in bpm calculation application

var visualiser : int = VISUALISER.SHOCKWAVE ## Selected background visualizer
var sound_set : int = 0 ## Selected soundset
var music_file_path_to_load : String = "" ## Path to the music file to load

var use_precise_bpm_calculation : bool = false ## If true, doesn't strip music file size, allowing CLI aplication to process it fully and give more accurate BPM calculation


func _ready() -> void:
	super()

	name = "SynthesiaMode"
	gamemode_name = "synthesia_mode"
	game.menu_screen_to_return = "synthesia_mode"
	is_single_skin_mode = true


## Called on game reset.
func _reset() -> int:
	level = 1

	if game.skin == null:
		var bpm : float = _calculate_bpm()
		if bpm == 0.0 : 
			return SYNTHESIA_MODE_ERROR.FAILED_TO_CALCULATE_BPM

		var error_code : int = await _build_skin(bpm)
		if error_code > 0:
			return error_code

	main._toggle_loading(false)
	await get_tree().create_timer(0.5).timeout

	current_lap = 0 if is_single_run else 1
	if is_single_skin_mode : current_lap = -1
	scoreboard._set_value([1,1,current_lap],"level")

	time_timer.start(1.0)
	game.piece_queue._reset()
	game._give_new_piece()
	game.skin._start()
	
	return OK


## Calculates provided music BPM and returns its value
func _calculate_bpm() -> float:
	if not music_file_path_to_load.get_extension() in ["mp3","ogg","wav"]:
		error_text = "Invalid file extension! Only MP3, OGG and WAV are supported"
		return 0.0

	var file : FileAccess
	var process_file_path : String = ""

	main.call_deferred("_set_loading_message", Data.LOADING_STATUS.CALCULATING_BPM)
		
	if use_precise_bpm_calculation:
		process_file_path = music_file_path_to_load
	else:
		# We make stripped down version of our music file so it wouldn't take long to process
		file = FileAccess.open(music_file_path_to_load, FileAccess.READ)

		var buffer_file_path : String = Data.CACHE_PATH + "music." + music_file_path_to_load.get_extension()
		var buffer_file : FileAccess = FileAccess.open(buffer_file_path, FileAccess.WRITE)

		var buffer : PackedByteArray = file.get_buffer(BPM_CALCULATE_MUSIC_FILE_SIZE)
		buffer_file.store_buffer(buffer)
		process_file_path = buffer_file.get_path_absolute()
		
		buffer_file.close()
		file.close()
	
	# Put our stripped music file into Essentia rhythm extractor CLI application (it was the easiest and fastest way to get it done)
	var shell_output : Array = []
	if OS.has_feature("linux") : OS.execute("third_party/essentia/essentia_streaming_rhythmextractor_multifeature", [process_file_path], shell_output)
	elif OS.has_feature("windows") : OS.execute("third_party/essentia/essentia_streaming_rhythmextractor_multifeature.exe", [process_file_path], shell_output)
	else : 
		error_text = "Failed to start BPM calculation software"
		return 0.0

	# Parse shell output to get our calculated BPM
	var shell_text : String = shell_output[0]
	var bpm_start_pos : int = shell_text.find("bpm", 40)
	var bpm_text : String = shell_text.substr(bpm_start_pos + 4, bpm_start_pos + 4 + 8)
	var calculated_bpm : float = float(bpm_text)

	# In case this programm fails, set BPM to standard 120
	if calculated_bpm < 1: calculated_bpm = 120.0

	return calculated_bpm


## Loads special skin and injects selected data into it. Returns 0 on success
func _build_skin(skin_bpm : float) -> int:
	var synthesia_skin : SkinData = SkinData.new()
	synthesia_skin.metadata.bpm = skin_bpm
	synthesia_skin.metadata.name = music_file_path_to_load.get_file()
	synthesia_skin.metadata.artist = "BPM : " + str(skin_bpm)
	synthesia_skin.metadata["settings"]["no_shaking"] = true

	# Load music file
	var music_stream : AudioStream
	if music_file_path_to_load.ends_with(".ogg") : music_stream = AudioStreamOggVorbis.load_from_file(music_file_path_to_load)
	elif music_file_path_to_load.ends_with(".mp3") : music_stream = AudioStreamMP3.load_from_file(music_file_path_to_load)
	elif music_file_path_to_load.ends_with(".wav") : music_stream = AudioStreamWAV.load_from_file(music_file_path_to_load)
	else : 
		error_text = "Failed to load provided music file"
		return SYNTHESIA_MODE_ERROR.FAILED_TO_LOAD_MUSIC

	synthesia_skin.stream["music"] = music_stream

	# Load selected SFX
	match sound_set:
		SOUND_SET.DRUMS:
			synthesia_skin.sounds = {
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
		
		_, SOUND_SET.BFXR:
			synthesia_skin.sounds = {
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
	
	var scenery_path : String
	match visualiser:
		VISUALISER.SHOCKWAVE : scenery_path = "res://scenery/game/skin_scenes/shockwave_visualizer.tscn"
		VISUALISER.SHOCKWAVE_SIMPLE : scenery_path = "res://scenery/game/skin_scenes/shockwave_visualizer_simple.tscn"
		_, VISUALISER.REZ : scenery_path = "res://scenery/game/skin_scenes/rez_visualizer2.tscn"

	var skin_change_result : int = await game._change_skin(synthesia_skin, true)
	if skin_change_result > 1:
		error_text = "Failed to load synthesia skin"
		return skin_change_result
	
	var scenery : Node = load(scenery_path).instantiate()
	game.skin.get_node("Back").add_child(scenery)
	scenery.position = Vector2(-960,-540)
	game.skin.scene_player = scenery.get_node("A")
	scenery.get_node("A").assigned_animation = "main"
	scenery.get_node("A").speed_scale = skin_bpm/120.0

	if is_single_run : game.skin.music_player.finished.connect(game._game_over)

	return 0


## Executes entered into Console command
func _execute_console_command(command : String, arguments : PackedStringArray) -> void:
	match command:
		# Prints current gamemode info
		"ginfo" : 
			Console._output("Synthesia mode info")
			Console._output("WIP")
	
	super(command, arguments)