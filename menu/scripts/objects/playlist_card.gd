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
# Button which shows loaded skin playlist contents
#-----------------------------------------------------------------------

const SKIN_BUTTON : PackedScene = preload("res://menu/objects/skin_button.tscn") ## Skin button packed scene

var playlist : SkinPlaylist = null ## Playlist reference
var is_empty : bool = false ## True is passed playlist is empty


func _ready() -> void:
	super()
	
	selected.connect(_selected)
	deselected.connect(_deselected)


## Loads and displays playlist content
func _load(playlist_path : String) -> void:
	playlist = SkinPlaylist.new()
	var success : int = playlist._load(playlist_path)
	
	if success != OK: 
		$Name.text = tr("FAILED_PLAYLIST") + " " + playlist.name
		$Name.modulate = Color.RED
		is_empty = true
		return
	
	if playlist.skins.size() == 0: 
		$Name.text = tr("EMPTY_PLAYLIST") + " " + playlist.name
		$Name.modulate = Color(0.5,0.5,0.5,1.0)
		is_empty = true
		return
	
	$Name.text = playlist.name.get_slice('.',0)
	
	# Add skin buttons according to loaded playlist
	for  i : int in playlist.skins_ids.size():
		var skin_metadata : SkinMetadata = playlist._get_skin_metadata_in_position(i)

		if skin_metadata == null:
			skin_metadata = SkinMetadata.new()
			skin_metadata.name = playlist.skins_names[i]

		var skin_label : MenuSelectableButton = SKIN_BUTTON.instantiate()
		skin_label.skin_metadata = skin_metadata
		skin_label.custom_minimum_size = Vector2(256, 64)
		skin_label._set_disable(true)
		skin_label.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		$Skins.add_child(skin_label)


## Called when button is pressed [br]
## **'silent'** - If true, no press sound will play
func _work(silent : bool = false) -> void:
	if parent_menu.is_locked or is_empty: 
		return
		
	if not silent : parent_menu._play_sound("confirm")
	Data.skin_playlist = playlist
	parent_menu.screens["playlist_mode"]._display_current_playlist()
	parent_screen._remove()


## Called when this button is selected
func _selected() -> void:
	modulate = Color(0.5,1.0,1.0,1.0)
	parent_menu._play_sound("select")
	
	var foreground_screen : MenuScreen = parent_menu.screens["foreground"]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(0)


## Called when this button is deselected
func _deselected() -> void:
	modulate = Color.WHITE
