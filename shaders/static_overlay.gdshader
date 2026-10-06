shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 cell = floor(UV * vec2(240.0, 135.0));
	float t = floor(TIME * 28.0);
	float n = hash(cell + vec2(t, t * 1.37));
	float scan = 0.82 + 0.18 * sin(UV.y * 520.0 + TIME * 36.0);
	vec3 col = vec3(n * scan);
	col = mix(col, vec3(0.55, 0.02, 0.03), smoothstep(0.72, 1.0, intensity));
	float vignette = smoothstep(0.35, 1.15, length((UV - vec2(0.5)) * vec2(1.15, 1.0)));
	float alpha = intensity * (0.18 + 0.82 * n) + vignette * intensity * 0.45;
	COLOR = vec4(col, clamp(alpha, 0.0, 0.94));
}
