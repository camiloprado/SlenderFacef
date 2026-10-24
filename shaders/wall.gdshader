shader_type spatial;
render_mode diffuse_burley;

uniform vec3 tint : source_color = vec3(0.2, 0.22, 0.26);
uniform vec3 trim : source_color = vec3(0.1, 0.12, 0.15);
uniform float wainscot = 1.05;
uniform float panel = 1.6;
uniform sampler2D plaster : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D plaster_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D plaster_rough : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float tex_scale = 0.55;
uniform float bump = 1.1;

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
	vec3 an = abs(w_normal);
	vec2 uv;
	vec3 tan_w;
	vec3 bit_w = vec3(0.0, 1.0, 0.0);
	float along;
	if (an.y > 0.5) {
		uv = w_pos.xz;
		tan_w = vec3(1.0, 0.0, 0.0);
		bit_w = vec3(0.0, 0.0, 1.0);
		along = w_pos.x;
	} else if (an.x > an.z) {
		uv = vec2(w_pos.z * sign(w_normal.x), y);
		tan_w = vec3(0.0, 0.0, sign(w_normal.x));
		along = w_pos.z;
	} else {
		uv = vec2(-w_pos.x * sign(w_normal.z), y);
		tan_w = vec3(-sign(w_normal.z), 0.0, 0.0);
		along = w_pos.x;
	}
	vec2 tuv = uv * tex_scale;
	vec3 plaster_col = texture(plaster, tuv).rgb;
	float lum = dot(plaster_col, vec3(0.333));
	float rough_map = texture(plaster_rough, tuv).r;
	vec3 nm = texture(plaster_normal, tuv).rgb * 2.0 - 1.0;
	float strength = bump;

	float n = noise(w_pos * 2.3) * 0.5 + noise(w_pos * 9.0) * 0.3;
	float grain = clamp(1.0 + (lum - 0.72) * 2.2, 0.55, 1.25);
	vec3 col = tint * grain * (0.88 + 0.24 * n);
	float rough = mix(0.75, 1.0, rough_map);
	if (y < wainscot) {
		col = trim * (0.9 + 0.25 * lum) * (0.94 + 0.12 * n);
		rough = mix(0.22, 0.45, rough_map);
		strength = bump * 0.35;
		float chip = smoothstep(0.78, 0.86, noise(vec3(along * 11.0, y * 13.0, 5.0)) * lum);
		col = mix(col, tint * 0.8, chip * 0.5);
	}
	float rail = 1.0 - smoothstep(0.0, 0.035, abs(y - wainscot));
	col = mix(col, trim * 0.55, rail);
	if (y < 0.13) {
		col = vec3(0.06, 0.06, 0.07);
		rough = 0.4;
		strength = 0.1;
	}
	float seam_d = abs(fract(along / panel + 0.5) - 0.5) * panel;
	float seam = (1.0 - smoothstep(0.0, 0.012, seam_d)) * step(wainscot, y);
	col *= 1.0 - seam * 0.3;
	float streak = noise(vec3(along * 5.0, y * 0.5, 3.0));
	col *= 1.0 - smoothstep(0.55, 0.85, streak) * 0.22 * (1.0 - smoothstep(0.2, 2.6, y));
	float ao = mix(0.5, 1.0, smoothstep(0.0, 0.55, y)) * mix(0.7, 1.0, smoothstep(3.1, 2.55, y));
	ALBEDO = col * ao;
	ROUGHNESS = rough;
	SPECULAR = 0.4;
	vec3 wn = normalize(w_normal + (tan_w * nm.x + bit_w * nm.y) * strength);
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
}
