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

extends FileDialog
##
## Contains some helper methods for building and using FileDialog
## 
class_name FileBrowser


## Sets file browser to select only single file
func select_single_file() -> void : file_mode = FileDialog.FILE_MODE_OPEN_FILE

## Sets file browser to select file for saving
func select_save_file() -> void : file_mode = FileDialog.FILE_MODE_SAVE_FILE

## Sets file browser to select multiple files
func select_files() -> void : file_mode = FileDialog.FILE_MODE_OPEN_FILES

## Sets file browser to select multiple files and dir
func select_files_and_dir() -> void : file_mode = FileDialog.FILE_MODE_OPEN_ANY


## Sets file selection filter to select only images
func setup_image_filter() -> void:
	clear_filters()
	
	var filter : String = ""
	for extensions_list : Array in ModdableAsset.TextureAsset.FORMAT_EXTENSIONS.values():
		if extensions_list.is_empty() : continue
		
		for extension : String in extensions_list:
			filter += "*" + extension + ", "
	
	add_filter(filter, "Image")

## Sets file selection filter to select only audio
func setup_audio_filter() -> void:
	clear_filters()
	
	var filter : String = ""
	for extensions_list : Array in ModdableAsset.AudioAsset.FORMAT_EXTENSIONS.values():
		if extensions_list.is_empty() : continue
		
		for extension : String in extensions_list:
			filter += "*" + extension + ", "
	
	add_filter(filter, "Audio")

## Sets file selection filter to select only video
func setup_video_filter() -> void:
	clear_filters()
	
	var filter : String = ""
	for extensions_list : Array in ModdableAsset.VideoAsset.FORMAT_EXTENSIONS.values():
		if extensions_list.is_empty() : continue
		
		for extension : String in extensions_list:
			filter += "*" + extension + ", "
	
	add_filter(filter, "Video")

## Sets file selection filter to select only fonts
func setup_font_filter() -> void:
	clear_filters()
	
	var filter : String = ""
	for extensions_list : Array in ModdableAsset.FontAsset.FORMAT_EXTENSIONS.values():
		if extensions_list.is_empty() : continue
		
		for extension : String in extensions_list:
			filter += "*" + extension + ", "
	
	add_filter(filter, "Font")
