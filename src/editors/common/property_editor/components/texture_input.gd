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

extends VBoxContainer
##
## Allows to insert single texture file
##
class_name TextureInputPropertyEditor

signal texture_selected(texture_filepath : String)

var file_browser : FileBrowser = null ## Parent editor file browser instance


## Sets property name
func set_property_name(value_name : String) -> void:
	$Name.text = value_name

## Sets texture to show
func set_texture(new_texture : Texture) -> void:
	$H/Texture.texture = new_texture

func _on_input_pressed() -> void:
	file_browser.setup_image_filter()
	file_browser.file_selected.connect(_on_file_browser_file_selected)
	file_browser.popup_centered()

func _on_file_browser_file_selected(filepath : String) -> void:
	file_browser.file_selected.disconnect(_on_file_browser_file_selected)
	texture_selected.emit(filepath)
