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

class_name Merge

##-----------------------------------------------------------------------
## Merge turns all blocks around into same color when activated
##-----------------------------------------------------------------------

var is_merged : bool = false ## True if all blocks around has merged


func _ready() -> void:
	super()
	
	landed.connect(_on_land)
	squared.connect(_merge)


## Called when block is landed
func _on_land() -> void:
	# If we're just silly remastered clone, do work immidiately
	if ruleset.rules["instant_special"] : 
		await physics_tick
		_merge()


## Turn all surrounding blocks in 5x5 area into same color as self
func _merge() -> void:
	if is_merged : return
	is_merged = true

	for x : int in range(grid_position.x - 2,grid_position.x + 3):
		for y : int in range(grid_position.y - 2, grid_position.y + 3):
			var block_position : Vector2i = Vector2i(x,y)
			var block : Block = game.blocks.get(block_position, null)

			if not is_instance_valid(block) : continue
			if block.is_removing : continue
			if block.is_scanned : continue

			if block.color != color : block._change_color(color)
	
	game._add_fx("merge", grid_position, color)
	special_sprite.queue_free()
