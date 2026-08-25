# Project Luminext - an ultimate block-stacking puzzle game
# Copyright (C) <2024-2026> <unfavorable_enhancer>
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

extends PropertyEditor
##
## Allows user to edit passed SkinBlock
##
class_name SEBlockPropertyEditor

const ANIMATION_START_DELAY : float = 3.0 ## Delay before starting block animation again

var block_data : SkinBlockData = null
var asset_data : SkinAssetData = null

var block : SkinBlockData.SkinBlock = null ## Currently editing block object
var block_modifier : SEBlockModifier = null ## Modifies currently editing block object

var anim_timer : Timer = null ## Timer which periodically starts block animation

@onready var id_selector : VariantSelectPropertyEditor = %ID ## Allows to select block type
@onready var anim_sprite_editor : AnimatedTexturePropertyEditor = %AnimTextureEditor ## Allows to edit block animated sprite sheet
@onready var anim_pattern_editor : AnimatedTextureSequencePropertyEditor = %AnimTextureSequenceEditor ## Allows to select music beats on which block animation should play


func _ready() -> void:
	id_selector.set_property_name("Block type:")
	anim_sprite_editor.set_property_name("Block animation frames:")
	anim_sprite_editor.file_browser = file_browser
	anim_pattern_editor.set_property_name("Block animation timing:")


func open_object(new_object : Variant, new_display_viewport : SubViewportContainer, new_object_subtree : EditorSubTree = null, _new_object_display_instance : Node = null) -> void:
	if new_object is not SkinBlockData.SkinBlock : return
	
	block = new_object
	block_modifier = SEBlockModifier.new(block.preset_id, block.id, block.index, block_data)
	block_modifier.undo_manager = undo_manager
	block_modifier.asset_data = asset_data
	block_modifier.id_changed.connect(_update_editor_block_id)
	block_modifier.values_changed.connect(_update_editor_values)
	block_modifier.animation_changed.connect(anim_sprite_editor.show_frames)
	
	display_viewport = new_display_viewport
	object_subtree = new_object_subtree
	
	id_selector.set_variants({
		"Red" : &"red",
		"White" : &"white",
		"Green" : &"green",
		"Purple" : &"purple",
		"Chain" : &"chain",
		"Merge" : &"merge",
		"Wipe" : &"wipe",
		"Column" : &"column",
		"Row" : &"row",
		"Multi" : &"multi",
		"Garbage" : &"garbage", 
		"Dark" : &"dark",
		"Ready" : &"ready",
		"Scan" : &"scan",
		"Erase" : &"erase"
	})
	id_selector.insert(block.id)
	
	_update_editor_values()
	anim_sprite_editor.set_frames(block.sprite_frames)
	
	_display_block()

func _update_editor_values() -> void:
	anim_sprite_editor.set_animation_fps(block.animation_fps)
	anim_sprite_editor.set_animation_loop(block.loop_animation)
	anim_pattern_editor.insert(block.animation_timing)
	
	_set_block_anim_timer()

func _update_editor_block_id() -> void:
	id_selector.insert(block.id)
	
	object_subtree.item_object_to_select = block
	object_subtree.rebuild()


## Puts block object instance inside sub-viewport for display
func _display_block() -> void:
	object_display_instance = AnimatedSprite2D.new()
	anim_timer = $AnimTimer
	@warning_ignore("unsafe_call_argument")
	anim_timer.timeout.connect(object_display_instance.play)
	
	if block.sprite_frames != null : 
		object_display_instance.sprite_frames = block.sprite_frames
		_set_block_anim_timer()
	
	display_viewport.display_object(object_display_instance)

## Setups timer which periodically starts block animation playback
func _set_block_anim_timer() -> void:
	if object_display_instance == null : return
	
	# Check if its looping animation, then we just need to start once and stop timer
	if block.loop_animation :
		anim_timer.stop()
		object_display_instance.play()
		return
	
	var anim_frame_count : int = block.sprite_frames.get_frame_count(&"default")
	var anim_fps : int = block.animation_fps
	
	anim_timer.start(anim_frame_count / anim_fps + ANIMATION_START_DELAY)


func _on_id_selected(variant : Variant) -> void:
	var new_block_id : StringName = variant
	block_modifier.set_id_and_index(new_block_id)

func _on_animation_pattern_changed(index : int, on : bool) -> void:
	block_modifier.set_animation_pattern(index, on)

func _on_animation_loop_changed(new_state: bool) -> void:
	block_modifier.set_animation_loop(new_state)

func _on_animation_fps_changed(new_value: int) -> void:
	block_modifier.set_animation_fps(new_value)

func _on_animation_frames_added(textures_filepaths : PackedStringArray) -> void:
	var texture_asset_uids : Array[StringName]
	for filepath : String in textures_filepaths:
		var texture_asset_uid : StringName = asset_data.insert_texture(filepath)
		if texture_asset_uid.is_empty() : continue
		
		texture_asset_uids.append(texture_asset_uid)
	
	block_modifier.add_animation_frames(texture_asset_uids)

func _on_animation_spritesheet_added(spritesheet_filepath: String) -> void:
	var texture_asset_uids : Array[StringName] = asset_data.insert_spritesheet(spritesheet_filepath)
	if texture_asset_uids.is_empty() : return
	
	block_modifier.add_animation_frames(texture_asset_uids)

func _on_animation_frame_replaced(at: int, texture_filepath: String) -> void:
	var texture_asset_uid : StringName = asset_data.insert_texture(texture_filepath)
	if texture_asset_uid.is_empty() : return
	
	block_modifier.replace_animation_frame(at, texture_asset_uid)

func _on_animation_frame_moved(from: int, to: int) -> void: 
	block_modifier.move_animation_frame(from, to)

func _on_animation_frame_removed(at: int) -> void:
	block_modifier.remove_animation_frame(at)

func _on_animation_all_frames_removed() -> void:
	block_modifier.remove_all_animation_frames()
