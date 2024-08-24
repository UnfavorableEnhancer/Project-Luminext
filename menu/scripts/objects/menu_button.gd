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

@export_multiline var description : String = "" # Description shown on button select
@export var button_layout : MENU_BUTTON_LAYOUT = MENU_BUTTON_LAYOUT.UP_DOWN_SELECT # Button layout which user can use now
@export var button_color : Color


func _ready() -> void:
	super()
	
	if disabled:
		button_color = Color.GRAY
	
	selected.connect(_selected)
	deselected.connect(_deselected)
	
	$Label.text = tr(text)
	$Info.text = tr(description)
	$Icon.texture = icon


func _process(_delta : float) -> void:
	$Label.text = text
	$Icon.texture = icon
	$Back.color = button_color


func _work(silent : bool = false) -> void:
	if Data.menu.is_locked or Data.menu.current_screen_name != parent_screen.snake_case_name: 
		return
	
	create_tween().parallel().tween_property($Back/Glow,"modulate:a",0.0,0.5).from(1.0)
	if not silent and press_sound_name.begins_with("announce") : Data.menu._sound("confirm")
	
	super(silent)


func _selected() -> void:
	Data.menu._sound("select")

	var foreground_screen : MenuScreen = Data.menu.screens["foreground"]
	if is_instance_valid(foreground_screen):
		foreground_screen._show_button_layout(button_layout)
	
	var tween : Tween = create_tween()
	tween.tween_property($Back,"scale:y",1.0,0.1).from(0.5)
	tween.parallel().tween_property($Icon,"scale",Vector2(2.8,2.8),0.1)
	tween.parallel().tween_property($Back/Glow,"modulate:a",0.0,0.2).from(0.5)
	
	$Info.modulate.a = 1.0
	custom_minimum_size.y = 128


func _deselected() -> void:
	var tween : Tween = create_tween()
	tween.tween_property($Back,"scale:y",1.0,0.1).from(1.25)
	tween.parallel().tween_property($Icon,"scale",Vector2(1.0,1.0),0.1)
	
	$Info.modulate.a = 0.0
	custom_minimum_size.y = 56
