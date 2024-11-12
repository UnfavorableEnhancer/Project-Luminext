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


extends Button

#-----------------------------------------------------------------------
# This button is used to input sound into SkinEditor dictionary entries
#-----------------------------------------------------------------------

@onready var editor : MenuScreen = Data.menu.get_node("Skin Editor")

@export var sound_name : String = "" # Sound name this button edits
@export_multiline var description : String = ""
@export var category : String = "sounds" # In which dictionary inside skin data this sound lays

# To make button multi-sound you need to assign SpinBox node named 'N'
# And make sure that corresponding sound inside SkinData is [null] Array
var is_multi_sound_button : bool = false
var current_sound : int = 0 # If its multi-sound button, this int shows current selection

var has_sound : bool = false # Does current entry has any sound?


func _ready() -> void:
	add_to_group("sound_buttons")
	
	gui_input.connect(_on_press)
	mouse_entered.connect(_selected)
	
	text = tr("SE_INPUT") + " " + tr(sound_name.to_upper())
	
	if has_node("N"): 
		is_multi_sound_button = true
		get_node("N").value_changed.connect(_load_sound)
	
	if has_node("Play"): get_node("Play").pressed.connect(_play_sound)


# Removes sound
func _remove_sound() -> void:
	var sounds : Variant = editor.skin_data.get(category)
	
	if is_multi_sound_button:
		if sounds[sound_name][current_sound] != null:
			sounds[sound_name].pop_at(current_sound)
			
			get_node("N").max_value -= 1 #get_node("N").max_value - 1
			get_node("N").value -= 1
			current_sound -= 1

			_load_sound()
	else:
		sounds[sound_name] = null
		text = tr("SE_INPUT") + " " + tr(sound_name.to_upper())


# Checks sound existance inside skin data and display corresponding text
func _load_sound(number : int = 0) -> void:
	var sounds : Variant = editor.skin_data.get(category)
	current_sound = number
	
	if is_multi_sound_button:
		if sounds[sound_name][current_sound] == null:
			text = tr(sound_name.to_upper())
			has_sound = false
		else:
			text = tr("SE_SOME") + " " + tr(sound_name.to_upper())
			has_sound = true
	
	else:
		if sounds[sound_name] == null:
			text = tr(sound_name.to_upper())
			has_sound = false
		else:
			text = tr("SE_SOME") + " " + tr(sound_name.to_upper())
			has_sound = true


# Called on button press
func _on_press(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				var path : String
				
				editor._open_file_dialog("audio")
				await editor.file_selected
				
				if is_multi_sound_button:
					path = editor._edit_skn_audio(sound_name,category,current_sound)
					
					if path == "" : return
					# If we added sound to the end of sounds array
					if not has_sound:
						# Increase SpinBox max to make adding more sounds possible
						get_node("N").max_value += 1
					
					has_sound = true
				
				else: 
					path = editor._edit_skn_audio(sound_name,category)
					
					if path == "" : return
					has_sound = true
				
				text = path.substr(path.length() - 20)
			
			MOUSE_BUTTON_RIGHT: _remove_sound()


# Makes button play currently assigned sound
func _play_sound() -> void:
	if has_sound:
		var player : AudioStreamPlayer = AudioStreamPlayer.new()
		
		if is_multi_sound_button: player.stream = editor.skin_data.get(category)[sound_name][current_sound]
		else: player.stream = editor.skin_data.get(category)[sound_name]
		
		if player.stream == null:
			player.queue_free()
			return
		
		player.finished.connect(player.queue_free)
		add_child(player)
		player.play()


# Called when hovered by mouse
func _selected() -> void:
	editor._show_description(description)
