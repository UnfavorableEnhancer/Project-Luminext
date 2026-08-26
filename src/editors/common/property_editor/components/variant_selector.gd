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
## Allows to select one of putted variants
##
class_name VariantSelectPropertyEditor

signal variant_selected(new_value : Variant)

var variants : Dictionary[String, Variant] = {}


## Sets text above editor
func set_label_text(value_name : String) -> void:
	$Name.text = value_name

## Adds variants to select
func add_variants(new_variants : Dictionary[String, Variant]) -> void:
	$Selector.clear()
	variants = new_variants
	
	for variant_name : String in variants.keys():
		$Selector.add_item(variant_name)

## Sets currently selected variant
func set_value(new_variant : Variant) -> void:
	var key_index : int = variants.values().find(new_variant)
	if key_index == -1 : return
	$Selector.select(key_index)

func _on_selector_item_selected(index: int) -> void:
	var selected_variant : Variant = variants[$Selector.get_item_text(index)]
	variant_selected.emit(selected_variant)
