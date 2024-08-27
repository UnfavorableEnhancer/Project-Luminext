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


extends MenuScreen

#-----------------------------------------------------------------------
# Basic Skin Editor
#
# Allows user to replace several textures, add own sounds/music/video data and edit metadata. 
# In far away future advanced skin editor will be implemented, which will provide close to Godot Engine experience and features.
#-----------------------------------------------------------------------

signal skin_saved
signal skin_loaded
signal file_selected

enum SAVE_CONFIRM_TEXT {NORMAL, UNSAVED}

var skin_data : SkinData = null # Currently editing skin data

var file_input : String = "" # What type of file we wanna get from FileExplorer now
var selected_path : String = "" # Currently selected path in FileExplorer

var skin_path : String = "" # Current skin path
var skin_by : String = "" # Current skin author name

var has_unsaved_changes : bool = false

var is_save_confirmed : bool = false
var is_exiting : bool = false
var is_in_playtest : bool = false

var stat_timer : Timer = null # Timer used to count total time spent in skin editor
var accepted : bool = true # Used for accept dialogs


#================================================================================================
#================================================================================================

func ___SKN_IO___() -> void: pass


func _ready() -> void:
	menu.screens["foreground"].visible = false

	if Data.menu.is_music_playing:
		Data.menu.custom_data["last_music_pos"] = Data.menu.music_player.get_playback_position()
		Data.menu._change_music("")
	
	%FileExplorer.close_requested.connect(func() -> void: selected_path = "cancel")
	%FileExplorer.canceled.connect(func() -> void: selected_path = "cancel")
	
	stat_timer = Timer.new()
	stat_timer.one_shot = false
	stat_timer.timeout.connect(func() -> void: Data.profile.progress["stats"]["total_skin_editor_time"] += 1)
	add_child(stat_timer)
	stat_timer.start(1.0)
	
	var new_skin : SkinData = SkinData.new()
	new_skin._load_standard_textures()
	_import_skin(new_skin)


# Start current skin saving
func _save_skin(skip_dialog : bool = false) -> void:
	if not skip_dialog:
		accepted = true
		Data.menu._sound("confirm3")
		var dialog : MenuScreen = menu._add_screen("accept_dialog")
		dialog.desc_text = "Are you sure you want to save this skin?"
		dialog.canceled.connect(func() -> void: accepted = false)
		await dialog.closed
		
		if not accepted : return
	await get_tree().create_timer(0.25).timeout
	
	var thread : Thread = Thread.new()
	
	# This timer is needed if skin saves too fast, so main thread can have time to await for skin signal
	var start_timer : Timer = Timer.new()
	start_timer.timeout.connect(thread.start.bind(skin_data._save.bind(skin_path)))
	start_timer.timeout.connect(start_timer.queue_free)
	add_child(start_timer)
	start_timer.start(0.1)
	
	Data.main._toggle_loading(true)
	Data.menu.is_locked = true
	
	await skin_data.skin_saved
	await get_tree().create_timer(0.01).timeout
	var _result : int = thread.wait_to_finish()
	
	skin_path = skin_data.metadata.path

	Data.main._toggle_loading(false)
	Data.menu.is_locked = false
	has_unsaved_changes = false
	skin_saved.emit()


# Loads .skn file, then displays whole skin contents into editor
func _import_skin(data : SkinData = null) -> void:
	if data == null:
		Data.menu._sound("confirm3")
		
		_open_file_dialog("skn")
		await file_selected
		# Add slight delay so '%FileExplorer.confirmed' could work
		await get_tree().create_timer(0.01).timeout

		if selected_path == "" : return
		skin_path = selected_path
		
		Data.profile.config["misc"]["last_skins_dir"] = selected_path 
		
		skin_data = SkinData.new()
		var result : int = skin_data._load_from_path(selected_path)
		
		if result != OK:
			Data.main._display_system_message("SKIN LOADING ERROR!\n\n" + selected_path)
			return
		
		if skin_data.version != SkinData.VERSION:
			has_unsaved_changes = true
	
	else:
		skin_data = data
	
	print("LOADING_METADATA")
	
	# Enter metadata content settings
	%Name.text = skin_data.metadata.name
	%Album.text = skin_data.metadata.album
	%Info.text = skin_data.metadata.info
	%Artist.text = skin_data.metadata.artist
	%BPM.text = str(skin_data.metadata.bpm)
	%Number.text = str(skin_data.metadata.number)
	
	# Get this skin edit history
	var edit_history : PackedStringArray = skin_data.stream["edit_history"]
	if not edit_history.is_empty():
		var text : String = ""
		var entry : int = 0
		var history_size : int = edit_history.size()
		while entry < history_size:
			var timestring : String = Time.get_datetime_string_from_unix_time(int(edit_history[entry])) 
			timestring = timestring.replace("T", " ")
			var editor : String = edit_history[entry + 1]
			text += timestring + " - " + editor + "\n"
			entry += 2
		
		%EditHistory.text = text
	
	if skin_data.metadata.label_art != null : %LabelArt.texture_normal = skin_data.metadata.label_art
	if skin_data.metadata.cover_art != null : %CoverArt.texture_normal = skin_data.metadata.cover_art
	
	%Shake.text = "ON" if skin_data.metadata.settings["no_shaking"] else "OFF"
	%Shake.button_pressed = skin_data.metadata.settings["no_shaking"]
	%Loop.text = "ON" if skin_data.metadata.settings["looping"] else "OFF"
	%Loop.button_pressed = skin_data.metadata.settings["looping"]
	%BonusRand.text = "ON" if skin_data.metadata.settings["random_bonus"] else "OFF"
	%BonusRand.button_pressed = skin_data.metadata.settings["random_bonus"]
	%Zoom.text = "ON" if skin_data.metadata.settings["zoom_background"] else "OFF"
	%Zoom.button_pressed = skin_data.metadata.settings["zoom_background"]
	
	print("LOADING_SOUNDS")
	
	for sound_name : String in ["bonus","square","timeline","blast","special"]:
		# Set corresponding sound's spinboxes max value to array lenght (-1 since last array member is null)
		var n : int = skin_data.sounds[sound_name].size() - 1
		
		match sound_name:
			"bonus" : 
				%BonusSound/N.max_value = n
				%BonusSound/N.value = 0
			"square" : 
				%SquareSound/N.max_value = n
				%SquareSound/N.value = 0
			"timeline" : 
				%TimelineSound/N.max_value = n
				%TimelineSound/N.value = 0
			"blast" : 
				%BlastSound/N.max_value = n
				%BlastSound/N.value = 0
			"special" : 
				%SpecialSound/N.max_value = n
				%SpecialSound/N.value = 0
	
	# Reset all sound button labels
	get_tree().call_group("sound_buttons","_load_sound")
	
	print("TEXTURES")
	
	for entry : String in skin_data.textures:
		var value : Variant = skin_data.textures[entry]
		
		# Skip if nothing found
		if value == null : continue

		match entry:
			"ui_design": 
				%UIDesign.select(value)
				_on_UIDesign_item_selected(%UIDesign.selected)
			# Color colorable things
			"red_fx" : 
				%redfx.modulate = value
			"white_fx" : 
				%whitefx.modulate = value
			"green_fx" : 
				%greenfx.modulate = value
			"purple_fx" : 
				%purplefx.modulate = value
			"ui_color" : 
				%UIColor.modulate = value
				%UIPreview.modulate = value
			"eq_visualizer_color" : 
				%EQColor.modulate = value
				%EQPreview.modulate = value
			"timeline_color" : 
				%TimelineColor.modulate = value
				%TimelinePreview.modulate = value
			"red_anim" :
				%RedAnim/Speed.text = str(value[2])
			"white_anim" :
				%WhiteAnim/Speed.text = str(value[2])
			"green_anim" :
				%GreenAnim/Speed.text = str(value[2])
			"purple_anim" :
				%PurpleAnim/Speed.text = str(value[2])
	
	%AnimStyle.selected = _get_animation_preset_index()
	
	if skin_data.stream.has("scene_path"):
		%ScenePath.text = skin_data.stream["scene_path"]
	
	# Setup animated blocks textures
	get_tree().call_group("texture_buttons","_load_texture")
	
	# Setup anything else
	get_tree().call_group("data_buttons","_load_data")
	
	
	print("SKN_IMPORT_SUCCESS!!")
	Data.profile.progress["stats"]["total_skin_load_times"] += 1
	skin_loaded.emit()


# Resets all entries to blank skin
func _reset() -> void:
	Data.menu._sound("confirm2")
	
	accepted = true
	var dialog : MenuScreen = menu._add_screen("accept_dialog")
	if has_unsaved_changes : dialog.desc_text = "This skin has unsaved changes. Are you sure you want to reset everything?"
	else : dialog.desc_text = "Are you sure you want to reset everything?"
	dialog.canceled.connect(func() -> void: accepted = false)
	await dialog.closed
	if not accepted : return
	
	var new_skin : SkinData = SkinData.new()
	new_skin._load_standard_textures()
	_import_skin(new_skin)

	skin_path = skin_data.metadata.path
	# We need to reset textures manually for proper SpriteFrames display
	get_tree().call_group("texture_buttons","_reset_texture")
	
	%Name.text = ""
	%Album.text = ""
	%Number.text = ""
	%Artist.text = ""
	%Info.text = ""


# Called on exiting skin editor
func _exit() -> void:
	if not Data.menu.is_locked and Data.menu.current_screen == self:
		Data.profile._save_config()
		Data.profile._save_progress()
		
		Data.menu._sound("cancel")
		
		accepted = true
		if has_unsaved_changes:
			var dialog : MenuScreen = menu._add_screen("accept_dialog")
			dialog.desc_text = "This skin has unsaved changes. Are you sure you want to exit?"
			dialog.canceled.connect(func() -> void: accepted = false)
			await dialog.closed
		if accepted:
			Data.menu._change_screen("main_menu")


# Starts skin playtest
func _start_playtest_skn() -> void:
	if is_in_playtest: return
	
	if has_unsaved_changes:
		accepted = true
		var dialog : MenuScreen = menu._add_screen("accept_dialog")
		dialog.desc_text = "This skin has unsaved changes and you must save it now in order to continue. Proceed?"
		dialog.canceled.connect(func() -> void: accepted = false)
		dialog.accepted.connect(func() -> void: has_unsaved_changes = false; _save_skin(true))
		await dialog.closed
		
		if accepted: await skin_saved
		else: return
	
	skin_data._cache_godot_scene()
	skin_data._cache_video()

	is_in_playtest = true
	$A.play("end")
	Data.menu._sound("enter")

	var playlist_mode : PlaylistMode = PlaylistMode.new()
	playlist_mode.is_single_run = false
	playlist_mode.is_single_skin_mode = true
	playlist_mode.is_playtest_mode = true
	playlist_mode.menu_screen_to_return = "skin_editor"

	skin_data.metadata.path = skin_path
	Data.main._start_game(skin_data.metadata, playlist_mode, skin_data)


# Ends skin playtest
func _end_playtest_skn() -> void:
	if is_in_playtest:
		Data.menu.current_screen = self
		Data.menu.current_screen_name = "skin_editor"
		Data.menu.move_child(self,Data.menu.get_child_count())

		menu.screens["foreground"].visible = false
		
		create_tween().tween_property(Data.main.black,"color",Color(0,0,0,0),1.0)
		$A.play("back")
		is_in_playtest = false


#================================================================================================
#================================================================================================

func ___DATA_INPUT___() -> void: pass


# Opens FileExplorer with desired format to look for defined in 'reason'
func _open_file_dialog(reason : String) -> void:
	selected_path = ""
	file_input = reason
	
	var file_dialog : FileDialog = %FileExplorer
	file_dialog.clear_filters()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	
	match reason:
		"skn" : 
			file_dialog.add_filter("*.skn", "Luminext Skin File")
		"texture" :
			file_dialog.add_filter("*.png", "PNG Image File")
			file_dialog.add_filter("*.jpeg", "JPEG Image File")
			file_dialog.add_filter("*.bmp", "BMP Image File")
			file_dialog.add_filter("*.webp", "WebP Image File")
		"audio" : 
			file_dialog.add_filter("*.ogg", "OGG Vorbis Audio File")
			file_dialog.add_filter("*.mp3", "MP3 Audio File")
			file_dialog.add_filter("*.wav", "Waveform Audio File")
		"video" : 
			file_dialog.add_filter("*.mp4", "MP4 h263/h264 Video File")
			file_dialog.add_filter("*.webm", "WebM VP8/VP9 Video File")
			file_dialog.add_filter("*.ogv", "OGV Theora Video File")
		"scene" :
			file_dialog.add_filter("*.pck", "Godot Package File")
			file_dialog.add_filter("*.zip", "ZIP Archive File")
	
	if file_input == "skn":
		%FileExplorer.current_path = Data.profile.config["misc"]["last_skins_dir"]
	else:
		%FileExplorer.current_path = Data.profile.config["misc"]["last_editor_dir"]
	
	$A.play("input")
	%FileExplorer.popup_centered()
	# Wait until popup_closes
	await %FileExplorer.visibility_changed
	
	# Godot must be burned to ashes for not being able to do such a simple dimple thing as a goddamn drive letter output
	var stupid_file_dialog_option_button : OptionButton = %FileExplorer.get_vbox().get_child(0).get_child(4).get_child(0)
	var drive_letter : String = stupid_file_dialog_option_button.get_item_text(stupid_file_dialog_option_button.selected)
	
	if selected_path == "cancel" : selected_path = ""
	else: selected_path = drive_letter + %FileExplorer.current_path
	
	$A.play("input",-1,-1.5,true)
	file_selected.emit()


# Inputs currently selected file path into some 'entry' in SkinData.stream
func _edit_skn_stream_data(entry : String) -> String:
	if is_in_playtest: return ""
	if selected_path == "" : return ""

	skin_data.stream[entry] = selected_path
	Data.profile.config["misc"]["last_editor_dir"] = selected_path 
	has_unsaved_changes = true
	
	return selected_path


# Toggles boolean 'entry' inside skin data
func _toggle_skn_data(entry : String, on : bool) -> void:
	skin_data.metadata.settings[entry] = on


# Inputs 'text' into some 'entry' inside SkinData dictionaries
func _edit_skn_text_data(entry : String, text : String) -> void:
	if is_in_playtest: return
	
	match entry:
		# Strings
		"name", "album", "artist", "info" : skin_data.metadata.set(entry, text)
		# Floats
		"BPM" : 
			text = text.replace(",",".")
			skin_data.metadata.bpm = float(text)
		# Ints
		"number" : 
			skin_data.metadata.number = int(text)
		# Block animation FPS
		"red_anim_speed" : skin_data.textures["red_anim"][2] = int(text)
		"white_anim_speed" : skin_data.textures["white_anim"][2] = int(text)
		"green_anim_speed" : skin_data.textures["green_anim"][2] = int(text)
		"purple_anim_speed" : skin_data.textures["purple_anim"][2] = int(text)
		
		"scene_path": skin_data.stream["scene_path"] = text
	
	has_unsaved_changes = true


# Takes color from "ColorPicker" node and assigns it to SkinData **'entry'** inside **'textures'** dictionary
func _edit_skn_color(entry : String) -> Color:
	var color : Color = %ColorPicker.color

	match entry:
		"ui_color" : 
			%UIColor.modulate = color
			%UIPreview.modulate = color
		"timeline_color" : 
			%TimelineColor.modulate = color
			%TimelinePreview.modulate = color
		"eq_visualizer_color" : 
			%EQColor.modulate = color
			%EQPreview.modulate = color

	skin_data.textures[entry] = color
	has_unsaved_changes = true
	
	return color


# Used to input audio data into **'entry'** inside SkinData **'dictionary'**
# If it's multi-sound entry, position must be specified in **'multisound_pos'**
func _edit_skn_audio(entry : String, dictionary_name : String, multisound_pos : int = -1) -> String:
	if selected_path == "" : return ""
	Data.profile.config["misc"]["last_editor_dir"] = selected_path 
	
	var sample : AudioStream
	if selected_path.ends_with(".ogg"): 
		sample = AudioStreamOggVorbis.load_from_file(selected_path)
	elif selected_path.ends_with(".mp3"): 
		var file : FileAccess = FileAccess.open(selected_path, FileAccess.READ)
		sample = AudioStreamMP3.new()
		sample.data = file.get_buffer(file.get_length())
		file.close()
	elif selected_path.ends_with(".wav"): 
		var audio_loader : AudioLoader = AudioLoader.new()
		sample = audio_loader.loadfile(selected_path)
	else: return ""
	
	if entry == "announce":
		skin_data.metadata.announce = sample
		return selected_path
	elif entry == "preview":
		skin_data.metadata.preview = sample
		return selected_path
	
	var dictionary : Dictionary = skin_data.get(dictionary_name)
	
	if multisound_pos > -1: 
		dictionary[entry][multisound_pos] = sample
		# Append null at the end of multi-sound array, so it can be modifyed later
		if multisound_pos == dictionary[entry].size() - 1 : dictionary[entry].append(null)	
	else: dictionary[entry] = sample
	
	has_unsaved_changes = true
	return selected_path


# Used to input texture image into some 'entry' inside SkinData 'dictionary'
func _edit_skn_texture(entry : String, dictionary_name : String) -> Resource:
	if selected_path == "" : return null
	Data.profile.config["misc"]["last_editor_dir"] = selected_path 
	
	var image : Image = Image.load_from_file(selected_path)
	image.fix_alpha_edges()
	var texture : PortableCompressedTexture2D = PortableCompressedTexture2D.new()
	texture.keep_compressed_buffer = true
	texture.create_from_image(image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
	
	# If its just single texture
	if entry in ["arrow_1","arrow_2","arrow_3","arrow_4","X_tex","2_tex","3_tex","4_tex",
	"back","erase","select","effect_1","effect_2"]:
		skin_data.get(dictionary_name)[entry] = texture
		return texture
	elif entry == "cover_art" or entry == "label_art":
		skin_data.metadata.set(entry, texture)
		return texture
	
	# Else we assume it's animated one
	var sheet : SpriteFrames = SpriteFrames.new()
	
	var image_height : int = image.get_height()
	var image_width : int = image.get_width()
	var sprites_amount : int = int(float(image_width) / image_height)
	
	# We expect linear texture sheets to be inputed so slice this image into equal pieces
	for i : int in sprites_amount:
		var atlas_texture : AtlasTexture = AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(i * image_height,0,image_height,image_height)
		sheet.add_frame("default",atlas_texture)
	
	sheet.set_animation_loop("default",false)
	sheet.set_animation_speed("default",sheet.get_frame_count("default") * 6)
	
	# Set special animation speed for colored blocks textures, with exception of special blocks
	if not entry.ends_with("chain"):
		if entry.begins_with("r"): sheet.set_animation_speed("default",skin_data.textures["red_anim"][2])
		if entry.begins_with("wh"): sheet.set_animation_speed("default",skin_data.textures["white_anim"][2])
		if entry.begins_with("gr"): sheet.set_animation_speed("default",skin_data.textures["green_anim"][2])
		if entry.begins_with("p"): sheet.set_animation_speed("default",skin_data.textures["purple_anim"][2])
	
	skin_data._update_sprite_sheet(sheet,entry)
	has_unsaved_changes = true
	return sheet


func _change_block_animation_preset(index : int) -> void:
	var preset : Array[int]
	
	match index:
		SkinData.BLOCK_ANIM_PATTERN.EACH_BEAT: preset = [0,4,2,4,0,4,2,4]
		SkinData.BLOCK_ANIM_PATTERN.EACH_2BEATS: preset = [0,8,4,8,0,8,4,8]
		SkinData.BLOCK_ANIM_PATTERN.EACH_BAR: preset = [0,16,8,16,0,16,8,16]
		SkinData.BLOCK_ANIM_PATTERN.EACH_HALF_BEAT: preset = [0,2,1,2,0,2,1,2]
		SkinData.BLOCK_ANIM_PATTERN.COLOR_ORDER: preset = [0,8,2,8,4,8,6,8]
		SkinData.BLOCK_ANIM_PATTERN.CONSTANT_LOOPING: preset = [0,0,0,0,0,0,0,0]
	
	skin_data.textures["red_anim"][0] = preset[0]
	skin_data.textures["red_anim"][1] = preset[1]
	skin_data.textures["white_anim"][0] = preset[2]
	skin_data.textures["white_anim"][1] = preset[3]
	skin_data.textures["green_anim"][0] = preset[4]
	skin_data.textures["green_anim"][1] = preset[5]
	skin_data.textures["purple_anim"][0] = preset[6]
	skin_data.textures["purple_anim"][1] = preset[7]
	
	has_unsaved_changes = true


func _get_animation_preset_index() -> int:
	var animation_offset : int = skin_data.textures["red_anim"][0]
	var animation_beat : int = skin_data.textures["red_anim"][1]
	
	if animation_beat == 2 and animation_offset == 0: return SkinData.BLOCK_ANIM_PATTERN.EACH_BEAT
	if animation_beat == 4 and animation_offset == 0: return SkinData.BLOCK_ANIM_PATTERN.EACH_2BEATS
	if animation_beat == 8 and animation_offset == 0: return SkinData.BLOCK_ANIM_PATTERN.EACH_BAR
	if animation_beat == 1 and animation_offset == 0: return SkinData.BLOCK_ANIM_PATTERN.EACH_HALF_BEAT
	if skin_data.textures["purple_anim"][0] == 6 : return SkinData.BLOCK_ANIM_PATTERN.COLOR_ORDER
	if animation_beat == 0 and animation_offset == 0: return  SkinData.BLOCK_ANIM_PATTERN.CONSTANT_LOOPING
	
	return 0 


#================================================================================================
#================================================================================================

func ___MISCELLANEOUS___() -> void: pass


func _input(event : InputEvent) -> void:
	if not is_in_playtest:
		if event.is_action("ui_cancel"):
			_exit()


func _show_description(desc : String) -> void:
	%Description.text = tr(desc)


# That's kinda too much to make an separate oneliner scripts for those guys :/
func _on_UIDesign_item_selected(index : int) -> void:
	skin_data.textures["ui_design"] = index
	
	match index:
		SkinData.UI_DESIGN.STANDARD: %UIPreview.texture = load("res://images/menu/ui_preview/standard.png")
		SkinData.UI_DESIGN.SHININ: %UIPreview.texture = load("res://images/menu/ui_preview/shinin.png")
		SkinData.UI_DESIGN.SQUARE: %UIPreview.texture = load("res://images/menu/ui_preview/classic.png")
		SkinData.UI_DESIGN.MODERN: %UIPreview.texture = load("res://images/menu/ui_preview/modern.png")
		SkinData.UI_DESIGN.LIVE: %UIPreview.texture = load("res://images/menu/ui_preview/live.png")
		SkinData.UI_DESIGN.PIXEL: %UIPreview.texture = load("res://images/menu/ui_preview/pixel.png")
		SkinData.UI_DESIGN.BLACK: %UIPreview.texture = load("res://images/menu/ui_preview/black.png")
		SkinData.UI_DESIGN.COMIC: %UIPreview.texture = load("res://images/menu/ui_preview/comic.png")
		SkinData.UI_DESIGN.CLEAN: %UIPreview.texture = load("res://images/menu/ui_preview/clean.png")
		SkinData.UI_DESIGN.VECTOR: %UIPreview.texture = load("res://images/menu/ui_preview/vector.png")
		SkinData.UI_DESIGN.TECHNO: %UIPreview.texture = load("res://images/menu/ui_preview/techno.png")


func _on_UIDesign_mouse_entered() -> void:
	_show_description("Select UI design.")

func _on_Info_text_changed() -> void:
	skin_data.metadata["info"] = get_node("%Info").text

func _on_Info_mouse_entered() -> void:
	_show_description("Skin description/about text. Write here whatever you want.")

func _on_Test_mouse_entered() -> void:
	_show_description("Start skin playtest session.")

func _on_Load_mouse_entered() -> void:
	_show_description("Load skin file to edit.")

func _on_Save_mouse_entered() -> void:
	_show_description("Save current skin. Skin will be saved to your 'skins' directory.")

func _on_Reset_mouse_entered() -> void:
	_show_description("Reset current skin to standard one.")

func _on_AnimStyle_mouse_entered() -> void:
	_show_description("Select block animation timings preset.")

func _on_edit_history_mouse_entered() -> void:
	_show_description("Shows every saved skin edit date and editor name.")
