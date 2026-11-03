class_name Art
extends RefCounted
## Shared look: marker font, toon + outline materials, UI styles.

const INK := Color(0.09, 0.07, 0.12)

static var font: SystemFont
static var toon_shader: Shader
static var toon_double_shader: Shader
static var outline_shader: Shader
static var _outlines := {}


static func setup() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Marker Felt", "Chalkboard SE", "Noteworthy", "Comic Sans MS"])
	toon_shader = load("res://shaders/toon.gdshader")
	toon_double_shader = load("res://shaders/toon_double.gdshader")
	outline_shader = load("res://shaders/outline.gdshader")


static func outline(mode: int, width: float) -> ShaderMaterial:
	var k := "%d_%.3f" % [mode, width]
	if not _outlines.has(k):
		var m := ShaderMaterial.new()
		m.shader = outline_shader
		m.set_shader_parameter("mode", mode)
		m.set_shader_parameter("width", 0.0034 * width)
		_outlines[k] = m
	return _outlines[k]


## outline_mode: -1 none, 0 box, 1 normals, 2 cylinder
static func toon(color: Color, outline_mode := 0, width := 1.0, double := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = toon_double_shader if double else toon_shader
	m.set_shader_parameter("albedo", color)
	if outline_mode >= 0:
		m.next_pass = outline(outline_mode, width)
	return m


static var _flat := {} # shared materials for plain decoration (no outline), one per colour


static func mesh(parent: Node3D, m: Mesh, pos: Vector3, color: Color, outline_mode := 0, width := 1.0, double := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	if outline_mode < 0 and not double: # decoration: share one material per colour
		var k := color.to_html()
		if not _flat.has(k):
			_flat[k] = toon(color, -1, width, false)
		mi.material_override = _flat[k]
	else:
		mi.material_override = toon(color, outline_mode, width, double)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, outline_mode := 0, width := 1.0) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return mesh(parent, bm, pos, color, outline_mode, width)


static func label3d(text: String, size: int, pixel := 0.001) -> Label3D:
	var l := Label3D.new()
	l.font = font
	l.text = text
	l.font_size = size
	l.pixel_size = pixel
	l.modulate = INK
	l.outline_size = 0
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return l


static func panel_style(bg: Color, border := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(border)
	s.border_color = INK
	s.set_corner_radius_all(12)
	s.shadow_color = Color(INK, 0.35)
	s.shadow_size = 0
	s.shadow_offset = Vector2(4, 5)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 9
	# a hair of skew so boxes feel hand-drawn
	s.skew = Vector2(0.015, 0)
	return s


static func make_theme() -> Theme:
	var th := Theme.new()
	th.default_font = font
	th.default_font_size = 20
	th.set_color("font_color", "Label", INK)
	th.set_stylebox("panel", "PanelContainer", panel_style(Color("#fff6dc")))
	var bn := panel_style(Color("#ffd23f"), 3)
	bn.content_margin_top = 3
	bn.content_margin_bottom = 4
	var bh := bn.duplicate() as StyleBoxFlat
	bh.bg_color = Color("#ffe27a")
	var bp := bn.duplicate() as StyleBoxFlat
	bp.bg_color = Color("#f0b400")
	th.set_stylebox("normal", "Button", bn)
	th.set_stylebox("hover", "Button", bh)
	th.set_stylebox("pressed", "Button", bp)
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		th.set_color(c, "Button", INK)
	return th
