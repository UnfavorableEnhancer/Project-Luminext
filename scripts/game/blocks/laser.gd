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

# Laser special block erases all blocks in 8 directions

class_name Laser

const LASER_DELAY : float = 0.2

var laser_fx : FX = null
var laser_timer : Timer = null
var working : bool = false

var lasered : Array[Block] = []


func _ready() -> void:
	super()

	reset.connect(_laser_reset)
	falled_down.connect(_on_fall)
	squared.connect(_on_fall)


func _on_fall() -> void:
	await get_tree().create_timer(0.01).timeout
	# If we're just silly remastered clone, do work immidiately
	if Data.profile.config["gameplay"]["instant_special"] : _squared()


# Resets laser block, and "unlaser" all lasered blocks
func _laser_reset() -> void:
	if working:
		working = false
		
		laser_fx.queue_free()
		laser_fx = null
		
		laser_timer.queue_free()
		laser_timer = null
		
		for block : Block in lasered:
			if is_instance_valid(block) : block._reset(false)
		lasered.clear()


# Called when laser block is squared
func _squared() -> void:
	if not working: 
		working = true
		
		# Add and store laser special effect, so we could remove it later
		laser_fx = Data.game._add_fx("laser", grid_position, color)
		
		laser_timer = Timer.new()
		laser_timer.timeout.connect(_work)
		add_child(laser_timer)
		laser_timer.start(LASER_DELAY)
		
		# Mark self to delete
		_add_mark(OVERLAY_MARK.DELETE)


# "Laser" all blocks in directions (angles)
func _work(angles : Array[float] = [0.0,45.0,90.0,135.0,180.0,225.0,270.0,315.0]) -> void:
	# When squared, mark to delete anything on horizontal, vertical and diagonal sight
	for angle : float in angles:
		for distance : int in 17:
			var search_vec : Vector2i = Vector2i(grid_position.x + distance * round(cos(deg_to_rad(angle))), grid_position.y + distance * round(sin(deg_to_rad(angle))))
			
			if Data.game.blocks.has(search_vec):
				var block : Block = Data.game.blocks[search_vec]
				
				if not block.is_falling and not block in lasered:  
					block._add_mark(OVERLAY_MARK.DELETE)
					block._make_deletable()
					lasered.append(block)


# Remove all lasered blocks with special animation
func _laser_blast() -> void:
	if working:
		working = false
		laser_fx._explode()
		
		laser_timer.queue_free()
		laser_timer = null
		
		for block : Block in lasered:
			if is_instance_valid(block) : block._free()


func _free() -> void:
	_laser_blast()
	super()
