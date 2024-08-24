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

const LABEL_FONT : FontFile = preload("res://fonts/lumifont.ttf")
const BUTTON_ICON_SIZE : Vector2 = Vector2(64,64)

enum MENU_BUTTON_LAYOUT{
	EMPTY,
	UP_DOWN_SELECT,
	SELECT,
	CHANGE_INPUT,
	SKIN_SELECT,
	PLAYLIST_SELECT,
	SLIDER,
	MAIN_MENU,
	TOGGLE_UP_DOWN,
	TOGGLE,
	SYNTHESIA_SONG,
	TA_TIME,
	PROFILE,
	LOGIN_PROFILE,
	LOGIN,
	SCROLL,
	SOUND_REPLAY,
	PAUSE,
	GAMEOVER,
}

var current_button_layout : int = -1
@onready var time_text : Label = $ProfileLayout/Time


func _ready() -> void:
	Data.input_method_changed.connect(_show_button_layout.bind(-1))
	
	$Timer.timeout.connect(func() -> void: time_text.text = Time.get_time_string_from_system())
	$Timer.start(1.0)
	
	$ProfileLayout/Name.text = Data.profile.name


func _raise() -> void:
	_show_button_layout(MENU_BUTTON_LAYOUT.EMPTY)
	menu.move_child(self,menu.get_child_count() - 1)


func  _show_button_layout(button_layout : int = -1) -> void:
	if current_button_layout == button_layout : return
	
	# If you input -1, function will just recreate current button layout (which is used when input method changed)
	if button_layout == -1 : button_layout = current_button_layout
	
	for i : Control in $ButtonLayout.get_children():
		i.queue_free()
	
	match button_layout:
		MENU_BUTTON_LAYOUT.EMPTY:
			return
		
		# SELECT (UP_DOWN) ENTER BACK
		MENU_BUTTON_LAYOUT.UP_DOWN_SELECT:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("ENTER"))
			
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("BACK TO PREVIOUS SCREEN"))
		
		# SELECT ENTER BACK
		MENU_BUTTON_LAYOUT.SELECT:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("ENTER"))
			
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("BACK TO PREVIOUS SCREEN"))
		
		# CHANGE_INPUT ENTER BACK
		MENU_BUTTON_LAYOUT.CHANGE_INPUT:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("CHANGE INPUT"))
			
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("BACK TO PREVIOUS SCREEN"))
		
		# SELECT ADD_TO_PLAYLIST PLAY_SELECTED_SKIN
		MENU_BUTTON_LAYOUT.SKIN_SELECT:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("ADD THIS SKIN TO PLAYLIST"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_middle", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Data.menu._create_button_icon("ui_extra", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("PLAY THIS SKIN"))
		
		# SELECT SWAP_SKINS REMOVE_SKIN
		MENU_BUTTON_LAYOUT.PLAYLIST_SELECT:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("SWAP THIS SKIN"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_right", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
			if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : $ButtonLayout.add_child(Data.menu._create_button_icon("backspace", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("REMOVE THIS SKIN FROM PLAYLIST"))
		
		# CHANGE_VALUE SELECT BACK
		MENU_BUTTON_LAYOUT.SLIDER:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE :
				$ButtonLayout.add_child(Data.menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))

				$ButtonLayout.add_child(Data.menu._create_button_icon("left_right", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("CHANGE SLIDER VALUE"))
				
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("BACK TO PREVIOUS SCREEN"))
			else:
				$ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("CHANGE SLIDER VALUE"))
		
		MENU_BUTTON_LAYOUT.MAIN_MENU:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("ENTER"))
			
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("EXIT FROM THE GAME"))

		MENU_BUTTON_LAYOUT.TOGGLE_UP_DOWN:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("TOGGLE ON/OFF"))
			
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("BACK TO PREVIOUS SCREEN"))

		MENU_BUTTON_LAYOUT.TOGGLE:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("TOGGLE ON/OFF"))
			
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("BACK TO PREVIOUS SCREEN"))
		
		MENU_BUTTON_LAYOUT.SYNTHESIA_SONG:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("PLAY WITH THIS SONG"))
			
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("BACK TO PREVIOUS SCREEN"))
		
		MENU_BUTTON_LAYOUT.TA_TIME:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("CHOOSE THIS TIME LIMIT"))
			
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("BACK TO PREVIOUS SCREEN"))
		
		MENU_BUTTON_LAYOUT.PROFILE:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("CHOOSE THIS PROFILE"))
			
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("BACK TO PREVIOUS SCREEN"))
		
		MENU_BUTTON_LAYOUT.LOGIN_PROFILE:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("CHOOSE THIS PROFILE"))

			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("EXIT FROM THE GAME"))
		
		MENU_BUTTON_LAYOUT.LOGIN:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("ENTER"))

			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("EXIT FROM THE GAME"))
		
		MENU_BUTTON_LAYOUT.SCROLL:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SCROLL UP/DOWN"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("BACK TO PREVIOUS SCREEN"))
		
		MENU_BUTTON_LAYOUT.SOUND_REPLAY:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("PLAY THIS SKIN"))
		
		MENU_BUTTON_LAYOUT.PAUSE:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("ENTER"))

			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("BACK TO THE GAME"))
		
		MENU_BUTTON_LAYOUT.GAMEOVER:
			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if Data.current_input_mode == Data.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Data.menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("SELECT"))
			
			if Data.current_input_mode == Data.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Data.menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Data.menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("ENTER"))

			if Data.current_input_mode != Data.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Data.menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("RETURN BACK TO MENU"))

		
	current_button_layout = button_layout


# Helper function, which makes text string node for input map display
func _create_text_node(text : String) -> Label:
	var label : Label = Label.new()
	var label_settings : LabelSettings = LabelSettings.new()
	
	label_settings.font = LABEL_FONT
	label_settings.font_size = 16
	
	label.text = " " + text + "   "
	label.uppercase = true
	label.label_settings = label_settings
	
	return label
	 
