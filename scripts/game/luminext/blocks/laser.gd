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


extends Block

class_name Laser

##-----------------------------------------------------------------------
## Laser erases all blocks in several directions
##-----------------------------------------------------------------------

const LASER_DELAY : float = LuminextGame.TICK * 10 ## Delay before calling chain function
var laser_timer_left : float = 0.0 ## Time left before calling laser function

var lasered : Dictionary[Vector2i, Block] = {} ## Blocks passed by our lasers [br] [Vector2i : Block]

var laser_fx : FX = null ## Laser FX instance
var is_working : bool = false ## True if laser is active

## Angles towards which lasers are fired and removes blocks
var angles : Array[float] = [0.0,45.0,90.0,135.0,180.0,225.0,270.0,315.0] 


func _ready() -> void:
	super()

	reset.connect(_reset_laser)
	if not ruleset.rules["instant_special"]:
		unsquared.connect(_reset_laser)

	squared.connect(_on_squared)
	landed.connect(_on_land)	
	removed.connect(_laser_blast)


## Called on each physics tick
func _physics(delta : float) -> void:
	super(delta)

	if not is_working : return

	laser_timer_left -= delta
	if laser_timer_left <= 0.0 : 
		_laser()
		laser_timer_left = LASER_DELAY


## Called when block is landed
func _on_land() -> void:
	# If we're just silly remastered clone, do work immidiately
	if ruleset.rules["instant_special"] and not is_working:
		await physics_tick
		_on_squared()


## Called when this block is squared
func _on_squared() -> void:
	if is_working : return
	# Add and store laser special effect, so we could use it later
	laser_fx = game._add_fx("laser", grid_position, color)
	
	laser_timer_left = LASER_DELAY
	is_working = true

	_laser()


## "Laser" all blocks in directions defined by **'angles'**
func _laser() -> void:
	for angle : float in angles:
		for distance : int in 17:
			var search_vec : Vector2i = Vector2i(grid_position.x + distance * round(cos(deg_to_rad(angle))), grid_position.y + distance * round(sin(deg_to_rad(angle))))
			
			var block : Block = game.blocks.get(search_vec, null)

			if not is_instance_valid(block) : continue
			if block.is_falling : continue
			if block.is_removing : continue
			if lasered.has(search_vec) : continue
			
			block._special_delete(grid_position)
			block.reset.connect(_remove_block.bind(search_vec))

			lasered[search_vec] = block


## Removes lasered block from laser sight
func _remove_block(at_position : Vector2i) -> void:
	var block : Block = lasered.get(at_position, null)
	if is_instance_valid(block) : 
		block._special_undelete(grid_position)
		block.reset.disconnect(_remove_block.bind(at_position))
	lasered.erase(at_position)


## Resets laser block to initial state
func _reset_laser() -> void:
	if not is_working : return
	is_working = false
		
	if laser_fx != null:
		laser_fx.queue_free()
		laser_fx = null
	
	for block : Block in lasered.values():
		if is_instance_valid(block) : block._special_undelete(grid_position)
	
	lasered.clear()


## Remove all lasered blocks with special animation
func _laser_blast() -> void:
	if not is_working : return
	is_working = false
	laser_fx._explode()
	
	for block : Block in lasered.values():
		if is_instance_valid(block) : block._remove()
