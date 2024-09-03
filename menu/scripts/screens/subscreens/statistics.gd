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

var time_label : Label = null


func _ready() -> void:
	menu.screens["foreground"]._raise()
	
	var font_data : FontFile = load("res://fonts/lumifont.ttf")
	
	var label_settings : LabelSettings = LabelSettings.new()
	label_settings.font = font_data
	label_settings.font_size = 20
	
	for key : String in Data.profile.progress["stats"]:
		var label : Label = Label.new()
		label.label_settings = label_settings
		label.uppercase = true
		
		var value : int = Data.profile.progress["stats"][key]
		
		match key:
			"total_time" : time_label = label
			"total_play_time" : label.text = "Total gameplay time : " + Data._to_time(value)
			"total_score" : label.text = "Total score : " + str(value)
			"total_squares_erased" : label.text = "Total squares erased : " + str(value)
			"total_blocks_erased" : label.text = "Total blocks erased : " + str(value)
			"total_special_blocks_used" : label.text = "Total special blocks used : " + str(value)
			"total_piece_swaps" : label.text = "Total piece swaps used : " + str(value)
			"top_square_group_erased" : label.text = "Top erased square group size : " + str(value)
			"top_square_per_sweep" : label.text = "Top square erased per timeline sweep : " + str(value)
			"top_combo" : label.text = "Top combo : " + str(value)
			"top_score_gain" : label.text = "Top score gain : " + str(value)
			"top_time_spent_in_gameplay" : label.text = "Top time spent in single game : " + Data._to_time(value)
			"total_4x_bonuses" : label.text = "Total 4X bonuses : " + str(value)
			"total_single_color_bonuses" : label.text = "Total single color bonuses : " + str(value)
			"total_all_clears" : label.text = "Total all clear bonuses : " + str(value)
			
			# Time attack mode
			"ta_total_retry_count" : label.text = "Total time attack mode attempts count : " + str(value)
			"ta_top_retry_count" : label.text = "Top time attack mode attempts streak : " + str(value)
			"ta_total_time" : label.text = "Total time spent in time attack mode : " + Data._to_time(value)
			
			# Editors data
			"total_skin_editor_time" : label.text = "Total time spent in skin editor : " + Data._to_time(value)
			"total_skin_load_times" : label.text = "Total skin loads in skin editor : " + str(value)
		
		$Content/Scroll/V.add_child(label)
	
	await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


func _process(_delta: float) -> void:
	time_label.text = "Total time : " + Data._to_time(Data.profile.progress["stats"]["total_time"])

	if Input.is_action_pressed("ui_up") :
		$Content/Scroll.scroll_vertical = clamp($Content/Scroll.scroll_vertical - 10, 0, INF)
	if Input.is_action_pressed("ui_down") :
		$Content/Scroll.scroll_vertical = clamp($Content/Scroll.scroll_vertical + 10, 0, INF)
