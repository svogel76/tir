shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

uniform vec4 base_color : source_color = vec4(0.38, 0.55, 0.22, 1.0);
uniform vec4 lit_tint : source_color = vec4(0.98, 0.95, 0.86, 1.0);
uniform vec4 halfshadow_tint : source_color = vec4(0.72, 0.80, 0.70, 1.0);
uniform vec4 shadow_tint : source_color = vec4(0.18, 0.32, 0.22, 1.0);
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.52;
uniform float halfshadow_strength : hint_range(0.0, 1.0) = 0.74;
uniform float band_softness : hint_range(0.005, 0.2) = 0.045;
uniform float band_1_threshold : hint_range(0.05, 0.9) = 0.33;
uniform float band_2_threshold : hint_range(0.1, 0.95) = 0.66;
uniform float relief_strength : hint_range(0.0, 1.0) = 0.12;
uniform vec4 rim_color : source_color = vec4(0.90, 0.95, 0.90, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.06;
uniform float rim_power : hint_range(0.5, 8.0) = 3.2;
uniform vec4 moonlight_color : source_color = vec4(0.58, 0.67, 0.82, 1.0);
uniform float moonlight_strength : hint_range(0.0, 0.4) = 0.08;
uniform vec3 moonlight_direction = vec3(-0.4, 0.85, 0.35);
uniform float moonlight_wrap : hint_range(0.0, 1.0) = 0.22;

uniform float atmospheric_near : hint_range(5.0, 120.0) = 28.0;
uniform float atmospheric_far : hint_range(30.0, 400.0) = 165.0;
uniform float atmospheric_strength : hint_range(0.0, 1.0) = 0.55;
uniform vec4 distant_tint : source_color = vec4(0.62, 0.82, 0.78, 1.0);

varying vec3 v_base_color;
varying vec3 v_world_vertex;
varying float v_facing;

void vertex() {
	v_world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float dist = length(v_world_vertex - CAMERA_POSITION_WORLD);
	float atm = smoothstep(atmospheric_near, atmospheric_far, dist) * atmospheric_strength;
	vec3 tinted = mix(base_color.rgb, base_color.rgb * distant_tint.rgb, atm);
	v_base_color = tinted;
	vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 world_view = normalize(CAMERA_POSITION_WORLD - v_world_vertex);
	v_facing = abs(dot(world_normal, world_view));
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

	float silhouette = mix(1.0, 0.92, smoothstep(0.2, 0.95, v_facing));
	shaded *= mix(1.0, 1.0 - relief_strength, silhouette);

	DIFFUSE_LIGHT += shaded * toon_tint * LIGHT_COLOR * ATTENUATION;

	float rim = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), rim_power);
	rim *= rim_strength * smoothstep(0.15, 0.85, ndl);
	DIFFUSE_LIGHT += rim_color.rgb * rim * ATTENUATION;

	vec3 moon_dir = normalize(moonlight_direction);
	float moon_ndl = max(dot(NORMAL, moon_dir), 0.0);
	float moon_fill = mix(moon_ndl, 1.0, moonlight_wrap) * moonlight_strength;
	DIFFUSE_LIGHT += v_base_color * moonlight_color.rgb * moon_fill;
}
