extends Resource
class_name SkinData

const VERSION : int = 20 ## Format version
const COMPRESSION : FileAccess.CompressionMode = FileAccess.CompressionMode.COMPRESSION_ZSTD ## File compression algorythm

## Enum of skin data states
enum STATE {
	NONE,
	LOADING,
	SAVING
}

## Enum of loading/saving stages
enum IO_STAGE {
	STARTED,
	METADATA,
	ASSETS,
	ANIMATIONS,
	SCENE,
	SEQUENCE,
	BLOCKS,
	SFX,
	EFFECTS,
	GUI,
	FINISHED
}

## Enum of all possible skin loading/saving errors
enum IO_ERROR {
	OK,
	FILE_ERROR,
	DEPRECATED_VERSION,
	VERSION_WRITE_FAILURE,
	NO_METADATA
}

signal io_finished ## Emitted when skin loading/saving is finished
signal io_stage(stage : IO_STAGE) ## Emitted when skin loading/saving stage changes

var latest_error : IO_ERROR = IO_ERROR.OK ## Latest loading/saving error

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
	io_stage.emit.call_deferred(IO_STAGE.STARTED)
	
	var file : FileAccess = FileAccess.open_compressed(path, FileAccess.READ, COMPRESSION)
	if not file:
		Console.error.call_deferred("Skin file opening failed : " + error_string(FileAccess.get_open_error()))
		latest_error = IO_ERROR.FILE_ERROR
		io_finished.emit.call_deferred()
		return
	
	var skin_version : int = file.get_8()
	if skin_version < 7:
		Console.error.call_deferred("Deprecated skin version")
		file.close()
		latest_error = IO_ERROR.DEPRECATED_VERSION
		io_finished.emit.call_deferred()
		return
	if skin_version == 8 or skin_version == 9:
		Console.log.call_deferred("Legacy versions skin. Converting...")
		load_legacy_version_skin(file)
		return
	
	for stage : IO_STAGE in IO_STAGE:
		var object_to_load : Variant
		match stage:
			IO_STAGE.STARTED, IO_STAGE.FINISHED : continue
			IO_STAGE.METADATA : object_to_load = metadata; Console.log.call_deferred("Loading skin metadata...")
			IO_STAGE.ASSETS : object_to_load = assets; Console.log.call_deferred("Loading skin assets...")
			IO_STAGE.ANIMATIONS : object_to_load = animations; Console.log.call_deferred("Loading skin animations...")
			IO_STAGE.SCENE : object_to_load = scene; Console.log.call_deferred("Loading skin background scenery...")
			IO_STAGE.SEQUENCE : object_to_load = sequence; Console.log.call_deferred("Loading skin playback sequence...")
			IO_STAGE.BLOCKS : object_to_load = blocks; Console.log.call_deferred("Loading skin blocks...")
			IO_STAGE.SFX : object_to_load = sfx; Console.log.call_deferred("Loading skin sfx...")
			IO_STAGE.EFFECTS : object_to_load = effects; Console.log.call_deferred("Loading skin effects...")
			IO_STAGE.GUI  : object_to_load = gui; Console.log.call_deferred("Loading skin gui modifiers...")
	
		io_stage.emit.call_deferred(stage)
		@warning_ignore("unsafe_method_access")
		if (not object_to_load.load(file)):
			file.close()
			latest_error = IO_ERROR.DEPRECATED_VERSION # TODO : Catch IO_ERROR from sub datas instead of bool
			io_finished.emit.call_deferred()
			return
	
	metadata.skin_filepath = path
	
	Console.log.call_deferred("Skin loading finished!")
	io_stage.emit.call_deferred(IO_STAGE.FINISHED)
	latest_error = IO_ERROR.OK
	io_finished.emit.call_deferred()


## Saves skin to "skn" formatted file
func save_to_file(path : String) -> void:
	Console.log.call_deferred("Saving skin file to path : " + path)
	io_stage.emit.call_deferred(IO_STAGE.STARTED)
	
	var file : FileAccess = FileAccess.open_compressed(path, FileAccess.WRITE, COMPRESSION)
	if not file:
		Console.error.call_deferred("Skin file opening failed : " + error_string(FileAccess.get_open_error()))
		latest_error = IO_ERROR.FILE_ERROR
		io_finished.emit.call_deferred()
		return
	
	if (not file.store_8(VERSION)):
		Console.error.call_deferred("Version write failed : " + error_string(FileAccess.get_open_error()))
		latest_error = IO_ERROR.VERSION_WRITE_FAILURE
		io_finished.emit.call_deferred()
		return
	
	for stage : IO_STAGE in IO_STAGE:
		var object_to_save : Variant
		match stage:
			IO_STAGE.STARTED, IO_STAGE.FINISHED : continue
			IO_STAGE.METADATA : object_to_save = metadata; Console.log.call_deferred("Saving skin metadata...")
			IO_STAGE.ASSETS : object_to_save = assets; Console.log.call_deferred("Saving skin assets...")
			IO_STAGE.ANIMATIONS : object_to_save = animations; Console.log.call_deferred("Saving skin animations...")
			IO_STAGE.SCENE : object_to_save = scene; Console.log.call_deferred("Saving skin background scenery...")
			IO_STAGE.SEQUENCE : object_to_save = sequence; Console.log.call_deferred("Saving skin playback sequence...")
			IO_STAGE.BLOCKS : object_to_save = blocks; Console.log.call_deferred("Saving skin blocks...")
			IO_STAGE.SFX : object_to_save = sfx; Console.log.call_deferred("Saving skin sfx...")
			IO_STAGE.EFFECTS : object_to_save = effects; Console.log.call_deferred("Saving skin effects...")
			IO_STAGE.GUI  : object_to_save = gui; Console.log.call_deferred("Saving skin gui modifiers...")
	
		io_stage.emit.call_deferred(stage)
		@warning_ignore("unsafe_method_access")
		if (not object_to_save.save(file)):
			file.close()
			latest_error = IO_ERROR.DEPRECATED_VERSION # TODO : Catch IO_ERROR from sub datas instead of bool
			io_finished.emit.call_deferred()
			return
	
	Console.log.call_deferred("Skin saving finished!")
	io_stage.emit.call_deferred(IO_STAGE.FINISHED)
	latest_error = IO_ERROR.OK
	io_finished.emit.call_deferred()


## Loads skin from Project Luminext "legacy" versions (skn file versions 8 and 9) # TODO
func load_legacy_version_skin(file : FileAccess) -> void:
	pass


## Loads and returns SkinMetadata from passed file path.[br]Returns **null** on loading failure.
static func get_metadata_from_file(path : String) -> SkinMetadata:
	var output_metadata : SkinMetadata = SkinMetadata.new()
	
	var file : FileAccess = FileAccess.open_compressed(path, FileAccess.READ, COMPRESSION)
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
