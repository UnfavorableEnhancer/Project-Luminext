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
## Contains all animations which are used by sequencer to animate background scenery.
##
class_name SkinAnimationData

## All avaiable background animations as animation uid (name) - [Animation] pairs
var animations : Dictionary[StringName, Animation] = {
	# animation uid : animation
}

## Compiled animation is built using finished [SkinSequenceData] and contains all animation tracks packed into single animation for performance boost.
var compiled_animation : Animation = null


## Compiles all animations into single animation using passed [SkinSequenceData].[br]
## Returns **true** on success.
func compile(sequence_data : SkinSequenceData) -> bool:
	return true


## Loads animations data from passed FileAccess, which has valid skin file opened
func load(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK

## Saves animations data to passed FileAccess, which has valid skin file opened
func save(file : FileAccess) -> SkinConsts.IO_ERROR:
	return SkinConsts.IO_ERROR.OK
