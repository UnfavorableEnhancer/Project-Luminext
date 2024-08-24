extends Block

# Merge special block turns all blocks around into same color when activated

class_name Merge

var merged : bool = false


func _ready() -> void:
	super()
	
	falled_down.connect(_on_fall)
	squared.connect(_squared)


func _on_fall() -> void:
	await get_tree().create_timer(0.01).timeout
	# If we're just silly remastered clone, do work immidiately
	if Data.profile.config["gameplay"]["instant_special"] : _squared()


# Called when merge block is squared
func _squared() -> void:
	if not merged:
		merged = true
		# When squared, turn everyone same color
		for x : int in range(grid_position.x - 2,grid_position.x + 3):
			for y : int in range(grid_position.y - 2, grid_position.y + 3):
				if Data.game.blocks.has(Vector2i(x,y)):
					var block : Block = Data.game.blocks[Vector2i(x,y)]
					if block.is_dying : continue
					if block.is_scanned : continue

					if block.color != color:
						block.color = color
						block._render()
		
		Data.game._add_fx("merge", grid_position, color)
		
		# Remove special gem from self
		$Special.queue_free()
		
		await get_tree().create_timer(0.01).timeout
		Data.game._square_check(-1)

