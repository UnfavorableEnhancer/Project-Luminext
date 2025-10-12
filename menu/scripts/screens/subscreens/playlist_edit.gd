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


extends MenuScreen

##-----------------------------------------------------------------------
## Loads and displays all avaiable playlists list and allows to select any
##-----------------------------------------------------------------------

const PLAYLIST_CARD : PackedScene = preload("res://menu/objects/playlist_card.tscn") ## Playlist card instance


func _ready() -> void:
	parent_menu.screens["foreground"]._raise()
	
	cursor_selection_success.connect(_scroll)
	_load()


## Loads and displays playlist list
func _load() -> void:
	var playlists : Array = Data._parse(Data.PARSE.PLAYLISTS, true)
	
	if playlists.is_empty() : 
		$Label.text = tr("NO_PLAYLISTS")
		_set_selectable_position($BACK, Vector2i(0,0))
	
	else:
		var count : int = 0
		for playlist_path : String in playlists:
			var playlist_card : MenuSelectableButton = PLAYLIST_CARD.instantiate()
			playlist_card._load(playlist_path)
			playlist_card.menu_position = Vector2i(0,count)
			playlist_card.parent_menu = parent_menu
			playlist_card.parent_screen = self
			
			$Scroll/V.add_child(playlist_card)
			count += 1
		
		_set_selectable_position($BACK, Vector2i(0,count))
	
	if parent_menu.is_locked : await parent_menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


## Scrolls playlist list scroll bar
func _scroll(cursor_pos : Vector2i) -> void:
	$Scroll.scroll_vertical = clamp(cursor_pos.y * 144 - 144 ,0 ,INF)
