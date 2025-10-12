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
## Displays enabled score/time/level/deleted counters
##-----------------------------------------------------------------------

func _ready() -> void:
	for i : Control in $V.get_children():
		i.visible = false
	
	$V/sep1.visible = false
	$V/sep2.visible = false
	$V/sep3.visible = false
	$V/sep4.visible = false


## Changes this [UIElement] design to match passed [SkinData]
func _change_style(skin_data : SkinData = null) -> void:
	$V.modulate = skin_data.textures["ui_color"]

	var separators : Array = []
	var label_settings : LabelSettings = LabelSettings.new()
	var folder_name : String = ""
	var font_settings : Array = []
	var small_letter_settings : Array = []
	
	match skin_data.textures["ui_design"]:
		SkinData.UI_DESIGN.STANDARD:
			separators = [48,0,0,48]
			folder_name = "standard"
			font_settings = [load("res://fonts/lumifont.ttf"), 32, Vector2(250,42)]
			small_letter_settings = [16,Color(0,0,0,0),0,Vector2(0,0)]
		SkinData.UI_DESIGN.SHININ:
			separators = [16,16,16,16]
			folder_name = "shinin"
			font_settings = [load("res://fonts/lumifont.ttf"), 32, Vector2(250,46)]
			small_letter_settings = [16,Color(0,0,0,1),2,Vector2(1,1)]
		SkinData.UI_DESIGN.SQUARE:
			separators = [0,0,0,0]
			folder_name = "square"
			font_settings = [load("res://fonts/lumifont.ttf"), 32, Vector2(250,46)]
			small_letter_settings = [16,Color(0,0,0,0),0,Vector2(0,0)]
		SkinData.UI_DESIGN.MODERN:
			separators = [0,0,0,0]
			folder_name = "modern"
			font_settings = [load("res://fonts/foreground/xolonium_regular.otf"), 42, Vector2(250,46)]
			small_letter_settings = [20,Color(0,0,0,1),4,Vector2(2,2)]
		SkinData.UI_DESIGN.LIVE:
			separators = [24,24,24,24]
			folder_name = "live"
			font_settings = [load("res://fonts/foreground/roboto_medium.ttf"), 36, Vector2(220,50)]
			small_letter_settings = [18,Color(0.5,0.5,0.5,1),2,Vector2(1,1)]
		SkinData.UI_DESIGN.PIXEL:
			separators = [16,16,16,16]
			folder_name = "pixel"
			font_settings = [load("res://fonts/foreground/public_pixel.ttf"), 32, Vector2(230,50)]
			small_letter_settings = [16,Color(0.0,0.0,0.0,1),3,Vector2(2,2)]
		SkinData.UI_DESIGN.BLACK:
			separators = [0,0,0,0]
			folder_name = "black"
			font_settings = [load("res://fonts/foreground/source_sans_pro_black.ttf"), 48, Vector2(250,50)]
			small_letter_settings = [24,Color(0,0,0,1),0,Vector2(0,0)]
		SkinData.UI_DESIGN.COMIC:
			separators = [0,0,0,0]
			folder_name = "comic"
			font_settings = [load("res://fonts/foreground/badcomic_regular.ttf"), 42, Vector2(250,68)]
			small_letter_settings = [20,Color(0,0,0,1),4,Vector2(2,2)]
		SkinData.UI_DESIGN.CLEAN:
			separators = [32,0,0,32]
			folder_name = "clean"
			font_settings = [load("res://fonts/lumifont.ttf"), 36, Vector2(276,48)]
			small_letter_settings = [18,Color(0,0,0,1),4,Vector2(2,2)]
		SkinData.UI_DESIGN.VECTOR:
			separators = [24,24,24,24]
			folder_name = "vector"
			font_settings = [load("res://fonts/foreground/robtronika_regular.ttf"), 32, Vector2(250,46)]
			small_letter_settings = [16,Color(0.5,0.5,0.5,1),4,Vector2(2,2)]
		SkinData.UI_DESIGN.TECHNO:
			separators = [48,0,0,48]
			folder_name = "techno"
			font_settings = [load("res://fonts/foreground/trigram_regular.ttf"), 42, Vector2(250,46)]
			small_letter_settings = [20,Color(0.0,0.0,0.0,0),0,Vector2(0,0)]
		_: return
	
	label_settings.font = font_settings[0]
	label_settings.font_size = font_settings[1]
	label_settings.shadow_color = small_letter_settings[1]
	label_settings.shadow_size = small_letter_settings[2]
	label_settings.shadow_offset = small_letter_settings[3]
	
	$V/H2/lap.label_settings.font.base_font = font_settings[0]
	$V/H2/lap.label_settings.font_size = small_letter_settings[0]
	$V/H2/lap.label_settings.shadow_color = small_letter_settings[1]
	$V/H2/lap.label_settings.shadow_size = small_letter_settings[2]
	$V/H2/lap.label_settings.shadow_offset = small_letter_settings[3]
	
	$V/H/icon.label_settings.shadow_color = small_letter_settings[1]
	$V/H/icon.label_settings.shadow_size = small_letter_settings[2]
	$V/H/icon.label_settings.shadow_offset = small_letter_settings[3]
	
	var base_path : String = ""
	match Player.config.misc["language"]:
		"it" : base_path = "res://images/game/foreground/scoreboard/designs_it/"
		"pt" : base_path = "res://images/game/foreground/scoreboard/designs_pt/"
		_: base_path = "res://images/game/foreground/scoreboard/designs/"
	
	$V/Label1.texture = load(base_path + folder_name + "/level.png")
	$V/Label2.texture = load(base_path + folder_name + "/hi-score.png")
	$V/Label3.texture = load(base_path + folder_name + "/score.png")
	$V/Label4.texture = load(base_path + folder_name + "/deleted.png")
	$V/Label5.texture = load(base_path + folder_name + "/time.png")
	
	for separate : int in 4:
		get_node("V/sep" + str(separate+1)).custom_minimum_size.y = separators[separate]
	
	for label : TextureRect in [$V/Label1, $V/Label2, $V/Label3, $V/Label4, $V/Label5]:
		label.custom_minimum_size = font_settings[2]
	
	for label : Label in [$V/hiscore, $V/score, $V/time, $V/H2/stage, $V/H2/level, $V/H/deletedsqr]:
		label.label_settings = label_settings


## Displays chosen counter
func _enable_counter(counter_name : String) -> void:
	match counter_name:
		"level" : 
			$V/Label1.visible = true
			$V/H2.visible = true
		"time" : 
			$V/sep4.visible = true
			$V/Label5.visible = true
			$V/time.visible = true
		"score" : 
			$V/sep1.visible = true
			$V/Label3.visible = true
			$V/score.visible = true
		"hiscore" : 
			$V/sep2.visible = true
			$V/Label2.visible = true
			$V/hiscore.visible = true
		"deleted" : 
			$V/sep3.visible = true
			$V/Label4.visible = true
			$V/H.visible = true


## Sets one of the counters value
func _set_value(value : Variant, counter_name : String) -> void:
	match counter_name:
		"level" : 
			var level : int = value[1]
			var stage : int = value[0]
			var lap : int = value[2]
			
			if lap == -1 : 
				$V/H2/stage.text = ""
				$V/H2/lap.text = ""
				$V/H2/level.text = str(level)
			elif lap < 2 : 
				$V/H2/stage.text = str(stage)
				$V/H2/lap.text = ""
				$V/H2/level.text = " - " + str(level)
			else:
				$V/H2/stage.text = str(stage)
				$V/H2/lap.text = str(lap)
				$V/H2/level.text = " - " + str(level)

		"time" : $V/time.text = str(value)
		"score" : $V/score.text = str(value)
		"hiscore" : $V/hiscore.text = str(value)
		"deleted_squares" : $V/H/deletedsqr.text = str(value)
