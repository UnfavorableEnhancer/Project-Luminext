shader_type canvas_item;

uniform float offset : hint_range(-2.0, 4.0) = 0.0;
uniform float width : hint_range(0.0, 10.0) = 0.0;
uniform float power : hint_range(0.0, 10.0) = 5.0;
uniform float angle : hint_range(0.0, 360.0) = 180.0;

void fragment() {
	COLOR.a = COLOR.a * smoothstep(offset - width, offset + width, UV.x * cos(angle) + UV.y * sin(angle)) * (1.0 - smoothstep(offset - width, offset + width, UV.x * cos(angle) + UV.y * sin(angle))) * power;
}