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


extends Resource

#-----------------------------------------------------------------------
# Skin data class aka ".skn" file format
# This file format is used by Luminext to store and load skin assets.
#-----------------------------------------------------------------------

class_name SkinData

signal skin_loaded
@warning_ignore("unused_signal") # Ignored because is used via "call_deferred"
signal io_progress(progress : int) # Emitted on each step of skin loading/saving process
signal skin_saved

const VERSION : int = 7 # Current skin data version

# All supported block animation patterns
enum BLOCK_ANIM_PATTERN {
	EACH_BEAT,
	EACH_2BEATS,
	EACH_BAR,
	EACH_HALF_BEAT,
	COLOR_ORDER,
	CONSTANT_LOOPING
	} 

# All supported UI designs
enum UI_DESIGN {
	STANDARD,
	SHININ,
	SQUARE,
	MODERN,
	LIVE,
	PIXEL,
	BLACK,
	COMIC,
	CLEAN,
	VECTOR,
	TECHNO,
	} 

var version : int = VERSION 
var metadata : SkinMetadata = SkinMetadata.new()

var video_is_cached : bool = false
var scenery_is_cached : bool = false

# List of words which are banned in custom scene scripts. If such words were found on scene check, scene wont be loaded.
const BANNED_WORDS : PackedStringArray = ["FileAccess","DirAccess","IP","JavaClassWrapper","JavaScriptBridge","JavaScriptObject","JavaClass",
"GDExtensionManager","GDExtension","OS","ProjectSettings","ResourceLoader","ResourceSaver","Engine","bytes_to_var","bytes_to_var_with_objects",
"var_to_str","str_to_var","var_to_bytes","var_to_bytes_with_objects","dict_to_inst","inst_to_dict","JSONRPC","JSON","change_scene_to_file",
"change_scene_to_packed","get_multiplayer","MultiplayerAPI","MultiplayerAPIExtension","MultiplayerPeer","MultiplayerPeerExtension","MultiplayerSpawner",
"MultiplayerSynchronizer","ENetMultiplayerPeer","SceneMultiplayer","quit","reload_current_scene","unload_current_scene","Window","get_last_exclusive_window",
"get_viewport","get_window","propagate_call","propagate_notification","rpc","rpc_config","rpc_id","multiplayer","HTTPRequest","ResourcePreloader","FileDialog",
"HTTPClient","Crypto","DTLSServer","ENetConnection","PacketPeer","ENetPacketPeer","OfflineMultiplayerPeer","WebRTCMutliplayerPeer","WebSocketMultiplayerPeer",
"PacketPeerDTLS","PacketPeerUDP","WebRTCDataChannel","WebRTCDataChannelExtension","WebSocketPeer","PCKPacker","CryptoKey","PackedScene","SceneReplicationConfig",
"X509Certificate","ResourceFormatLoader","ResourceFormatSaver","StreamPeer","StreamPeerBuffer","StreamPeerExtension","StreamPeerGZIP","StreamPeerTCP","StreamPeerTLS",
"TCPServer","TLSOptions","UDPServer","UPNP","UPNPDevice","WebRTCPeerConnection","WebRTCPeerConnectionExtension","WebRTCDataChannel","WebRTCDataChannelExtension",
"XMLParser","ZIPPacker","ZIPReader","AcceptDialog","ConfirmationDialog","Popup","PopupMenu","PopupPanel"]

# List of nodes which are banned in custom scene. If such nodes were found on scene check, scene wont be loaded.
const BANNED_NODES : PackedStringArray = ["HTTPRequest","Window","AcceptDialog","ConfirmationDialog","Popup","PopupMenu","PopupPanel","FileDialog",
"MultiplayerSpawner","MultiplayerSynchronizer","ResourcePreloader",""]

var sounds : Dictionary = {
	# Multi-sounds, stored as Arrays which contain multiple AudioStreams, all Arrays must end with 'null' entry
	"bonus" : [null], # 4X Bonus
	"square" : [null], # Square creation
	"special" : [null], # Special block erase
	"timeline" : [null], # Timeline erasing blocks
	"blast" : [null], # Square blast
	
	# Single sounds
	"move" : null, # Piece move
	"rotate_left" : null, # Piece left rotation
	"rotate_right" : null, # Piece right rotation
	"left_dash" : null, # Piece left dash
	"right_dash" : null, # Piece right dash
	"drop" : null, # Piece drop
	"queue_shift" : null, # Queue shift
	"level_up" : null, # Level up
	"special_bonus" : null, # Single color/All clear bonus sound

	"ending" : null, # Music ending sample, would play when skin is ended
}

# Skin textures and other graphics data dictionary
var textures : Dictionary = {
	# Those three entries below contains SpriteFrames, which allow us to animate blocks and squares
	# They should be modified only thru special "_update_texture_sheet" function
	"block" : "res://images/game/export/block_frames.tres",
	"special" : "res://images/game/export/special_frames.tres",
	"square" : "res://images/game/export/square_frames.tres",
	
	"erase" : "res://images/game/export/erase.png", # Erased block texture
	"select" : "res://images/game/export/select.png", # Selected to remove block texture
	"multi_mark" : "res://images/game/export/multi_mark.png", # Multi block mark texture
	
	"effect_1" : "res://images/game/export/star.png", # Blast effect star sprite
	"effect_2" : "res://images/game/export/big_star.png", # Blast effect second star sprite

	# Effects colors
	"red_fx" : Color("ec7d24"),
	"white_fx" : Color.AQUAMARINE,
	"green_fx" : Color.GREEN,
	"purple_fx" : Color.PURPLE,
	
	# UI colors
	"eq_visualizer_color" : Color.BLACK,
	"ui_color" : Color.WHITE,
	"timeline_color" : Color(1.0,0.75,0.0),
	
	"ui_design" : UI_DESIGN.STANDARD,
	
	# Arrays which control block/squares animation timing:
	# 1st index - half-beats offset - Offsets animation start
	# 2nd index - half-beats per animation - How many half-beats we must wait to start blocks animation
	# 3rd index - animation FPS - How fast this animation plays
	# In frontend all of those values are changed via predefined "BLOCK_ANIM_PATTERN" enum patterns
	"red_anim" : [0,8,36],
	"white_anim" : [4,8,36],
	"green_anim" : [0,8,36],
	"purple_anim" : [4,8,36],
	
	# Bonus animation textures
	"arrow_1" : "res://images/game/export/arrow.png", # 1X Combo big arrow
	"arrow_2" : "res://images/game/export/arrow.png", # 2X Combo big arrow
	"arrow_3" : "res://images/game/export/arrow.png", # 3X Combo big arrow
	"arrow_4" : "res://images/game/export/arrow.png", # 4 and more X Combo big arrow
	"2_tex" : "res://images/game/export/2.png", #2X Combo number
	"3_tex" : "res://images/game/export/3.png", #3X Combo number
	"4_tex" : "res://images/game/export/4.png", #4X Combo number
	
	# Static background
	"back" : "res://images/game/export/background.png", 
}

# All avaiable in-game effects
# It's currently not saved inside .skn file, and cannot be edited outside of this code
var fx : Dictionary = {
	"square" : load("res://scenery/game/effects/fx_square.tscn"),
	"num" : load("res://scenery/game/effects/fx_number.tscn"),
	"scorenum" : load("res://scenery/game/effects/fx_score_number.tscn"),
	"blast" : load("res://scenery/game/effects/fx_blast.tscn"),
	"blast_fury" : "res://scenery/game/effects/fx_blast_fury.tscn",
	"erase" : load("res://scenery/game/effects/fx_erase.tscn"),
	"merge" : "res://scenery/game/effects/fx_merge.tscn",
	"levelup" : "res://scenery/game/effects/fx_level_up.tscn",
	"message" : load("res://scenery/game/effects/fx_message.tscn"),
	"special_message" : load("res://scenery/game/effects/fx_spec_message.tscn"),
	"laser" : "res://scenery/game/effects/fx_laser.tscn",
	"wipe" : "res://scenery/game/effects/fx_wipe.tscn",
}

# Contains heavy things such as video and godot scenery.
var stream : Dictionary = {
	"music" : null,
	"scene" : null, # Custom godot scene package file (.pak/.zip)
	"scene_format" : "", 
	"scene_path" : "", # Path to the scene file in imported pack directory
	
	# Record of who ever edited this skin
	# ["time_stamp", "editor", ....] 
	# Stored in "stream" to make modifying this value externally harder.
	"edit_history" : PackedStringArray(),  
	
	"video" : null, # Background video (.webm, .mp4)
	"video_format" : "",
}


# Prepares SkinData to be usable
func _init() -> void:
	if Data.main != null:
		io_progress.connect(Data.main._change_loading_message)


# Clones this SkinData and returns cloned resource
func _clone() -> SkinData:
	var clone_skin : SkinData = SkinData.new()

	clone_skin.metadata = metadata._duplicate()
	clone_skin.textures = textures.duplicate(true)
	clone_skin.sounds = sounds.duplicate(true)
	clone_skin.stream = stream.duplicate(true)

	return clone_skin


# Reloads all standard textures from "res://images/game/export/" path, making them able to be exported and loaded back later
func _load_standard_textures() -> void:
	# Create new exportable atlas texture, to replace all atlases inside SpriteFrames
	var block_sheet : Image = load("res://images/game/export/blocks_sheet_image.png")
	block_sheet.fix_alpha_edges()
	var atlas_texture : PortableCompressedTexture2D = PortableCompressedTexture2D.new()
	atlas_texture.keep_compressed_buffer = true
	atlas_texture.create_from_image(block_sheet, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
	
	# Replace atlases in SpriteSheets, making them independant from original file inside project path
	for animated_texture_entry : String in ["block","special","square"]:
		var sprite_sheet : SpriteFrames = load(textures[animated_texture_entry])
		
		for animation_name : String in sprite_sheet.get_animation_names():
			for frame : int in sprite_sheet.get_frame_count(animation_name):
				var origin_texture : AtlasTexture = sprite_sheet.get_frame_texture(animation_name, frame)
				origin_texture.atlas = atlas_texture
		
		textures[animated_texture_entry] = sprite_sheet
	
	# Here we specify single (not animated) texture entries we wanna make exportable
	var texture_entries : Array[String] = ["erase","select","multi_mark","effect_1","effect_2","arrow_1","arrow_2",
	"arrow_3","arrow_4","2_tex","3_tex","4_tex","back"]
	
	for texture_entry : String in texture_entries:
		var texture_path : String = textures[texture_entry]
		
		var texture_image : Image = load(texture_path)
		texture_image.fix_alpha_edges()
		var export_texture : PortableCompressedTexture2D = PortableCompressedTexture2D.new()
		export_texture.keep_compressed_buffer = true
		export_texture.create_from_image(texture_image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
		
		textures[texture_entry] = export_texture


# Replaces animation in one of the existing SpriteFrames in "texture" Dictionary
# - "new_texture" - Could be either single image, either SprtieFrames object with single "default" animation, which would be used as replacement
# - "animation_name" - Animation name to replace, must be some real existing name from one of the three SpriteFrames (check "*_frames.tres" inside "images/game" folder)
func _update_sprite_sheet(new_texture : Variant, animation_name : String) -> void:
	var sprite_sheet_name : String = ""
	
	if animation_name in textures["block"].get_animation_names(): sprite_sheet_name = "block"
	elif animation_name in textures["special"].get_animation_names(): sprite_sheet_name = "special"
	elif animation_name in textures["square"].get_animation_names(): sprite_sheet_name = "square"
	else : return
	
	textures[sprite_sheet_name].clear(animation_name)
	
	if new_texture is SpriteFrames:
		for frame : int in new_texture.get_frame_count("default"):
			textures[sprite_sheet_name].add_frame(animation_name,new_texture.get_frame_texture("default",frame))
		
		textures[sprite_sheet_name].set_animation_speed(animation_name,new_texture.get_frame_count("default") * 6)
		
		if not animation_name.ends_with("chain"):
			if animation_name.begins_with("r"): textures[sprite_sheet_name].set_animation_speed(animation_name,textures["red_anim"][2])
			elif animation_name.begins_with("wh"): textures[sprite_sheet_name].set_animation_speed(animation_name,textures["white_anim"][2])
			elif animation_name.begins_with("gr"): textures[sprite_sheet_name].set_animation_speed(animation_name,textures["green_anim"][2])
			elif animation_name.begins_with("p"): textures[sprite_sheet_name].set_animation_speed(animation_name,textures["purple_anim"][2])
	
	else:
		textures[sprite_sheet_name].add_frame(animation_name,new_texture)


# Saves skin into specified path as '.skn' file
func _save(path : String = "") -> int:
	print("")
	print("SKIN SAVING STARTED...")
	call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.SKIN_SAVE_START)
	
	# If no path is specified, use standard skins directory with file name snake_cased
	if path == "":
		path = Data.SKINS_PATH + metadata.name + ".skn"
		path = path.replace(" ","_").to_lower()
	
	var file : FileAccess = FileAccess.open_compressed(path,FileAccess.WRITE,FileAccess.COMPRESSION_DEFLATE)
	if not file: 
		print("FILE ERROR! : ", error_string(FileAccess.get_open_error()))
		file.close()
		return FileAccess.get_open_error()
	
	var save_start_time : float = Time.get_unix_time_from_system()
	stream["edit_history"].append(str(save_start_time))
	stream["edit_history"].append(Data.profile.name)
	
	metadata.skin_by = Data.profile.name
	metadata.save_date = save_start_time
	metadata.path = path
	print("SAVE STARTED AT : ", Time.get_datetime_string_from_unix_time(save_start_time as int).replace("T"," "))
	
	print("PREPARING AUDIO")
	call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.AUDIO_PREPARE)
	
	if stream["music"] != null and stream["music"] is String:
		var sample : AudioStream = null
		
		if stream["music"].ends_with(".ogg"): 
			sample = AudioStreamOggVorbis.load_from_file(stream["music"])
			
		elif stream["music"].ends_with(".mp3"): 
			var music_file : FileAccess = FileAccess.open(stream["music"], FileAccess.READ)
			if not music_file:
				print("MUSIC FILE ERROR : ", error_string(FileAccess.get_open_error()))
			
			sample = AudioStreamMP3.new()
			sample.data = music_file.get_buffer(music_file.get_length())
			music_file.close()
			
		elif stream["music"].ends_with(".wav"): 
			var audio_loader : AudioLoader = AudioLoader.new()
			sample = audio_loader.loadfile(stream["music"])
		
		else:
			print("ERROR! INVALID MUSIC FORMAT")
		
		stream["music"] = sample
		print("DONE")
	
	print("PREPARING VIDEO")
	call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.VIDEO_PREPARE)
	
	if stream["video"] != null and stream["video"] is String:
		stream["video_format"] = stream["video"].get_extension()
		
		if stream["video_format"] in ["ogv","webm","mp4"]:
			stream["video"] = FileAccess.get_file_as_bytes(stream["video"])
			if stream["video"].is_empty():
				print("VIDEO FILE ERROR : ", error_string(FileAccess.get_open_error()))
			else:
				print("DONE")
		else:
			print("INVALID VIDEO FORMAT")
	
	print("PREPARING SCENERY")
	call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.SCENE_PREPARE)
	
	if stream["scene"] != null and stream["scene"] is String:
		stream["scene_format"] = stream["scene"].get_extension()
		
		if stream["scene_format"] in ["pck","zip"]:
			stream["scene"] = FileAccess.get_file_as_bytes(stream["scene"])
			if stream["scene"].is_empty():
				print("SCENE FILE ERROR : ", error_string(FileAccess.get_open_error()))
			else:
				print("DONE")
		else:
			print("INVALID SCENERY FORMAT")
	
	print("SAVING METADATA")
	call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.METADATA_SAVE)
	file.store_8(VERSION)
	metadata._save(file)
	
	print("SAVING SOUNDS")
	call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.AUDIO_SAVE)
	file.store_var(sounds,true)
	
	print("SAVING TEXTURES")
	call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.TEXTURES_SAVE)
	file.store_var(textures,true)
	
	print("SAVING STREAM DATA")
	call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.STREAM_SAVE)
	file.store_var(stream,true)
	
	print("FINISH!")
	call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.FINISH)
	file.close()
	
	var save_end_time : float = Time.get_unix_time_from_system()
	print("SAVE LASTED : ", Time.get_time_string_from_unix_time(int(save_end_time - save_start_time)))
	
	skin_saved.emit()
	return OK


# Loads SkinData from AddonPack file, path to addon must be specified in passed SkinMetadata
# Currently commented because AddonPack class was temporarily removed from the project
#func _load_from_addon(skin_metadata : SkinMetadata) -> int:
	#if skin_metadata.path.is_empty():
		#print("ERROR! NO ADDON FILE FOUND") 
		#return ERR_FILE_NOT_FOUND
#
	#var addon : AddonPack = AddonPack.new()
	#addon._load(skin_metadata.path)
#
	#var skins_dict : Dictionary = addon.internal_data["skins"]
#
	#var file : FileAccess = FileAccess.open_compressed(skin_metadata.path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	#if not file:
		#print("ERROR! ADDON FILE LOADING FAILED : ", FileAccess.get_open_error())
		#file.close()
		#return FileAccess.get_open_error()
#
	## Skip first two dictionaries stored in file, which contain addon & content metadata
	#file.get_8()
	#file.get_var(true)
	#file.get_var(true)
#
	#var distance_to_skin_contents : int = 0
	#for skin : String in skins_dict:
		#if skin == skin_metadata["name"]: break
		#distance_to_skin_contents += skins_dict[skin][0]
#
	#file.seek(file.get_position() + distance_to_skin_contents)
#
	#var ver : int = file.get_8()
	#print(ver)
#
	#if ver == VERSION :
		#print("SKN VERSION 7 DETECTED!")
#
		## Load data
		#metadata = file.get_var(true)
		#print(metadata)
		#sounds = file.get_var(true)
		#textures = file.get_var(true)
		#stream = file.get_var(true)
	#else:
		#Data.main._display_system_message("ERROR! DEPRECATED SKN FILE VERSION!")
		#print("ERROR! DEPRECATED SKN FILE VERSION!")
		#file.close()
		#emit_signal("skin_loaded")
		#return ERR_INVALID_DATA
#
	#file.close()
	#emit_signal("skin_loaded")
	#return OK


# This function loads SkinData from file
# If 'file' is passed, this FileAccess instance would be used to load SkinData (with possibly different file path and file cursor position)
func _load_from_path(path : String, file : FileAccess = null) -> int:
	
	print("")
	print("SKIN LOADING STARTED...")
	if file == null:
		file = FileAccess.open_compressed(path,FileAccess.READ,FileAccess.COMPRESSION_DEFLATE)
		if not file: 
			print("SKIN FILE ERROR! : " + error_string(FileAccess.get_open_error()))
			skin_loaded.emit()
			return FileAccess.get_open_error()
	
	call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.SKIN_LOAD_START)
	var ver : int = file.get_8()
	
	if ver == VERSION :
		print("SKN VERSION 7 DETECTED!")
		
		# Load data
		metadata = SkinMetadata.new()
		call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.METADATA_LOAD)
		metadata._load(file)
		call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.AUDIO_LOAD)
		sounds = file.get_var(true)
		call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.TEXTURES_LOAD)
		textures = file.get_var(true)
		call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.STREAM_LOAD)
		stream = file.get_var(true)

		_cache_video()
		_cache_godot_scene()
	
	else:
		print("DEPRECATED SKN VERSION!")
		file.close()
		skin_loaded.emit()
		return ERR_INVALID_DATA

	print("FINISH!")
	call_deferred("emit_signal", "io_progress", Data.LOADING_STATUS.FINISH)
	file.close()
	version = ver
	skin_loaded.emit()
	return OK


# Loads video and caches it in Data.CACHE_PATH, so skin can access it. Sets 'video_is_cached' true on success.
func _cache_video() -> void:
	video_is_cached = false
	
	if stream["video"] == null: return 
	if stream["video"].is_empty(): return 
	if Data.profile.config["video"]["disable_video"] : return
	
	print("CACHING VIDEO")
	var extension : String = stream["video_format"]
	if not extension in ["webm","mp4","ogv"]: 
		print("VIDEO CACHE FAILED! INVALID FORMAT")
		return
	
	var cached_video_name : String = "video." + extension 
	if Data.use_second_cache: cached_video_name = "video2." + extension 
	
	var file : FileAccess = FileAccess.open(Data.CACHE_PATH + cached_video_name,FileAccess.WRITE)
	if not file : 
		print("VIDEO CACHE FAILED! FILE ERROR : ", error_string(FileAccess.get_open_error()))
		return
	file.store_buffer(stream["video"])
	file.close()

	video_is_cached = true
	print("VIDEO IS CACHED!")


# Loads packed Godot scenery stored in skin data
func _cache_godot_scene() -> void:
	scenery_is_cached = false

	if stream["scene"] == null: return 
	if not stream.has("scene_path"): return 
	if Data.profile.config["video"]["disable_scenery"] : return
	
	print("CACHING SCENE")
	var extension : String = stream["scene_format"]
	if not extension in ["pck","zip"] : 
		print("SCENE CACHE FAILED! INVALID FORMAT")
		return
	
	var cached_scene_name : String = "scene." + stream["scene_format"]
	if Data.use_second_cache: cached_scene_name = "scene2." + stream["scene_format"]
	
	var file : FileAccess = FileAccess.open(Data.CACHE_PATH + cached_scene_name, FileAccess.WRITE)
	if not file : 
		print("SCENE CACHE FAILED! FILE ERROR : ", error_string(FileAccess.get_open_error()))
		return
	file.store_buffer(stream["scene"])
	file.close()
	
	var success : bool = ProjectSettings.load_resource_pack(Data.CACHE_PATH + cached_scene_name, false)
	if not success: 
		print("SCENE PACK LOAD ERROR!")
		return
	
	if not _check_godot_scene():
		print("SCENE CHECK FAILED! THIS SCENE CONTAINS SCRIPTS OR NODES WITH MALICIOUS CODE!!")
		return

	scenery_is_cached = true
	print("SCENE IS CACHED!")


# Checks loaded godot scenery for malicious code
func _check_godot_scene() -> bool:
	print("CHECKING SCENE SCRIPTS...")

	if not ResourceLoader.exists("res://" + stream["scene_path"]): 
		print("SCENE CHECK FAILED! MISSING PATH! ", stream["scene_path"])
		return false

	var scene_state : SceneState = load("res://" + stream["scene_path"]).get_state()

	for node_id : int in scene_state.get_node_count():
		for prop_id : int in scene_state.get_node_property_count(node_id):
			if scene_state.get_node_property_name(node_id, prop_id) == "script":
				print("SCRIPT FOUND! NODE : ", scene_state.get_node_name(node_id), ", id = ", node_id)

				var type : StringName = scene_state.get_node_type(node_id)
				if type in BANNED_NODES:
					print("BANNED NODE: ", type, " DETECTED!")
					return false

				var script : Script = scene_state.get_node_property_value(node_id, prop_id)
				if not script.has_source_code():
					print("EMPTY SCRIPT SOURCE CODE! PLEASE DISABLE BINARY TOKENIZATION ON SCENE EXPORT!")
					return false
				
				var source_code : String = script.source_code
				for bad_word : String in BANNED_WORDS:
					if source_code.contains(bad_word):
						print("BANNED WORD: ", bad_word, " DETECTED!")
						return false
	print("OK!")
	return true