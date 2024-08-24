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

# warning-ignore-all:return_value_discarded

signal skin_selected(metadata) # Emitted when skin button is selected and returns its metadata

signal left_click
signal right_click
signal middle_click

var skin_name : String = "" # Skin this button displays
var metadata : Dictionary = {}

var preview : AudioStream = null # Preview sample to play

var can_play_preview : bool = false

var is_in_playlist : bool = false
var is_selected_for_swap : bool = false

var is_skin_missing : bool = false
var is_skin_locked : bool = false

 
func _ready() -> void:
	connect("selected", Callable(self, "_selected"))
	connect("deselected", Callable(self, "_deselected"))

	connect("mouse_exited", Callable(self, "_deselected"))
	
	work_mode = WORK_MODE.SPECIAL

	if metadata.is_empty() : metadata = Data.skin_list._get_skin_metadata_by_name(skin_name)
	
	if not metadata.has("path") or metadata["path"] == null: 
		is_skin_missing = true
		modulate = Color.RED
		$Name.text = "MISSING!"
		return
	
	if metadata["preview"] != null: 
		preview = metadata["preview"]
		$Preview.connect("timeout", Callable(Data.menu, "_start_preview").bind(preview))
	else:
		$Preview.free()
	
	if metadata["name"] in Data.skin_list.locked_skins:
		is_skin_locked = true
	else:
		$Locked.free()
	
	if is_in_playlist: add_to_group("playlist_buttons")
	else: add_to_group("skin_list_buttons")
	
	var skin_label_tex : Texture2D = metadata["label_art"]
	if skin_label_tex == null: 
		$Name.text = skin_name
	else: 
		$Name.free()
		$LabelTexture.texture = skin_label_tex


func _selected() -> void:	
	if Data.menu.screens.has("foreground"): 
		if is_in_playlist: Data.menu.screens["foreground"]._show_button_layout(4)
		else: Data.menu.screens["foreground"]._show_button_layout(3)
	
	if not is_in_playlist and preview != null:
		$Preview.start(1.5)
	
	emit_signal("skin_selected", metadata)


func _deselected() -> void:
	if preview != null:
		$Preview.stop()
		Data.menu._stop_preview()


func _input(event) -> void:
	if is_selected and work_mode == WORK_MODE.SPECIAL:
		if event.is_action_pressed("ui_accept"): emit_signal("left_click")
		elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("backspace"): emit_signal("right_click")
		elif event.is_action_pressed("ui_extra"): emit_signal("middle_click")


# Mouse input handler
func _on_press(event) -> void:
	if is_selected and work_mode == WORK_MODE.SPECIAL:
		if event is InputEventMouseButton and event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT: emit_signal("left_click")
				MOUSE_BUTTON_RIGHT: emit_signal("right_click")
				MOUSE_BUTTON_MIDDLE: emit_signal("middle_click")
