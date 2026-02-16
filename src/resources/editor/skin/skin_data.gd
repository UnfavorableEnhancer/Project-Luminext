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


extends Resource
##
## Contains all data related to skin - an animated background with set music sequence and gameplay visuals.[br]
## Can be passed to [SkinPlayer] in order to be played or edited by user in [SkinEditor].[br]
## Skin is stored in ".skn" formatted file.
##
class_name SkinData

signal io_finished ## Emitted when skin loading/saving is finished
signal io_stage(stage : SkinConsts.IO_STAGE) ## Emitted when skin loading/saving stage changes

var version : int = SkinConsts.VERSION ## Current skin data version
var latest_error : SkinConsts.IO_ERROR = SkinConsts.IO_ERROR.OK ## Latest loading/saving error

var metadata : SkinMetadata = SkinMetadata.new() ## Contains skin name, artist, BPM and other frontend info
var assets : SkinAssetData = SkinAssetData.new() ## Contains skin textures, audio streams and other assets
var animations : SkinAnimationData = SkinAnimationData.new() ## Contains animations for skin scene, effects and other objects
var scene : SkinSceneData = SkinSceneData.new() ## Contains skin background scenery
var sequence : SkinSequenceData = SkinSequenceData.new() ## Contains skin playback sequence
var blocks : SkinBlockData = SkinBlockData.new() ## Contains skin blocks data
var sfx : SkinSFXData = SkinSFXData.new() ## Contains skin sound effects
var effects : SkinEffectData = SkinEffectData.new()  ## Contains skin visual effects
var gui : SkinGUIData = SkinGUIData.new() ## Contains skin GUI modifiers


## Loads skin from "skn" formatted file
func load_from_path(path : String) -> void:
	Console.log.call_deferred("Loading skin file with path : " + path)
	io_stage.emit.call_deferred(SkinConsts.IO_STAGE.STARTED)
	
	var file : FileAccess = FileAccess.open_compressed(path, FileAccess.READ, SkinConsts.FILE_COMPRESSION)
	if not file:
		Console.error.call_deferred("Skin file opening failed : " + error_string(FileAccess.get_open_error()))
		latest_error = SkinConsts.IO_ERROR.FILE_ERROR
		io_finished.emit.call_deferred()
		return
	
	var skin_version : int = file.get_8()
	if skin_version <= SkinConsts.DEPRECATED_VERSION:
		Console.error.call_deferred("Deprecated skin version")
		file.close()
		latest_error = SkinConsts.IO_ERROR.DEPRECATED_VERSION
		io_finished.emit.call_deferred()
		return
	if skin_version == SkinConsts.LEGACY_VERSION:
		Console.log.call_deferred("Legacy version skin. Converting...")
		load_legacy_version_skin(file)
		return
	
	for stage : SkinConsts.IO_STAGE in SkinConsts.IO_STAGE:
		var object_to_load : Variant
		match stage:
			SkinConsts.IO_STAGE.STARTED, SkinConsts.IO_STAGE.FINISHED : continue
			SkinConsts.IO_STAGE.METADATA : object_to_load = metadata
			SkinConsts.IO_STAGE.ASSETS : object_to_load = assets
			SkinConsts.IO_STAGE.ANIMATIONS : object_to_load = animations
			SkinConsts.IO_STAGE.SCENE : object_to_load = scene
			SkinConsts.IO_STAGE.SEQUENCE : object_to_load = sequence
			SkinConsts.IO_STAGE.BLOCKS : object_to_load = blocks
			SkinConsts.IO_STAGE.SFX : object_to_load = sfx
			SkinConsts.IO_STAGE.EFFECTS : object_to_load = effects
			SkinConsts.IO_STAGE.GUI  : object_to_load = gui
	
		io_stage.emit.call_deferred(stage)
		latest_error = object_to_load.load(file)
		if (latest_error != SkinConsts.IO_ERROR.OK):
			file.close()
			io_finished.emit.call_deferred()
			return
	
	metadata.skin_filepath = path
	
	Console.log.call_deferred("Skin loading finished!")
	io_stage.emit.call_deferred(SkinConsts.IO_STAGE.FINISHED)
	latest_error = SkinConsts.IO_ERROR.OK
	io_finished.emit.call_deferred()


## Saves skin to "skn" formatted file
func save_to_file(path : String) -> void:
	Console.log.call_deferred("Saving skin file to path : " + path)
	io_stage.emit.call_deferred(SkinConsts.IO_STAGE.STARTED)
	
	var file : FileAccess = FileAccess.open_compressed(path, FileAccess.WRITE, SkinConsts.FILE_COMPRESSION)
	if not file:
		Console.error.call_deferred("Skin file opening failed : " + error_string(FileAccess.get_open_error()))
		latest_error = SkinConsts.IO_ERROR.FILE_ERROR
		io_finished.emit.call_deferred()
		return
	
	if (not file.store_8(SkinConsts.VERSION)):
		Console.error.call_deferred("Version write failed : " + error_string(FileAccess.get_open_error()))
		latest_error = SkinConsts.IO_ERROR.VERSION_WRITE_FAILURE
		io_finished.emit.call_deferred()
		return
	
	for stage : SkinConsts.IO_STAGE in SkinConsts.IO_STAGE:
		var object_to_save : Variant
		match stage:
			SkinConsts.IO_STAGE.STARTED, SkinConsts.IO_STAGE.FINISHED : continue
			SkinConsts.IO_STAGE.METADATA : object_to_save = metadata
			SkinConsts.IO_STAGE.ASSETS : object_to_save = assets
			SkinConsts.IO_STAGE.ANIMATIONS : object_to_save = animations
			SkinConsts.IO_STAGE.SCENE : object_to_save = scene
			SkinConsts.IO_STAGE.SEQUENCE : object_to_save = sequence
			SkinConsts.IO_STAGE.BLOCKS : object_to_save = blocks
			SkinConsts.IO_STAGE.SFX : object_to_save = sfx
			SkinConsts.IO_STAGE.EFFECTS : object_to_save = effects
			SkinConsts.IO_STAGE.GUI  : object_to_save = gui
	
		io_stage.emit.call_deferred(stage)
		latest_error = object_to_save.save(file)
		if (latest_error != SkinConsts.IO_ERROR.OK):
			file.close()
			io_finished.emit.call_deferred()
			return
	
	Console.log.call_deferred("Skin saving finished!")
	io_stage.emit.call_deferred(SkinConsts.IO_STAGE.FINISHED)
	latest_error = SkinConsts.IO_ERROR.OK
	io_finished.emit.call_deferred()


## Loads skin from Project Luminext "legacy" versions (skn file version 7) # TODO
func load_legacy_version_skin(file : FileAccess) -> void:
	pass


## Loads and returns SkinMetadata from passed file path.[br]Returns **null** on loading failure.
static func get_metadata_from_file(path : String) -> SkinMetadata:
	var output_metadata : SkinMetadata = SkinMetadata.new()
	
	var file : FileAccess = FileAccess.open_compressed(path, FileAccess.READ, SkinConsts.FILE_COMPRESSION)
	if not file:
		Console.error.call_deferred("Skin file opening failed : " + error_string(FileAccess.get_open_error()))
		return null
	
	var skin_version : int = file.get_8()
	if skin_version < 7:
		Console.log.call_deferred("Deprecated skin version")
		file.close()
		return null
	
	output_metadata.load(file) # TODO : Catch IO_ERROR from sub datas instead of bool
	
	return output_metadata
