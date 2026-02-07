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
## Contains all constants related to [SkinData] and it's sub-data structures
##
class_name SkinConsts

const DEPRECATED_VERSION : int = 6 ## Uncompatible format version
const LEGACY_VERSION : int = 7 ## Format version from legacy versions of Project Luminext (backward-compatible)
const VERSION : int = 10 ## Current format version
const FILE_COMPRESSION : FileAccess.CompressionMode = FileAccess.CompressionMode.COMPRESSION_ZSTD ## File compression algorythm

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
