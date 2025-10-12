/*
 * This should be your main shader file.
*/

shader_type canvas_item;

/**
0 = Texture: For use with Sprite2Ds, TextureRects, and Meshes
1 = Screen: For use with ColorRect
*/
uniform int texture_mode : hint_range(0,1) = 0;

// This file relies on a quantize shader include file, listed further down.
// The paths must match your file's location.
#include "res://shaders/quantize.gdshaderinc"

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

void vertex() {
    float zoom = length(CANVAS_MATRIX[1].xyz);
    v_quant_size = getQuantizeSize(zoom);
    v_model_matrix = MODEL_MATRIX;
    v_vertex = VERTEX;

    if (texture_mode == 0) {
        v_alt_matrix = inverse(MODEL_MATRIX);
        v_texture_data.xy = 1. / TEXTURE_PIXEL_SIZE;
        // Is texture flipped
        v_texture_data.zw = max(-sign((UV - 0.5) * VERTEX), 0.);
    } else {
        v_alt_matrix = SCREEN_MATRIX * CANVAS_MATRIX;

        if (snap_to_world) {
            v_alt_matrix = inverse(v_alt_matrix);
        }

        vec2 local_origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0, 1)).xy;
        vec2 clip = (v_alt_matrix * vec4(local_origin, 0,1)).xy;
        vec2 screen_origin_uv = clip * 0.5 + 0.5;
        vec2 screen_pixel_size = 1. / vec2(textureSize(SCREEN_TEXTURE, 0));
        vec2 q = screen_pixel_size * float(v_quant_size) * zoom;
        v_texture_data.xy = screen_origin_uv;
        v_texture_data.zw = q;
    }
}

void fragment() {
    if (texture_mode == 0) {
        vec4 uvResult = getQuantizeTextureUV(UV);
        COLOR = texture(TEXTURE, uvResult.xy);
    } else {
        vec4 uvResult = getQuantizeScreenUV(SCREEN_UV);
        COLOR = texture(SCREEN_TEXTURE, uvResult.xy);
    }
}
