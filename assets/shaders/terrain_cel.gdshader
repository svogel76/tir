shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

// Required by VoxelMesherTransvoxel for LOD transition support.
uniform sampler2D u_transition_mask;

uniform vec4 grass_flat_color : source_color = vec4(0.29, 0.48, 0.18, 1.0); // ~RGB(74,122,45)
uniform vec4 earth_mid_color : source_color = vec4(0.44, 0.35, 0.24, 1.0);
uniform vec4 rock_steep_color : source_color = vec4(0.42, 0.38, 0.33, 1.0);
uniform vec4 lit_tint : source_color = vec4(0.98, 0.95, 0.86, 1.0);
uniform vec4 halfshadow_tint : source_color = vec4(0.72, 0.80, 0.70, 1.0);
uniform vec4 shadow_tint : source_color = vec4(0.20, 0.29, 0.23, 1.0); // dark green, not black
uniform vec4 rim_color : source_color = vec4(0.90, 0.95, 0.90, 1.0);

uniform float grass_max_angle_deg : hint_range(0.0, 89.0) = 30.0;
uniform float rock_min_angle_deg : hint_range(0.0, 89.0) = 60.0;
uniform float slope_blend_softness_deg : hint_range(0.5, 20.0) = 6.0;
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.62;
uniform float halfshadow_strength : hint_range(0.0, 1.0) = 0.82;
uniform float band_softness : hint_range(0.005, 0.2) = 0.045;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.07;
uniform float rim_power : hint_range(0.5, 8.0) = 3.2;

varying vec3 v_base_color;

void fragment() {
	// Use world-space normal so slope coloring is camera-independent.
	vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float slope_angle_deg = degrees(acos(clamp(world_normal.y, 0.0, 1.0)));
	float grass_to_earth = smoothstep(
		grass_max_angle_deg - slope_blend_softness_deg,
		rock_min_angle_deg + slope_blend_softness_deg,
		slope_angle_deg
	);
	float earth_to_rock = smoothstep(
		rock_min_angle_deg - slope_blend_softness_deg,
		88.0,
		slope_angle_deg
	);
	vec3 mid = mix(grass_flat_color.rgb, earth_mid_color.rgb, grass_to_earth);
	v_base_color = mix(mid, rock_steep_color.rgb, earth_to_rock);
	ALBEDO = v_base_color;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = max(dot(NORMAL, LIGHT), 0.0);
	float b1 = 0.33;
	float b2 = 0.66;
	float soft = band_softness;

	// Cel bands with soft thresholds to prevent Transvoxel block artifacts.
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

	DIFFUSE_LIGHT += shaded * toon_tint * LIGHT_COLOR * ATTENUATION;

	float rim = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), rim_power);
	rim *= rim_strength * smoothstep(0.15, 0.85, ndl);
	DIFFUSE_LIGHT += rim_color.rgb * rim * ATTENUATION;
}
