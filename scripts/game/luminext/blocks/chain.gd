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

class_name Chain

##-----------------------------------------------------------------------
## Chains all adjacent same colored blocks and makes them deletable by timeline
##-----------------------------------------------------------------------

const CHAIN_DELAY : float = LuminextGame.TICK * 10 ## Delay before block chaining starts
var chain_timer_left : float = 999.0 ## Time left before calling chain function

var chained : Dictionary[Vector2i, Block] = {} ## Blocks chained by this chain block [br] [Vector2i : Block]

var is_working : bool = false ## True if chain is active


func _ready() -> void:
	super()

	reset.connect(_reset_chain)
	if not game.gamemode.ruleset.rules["instant_special"]:
		unsquared.connect(_reset_chain)

	squared.connect(_on_squared)
	landed.connect(_on_land)


## Called when block is landed
func _on_land() -> void:
	# If we're just silly remastered clone, do work immidiately
	if ruleset.rules["instant_special"] and not is_working:
		chain_timer_left = CHAIN_DELAY
		is_working = true


## Called on each physics tick
func _physics(delta : float) -> void:
	super(delta)

	if not is_working : return

	chain_timer_left -= delta
	if chain_timer_left <= 0.0 : 
		_chain(grid_position, color)
		chain_timer_left = CHAIN_DELAY


## Called when this block is squared
func _on_squared() -> void:
	if not is_working:
		chain_timer_left = CHAIN_DELAY
		is_working = true


## Resets chain removing all connected blocks from it
func _reset_chain() -> void:
	if not is_working : return
	is_working = false
	chain_timer_left = 999.0
	
	for block : Block in chained.values():
		if is_instance_valid(block): 
			block._special_undelete(grid_position)
			block.reset.disconnect(_remove_block.bind(block.grid_position))
	
	chained.clear()


## Chains all adjacent blocks, making them deletable
func _chain(in_position : Vector2i, with_color : int = color) -> void:
	var blocks_to_check : Array[Vector2i] = [in_position]
	var current_chained : Dictionary[Vector2i, Block] = {}

	while not blocks_to_check.is_empty():
		var block_position : Vector2i = blocks_to_check.pop_back()

		if current_chained.has(block_position) : continue
		var block : Block = game.blocks.get(block_position, null)

		if not is_instance_valid(block) : continue
		if block.is_falling : continue
		if block.color != with_color: continue
		if block.is_removing : continue
		if block is Joker: continue
		
		if not chained.has(block_position):
			chained[block_position] = block
			block._special_delete(grid_position)
			block.reset.connect(_remove_block.bind(block_position))

		current_chained[block_position] = block

		blocks_to_check.append_array([block_position + Vector2i(1,0), block_position + Vector2i(-1,0), block_position + Vector2i(0,1), block_position + Vector2i(0,-1)])
 

## Removes chained block from chain
func _remove_block(at_position : Vector2i) -> void:
	var block : Block = chained.get(at_position, null)
	if is_instance_valid(block) : 
		block._special_undelete(grid_position)
		block.reset.disconnect(_remove_block.bind(at_position))
	chained.erase(at_position)
