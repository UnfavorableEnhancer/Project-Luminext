# Project Luminext - an ultimate block-stacking puzzle game
# Copyright (C) <2024-2025> <unfavorable_enhancer>
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

##-----------------------------------------------------------------------
## Singletone containing all directories paths, content parsers instances and some other utility data
##-----------------------------------------------------------------------

enum PARSE {PROFILES, PLAYLISTS, RULESETS, ADDONS, MODS, REPLAYS}

const VERSION : String = "0.1.2" ## Current game version
const BUILD : String = "26.09.2025" ## Latest build date

const SKINS_PATH : String = "content/skins/" ## Path to the skins folder
const PLAYLISTS_PATH : String = "content/playlists/" ## Path to the saved playlists folder
const ADDONS_PATH : String = "content/addons/" ## Path to the addons folder (currently unused)
const PROFILES_PATH : String = "profiles/" ## Path to the profiles folder
const RULESETS_PATH : String = "content/rulesets/" ## Path to the game presets folder
const MODS_PATH : String = "content/mods/" ## Path to the .pck mods folder
const SCREENSHOTS_PATH : String = "export/screenshots/" ## Path to the game screenshots folder
const LOGS_PATH : String = "export/logs/" ## Path to the game logs folder
const REPLAYS_PATH : String = "export/replays/" ## Path to the replays folder
const GRAPHS_PATH : String = "export/graphs/" ## Path to the statistics graphs folder

const BUILD_IN_PATH : String = "res://internal/" ## Path to the build-in game content, which is exported with entiere project
const GLOBAL_DATA_PATH : String = "user://global.json" ## Path to the global data json
const LOCAL_RANKING_PATH : String = "user://local_ranking.json" ## Path to the local ranking json (TODO : move to ranking_manager.gd)
const CACHE_PATH : String = "user://cache/" ## Path to the data cache

var skin_list : SkinList = SkinList.new() ## All skins list
var skin_playlist : SkinPlaylist = SkinPlaylist.new() ## Skins playlist

var coremod_list : CoreModList = CoreModList.new() ## All core mods list

var blank_skin : SkinData = SkinData.new() ## Blank skin which is used to speed up loading times, by copying its contents to new [SkinData] if needed
var use_second_cache : bool = false ## If true game will use second name for caching video & scenery, so things wont break on skin transition


## Loads all nessesary data for boot
func _load() -> void:
	for path : String in [SKINS_PATH, PLAYLISTS_PATH, PROFILES_PATH, RULESETS_PATH, CACHE_PATH, SCREENSHOTS_PATH, LOGS_PATH, REPLAYS_PATH]:
		if not DirAccess.dir_exists_absolute(path):
			Console._log("Creating directory : " + path)
			DirAccess.make_dir_recursive_absolute(path)

	skin_list._parse_threaded()
	blank_skin._load_standard_textures()
	coremod_list._load_mods()


## Parses specified content directory and returns its file names/paths array.[br]
## - [b]'content_type'[/b] - What should be parsed, specified in [constant PARSE] enum[br]
## - [b]'output_names'[/b] - Result Array will contain file names instead of file paths[br]
func _parse(content_type : int, output_names : bool = false) -> Array[String]:
	var output : Array[String] = []
	var parse_directory : String
	var file_extension : String
	var has_build_in : bool
	
	Console._space()
	match content_type:
		PARSE.PROFILES:
			Console._log("Parsing profiles directory")
			parse_directory = PROFILES_PATH
			has_build_in = false
			file_extension = "dat"
		PARSE.RULESETS:
			Console._log("Parsing rulesets directory")
			parse_directory = RULESETS_PATH
			has_build_in = true
			file_extension = "json"
		PARSE.PLAYLISTS:
			Console._log("Parsing playlists directory")
			parse_directory = PLAYLISTS_PATH
			has_build_in = false
			file_extension = "ply"
		PARSE.ADDONS:
			Console._log("Parsing addons directory")
			parse_directory = ADDONS_PATH
			has_build_in = true
			file_extension = "add"
		PARSE.REPLAYS:
			Console._log("Parsing replays directory")
			parse_directory = REPLAYS_PATH
			has_build_in = false
			file_extension = "rec"
		_:
			Console._log("ERROR! Unknown content type : " + str(content_type))
			return []

	if not DirAccess.dir_exists_absolute(parse_directory):
		Console._log("ERROR! Content directory is missing : " + parse_directory)
		DirAccess.make_dir_absolute(parse_directory)
		return []

	var dir : DirAccess = DirAccess.open(parse_directory)
	if not dir:
		dir.make_dir(parse_directory)
		Console._log("ERROR! Cannot access content directory : " + error_string(DirAccess.get_open_error()))
		return []
	
	dir.list_dir_begin()
	var file_name : String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension() == file_extension:
			if output_names : output.append(file_name.get_basename())
			else : output.append(parse_directory + file_name)
			Console._log("Found file : " + file_name)
		file_name = dir.get_next()
	
	# If current file type we parsing is present in game build-in directory, parse it too
	if has_build_in :
		Console._log("Parsing internal content directory")
		dir = DirAccess.open(Data.BUILD_IN_PATH + parse_directory)
		if not dir:
			Console._log("ERROR! Cannot access internal content directory : " + error_string(DirAccess.get_open_error()))
			return output
		
		dir.list_dir_begin()
		file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.get_extension() == file_extension:
				if output_names : output.append(file_name.get_basename())
				else : output.append(Data.BUILD_IN_PATH + parse_directory + file_name)
				Console._log("Found build-in file : " + file_name)
			file_name = dir.get_next()
	
	Console._log("Parse complete!")
	return output
