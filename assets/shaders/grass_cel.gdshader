shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

// 0 = grass (height gradient via UV.y), 1 = flower, 2 = rock (moss)
uniform int cover_kind : hint_range(0, 2) = 0;

uniform vec4 color_grass_top : source_color = vec4(0.478, 0.706, 0.282, 1.0);
uniform vec4 color_grass_bottom : source_color = vec4(0.239, 0.420, 0.165, 1.0);

uniform vec4 lit_tint : source_color = vec4(0.98, 0.95, 0.86, 1.0);
uniform vec4 halfshadow_tint : source_color = vec4(0.72, 0.80, 0.70, 1.0);
uniform vec4 shadow_tint : source_color = vec4(0.20, 0.30, 0.22, 1.0);
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.50;
uniform float halfshadow_strength : hint_range(0.0, 1.0) = 0.72;
uniform float band_softness : hint_range(0.005, 0.2) = 0.042;
uniform float band_1_threshold : hint_range(0.05, 0.9) = 0.33;
uniform float band_2_threshold : hint_range(0.1, 0.95) = 0.66;
uniform vec4 rim_color : source_color = vec4(0.90, 0.95, 0.88, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.055;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform vec4 moonlight_color : source_color = vec4(0.58, 0.67, 0.82, 1.0);
uniform float moonlight_strength : hint_range(0.0, 0.4) = 0.06;
uniform vec3 moonlight_direction = vec3(-0.4, 0.85, 0.35);
uniform float moonlight_wrap : hint_range(0.0, 1.0) = 0.22;

uniform vec4 flower_petal : source_color = vec4(0.960784, 0.772549, 0.258824, 1.0);
uniform vec4 flower_center_col : source_color = vec4(0.909804, 0.627451, 0.12549, 1.0);
uniform vec4 flower_petal_white : source_color = vec4(0.960784, 0.941176, 0.909804, 1.0);
uniform vec4 flower_center_white : source_color = vec4(0.941176, 0.803922, 0.376471, 1.0);
uniform bool flower_is_white = false;
uniform vec4 stem_color : source_color = vec4(0.18, 0.32, 0.14, 1.0);
uniform float flower_disk_radius : hint_range(0.02, 0.28) = 0.175;
uniform float flower_stem_cutoff : hint_range(0.05, 0.35) = 0.108;

uniform vec4 rock_moss : source_color = vec4(0.290, 0.478, 0.239, 1.0);
uniform vec4 rock_side : source_color = vec4(0.478, 0.419, 0.333, 1.0);
uniform float moss_edge : hint_range(0.2, 0.9) = 0.50;

// Reserved for wind sway (not implemented).
uniform float wind_strength : hint_range(0.0, 2.0) = 0.0;

varying vec3 v_base_color;
varying vec3 v_world_vertex;
varying float v_facing;

void vertex() {
	v_world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 world_n;
	if (cover_kind == 1) {
		vec3 n_view = normalize(NORMAL);
		if (dot(n_view, VIEW) < 0.0) {
			n_view = -n_view;
		}
		NORMAL = n_view;
		world_n = normalize((INV_VIEW_MATRIX * vec4(n_view, 0.0)).xyz);
	} else {
		world_n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	}
	if (cover_kind == 0) {
		float vt = clamp(UV.y, 0.0, 1.0);
		vt = pow(vt, 0.85);
		v_base_color = mix(color_grass_bottom.rgb, color_grass_top.rgb, vt);
	} else if (cover_kind == 1) {
		if (VERTEX.y < flower_stem_cutoff) {
			v_base_color = stem_color.rgb;
		} else {
			float r = length(VERTEX.xz) / max(flower_disk_radius, 0.001);
			vec3 petal = flower_is_white ? flower_petal_white.rgb : flower_petal.rgb;
			vec3 cent = flower_is_white ? flower_center_white.rgb : flower_center_col.rgb;
			v_base_color = mix(cent, petal, smoothstep(0.12, 0.55, r));
		}
	} else {
		float upw = world_n.y;
		v_base_color = mix(rock_side.rgb, rock_moss.rgb, smoothstep(moss_edge - 0.2, moss_edge + 0.2, upw));
	}

	vec3 world_view = normalize(CAMERA_POSITION_WORLD - v_world_vertex);
	v_facing = abs(dot(world_n, world_view));
	ALBEDO = v_base_color;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = max(dot(NORMAL, LIGHT), 0.0);
	float b1 = min(band_1_threshold, band_2_threshold - 0.05);
	float b2 = max(band_2_threshold, b1 + 0.05);
	float soft = band_softness;

	float w_shadow = 1.0 - smoothstep(b1 - soft, b1 + soft, ndl);
	float w_light = smoothstep(b2 - soft, b2 + soft, ndl);
	float w_half = clamp(1.0 - w_shadow - w_light, 0.0, 1.0);

	vec3 toon_tint =
		shadow_tint.rgb * w_shadow +
		halfshadow_tint.rgb * w_half +
		lit_tint.rgb * w_light;
	vec3 shaded =
		(v_base_color * shadow_strength) * w_shadow +
		(v_base_color * halfshadow_strength) * w_half +
		v_base_color * w_light;

	float silhouette = mix(1.0, 0.94, smoothstep(0.2, 0.95, v_facing));
	shaded *= silhouette;

	DIFFUSE_LIGHT += shaded * toon_tint * LIGHT_COLOR * ATTENUATION;

	float rim = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), rim_power);
	rim *= rim_strength * smoothstep(0.12, 0.82, ndl);
	DIFFUSE_LIGHT += rim_color.rgb * rim * ATTENUATION;

	vec3 moon_dir = normalize(moonlight_direction);
	float moon_ndl = max(dot(NORMAL, moon_dir), 0.0);
	float moon_fill = mix(moon_ndl, 1.0, moonlight_wrap) * moonlight_strength;
	DIFFUSE_LIGHT += v_base_color * moonlight_color.rgb * moon_fill;
}
