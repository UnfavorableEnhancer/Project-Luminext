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

var anim_timer : Timer = null ## Timer which periodically starts block animation

@onready var id_selector : VariantSelectPropertyEditor = %ID ## Allows to select block type
@onready var anim_sprite_editor : AnimatedTexturePropertyEditor = %AnimTextureEditor ## Allows to edit block animated sprite sheet
@onready var anim_pattern_editor : AnimatedTextureSequencePropertyEditor = %AnimTextureSequenceEditor ## Allows to select music beats on which block animation should play


func _ready() -> void:
	id_selector.set_property_name("Block type:")
	anim_sprite_editor.set_property_name("Block animation frames:")
	anim_sprite_editor.file_browser = file_browser
	anim_pattern_editor.set_property_name("Block animation timing:")


func open_object(new_object : Variant, new_viewport : SubViewportContainer, new_object_tree_item : TreeItem = null) -> void:
	if new_object is not SkinBlockData.SkinBlock : return
	
	block = new_object
	display_viewport = new_viewport
	object_tree_item = new_object_tree_item
	
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
	anim_sprite_editor.set_frames(block.sprite_frames)
	anim_sprite_editor.set_animation_fps(block.animation_fps)
	anim_sprite_editor.set_animation_loop(block.loop_animation)
	anim_pattern_editor.insert(block.animation_timing)
	
	_display_block()

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
	if not block : return
	if block.id == variant : return
	
	block_data.blocks[block.variant_id][block.id].remove_at(block.index)
	
	
	
	block.id = variant
	block.index = block_data.blocks[block.variant_id][variant].size()
	block_data.blocks[block.variant_id][variant].append(block)
	
	object_tree_item.set_text(0, str(variant) + str(block.index + 1))


func _on_animation_pattern_changed(pattern: Array[bool]) -> void:
	block.animation_timing = pattern

func _on_animation_loop_changed(new_state: bool) -> void:
	block.loop_animation = new_state
	_set_block_anim_timer()

func _on_animation_fps_changed(new_value: int) -> void:
	block.animation_fps = new_value
	_set_block_anim_timer()


func _on_animation_frames_added(textures_filepaths : PackedStringArray) -> void:
	for filepath : String in textures_filepaths:
		var texture_asset_uid : StringName = asset_data.insert_texture(filepath)
		if texture_asset_uid.is_empty() : continue
		
		block.frames.append(texture_asset_uid)
		block.sprite_frames.add_frame(&"default", asset_data.textures[texture_asset_uid].texture)
	
	anim_sprite_editor.show_frames()

func _on_animation_spritesheet_added(spritesheet_filepath: String) -> void:
	var texture_asset_uids : Array[StringName] = asset_data.insert_spritesheet(spritesheet_filepath)
	if texture_asset_uids.is_empty() : return
	
	for texture_uid : StringName in texture_asset_uids:
		block.frames.append(texture_uid)
		block.sprite_frames.add_frame(&"default", asset_data.textures[texture_uid].texture)
	
	anim_sprite_editor.show_frames()

func _on_animation_frame_replaced(at: int, texture_filepath: String) -> void:
	var texture_asset_uid : StringName = asset_data.insert_texture(texture_filepath)
	if texture_asset_uid.is_empty() : return
	
	block.frames[at] = texture_asset_uid
	block.sprite_frames.set_frame(&"default", at, asset_data.textures[texture_asset_uid].texture)
	
	anim_sprite_editor.show_frames()

func _on_animation_frame_moved(from: int, to: int) -> void:
	var texture_buff : Texture2D = block.sprite_frames.get_frame_texture(&"default", to)
	var texture_uid_buff : StringName = block.frames[to]
	
	block.sprite_frames.set_frame(&"default", to, block.sprite_frames.get_frame_texture(&"default", from))
	block.sprite_frames.set_frame(&"default", from, texture_buff)
	
	block.frames[to] = block.frames[from]
	block.frames[from] = texture_uid_buff
	
	anim_sprite_editor.show_frames()

func _on_animation_frame_removed(at: int) -> void:
	block.frames.remove_at(at)
	block.sprite_frames.remove_frame(&"default", at)
	
	anim_sprite_editor.show_frames()

func _on_animation_all_frames_removed() -> void:
	block.frames.clear()
	block.sprite_frames.clear(&"default")
	
	anim_sprite_editor.show_frames()
