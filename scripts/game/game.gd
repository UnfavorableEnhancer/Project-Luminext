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


extends Node2D

#-----------------------------------------------------------------------
# Game logic script
# 
# Main script which initiates and controls 'Lumines-like' gameplay
# Does game state control, block management, square checking, score manipulation, SFX and FX playback work.
#-----------------------------------------------------------------------


signal reset # Emitted when game resets
signal paused(on : bool) # Emitted when game pause is triggered
signal game_over # Emitted when game is over

signal skin_change_started # Emitted when skin change starts
signal skin_change_ended # Emitted when skin change completed

signal new_piece_is_given # Emmited when player gets new piece
signal timeline_started # Emmited when timeline starts

enum SKIN_CHANGE_STATUS {FAILED, NOT_NEEDED, GAME_OVER, SUCCESS}

const TIMELINE_SCENE : PackedScene = preload("res://scenery/game/timeline.tscn")
const SKIN_SCENE : PackedScene = preload("res://scenery/game/skin.tscn")

var is_paused : bool = false
var is_game_over : bool = false
var is_changing_skins_now : bool = false

var is_piece_noclip_mode : bool = false # When active current piece ignores collisions with other blocks, it only collides with floor
var is_paint_mode : bool = false # When active user can draw blocks on field with mouse
var is_manual_timeline : bool = false # When active stops timeline creation when skin music sample ends
var is_adding_pieces_to_queue : bool = true # When active game generates new piece and appends it to queue each time queue size is less than 3

 # What inputs are locked for current piece
var input_lock : Dictionary = {
	&"move_left" : false,
	&"move_right" : false,
	&"rotate_left" : false,
	&"rotate_right" : false,
	&"quick_drop" : false,
	&"side_ability" : false
}

var all_blocks : Dictionary = {} # All blocks on the game field | [position : Vector2i] = Block
var blocks : Dictionary = {} # All blocks on the game field | [position : Vector2i] = Block
var delete : Dictionary = {} # Ready to be deleted by timeline blocks | [position : Vector2i] = Block
var squares : Dictionary = {} # All squares on the game field | [position : Vector2i] = FX
var ghosts : Array = [] # All ghosts on the game field

var gamemode : Gamemode = null # Current gamemode, which defines game rules
var skin : Node2D = null # Currently loaded skin instance
var timeline : Node2D = null # Current timeline instance, does blocks clearing work

var skin_change_status : int = 0 # Shows status of skin replacement procedure

var created_squares : Array[Vector2i] = []
var square_group : Array[Square] = []
var is_adding_square_number : bool = false

var sound_queue : Array = [] # Queued sounds, to be played in sync with music beat

var piece : Piece = null # Current piece reference
var piece_fall_speed : float = 1.0 # Piece falling speed in seconds
var piece_fall_delay : float = 1.0 # Piece fall start delay in seconds

var rng : RandomNumberGenerator = RandomNumberGenerator.new()

@onready var replay : Replay = $Replay
var is_playing_replay : bool = false

var menu_screen_to_return : String = "main_menu" # Menu screen name to which game will try to return when its ends
var pause_screen_name : String = "playlist_mode_pause" # Menu screen name which would be created on game pause
var game_over_screen_name : String = "playlist_mode_gameover" # Menu screen name which would be created on game over

var custom_var : Dictionary = {} # Custom variables which might be used by mods

@onready var foreground : Node2D = $Foreground # Foreground is used to display UI (score, time, combo, etc.)
@onready var gameplay : Node2D = $Gameplay # Gameplay is where all gameplay things takes place
@onready var field : Node2D = $Gameplay/Field # Field is the place where all placed blocks exists
@onready var effects : Node2D = $Gameplay/Effects # Effects is the place where all FX objects exists
@onready var piece_queue : ScrollContainer = $Gameplay/PieceQueue # Stack is where all pieces life until getting into player's hand
@onready var sounds : Node2D = $Sounds # Node for spawning all sounds
@onready var pause_background : ColorRect = $PauseBack # ColorRect which covers whole game when its paused


func ___GAME_STATE___() -> void: return


func _ready() -> void:
	# These special FX use GPUParticles, which make stutter on first spawn, so we spawn them before game starts to cache them
	_add_fx("blast", Vector2(0,0), "rsquare")
	_add_fx("square", Vector2(0,0), "rsquare")

	Data.console.opened.connect(_pause.bind(true,false,false))
	Data.console.closed.connect(_pause.bind(false,false,false))


# Resets game back to initial state and starts it again
func _reset() -> void:
	reset.emit()
	replay._reset_replay()
	gamemode._prereset()

	is_game_over = true
	is_paused = true
	skin._pause(true)
	
	gameplay.process_mode = Node.PROCESS_MODE_INHERIT
	foreground.process_mode = Node.PROCESS_MODE_INHERIT
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	blocks.clear()
	squares.clear()
	delete.clear()
	
	timeline = null
	
	for effect : FX in effects.get_children(): effect.queue_free()
	for object : Node2D in field.get_children(): object.queue_free()
	
	if is_playing_replay:
		is_manual_timeline = true
		for i : StringName in input_lock.keys() : input_lock[i] = true

	gamemode._reset()
	await gamemode.reset_complete
	print("RESETTTED")

	piece = null
	piece_queue._reset()
	_give_new_piece()

	if is_playing_replay: 
		replay._start_playback()
		_create_timeline()
	else: 
		replay._start_recording()
	
	is_game_over = false
	skin._start()
	_pause(false)


# Removes the game and makes return to specified main menu screen
func _end() -> void:
	gamemode._end()

	# Blackout animation
	create_tween().tween_property(Data.main.black,"color",Color(0,0,0,1),1.0)
	await get_tree().create_timer(1.0).timeout
	
	# Called when we are in skin editor playtest mode
	if menu_screen_to_return == "skin_editor":
		Data.menu._add_screen("background")
		Data.menu._add_screen("foreground")
		Data.menu.screens[menu_screen_to_return]._end_playtest_skn()
		queue_free()
		return
	
	Data.menu._return_from_game(menu_screen_to_return)
	queue_free()


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("pause") : 
		if not is_paused: _pause(true)


# Ends game and starts game over sequence
func _game_over() -> void:
	if is_playing_replay :  replay._stop_playback()
	else : replay._stop_recording()

	is_game_over = true
	_pause(true,false,false)

	while not sound_queue.is_empty() : sound_queue.pop_back().free()

	Data.menu._add_screen("foreground")
	Data.menu._add_screen(game_over_screen_name)
	
	timeline = null
	
	game_over.emit()
	gamemode._game_over()


# This function toggles pause state
func _pause(on : bool = true, wait_for_screen_end : bool = false, add_pause_screen : bool = true) -> void:
	if wait_for_screen_end : await Data.menu.all_screens_removed
	paused.emit(on)
	
	if on:
		replay._pause(on)

		is_paused = true
		gameplay.process_mode = Node.PROCESS_MODE_DISABLED
		foreground.process_mode = Node.PROCESS_MODE_DISABLED

		if timeline != null : timeline._pause(true)
		skin._pause(true)
		gamemode._pause(true)
		
		$Announce.paused = true

		create_tween().tween_property(pause_background, "modulate", Color(0,0,0,0.5), 1.0).from(Color(0.2,0.2,0.2,0))

		if add_pause_screen:
			Data.menu._add_screen("foreground")
			Data.menu._add_screen(pause_screen_name)
			Data.menu._sound("confirm4")
	else:
		is_paused = false
		gameplay.process_mode = Node.PROCESS_MODE_INHERIT
		foreground.process_mode = Node.PROCESS_MODE_INHERIT
		
		if timeline != null : timeline._pause(false)
		skin._pause(false)
		gamemode._pause(false)
		
		$Announce.paused = false
		replay._pause(on)

		create_tween().tween_property(pause_background, "modulate", Color(0,0,0,0), 1.0).from(Color(0.2,0.2,0.2,0.5))


# Restarts game
func _retry() -> void:
	# Black-in animation
	create_tween().tween_property(Data.main.black,"color:a",1.0,1.0).from(0.0)
	await get_tree().create_timer(1.0).timeout

	gamemode._retry()
	# Gamemode might do some long actions, like loading another skin, so we wait for its signal
	await gamemode.retry_complete

	if gamemode.retry_status != OK : 
		_game_over()
		return

	await get_tree().create_timer(0.25).timeout
	_reset()
	
	# Black-out animation
	create_tween().tween_property(Data.main.black,"color",Color(0,0,0,0),0.5)


# Loads new skin defined by "path" and replaces current one with it
# If "quick" is true, skips skin transition animation and loads new skin immidiately
func _change_skin(skin_path : String = "", quick : bool = false) -> void:
	if is_changing_skins_now : return
	if skin_path == "": return

	# XOR cache variable, so important data won't be overwritten by new one and break things
	Data.use_second_cache = !Data.use_second_cache

	print("SKIN CHANGE STARTED. SKIN PATH : ", skin_path)
	is_changing_skins_now = true 
	skin_change_started.emit()
	
	var skin_data : SkinData = SkinData.new()

	var load_thread : Thread = Thread.new()
	var err : int = load_thread.start(skin_data._load_from_path.bind(skin_path))
	if err != OK:
		print("SKIN LOAD THREAD ERROR : ", error_string(err))
		print("SKIN CHANGE FAILED!")
		is_changing_skins_now = false
		
		skin_change_status = SKIN_CHANGE_STATUS.FAILED
		skin_change_ended.emit()
		return
	
	await skin_data.skin_loaded
	await get_tree().create_timer(0.01).timeout
	var result : int = load_thread.wait_to_finish()
	
	if result != OK:
		print("SKIN CHANGE FAILED!")
		is_changing_skins_now = false
		
		skin_change_status = SKIN_CHANGE_STATUS.FAILED
		skin_change_ended.emit()
		return
	
	if quick:
		print("SKIN CHANGE SUCCESS!")
		is_changing_skins_now = false
		skin_change_status = SKIN_CHANGE_STATUS.SUCCESS
		skin.sample_ended.disconnect(_start_timeline)
		_replace_skin(skin_data, true)
		skin_change_ended.emit()
		return

	await skin.sample_ended
	skin._play_ending()

	# Turn music volume down
	if skin.music_player != null:
		create_tween().tween_property(skin.music_player, "volume_db", -40.0, 60.0 / skin.bpm * 8.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)

	# New skin announce starts after half of the sample passed, and uses Timer node, so we can pause the game while doing transition 
	$Announce.start(60.0 / skin.bpm * 6.0)
	await $Announce.timeout
	_play_announce(skin_data)
	
	# Disconnect timeline so it won't spawn twice when new skin appear
	skin.sample_ended.disconnect(_start_timeline)

	await skin.sample_ended

	_replace_skin(skin_data)
	# Raise music volume up
	if skin.music_player != null:
		create_tween().tween_property(skin.music_player, "volume_db", 0.0, 60.0 / skin.bpm * 8.0).from(-40.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	
	is_changing_skins_now = false
	skin_change_status = SKIN_CHANGE_STATUS.SUCCESS
	skin_change_ended.emit()
	print("SKIN CHANGE SUCCESS!")


# Replaces current skin with new one defined by passed SkinData
# If "quick" is true, skips skin transition animation and starts new skin immidiately
func _replace_skin(skin_data : SkinData, quick : bool = false) -> void:
	skin.half_beat.disconnect(_add_sounds_from_queue)
	
	var replace_anim_time : float = 60.0 / skin.bpm * 6.0

	if quick: skin.queue_free()
	else: skin._end(replace_anim_time)
	
	_add_skin(skin_data)

	get_tree().call_group("blocks","_refresh_render")
	get_tree().call_group("squares","_refresh_render")

	if quick:
		foreground._change_style(skin_data.textures["ui_design"], skin.skin_data, 0.0)
	else:
		foreground._change_style(skin_data.textures["ui_design"], skin.skin_data, replace_anim_time)
		create_tween().tween_property(skin, "modulate:a", 1.0, replace_anim_time).from(0.0)
		skin._start()


# Creates skin instance from passed SkinData and connects it to the game
func _add_skin(skin_data : SkinData) -> void:
	var new_skin : Node2D = SKIN_SCENE.instantiate()
	new_skin.skin_data = skin_data
	skin = new_skin
	
	skin.half_beat.connect(_add_sounds_from_queue)
	skin.sample_ended.connect(_start_timeline)
	
	add_child(new_skin)


#================================================================================================
#================================================================================================

func ___BLOCKS_MANAGEMENT___() -> void: return


# Give piece from queue to the player's hand
func _give_new_piece(piece_start_pos : Vector2i = Vector2i(8,-1), piece_data : PieceData = null, has_waited_for_new_piece : bool = false) -> void:
	if piece != null : 
		piece._end()
		piece = null
	if piece_data == null:
		if has_waited_for_new_piece:
			piece_queue.piece_appended.disconnect(_give_new_piece.bind(piece_start_pos,null,true))
		if piece_queue.queue.size() < 1:
			# Wait for new piece to come into queue
			piece_queue.piece_appended.connect(_give_new_piece.bind(piece_start_pos,null,true))
			return
		
		piece_data = piece_queue._get_piece()
	
	piece = Piece.new()
	piece.grid_position = piece_start_pos
	piece.fall_delay = piece_fall_delay
	piece.fall_speed = piece_fall_speed
	piece.blocks = piece_data.blocks

	if Data.profile.config["video"]["background_shaking"] and not skin.skin_data.metadata.settings["no_shaking"]:
		piece.piece_moved.connect(skin._shake_background)
		piece.piece_quick_drop.connect(skin._shake_background)
	
	piece.position = Vector2(piece_start_pos.x * 68, piece_start_pos.y * 68 - 2)
	new_piece_is_given.emit()
	piece.replay = replay
	piece.emulated_inputs = replay.emulated_inputs
	field.add_child(piece)
	replay.piece = piece
	
	piece_data.free()


# Replaces current piece in hand data with new one
func _replace_current_piece(piece_data : PieceData) -> void:
	if not is_instance_valid(piece): return
	var tween : Tween = create_tween().set_parallel(true)

	for block_pos : Vector2i in piece.blocks.keys():
		var block : BlockBase = piece.blocks[block_pos]
		block.color = piece_data.blocks[block_pos][0]
		block.special = piece_data.blocks[block_pos][1]
		block._render()
		tween.tween_property(block,"modulate",Color(1,1,1,1),0.25).from(Color(0,0,0,0))


# Adds block to the game field
func _add_block(to_position : Vector2i, color : int, special : StringName, smooth : bool = false) -> void:
	if to_position.y < 0 or to_position.y > 9: return
	var block : Block = null
	
	match special:
		&"chain" : block = Chain.new()
		&"merge" : block = Merge.new()
		&"laser" : block = Laser.new()
		&"wipe" : block = Wipe.new()
		&"joker" : block = Joker.new()
	
	if block == null:
		if color == Block.BLOCK_COLOR.GARBAGE: block = Garbage.new()
		elif color == Block.BLOCK_COLOR.NULL: return
		else: block = Block.new()
	
	block.grid_position = to_position
	block.color = color
	block.special = special
	
	field.add_child(block)
	block._render()

	if smooth: create_tween().tween_property(block, "modulate", Color(1,1,1,1), 0.25).from(Color(0,0,0,0))


func _add_ghost(to_position : Vector2i, color : int, special : StringName, smooth : bool = false) -> void:
	if to_position.y < 0 or to_position.y > 9: return
	
	if special == &"square":
		var ghost_square : ColorRect = ColorRect.new()

		match color:
			BlockBase.BLOCK_COLOR.RED : ghost_square.color = skin.skin_data.textures["red_fx"]
			BlockBase.BLOCK_COLOR.WHITE : ghost_square.color = skin.skin_data.textures["red_fx"]
			BlockBase.BLOCK_COLOR.GREEN : ghost_square.color = skin.skin_data.textures["red_fx"]
			BlockBase.BLOCK_COLOR.PURPLE : ghost_square.color = skin.skin_data.textures["red_fx"]
			BlockBase.BLOCK_COLOR.MULTI : ghost_square.color = skin.skin_data.textures["red_fx"]
		
		ghost_square.color.a = 0.5
		ghost_square.position = Vector2(to_position.x * 68 - 34, to_position.y * 68 + 32) 
		ghosts.append(ghost_square)

		if smooth:
			create_tween().tween_property(ghost_square, "modulate", Color(1,1,1,0.5), 0.25).from(Color(0,0,0,0))
	else:
		var ghost_block : BlockBase = BlockBase.new()
			
		ghost_block.position = Vector2(to_position.x * 68 - 34, to_position.y * 68 + 32) 
		ghost_block.color = color
		ghost_block.special = special
		ghost_block.is_ghost = true
		
		field.add_child(ghost_block)
		ghosts.append(ghost_block)
		ghost_block._render()

		if smooth:
			create_tween().tween_property(ghost_block, "modulate", Color(1,1,1,0.5), 0.25).from(Color(0,0,0,0))


func _clear_ghosts() -> void:
	for i : int in ghosts.size():
		ghosts.pop_back().queue_free()


# Turns on all placed blocks gravity
func _move_blocks(delay : float = 0.0) -> void:
	await get_tree().create_timer(delay, true, true).timeout
	# Call blocks from down-right corner, and go up-left, so they would fall in right order and won't clip thru each other
	for x : int in range(16,0,-1):
		for y : int in range(9,-1,-1):
			var block : Block = blocks.get(Vector2i(x,y), null)
			if block != null: block._fall()


# Removes all placed blocks from the field
func _clear_field() -> void:
	for block : Variant in blocks.values():
		if not is_instance_valid(block) : continue
		block._free()
	for square : Variant in squares.values():
		if not is_instance_valid(square) : continue
		square.queue_free()

	delete.clear()
	squares.clear()


#================================================================================================

func ___GAME_LOGIC___() -> void: return


func _tick() -> void:
	if is_paused : return

	if piece : piece._physics()
	
	for x : int in range(16,0,-1):
		for y : int in range(9,-1,-1):
			var block : Variant = all_blocks.get(Vector2i(x,y), null)
			if block != null : block._physics()
	
	if timeline : timeline._physics()


func _physics_process(delta: float) -> void:
	if is_paused : return
	
	if replay.is_recording : replay.current_tick += 1
	if replay.is_playback : replay.advance(delta)

	if piece : piece._physics()
	
	for x : int in range(16,0,-1):
		for y : int in range(9,-1,-1):
			var block : Variant = all_blocks.get(Vector2i(x,y), null)
			if block != null : block._physics()
	
	if timeline : timeline._physics()


# Scans area for possible squares and creates them
func _square_check(area : Rect2i) -> void:
	for x : int in range(area.position.x,area.position.y):
		var has_square_on_row : bool = false
		for y : int in range(area.size.x,area.size.y):
			var squared_blocks : Array = _check_square_possible(Vector2i(x,y))
			
			if squared_blocks.is_empty() : continue
			has_square_on_row = true

			if _create_square(Vector2i(x,y), squared_blocks): created_squares.append(Vector2i(x,y))
		
		if not created_squares.is_empty() and not has_square_on_row and not is_adding_square_number:
			is_adding_square_number = true
			await get_tree().create_timer(0.025,true,true).timeout
			_add_square_numbers()


# Checks is square possible at game field position
func _check_square_possible(in_position : Vector2i) -> Array:
	var block : Variant = blocks.get(in_position,null)
	
	if block == null: 
		blocks.erase(in_position)
		return []
	if block.is_falling : return []
	
	var squared_blocks : Array = [block]
	var color : int = block.color
	
	# If block color is dark, garbage or null
	if color > 4 : return []
	
	var adjacent_blocks_pos : Array[Vector2i] = [in_position + Vector2i(1,0), in_position + Vector2i(0,1), in_position + Vector2i(1,1)]
	for pos : Vector2i in adjacent_blocks_pos:
		var next_block : Block = blocks.get(pos,null)
		
		if next_block == null : return []
		if next_block.is_falling : return []
		
		var next_color : int = next_block.color
		if next_color > 4: return []
		
		if color == BlockBase.BLOCK_COLOR.MULTI:
			color = next_color
			squared_blocks.append(next_block)
			continue
		
		if next_color == BlockBase.BLOCK_COLOR.MULTI:
			squared_blocks.append(next_block)
			continue
		
		if next_color != color: return []

		squared_blocks.append(next_block)
	
	squared_blocks.append(color)
	return squared_blocks


# Removes square at game field position safely
func _remove_square(in_position : Vector2i) -> void:
	if squares.has(in_position):
		squares[in_position]._remove()


# Checks every sqaure in "created_sqaures", builds their groups and adds respective group sizes number animation
func _add_square_numbers() -> void:
	while not created_squares.is_empty():
		var square_pos : Vector2i = created_squares.pop_front()
		if not squares.has(square_pos) : continue

		square_group.clear()
		var origin_square : Square = squares[square_pos]

		_get_square_group(origin_square,created_squares)
		
		_add_sound("square", Vector2(square_pos.x*48+300,square_pos.y*48+200), false, false)
		_add_fx("num", square_pos, square_group.size())

	is_adding_square_number = false

		
# Scan all chained squares from origin sqaure and store result sqaure group in "square_group" variable
# Also clean-ups "squares_to_check" array leaving only single squares instances from each group
func _get_square_group(origin_square : Square, squares_to_check : Array) -> void:
	square_group.append(origin_square)

	for adj_square : Square in origin_square.adjacent_squares.values():
		if not adj_square in square_group:
			if adj_square.grid_position in squares_to_check:
				squares_to_check.erase(adj_square.grid_position)

			_get_square_group(adj_square,squares_to_check)


# Scans all squares from "created_sqaures" array and builds their respective square groups, which are packed into single array and returned
func _get_all_sqaure_groups(squares_to_check : Array) -> Array:
	var sqaure_groups : Array = []

	while not squares_to_check.is_empty():
		var square_pos : Vector2i = squares_to_check.pop_front()
		if not squares.has(square_pos) : continue

		square_group.clear()
		var origin_square : Square = squares[square_pos]

		_get_square_group(origin_square,squares_to_check)
		sqaure_groups.append(square_group.duplicate(true))

	return sqaure_groups


# Creates square at game field position
# "squared_blocks" Array must contain 4 Blocks references and blocks color
func _create_square(in_position : Vector2i, squared_blocks : Array) -> bool:
	if squares.has(in_position) : return false
	
	var color : int = squared_blocks[4]
	var square : FX = _add_fx("square", in_position, color)
	
	square.grid_position = in_position
	squares[in_position] = square
	square._check_adjacent()
	
	# Remove blocks color string from array
	squared_blocks.pop_back()
	
	for block : Block in squared_blocks:
		block._square(square)
	
	return true


func _start_timeline() -> void:
	if not is_manual_timeline:
		_create_timeline()


# This function starts new timeline from begining, and removes current one
func _create_timeline() -> void:
	replay._record_timeline_start()
	if timeline != null : timeline._end()
	
	if is_game_over: return
	
	timeline = TIMELINE_SCENE.instantiate()
	
	timeline.squares_deleted.connect(func(_pass : int) -> void : skin.is_music_looping = false)
	game_over.connect(timeline.queue_free)
	reset.connect(timeline.queue_free)
	skin.beat.connect(timeline._beat)
	timeline.get_node("Color").modulate = skin.skin_data.textures["timeline_color"]
	
	gameplay.add_child(timeline)
	if is_paused : timeline._pause(true)
	timeline_started.emit()


#================================================================================================

func ___MISCELLANEOUS___() -> void: return


# Plays next skin announce sound
func _play_announce(skin_data : SkinData) -> void:
	if Data.profile.config["audio"]["announcer"] == Profile.ANNOUNCER_MODE.OFF: return
	
	var announce : AudioStreamPlayer = AudioStreamPlayer.new()
	announce.stream = skin_data.metadata.announce
	announce.finished.connect(announce.queue_free)
	announce.bus = "Announce"
	sounds.add_child(announce)
	announce.play()


# Adds animated effect to the game
func _add_fx(fx_name : StringName, to_position : Vector2, parameter : Variant = null) -> FX:
	var fx_data : Variant = skin.skin_data.fx[fx_name]
	var fx : FX
	
	if fx_data is String: fx = load(fx_data).instantiate()
	else: fx = fx_data.instantiate()
	
	fx.position = to_position
	fx.parameter = parameter
	
	effects.add_child(fx)
	return fx


# This function adds sound from currently loaded skin
func _add_sound(sound_name : StringName, sound_pos : Vector2, _play_once : bool = false, sync_to_beat : bool = true, sound_id : int = -1) -> AudioStreamPlayer2D:
	# TODO : Create better method for finding existing sounds for now this thing is deprecated, since its currently used by literally one sound in game anyway, and it doesn't break much without this function
	#if play_once and $Sounds.has_node(sound_name): 
		#return null
	
	var sounds_dict : Dictionary = skin.skin_data.sounds
	var sample : AudioStream = null

	if sound_id > -1:
		sample = sounds_dict[sound_name][clampi(sound_id,0,sounds_dict[sound_name].size() - 2)]
	else:
		match sound_name:
			&"blast1" : sample = sounds_dict["blast"][0]
			&"blast2" : 
				if sounds_dict["blast"].size() > 2:
					var even_array : Array = sounds_dict["blast"].slice(1,999,2,true)
					if even_array.back() == null: even_array.pop_back()
					if even_array.is_empty() : return null
					
					sample = even_array.pick_random()
				else:
					sample = sounds_dict["blast"][0]

			&"blast3" : 
				if sounds_dict["blast"].size() > 3:
					var uneven_array : Array = sounds_dict["blast"].slice(2,999,2,true)
					if uneven_array.back() == null: uneven_array.pop_back()
					if uneven_array.is_empty() : return null
					
					sample = uneven_array.pick_random()
				else:
					sample = sounds_dict["blast"][0]

			&"square", &"timeline", &"special", &"blast", &"bonus":
				var sounds_array : Array = sounds_dict[sound_name].duplicate(true)
				# Remove last null entry in multi-sounds array
				if sounds_array.back() == null: sounds_array.pop_back()
				if sounds_array.is_empty() : return null
				
				sample = sounds_array.pick_random()
			
			_ : if sounds_dict.has(sound_name) : sample = sounds_dict[sound_name]
	
	if sample == null : return null
	
	var sound : AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	sound.name = sound_name
	sound.stream = sample
	sound.position = sound_pos if Data.profile.config["audio"]["spatial_sound"] else Vector2(960,540)
	sound.bus = "Sound"
	sound.finished.connect(sound.queue_free)
	
	if sync_to_beat: 
		sound_queue.append(sound)
	else:
		sounds.add_child(sound)
		sound.play()
	
	return sound


# This function plays all queued sounds, usually when music beat occurs
func _add_sounds_from_queue() -> void:
	while not sound_queue.is_empty():
		var sound : AudioStreamPlayer2D = sound_queue.pop_back()
		sounds.add_child(sound)
		sound.play()
