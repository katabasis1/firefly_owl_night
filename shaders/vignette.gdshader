shader_type canvas_item;
// Мягкая виньетка поверх игрового мира.

uniform float strength = 0.6;
uniform vec4 tint : source_color = vec4(0.02, 0.0, 0.07, 1.0);

void fragment() {
	vec2 d = (UV - 0.5) * vec2(1.0, 0.85);
	float v = smoothstep(0.32, 0.8, length(d));
	COLOR = vec4(tint.rgb, v * strength);
}
