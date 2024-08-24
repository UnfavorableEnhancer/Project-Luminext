@tool
extends MenuSelectableButton

@export var foreground_screen_name : String = "foreground" # Foreground screen name used to transfer data into

@export var glow_color : Color

@export var button_layout : int = 0 # Button layout which user can use now


func _ready():
	# Assign translated "Button" class "text" variable, to the "Label" node text
	$Label.text = tr(text)
	$Icon.texture = icon


func _process(delta):
	$Icon.texture = icon


func _select():
	super._select()
	
	var foreground_screen = Data.menu.screens[foreground_screen_name]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(button_layout)
	
	modulate = glow_color


func _deselect():
	super._deselect()
	
	modulate = Color.WHITE
