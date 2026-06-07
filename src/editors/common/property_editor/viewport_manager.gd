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

extends Control
##
## Controls display of currently editing objects
##
class_name EditorViewportManager

enum VIEWPORT_TYPE {
	NONE,
	SKIN_OBJECT_DISPLAY,
	SKIN_SCENE_DISPLAY,
	AVATAR_DISPLAY
}

var viewports : Dictionary[VIEWPORT_TYPE, Node] = {
	VIEWPORT_TYPE.SKIN_OBJECT_DISPLAY : null,
	VIEWPORT_TYPE.SKIN_SCENE_DISPLAY : null,
	VIEWPORT_TYPE.AVATAR_DISPLAY : null, # NOTE : Avatar display is probably gonna be regular node
}

var currently_opened_viewport : Node = null

func _ready() -> void:
	for node : Node in get_children():
		if node is SEObjectWindow : viewports[VIEWPORT_TYPE.SKIN_OBJECT_DISPLAY] = node
		#elif node is SkinPlayer : viewports[VIEWPORT_TYPE.SKIN_SCENE_DISPLAY] = node
		#elif node is AvatarPlayer : viewports[VIEWPORT_TYPE.SKIN_SCENE_DISPLAY] = node


## Checks object type and returns viewport where it should be shown
func get_display_viewport_for_object(object : Variant) -> SubViewportContainer:
	if currently_opened_viewport:
		currently_opened_viewport.visible = false
		currently_opened_viewport = null
	
	if object is SkinBlockData.SkinBlock : currently_opened_viewport = viewports[VIEWPORT_TYPE.SKIN_OBJECT_DISPLAY]
	else : return null
	
	currently_opened_viewport.visible = true
	return currently_opened_viewport
