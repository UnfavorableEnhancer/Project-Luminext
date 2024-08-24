@tool
extends MenuSelectableButton

enum MENU_BUTTON_LAYOUT{
	EMPTY,
	UP_DOWN_SELECT,
	SELECT,
	CHANGE_INPUT,
	SKIN_SELECT,
	PLAYLIST_SELECT,
	SLIDER,
	MAIN_MENU
}

var main_color : Color

@export var desc_node_path : NodePath
@export var label_node_path : NodePath
@export var label_color : Color

@export var description : String = "" # Description shown on button select
@export var button_layout : MENU_BUTTON_LAYOUT = MENU_BUTTON_LAYOUT.UP_DOWN_SELECT # Button layout which user can use now


func _ready() -> void:
	super()
	
	main_color = modulate
	selected.connect(_selected)
	$Icon.texture = icon


func _process(_delta : float) -> void:
	$Icon.texture = icon
	$Back.color = label_color


func _selected() -> void:
	Data.menu._sound("select")

	var foreground_screen : MenuScreen = Data.menu.screens["foreground"]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(button_layout)
	
	var tween : Tween = create_tween()
	tween.tween_property($Back,"scale",Vector2(1.0,1.5),0.1)
	tween.parallel().tween_property($Back/Glow,"modulate:a",0.0,0.2).from(1.0)
	tween.parallel().tween_property($Icon,"position:y",72,0.1)
	
	get_node(desc_node_path).text = tr(description)

	get_node(label_node_path).get_node("Text").text = tr(text)
	get_node(label_node_path).modulate = label_color


func _deselected() -> void:
	var tween : Tween = create_tween()
	tween.tween_property($Back,"scale",Vector2(1.0,1.0),0.1)
	tween.parallel().tween_property($Icon,"position:y",24,0.1)
