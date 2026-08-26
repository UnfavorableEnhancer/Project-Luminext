# Project Luminext - an ultimate block-stacking puzzle game
# Copyright (C) <2024-2026> <unfavorable_enhancer>
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

extends VBoxContainer
##
## Allows to insert single texture file
##
class_name AnimatedTexturePropertyEditor

signal frames_added(textures_filepaths : PackedStringArray)
signal spritesheet_added(spritesheet_filepath : String)
signal frame_moved(from : int, to : int)
signal frame_replaced(at : int, texture_filepath : String)
signal frame_removed(at : int)
signal all_frames_removed()

signal fps_changed(new_value : int)
signal loop_state_changed(new_state : bool)

const FRAMES_PER_PAGE : int = 12 ## Amount of frames shown per page

var current_page : int = 1 ## Current page number
var spriteframes : SpriteFrames = null ## Currently viewing spriteframes

var selected_frame_instance : TextureButton = null ## Currently selected frame node
var selected_frame_instance_index : int = -1 ## Currently selected frame node index
var selected_frame_index : int = -1 ## Currently selected frame index in spritesheet

var is_replacing_frame : bool = false

var file_browser : FileBrowser = null ## Parent editor file browser instance
var confirm_dialog = null ## Parent editor confimation dialog instance


func _ready() -> void:
	for i : int in FRAMES_PER_PAGE :
		var frame : TextureButton = get_node("V/Grid/Frame" + str(i+1))
		
		frame.selected.connect(_on_frame_selected)
		frame.internal_index = i + 1
		frame.visible = false


## Sets text above editor
func set_label_text(value_name : String) -> void:
	$Name.text = value_name

## Sets [SpriteFrames] frames to edit
func set_frames(new_spriteframes : SpriteFrames) -> void:
	spriteframes = new_spriteframes
	show_frames()

## Sets currently editing spritesheet animation fps
func set_animation_fps(new_fps : int) -> void:
	$H/FPS.value = new_fps

## Sets currently editing spritesheet animation loop
func set_animation_loop(enabled : bool) -> void:
	$H2/Loop.button_pressed = enabled


## Shows frames in current page
func show_frames() -> void:
	for i : int in FRAMES_PER_PAGE :
		var frame : TextureButton = get_node("V/Grid/Frame" + str(i+1))
		var index : int = i + (current_page - 1) * FRAMES_PER_PAGE
		
		if index >= spriteframes.get_frame_count(&"default") :
			frame.visible = false 
			continue
		
		frame.set_texture(spriteframes.get_frame_texture(&"default", index))
		frame.index = index
		frame.visible = true


## Called when some frame is selected
func _on_frame_selected(frame_index : int, frame_node_index : int) -> void:
	selected_frame_index = frame_index
	selected_frame_instance_index = frame_node_index
	selected_frame_instance = get_node("V/Grid/Frame" + str(frame_node_index))
	$Free/Selection.visible = true
	$Free/Selection.position = selected_frame_instance.position + Vector2(0, -492)

## Called after some action with frames, to show actually selected frame
func _update_selection() -> void:
	selected_frame_instance = get_node("V/Grid/Frame" + str(selected_frame_instance_index))
	$Free/Selection.visible = true
	$Free/Selection.position = selected_frame_instance.position + Vector2(0, -492)

## Deselects currently selected frame
func _remove_selection() -> void:
	$Free/Selection.visible = false
	selected_frame_index = -1
	selected_frame_instance_index = -1
	selected_frame_instance = null


func _on_move_left_pressed() -> void:
	if selected_frame_index <= 0: return
	frame_moved.emit(selected_frame_index, selected_frame_index - 1)
	
	if selected_frame_instance_index == 1 : 
		_remove_selection()
	else:
		selected_frame_index = selected_frame_index - 1
		selected_frame_instance_index = selected_frame_instance_index - 1
		_update_selection()

func _on_move_right_pressed() -> void:
	if selected_frame_index < 0 or selected_frame_index == (spriteframes.get_frame_count(&"default") - 1): return
	frame_moved.emit(selected_frame_index, selected_frame_index + 1)
	
	if selected_frame_instance_index == FRAMES_PER_PAGE : 
		_remove_selection()
	else:
		selected_frame_index = selected_frame_index + 1
		selected_frame_instance_index = selected_frame_instance_index + 1
		_update_selection()

func _on_add_pressed() -> void:
	is_replacing_frame = false
	
	file_browser.setup_image_filter()
	file_browser.select_files_and_dir()
	file_browser.title = "Select linear sprite-sheet image, multiple images or images directory"
	file_browser.files_selected.connect(_on_file_browser_files_selected)
	file_browser.file_selected.connect(_on_file_browser_file_selected)
	file_browser.dir_selected.connect(_on_file_browser_dir_selected)
	file_browser.popup_centered()

func _on_replace_pressed() -> void:
	is_replacing_frame = true
	
	file_browser.setup_image_filter()
	file_browser.select_single_file()
	file_browser.title = "Select image for replacement"
	file_browser.file_selected.connect(_on_file_browser_file_selected)
	file_browser.popup_centered()

func _on_delete_selected_pressed() -> void:
	frame_removed.emit(selected_frame_index)
	if spriteframes.get_frame_count(&"default") == 0 : _remove_selection()
	else : _update_selection()

func _on_delete_all_pressed() -> void:
	# TODO : Add confirmation dialog
	
	all_frames_removed.emit()
	_remove_selection()


func _on_page_up_pressed() -> void:
	if current_page + 1 > (int(spriteframes.get_frame_count(&"default") / (FRAMES_PER_PAGE + 1)) + 1) : return
	
	_remove_selection()
	current_page += 1
	$V/H/Page.text = str(current_page)
	show_frames()

func _on_page_down_pressed() -> void:
	if current_page == 1 : return
	
	_remove_selection()
	current_page -= 1
	$V/H/Page.text = str(current_page)
	show_frames()

func _on_page_value_changed(value : String) -> void:
	if not value.is_valid_int() or \
	int(value) < 1 or \
	int(value) > (int(spriteframes.get_frame_count(&"default") / (FRAMES_PER_PAGE + 1)) + 1) : 
		$V/H/Page.text = str(current_page)
		return
	
	_remove_selection()
	current_page = int(value)
	$V/H/Page.text = str(current_page)
	show_frames()


func _on_fps_value_changed(value: float) -> void:
	fps_changed.emit(value as int)

func _on_loop_toggled(toggled_on: bool) -> void:
	loop_state_changed.emit(toggled_on)


func _on_file_browser_canceled() -> void:
	file_browser.files_selected.disconnect(_on_file_browser_files_selected)
	
	if not is_replacing_frame:
		file_browser.file_selected.disconnect(_on_file_browser_file_selected)
		file_browser.dir_selected.disconnect(_on_file_browser_dir_selected)

func _on_file_browser_files_selected(filepath : PackedStringArray) -> void:
	file_browser.files_selected.disconnect(_on_file_browser_files_selected)
	file_browser.file_selected.disconnect(_on_file_browser_file_selected)
	file_browser.dir_selected.disconnect(_on_file_browser_dir_selected)
	frames_added.emit(filepath)

func _on_file_browser_dir_selected(dirpath : String) -> void:
	file_browser.files_selected.disconnect(_on_file_browser_files_selected)
	file_browser.file_selected.disconnect(_on_file_browser_file_selected)
	file_browser.dir_selected.disconnect(_on_file_browser_dir_selected)
	
	var output : Array[String] = []
	for path : String in DirAccess.get_files_at(dirpath):
		if ("." + path.get_extension()) in ModdableAsset.TextureAsset.FORMAT_EXTENSIONS:
			output.append(path)
	
	frames_added.emit(selected_frame_index, PackedStringArray(output))

func _on_file_browser_file_selected(filepath : String) -> void:
	file_browser.file_selected.disconnect(_on_file_browser_file_selected)
	
	if is_replacing_frame:
		frame_replaced.emit(selected_frame_index, filepath)
	else:
		file_browser.files_selected.disconnect(_on_file_browser_files_selected)
		file_browser.dir_selected.disconnect(_on_file_browser_dir_selected)
		spritesheet_added.emit(filepath)
