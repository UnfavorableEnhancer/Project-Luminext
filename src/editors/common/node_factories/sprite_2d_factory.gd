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


## Constructs [Sprite2D] instance
extends ModdableScene.NodeFactory
class_name Sprite2DFactory

var texture_uid : StringName = &""
var texture : ModdableAsset.TextureAsset = null:
	set(value) : if node : node.texture = value.texture
var texture_offset : Vector2 = Vector2(0,0):
	set(value) : if node : node.offset = value
var position : Vector2 = Vector2(0,0): 
	set(value) : if node : node.position = value
var scale : Vector2 = Vector2(1,1):
	set(value) : if node : node.scale = value
var rotation : float = 0.0:
	set(value) : if node : node.rotation_degrees = value
var skew : float = 0.0:
	set(value) : if node : node.skew = value
var color : Color = Color.WHITE:
	set(value) : if node : node.modulate = value
var layer : int = 0:
	set(value) : if node : node.z_index = value


## Builds node instance. Returns **true** on success.
func build_node() -> bool:
	node = Sprite2D.new()
	node.name = name
	
	if not texture.texture : return false
	
	node.texture = texture.texture
	node.offset = texture_offset
	node.position = position
	node.scale = scale
	node.rotation_degrees = rotation
	node.skew = skew
	node.modulate = color
	node.z_index = layer
	
	return true

## Loads [ModdableAssets] into our node factory from passed asset container (ex. [SkinAssetData]).[br]
## Returns **true** on success.
func load_assets(asset_contaner : RefCounted) -> bool:
	if not "textures" in asset_contaner : return false
	if not asset_contaner.textures.has(texture_uid) : return false
	
	texture = asset_contaner.textures[texture_uid]
	
	return true

## Saves node properties into passed [FileAccess]. Returns error code.
func save(file : FileAccess) -> int:
	return OK

	## Loads node properties from passed [FileAccess]. Returns error code.
func load(file : FileAccess) -> int:
	return OK
