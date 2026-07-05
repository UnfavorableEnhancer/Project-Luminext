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


## Container for [TreeItem] metadata.[br]
## type - One of [SkinEditorTree.ITEM_TYPE];[br]
## owner - [TreeItem] which holds this metadata;[br]
## parent_subtree - [SubTree] in which parent [TreeItem] exists;[br]
## object - Some variable or object this metadata can contain
class_name EditorTreeItemMetadata

var type : int ## Type of this ItemTree (defined by editor tree)
var owner : TreeItem ## Owner ItemTree instance
var parent_subtree : EditorSubTree ## Parent [SubTree]
var object : Variant ## Object this item represents

func _init(input_type : int, input_subtree : EditorSubTree, input_object : Variant) -> void:
	type = input_type
	parent_subtree = input_subtree
	object = input_object

## Returns correct copy of this ItemMetadata
func duplicate() -> EditorTreeItemMetadata:
	if type == 0 : return null
	
	var copy : EditorTreeItemMetadata = EditorTreeItemMetadata.new(type, parent_subtree, null)
	copy.owner = null
	if object.has_method(&"duplicate") : copy.object = object.duplicate() # TODO : Implement duplicate for all ModdableAssets
	
	return copy
