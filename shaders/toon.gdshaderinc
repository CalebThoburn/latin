// Shared cel-shading (Wind Waker style): two crisp flat tones with a cool
// blue-violet shadow, a small hard specular pop and a thin rim light.
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 shade_tint : source_color = vec4(0.62, 0.64, 0.90, 1.0);
uniform float highlight = 0.0;
uniform float spec_strength = 0.18;
uniform float rim_strength = 0.14;

void fragment() {
	ALBEDO = albedo.rgb;
	EMISSION = albedo.rgb * highlight * 0.35 + vec3(1.0, 0.85, 0.3) * highlight * 0.12;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float shadow = step(0.5, ATTENUATION);
	float lit = step(0.02, ndl) * shadow;
	vec3 tone = mix(shade_tint.rgb, vec3(1.0), lit);
	vec3 h = normalize(LIGHT + VIEW);
	float spec = step(0.975, dot(NORMAL, h)) * lit * spec_strength;
	float rim = step(0.62, 1.0 - dot(NORMAL, VIEW)) * lit * rim_strength;
	// the sun is outside: it only adds light where it actually reaches (through
	// the garage-door windows); the lamps inside light everything, toon-shaded
	float gate = LIGHT_IS_DIRECTIONAL ? lit : 1.0;
	DIFFUSE_LIGHT += tone * LIGHT_COLOR / PI * gate;
	SPECULAR_LIGHT += vec3(spec + rim) * LIGHT_COLOR / PI * gate;
}
