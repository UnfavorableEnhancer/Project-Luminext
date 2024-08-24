/*
	Mosaic shader for 2D canvas item by Yui Kinomoto @arlez80
	2DCanvas Item用モザイクシェーダー by あるる（きのもと 結衣）

	size = tile size

	MIT License
*/
shader_type canvas_item;

uniform float size = 10.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

void fragment( )
{
	vec2 p = floor( FRAGCOORD.xy / size ) * size;
	vec2 quat_x = vec2( size / 4.0, 0 );
	vec2 quat_y = vec2( 0, quat_x.x );
	COLOR = vec4( (
		texelFetch( SCREEN_TEXTURE, ivec2( p ), 0 ).xyz
	+	texelFetch( SCREEN_TEXTURE, ivec2( p + quat_x ), 0 ).xyz
	+	texelFetch( SCREEN_TEXTURE, ivec2( p + quat_x * 2.0 ), 0 ).xyz
	+	texelFetch( SCREEN_TEXTURE, ivec2( p + quat_x * 3.0 ), 0 ).xyz
	+	texelFetch( SCREEN_TEXTURE, ivec2( p + quat_y ), 0 ).xyz
	+	texelFetch( SCREEN_TEXTURE, ivec2( p + quat_y + quat_x ), 0 ).xyz
	+	texelFetch( SCREEN_TEXTURE, ivec2( p + quat_y + quat_x * 2.0 ), 0 ).xyz
	+	texelFetch( SCREEN_TEXTURE, ivec2( p + quat_y + quat_x * 3.0 ), 0 ).xyz
	+	texelFetch( SCREEN_TEXTURE, ivec2( p + quat_y * 2.0 ), 0 ).xyz
	+	texelFetch( SCREEN_TEXTURE, ivec2( p + quat_y * 2.0 + quat_x ), 0 ).xyz
	+	texelFetch( SCREEN_TEXTURE, ivec2( p + quat_y * 2.0 + quat_x * 2.0 ), 0 ).xyz
	+	texelFetch( SCREEN_TEXTURE, ivec2( p + quat_y * 2.0 + quat_x * 3.0 ), 0 ).xyz
	+	texelFetch( SCREEN_TEXTURE, ivec2( p + quat_y * 3.0 ), 0 ).xyz
	+	texelFetch( SCREEN_TEXTURE, ivec2( p + quat_y * 3.0 + quat_x ), 0 ).xyz
	+	texelFetch( SCREEN_TEXTURE, ivec2( p + quat_y * 3.0 + quat_x * 2.0 ), 0 ).xyz
	+	texelFetch( SCREEN_TEXTURE, ivec2( p + quat_y * 3.0 + quat_x * 3.0 ), 0 ).xyz
	) / 16.0, 1.0 );
}