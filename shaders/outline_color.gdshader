shader_type canvas_item;
render_mode blend_add;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tint_effect_factor : hint_range(0, 1) = 0.0;
uniform float test : hint_range(0, 1) = 0.0;
uniform float test2 : hint_range(0, 1) = 0.0;

//---------------------------------------------
//fragment
//---------------------------------------------
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec4 color2 = color;
	vec4 color3 = color;
	
	color2 = smoothstep(color.a, 1.05, tint_effect_factor) * color.a * tint_color * 1.25;
	color3 = vec4(smoothstep(1.05, color.a, tint_effect_factor) * color.a);
	
	COLOR = (color2 + color3);
}