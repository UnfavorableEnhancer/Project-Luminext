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


extends ScrollContainer

#-----------------------------------------------------------------------
# Piece queue script
# 
# Contains queued pieces and generates new ones
#-----------------------------------------------------------------------

signal piece_swap # Emitted when piece swap occurs

const QUEUE_SPEED : float = 0.15 # How fast queue moves pieces in seconds

var queue : Array = [] # Array of pieces in queue
@onready var queue_node : Control = $Queue

var before_special_left : int = 999 # How many piece's left before new special block spawn

var is_shifting : bool = false # Is queue currently moving pieces or not


func _ready() -> void:
	Data.profile.settings_changed.connect(_sync_settings)


func _sync_settings() -> void:
	before_special_left = Data.profile.config["gameplay"]["special_block_delay"] 


# Clears queue and fills it with new pieces
func _reset() -> void:
	_sync_settings()

	queue.clear()
	for piece : PieceData in queue_node.get_children(): piece.queue_free()
	for i : int in 4: _append_piece()


# Returns last piece in queue, and moves all pieces up
func _get_piece() -> PieceData:
	if queue.size() != 4: _append_piece()
	
	var come_in_piece : PieceData = queue.pop_front()
	
	before_special_left -= 1

	_remove_end_piece(come_in_piece, QUEUE_SPEED)
	# We return clone piece data, since its gonna be removed soon by previous function
	return _clone_piece(come_in_piece)


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("side_ability") and not Data.game.is_paused:
		Data.game.replay._record_action_press(&"side_ability")
		_shift_queue()
	elif event.is_action_released("side_ability"):
		Data.game.replay._record_action_release(&"side_ability")


# Shifts queue and replaces current piece in hand
func _shift_queue() -> void:
	if not Data.profile.config["gameplay"]["piece_swaping"]: return

	if not is_shifting:
		var game_piece : Piece = Data.game.piece
		if game_piece == null or game_piece.is_droping: return
		
		Data.profile.progress["stats"]["total_piece_swaps"] += 1
		piece_swap.emit()
		
		var clone_piece : PieceData = PieceData.new()
		for block_pos : Vector2i in game_piece.blocks:
			clone_piece.blocks[block_pos] = [game_piece.blocks[block_pos].color, game_piece.blocks[block_pos].special]
		_append_piece(clone_piece)
		
		Data.game._add_sound(&"queue_shift", Vector2(200,300),false,false)
		
		var come_in_piece : PieceData = queue.pop_front()
		Data.game._replace_current_piece(_clone_piece(come_in_piece))
		_remove_end_piece(come_in_piece, QUEUE_SPEED)


# Moves all pieces up and removes last piece
func _remove_end_piece(piece_data : PieceData, delay : float) -> void:
	is_shifting = true

	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property(piece_data, 'position:y', -90.0, QUEUE_SPEED)
	# Move all pieces up
	for piece_pos : int in queue.size():
		tween.tween_property(queue[piece_pos], 'position:y', float(74 + piece_pos * 164), QUEUE_SPEED)
	
	await get_tree().create_timer(delay).timeout
	piece_data.queue_free()

	is_shifting = false


# Returns clone of passed piece data. Needed if passed piece data is going to be deleted, but we still need it
func _clone_piece(piece : PieceData) -> PieceData:
	var clone_piece : PieceData = PieceData.new()
	clone_piece.blocks = piece.blocks
	
	return clone_piece


# Adds piece to the bottom of the queue
# If "piece_data" is passed, data from this piece would be used instead of random generated one
func _append_piece(piece_data : PieceData = null) -> void:
	if piece_data == null:
		piece_data = PieceData.new()
		
		var do_special : bool = before_special_left <= 0
		piece_data._generate(do_special)
		if do_special: before_special_left = Data.profile.config["gameplay"]["special_block_delay"] 
	
	piece_data.position = Vector2(72, 74 + queue.size() * 164)
	queue.append(piece_data)
	queue_node.add_child(piece_data)
	piece_data._render()

	

	
