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
var laser_timer : float = 0.0

var laser_fx : FX = null
var is_working : bool = false

var lasered : Dictionary = {} #[Vector2i : Block]


func _ready() -> void:
	super()

	falled_down.connect(_on_fall)
	squared.connect(_start_laser)


func _physics() -> void:
	super()

	if is_working:
		if laser_timer > 0.0 : laser_timer -= TICK
		else : 
			laser_timer = LASER_DELAY * (120.0 / Data.game.skin.bpm)
			_laser()


func _on_fall() -> void:
	# If we're just silly remastered clone, do work immidiately
	if Data.profile.config["gameplay"]["instant_special"] and not is_working:
		await physics_tick
		_start_laser()


# Called when laser block is squared
func _start_laser() -> void:
	if not is_working:
		# Add and store laser special effect, so we could use it later
		laser_fx = Data.game._add_fx("laser", grid_position, color)
		
		laser_timer = LASER_DELAY * (120.0 / Data.game.skin.bpm)
		is_working = true

		_laser()


# "Laser" all blocks in directions (angles)
func _laser(angles : Array[float] = [0.0,45.0,90.0,135.0,180.0,225.0,270.0,315.0]) -> void:
	# When squared, mark to delete anything on horizontal, vertical and diagonal sight
	for angle : float in angles:
		for distance : int in 17:
			var search_vec : Vector2i = Vector2i(grid_position.x + distance * round(cos(deg_to_rad(angle))), grid_position.y + distance * round(sin(deg_to_rad(angle))))
			
			if Data.game.blocks.has(search_vec):
				var block : Block = Data.game.blocks[search_vec]

				if block.is_dying : continue
				if lasered.has(block.grid_position) : continue
				
				block._make_deletable(true)
				if not block.reset.is_connected(_remove_block.bind(block.grid_position)):
					block.reset.connect(_remove_block.bind(block.grid_position))
				lasered[block.grid_position] = block


func _remove_block(at_position : Vector2i) -> void:
	lasered.erase(at_position)


# Resets laser block, and "unlaser" all lasered blocks
func _reset(remove_squares : bool) -> void:
	if is_working:
		is_working = false
		
		if laser_fx != null:
			laser_fx.queue_free()
			laser_fx = null
		
		for block : Variant in lasered.values():
			if is_instance_valid(block) : block._reset(false)
		lasered.clear()
	
	super(remove_squares)


# Remove all lasered blocks with special animation
func _laser_blast() -> void:
	if is_working:
		is_working = false
		laser_fx._explode()
		
		for block : Variant in lasered.values():
			if is_instance_valid(block) : block._free()


func _free() -> void:
	_laser_blast()
	super()
