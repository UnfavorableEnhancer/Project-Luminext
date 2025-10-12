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
	name = "b" + str(position.x + 10) + str(position.y + 10)
	
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
	
	if Player.config.video["background_effects"] : z_index = -4
	
	$S1.material.set_shader_parameter("tint_color", color)
	$S2.material.set_shader_parameter("tint_color", color)
	$Glow.material.set_shader_parameter("tint_color", color)
	$P1.material.set_shader_parameter("tint_color", color)
	$P3.material.set_shader_parameter("tint_color", color)
	
	$Line.self_modulate = color
	$Line2.self_modulate = color
	
	$P1.texture = skin_data.textures["effect_1"]
	$P3.texture = skin_data.textures["effect_2"]
	
	match Player.config.video["fx_quality"]:
		Config.EFFECTS_QUALITY.MINIMUM : 
			start_animation = "min"
		Config.EFFECTS_QUALITY.LOW :
			$P1.amount = 4
			$P2.amount = 16
			$P3.amount = 8
		Config.EFFECTS_QUALITY.MEDIUM :
			$P1.amount = 6
			$P2.amount = 32
			$P3.amount = 12
		Config.EFFECTS_QUALITY.HIGH :
			$P1.amount = 7
			$P2.amount = 64
			$P3.amount = 16
		Config.EFFECTS_QUALITY.BEAUTIFUL :
			$P1.amount = 8
			$P2.amount = 96
			$P3.amount = 24
	
	_start()
