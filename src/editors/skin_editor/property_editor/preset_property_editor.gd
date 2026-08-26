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
class_name SEPresetPropertyEditor

const ANIMATION_START_DELAY : float = 3.0 ## Delay before starting block animation again
const OBJECT_PREVIEW_ROW_SIZE : int = 5 ## How many preview objects of currently editing preset to show in single row

var block_data : SkinBlockData = null
var sfx_data : SkinSFXData = null
var effect_data : SkinEffectData = null
var gui_data : SkinGUIData = null

var preset : RefCounted = null ## Currently editing preset object
var preset_modifier : SEPresetModifier = null ## Modifies currently editing preset object

@onready var anim_timer : Timer = $AnimTimer ## Timer which periodically starts block animation
@onready var preset_id_edit : StringPropertyEditor = %PresetName ## Allows to edit preset ID


func _ready() -> void:
	preset_id_edit.set_label_text("Preset name:")


func open_object(new_object : Variant, new_display_viewport : SubViewportContainer, new_object_subtree : EditorSubTree = null, _new_object_display_instance : Node = null) -> void:
	if new_object is not SkinBlockData.SkinBlockPreset : return
	preset = new_object
	
	@warning_ignore("unsafe_call_argument")
	preset_modifier = SEPresetModifier.new(preset.id, block_data)
	preset_modifier.undo_manager = undo_manager
	preset_modifier.id_changed.connect(_update_editor_preset_id)
	
	display_viewport = new_display_viewport
	object_subtree = new_object_subtree
	
	@warning_ignore("unsafe_call_argument")
	preset_id_edit.set_value(preset.id)
	_display_objects()

func _update_editor_preset_id() -> void:
	@warning_ignore("unsafe_call_argument")
	preset_id_edit.set_value(preset.id)
	
	object_subtree.item_object_to_select = preset
	object_subtree.rebuild()


## Puts objects from this preset inside sub-viewport for display and comparison
func _display_objects() -> void:
	var current_preview_column : int = 0
	var current_preview_row : int = 0
	
	if preset is SkinBlockData.SkinBlockPreset:
		var base_node : Node2D = Node2D.new()
		
		var blocks_arrays : Array = preset.blocks.values()
		for blocks_array : Array in blocks_arrays:
			for block : SkinBlockData.SkinBlock in blocks_array:
				if block.sprite_frames == null : continue
				
				var block_sprite : AnimatedSprite2D = AnimatedSprite2D.new()
				@warning_ignore("unsafe_call_argument")
				anim_timer.timeout.connect(block_sprite.play)
				block_sprite.sprite_frames = block.sprite_frames
				block_sprite.position = Vector2(64 * current_preview_column, 64 * current_preview_row)
				
				current_preview_column += 1
				if current_preview_column == OBJECT_PREVIEW_ROW_SIZE:
					current_preview_column = 0
					current_preview_row += 1
				
				base_node.add_child(block_sprite)
		
		anim_timer.start(ANIMATION_START_DELAY)
		object_display_instance = base_node
		display_viewport.display_object(base_node)


func _on_preset_id_changed(new_id : String) -> void:
	preset_modifier.set_id(new_id)
