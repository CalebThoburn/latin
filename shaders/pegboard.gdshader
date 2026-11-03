// Pegboard: a flat toon-lit board with a grid of dark holes.
shader_type spatial;
render_mode cull_back;

uniform vec4 albedo : source_color = vec4(0.79, 0.64, 0.45, 1.0);
uniform vec4 hole_color : source_color = vec4(0.25, 0.18, 0.13, 1.0);
uniform vec4 shade_tint : source_color = vec4(0.62, 0.64, 0.90, 1.0);
uniform float pitch = 0.075;
uniform float hole_r = 0.13;

varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 g = fract(wp.xy / pitch) - 0.5;
	float hole = 1.0 - step(hole_r, length(g));
	ALBEDO = mix(albedo.rgb, hole_color.rgb, hole);
}

void light() {
	float lit = step(0.02, dot(NORMAL, LIGHT)) * step(0.5, ATTENUATION);
	DIFFUSE_LIGHT += mix(shade_tint.rgb, vec3(1.0), lit) * LIGHT_COLOR / PI;
}
