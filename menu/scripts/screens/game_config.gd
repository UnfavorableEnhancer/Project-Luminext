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

##-----------------------------------------------------------------------
## This menu screen allows to edit profile gamerule, which is used only for [PlaylistMode] and [SynthesiaMode]
##-----------------------------------------------------------------------

## All avaiable options tabs
enum OPTIONS_TABS {BLOCKS, RULES, PARAMS}

var current_tab : int = OPTIONS_TABS.BLOCKS ## Currently selected option tab


func _ready() -> void:
	if parent_menu.screens.has("background"):
		parent_menu.screens["background"]._change_gradient_colors(Color("00210b"),Color("00211f"),Color("0a2430"),Color("121f35"),Color("00000A"))

	_set_selectables(OPTIONS_TABS.BLOCKS)

	cursor_selection_success.connect(_scroll)

	_load_settings()

	await parent_menu.all_screens_added
	cursor = Vector2i(0,0)
	_move_cursor()


## Opens text input subscreen to enter seed value
func _set_seed() -> void:
	var input : MenuScreen = parent_menu._add_screen("text_input")
	input.desc_text = tr("SEED_DIALOG")

	var value : String = await input.closed_text
	if value.is_empty() : return

	Player.config.user_ruleset._set_config_value("seed", int(value))
	$PARAMS/SCROLL/V/SEED/Button/IO.text = value


## Scrolls selected tab scroll bar
func _scroll(cursor_pos : Vector2) -> void:
	if main.current_input_mode == Main.INPUT_MODE.MOUSE: return

	if cursor_pos.x == 1:
		if current_tab == OPTIONS_TABS.BLOCKS:
			$BLOCKS/SCROLL.scroll_vertical = clamp(cursor_pos.y * 68 - 136 ,0 ,INF)
		elif current_tab == OPTIONS_TABS.RULES:
			$RULES/SCROLL.scroll_vertical = clamp(cursor_pos.y * 68 - 136 ,0 ,INF)
		elif current_tab == OPTIONS_TABS.PARAMS:
			$PARAMS/SCROLL.scroll_vertical = clamp(cursor_pos.y * 68 - 136 ,0 ,INF)


## Changes current settings tab
func _change_tab(to_tab : String) -> void:
	var tween : Tween = create_tween().set_parallel(true)

	match to_tab:
		"blocks":
			current_tab = OPTIONS_TABS.BLOCKS
			$BLOCKS.visible = true
			$RULES.visible = false
			$PARAMS.visible = false
			
			$BLOCKS.position = Vector2(536,96)
			
			_set_selectables(current_tab)
			
			tween.tween_property($BLOCKS,"scale:y",1.0,0.25).from(0.0)
			tween.tween_property($BLOCKS,"modulate:a",1.0,0.25).from(0.0)
		
		"rules":
			current_tab = OPTIONS_TABS.RULES
			$BLOCKS.visible = false
			$RULES.visible = true
			$PARAMS.visible = false
			
			$RULES.position = Vector2(536,96)
			
			_set_selectables(current_tab)

			tween.tween_property($RULES,"scale:y",1.0,0.25).from(0.0)
			tween.tween_property($RULES,"modulate:a",1.0,0.25).from(0.0)
		
		"params":
			current_tab = OPTIONS_TABS.PARAMS
			$BLOCKS.visible = false
			$RULES.visible = false
			$PARAMS.visible = true
			
			$PARAMS.position = Vector2(536,96)
			
			_set_selectables(current_tab)

			tween.tween_property($PARAMS,"scale:y",1.0,0.25).from(0.0)
			tween.tween_property($PARAMS,"modulate:a",1.0,0.25).from(0.0)


## Used by sliders to set gamerule config value
func _change_option(value : float, setting_name : String) -> void:
	Player.config.user_ruleset._set_config_value(setting_name, value)


## Sets menu screen selectables for **'tab'**
func _set_selectables(tab : int) -> void:
	selectables.clear()
	
	_set_selectable_position($Menu/BLOCKS, Vector2i(0,0))
	_set_selectable_position($Menu/RULES, Vector2i(0,1))
	_set_selectable_position($Menu/PARAMS, Vector2i(0,2))
	_set_selectable_position($Menu/APPLY, Vector2i(0,3))
	_set_selectable_position($Menu/LOAD, Vector2i(0,4))
	_set_selectable_position($Menu/SAVE, Vector2i(0,5))
	_set_selectable_position($Menu/EXIT, Vector2i(0,6))

	var tab_instance : Control

	match tab:
		OPTIONS_TABS.BLOCKS: tab_instance = $BLOCKS/SCROLL/V
		OPTIONS_TABS.RULES: tab_instance = $RULES/SCROLL/V
		OPTIONS_TABS.PARAMS: tab_instance = $PARAMS/SCROLL/V
		
	var y_position : int = 0

	for child_idx : int in tab_instance.get_child_count():
		var child : Control = tab_instance.get_child(child_idx)
		if not child is TextureRect : continue

		var selectable : Control = child.get_child(0)

		_set_selectable_position(selectable, Vector2i(1,y_position))
		y_position += 1


## Loads current profile gamerule settings
func _load_settings() -> void:
	get_tree().call_group("toggle_buttons","_set_toggle_by_data")
	get_tree().call_group("sliders","_set_value_by_data")
	
	$PARAMS/SCROLL/V/SEED/Button/IO.text = str(Player.config.user_ruleset.params["seed"])


## Exits this menu screen with applying of all changed settings
func _exit_with_apply() -> void:
	var color_check : bool = false
	for i : String in ["red","white","green","purple"]:
		if Player.config.user_ruleset.blocks[i]: color_check = true
	if not color_check:
		main._display_system_message("WARNING!\nNO BLOCK COLORS ENABLED!")
		return

	Player.config.user_ruleset.rules_changed.emit()
	Player._save_profile()
	
	parent_menu._change_screen(previous_screen_name)


## Exits this menu screen with canceling all changes
func _exit_with_cancel() -> void:
	Player.config.user_ruleset._reset_config_setting("all")

	parent_menu._change_screen(previous_screen_name)


## Saves selected gamerule settings as preset
func _save_preset() -> void:
	var input : MenuScreen = parent_menu._add_screen("text_input")
	input.desc_text = tr("SAVE_PRESET_DIALOG")
	input.accept_function = Player.config.user_ruleset._save
