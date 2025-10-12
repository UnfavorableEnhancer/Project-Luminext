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
# Button used to display loaded skin metadata
# By default its intended to be used in 'Playlist Mode' menu screen
# But if you change *'accept_action', 'cancel_action'* and *'extra_action'* after adding this button
# as child, you can do anything else you want
#-----------------------------------------------------------------------

signal skin_selected(metadata : SkinMetadata) ## Emitted when skin button is selected and returns its metadata
signal invalid_skin_selected(error : String) ## Emitted when invalid skin button is selected and returns error string
signal locked_skin_selected(lock_condition : String) ## Emitted when locked skin button is selected and returns its unlock condition

var skin_metadata : SkinMetadata = null ## Skin metadata this button displays

var can_play_preview : bool = false ## True if skin metadata has music preview sample
var button_layout : int = 4 ## Button layout foreground menu screen will show when this button is selected

var is_in_playlist : bool = false ## True if this skin button is put into playlist
var is_selected_for_swap : bool = false ## True if this skin button was selected to be swapped with other

var is_skin_invalid : bool = false ## True if loaded into button [SkinMetadata] is invalid
var is_skin_locked : bool = false ## True if skin is locked by current player progress


func _ready() -> void:
	super()
	press_sound_name = ""

	selected.connect(_selected)
	deselected.connect(_deselected)
	
	work_mode = WORK_MODE.SPECIAL
	accept_action = _add_to_playlist
	cancel_action = _remove_from_playlist
	extra_action = _start_this_skin

	if is_in_playlist: add_to_group("playlist_buttons")
	else: add_to_group("skin_list_buttons")

	if skin_metadata == null:
		is_skin_invalid = true
		modulate = Color.RED
		$Name.text = "INVALID!"
		return
	
	if not FileAccess.file_exists(skin_metadata.path):
		is_skin_invalid = true
		modulate = Color.ORANGE
		$Name.text = skin_metadata.name
		return
	
	if Data.skin_list.locked_skins.has(skin_metadata.id):
		is_skin_locked = true
		$LabelTexture.texture = load("res://images/menu/locked.png")
		$Name.free()
		return

	#if skin_metadata.preview != null : $Preview.timeout.connect(parent_menu._start_skin_preview.bind(skin_metadata.preview))
	#else : 
	$Preview.free()
	
	if skin_metadata.label_art == null: 
		$Name.text = skin_metadata.name
	else: 
		$Name.free()
		$LabelTexture.texture = skin_metadata.label_art


## Called when this button is selected
func _selected() -> void:
	if is_off : return

	parent_menu._play_sound("select")

	if parent_menu.screens.has("foreground"): 
		parent_menu.screens["foreground"]._show_button_layout(button_layout)

		#if sound_replay_button: Data.menu.screens["foreground"]._show_button_layout(16)
		#elif is_in_playlist: Data.menu.screens["foreground"]._show_button_layout(5)
		#else: Data.menu.screens["foreground"]._show_button_layout(4)

	$Selected.visible = true
	create_tween().tween_property($Glow,"modulate:a",0.0,0.2).from(1.0)

	if is_skin_invalid : 
		invalid_skin_selected.emit("WIP")
		return
	if is_skin_locked : 
		locked_skin_selected.emit("WIP")
		return

	#if skin_metadata.preview != null : $Preview.start(1.5)
	skin_selected.emit(skin_metadata)


## Called when this button is deselected
func _deselected() -> void:
	if is_off : return

	$Selected.visible = false

	if is_skin_invalid : return
	if is_skin_locked : return
	#if skin_metadata.preview != null:
		#$Preview.stop()
		#parent_menu._stop_skin_preview()


## Adds loaded [SkinMetadata] into skin playlist
func _add_to_playlist() -> void:
	if is_off or is_skin_invalid or is_skin_locked : return
	
	if not FileAccess.file_exists(skin_metadata.path):
		is_skin_invalid = true
		modulate = Color.RED
		$LabelTexture.texture = null
		$Name.text = "INVALID!"
		return

	# If we push button inside playlist, start swap routine instead
	if is_in_playlist and Data.skin_playlist.skins_ids.size() > 1:
		parent_menu._play_sound("confirm2")
		# We use selectables var "position" to store current position in playlist
		parent_screen._swap_skins(menu_position.y - 1)
		modulate = Color.PURPLE
		return
	else:
		parent_menu._play_sound("confirm3")
		Data.skin_playlist._add_to_playlist(skin_metadata)


## Removes loaded [SkinMetadata] from skin playlist
func _remove_from_playlist() -> void:
	if is_off or not is_in_playlist or parent_screen.currently_swapping_skin_pos > -1 : return

	parent_menu._play_sound("cancel")
	Data.skin_playlist._remove_from_playlist(menu_position.y - 1)


## Starts playlist mode game with loaded [SkinMetadata]
func _start_this_skin() -> void:
	if is_off or is_skin_invalid or is_skin_locked or parent_screen.currently_swapping_skin_pos > -1: return
	
	if not FileAccess.file_exists(skin_metadata.path):
		is_skin_invalid = true
		modulate = Color.RED
		$LabelTexture.texture = null
		$Name.text = "INVALID!"
		return
	
	_deselected()
	parent_screen._start_game(true, skin_metadata)
