# Project Luminext - an advanced open-source Lumines spiritual successor
# Copyright (C) <2024> <unfavorable_enhancer>
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


extends TextureButton

#-----------------------------------------------------------------------
# This button is used to input textures into SkinEditor dictionary entries
#-----------------------------------------------------------------------

@onready var editor : MenuScreen = Data.menu.get_node("Skin Editor")

@export var texture_name : String = "" # Texture2D name this button edits
@export_multiline var description : String = ""
@export var category : String = "textures" # In which dictionary inside skin data this texture lays

# Those are textures this button will fallback when texture was removed
var standard_texture : Texture2D = null
var standard_anim : SpriteFrames = null

@onready var animation : AnimatedSprite2D = get_node("A") if has_node("A") else null


func _ready() -> void:
	add_to_group("texture_buttons")
	
	gui_input.connect(_on_press)
	mouse_entered.connect(_selected)
	
	if animation: 
		# Connect this animation sprite, to several things to make it animation looping
		editor.get_node("Animate").timeout.connect(_play_animation)
		animation.animation_finished.connect(_loop_animation)


# Loads texture from currently loaded into editor SkinData
func _load_texture() -> void:
	var what : String = texture_name
	# Animated textures are stored in SpriteFrames, so if this texture is animated we must get specific entry from SkinData
	if what in editor.skin_data.textures["block"].get_animation_names(): what = "block"
	if what in editor.skin_data.textures["special"].get_animation_names(): what = "special"
	if what in editor.skin_data.textures["square"].get_animation_names(): what = "square"
	
	var texture : Variant
	
	if texture_name in ["cover_art","label_art"]:
		texture = editor.skin_data.metadata.get(texture_name)
	else:
		texture = editor.skin_data.get(category)[what]
	
	if texture == null:
		_reset_texture()
		return
	
	# If its animated texture
	if texture is SpriteFrames:
		var animation_frames_count : int = texture.get_frame_count(texture_name)
		if animation_frames_count == 0:
			_reset_texture()
			return
		
		# Create new SpriteFrames which would contain only our animation
		var new_frames : SpriteFrames = SpriteFrames.new()
		
		# Extract our animation from bigger skin data SpriteFrames
		for i : int in animation_frames_count:
			new_frames.add_frame("default",texture.get_frame_texture(texture_name,i))
		
		if not texture_name.ends_with("chain"):
			if texture_name.begins_with("r"): new_frames.set_animation_speed("default", editor.skin_data.textures["red_anim"][2])
			elif texture_name.begins_with("w"): new_frames.set_animation_speed("default", editor.skin_data.textures["white_anim"][2])
			elif texture_name.begins_with("g") and texture_name != "garbage": new_frames.set_animation_speed("default", editor.skin_data.textures["green_anim"][2])
			elif texture_name.begins_with("p"): new_frames.set_animation_speed("default", editor.skin_data.textures["purple_anim"][2])
			else: new_frames.set_animation_speed("default", animation_frames_count * 6)
		else:	
			new_frames.set_animation_speed("default", animation_frames_count * 6)
		
		new_frames.set_animation_loop("default", false)
		
		if animation:
			texture_normal = null
			animation.sprite_frames = new_frames
			animation.play("default")
			if standard_anim == null : standard_anim = new_frames
		else:
			var first_frame : Texture = new_frames.get_frame_texture("default",0)
			texture_normal = first_frame
			if standard_texture == null : standard_texture = first_frame
	
	# If single texture
	else:
		texture_normal = texture
		if standard_texture == null : standard_texture = texture
		if animation: animation.sprite_frames = null


func _set_animation_fps(color : String, fps : int) -> void:
	if not animation : return

	if not texture_name.ends_with("chain"):
		match color:
			"red_anim" : if texture_name.begins_with("r"): animation.sprite_frames.set_animation_speed("default", fps)
			"white_anim" : if texture_name.begins_with("w"): animation.sprite_frames.set_animation_speed("default", fps)
			"green_anim" : if texture_name.begins_with("g") and texture_name != "garbage": animation.sprite_frames.set_animation_speed("default", fps)
			"purple_anim" : if texture_name.begins_with("p"): animation.sprite_frames.set_animation_speed("default", fps)


# Reset texture to standard one
func _reset_texture() -> void:
	if texture_name in ["cover_art","label_art"]: 
		texture_normal = load("res://images/back.png")
		editor.skin_data.metadata.set(texture_name,null)
		standard_texture = null
	
	if standard_anim == null and standard_texture == null : return
	
	if animation:
		var default_tex : Variant
		if standard_anim != null:
			texture_normal = null
			default_tex = standard_anim
			animation.sprite_frames = standard_anim
			animation.play("default")
		else:
			default_tex = standard_texture
			texture_normal = standard_texture
			animation.sprite_frames = null
		
		editor.skin_data._update_sprite_sheet(default_tex, texture_name)
	
	else:
		texture_normal = standard_texture
		editor.skin_data.textures[texture_name] = standard_texture


# Calls texture assign routine in skin editor and then applies selected texture
func _assign_texture() -> void:
	editor._open_file_dialog("texture")
	await editor.file_selected
	var texture : Variant = editor._edit_skn_texture(texture_name, category)
	
	if texture == null : return
	
	if texture is SpriteFrames and animation:
		texture_normal = null
		animation.sprite_frames = texture
		animation.play("default")
	else:
		texture_normal = texture
		if animation: animation.sprite_frames = null


# Called on button press
func _on_press(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT: _assign_texture()
			MOUSE_BUTTON_RIGHT: _reset_texture()


func _play_animation() -> void:
	if animation.sprite_frames != null:
		animation.play()


func _loop_animation() -> void:
	if animation.sprite_frames != null:
		animation.stop()
		animation.frame = 0


# Called when hovered by mouse
func _selected() -> void:
	editor._show_description(description)
