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

signal skin_selected(metadata : SkinMetadata) # Emitted when skin button is selected and returns its metadata
#signal swap(position : int)

var skin_metadata : SkinMetadata = null

var can_play_preview : bool = false
var sound_replay_button : bool = false

var is_in_playlist : bool = false
var is_selected_for_swap : bool = false

var is_skin_missing : bool = false
var is_skin_locked : bool = false


func _ready() -> void:
	super()
	press_sound_name = ""

	selected.connect(_selected)
	deselected.connect(_deselected)
	
	work_mode = WORK_MODE.SPECIAL

	if skin_metadata == null or not FileAccess.file_exists(skin_metadata.path):
		is_skin_missing = true
		skin_metadata = null
		modulate = Color.RED
		$Name.text = "MISSING!"
		return
	
	if skin_metadata.preview != null: 
		$Preview.timeout.connect(Data.menu._start_skin_preview.bind(skin_metadata.preview))
	else:
		$Preview.free()
	
	if is_in_playlist: add_to_group("playlist_buttons")
	else: add_to_group("skin_list_buttons")

	if skin_metadata.metadata_hash in Data.skin_list.locked_skins: 
		is_skin_locked = true
		$LabelTexture.texture = load("res://images/menu/locked.png")
		$Name.free()
		return
	
	if skin_metadata.label_art == null: 
		$Name.text = skin_metadata.name
	else: 
		$Name.free()
		$LabelTexture.texture = skin_metadata.label_art


func _selected() -> void:	
	Data.menu._sound("select")

	if Data.menu.screens.has("foreground"): 
		if sound_replay_button: Data.menu.screens["foreground"]._show_button_layout(16)
		elif is_in_playlist: Data.menu.screens["foreground"]._show_button_layout(5)
		else: Data.menu.screens["foreground"]._show_button_layout(4)

	$Selected.visible = true
	create_tween().tween_property($Glow,"modulate:a",0.0,0.2).from(1.0)

	if skin_metadata.preview != null:
		$Preview.start(1.5)
	
	skin_selected.emit(skin_metadata)


func _deselected() -> void:
	$Selected.visible = false

	if skin_metadata.preview != null:
		$Preview.stop()
		Data.menu._stop_skin_preview()


func _input(event : InputEvent) -> void:
	if is_selected:
		if event.is_action_pressed("ui_accept") : 
			if sound_replay_button : 
				_deselected()
				parent_screen._start_game(skin_metadata)
			else : _add_to_playlist()
		elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("backspace") : 
			if sound_replay_button : return
			else : _remove_from_playlist()
		elif event.is_action_pressed("ui_extra") : 
			if sound_replay_button : return
			else : _start_this_skin()


# Mouse input handler
func _on_press(event : InputEvent) -> void:
	if is_selected and event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT: 
				if sound_replay_button : 
					_deselected()
					parent_screen._start_game(skin_metadata)
				else : _add_to_playlist()
			MOUSE_BUTTON_RIGHT: 
				if sound_replay_button : return
				else : _remove_from_playlist()
			MOUSE_BUTTON_MIDDLE: 
				if sound_replay_button : return
				else : _start_this_skin()


func _add_to_playlist() -> void:
	if is_skin_missing or is_skin_locked : return
	
	if is_in_playlist:
		if Data.playlist.skins.size() > 1:
			Data.menu._sound("confirm2")
			# We use selectables var "position" to store current position in playlist
			parent_screen._swap_skins(menu_position.y)
			modulate = Color.PURPLE
			return
	else:
		Data.menu._sound("confirm3")
		Data.playlist._add_to_playlist(skin_metadata.path, skin_metadata.metadata_hash)


func _remove_from_playlist() -> void:
	if parent_screen.currently_swapping_skin_pos > -1 : return

	Data.menu._sound("cancel")
	if not is_in_playlist : return
	
	Data.playlist._remove_from_playlist(menu_position.y)
	parent_screen._display_current_playlist()


func _start_this_skin() -> void:
	if is_skin_missing or is_skin_locked or parent_screen.currently_swapping_skin_pos > -1: return
	
	if not FileAccess.file_exists(skin_metadata.path):
		is_skin_missing = true
		modulate = Color.RED
		$LabelTexture.texture = null
		$Name.text = "MISSING!"
		return
	
	_deselected()
	parent_screen._start_game(skin_metadata, true)
