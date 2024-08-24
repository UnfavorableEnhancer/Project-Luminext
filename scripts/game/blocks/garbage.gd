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
