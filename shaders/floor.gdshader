shader_type spatial;
render_mode diffuse_burley;

uniform vec3 tint : source_color = vec3(0.22, 0.23, 0.26);
uniform float tile = 0.6;
uniform float grout = 0.012;
uniform float gloss = 0.35;

varying vec3 w_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = w_pos.xz;
	float n = noise(p * 1.7) * 0.5 + noise(p * 7.0) * 0.3 + noise(p * 33.0) * 0.2;
	vec3 col = tint * (0.85 + 0.3 * n);
	float rough = 0.9;
	if (tile > 0.0) {
		vec2 cell = floor(p / tile);
		vec2 f = abs(fract(p / tile) - 0.5) * tile;
		float edge = max(f.x, f.y);
		float line = smoothstep(tile * 0.5 - grout, tile * 0.5 - grout * 0.4, edge);
		col *= 0.9 + 0.2 * hash(cell);
		col = mix(col, tint * 0.45, line);
		float wet = smoothstep(0.55, 0.8, noise(p * 0.35 + 7.0));
		rough = mix(mix(0.75, 0.3, gloss), 0.15, wet * gloss) + line * 0.3;
	}
	float dirt = smoothstep(0.6, 0.9, noise(p * 0.8 + 3.0));
	col *= 1.0 - dirt * 0.25;
	ALBEDO = col;
	ROUGHNESS = clamp(rough, 0.05, 1.0);
	SPECULAR = 0.45;
}
