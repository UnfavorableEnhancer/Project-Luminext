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

extends FX

func _ready() -> void:
	# Set special name
	name = "m" + str(position.x + 10) + str(position.y + 10)
	
	var color : Color = Color.WHITE
	var skin_data : SkinData = game.skin.skin_data
	
	match Player.config.video["blocks_replacement"] :
		Config.BLOCK_TEXTURE_OVERRIDE.NONE:
			match parameter:
				BlockBase.BLOCK_COLOR.RED: color = skin_data.textures["red_fx"]
				BlockBase.BLOCK_COLOR.WHITE : color = skin_data.textures["white_fx"]
				BlockBase.BLOCK_COLOR.GREEN : color = skin_data.textures["green_fx"]
				BlockBase.BLOCK_COLOR.PURPLE : color = skin_data.textures["purple_fx"]
		_: 
			match parameter:
				BlockBase.BLOCK_COLOR.RED : color = Color("ec7d24")
				BlockBase.BLOCK_COLOR.WHITE : color = Color.WHITE
				BlockBase.BLOCK_COLOR.GREEN : color = Color.GREEN
				BlockBase.BLOCK_COLOR.PURPLE : color = Color.PURPLE
	
	if Player.config.video["fx_quality"] == Config.EFFECTS_QUALITY.MINIMUM:
		$S4.free()
		$S5.free()
		$ANIM.get_animation_library("").remove_animation("start")
		start_animation = "min"
	else:
		start_animation = "start"
	
	# Color merge effect
	modulate = color
	
	_start()
