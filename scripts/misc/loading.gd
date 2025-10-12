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

extends Control

##-----------------------------------------------------------------------
## Loading screen which overlays everything and is meant to be shown when game loads something heavy
## To be avaiable a MenuScreen scene must be placed into *"res://menu/loading.tscn"* 
## and it must have animation named *"loading"* and method *'_set_text(text : String)'*
##-----------------------------------------------------------------------

class_name LoadingScreen

const LOADING_SCREEN_PATH : String = "res://menu/loading.tscn" ## Path to the loading screen
const LOADING_APPEAR_SPEED : float = 1.0 ## How fast loading screen should appear in seconds

var screen : Control = null ## Loaded loading screen instance
   
## All avaiable to display on loading screen info
enum LOADING_STATUS {
	SKIN_SAVE_START,
	SKIN_LOAD_START,
	AUDIO_PREPARE,
	VIDEO_PREPARE,
	SCENE_PREPARE,
	METADATA_SAVE,
	AUDIO_SAVE,
	TEXTURES_SAVE,
	STREAM_SAVE,
	METADATA_LOAD,
	AUDIO_LOAD,
	TEXTURES_LOAD,
	STREAM_LOAD,
	CALCULATING_BPM,
	SAVING_REPLAY,
	FINISH
}


## Loads loading screen [MenuScreen] from *"res://menu/loading.tscn"*
func _load() -> void :
	if not FileAccess.file_exists(LOADING_SCREEN_PATH) : return
	
	screen = load(LOADING_SCREEN_PATH).instantiate()

	if not screen.has_method("_play") : 
		Console._log("ERROR! Provided loading screen doesn't have method '_play'")
		screen.free()
		return
	if not screen.has_method("_stop") : 
		Console._log("ERROR! Provided loading screen doesn't have method '_stop'")
		screen.free()
		return
	if not screen.has_method("_set_text") : 
		Console._log("ERROR! Provided loading screen doesn't have method '_set_text'")
		screen.free()
		return

	add_child(screen)
	screen.modulate.a = 0.0


## Toggles loading animation which overlaps everything. Menu must be loaded first and contain menu screen called [b]"loading"[/b] in order to work.
func _toggle_loading(on : bool) -> void:
	if screen == null: return

	var tween : Tween = create_tween()
	if on:
		tween.tween_property(screen, "modulate:a", 1.0, LOADING_APPEAR_SPEED)
		screen._play()
	elif not on:
		tween.tween_property(screen, "modulate:a", 0.0, LOADING_APPEAR_SPEED)
		await tween.finished
		screen._stop()


## Sets current loading message to one from [LOADING_STATUS]
func _set_message(message : int) -> void:
	var message_text : String = ""

	match message:
		LOADING_STATUS.SKIN_LOAD_START: message_text = "LOADING SKIN..."
		LOADING_STATUS.SKIN_SAVE_START: message_text = "SAVING SKIN..."
		LOADING_STATUS.METADATA_LOAD: message_text = "LOADING METADATA..."
		LOADING_STATUS.METADATA_SAVE: message_text = "SAVING METADATA..."
		LOADING_STATUS.AUDIO_PREPARE: message_text = "PREPARING MUSIC..."
		LOADING_STATUS.AUDIO_LOAD: message_text = "LOADING SOUNDS..."
		LOADING_STATUS.AUDIO_SAVE: message_text = "SAVING SOUNDS..."
		LOADING_STATUS.TEXTURES_LOAD: message_text = "LOADING TEXTURES..."
		LOADING_STATUS.TEXTURES_SAVE: message_text = "SAVING TEXTURES..."
		LOADING_STATUS.STREAM_LOAD: message_text = "LOADING SCENERY/VIDEO & MUSIC..."
		LOADING_STATUS.STREAM_SAVE: message_text = "SAVING SCENERY/VIDEO & MUSIC..."
		LOADING_STATUS.VIDEO_PREPARE: message_text = "PREPARING VIDEO..."
		LOADING_STATUS.SCENE_PREPARE: message_text = "PREPARING SCENERY..."
		LOADING_STATUS.CALCULATING_BPM: message_text = "CALCULATING SONG BPM..."
		LOADING_STATUS.SAVING_REPLAY: message_text = "SAVING REPLAY..."
		LOADING_STATUS.FINISH: message_text = "PLEASE WAIT"

	screen._set_text(message_text)
