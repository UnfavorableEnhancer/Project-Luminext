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


extends Node2D

class_name Timeline

##-----------------------------------------------------------------------
## Timeline moves from left side to right side of the gamefield and scans
## all squares and deletable blocks it passes and then erases them
##-----------------------------------------------------------------------

signal scan_started ## Emitted when timeline starts passing thru deletable blocks and squares
signal blocks_deleted(amount : int) ## Emitted when timeline deletes blocks and returns deleted amount
signal squares_deleted(amount : int) ## Emitted when timeline deletes squares and returns deleted amount
signal finished ## Emitted when timeline ends its travel

const GRADIENT_LENGTH : float = 256.0 ## Size of gradient texture

var game : LuminextGame ## Game instance

var is_doing_beat : bool = false ## If true, timeline will do beat animation
var is_paused : bool = false ## If true, timeline movement is stopped
var is_removing : bool = false ## If true, timeline is currently removing

var timeline_sound : AudioStreamPlayer2D = null ## Currently playing timeline sound instance
var has_played_sound : bool = false ## True if timeline sound is already played

var x_pos : int = 0 ## Current timeline X position in game field cell coordinates
var next_x_pos_to_check : float = 9999 ## Next X position from which we check erasable blocks/squares

var total_deleted_squares_count : int = 0 ## Total deleted by this timeline squares count
var currently_scanned_square_count : int = 0 ## Currently scanned squares count

var last_scanned_square_pos : Vector2i ## Latest scanned square position

var scanned_blocks : Array[Vector2i] = [] ## All deletable blocks positions currently scanned by timeline
var scanned_squares : Dictionary[Vector2i, bool] = {} ## All squares positions currently scanned by timeline

var speed : float = LuminextGame.CELL_SIZE * 16.0 / 4.0 ## How fast timeline moves per music beat


func _ready() -> void:
	name = "Timeline"
	position = Vector2(0,0)

	var tween : Tween = create_tween().set_parallel(true)
	
	tween.tween_property($Color/Gradient, "offset:x", -GRADIENT_LENGTH, game.skin.single_beat).from(0.0)
	tween.tween_property($Color/Gradient, "region_rect:size:x", GRADIENT_LENGTH, game.skin.single_beat).from(0.0)
	tween.tween_property($Color/GLOW/Gradient, "offset:x", -GRADIENT_LENGTH, game.skin.single_beat).from(0.0)
	tween.tween_property($Color/GLOW/Gradient, "region_rect:size:x", GRADIENT_LENGTH, game.skin.single_beat).from(0.0)

	speed = speed * (game.skin.bpm / SkinPlayer.BASE_BPM)
	_scan_current_line()


## Called on each physics tick
func _physics(delta : float) -> void:
	if is_paused : return

	position.x += speed * delta
	if position.x >= next_x_pos_to_check:
		_scan_current_line()


## Scan all avaiable in current row deletable blocks and squares and advance to the next row
func _scan_current_line() -> void:
	var has_erased_something : bool = false
	
	for y : int in 10:
		var scan_position : Vector2i = Vector2i(x_pos, y)

		var block : Block = game.blocks.get(scan_position, null)
		if is_instance_valid(block) and block.is_deletable:
			if scanned_blocks.is_empty(): scan_started.emit()
			scanned_blocks.append(scan_position)
			block._scan()
			has_erased_something = true
		
		var square : Square = game.squares.get(scan_position, null)
		if is_instance_valid(square): 
			currently_scanned_square_count += 1
			scanned_squares[scan_position] = true
			last_scanned_square_pos = scan_position

			var fx_pos : Vector2
			fx_pos.x = (scan_position.x + 1) * LuminextGame.CELL_SIZE + LuminextGame.FIELD_X_OFFSET
			fx_pos.y = (scan_position.y + 1) * LuminextGame.CELL_SIZE + LuminextGame.FIELD_Y_OFFSET

			game._add_fx(&'erase', fx_pos, square.color)

	if has_erased_something and not has_played_sound:
		has_played_sound = true
		timeline_sound = game._add_sound(&'timeline',position,true,false)
		is_doing_beat = true
	
	$Number.text = str(total_deleted_squares_count + currently_scanned_square_count)
	
	if not has_erased_something and not scanned_blocks.is_empty():
		_delete_scanned()
	
	x_pos += 1
	next_x_pos_to_check = x_pos * LuminextGame.CELL_SIZE


## Removes all currently scanned deletable blocks and squares
func _delete_scanned() -> void:
	var has_found_special : bool = false
	var is_square_deleted : bool = false	
	var actual_deleted_squares_count : int = 0

	if scanned_squares.size() > 0 : 
		is_square_deleted = true
		
		var deleted_square_groups : Array[Dictionary] = game._get_all_square_groups_in_positions(scanned_squares)

		for square_group : Dictionary[Vector2i, Square] in deleted_square_groups:
			var square_group_squares : Array[Square] = square_group.values() 

			while not square_group_squares.is_empty():
				var square : Square = square_group_squares.pop_back()
				if not is_instance_valid(square) : continue

				var square_position : Vector2i = square.grid_position
				
				# Check top-left block inside square if it is actually scanned by timeline
				var check_block : Block = game.blocks.get(square_position, null)
				if not is_instance_valid(check_block) or not check_block.is_scanned : continue
				
				var fx_pos : Vector2
				fx_pos.x = (square_position.x + 1) * LuminextGame.CELL_SIZE + LuminextGame.FIELD_X_OFFSET
				fx_pos.y = (square_position.y + 1) * LuminextGame.CELL_SIZE + LuminextGame.FIELD_Y_OFFSET
				game._add_fx("blast", fx_pos, square.color)

				square._remove()
				actual_deleted_squares_count += 1
		
		total_deleted_squares_count += actual_deleted_squares_count
		squares_deleted.emit(actual_deleted_squares_count)
		$Number.text = str(total_deleted_squares_count)
	
	scanned_squares.clear()
	currently_scanned_square_count = 0

	if scanned_blocks.size() > 0 : 
		var actual_deleted_blocks_count : int = 0
		for block_position : Vector2i in scanned_blocks:
			var block : Block = game.blocks.get(block_position, null)
			if not is_instance_valid(block) : continue 
			if not block.is_scanned : continue 

			if not block.special.is_empty() and block.special != &"joker" : has_found_special = true
			actual_deleted_blocks_count += 1
			block._remove()
	
		blocks_deleted.emit(actual_deleted_blocks_count)
	
	scanned_blocks.clear()
	
	if is_instance_valid(timeline_sound):
		timeline_sound.stop()
		timeline_sound.queue_free()
		timeline_sound = null
		has_played_sound = false
	
	if is_square_deleted:
		if has_found_special:
			game._add_sound(&"special",Vector2(x_pos*48+300,480))
		else: 
			if Player.config.audio["sequential_sounds"]:
				if actual_deleted_squares_count == 1:
					game._add_sound(&"blast",Vector2(x_pos*48+300,480),false,true,1)
				elif actual_deleted_squares_count % 2 == 0:
					game._add_sound(&"blast",Vector2(x_pos*48+300,480),false,true,-2)
				elif actual_deleted_squares_count % 2 == 1:
					game._add_sound(&"blast",Vector2(x_pos*48+300,480),false,true,-3)
			else:
				game._add_sound(&"blast",Vector2(x_pos*48+300,480))
	
	game._move_blocks()
	has_played_sound = false


# Plays "beat" animation
func _beat() -> void:
	if is_doing_beat and not is_paused:
		var beat_tween : Tween = create_tween()
		beat_tween.tween_property($Color/GLOW,"modulate:a",1.0,game.skin.single_beat / 4.0).from(0.0)
		beat_tween.tween_interval(game.skin.single_beat / 4.0)
		beat_tween.tween_property($Color/GLOW,"modulate:a",0.0,game.skin.single_beat / 4.0)


## Removes timeline with special animation[br]
## If **'quiet** is true, removes timeline without animation [br]
## If **'at_end** is true, teleports timeline to the end of game field
func _remove(quiet : bool = false, at_end : bool = true) -> void:
	if is_removing : return
	is_removing = true
	is_paused = true
	
	if not scanned_blocks.is_empty() and x_pos > 1: _delete_scanned()
	
	finished.emit()
	if at_end : position = Vector2(LuminextGame.CELL_SIZE * 16.0, 0.0)
	
	$Color/Arrow.visible = false
	$Color/Line.visible = false
	$Number.visible = false
	
	game.timeline = null
	if quiet:
		queue_free()
		return

	var gradient_tween : Tween = create_tween().set_parallel(true)
	gradient_tween.tween_property($Color/Gradient, "offset:x", 0.0, game.skin.single_beat).from(-GRADIENT_LENGTH)
	gradient_tween.tween_property($Color/Gradient, "region_rect:size:x", 0.0, game.skin.single_beat).from(GRADIENT_LENGTH)
	gradient_tween.tween_property($Color/GLOW/Gradient, "offset:x", 0.0, game.skin.single_beat).from(-GRADIENT_LENGTH)
	gradient_tween.tween_property($Color/GLOW/Gradient, "region_rect:size:x", 0.0, game.skin.single_beat).from(GRADIENT_LENGTH)
	
	if is_doing_beat : 
		var beat_tween : Tween = create_tween()
		beat_tween.tween_property($Color/GLOW, "modulate:a", 0.0, game.skin.single_beat / 1.5).from(1.0)

	await gradient_tween.step_finished
	queue_free()
