shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_back;

uniform float fuzz : hint_range(0.0, 1.0) = 0.5;
uniform float softness : hint_range(0.0, 1.0) = 0.32;
uniform float gloss : hint_range(0.0, 1.0) = 0.08;
uniform float glow : hint_range(0.0, 2.0) = 0.0;
uniform vec3 glow_color : source_color = vec3(0.02, 0.02, 0.03);
uniform float puff : hint_range(0.0, 0.04) = 0.008;
uniform vec4 tint : source_color = vec4(1.0);
uniform float brightness : hint_range(0.5, 1.6) = 1.35;
uniform float grime : hint_range(0.0, 1.0) = 0.0;
uniform float lumps : hint_range(0.0, 0.06) = 0.0;
uniform float lump_scale = 5.0;

varying vec3 v_col;
varying vec3 v_local;

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
	v_col = COLOR.rgb * tint.rgb;
	v_local = VERTEX;
	float sag = noise(VERTEX * lump_scale) - 0.5;
	VERTEX += NORMAL * (puff + sag * lumps);
}

void fragment() {
	float fiber = hash(floor(v_local * 90.0));
	float weave = 0.9 + 0.1 * fiber;
	vec3 base = v_col * weave * brightness;
	if (grime > 0.001) {
		float blot = noise(v_local * 3.1) * 0.65 + noise(v_local * 11.0) * 0.35;
		float dirt = smoothstep(0.35, 0.85, blot) * grime;
		float grey = dot(base, vec3(0.3, 0.55, 0.15));
		base = mix(base, vec3(grey) * vec3(0.78, 0.72, 0.6), dirt * 0.55);
		base *= 1.0 - dirt * 0.38;
	}
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fres = pow(1.0 - ndv, 2.2);
	vec3 halo = base * 1.35 + vec3(0.12, 0.1, 0.08);
	ALBEDO = mix(base, halo, fres * fuzz);
	ROUGHNESS = mix(0.97, 0.55, gloss + fres * 0.15);
	SPECULAR = mix(0.06, 0.45, gloss);
	METALLIC = 0.0;
	SSS_STRENGTH = softness;
	SSS_TRANSMITTANCE_COLOR = vec4(base * 0.6, 1.0);
	RIM = fres * fuzz * 0.35;
	RIM_TINT = 0.7;
	if (glow > 0.001) {
		EMISSION = glow_color * glow;
	}
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float wrap = clamp(ndl * 0.42 + 0.58, 0.0, 1.0);
	DIFFUSE_LIGHT += wrap * ATTENUATION * LIGHT_COLOR * ALBEDO;
	vec3 half_vec = normalize(LIGHT + VIEW);
	float spec = pow(clamp(dot(NORMAL, half_vec), 0.0, 1.0), mix(48.0, 8.0, ROUGHNESS));
	SPECULAR_LIGHT += spec * ATTENUATION * LIGHT_COLOR * gloss * 0.25;
}
