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
## Contains all GUI modifiers which changes some aspects (textures, fonts, positions) of game GUI.
##
class_name SkinGUIData

signal current_gui_modifiers_changed ## Emitted when current GUI modifiers set is updated

## All avaiable GUI modifiers.[br]
## Each array can store multiple GUI modifiers under same UID, but they all must have different **segment ID**.
var gui_modifiers : Dictionary[StringName, Array] = {
	&"header_score" : [], # Score counter header (only texture can be modified)
	&"counter_score" : [], # Score counter (only font and color can be modified)
	&"header_hiscore" : [], # Hi-Score counter header (only texture can be modified)
	&"counter_hiscore" : [], # Hi-Score counter (only font and color can be modified)
	&"header_time" : [], # Time counter header (only texture can be modified)
	&"counter_time" : [], # Time counter (only font and color can be modified)
	&"header_level" : [], # Level counter header (only texture can be modified)
	&"counter_level" : [], # Level counter (only font and color can be modified)
	&"header_deleted" : [], # Deleted counter header (only texture can be modified)
	&"counter_deleted" : [], # Deleted counter (only font and color can be modified)
	&"luminext_board" : [], # Luminext base board, where blocks, squares and timeline are shown
	&"luminext_piece_queue" : [], # Luminext piece queue, which shows next pieces in queue
	&"luminext_piece_holder" : [], # Luminext piece holder, which holds current piece
	&"luminext_audio_visualizer" : [], # Luminext audio visualizer, which reacts to all audio playing
	&"luminext_timeline" : [], # Luminext timeline header
	&"luminext_timeline_bar" : [], # Luminext timeline bar
	&"luminext_4x_bonus_popup" : [], # Luminext 4x bonus results popup
	&"luminext_square_num_popup" : [], # Luminext square amount number popup (only font and color can be modified)
	&"luminext_score_inc_popup" : [] # Luminext score increase number popup (only font and color can be modified)
}

## All used in current sequence segment blocks.
var current_gui_modifiers : Dictionary[StringName, SkinGUIModifier] = {
	&"header_score" : null,
	&"counter_score" : null,
	&"header_hiscore" : null,
	&"counter_hiscore" : null,
	&"header_time" : null,
	&"counter_time" : null,
	&"header_level" : null,
	&"counter_level" : null,
	&"header_deleted" : null,
	&"counter_deleted" : null,
	&"luminext_board" : null,
	&"luminext_piece_queue" : null,
	&"luminext_piece_holder" : null,
	&"luminext_audio_visualizer" : null,
	&"luminext_timeline" : null,
	&"luminext_timeline_bar" : null,
	&"luminext_4x_bonus_popup" : null,
	&"luminext_square_num_popup" : null,
	&"luminext_score_inc_popup" : null
}


## Loads GUI modifiers data from passed FileAccess, which has valid skin file opened
func load(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Saves GUI modifiers data to passed FileAccess, which has valid skin file opened
func save(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK


## Loads all GUI modifiers with assets from passed [SkinAssetData]
func load_assets(asset_data : SkinAssetData) -> void:
	for gui_modifiers_array : Array in gui_modifiers.values():
		for gui_modifier : SkinGUIModifier in gui_modifiers_array:
			gui_modifier.load_assets(asset_data)


## Called by [SkinSequenceData] when segment changes, so current GUI modifiers would be switched with GUI modifiers prepared for specified segment.
func select_segment(segment_id : int) -> void:
	for uid : String in gui_modifiers.keys():
		for gui_modifier : SkinGUIModifier in gui_modifiers[uid]:
			if gui_modifier.segment_id == segment_id:
				current_gui_modifiers[uid] = gui_modifier
	
	current_gui_modifiers_changed.emit()


class SkinGUIModifier:
	var uid : StringName = &"none" ## Unique ID used by certain GUI element to modify itself
	var segment_id : int = 0 ## Skin sequence segment on which this GUI modifier will be used
	
	var texture : ModdableAsset.TextureAsset = null ## GUI element texture asset
	var texture_uid : StringName = &"" ## GUI element texture asset uid
	
	var font : ModdableAsset.FontAsset = null ## GUI element font asset
	var font_uid : StringName = &"" ## GUI element font asset uid
	
	var font_shadow_color : Color = Color.BLACK ## GUI element text shadow color
	var font_shadow_offset : Vector2 = Vector2(0,0) ## GUI element text shadow offset
	
	var color : Color = Color.WHITE ## GUI element color
	
	var position_offset : Vector2 = Vector2(0,0) ## Offset from GUI element standard position
	var rotation : float = 0.0 ## GUI element rotation in degrees
	var scale : Vector2 = Vector2(1,1) ## GUI element scale


	## Copies all needed [AudioAsset] from passed [SkinAssetData]
	func load_assets(asset_data : SkinAssetData) -> void:
		if not asset_data.textures.has(texture_uid) : return
		if not asset_data.fonts.has(font_uid) : return
		
		texture = asset_data.textures[texture_uid]
		font = asset_data.fonts[font_uid]


	## Loads GUI modifier data from passed FileAccess, which has valid skin file opened
	func load(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK


	## Saves GUI modifier data to passed FileAccess, which has valid skin file opened
	func save(file : FileAccess) -> SkinConsts.IO_ERROR:
		return SkinConsts.IO_ERROR.OK
