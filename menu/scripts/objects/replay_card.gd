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


extends MenuSelectableButton

var replay_path : String = "" 
var is_invalid : bool = false


func _ready() -> void:
	super()
	
	selected.connect(_selected)
	deselected.connect(_deselected)


# Loads replay metadata
func _load() -> void:
	var file : FileAccess = FileAccess.open_compressed(replay_path,FileAccess.READ,FileAccess.COMPRESSION_DEFLATE)
	if not file: 
		print("FILE ERROR! : ", error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()
	
	$V/Name.text = file.get_pascal_string()
	$V/Author.text = file.get_pascal_string()
	$V/Date.text = file.get_pascal_string()

	$Screenshot.texture = file.get_var(true)
	var gamemode_settings : Dictionary = file.get_var(true)

	if not gamemode_settings.has("name"):
		$V/Name.text = "INVALID REPLAY"
		$V/Gamemode.text = replay_path
		$V/Name.modulate = Color.RED
		$V/Author.text = ""
		$V/Date.text = ""
		replay_path = ""
		is_invalid = true

	match gamemode_settings["name"]:
		"time_attack_mode":
			var ruleset_string : String = "???"
			match gamemode_settings["ruleset"]:
				TimeAttackMode.TIME_ATTACK_RULESET.STANDARD: ruleset_string = "STANDARD"
				TimeAttackMode.TIME_ATTACK_RULESET.CLASSIC: ruleset_string = "CLASSIC"
				TimeAttackMode.TIME_ATTACK_RULESET.ARCADE: ruleset_string = "ARCADE"
				TimeAttackMode.TIME_ATTACK_RULESET.COLOR_3: ruleset_string = "3 COLOR"
				TimeAttackMode.TIME_ATTACK_RULESET.HARDCORE: ruleset_string = "HARDCORE"
			
			$V/Gamemode.text = "TIME ATTACK MODE | " + str(gamemode_settings["time_limit"]) + " SEC | " + ruleset_string + " | SCORE : " + str(gamemode_settings["score"])
			$Icon.texture.region = Rect2(0,256,256,256)
		_:
			$V/Name.text = "INVALID REPLAY"
			$V/Gamemode.text = replay_path
			$V/Name.modulate = Color.RED
			$V/Author.text = ""
			$V/Date.text = ""
			replay_path = ""
			is_invalid = true


func _selected() -> void:
	modulate = Color(0.5,1,1,1)
	Data.menu._sound("select")
	
	var foreground_screen : MenuScreen = Data.menu.screens["foreground"]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(0)


func _deselected() -> void:
	modulate = Color.WHITE
