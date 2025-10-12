# Project Luminext - an ultimate block-stacking puzzle game
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


extends Resource

##-----------------------------------------------------------------------
## Contains all skin assets, metadata and settings and saves them in .skn formatted file
##-----------------------------------------------------------------------

class_name SkinData


@warning_ignore("unused_signal") # Ignored because is used via "call_deferred"
signal io_progress(progress : int) ## Emitted on each step of skin loading/saving process

@warning_ignore("unused_signal") # Ignored because is used via "call_deferred"
signal skin_loaded ## Emitted when skin load finishes

@warning_ignore("unused_signal") # Ignored because is used via "call_deferred"
signal skin_saved ## Emitted when skin save finishes

const VERSION : int = 7 ## Latest .skn format version

## All supported block animation patterns
enum BLOCK_ANIM_PATTERN {
	EACH_BEAT,
	EACH_2BEATS,
	EACH_BAR,
	EACH_HALF_BEAT,
	COLOR_ORDER = 5,
	CONSTANT_LOOPING = 6
	} 

## All supported UI designs
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

var version : int = VERSION ## Currently loaded skin format version
var metadata : SkinMetadata = SkinMetadata.new() ## Skin metadata which contains its name, id and other info which could be loaded first quickly

var video_is_cached : bool = false ## True if this skin video was cached to [constant Data.CACHE_PATH]
var scenery_is_cached : bool = false ## True if this skin scenery was cached to [constant Data.CACHE_PATH]

## List of words which are banned in custom scene scripts. If such words were found on custom scene check, scene wont be loaded.
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

## List of nodes which are banned in custom scene. If such nodes were found on custom scene check, scene wont be loaded.
const BANNED_NODES : PackedStringArray = ["HTTPRequest","Window","AcceptDialog","ConfirmationDialog","Popup","PopupMenu","PopupPanel","FileDialog",
"MultiplayerSpawner","MultiplayerSynchronizer","ResourcePreloader",""]

## Contains all skin SFX
var sounds : Dictionary = {
	# Multi-sounds, stored as arrays which contain multiple AudioStreams, all arrays must end with 'null' entry
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

## Contains all skin textures and other graphics settings
var textures : Dictionary = {
	# Those three entries below contains SpriteFrames, which allow us to animate blocks and squares
	# They should be modified only thru special "_update_texture_sheet" function
	"block" : "res://images/game/export/block_frames.tres", # All blocks spritesheet
	"special" : "res://images/game/export/special_frames.tres", # All special blocks overlays spritesheet
	"square" : "res://images/game/export/square_frames.tres", # All squares spritesheet
	
	"erase" : "res://images/game/export/erase.png", # Timeline scanned block overlay texture
	"select" : "res://images/game/export/select.png", # Selected to be deleted block overlay texture
	"multi_mark" : "res://images/game/export/multi_mark.png", # Active multi block mark overlay texture
	
	"effect_1" : "res://images/game/export/star.png", # Blast effect star sprite
	"effect_2" : "res://images/game/export/big_star.png", # Blast effect second star sprite

	# Effects colors
	"red_fx" : Color("ec7d24"),
	"white_fx" : Color.AQUAMARINE,
	"green_fx" : Color.GREEN,
	"purple_fx" : Color.PURPLE,
	
	# UI colors & design
	"eq_visualizer_color" : Color.BLACK,
	"ui_color" : Color.WHITE,
	"timeline_color" : Color(1.0,0.75,0.0),
	"ui_design" : UI_DESIGN.STANDARD,
	
	# Arrays which control block/squares animation timing:
	# 1st index - half-beats offset - Offsets animation start by specified amount of half-beats
	# 2nd index - half-beats per animation - Amount of half-beats before playing block animation
	# 3rd index - animation FPS - How fast this animation plays
	# In frontend all of those values are changed via predefined by "BLOCK_ANIM_PATTERN" enum patterns
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

## All avaiable effects [br]
## It's currently not saved inside .skn file, and cannot be edited outside of this code
var effects : Dictionary = {
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

## Contains heavy stuff like video and custom godot scene.
var stream : Dictionary = {
	"music" : null, # Skin music (.mp3/.ogg/.wav)
	"scene" : null, # Custom godot scene package file (.pak/.zip)
	"scene_format" : "", # Custom scene package file format
	"scene_path" : "", # Path to the scene file in imported pack directory
	
	# Record of who ever edited this skin
	# ["time_stamp", "editor", ....] 
	# Stored in "stream" to make modifying this value externally harder.
	"edit_history" : PackedStringArray(),  
	
	"video" : null, # Background video (.webm, .mp4)
	"video_format" : "", # Video file format
}


## Returns a copy of this [SkinData]
func _duplicate() -> SkinData:
	var clone_skin : SkinData = SkinData.new()

	clone_skin.version = version
	clone_skin.metadata = metadata._duplicate()
	clone_skin.textures = textures.duplicate(true)
	clone_skin.sounds = sounds.duplicate(true)
	clone_skin.stream = stream.duplicate(true)

	return clone_skin


## Loads all default textures from [i]'res://images/game/export/'[/i] path
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


## Replaces animation in one of the existing SpriteFrames in [b]'texture'[/b] Dictionary[br]
## - [b]'new_texture'[/b] - Could be either single image, either SprtieFrames object with single "default" animation, which would be used as replacement[br]
## - [b]'animation_name'[/b] - Animation name to replace, must be some real existing name from one of the three SpriteFrames (check "*_frames.tres" inside "images/game" folder)
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
			elif animation_name.begins_with("w"): textures[sprite_sheet_name].set_animation_speed(animation_name,textures["white_anim"][2])
			elif animation_name.begins_with("g") and animation_name != "garbage": textures[sprite_sheet_name].set_animation_speed(animation_name,textures["green_anim"][2])
			elif animation_name.begins_with("p"): textures[sprite_sheet_name].set_animation_speed(animation_name,textures["purple_anim"][2])
	
	else:
		textures[sprite_sheet_name].add_frame(animation_name,new_texture)


## Sets FPS for specified color animations inside [i]'block'[/i] and [i]'square'[/i] SpriteSheets[br]
## [b]'color'[/b] must be one of the following strings: [i]'red_anim', 'white_anim', 'green_anim'[/i] and [i]'purple_anim'[/i]
func _set_sprite_sheet_fps(color : String, fps : int) -> void:
	for sprite_sheet_name  : String in ["block","square"]:
		for animation_name : String in textures[sprite_sheet_name].get_animation_names():
			textures[sprite_sheet_name].set_animation_speed(animation_name,fps)
		
			if not animation_name.ends_with("chain"):
				match color:
					"red_anim" : if animation_name.begins_with("r"): textures[sprite_sheet_name].set_animation_speed(animation_name, fps)
					"white_anim" : if animation_name.begins_with("w"): textures[sprite_sheet_name].set_animation_speed(animation_name, fps)
					"green_anim" : if animation_name.begins_with("g") and animation_name != "garbage": textures[sprite_sheet_name].set_animation_speed(animation_name, fps)
					"purple_anim" : if animation_name.begins_with("p"): textures[sprite_sheet_name].set_animation_speed(animation_name, fps)


## Saves skin into specified path as .skn formatted file
func _save(path : String = "") -> int:
	call_deferred("emit_signal", "io_progress", LoadingScreen.LOADING_STATUS.SKIN_SAVE_START)
	
	# If no path is specified, use standard skins directory with file name snake_cased
	if path == "":
		path = Data.SKINS_PATH + metadata.name + ".skn"
		path = path.replace(" ","_").to_lower()
	
	Console._space.call_deferred()
	Console._log.call_deferred("Saving skin to the path : " + path)
	
	var file : FileAccess = FileAccess.open_compressed(path,FileAccess.WRITE,FileAccess.COMPRESSION_DEFLATE)
	if not file: 
		print("ERROR! Failed saving skin. File open error : ", error_string(FileAccess.get_open_error()))
		call_deferred("emit_signal", "skin_saved")
		return FileAccess.get_open_error()
	
	var save_start_time : float = Time.get_unix_time_from_system()
	stream["edit_history"].append(str(save_start_time))
	stream["edit_history"].append(Player.profile_name)
	
	metadata.skin_by = Player.profile_name
	metadata.save_date = save_start_time
	metadata.path = path
	
	Console._log.call_deferred("Preparing audio")
	call_deferred("emit_signal", "io_progress", LoadingScreen.LOADING_STATUS.AUDIO_PREPARE)
	
	if stream["music"] != null and stream["music"] is String:
		var sample : AudioStream = null
		
		if stream["music"].ends_with(".ogg"): sample = AudioStreamOggVorbis.load_from_file(stream["music"])
		elif stream["music"].ends_with(".mp3"): sample = AudioStreamMP3.load_from_file(stream["music"])
		elif stream["music"].ends_with(".wav"): sample = AudioStreamWAV.load_from_file(stream["music"])
		else: Console._log.call_deferred("ERROR! Invalid music file format")
		
		stream["music"] = sample
	
	Console._log.call_deferred("Preparing video")
	call_deferred("emit_signal", "io_progress", LoadingScreen.LOADING_STATUS.VIDEO_PREPARE)
	
	if stream["video"] != null and stream["video"] is String:
		stream["video_format"] = stream["video"].get_extension()
		
		if stream["video_format"] in ["webm","mp4"]:
			stream["video"] = FileAccess.get_file_as_bytes(stream["video"])
			if stream["video"].is_empty() : print("ERROR! Failed loading video file. File open error : ", error_string(FileAccess.get_open_error()))
		else:
			Console._log.call_deferred("ERROR! Invalid video file format")
	
	Console._log.call_deferred("Preparing custom godot scene")
	call_deferred("emit_signal", "io_progress", LoadingScreen.LOADING_STATUS.SCENE_PREPARE)
	
	if stream["scene"] != null and stream["scene"] is String:
		stream["scene_format"] = stream["scene"].get_extension()
		
		if stream["scene_format"] in ["pck","zip"]:
			stream["scene"] = FileAccess.get_file_as_bytes(stream["scene"])
			if stream["scene"].is_empty() : print("ERROR! Failed loading scene package file. File open error : ", error_string(FileAccess.get_open_error()))
		else:
			Console._log.call_deferred("ERROR! Invalid scene package file format")
	
	Console._log.call_deferred("Saving skin metadata")
	call_deferred("emit_signal", "io_progress", LoadingScreen.LOADING_STATUS.METADATA_SAVE)
	file.store_8(VERSION)
	metadata._save(file)
	
	Console._log.call_deferred("Saving skin sounds")
	call_deferred("emit_signal", "io_progress", LoadingScreen.LOADING_STATUS.AUDIO_SAVE)
	file.store_var(sounds,true)
	
	Console._log.call_deferred("Saving skin textures")
	call_deferred("emit_signal", "io_progress", LoadingScreen.LOADING_STATUS.TEXTURES_SAVE)
	file.store_var(textures,true)
	
	Console._log.call_deferred("Saving skin music/video/godot scene")
	call_deferred("emit_signal", "io_progress", LoadingScreen.LOADING_STATUS.STREAM_SAVE)
	file.store_var(stream,true)
	
	Console._log.call_deferred("Skin save finished!")
	call_deferred("emit_signal", "io_progress", LoadingScreen.LOADING_STATUS.FINISH)
	file.close()
	
	var save_end_time : float = Time.get_unix_time_from_system()
	Console._log.call_deferred("Saving lasted : " + Time.get_time_string_from_unix_time(int(save_end_time - save_start_time)))

	call_deferred("emit_signal", "skin_saved")
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


## Loads [SkinData] from .skn formatted file. [br]
## If [b]'file'[/b] is passed, this [FileAccess] instance would be used to load [SkinData] (with possibly different file path and file cursor position)
func _load_from_path(path : String, file : FileAccess = null) -> int:
	Console._space.call_deferred()
	
	if file == null:
		Console._log.call_deferred("Loading skin from path : " + path)

		file = FileAccess.open_compressed(path,FileAccess.READ,FileAccess.COMPRESSION_DEFLATE)
		if not file: 
			print("ERROR! Failed to open skin file. File open error : " + error_string(FileAccess.get_open_error()))
			call_deferred("emit_signal", "skin_loaded")
			return FileAccess.get_open_error()
	else:
		Console._log.call_deferred("Loading skin")

	call_deferred("emit_signal", "io_progress", LoadingScreen.LOADING_STATUS.SKIN_LOAD_START)
	var ver : int = file.get_8()
	
	Console._log.call_deferred(".skn format version : " + str(ver))
	if ver == VERSION :
		# Load data
		Console._log.call_deferred("Loading skin metadata")
		metadata = SkinMetadata.new()
		call_deferred("emit_signal", "io_progress", LoadingScreen.LOADING_STATUS.METADATA_LOAD)
		metadata._load(file)

		Console._log.call_deferred("Loading skin sounds")
		call_deferred("emit_signal", "io_progress", LoadingScreen.LOADING_STATUS.AUDIO_LOAD)
		sounds = file.get_var(true)

		Console._log.call_deferred("Loading skin textures")
		call_deferred("emit_signal", "io_progress", LoadingScreen.LOADING_STATUS.TEXTURES_LOAD)
		textures = file.get_var(true)

		Console._log.call_deferred("Loading skin music/video/godot scene")
		call_deferred("emit_signal", "io_progress", LoadingScreen.LOADING_STATUS.STREAM_LOAD)
		stream = file.get_var(true)

		Data.use_second_cache = !Data.use_second_cache
		_cache_video()
		_cache_godot_scene()
	
	else:
		Console._log.call_deferred("ERROR! This .skn format version is deprecated and cannot be loaded!")
		file.close()
		skin_loaded.emit()
		return ERR_INVALID_DATA

	Console._log.call_deferred("Skin load finished!")
	call_deferred("emit_signal", "io_progress", LoadingScreen.LOADING_STATUS.FINISH)
	file.close()

	version = ver
	metadata.path = path

	call_deferred("emit_signal", "skin_loaded")
	return OK


## Loads video and caches it in [constant Data.CACHE_PATH], so skin can access it. [br]
## Sets [b]'video_is_cached'[/b] true on success.
func _cache_video() -> void:
	Console._log.call_deferred("Caching skin video")
	video_is_cached = false
	
	if stream["video"] == null: 
		Console._log.call_deferred("No video avaiable to cache")
		return 
	if stream["video"].is_empty(): 
		Console._log.call_deferred("No video avaiable to cache")
		return 
	if Player.config.video["disable_video"] : 
		Console._log.call_deferred("Video playback is disabled in current profile")
		return
	
	var extension : String = stream["video_format"]
	if not extension in ["webm","mp4","ogv"]: 
		Console._log.call_deferred("ERROR! Invalid video file format")
		return
	
	var cached_video_name : String = "video." + extension 
	if Data.use_second_cache: cached_video_name = "video2." + extension 
	
	var file : FileAccess = FileAccess.open(Data.CACHE_PATH + cached_video_name,FileAccess.WRITE)
	if not file : 
		Console._log.call_deferred("ERROR! Video cache failed. File open error : " + error_string(FileAccess.get_open_error()))
		return

	file.store_buffer(stream["video"])
	file.close()

	video_is_cached = true
	Console._log.call_deferred("Video is successfully cached to path : " + Data.CACHE_PATH + cached_video_name)


## Loads packed godot scene and caches it in [constant Data.CACHE_PATH], so skin can access it. [br]
## Sets [b]'scenery_is_cached'[/b] true on success.
func _cache_godot_scene() -> void:
	Console._log.call_deferred("Caching skin custom godot scene")
	scenery_is_cached = false

	if stream["scene"] == null: 
		Console._log.call_deferred("No custom scene avaiable to cache")
		return 
	if not stream.has("scene_path"): 
		Console._log.call_deferred("No custom scene avaiable to cache")
		return 
	if Player.config.video["disable_scenery"] : 
		Console._log.call_deferred("Scenery playback is disabled in current profile")
		return
	
	var extension : String = stream["scene_format"]
	if not extension in ["pck","zip"] : 
		Console._log.call_deferred("ERROR! Invalid custom scene package file format")
		return
	
	var cached_scene_name : String = "scene." + stream["scene_format"]
	if Data.use_second_cache: cached_scene_name = "scene2." + stream["scene_format"]
	
	var file : FileAccess = FileAccess.open(Data.CACHE_PATH + cached_scene_name, FileAccess.WRITE)
	if not file : 
		Console._log.call_deferred("ERROR! Custom scene cache failed. File open error : " + error_string(FileAccess.get_open_error()))
		return
	file.store_buffer(stream["scene"])
	file.close()
	
	var success : bool = ProjectSettings.load_resource_pack(Data.CACHE_PATH + cached_scene_name, true)
	if not success: 
		Console._log.call_deferred("ERROR! Failed to load custom scene package into internal directory")
		return
	
	if not _check_godot_scene():
		Console._log.call_deferred("ERROR! Custom scene security check failed.")
		return

	scenery_is_cached = true
	Console._log.call_deferred("Custom scene is successfully cached to path : " + Data.CACHE_PATH + cached_scene_name)


## Checks loaded custom godot scene for malicious code
func _check_godot_scene() -> bool:
	Console._log.call_deferred("Checking custom scene scripts")

	if not ResourceLoader.exists("res://" + stream["scene_path"]): 
		Console._log.call_deferred("ERROR! Custom scene path is invalid : " + stream["scene_path"])
		return false

	var scene_state : SceneState = load("res://" + stream["scene_path"]).get_state()
	var is_check_completed : bool = true

	for node_id : int in scene_state.get_node_count():
		for prop_id : int in scene_state.get_node_property_count(node_id):

			var node_type : StringName = scene_state.get_node_type(node_id)
			if node_type in BANNED_NODES:
				Console._log.call_deferred("WARNING! Found banned node class : " + node_type)
				is_check_completed = false

			if scene_state.get_node_property_name(node_id, prop_id) == "script":
				Console._log.call_deferred("Found script in node : " + scene_state.get_node_name(node_id) + ", id = " + str(node_id))

				var script : Script = scene_state.get_node_property_value(node_id, prop_id)
				if not script.has_source_code():
					Console._log.call_deferred("WARNING! Found script cannot be parsed for security check. Please disable binary tokenization on scene export")
					is_check_completed = false
				
				var source_code : String = script.source_code
				for bad_word : String in BANNED_WORDS:
					if source_code.contains(bad_word):
						Console._log.call_deferred("WARNING! Found banned word inside script : " +  bad_word)
						is_check_completed = false

	Console._log.call_deferred("Check finished")
	return is_check_completed
