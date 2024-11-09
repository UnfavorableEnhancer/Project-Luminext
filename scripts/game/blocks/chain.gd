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

# Chain special block "chains" all adjacent same colored blocks, making them deletable by timeline

class_name Chain

const CHAIN_DELAY : float = 0.2

var chained : Dictionary = {} # Blocks chained by this chain block [Vector2i : Block]

var chain_timer : float = 0.0 # Time before calling chain function

var is_working : bool = false


func _ready() -> void:
	super()
	
	reset.connect(_chain_reset)
	squared.connect(_squared)
	falled_down.connect(_on_fall)


func _on_fall() -> void:
	# If we're just silly remastered clone, do work immidiately
	if Data.profile.config["gameplay"]["instant_special"] : 
		chain_timer = TICK
		is_working = true


func _physics() -> void:
	super()

	if is_working:
		if chain_timer > 0.0 : chain_timer -= TICK
		else : _start_chain()


# Called when block is deleted
func _free() -> void:
	_chain_reset()
	super()


# Called when chain block is squared
func _squared() -> void:
	chain_timer = CHAIN_DELAY
	is_working = true


# Called by chain timer
func _start_chain() -> void:
	is_working = false
	# We clear "chained" each cycle because when field changes much, we can't be sure are blocks adjacent anymore
	chained.clear()
	_chain(self, color)


# Chains adjacent blocks, making them deletable
func _chain(block : Block, with_color : int = color) -> void:
	# Search for same-colored adjacent blocks, from this block position
	for side : int in [SIDE.LEFT,SIDE.DOWN,SIDE.UP,SIDE.RIGHT]:
		var adj_block : Block = block._find_block(side)
		
		if adj_block == null: continue
		if adj_block.color != with_color: continue
		if adj_block.is_dying : continue
		if adj_block is Joker: continue
		
		if not chained.has(adj_block.grid_position):
			chained[adj_block.grid_position] = adj_block
			adj_block._make_deletable(true)
			adj_block.reset.connect(chained.erase.bind(adj_block.grid_position))
			_chain(adj_block, with_color)


# Resets chain block, and 'unchain' all chained blocks
func _chain_reset() -> void:
	is_working = false
	chain_timer = 0.0
	
	for block : Variant in chained.values():
		if is_instance_valid(block): block._reset(false)
	
	chained.clear()
