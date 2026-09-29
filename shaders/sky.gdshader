shader_type canvas_item;
// Ночное небо: градиент, северное сияние и мерцающие звёзды.

uniform vec4 top_color : source_color = vec4(0.03, 0.03, 0.11, 1.0);
uniform vec4 mid_color : source_color = vec4(0.13, 0.07, 0.28, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.04, 0.17, 0.24, 1.0);
uniform vec4 aurora_color : source_color = vec4(0.15, 0.85, 0.7, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec3 col = mix(top_color.rgb, mid_color.rgb, smoothstep(0.0, 0.55, uv.y));
	col = mix(col, bottom_color.rgb, smoothstep(0.5, 1.0, uv.y));

	float wave = sin(uv.x * 5.0 + TIME * 0.15 + sin(uv.x * 11.0 - TIME * 0.2) * 0.8) * 0.5 + 0.5;
	float band = smoothstep(0.13, 0.0, abs(uv.y - 0.3 - 0.07 * sin(uv.x * 3.5 + TIME * 0.1)));
	col += aurora_color.rgb * band * wave * 0.22;

	vec2 grid = uv * vec2(45.0, 80.0);
	vec2 id = floor(grid);
	vec2 f = fract(grid) - 0.5;
	float h = hash(id);
	if (h > 0.93) {
		vec2 off = vec2(hash(id + 3.1), hash(id + 7.7)) - 0.5;
		float d = length(f - off * 0.6);
		float tw = 0.45 + 0.55 * sin(TIME * (0.8 + h * 3.0) + h * 60.0);
		float s = (smoothstep(0.09, 0.0, d) + smoothstep(0.3, 0.0, d) * 0.25) * tw;
		col += vec3(1.0, 0.95, 0.85) * s * (1.0 - uv.y * 0.85);
	}
	COLOR = vec4(col, 1.0);
}
