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


extends Block

# Wipe special block removes all same colored blocks in range

class_name Wipe

const WIPE_DELAY : float = 0.2

var working : bool = false
var wipe_timer : Timer = null
var wipe_fx : FX = null

var wiped : Array[Block] = []


func _ready() -> void:
	super()

	reset.connect(_wipe_reset)
	falled_down.connect(_on_fall)
	squared.connect(_squared)


func _on_fall() -> void:
	await get_tree().create_timer(0.01).timeout
	# If we're just silly remastered clone, do work immidiately
	if Data.profile.config["gameplay"]["instant_special"] : _squared()


# Resets wipe block, and "unwipe" all wiped blocks
func _wipe_reset() -> void:
	if working:
		working = false
		
		wipe_fx.queue_free()
		wipe_fx = null
		
		wipe_timer.queue_free()
		wipe_timer = null
		
		for block : Block in wiped:
			if is_instance_valid(block) : block._reset(false)
		
		wiped = []


# Called when wipe block is squared
func _squared() -> void:
	if not working: 
		working = true
		
		wipe_fx = Data.game._add_fx("wipe", grid_position, color)
		
		# Create special work timer
		wipe_timer = Timer.new()
		wipe_timer.timeout.connect(_work)
		add_child(wipe_timer)
		wipe_timer.start(WIPE_DELAY)
		
		# Mark self to delete
		_add_mark(OVERLAY_MARK.DELETE)


# Marks all blocks to delete in range
func _work(work_range : int = 3) -> void:
	for x : int in range(grid_position.x - work_range, grid_position.x + work_range + 1):
		for y : int in range(grid_position.y - work_range, grid_position.y + work_range + 1):
			if Data.game.blocks.has(Vector2i(x,y)):
				var block : Block = Data.game.blocks[Vector2i(x,y)]
				
				if not block.is_falling and block.color == color and not block in wiped:
					block._add_mark(OVERLAY_MARK.DELETE)
					block._make_deletable()
					wiped.append(block)


# Remove all wiped blocks with special animation
func _wipe_blast() -> void:
	if working:
		working = false
		
		wipe_fx._explode()
		
		wipe_timer.queue_free()
		wipe_timer = null
		
		for block : Block in wiped:
			if is_instance_valid(block) : block._free()


func _free() -> void:
	_wipe_blast()
	super()
