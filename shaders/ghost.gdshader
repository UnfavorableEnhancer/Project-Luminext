shader_type canvas_item;
uniform float ghost : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void fragment()
{
    vec4 baseTexture = texture(SCREEN_TEXTURE, UV);
    COLOR = baseTexture;

    // Centre pour l'effet de fantôme
    vec2 center = vec2(0.5, 0.5);
    vec2 offset = (UV - center) * ghost; // Ajuste le décalage en fonction de 'ghost'
    vec2 ghostUV = center + offset; // Calcule les nouvelles coordonnées UV pour l'effet de fantôme

    // Appliquer l'effet "fantôme" avec les coordonnées UV distordues (vibrantes)
    COLOR += texture(SCREEN_TEXTURE, vec2(ghostUV.x, ghostUV.y)) * ghost;
}