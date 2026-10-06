shader_type spatial;
render_mode cull_disabled, diffuse_burley;

uniform sampler2D page_tex : source_color, filter_linear;
uniform vec3 back_color : source_color = vec3(0.86, 0.83, 0.74);
uniform float flutter = 0.006;
uniform float curl = 0.012;
uniform float tear = 0.0;
uniform float glow = 0.25;
uniform float seed = 0.0;

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
	vec2 c = UV - 0.5;
	float edge = clamp(length(c) * 1.6, 0.0, 1.0);
	float wave = sin(TIME * 2.6 + UV.x * 6.0 + seed) * 0.6 + sin(TIME * 4.3 + UV.y * 8.0 + seed * 1.7) * 0.4;
	VERTEX += NORMAL * (dot(c, c) * curl * 4.0 + wave * flutter * edge);
}

void fragment() {
	if (tear > 0.0) {
		float d = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
		float n = noise(UV * 38.0 + seed) * 0.7 + noise(UV * 110.0 + seed) * 0.3;
		if (d < tear * n) {
			discard;
		}
	}
	vec3 col = FRONT_FACING ? texture(page_tex, UV).rgb : back_color;
	ALBEDO = col;
	EMISSION = col * glow;
	ROUGHNESS = 0.88;
	SPECULAR = 0.15;
	BACKLIGHT = vec3(0.3, 0.28, 0.22);
}
