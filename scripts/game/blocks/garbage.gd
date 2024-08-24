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

var neibors : Array[Block] = []


func _ready() -> void:
	super()

	var timer : Timer = Timer.new()
	timer.wait_time = LOOK_DELAY
	timer.timeout.connect(_check)
	add_child(timer)
	timer.start()


# Checks for adjacent blocks and connects their deletion signals to self. 
# So when some adjacent block is removed this garbage block is removed too.
func _check() -> void:
	# Disconnect old blocks
	for block : Block in neibors: block.deleted.disconnect(_free)
	neibors.clear()
	
	for side : int in [SIDE.LEFT,SIDE.DOWN,SIDE.UP,SIDE.RIGHT]:
		var block : Block = _find_block(side)
		
		if block != null and block.color < 5: 
			neibors.append(block)
			block.deleted.connect(_free)
