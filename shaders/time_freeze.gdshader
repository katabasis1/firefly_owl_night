shader_type canvas_item;
// «Время стоит»: мир под линией обесцвечивается и остывает.
// Узел стоит в дереве сцены после уровня, поэтому линия и светлячок остаются яркими.

uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 cold_tint : source_color = vec3(0.62, 0.78, 1.0);
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 frozen = vec3(g) * cold_tint * 1.08;
	// лёгкая «плёнка» по краям
	vec2 d = SCREEN_UV - 0.5;
	float edge = smoothstep(0.25, 0.75, length(d));
	frozen = mix(frozen, frozen * vec3(0.7, 0.8, 1.0), edge * 0.6);
	COLOR = vec4(mix(c, frozen, amount * 0.85), 1.0);
}
