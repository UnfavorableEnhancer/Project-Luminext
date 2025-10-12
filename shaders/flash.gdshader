shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Maximum distance that a pixel can be dragged
uniform float max_drag_distance : hint_range(0.0, 1.0) = 0.5;

// Number of samples along the drag path
uniform int samples : hint_range(1, 100) = 20;

// Contrast adjustment
uniform float contrast : hint_range(0.0, 4.0) = 1.0;

void fragment() {
    vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec4 fragCoord = FRAGCOORD;
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 center = vec2(0.5, 0.5);
    vec2 dir = uv - center;
    float dist = length(dir);
    vec2 norm_dir = normalize(dir);
    vec3 accumulated_color = vec3(0.0);
    float total_opacity = 0.0;

    for (int i = 0; i < samples; i++) {
        float t = float(i) / float(samples - 1);
        vec2 sample_uv = uv + norm_dir * t * max_drag_distance * dist;
        float opacity = 1.0 - t;
        vec3 sample_color = texture(SCREEN_TEXTURE, sample_uv).rgb;
        accumulated_color += sample_color * opacity;
        total_opacity += opacity;
    }
    accumulated_color /= total_opacity;
    accumulated_color = mix(vec3(0.5), accumulated_color, contrast);

    COLOR = vec4(accumulated_color, 1.0);
}