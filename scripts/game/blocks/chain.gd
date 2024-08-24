extends Block

# Chain special block "chains" all adjacent same colored blocks, making them deletable by timeline

class_name Chain

const CHAIN_DELAY : float = 0.2

var chained : Array = [] # Blocks chained by this chain block
var checked : Array = [] # Blocks which already were checked by current check cycle

var chain_timer : Timer = null # Timer which calls 'chaining' function

var is_working : bool = false


func _ready() -> void:
	super()
	
	reset.connect(_chain_reset)
	squared.connect(_squared)
	falled_down.connect(_on_fall)


func _on_fall() -> void:
	await get_tree().create_timer(0.01).timeout
	# If we're just silly remastered clone, do work immidiately
	if Data.profile.config["gameplay"]["instant_special"] : _squared()


# Resets chain block, and 'unchain' all chained blocks
func _chain_reset() -> void:
	if is_working:
		is_working = false
		
		if chain_timer != null:
			chain_timer.queue_free()
			chain_timer = null
		
		for block : Block in chained:
			if is_instance_valid(block): block._reset(false)
		
		chained.clear()


# Called when block is deleted
func _free() -> void:
	_chain_reset()
	super()


# Called when chain block is squared
func _squared() -> void:
	if not is_working:
		is_working = true
		
		chain_timer = Timer.new()
		chain_timer.timeout.connect(_start_chain)
		add_child(chain_timer)
		chain_timer.start(CHAIN_DELAY)


# Called by chain timer
func _start_chain() -> void:
	# We clear "chained" each cycle because when field changes much, we can't be sure are blocks adjacent anymore
	chained.clear()
	_chain(self, color)


# Chains adjacent blocks, making them deletable
func _chain(block : BlockBase, with_color : int = color) -> void:
	# Search for same-colored adjacent blocks, from this block position
	for side : int in [SIDE.LEFT,SIDE.DOWN,SIDE.UP,SIDE.RIGHT]:
		var adj_block : Block = block._find_block(side)
		
		if adj_block == null: continue
		if adj_block.is_falling : continue
		if adj_block is Joker: continue
		if adj_block.color != with_color: continue
		
		if not adj_block in chained:
			chained.append(adj_block)
			adj_block._add_mark(OVERLAY_MARK.DELETE)
			adj_block._make_deletable()
			_chain(adj_block, with_color)
