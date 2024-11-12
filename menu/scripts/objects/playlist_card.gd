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

var playlist : SkinPlaylist = null 
var is_empty : bool = false # Is this playlist is empty and couldn't be loaded


func _ready() -> void:
	super()
	
	selected.connect(_selected)
	deselected.connect(_deselected)


# Loads playlist content
func _load(playlist_path : String) -> void:
	playlist = SkinPlaylist.new()
	var success : int = playlist._load(playlist_path)
	
	if success != OK: 
		$Name.text = tr("FAILED_PLAYLIST") + " " + playlist.name
		$Name.modulate = Color.RED
		is_empty = true
		return
	
	if playlist.skins.size() == 0: 
		$Name.text = tr("CORRUPT_PLAYLIST") + " " + playlist.name
		$Name.modulate = Color.RED
		is_empty = true
		return
	
	$Name.text = playlist.name.get_slice('.',0)
	
	# Add skin buttons according to loaded playlist
	var count : int = 0
	for skin_entry : Array in playlist.skins:
		if count > 3: return
		var skin_hash : StringName = skin_entry[1]
		var skin_metadata : SkinMetadata = Data.skin_list._get_skin_metadata_by_hash(skin_hash)
		if skin_metadata == null : continue

		var skin_label : TextureRect = TextureRect.new()
		skin_label.custom_minimum_size = Vector2(256, 64)
		skin_label.texture = skin_metadata.label_art
		skin_label.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		$Skins.add_child(skin_label)
		count += 1


func _work(_silent : bool = false) -> void:
	if not Data.menu.is_locked and not is_empty:
		Data.playlist = playlist
		Data.menu.screens["playlist_mode"]._display_current_playlist()
		parent_screen._remove()


func _selected() -> void:
	modulate = Color(0.5,1,1,1)
	Data.menu._sound("select")
	
	var foreground_screen : MenuScreen = Data.menu.screens["foreground"]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(0)


func _deselected() -> void:
	modulate = Color.WHITE
