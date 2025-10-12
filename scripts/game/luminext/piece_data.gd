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


extends Node2D

##-----------------------------------------------------------------------
## Contains piece blocks and does piece generation work
##-----------------------------------------------------------------------

class_name PieceData

var game : LuminextGame ## Game instance
var ruleset : Ruleset ## Ruleset instance

## All blocks inside piece [br]
## [Vector2i] :[block_color (int), block_special (StringName)]
var blocks : Dictionary[Vector2i, Array] = {} 

var special_chance : float = 0.25 ## Chance of special block to appear in of 4 blocks of single piece


func _ready() -> void:
	if not blocks.is_empty() : _render()


func _clone() -> PieceData:
	var clone_piece : PieceData = PieceData.new()
	clone_piece.blocks = blocks
	clone_piece.ruleset = ruleset
	
	return clone_piece


## Displays all blocks inside piece
func _render() -> void:
	z_index = 1

	for i : Node in get_children() : i.queue_free()

	for block_pos : Vector2i in blocks.keys():
		var block : BlockBase = BlockBase.new()
		
		block.color = blocks[block_pos][0]
		block.special = blocks[block_pos][1]
		block.position = Vector2(-34 + 68 * block_pos.x, -34 + 68 * block_pos.y)
		block.is_trail_enabled = false
		
		block.game = game
		block.ruleset = ruleset

		add_child(block)


## Generates random blocks pattern for this piece
func _generate(special : bool = false) -> void:
	special_chance = 0.25

	for block_pos : Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
		var generated_block_data : Array = _make_block_type_and_special(special)
		blocks[block_pos] = generated_block_data
	
	_render()


## Returns randomized block color and special [br]
## If **'do_special'** is true, tries to generate special for this block
func _make_block_type_and_special(do_special : bool = false) -> Array:
	var block_color : int = 0
	var block_special : StringName = ""
	
	var colors : Array[int] = []
	if ruleset.blocks["red"] : colors.append(BlockBase.BLOCK_COLOR.RED)
	if ruleset.blocks["white"] : colors.append(BlockBase.BLOCK_COLOR.WHITE)
	if ruleset.blocks["green"] : colors.append(BlockBase.BLOCK_COLOR.GREEN)
	if ruleset.blocks["purple"] : colors.append(BlockBase.BLOCK_COLOR.PURPLE)
	
	var random : float = game.rng.randf()
	block_color = colors[roundi(random * (colors.size() - 1))]
	
	if ruleset.blocks["garbage"] and random > 0.85 : return [BlockBase.BLOCK_COLOR.GARBAGE,""]
	if ruleset.blocks["multi"] and random > 0.65 : return [BlockBase.BLOCK_COLOR.MULTI,""]
	if ruleset.blocks["joker"] and random > 0.50 : return [block_color,&"joker"]
	
	if do_special and special_chance < 40.0:
		if random > special_chance:
			special_chance += 0.25
			return[block_color,""]

		# Make high special chance so only one special block appears in piece
		special_chance = 42.0

		var specials : Array[StringName] = []
		if ruleset.blocks["chain"] : specials.append(&"chain")
		if ruleset.blocks["merge"] : specials.append(&"merge")
		if ruleset.blocks["laser"] : specials.append(&"laser")
		if ruleset.blocks["wipe"] : specials.append(&"wipe")
		
		if specials.is_empty(): return [block_color,""]
		block_special = specials[roundi(random * (specials.size() - 1))]

	return [block_color,block_special]
