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
	name = "e" + str(position.x + 10) + str(position.y + 10)
	
	z_as_relative = false
	z_index = LuminextGame.BLAST_Z_INDEX
	
	var skin_data : SkinData = game.skin.skin_data
	var color : Color = Color.WHITE
	
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
	
	start_animation = "start"
	
	$Line2D.self_modulate = color
	$Line2D/S4.material.set_shader_parameter("tint_color", color)
	
	$ANIM.speed_scale = 2.5 * (game.skin.bpm / 120.0)
	
	_start()
