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

extends Node
##
## Controls editor copy buffer
##
class_name EditorCopyManager

signal copy_requested ## Called when copy action is pressed and requests currently focused node to insert something for copy
signal paste_requested ## Called when paste action is pressed and requests currently focused node to select object to paste
signal cut_requested ## Called when cut action is pressed and requests currently focused node to cut currently selected object

enum COPY_TYPE {
	NUMBER,
	STRING,
	COLOR,
	TEXTURE_UID,
	SOUND_UID,
	VIDEO_UID,
	FONT_UID,
	ANIMATION_UID,
	TREE_ITEM
}

## Holds objects of several types for future paste in some editor node
var copy_buffer : Dictionary[COPY_TYPE, Variant] = {
	COPY_TYPE.NUMBER : null,
	COPY_TYPE.STRING : null,
	COPY_TYPE.COLOR : null,
	COPY_TYPE.TEXTURE_UID : null,
	COPY_TYPE.SOUND_UID : null,
	COPY_TYPE.VIDEO_UID : null,
	COPY_TYPE.FONT_UID : null,
	COPY_TYPE.ANIMATION_UID : null,
	COPY_TYPE.TREE_ITEM : null
}


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_copy"): copy_requested.emit()
	if event.is_action_pressed("ui_paste"): paste_requested.emit()
	if event.is_action_pressed("ui_cut"): cut_requested.emit()


## Inserts passed object into copy buffer if possible
func copy_object(object : Variant) -> bool:
	if object is int or object is float : copy_buffer[COPY_TYPE.NUMBER] = object
	elif object is String : copy_buffer[COPY_TYPE.STRING] = object
	elif object is Color : copy_buffer[COPY_TYPE.COLOR] = object
	
	elif object is StringName :
		match object[0]:
			ModdableAsset.TextureAsset.UID_PREFIX : copy_buffer[COPY_TYPE.TEXTURE_UID] = object
			ModdableAsset.AudioAsset.UID_PREFIX : copy_buffer[COPY_TYPE.SOUND_UID] = object
			ModdableAsset.VideoAsset.UID_PREFIX : copy_buffer[COPY_TYPE.VIDEO_UID] = object
			ModdableAsset.FontAsset.UID_PREFIX : copy_buffer[COPY_TYPE.FONT_UID] = object
	
	elif object is EditorTreeItemMetadata : 
		var item_copy : EditorTreeItemMetadata = object.duplicate()
		if item_copy == null : return false
		copy_buffer[COPY_TYPE.TREE_ITEM] = item_copy
	
	else : return false
	
	return true

## Returns valid object from copy buffer
func get_paste_object(type : COPY_TYPE) -> Variant:
	return copy_buffer[type]

## Inserts passed object into copy buffer if possible and calls callable to remove original object on success
func cut_object(delete_callable : Callable, object : Variant) -> bool:
	if not copy_object(object) : return false
	
	delete_callable.call()
	return true
