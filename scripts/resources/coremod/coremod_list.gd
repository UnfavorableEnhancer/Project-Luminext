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


extends Resource

##-----------------------------------------------------------------------
## Handles core mods integration into various game systems
##-----------------------------------------------------------------------

class_name CoreModList


## Loads all mods .pck files stored in [constant Data.MODS_PATH]
## Mod can replace any file inside project
func _load_mods() -> void:
	var mods_paths : Array = Data._parse(Data.PARSE.MODS)

	for path : String in mods_paths:
		Console._log("Loading mod : " + path)
		var success : bool = ProjectSettings.load_resource_pack(path, true)
		if success: Console._log("Mod loaded successfully!")
		else: Console._log("ERROR! Mod load failed.")