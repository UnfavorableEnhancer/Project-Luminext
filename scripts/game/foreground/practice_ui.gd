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


extends UIElement

##-----------------------------------------------------------------------
## Main UI for PracticeMode
## Shows texts messages telling player about current tutorial stage goal
##-----------------------------------------------------------------------

const LABEL_FONT : FontFile = preload("res://fonts/sani_trixie_sans.ttf")
const BUTTON_ICON_SIZE : Vector2 = Vector2(64,64)

signal intro_finished
signal outro_finished
signal message_resetted

var label_settings : LabelSettings


func _ready() -> void:
	$Message/Back.scale.x = 0.0
	$Message/Line.scale.x = 0.0
	$Message/Line2.scale.x = 0.0
	$Mission/Line2.scale.x = 0.0
	$Mission/Line2.scale.x = 0.0
	$Mission/Line2.scale.x = 0.0
	
	label_settings = LabelSettings.new()
	label_settings.font = LABEL_FONT
	label_settings.font_size = 32
	
	_show_intro()


func _show_intro() -> void:
	var tween : Tween = create_tween()
	
	$Intro.modulate.a = 1.0
	$Intro/Text1.modulate.a = 0.0
	$Intro/Text2.modulate.a = 0.0
	tween.tween_property($Intro/Text1, "modulate:a", 1.0, 1.32).from(0.0).set_ease(Tween.EASE_IN)
	tween.tween_interval(1.32)
	tween.tween_property($Intro/Text2, "modulate:a", 1.0, 1.32).from(0.0).set_ease(Tween.EASE_IN)
	tween.tween_interval(1.32)
	tween.tween_property($Intro, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	
	await tween.finished
	intro_finished.emit()


func _show_outro() -> void:
	var tween : Tween = create_tween()
	
	$Outro.modulate.a = 1.0
	$Outro/Text1.modulate.a = 0.0
	$Outro/Text2.modulate.a = 0.0
	$Outro/Text3.modulate.a = 0.0
	$Outro/Text4.modulate.a = 0.0
	tween.tween_property($Intro/Text1, "modulate:a", 1.0, 1.32).from(0.0).set_ease(Tween.EASE_IN)
	tween.tween_interval(1.32)
	tween.tween_property($Intro/Text2, "modulate:a", 1.0, 1.32).from(0.0).set_ease(Tween.EASE_IN)
	tween.tween_interval(1.32)
	tween.tween_property($Intro/Text3, "modulate:a", 1.0, 1.32).from(0.0).set_ease(Tween.EASE_IN)
	tween.tween_interval(1.32)
	tween.tween_property($Intro/Text4, "modulate:a", 1.0, 1.32).from(0.0).set_ease(Tween.EASE_IN)
	tween.tween_interval(1.32)
	tween.tween_property($Intro/Text1, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property($Intro/Text2, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property($Intro/Text3, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property($Intro/Text4, "modulate:a", 0.0, 0.5)
	
	await tween.finished
	outro_finished.emit()


func _init_message() -> void:
	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property($Message, "modulate:a", 1.0, 0.5).from(0.0)
	tween.tween_property($Message/Back, "scale:x", 1.0, 0.5).from(0.0)
	tween.tween_property($Message/Line, "scale:x", 1.0, 0.5).from(0.0)
	tween.tween_property($Message/Line2, "scale:x", 1.0, 0.5).from(0.0)
	
	tween.tween_property($Mission, "modulate:a", 1.0, 0.5).from(0.0)
	tween.tween_property($Mission/Back, "scale:x", 1.0, 0.5).from(0.0)
	tween.tween_property($Mission/Line, "scale:x", 1.0, 0.5).from(0.0)
	tween.tween_property($Mission/Line2, "scale:x", 1.0, 0.5).from(0.0)


func _reset_message() -> void:
	var tween : Tween = create_tween().set_parallel(true)
	
	for i : int in range(1,3):
		for node : Node in get_node("Message/TextBox" + str(i)).get_children():
			tween.tween_property(node, "modulate:a", 0.0, 0.25).from(1.0).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(0.3).timeout
	for i : int in range(1,3):
		for node : Node in get_node("Message/TextBox" + str(i)).get_children():
			node.queue_free()
	
	message_resetted.emit()


func _highlight_mission(text : String, red : bool = false) -> void:
	var line : Label = get_node("Mission/Text")
	line.text = text
	
	if red : 
		create_tween().tween_property(line, "modulate", Color.WHITE, 0.5).from(Color.RED)
		#Data.menu._sound("cancel")
	else : 
		create_tween().tween_property(line, "modulate", Color.WHITE, 0.5).from(Color("00ffa5"))
		#Data.menu._sound("confirm4")


func _update_mission_text(text : String, speed : float = 0.5) -> void:
	var line : Label = get_node("Mission/Text")
	line.text = text
	create_tween().tween_property(line, "modulate:a", 1.0, speed).from(0.0)


func _close_mission() -> void:
	create_tween().tween_property(get_node("Mission/Text"), "modulate:a", 0.0, 0.5).from(1.0)


func _add_text_to_line(index : int, text : String) -> Label:
	var line : HBoxContainer = get_node("Message/TextBox" + str(index))
	var label : Label = Label.new()
	
	label.text = " " + tr(text)
	label.label_settings = label_settings
	
	line.add_child(label)
	create_tween().tween_property(label, "modulate:a", 1.0, 0.25).from(0.0).set_ease(Tween.EASE_IN)
	return label


func _add_button_icon_to_line(index : int, button_name : String) -> void:
	var line : HBoxContainer = get_node("Message/TextBox" + str(index))
	var icon : TextureRect = Menu._create_button_icon(button_name, BUTTON_ICON_SIZE)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.custom_minimum_size = BUTTON_ICON_SIZE
	line.add_child(icon)
	
	create_tween().tween_property(icon, "modulate:a", 1.0, 0.25).from(0.0).set_ease(Tween.EASE_IN)
