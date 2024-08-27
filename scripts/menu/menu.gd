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


extends Control

#-----------------------------------------------------------------------
# Menu API
#
# Main menu node script which controls all menus.
# It's basically a container for nodes called "screens".
# Each "screen" node must inherit from **MenuScreen** class and feature an AnimationPlayer node called 'A'.
# 'A' must contain "start" and "end" titled animations in order to work, but can have more animations if needed
# Then you can do and code anything you want inside menu screen.
#
# This API kinda ignores most of the standard Godot Control API cause I didn't really liked how it approached
# connecting signals and buttons selection. You can try building menu other way but there's no guarantee that
# something woudn't break, so I recommend using methods and signals present here and related classes only.
#-----------------------------------------------------------------------

signal screen_remove_started # Called when screen remove started
signal screen_removed(name : String) # Called when screen is removed, and returns removed screen name
signal all_screens_removed # Called when all screens in queue were removed

signal screen_add_started # Called when new screen creation started
signal screen_added(name : String) # Called when screen is added, and returns added screen name
signal all_screens_added # Called when all screens in queue were added

const BUTTONS_ICONS_TEX : Texture = preload("res://images/menu/key_graphics.png") # Build-in buttons icons atlas texture
const BUTTON_KEY_SCENE : PackedScene = preload("res://scenery/menu/button_key.tscn") # Used when key is not in BUTTONS_ICONS_TEX

var is_locked : bool = false # If menu is locked, nothing could be done

var loaded_screens_data : Dictionary = {} # All avaiable menu screens (stored as paths to .tscn files)
var loaded_music_data : Dictionary = {} # All avaiable menu music (stored as paths to .mp3 or .ogg)
var loaded_sounds_data : Dictionary = {} # All avaiable system sounds (stored as loaded .mp3 or .ogg instances)

var screens : Dictionary = {} # All currently alive menu screens dictionary
var current_screen : Control = null
var current_screen_name : String = "" # Current menu screen name (in snake_case)

var keep_locked : bool = false # If true menu won't unlock when screen is added, so screen can unlock menu manually later
var currently_adding_screens_amount : int = 0 # Number of currently adding screens
var currently_removing_screens_amount : int = 0 # Number of currently removing screens

var music_player : AudioStreamPlayer = null # Music player node
var is_music_playing : bool = false

@onready var preview_player : AudioStreamPlayer = $Preview # Skin preview player node
var preview_tween : Tween = null # Tween used for controlling preview player volume

var custom_data : Dictionary = {} # Some custom data custom menu could use freely


func _ready() -> void:
	preview_player.finished.connect(preview_player.play)


# Starts intro sequence and loads first screens
# You can input 'force_screen' and menu will skip intro and immidiately load setted screen
func _boot(force_screen : String = "") -> void:
	_add_screen("background")
	_add_screen("foreground","null")
	
	if not force_screen.is_empty():
		_add_screen(force_screen)
		return

	var startup_screen : MenuScreen = _add_screen("startup")
	await startup_screen.finish
	
	_remove_screen("startup")
	await get_tree().create_timer(1.0).timeout
	_add_screen("splash_screen")


func ___SCREENS_WORKFLOW___() -> void: pass


# Adds a screen to the menu scenery. **New screen will overlay previous one, and all variables set by it.**
# "screen_name" - Name of the screen to add
# "screen_anim" - New screen starting animation (enter "null" to skip animation)
func _add_screen(screen_name : String, screen_anim : String = "start") -> MenuScreen:
	if not screen_name in loaded_screens_data.keys(): 
		return null
	
	is_locked = true
	currently_adding_screens_amount += 1
	screen_add_started.emit()
	
	var new_screen : MenuScreen = load(loaded_screens_data[screen_name]).instantiate()
	screens[screen_name] = new_screen
	
	new_screen.previous_screen_name = current_screen_name
	current_screen_name = screen_name
	current_screen = new_screen
	
	new_screen.snake_case_name = screen_name
	add_child(new_screen)
	
	_process_added_screen(new_screen,screen_anim)
	return new_screen

# Helper function to start added screen appear animation and wait until it ends to unlock menu
func _process_added_screen(new_screen : MenuScreen, screen_anim : String) -> void:
	# We expect that screen will show its appear animation, so we wait until it ends
	if new_screen.animation_player != null and new_screen.animation_player.has_animation(screen_anim):
		new_screen.animation_player.play(screen_anim)
		await new_screen.animation_player.animation_finished
	
	screen_added.emit(new_screen.snake_case_name)
	currently_adding_screens_amount -= 1
	
	# Make sure that no other screen add/removal is queued
	if currently_adding_screens_amount == 0:
		if currently_removing_screens_amount == 0 and not keep_locked: 
			is_locked = false
		
		all_screens_added.emit()


# Removes screen from menu scenery.
# "screen_name" - Name of the screen to remove
# "screen_anim" - Removing screen ending animation (enter "null" to skip animation)
func _remove_screen(screen_name : String, screen_anim : String = "end") -> void:
	if not screens.has(screen_name): return
	is_locked = true
	screen_remove_started.emit()
	
	var old_screen : MenuScreen = screens[screen_name]
	old_screen.remove_started.emit()
	screens.erase(screen_name)
	currently_removing_screens_amount += 1
	
	if old_screen.animation_player != null and old_screen.animation_player.has_animation(screen_anim):
		old_screen.animation_player.play(screen_anim)
		await old_screen.animation_player.animation_finished
	
	old_screen.queue_free()
	screen_removed.emit(screen_name)
	currently_removing_screens_amount -= 1
	
	# Make sure that no other screen add/removal is queued
	if currently_removing_screens_amount == 0:
		if currently_adding_screens_amount == 0: 
			if not keep_locked:
				is_locked = false

		all_screens_removed.emit()


# Replaces current menu scenery with some new one, removing older one
# "new_screen_name" - Name of the screen to add
# "new_screen_anim" - New screen starting animation (you can enter "null" to skip animation)
# "old_screen_anim" - Current screen ending animation (you can enter "null" to skip animation)
func _change_screen(new_screen_name : String, new_screen_anim : String = "start", old_screen_anim : String = "end") -> Control:
	if currently_adding_screens_amount > 0 : await all_screens_added
	if currently_removing_screens_amount > 0 : await all_screens_removed
	await get_tree().create_timer(0.01).timeout
	
	_remove_screen(current_screen_name, old_screen_anim)
	await all_screens_removed
	var new_screen : MenuScreen = _add_screen(new_screen_name, new_screen_anim)
	
	return new_screen


# Used when game is over, and returns into main menu with screen specified in "screen_name"
func _return_from_game(screen_name : String = "main_menu") -> void:
	# Start "fade-out" animation
	create_tween().tween_property(Data.main.black,"color",Color(0,0,0,0),0.5)
	
	# If we started game in skin playtest mode, return into skin editor.
	if screens.has("skin_editor"):
		current_screen = screens["skin_editor"]
		current_screen_name = "skin_editor"
		screens["skin_editor"]._end_playtest_skn()
		return

	_add_screen("background")
	_add_screen("foreground")
	_add_screen(screen_name)


func ___SFX_N_MUSIC_PLAYBACK___() -> void: pass


# Plays one of the avaiable in "menu/sounds" sounds, or appended AudioStream
# Announcer samples should have prefix "announce_" to work correctly
func _sound(sound_name : String, stream : AudioStream = null, start_immidiately : bool = true) -> AudioStreamPlayer:
	if sound_name == "":
		return
	if not loaded_sounds_data.has(sound_name) and stream == null: 
		print("No menu sound found with name : ", sound_name)
		return
	
	var player : AudioStreamPlayer = AudioStreamPlayer.new()
	
	if sound_name.begins_with("announce_"):
		if Data.profile.config["audio"]["announcer"] == Profile.ANNOUNCER_MODE.OFF or Data.profile.config["audio"]["announcer"] == Profile.ANNOUNCER_MODE.GAME_ONLY: return
		player.bus = 'Announce'
	else:
		player.bus = 'Sound'
	
	if stream != null: player.stream = stream
	else: player.stream = loaded_sounds_data[sound_name]
	
	player.finished.connect(player.queue_free)
	
	add_child(player)
	if start_immidiately : player.play()
	return player


# Starts looping menu music sample
# Music files inside "menu/music" should be "ogg" or "mp3" **with "looping" set to false**, and have same file names as corresponding menu screens
func _change_music(music_sample_name : String = "", change_speed : float = 1.0) -> void:
	if music_sample_name != "" and not loaded_music_data.has(music_sample_name):
		music_player = null
		return
	
	if music_player != null: 
		var tween : Tween = create_tween()
		tween.tween_property(music_player,"volume_db",-40.0,change_speed).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
		tween.tween_callback(music_player.queue_free)
		is_music_playing = false
	
	if music_sample_name == "":
		return
	
	if current_screen_name == "":
		music_player = null
		return
	
	var music_sample : AudioStream = loaded_music_data[music_sample_name]
	
	var player : AudioStreamPlayer = AudioStreamPlayer.new()
	player.volume_db = -40.0
	player.stream = music_sample
	player.bus = "Music"
	music_player = player
	create_tween().tween_property(music_player,"volume_db",0.0,change_speed).from(-40.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	is_music_playing = true
	
	player.finished.connect(player.play)
	add_child(player)
	player.play()


# Stops skin preview
func _stop_skin_preview() -> void:
	if preview_tween : preview_tween.kill()
	preview_tween = create_tween()
	
	if is_music_playing: preview_tween.parallel().tween_property(music_player,"volume_db",0.0,1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	
	preview_tween.parallel().tween_property(preview_player,"volume_db",-40.0,1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	preview_tween.tween_callback(preview_player.stop)


# Starts skin preview with given audio sample
func _start_skin_preview(sample : AudioStream) -> void:
	if not Data.profile.config["audio"]["skin_preview"] : return
	
	preview_player.stream = sample
	preview_player.play()
	
	if preview_tween : preview_tween.kill()
	preview_tween = create_tween()
	
	if is_music_playing : preview_tween.parallel().tween_property(music_player,"volume_db",-40.0,1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	preview_tween.parallel().tween_property(preview_player,"volume_db",0.0,1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)


func ___MISCELLANEOUS___() -> void: pass


# Closes all menu screens
func _exit() -> void:
	current_screen_name = ""
	is_locked = true
	
	# Fade-out menu music
	if music_player != null: 
		var tween : Tween = create_tween()
		tween.tween_property(music_player,"volume_db",-40.0,1.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
		tween.tween_callback(music_player.queue_free)
		is_music_playing = false
	
	for screen_name : String in screens.keys():
		# Skin editor is exception here, since it can run game in skin playtest mode. So we should have opportunity to come back.
		if screen_name == "skin_editor" : continue
		
		_remove_screen(screen_name)
	
	await all_screens_removed
	is_locked = false


# Creates a button icon node, which is useful for buttons layout display
func _create_button_icon(action : String, button_size : Vector2 = Vector2(42,42)) -> TextureRect:
	var action_index : int
	
	match action:
		# D-pad or keyboard movement actions id's
		"all_arrows" : 
			action_index = 1001 if Data.current_input_mode == Data.INPUT_MODE.GAMEPAD else 3001
		"up_down" : 
			action_index = 1002 if Data.current_input_mode == Data.INPUT_MODE.GAMEPAD else 3002
		"left_right" : 
			action_index = 1003 if Data.current_input_mode == Data.INPUT_MODE.GAMEPAD else 3003
		"all_arrows2" : 
			action_index = 3004
		"up_down2" : 
			action_index = 3005
		"left_right2" : 
			action_index = 3006
		
		# Mouse buttons actions id's
		"mouse_left": action_index = 2001
		"mouse_right": action_index = 2002
		"mouse_middle": action_index = 2003
		
		"backspace": action_index = KEY_BACKSPACE
		
		# Any else action
		_:
			if Data.current_input_mode == Data.INPUT_MODE.GAMEPAD : 
				var gamepad_action_name : String = Data.profile.config["controls"][action + "_pad"]
				action_index = int(gamepad_action_name.substr(4))
			else:
				action_index = OS.find_keycode_from_string(Data.profile.config["controls"][action])
	
	var atlas_region : Rect2 = Rect2(128,128,128,128)
	var atlas_position : Vector2 = Vector2(0,0)
	var icon : TextureRect
	
	match action_index:
		# Gamepad
		JOY_BUTTON_A : atlas_position = Vector2(0,0) # XBOX A
		JOY_BUTTON_B: atlas_position = Vector2(1,0) # XBOX B
		JOY_BUTTON_X: atlas_position = Vector2(2,0) # XBOX X
		JOY_BUTTON_Y: atlas_position = Vector2(3,0) # XBOX Y
		1001:atlas_position = Vector2(5,0) # ALL ARROWS
		1002: atlas_position = Vector2(1,1) # UPDOWN
		1003: atlas_position = Vector2(0,1) # LEFTRIGHT
		JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_DPAD_DOWN : atlas_position = Vector2(4,0) # SINGLE ARROW
		JOY_BUTTON_RIGHT_SHOULDER: atlas_position = Vector2(2,1) # R1
		JOY_BUTTON_LEFT_SHOULDER: atlas_position = Vector2(3,1) # L1
		JOY_AXIS_TRIGGER_RIGHT: atlas_position = Vector2(4,1) # R2
		JOY_AXIS_TRIGGER_LEFT: atlas_position = Vector2(5,1) # L2
		JOY_BUTTON_START: atlas_position = Vector2(0,2) # START
		JOY_BUTTON_GUIDE: atlas_position = Vector2(1,2) # SELECT
		
		# Keyboard
		KEY_ENTER: atlas_position = Vector2(2,2) # ENTER
		KEY_SHIFT: atlas_position = Vector2(3,2) # SHIFT
		KEY_ESCAPE: atlas_position = Vector2(5,2) # ESC
		KEY_SPACE: atlas_position = Vector2(4,2) # SPACE
		KEY_BACKSPACE: atlas_position = Vector2(0,3) # BACKSPACE
		KEY_UP,KEY_DOWN,KEY_RIGHT,KEY_LEFT : atlas_position = Vector2(5,3)
		3001: atlas_position = Vector2(2,3) # WASD
		3002: atlas_position = Vector2(4,3) # WS
		3003: atlas_position = Vector2(3,3) # AD
		3004: atlas_position = Vector2(3,4) # ALL ARROWS
		3005: atlas_position = Vector2(5,4) # LEFT-RIGHT ARROWS
		3006: atlas_position = Vector2(4,4) # UP-DOWN ARROWS
		
		# Mouse
		2001: atlas_position = Vector2(0,4) # LEFT CLICK
		2002: atlas_position = Vector2(1,4) # RIGHT CLICK
		2003: atlas_position = Vector2(2,4) # MIDDLE CLICK

		# If no button in atlas found, this button is threated as keyboard button and special object is created and used
		_: 
			atlas_region = Rect2(128,384,128,128)
			icon = load("res://scenery/menu/button_key.tscn").instantiate()
			icon.get_node("Label").text = OS.get_keycode_string(action_index)
			return icon
	
	atlas_region.position = atlas_position * 128

	icon = TextureRect.new()
	var tex : AtlasTexture = AtlasTexture.new()
	tex.atlas = BUTTONS_ICONS_TEX
	tex.region = atlas_region
	icon.texture = tex
	# Center TextureRect
	icon.pivot_offset = Vector2(button_size.x / 2,button_size.y / 2)
	icon.custom_minimum_size = button_size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# If its single arrow button, rotate it depending on direction
	match action_index:
		JOY_BUTTON_DPAD_DOWN, KEY_DOWN, 1003 : icon.rotation_degrees = 90
		JOY_BUTTON_DPAD_LEFT, KEY_LEFT : icon.rotation_degrees = 180
		JOY_BUTTON_DPAD_UP, KEY_UP : icon.rotation_degrees = 270
	
	return icon


# Resets menu to its initial state
func _reset() -> void:
	# Free all menu screens
	for menu_screen : Node in get_children():
		# There's also a preview player node don't remove it
		if menu_screen == preview_player: continue
		menu_screen.queue_free()
	
	# Reset all vars
	is_locked = false
	current_screen_name = ""
	loaded_screens_data.clear()
	loaded_music_data.clear()
	loaded_sounds_data.clear()
	music_player = null
