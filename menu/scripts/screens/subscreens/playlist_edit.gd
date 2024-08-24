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

const PLAYLIST_CARD : PackedScene = preload("res://menu/objects/playlist_card.tscn")


func _ready() -> void:
	menu.screens["foreground"]._raise()
	
	cursor_selection_success.connect(_scroll)
	_load()


func _load() -> void:
	var playlists : Array = Data._parse(Data.PARSE.PLAYLISTS)
	if playlists.is_empty() : 
		$Label.text = "NO PLAYLISTS FOUND"
		_assign_selectable($BACK, Vector2i(0,0))
		if menu.is_locked : await menu.all_screens_added
		cursor = Vector2i(0,0)
		_move_cursor()
		return
	
	var count : int = 0
	for playlist_path : String in playlists:
		var playlist_card : MenuSelectableButton = PLAYLIST_CARD.instantiate()
		playlist_card._load(playlist_path)
		playlist_card.menu_position = Vector2i(0,count)
		
		$Scroll/V.add_child(playlist_card)
		count += 1
	
	_assign_selectable($BACK, Vector2i(0,count))
	
	if menu.is_locked : await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


func _scroll(cursor_pos : Vector2i) -> void:
	$Scroll.scroll_vertical = clamp(cursor_pos.y * 144 - 144 ,0 ,INF)
