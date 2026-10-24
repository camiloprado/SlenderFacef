shader_type spatial;
render_mode diffuse_burley;

uniform vec3 tint : source_color = vec3(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rough_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D metal_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float scale = 1.0;
uniform float metal = 0.0;
uniform float rough = 1.0;
uniform float bump = 1.0;
uniform bool local_space = false;

varying vec3 w_pos;
varying vec3 w_normal;

void vertex() {
	if (local_space) {
		w_pos = VERTEX;
		w_normal = NORMAL;
	} else {
		w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		w_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	}
}

void fragment() {
	vec3 an = abs(w_normal);
	vec2 uv;
	vec3 tan_w;
	vec3 bit_w;
	if (an.y >= an.x && an.y >= an.z) {
		uv = w_pos.xz;
		tan_w = vec3(1.0, 0.0, 0.0);
		bit_w = vec3(0.0, 0.0, 1.0);
	} else if (an.x >= an.z) {
		uv = vec2(w_pos.z * sign(w_normal.x), w_pos.y);
		tan_w = vec3(0.0, 0.0, sign(w_normal.x));
		bit_w = vec3(0.0, 1.0, 0.0);
	} else {
		uv = vec2(-w_pos.x * sign(w_normal.z), w_pos.y);
		tan_w = vec3(-sign(w_normal.z), 0.0, 0.0);
		bit_w = vec3(0.0, 1.0, 0.0);
	}
	uv *= scale;
	ALBEDO = texture(albedo_tex, uv).rgb * tint;
	ROUGHNESS = texture(rough_tex, uv).r * rough;
	METALLIC = texture(metal_tex, uv).r * metal;
	vec3 nm = texture(normal_tex, uv).rgb * 2.0 - 1.0;
	vec3 wn = normalize(w_normal + (tan_w * nm.x + bit_w * nm.y) * bump);
	if (local_space) {
		wn = (MODEL_MATRIX * vec4(wn, 0.0)).xyz;
	}
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
}
