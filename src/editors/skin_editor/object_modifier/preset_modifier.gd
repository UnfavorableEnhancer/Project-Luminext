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


##
## Contains all functions to edit preset instance from any skin data sub-structure, identified by passed preset ID
##
class_name SEPresetModifier

signal id_changed

var preset_id : String = &"none"

var skin_sub_data : RefCounted = null ## Skin sub data structure which is related to currently editing preset
var undo_manager : EditorHistoryManager = null


func _init(new_preset_id : String, new_skin_sub_data : RefCounted) -> void:
	preset_id = new_preset_id
	skin_sub_data = new_skin_sub_data

## Returns currently active block instance at current preset ID, ID and index.
func _find_preset() -> RefCounted:
	if skin_sub_data is SkinBlockData : return skin_sub_data.blocks_presets[preset_id]
	
	return null


## Changes preset ID and properly updates all of its children.
func set_id(new_id : StringName) -> void:
	var preset : RefCounted = _find_preset()
	
	if preset is SkinBlockData.SkinBlockPreset:
		if preset.id == new_id : return
		
		undo_manager.track(
			self,
			set_id.bind(preset.id),
			set_id.bind(new_id)
		)
		
		skin_sub_data.blocks_presets[new_id] = skin_sub_data.blocks_presets[preset.id]
		skin_sub_data.blocks_presets.erase(preset.id)
		preset.id = new_id
		preset_id = new_id
		
		var blocks_arrays : Array = preset.blocks.values()
		for blocks_array : Array in blocks_arrays:
			for block : SkinBlockData.SkinBlock in blocks_array:
				block.preset_id = new_id
		
		id_changed.emit()
