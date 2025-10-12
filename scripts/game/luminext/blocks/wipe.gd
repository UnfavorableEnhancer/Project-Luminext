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

class_name Wipe

##-----------------------------------------------------------------------
## Wipes all same colored blocks in 5x5 area and makes them deletable by timeline
##-----------------------------------------------------------------------

const WIPE_DELAY : float = LuminextGame.TICK * 10 ## Delay before block wipe starts
var wipe_timer_left : float = 999.0 ## Time left before calling wipe function

var wiped : Dictionary[Vector2i, Block] = {}  ## Blocks which are going to be wiped [br] [Vector2i : Block]
var wipe_fx : FX = null ## Wipe FX instance

var is_working : bool = false ## True if wipe is active


func _ready() -> void:
	super()

	reset.connect(_reset_wipe)
	if not ruleset.rules["instant_special"]:
		unsquared.connect(_reset_wipe)

	landed.connect(_on_land)
	squared.connect(_on_squared)
	removed.connect(_wipe_blast)


## Called when block is landed
func _on_land() -> void:
	# If we're just silly remastered clone, do work immidiately
	if ruleset.rules["instant_special"] and not is_working: 
		await physics_tick
		_on_squared()


## Called on each physics tick
func _physics(delta : float) -> void:
	super(delta)

	if not is_working : return

	wipe_timer_left -= delta
	if wipe_timer_left <= 0.0 : 
		_wipe()
		wipe_timer_left = WIPE_DELAY


## Called when this block is squared
func _on_squared() -> void:
	if is_working : return
	# Add and store wipe special effect, so we could use it later
	wipe_fx = game._add_fx("wipe", grid_position, color)

	wipe_timer_left = WIPE_DELAY
	is_working = true
	
	_wipe()


## Marks all blocks to delete in range
func _wipe() -> void:
	for x : int in range(grid_position.x - 3, grid_position.x + 4):
		for y : int in range(grid_position.y - 3, grid_position.y + 4):
			var search_vec : Vector2i = Vector2i(x,y)
			
			var block : Block = game.blocks.get(search_vec, null)
			
			if not is_instance_valid(block) : continue
			if block.is_falling : continue
			if block.is_removing : continue
			if wiped.has(search_vec) : continue
			if block.color != color : continue
			
			block._special_delete(grid_position)
			block.reset.connect(_remove_block.bind(search_vec))

			wiped[search_vec] = block


## Removes wiped block from sight
func _remove_block(at_position : Vector2i) -> void:
	var block : Block = wiped.get(at_position, null)
	if is_instance_valid(block) : 
		block._special_undelete(grid_position)
		block.reset.disconnect(_remove_block.bind(at_position))
	wiped.erase(at_position)


## Resets wipe block to initial state
func _reset_wipe() -> void:
	if not is_working : return
	is_working = false

	if wipe_fx != null:
		wipe_fx.queue_free()
		wipe_fx = null

	for block : Variant in wiped.values():
		if is_instance_valid(block) : block._special_undelete(grid_position)

	wiped.clear()


## Remove all wiped blocks with special animation
func _wipe_blast() -> void:
	if not is_working : return
	is_working = false
		
	wipe_fx._explode()
		
	for block : Variant in wiped.values():
		if is_instance_valid(block) : block._remove()
