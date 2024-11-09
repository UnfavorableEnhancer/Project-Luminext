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
var wipe_timer : float = 0.0

var is_working : bool = false
var wipe_fx : FX = null

var wiped : Dictionary = {} # [Vector2i : Block]


func _ready() -> void:
	super()

	reset.connect(_wipe_reset)
	falled_down.connect(_on_fall)
	squared.connect(_start_wipe)


func _on_fall() -> void:
	await physics_tick
	# If we're just silly remastered clone, do work immidiately
	if Data.profile.config["gameplay"]["instant_special"] : _start_wipe()


func _physics() -> void:
	super()

	if is_working:
		if wipe_timer > 0.0 : wipe_timer -= TICK
		else : 
			wipe_timer = WIPE_DELAY
			_wipe()


func _start_wipe() -> void:
	wipe_fx = Data.game._add_fx("wipe", grid_position, color)
	
	wipe_timer = WIPE_DELAY
	is_working = true

	_wipe()


# Marks all blocks to delete in range
func _wipe() -> void:
	for x : int in range(grid_position.x - 3, grid_position.x + 4):
		for y : int in range(grid_position.y - 3, grid_position.y + 4):
			if Data.game.blocks.has(Vector2i(x,y)):
				var block : Block = Data.game.blocks[Vector2i(x,y)]

				if block.color != color : continue
				if wiped.has(block.grid_position) : continue
				
				block._add_mark(OVERLAY_MARK.ERASE)
				block.reset.connect(wiped.erase.bind(block.grid_position))
				wiped[block.grid_position] = block


# Resets wipe block, and "unwipe" all wiped blocks
func _wipe_reset() -> void:
	is_working = false
	
	wipe_fx.queue_free()
	wipe_fx = null
	
	for block : Variant in wiped.values:
		if is_instance_valid(block) : block._reset(false)
	
	wiped.clear()


# Remove all wiped blocks with special animation
func _wipe_blast() -> void:
	is_working = false
	
	wipe_fx._explode()
	
	for block : Variant in wiped.values:
		if is_instance_valid(block) : block._free()


func _free() -> void:
	_wipe_blast()
	super()
