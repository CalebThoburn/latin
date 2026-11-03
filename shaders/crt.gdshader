// Chunky pixel display: nearest-neighbour pixels with a dark grid between
// them and a little CRT falloff at the corners.
shader_type spatial;
render_mode unshaded, cull_back;

uniform sampler2D img : source_color, filter_nearest;
uniform vec2 res = vec2(104.0, 56.0);

void fragment() {
	vec3 c = texture(img, UV).rgb;
	vec2 cell = fract(UV * res);
	float grid = step(0.12, cell.x) * step(0.12, cell.y);
	c *= mix(0.7, 1.0, grid);
	vec2 d = UV - 0.5;
	c *= 1.0 - dot(d, d) * 0.9;
	ALBEDO = c * 1.15;
}
