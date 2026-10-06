shader_type spatial;
render_mode diffuse_burley;

uniform vec3 tint : source_color = vec3(0.2, 0.22, 0.26);
uniform vec3 trim : source_color = vec3(0.1, 0.12, 0.15);
uniform float wainscot = 1.05;
uniform float panel = 1.6;

varying vec3 w_pos;
varying vec3 w_normal;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(hash(i), hash(i + vec3(1, 0, 0)), f.x);
	float b = mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x);
	float c = mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x);
	float d = mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x);
	return mix(mix(a, b, f.y), mix(c, d, f.y), f.z);
}

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float y = w_pos.y;
	float along = abs(w_normal.x) > 0.5 ? w_pos.z : w_pos.x;
	float n = noise(w_pos * 2.3) * 0.5 + noise(w_pos * 9.0) * 0.3 + noise(w_pos * 41.0) * 0.2;
	vec3 col = tint * (0.86 + 0.26 * n);
	float rough = 0.92;
	if (y < wainscot) {
		col = trim * (0.92 + 0.16 * n);
		rough = 0.5;
	}
	float rail = 1.0 - smoothstep(0.0, 0.035, abs(y - wainscot));
	col = mix(col, trim * 0.55, rail);
	if (y < 0.13) {
		col = vec3(0.06, 0.06, 0.07);
		rough = 0.4;
	}
	float seam_d = abs(fract(along / panel + 0.5) - 0.5) * panel;
	float seam = (1.0 - smoothstep(0.0, 0.012, seam_d)) * step(wainscot, y);
	col *= 1.0 - seam * 0.3;
	float streak = noise(vec3(along * 5.0, y * 0.5, 3.0));
	col *= 1.0 - smoothstep(0.55, 0.85, streak) * 0.22 * (1.0 - smoothstep(0.2, 2.6, y));
	float ao = mix(0.5, 1.0, smoothstep(0.0, 0.55, y)) * mix(0.7, 1.0, smoothstep(3.1, 2.55, y));
	ALBEDO = col * ao;
	ROUGHNESS = rough;
	SPECULAR = 0.35;
	vec3 jitter = vec3(noise(w_pos * 60.0) - 0.5, noise(w_pos * 60.0 + 17.0) - 0.5, noise(w_pos * 60.0 + 31.0) - 0.5);
	NORMAL = normalize(NORMAL + (VIEW_MATRIX * vec4(jitter * 0.08, 0.0)).xyz);
}
