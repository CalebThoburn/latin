// Gentle full-screen finish: a little colour punch (Wind Waker is bright and
// saturated), a faint static paper tooth, and a soft vignette. Nothing moves.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float saturation = 1.12;
uniform float grain = 0.018;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec3 c = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(lum), c, saturation);
	float paper = vnoise(FRAGCOORD.xy * 0.5) * 0.5 + vnoise(FRAGCOORD.xy * 0.08) * 0.5;
	c *= 1.0 + (paper - 0.5) * grain * 2.0;
	vec2 d = SCREEN_UV - 0.5;
	c *= 1.0 - dot(d, d) * 0.3;
	COLOR = vec4(c, 1.0);
}
