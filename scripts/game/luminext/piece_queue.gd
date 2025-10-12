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


extends ScrollContainer

##-----------------------------------------------------------------------
## Contains all pieces in queue and allows to add and take them
##-----------------------------------------------------------------------

class_name PieceQueue

signal piece_swap ## Emitted when piece swap happens
signal piece_appended ## Emitted new piece was appended to queue

const QUEUE_SPEED : float = 0.15 ## How fast queue moves all pieces in seconds

var game : LuminextGame ## Game instance
var ruleset : Ruleset ## Current ruleset instance

var queue : Array = [] ## Array of pieces in queue
var queue_node : Control = null ## Queue node instance

var before_special_left : int = 999 ## How many piece's are left before new special block spawn

var is_adding_pieces_to_queue : bool = true ## If true, generates new piece and appends it to queue each time queue size is less than 3
var is_shifting : bool = false ## Is queue currently moving pieces or not


func _ready() -> void:
	queue_node = Control.new()
	add_child(queue_node)

	ruleset.changed.connect(_sync_settings)
	_sync_settings()


func _sync_settings() -> void:
	before_special_left = ruleset.rules["special_block_delay"] 


## Clears queue and fills it with new pieces if game allows it
func _reset() -> void:
	_sync_settings()
	_clear()

	if is_adding_pieces_to_queue:
		for i : int in 4: _append_piece()


## Removes all pieces from the queue
func _clear() -> void:
	queue.clear()
	for piece : PieceData in queue_node.get_children(): piece.queue_free()


## Returns last piece in queue, and moves all pieces up
func _get_piece() -> PieceData:
	if is_adding_pieces_to_queue:
		if queue.size() != 4: _append_piece()
	
	# We store clone piece data, since its gonna be removed soon by _remove_end_piece function
	var come_in_piece : PieceData = queue.front()._clone()
	_remove_end_piece(QUEUE_SPEED)

	before_special_left -= 1
	return come_in_piece


## Puts passed piece into queue and pulls up and returns top piece
func _swap_piece(piece : PieceData) -> PieceData:
	if is_shifting : return null
	if queue.size() < 1: return null

	_append_piece(piece._clone())
	
	var come_in_piece : PieceData = queue.front()._clone()
	_remove_end_piece(QUEUE_SPEED)

	piece_swap.emit()
	return come_in_piece
	

## Moves all pieces up and removes latest piece in queue after **'delay'**
func _remove_end_piece(delay : float) -> void:
	is_shifting = true

	var last_piece : PieceData = queue.pop_front()

	var tween : Tween = create_tween().set_parallel(true)
	tween.tween_property(last_piece, 'position:y', -90.0, QUEUE_SPEED)
	# Move all pieces up
	for piece_pos : int in queue.size():
		tween.tween_property(queue[piece_pos], 'position:y', float(74 + piece_pos * 164), QUEUE_SPEED)
	
	await get_tree().create_timer(delay,true,true).timeout
	last_piece.queue_free()

	is_shifting = false


## Adds piece to the bottom of the queue [br]
## If **'piece_data'** is passed, data from this piece would be used instead of random generated one
func _append_piece(piece_data : PieceData = null) -> void:
	if piece_data == null:
		piece_data = PieceData.new()

		piece_data.game = game
		piece_data.ruleset = ruleset
		
		if before_special_left <= 0:
			piece_data._generate(true)
			_sync_settings()
		else:
			piece_data._generate(false)
	
	piece_data.position = Vector2(72, 74 + queue.size() * 164)
	queue.append(piece_data)
	
	# Avoid animation glitch if game waits for new piece and queue is empty
	if game.is_giving_pieces_to_player and game.piece == null and queue.size() == 1 : 
		piece_data.visible = false
	
	queue_node.add_child(piece_data)
	piece_appended.emit()
