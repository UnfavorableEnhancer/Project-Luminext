# Project Luminext - an advanced open-source Lumines spiritual successor
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


extends Block

class_name Joker

##-----------------------------------------------------------------------
## Joker block changes color to random one every timeline pass
##-----------------------------------------------------------------------

var colors : Array[int] = [] ## Avaiable for randomization colors


func _ready() -> void:
	super()

	game.skin.sample_passed.connect(_joke)
	ruleset.changed.connect(_sync_settings)

	_sync_settings()
	# Make it slightly darker, than other blocks so it can be distinguished
	self_modulate = Color.LIGHT_GRAY


## Syncs current profile settings
func _sync_settings() -> void:
	colors.clear()

	if ruleset.blocks["red"] : colors.append(BLOCK_COLOR.RED)
	if ruleset.blocks["white"] : colors.append(BLOCK_COLOR.WHITE)
	if ruleset.blocks["green"] : colors.append(BLOCK_COLOR.GREEN)
	if ruleset.blocks["purple"] : colors.append(BLOCK_COLOR.PURPLE)


## Changes block color to random one
func _joke() -> void:
	if is_falling or is_removing or is_scanned : return
	_change_color(colors.pick_random())