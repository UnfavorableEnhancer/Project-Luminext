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

class_name Garbage

##-----------------------------------------------------------------------
## Garbage block can be erased only when adjacent block (but not another garbage one) is getting erased
##-----------------------------------------------------------------------

const LOOK_DELAY : float = LuminextGame.TICK * 10 ## Delay before checking for block deletions

var look_timer_left : float = LOOK_DELAY ## Time left before checking for block deletions
var adjacent : Array[Block] = [] ## All adjacent blocks instances


func _physics(delta : float) -> void:
	super(delta)

	look_timer_left -= delta

	if look_timer_left <= 0:
		_check()
		look_timer_left = LOOK_DELAY
		

## Checks for adjacent blocks and connects their deletion signals to self
func _check() -> void:
	# Disconnect old blocks
	for block : Block in adjacent:
		if is_instance_valid(block): 
			block.removed.disconnect(_remove)
	adjacent.clear()
	
	for side : int in [SIDE.LEFT,SIDE.DOWN,SIDE.UP,SIDE.RIGHT]:
		var block : Variant = _find_block(side)
		
		if block == null : continue
		if block.is_falling : continue
		if block.is_removing : _remove()
		if block.color > 4 : continue
		
		adjacent.append(block)
		block.removed.connect(_remove)