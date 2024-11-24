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

var pos : int = 1
var score : int = 1
var datetime : int = 1
var author : String = "MISSING_NO"
var author_id : String = ""

var time_attack_screen : MenuScreen = null

func _ready() -> void:
	super()
	
	selected.connect(_selected)
	deselected.connect(_deselected)
	
	$H/Num.text = str(pos)
	$H/Name.text = author
	if author_id.is_empty() : $H/ID.text = ""
	else : $H/ID.text = "#" + str(hash(author_id)).left(8)
	var datetime_str : String = Time.get_datetime_string_from_unix_time(datetime).replace("-",".")
	$Date.text = datetime_str.split("T")[1] + "  " + datetime_str.split("T")[0]
	$Result.text = str(score)
	
	create_tween().tween_property($Back/Glow,"modulate:a",0.0,0.2).from(0.5)


func _selected() -> void:
	Data.menu._sound("select")

	var foreground_screen : MenuScreen = Data.menu.screens["foreground"]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(0)
	
	$Back.color = Color("ab2966bf")
	create_tween().tween_property($Back/Glow,"modulate:a",0.0,0.2).from(0.5)


func _deselected() -> void:
	$Back.color = Color(0.24,0.24,0.24,0.75)
