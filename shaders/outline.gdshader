// Inverted-hull ink outline. Pushed out proportionally to view distance so
// lines keep a steady, even on-screen thickness. No jitter.
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;

uniform vec4 ink : source_color = vec4(0.09, 0.07, 0.12, 1.0);
uniform float width = 0.0035;
// 0 = box (grow along each axis), 1 = smooth normals, 2 = cylinder
uniform int mode = 0;

void vertex() {
	float dist = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	float w = width * dist;
	vec3 dir;
	if (mode == 0) {
		dir = sign(VERTEX);
	} else if (mode == 1) {
		dir = NORMAL;
	} else {
		vec2 r = VERTEX.xz;
		float l = length(r);
		vec2 rn = l > 0.0001 ? r / l : vec2(0.0);
		dir = vec3(rn.x, sign(VERTEX.y), rn.y);
	}
	VERTEX += dir * w;
}

void fragment() {
	ALBEDO = ink.rgb;
}
