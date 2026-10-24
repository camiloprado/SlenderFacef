shader_type spatial;
render_mode diffuse_burley;

uniform vec3 slate : source_color = vec3(0.05, 0.2, 0.12);
uniform float tray_y = 1.16;

varying vec3 w_pos;
varying vec3 w_normal;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
	return noise(p) * 0.5 + noise(p * 2.1 + 3.7) * 0.3 + noise(p * 4.3 + 9.1) * 0.2;
}

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 p = abs(w_normal.z) > 0.5 ? w_pos.xy : w_pos.zy;
	float base = fbm(p * 3.0);
	vec3 col = slate * (0.82 + 0.3 * base);
	vec2 swipe_p = vec2(p.x * 1.4 + sin(p.y * 2.0) * 0.4, p.y * 7.0);
	float swipe = smoothstep(0.45, 0.85, fbm(swipe_p)) * smoothstep(0.2, 0.7, fbm(p * 0.8 + 5.0));
	col += vec3(0.11, 0.13, 0.12) * swipe;
	float ghost = smoothstep(0.78, 0.92, noise(vec2(p.x * 22.0, p.y * 55.0))) * smoothstep(0.35, 0.75, fbm(p * 1.3 + 11.0));
	col += vec3(0.045) * ghost;
	float dust = smoothstep(tray_y + 0.2, tray_y, w_pos.y) * (0.6 + 0.4 * noise(p * 25.0));
	col = mix(col, vec3(0.42, 0.45, 0.42), dust * 0.35);
	ALBEDO = col;
	ROUGHNESS = 0.9 - swipe * 0.15;
	SPECULAR = 0.25;
}
