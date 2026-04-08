shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

uniform vec4 flower_color : source_color = vec4(0.960784, 0.772549, 0.258824, 1.0);
uniform vec4 stem_color : source_color = vec4(0.176471, 0.329412, 0.14902, 1.0);

uniform vec4 lit_tint : source_color = vec4(0.98, 0.95, 0.88, 1.0);
uniform vec4 shadow_tint : source_color = vec4(0.34, 0.39, 0.30, 1.0);
uniform float band_softness : hint_range(0.01, 0.15) = 0.06;
uniform float shade_threshold : hint_range(0.2, 0.8) = 0.48;

void fragment() {
	float vt = clamp(UV.y, 0.0, 1.0);
	vec3 base = vt > 0.5 ? flower_color.rgb : stem_color.rgb;
	ALBEDO = base;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = max(dot(NORMAL, LIGHT), 0.0);
	float lit_band = smoothstep(shade_threshold - band_softness, shade_threshold + band_softness, ndl);
	vec3 toon = mix(shadow_tint.rgb, lit_tint.rgb, lit_band);
	DIFFUSE_LIGHT += ALBEDO * toon * LIGHT_COLOR * ATTENUATION;
}
