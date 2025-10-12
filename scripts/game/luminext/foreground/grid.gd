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


extends UIElement

##-----------------------------------------------------------------------
## Contains game field grid visuals, music playback state indicator and current skin info
##-----------------------------------------------------------------------

var grid_shine_enabled : bool = false ## If true, grid shine animation appears
var main_anim_tween : Tween ## Tween which is played for each sample


func _ready() -> void:
	Player.config.changed.connect(_sync_settings)
	_sync_settings()


## Plays animation for piece swap
func _swap() -> void:
	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property($Stack/swap1, "position:y", 350.0, 0.25).from(0.0)
	tween.tween_property($Stack/swap2, "position:y", -350.0, 0.25).from(0.0)
	tween.tween_property($Stack/swap1, "modulate:a", 0.0, 0.25).from(0.8)
	tween.tween_property($Stack/swap2, "modulate:a", 0.0, 0.25).from(0.8)


## Syncs settings with player config
func _sync_settings() -> void:
	if Player.config.video["fx_quality"] >= Config.EFFECTS_QUALITY.MEDIUM: grid_shine_enabled = true
	else: grid_shine_enabled = false


## Changes this [UIElement] design to match passed [SkinData]
func _change_style(skin_data : SkinData = null) -> void:
	$name.text = skin_data.metadata.name + " / " + skin_data.metadata.artist
	$Field.modulate = skin_data.textures["ui_color"]
	$EQVisualizer.modulate = skin_data.textures["eq_visualizer_color"]
	
	var file_name : String = ""
	match skin_data.textures["ui_design"]:
		SkinData.UI_DESIGN.STANDARD: file_name = "standard"
		SkinData.UI_DESIGN.SHININ: file_name = "shinin"
		SkinData.UI_DESIGN.SQUARE: file_name = "square"
		SkinData.UI_DESIGN.MODERN: file_name = "modern"
		SkinData.UI_DESIGN.LIVE: file_name = "live"
		SkinData.UI_DESIGN.PIXEL: file_name = "pixel"
		SkinData.UI_DESIGN.BLACK: file_name = "black"
		SkinData.UI_DESIGN.COMIC: file_name = "comic"
		SkinData.UI_DESIGN.CLEAN: file_name = "clean"
		SkinData.UI_DESIGN.VECTOR: file_name = "vector"
		SkinData.UI_DESIGN.TECHNO: file_name = "techno"
		_: return
	
	$Stack.texture = load("res://images/game/foreground/stack/" + file_name + ".png")
	$Stack.modulate = skin_data.textures["ui_color"]


## Changes skin music playback indicator depending on passed state
func _update_loop_mark(skin_playback_state : int) -> void:
	match skin_playback_state:
		SkinPlayer.PLAYBACK_STATE.LOOPING:
			$Repeat.visible = true
			$Playing.visible = false
		SkinPlayer.PLAYBACK_STATE.ADVANCING:
			$Repeat.visible = false
			$Playing.visible = true
		SkinPlayer.PLAYBACK_STATE.PLAYING:
			$Repeat.visible = false
			$Playing.visible = false


## Called on game pause
func _on_pause(on : bool) -> void:
	if not main_anim_tween : return 

	if on : main_anim_tween.pause()
	else : main_anim_tween.play()


## Called on skin sample end and starts animations which lasts for whole next sample length
func _on_skin_sample_ended(skin_bpm : float) -> void:
	main_anim_tween = create_tween().set_parallel(true)

	var sample_length : float = 60.0 / skin_bpm * 8.0

	if grid_shine_enabled : main_anim_tween.tween_property($Field/GridShine,"material:shader_parameter/offset",3.0,sample_length).from(-1.5)
	main_anim_tween.tween_property($Field/Beatcount,"size:x",1084.0,sample_length).from(0.0)
