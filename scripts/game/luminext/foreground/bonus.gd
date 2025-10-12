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
## Shows bonus arrow animation when player gets 4X bonus
##-----------------------------------------------------------------------

var classic_animation : bool = false ## If true classic animation from Lumines Puzzle Fusion will be played

var arrow_1_tex : Texture = null ## Texture for 1x combo arrow
var arrow_2_tex : Texture = null ## Texture for 2x combo arrow
var arrow_3_tex : Texture = null ## Texture for 3x combo arrow
var arrow_4_tex : Texture = null ## Texture for 4x combo arrow


func _ready() -> void:
	Player.config.changed.connect(_sync_settings)
	_sync_settings()


## Called on game reset
func _reset() -> void:
	$BigArrow/ANIM.seek(0,true)
	$BigArrow/ANIM.stop()
	$Classic/ANIM.seek(0,true)
	$Classic/ANIM.stop()


## Changes bonus arrow texture to match passed [SkinData]
func _change_style(skin_data : SkinData = null) -> void:
	$BigArrow/number/two.texture = skin_data.textures["2_tex"]
	$BigArrow/number/three.texture = skin_data.textures["3_tex"]
	$BigArrow/number/four.texture = skin_data.textures["4_tex"]
	
	arrow_1_tex = skin_data.textures["arrow_1"]
	arrow_2_tex = skin_data.textures["arrow_2"]
	arrow_3_tex = skin_data.textures["arrow_3"]
	arrow_4_tex = skin_data.textures["arrow_4"]
	
	$Bonus/line5.color = skin_data.textures["timeline_color"]


## Sync with player settings
func _sync_settings() -> void:
	if Player.config.game["luminext_classic_bonus"]: 
		classic_animation = true
		$Classic.visible = true
		$BigArrow.visible = false
	else:
		classic_animation = false
		$Classic.visible = false
		$BigArrow.visible = true


## Shows bonus animation
func _bonus(combo : int, deleted_squares_count : int, result_score : int) -> void:
	$Bonus/squares.text = str(deleted_squares_count) + "x"
	$Bonus/score.text = "+" + str(result_score)

	if classic_animation: 
		$Classic/ANIM.stop()
		$Classic/ANIM.play("start")
		return
	
	if combo == 1 : 
		$BigArrow/number/two.visible = false
		$BigArrow/number/three.visible = false
		$BigArrow/number/four.visible = false
		$BigArrow/arrow.texture = arrow_1_tex
		$BigArrow/arrow2.texture = arrow_1_tex
	elif combo == 2 : 
		$BigArrow/number/two.visible = true
		$BigArrow/number/three.visible = false
		$BigArrow/number/four.visible = false
		$BigArrow/arrow.texture = arrow_2_tex
		$BigArrow/arrow2.texture = arrow_2_tex
	elif combo == 3 : 
		$BigArrow/number/two.visible = false
		$BigArrow/number/three.visible = true
		$BigArrow/number/four.visible = false
		$BigArrow/arrow.texture = arrow_3_tex
		$BigArrow/arrow2.texture = arrow_3_tex
	elif combo > 3: 
		$BigArrow/number/two.visible = false
		$BigArrow/number/three.visible = false
		$BigArrow/number/four.visible = true
		$BigArrow/arrow.texture = arrow_4_tex
		$BigArrow/arrow2.texture = arrow_4_tex
	
	$BigArrow/ANIM.stop()
	$BigArrow/ANIM.play("start")
