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

signal blocks_scan_started # Emmitted when timeline touches deletable block or square

signal blocks_deleted(amount : int) # Emitted when timeline removes blocks
signal squares_deleted(amount : int) # Emitted when timeline removes squares

signal finished # Emitted when timeline ends its travel

var is_doing_beat : bool = false # If true, timeline will do beat animation
var is_paused : bool = false
var is_dying : bool = false

var timeline_sound : AudioStreamPlayer2D = null # Timeline sound is stored here so it can be removed when timeline ends scan
var has_played_sound : bool = false

var x_pos : int = 0 # Current timeline X position in game field coords

var total_deleted_squares_count : int = 0
var current_square_group_size : int = 0

var last_scanned_square_pos : Vector2i

var scanned_blocks : Array = [] # All blocks currently scanned by timeline
var scanned_squares : Array = [] # All squares currently scanned by timeline

#var tween : Tween
var speed : float = 1088.0 / 120.0 / 4.0


# Starts timeline from begining
func _ready() -> void:
	position = Vector2(356,204)
	create_tween().tween_method(_gradient, 0.0, 1.0, 60.0 / Data.game.skin.bpm)

	speed = speed * (Data.game.skin.bpm / 120.0)

	_check_next_line()


func _physics() -> void:
	position.x += speed

	if position.x >= x_pos * 68 + 356:
		_check_next_line()


# Process next row, and search blocks to remove
func _check_next_line() -> void:
	x_pos += 1
	var has_erased_something : bool = false
	var delete : Dictionary = Data.game.delete
	var squares : Dictionary = Data.game.squares
	
	for y : int in 10:
		var pos : Vector2i = Vector2i(x_pos,y)
		
		if delete.has(pos):
			var block : Block = delete[pos]
			if scanned_blocks.is_empty(): blocks_scan_started.emit()
			
			if is_instance_valid(block): 
				scanned_blocks.append(block)
				block._add_mark(Block.OVERLAY_MARK.ERASE)
				block.is_scanned = true
				has_erased_something = true
		
		if squares.has(pos): 
			var square : Square = squares[pos]
			if is_instance_valid(square): 
				current_square_group_size += 1
				scanned_squares.append(pos)
				last_scanned_square_pos = Vector2i(x_pos,y)
				Data.game._add_fx(&'erase', Vector2(x_pos,y), square.parameter)
	
	if has_erased_something and not has_played_sound:
		has_played_sound = true
		timeline_sound = Data.game._add_sound(&'timeline',position,true,false)
		is_doing_beat = true
	
	$Number.text = str(total_deleted_squares_count + current_square_group_size)
	
	if not has_erased_something and not scanned_blocks.is_empty():
		_delete_scanned()


# Removes every scanned blocks and squares
func _delete_scanned() -> void:
	var has_found_special : bool = false
	var is_square_deleted : bool = false
	
	var actual_deleted_squares_count : int = 0

	var real_delete : Dictionary = Data.game.delete
	var before_delete : Dictionary = Data.game.delete.duplicate(true)

	if scanned_squares.size() > 0 : 
		is_square_deleted = true
		var deleted_square_groups : Array = Data.game._get_all_sqaure_groups(scanned_squares)

		for square_group : Array in deleted_square_groups:
			while not square_group.is_empty():
				var square : Square = square_group.pop_back()
				if not is_instance_valid(square) : continue
				
				# Check top-left block inside square if it is actually scanned by timeline
				var check_block : Block = before_delete[square.grid_position]
				if not check_block.is_scanned : continue
				
				Data.game._add_fx("blast", square.grid_position, square.parameter)
				square._remove()
				actual_deleted_squares_count += 1
		
		total_deleted_squares_count += actual_deleted_squares_count
		$Number.text = str(total_deleted_squares_count)
		scanned_squares.clear()
		current_square_group_size = 0
		
	squares_deleted.emit(actual_deleted_squares_count)

	if scanned_blocks.size() > 0 : 
		for block : Block in scanned_blocks:
			if not is_instance_valid(block) : continue 
			if not before_delete.has(block.grid_position) : continue
			
			real_delete.erase(block.grid_position)
			block._free()
			if not block.special.is_empty() and block.special != &"joker" : has_found_special = true
	
	blocks_deleted.emit(scanned_blocks.size())
	scanned_blocks.clear()
	
	if is_instance_valid(timeline_sound):
		timeline_sound.stop()
		timeline_sound.queue_free()
		timeline_sound = null
		has_played_sound = false
	
	if is_square_deleted:
		if has_found_special:
			Data.game._add_sound(&"special",Vector2(x_pos*48+300,480))
		else: 
			if Data.profile.config["audio"]["sequential_sounds"]:
				if actual_deleted_squares_count == 1:
					Data.game._add_sound(&"blast1",Vector2(x_pos*48+300,480))
				elif actual_deleted_squares_count % 2 == 0:
					Data.game._add_sound(&"blast2",Vector2(x_pos*48+300,480))
				elif actual_deleted_squares_count % 2 == 1:
					Data.game._add_sound(&"blast3",Vector2(x_pos*48+300,480))
			else:
				Data.game._add_sound(&"blast",Vector2(x_pos*48+300,480))
	
	Data.game._move_blocks()


# Pauses timeline
func _pause(on : bool) -> void:
	if is_dying: return
	is_paused = on


# Used to tween gradient
func _gradient(value : float) -> void:
	$Color/Gradient.texture.gradient.colors = PackedColorArray([Color(0,0,0,0),Color(1.0,1.0,1.0,value)])
	$Color/Gradient.texture.gradient.offsets = PackedFloat32Array([clamp(0.999 - value,0.0,1.0),1.0])


# Plays "beat" animation
func _beat() -> void:
	if is_doing_beat and not is_paused:
		var beat_tween : Tween = create_tween()
		beat_tween.tween_property($Color/GLOW,"modulate:a",1.0,60.0 / Data.game.skin.bpm / 4.0).from(0.0)
		beat_tween.tween_interval(60.0 / Data.game.skin.bpm / 4.0)
		beat_tween.tween_property($Color/GLOW,"modulate:a",0.0,60.0 / Data.game.skin.bpm / 4.0)


# Removes timeline
func _end(quiet : bool = false) -> void:
	if is_dying : return
	is_dying = true
	is_paused = true
	
	if not scanned_blocks.is_empty() and x_pos > 1: _delete_scanned()
	
	finished.emit()
	position = Vector2(1444,204)
	
	$Color/Arrow.visible = false
	$Color/Line.visible = false
	$Number.visible = false
	
	Data.game.timeline = null
	if quiet:
		queue_free()
		return

	var gradient_tween : Tween = create_tween()
	gradient_tween.tween_method(_gradient, 1.0, 0.0, 60.0 / Data.game.skin.bpm * 3.0)
	
	if is_doing_beat : 
		var beat_tween : Tween = create_tween()
		beat_tween.tween_property($Color/GLOW,"modulate:a",0.0,60.0 / Data.game.skin.bpm / 1.5).from(1.0)

	await gradient_tween.step_finished
	queue_free()
