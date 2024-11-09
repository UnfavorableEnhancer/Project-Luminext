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

# Garbage block can be erased only when adjacent block (but not another garbage one) is getting erased

class_name Garbage

const LOOK_DELAY : float = 0.5

var look_timer : float = LOOK_DELAY
var adjacent : Array[Block] = []


func _physics() -> void:
	super()

	if look_timer > 0.0 : look_timer -= TICK
	else : 
		look_timer = LOOK_DELAY
		_check()


# Checks for adjacent blocks and connects their deletion signals to self. 
# So when some adjacent block is removed this garbage block is removed too.
func _check() -> void:
	# Disconnect old blocks
	for block : Block in adjacent: block.deleted.disconnect(_free)
	adjacent.clear()
	
	for side : int in [SIDE.LEFT,SIDE.DOWN,SIDE.UP,SIDE.RIGHT]:
		var block : Variant = _find_block(side)
		
		if block != null and block.color < 5: 
			adjacent.append(block)
			block.deleted.connect(_free)