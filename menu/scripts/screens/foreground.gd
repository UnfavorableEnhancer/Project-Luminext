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

#-----------------------------------------------------------------------
# Displays button layout depending on selected button/slider
#-----------------------------------------------------------------------

const LABEL_FONT : FontFile = preload("res://fonts/lumifont.ttf")
const BUTTON_ICON_SIZE : Vector2 = Vector2(64,64)

## All avaiable to display button layouts
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

var current_button_layout : int = -1 ## Currently shown button layout
@onready var time_text : Label = $ProfileLayout/Time ## System time display label node


func _ready() -> void:
	main.input_method_changed.connect(_show_button_layout.bind(-1))
	main.total_time_tick.connect(func() -> void: time_text.text = Time.get_time_string_from_system())
	
	_update_profile_info()

	$ProfileLayout/GameVer.text = "PROJECT LUMINEXT\nv" + Data.VERSION + " BUILD : " + Data.BUILD


## Brings this menu screen on top layer
func _raise() -> void:
	_show_button_layout(MENU_BUTTON_LAYOUT.EMPTY)
	parent_menu.move_child(self, parent_menu.get_child_count() - 1)


func _update_profile_info() -> void:
	$ProfileLayout/Name.text = Player.profile_name


## Displays button layout
func  _show_button_layout(button_layout : int = -1) -> void:
	if current_button_layout == button_layout : return
	
	# If you input -1, function will just recreate current button layout (which is used when input method changed)
	if button_layout == -1 : button_layout = current_button_layout
	
	for i : Control in $ButtonLayout.get_children():
		i.queue_free()
	
	match button_layout:
		MENU_BUTTON_LAYOUT.EMPTY:
			return
		
		# SELECT (UP_DOWN) LAYOUT_ENTER BACK
		MENU_BUTTON_LAYOUT.UP_DOWN_SELECT:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_ENTER"))
			
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_BACK_TO_PREV"))
		
		# SELECT LAYOUT_ENTER BACK
		MENU_BUTTON_LAYOUT.SELECT:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_ENTER"))
			
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_BACK_TO_PREV"))
		
		# CHANGE_INPUT LAYOUT_ENTER BACK
		MENU_BUTTON_LAYOUT.CHANGE_INPUT:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_CHANGE_INPUT"))
			
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_BACK_TO_PREV"))
		
		# SELECT ADD_TO_PLAYLIST PLAY_SELECTED_SKIN
		MENU_BUTTON_LAYOUT.SKIN_SELECT:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_ADD_SKIN"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_middle", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Menu._create_button_icon("ui_extra", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_PLAY_SKIN"))
		
		# SELECT SWAP_SKINS REMOVE_SKIN
		MENU_BUTTON_LAYOUT.PLAYLIST_SELECT:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_SWAP_SKIN"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_right", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
			if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : $ButtonLayout.add_child(Menu._create_button_icon("backspace", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_REMOVE_SKIN"))
		
		# CHANGE_VALUE SELECT BACK
		MENU_BUTTON_LAYOUT.SLIDER:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE :
				$ButtonLayout.add_child(Menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))

				$ButtonLayout.add_child(Menu._create_button_icon("left_right", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SLIDER"))
				
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_BACK_TO_PREV"))
			else:
				$ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SLIDER"))
		
		MENU_BUTTON_LAYOUT.MAIN_MENU:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_ENTER"))
			
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_EXIT"))

		MENU_BUTTON_LAYOUT.TOGGLE_UP_DOWN:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_TOGGLE"))
			
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_BACK_TO_PREV"))

		MENU_BUTTON_LAYOUT.TOGGLE:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_TOGGLE"))
			
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_BACK_TO_PREV"))
		
		MENU_BUTTON_LAYOUT.SYNTHESIA_SONG:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_PLAY_SONG"))
			
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_BACK_TO_PREV"))
		
		MENU_BUTTON_LAYOUT.TA_TIME:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_TIME_LIMIT"))
			
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_BACK_TO_PREV"))
		
		MENU_BUTTON_LAYOUT.PROFILE:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_PROFILE"))
			
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_BACK_TO_PREV"))
		
		MENU_BUTTON_LAYOUT.LOGIN_PROFILE:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_PROFILE"))

			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_EXIT"))
		
		MENU_BUTTON_LAYOUT.LOGIN:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_ENTER"))

			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_EXIT"))
		
		MENU_BUTTON_LAYOUT.SCROLL:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SCROLL"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_BACK_TO_PREV"))
		
		MENU_BUTTON_LAYOUT.SOUND_REPLAY:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("all_arrows", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("all_arrows2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else : $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_PLAY_SKIN"))
		
		MENU_BUTTON_LAYOUT.PAUSE:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_ENTER"))

			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_BACK_TO_GAME"))
		
		MENU_BUTTON_LAYOUT.GAMEOVER:
			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("up_down", BUTTON_ICON_SIZE))
				if main.current_input_mode == Main.INPUT_MODE.KEYBOARD : 
					$ButtonLayout.add_child(Menu._create_button_icon("up_down2", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_SELECT"))
			
			if main.current_input_mode == Main.INPUT_MODE.MOUSE : $ButtonLayout.add_child(Menu._create_button_icon("mouse_left", BUTTON_ICON_SIZE))
			else: $ButtonLayout.add_child(Menu._create_button_icon("ui_accept", BUTTON_ICON_SIZE))
			$ButtonLayout.add_child(_create_text_node("LAYOUT_ENTER"))

			if main.current_input_mode != Main.INPUT_MODE.MOUSE : 
				$ButtonLayout.add_child(Menu._create_button_icon("ui_cancel", BUTTON_ICON_SIZE))
				$ButtonLayout.add_child(_create_text_node("LAYOUT_BACK_TO_MENU"))

		
	current_button_layout = button_layout


## Creates special label for button layout
func _create_text_node(text : String) -> Label:
	var label : Label = Label.new()
	var label_settings : LabelSettings = LabelSettings.new()
	
	label_settings.font = LABEL_FONT
	label_settings.font_size = 16
	
	label.text = " " + tr(text) + "   "
	label.uppercase = true
	label.label_settings = label_settings
	
	return label
	 
