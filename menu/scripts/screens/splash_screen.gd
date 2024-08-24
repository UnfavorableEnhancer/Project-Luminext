extends MenuScreen

var is_exiting : bool = true

func _ready() -> void:
	Data.menu.screens["foreground"].visible = false
	
	Data.input_method_changed.connect(_label)
	_label()
	
	await get_tree().create_timer(2.0).timeout
	#$GlassAnim.play("start")
	$LogoAnim.play("start")
	$StarAnim.play("start")
	is_exiting = false


func _label() -> void:
	if Data.current_input_mode == Data.INPUT_MODE.GAMEPAD: $ENTER.text = tr("PRESS START TO ENTER THE GAME")
	else: $ENTER.text = tr("PRESS ENTER TO START THE GAME")


func _input(event : InputEvent) -> void:
	# Press "start" button to proceed to menu screen
	if not is_exiting:
		if event.is_action_pressed("ui_enter"):
			is_exiting = true 
			
			Data.menu._sound("enter")
			
			if Data.profile.status != OK:
				Data.menu._change_screen("login")
			else:
				Data.menu._change_screen("main_menu")
			
			#create_tween().tween_property(Data.main.black,"color",Color(0,0,0,1),1.0)
	
	# Exit the game
	if event.is_action_pressed("ui_exit"):
		Data.main._exit()


func _catch_phrase() -> void:
	var catch : Array[String] = [
	"Life is music",
	"Stack the music",
	"yet another Lumines clone...",
	"hey! you read this message", 
	"welcome to the club",
	"puzzle excellence",
	"luminext system",
	"Lumines love letter", 
	"bean edition", 
	"have a nice day!", 
	"aka. tetris with great music, funky visuals and weird rules", 
	"thank you PSP",
	"Square dance", 
	"thank you for participating",
	"this feature is inspired by minecraft splash texts", 
	"ROCK IS DEAD", 
	"i love hearing the music in my soul", 
	"powered by Godot Engine 4.2.1",
	"Lunyaes was first", 
	"Block challenge", 
	"Puzzle X Music", 
	"Puzzle Fusion", 
	"insert funny splash text here", 
	"this game will xplode your computer!",  
	"ogv sux", 
	"cloning Lumines...", 
	"fan made spiritual successor remake remastered revision edition",  
	"An advanced Lumines clone",
	"Try out Lumines Remastered™ too next time!",
	"pizza time"]
	
	$Info/EDITION.text = catch.pick_random()
