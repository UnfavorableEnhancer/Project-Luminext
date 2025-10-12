# Project Luminext - an advanced open-source Lumines spiritual successor
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


extends MenuSelectableButton

#-----------------------------------------------------------------------
# Button used in score ranking nodes
#-----------------------------------------------------------------------

var pos : int = 1 ## Position in score ranking
var score : int = 1 ## Record score
var datetime : int = 1 ## Date when this record was made
var author : String = "MISSING_NO" ## Creator of this record
var author_id : String = "" ## Creator ID

var time_attack_screen : MenuScreen = null # Reference to time attack screen


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


## Called when this button is selected
func _selected() -> void:
	parent_menu._play_sound("select")

	var foreground_screen : MenuScreen = parent_menu.screens["foreground"]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(0)
	
	$Back.color = Color("ab2966bf")
	create_tween().tween_property($Back/Glow,"modulate:a",0.0,0.2).from(0.5)


## Called when this button is deselected
func _deselected() -> void:
	$Back.color = Color(0.24,0.24,0.24,0.75)


func _work(_silent : bool = false) -> void:
	return