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
## Describes a Godot scene tree structure in own format, 
## with allows only selected nodes and properties to save, load and modify.[br]
## Stores scene in simplier than TSCN format and is safe for use in modding.
##
class_name ModdableScene

enum NODE_TYPE {
	Base,
	Sprite,
	AnimatedSprite,
	Particles,
	VideoPlayer,
	Rect,
	Text
}

## Contains full scene tree, which is built from our nodes factories UID's.[br]
## Each factory UID has a dictionary as a value to put their children factories UID's into.
var scene_tree : Dictionary[StringName, Dictionary] = {
	# node_factory_uid : { node_factory_uid : { ... } }
}

## Contains all node factories used by **scene_tree** as UID - factory pairs.
var node_factories : Dictionary[StringName, NodeFactory] = {
	# node_factory_uid : node_factory_instance
}


## Loads [ModdableAssets] into all scene tree node factories from passed asset container (ex. [SkinAssetData])[br]
## Returns true on success.
func load_assets(asset_contaner : RefCounted) -> bool:
	for factory : NodeFactory in node_factories.values():
		if not factory.load_assets(asset_contaner) : return false
	
	return true


## Builds full scene tree using all factories inside of it.[br]
## Returns true on success.
func build() -> bool:
	for node : Node in get_children() : node.queue_free()
	for factory : NodeFactory in node_factories.values():
		if not factory.build_node() : return false
	
	var tree_build_func : Callable 
	tree_build_func = func(root_node : Node, node_leafs : Dictionary[StringName, Dictionary]) -> bool:
		for node_factory_uid : StringName in node_leafs.keys():
			if not node_factories.has(node_factory_uid) : return false
			
			var leaf_node : Node = node_factories[node_factory_uid].node
			root_node.add_child(leaf_node)
			if not node_leafs[node_factory_uid].is_empty() : 
				if not (tree_build_func.call(leaf_node, node_leafs[node_factory_uid])) : 
					return false
		
		return true
	
	return tree_build_func.call(self, scene_tree)


## Loads scenery data from passed [FileAccess]. Returns OK on success or ERROR.
func load(file : FileAccess) -> int:
	return OK


## Saves scenery data to passed [FileAccess]. Returns OK on success or ERROR.
func save(file : FileAccess) -> int:
	return OK


@abstract class NodeFactory:
	var uid : StringName
	var node : Node
	var name : String
	
	## Builds node instance from loaded properties. Returns **true** on success.
	@abstract func build_node() -> bool
	
	## Loads [ModdableAssets] into our node factory from passed asset container (ex. [SkinAssetData]). [br]
	## Returns **true** on success.
	@abstract func load_assets(asset_contaner : RefCounted) -> bool
	
	## Saves node properties into passed [FileAccess]. Returns error code.
	@abstract func save(file : FileAccess) -> int
	
	## Loads node properties from passed [FileAccess]. Returns error code.
	@abstract func load(file : FileAccess) -> int
