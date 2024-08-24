extends Node2D

class_name PieceData

#-----------------------------------------------------------------------
# Piece data class
# Contains piece blocks and does piece generation work
#-----------------------------------------------------------------------

# All blocks inside piece
var blocks : Dictionary = {
#	Vector2i : [block_color, block_special]
} 

var special_chance : float = 0.25 # Used for special block randomization


# Visualizes piece contents (used in piece queue)
func _render() -> void:
	z_index = 1

	for block_pos : Vector2i in blocks.keys():
		var block : BlockBase = BlockBase.new()
		block.color = blocks[block_pos][0]
		block.special = blocks[block_pos][1]
		block.position = Vector2(-34 + 68 * block_pos.x, -34 + 68 * block_pos.y)
		block.is_trail_enabled = false
		add_child(block)
		block._render()


# Generates random block pattern for supported piece type
func _generate(special : bool = false) -> void:
	special_chance = 0.25

	for block_pos : Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
		var generated_block_data : Array = _make_block_type_and_special(special)
		blocks[block_pos] = generated_block_data


# Returns randomized block color and special
func _make_block_type_and_special(do_special : bool = false) -> Array:
	var block_color : int = BlockBase.BLOCK_COLOR.NULL
	var block_special : StringName = ""
	
	var colors : Array[int] = []
	if Data.profile.config["gameplay"]["red"] : colors.append(BlockBase.BLOCK_COLOR.RED)
	if Data.profile.config["gameplay"]["white"] : colors.append(BlockBase.BLOCK_COLOR.WHITE)
	if Data.profile.config["gameplay"]["green"] : colors.append(BlockBase.BLOCK_COLOR.GREEN)
	if Data.profile.config["gameplay"]["purple"] : colors.append(BlockBase.BLOCK_COLOR.PURPLE)
	
	var random : float = Data.game.rng.randf()
	block_color = colors[round(random * colors.size() - 1)]
	
	if Data.profile.config["gameplay"]["garbage"] and random > 0.85:
		return [BlockBase.BLOCK_COLOR.GARBAGE,""]
	if Data.profile.config["gameplay"]["multi"] and random > 0.85:
		return [BlockBase.BLOCK_COLOR.MULTI,""]
	if Data.profile.config["gameplay"]["joker"] and random > 0.75:
		return [block_color,&"joker"]
	
	if do_special and special_chance < 40.0:
		if random > special_chance:
			special_chance += 0.25
			return[block_color,""]

		# Make high special chance so only one special block appears in piece
		special_chance = 42.0

		var specials : Array[StringName] = []
		if Data.profile.config["gameplay"]["chain"] : specials.append(&"chain")
		if Data.profile.config["gameplay"]["merge"] : specials.append(&"merge")
		if Data.profile.config["gameplay"]["laser"] : specials.append(&"laser")
		if Data.profile.config["gameplay"]["wipe"] : specials.append(&"wipe")
		
		if specials.is_empty(): return [block_color,""]
		block_special = specials[round(random * specials.size() - 1)]

	return [block_color,block_special]
