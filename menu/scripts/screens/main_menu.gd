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


enum MAIN_MENU_TABS {P1_MODE, CONTENT_EDIT, PROFILE, EXTRAS, EMPTY, NONE}

var current_tab : int = MAIN_MENU_TABS.NONE

var is_changing_tabs : bool = false
var is_exiting : bool = false


func _ready() -> void:
	Data.menu.screens["foreground"].visible =  true

	BUTTON_SEARCH_DISTANCE = 0

	remove_started.connect(_hide_tab)
	create_tween().tween_property(Data.main.black,"color",Color(0,0,0,0),1.0)
	
	$Background/BackAnim.seek(Data.menu.screens["background"].get_node("GridAnim").current_animation_position, true)
	
	if not Data.menu.is_music_playing:
		Data.menu._change_music("menu_theme")
		if Data.menu.custom_data.has("last_music_pos"):
			Data.menu.music_player.seek(Data.menu.custom_data["last_music_pos"])
	
	var seek_position : float = fposmod(menu.music_player.get_playback_position(), 8.0)
	$Background/BackAnim.seek(seek_position)
	$Background/FlashAnim.seek(seek_position)
	
	await menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


func _change_tab(tab : String) -> void:	
	var tab_cursor_x : int = 0
	
	match current_tab:
		MAIN_MENU_TABS.P1_MODE : 
			if tab == "1p_mode" : return
			$TabBar/P1MODE.position.x = -3000
			$Main/P1MODE._deselected()
		MAIN_MENU_TABS.CONTENT_EDIT : 
			if tab == "content_edit" : return
			$TabBar/CONTENT.position.x = -3000
			$Main/CONTENT._deselected()
		MAIN_MENU_TABS.PROFILE : 
			if tab == "profile" : return
			$TabBar/PROFILE.position.x = -3000
			$Main/PROFILE._deselected()
		MAIN_MENU_TABS.EXTRAS : 
			if tab == "extras" : return
			$TabBar/EXTRAS.position.x = -3000
			$Main/EXTRAS._deselected()
		MAIN_MENU_TABS.EMPTY :
			Data.menu.previously_selected._deselected()
	
	var tab_instance : Control
	
	selectables.clear()

	_assign_selectable($Main/P1MODE, Vector2i(0,0))
	_assign_selectable($Main/CONTENT, Vector2i(1,0))
	_assign_selectable($Main/PROFILE, Vector2i(2,0))
	_assign_selectable($Main/EXTRAS, Vector2i(3,0))
	
	# We set all of these to zero to ensure that player could select other tab by right/left press from any position
	visited_cursor_positions[0.0] = 0
	visited_cursor_positions[1.0] = 0
	visited_cursor_positions[2.0] = 0
	visited_cursor_positions[3.0] = 0
	
	match tab:
		"1p_mode":
			tab_instance = $TabBar/P1MODE
			
			current_tab = MAIN_MENU_TABS.P1_MODE
			tab_cursor_x = 0
			Data.menu.screens["background"]._change_gradient_colors(Color("121f35"),Color("1f2730"),Color("05061b"),Color("0b352f"),Color("010b0c"))
			
		"content_edit":
			tab_instance = $TabBar/CONTENT
			
			current_tab = MAIN_MENU_TABS.CONTENT_EDIT
			tab_cursor_x = 1
			Data.menu.screens["background"]._change_gradient_colors(Color("360c16"),Color("19001e"),Color("4a0a2b"),Color("1c0303"),Color("080002"))
			
		"profile":
			tab_instance = $TabBar/PROFILE
			
			current_tab = MAIN_MENU_TABS.PROFILE
			tab_cursor_x = 2
			Data.menu.screens["background"]._change_gradient_colors(Color("410042"),Color("181519"),Color("11022a"),Color("27040d"),Color("000509"))
			
		"extras":
			tab_instance = $TabBar/EXTRAS
			
			current_tab = MAIN_MENU_TABS.EXTRAS
			tab_cursor_x = 3
			Data.menu.screens["background"]._change_gradient_colors(Color("004231"),Color("343434"),Color("00120c"),Color("021c20"),Color("000807"))
			
		"empty":
			current_tab = MAIN_MENU_TABS.EMPTY
			Data.menu.screens["background"]._change_gradient_colors(Color("414608"),Color("557816"),Color("357010"),Color("2e3000"),Color("000000"))
			return
	
	var buttons_holder : VBoxContainer = tab_instance.get_node("Buttons")
	
	var button_idx : int = 0
	for button : MenuSelectableButton in buttons_holder.get_children(): 
		if not button.visible : continue
		button_idx += 1
		button.scale.x = 0.0
		_assign_selectable(button, Vector2(tab_cursor_x, button_idx))
	
	tab_instance.modulate.a = 0.0
	tab_instance.position.x = 0

	var tween : Tween = create_tween()
	tween.tween_property(tab_instance,"modulate:a",1.0,0.5)
	
	var tween2 : Tween = create_tween()
	var delay : float = 0.05
	
	for button : MenuSelectableButton in buttons_holder.get_children():
		tween2.parallel().tween_property(button,"scale:x",1.0,0.25).from(0.0).set_delay(delay).set_trans(Tween.TRANS_SINE)
		delay += 0.05


func _hide_tab() -> void:
	var tab_instance : Control
	
	match current_tab:
		MAIN_MENU_TABS.P1_MODE : 
			tab_instance = $TabBar/P1MODE
			$Main/P1MODE._deselected()
		MAIN_MENU_TABS.CONTENT_EDIT : 
			tab_instance = $TabBar/CONTENT
			$Main/CONTENT._deselected()
		MAIN_MENU_TABS.PROFILE : 
			tab_instance = $TabBar/PROFILE
			$Main/PROFILE._deselected()
		MAIN_MENU_TABS.EXTRAS : 
			tab_instance = $TabBar/EXTRAS
			$Main/EXTRAS._deselected()
		MAIN_MENU_TABS.EMPTY :
			Data.menu.currently_selected._deselected()
			return
	
	var buttons_holder : VBoxContainer = tab_instance.get_node("Buttons")
	
	var tween : Tween = create_tween()
	tween.tween_property(tab_instance,"modulate:a",0.0,0.5)
	
	var tween2 : Tween = create_tween()
	var delay : float = 0.05
	
	for button : MenuSelectableButton in buttons_holder.get_children():
		tween2.parallel().tween_property(button,"scale:x",0.0,0.25).from(1.0).set_delay(delay).set_trans(Tween.TRANS_SINE)
		delay += 0.05


func _input(event : InputEvent) -> void:
	super(event)
	
	if menu.current_screen == self and event.is_action_pressed("ui_cancel") and menu.currently_removing_screens_amount == 0:
		_exit_dialog()


func _exit_dialog() -> void:
	if is_exiting : return
	is_exiting = true
	
	var dialog : MenuScreen = Data.menu._add_screen("accept_dialog")
	dialog.desc_text = "Are you sure you want to exit from this game?"
	dialog.canceled.connect(func() -> void: await get_tree().create_timer(1.0).timeout; is_exiting = false)
	dialog.object_to_call = Data.main
	dialog.call_function_name = "_exit"
