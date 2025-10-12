group_uniforms Quantization;
/**Pixel resolution scale (0 is bypass)*/
uniform int quantize_size : hint_range(0,100) = 1;
/**Pixels are snapped based on world coordinates vs local coordinates.*/
uniform bool snap_to_world;
/**Auto-scales the quantize size when zoom is < 1, preventing subpixel artifacts*/
uniform bool limit_subpixels = true;
group_uniforms;

varying mat4 v_model_matrix;
varying mat4 v_alt_matrix;
varying vec2 v_vertex;
varying flat int v_quant_size;
varying flat vec4 v_texture_data;

const float EPSILON = 0.0001;

int getQuantizeSize(float in_zoom) {
    int q_size = quantize_size;

    if (limit_subpixels && in_zoom < 1.) {
        q_size = int(round(float(quantize_size) * (1. / in_zoom)));
    }

    return q_size;
}

vec2 _snap(vec2 in_uv, float in_q_size) {
    return (floor(in_uv / in_q_size) + 0.5) * in_q_size;
}

vec4 getQuantizeScreenUV(vec2 in_screen_uv) {
    vec4 result;

    if (v_quant_size == 0) {
        result.xy = in_screen_uv;
        result.zw = (v_model_matrix * vec4(v_vertex, 0, 1)).xy;
        return result;
    }

    if (snap_to_world) {
        vec2 uv = (v_model_matrix * vec4(v_vertex, 0, 1)).xy;
        result.zw = uv + EPSILON;
        uv = _snap(uv, float(v_quant_size));
        uv = (v_alt_matrix * vec4(uv, 0,1)).xy;
        uv = uv * 0.5 + 0.5;
        result.xy = uv;
        return result;
    } else {
        vec2 origin_uv = v_texture_data.xy;
        vec2 quant_pixel_size = v_texture_data.zw;
        vec2 uv = in_screen_uv - origin_uv;
        uv = (floor(uv / quant_pixel_size) + 0.5) * quant_pixel_size;

        uv = uv + origin_uv;
        vec2 clipXY = uv * 2.0 - 1.;
        vec2 world_pos = (v_alt_matrix * vec4(clipXY, 0.0, 1.0)).xy;
        result.zw = world_pos + EPSILON;
        result.xy = uv;
        return result;
    }
}

vec4 getQuantizeTextureUV(vec2 in_uv) {
    vec4 result;
    vec2 texture_size = v_texture_data.xy;
    vec2 flip = v_texture_data.zw;

    if (v_quant_size == 0) {
        result.xy = in_uv;
        result.zw = (v_model_matrix * vec4(in_uv * texture_size, 0, 1)).xy;
        return result;
    }

    vec2 offset;
    float q = float(v_quant_size);
    vec2 uv = in_uv;
    uv = mix(uv, 1.0 - uv, flip);

    if (snap_to_world) {
        vec2 inv_texture_size = 1. / texture_size;
        offset = v_vertex * inv_texture_size;
        offset = uv - offset;
        uv -= offset;

        uv *= texture_size;
        uv = (v_model_matrix * vec4(uv, 0, 1)).xy;
        result.zw = uv;
        uv = _snap(uv, q);
        uv = (v_alt_matrix * vec4(uv, 0, 1)).xy;
        uv *= inv_texture_size;

        uv = offset + uv;
    } else {
        uv *= texture_size;
        result.zw = uv;
        uv = _snap(uv, q);
        uv /= texture_size;
    }

    uv = mix(uv, 1.0 - uv, flip);
    result.xy = uv + EPSILON;
    return result;
}
