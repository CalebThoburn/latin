class_name Tile
extends Node3D
## One piece. Noun stems / noun endings are rectangular blocks with the word
## on top. Verb pieces are rods lying on their side like batteries, with the
## word printed on the curved side:
##   verb stem   = fat rod + a thinner vowel "knob" sticking out the right end
##                 (like a battery terminal; consonant stems have no knob)
##   verb ending = thin insert plug (i / u) + fat rod with the rest of the ending;
##                 the plug slides inside a knob that is wider than it
##   ō           = a fat cap that slips over an ā knob and hides it

const S := 0.75 # overall size of the pieces
const H := 0.06 * S # block height; also the reference "floor" for every piece
const D := 0.16 * S
const FONT_SIZE := 72
const PIXEL := 0.001 * S

const R := 0.048 * S # verb rod radius
const AXIS_Y := -H * 0.5 + R # rods rest on the table
const KNOB_L := 0.055 * S # knob length == plug length, so a tucked plug vanishes
# Radii decide what fits inside what. The i / u inserts on endings are all
# PLUG_R. ē and -īre ī knobs are as fat as the stem; ā is a bit thinner (the ō cap
# slips over it); the (i) of capiō-type verbs is as thin as an insert.
const PLUG_R := {"i": 0.02 * S, "u": 0.02 * S, "e": 0.02 * S}
const KNOB_R := {"a": 0.036 * S, "e": R, "i": R, "(i)": 0.02 * S}
const CAP_R := R # ō is as fat as the stem
const CAP_L := 0.085 * S
const SIDE_TILT := 55.0 # where on the rod the print sits (degrees down from the top)

# nouns are little circuit boards: stems green, endings coloured by declension
const COL_NOUN := Color("#2f7a4b")
const COL_TRACE := Color("#e2b04a") # gold traces / pads
const COL_SILK := Color("#f4f1e6") # white silkscreen lettering
const PIN_R := 0.0045 * S # noun connector pins
const PIN_L := 0.02 * S
const PIN_CIRCLE := 0.016 * S # I, II, V: pins in a circle in the middle of the face
const PIN_SQ := 0.009 * S # III, IV: pins in two little squares, one at each end of the face
const SQ_Z := D * 0.5 - 0.022 * S # where those two squares sit (± z)
const COL_MAGNET := Color("#c0392b") # the shared -is / -ibus endings stick on by magnets
# endings shared by two declensions, and which declensions they fit
const SHARED := Latin.SHARED
const COL_VERB := Color("#b3c2cf") # machined steel
const COL_GROOVE := Color("#6c7c8c")
# Three knob sizes, three shades of gold: small ī = pale, ā = mid, ē = deep.
const COL_KNOB := {"(i)": Color("#f9e6a0"), "i": Color("#f5d873"), "a": Color("#e3a935"), "e": Color("#c4831c")}
const COL_VEND := Color("#dd8a4e") # copper (active)
const COL_PASS := Color("#8e9ad8") # passive endings: blued steel
const COL_NUT := Color("#c7ced6") # steel hex collar
const COL_PLUG := Color("#e8b54a") # brass
const COL_HOLE := Color("#1d1824")
# Hole in the end of a knob: just big enough for an i / u insert. The thin (i)
# knob has none: an i-ending's insert simply takes its place.
const HOLE_R := {"a": 0.021 * S, "e": 0.021 * S, "i": 0.021 * S}
const SOCKET_R := 0.038 * S # hole in the back of the ō cap: takes an ā knob, not an ē knob
# Genitive endings carry a holder on their back: a word stood on its side in it
# belongs to (is owned by) the genitive.
const GEN_GAP := 0.014 * S # from the ending's back face to the held word
const GEN_Z := -D * 0.5 - GEN_GAP - H * 0.5 # centre of the slot (local z)
const GEN_BASE := 0.006 # thickness of the holder's floor
const GEN_JAW_H := 0.05 * S
const GEN_JAW_W := 0.07 * S
const COL_GEN := Color("#8e5bd6")
const GEN_IN := 0.088 * S # how far the holder slides into the piece when put away

var kind := "stem" # "stem" | "ending"
var key := ""
var cat := "" # ending category: verb | decl1 | decl2
var width := 0.2
var is_source := false # lives in a drawer; dragging spawns a copy
var in_tray := false # lying loose in the stem tray
var loose_body: RigidBody3D = null
var target_pos := Vector3.ZERO
var move_tween: Tween

var is_rod := false
var vclass := "" # verb stems
var knob_x := 0.0 # centre of the knob (verb stems)
var plug := "" # verb endings
var is_block := false
# cables: a piece may carry a cord (plug end) and/or a socket (hole) for one
var cord_kind := "" # "nom" (subject cable) | "acc" (object cable) | ""
var cord_anchor := Vector3.ZERO
var cord_dir := Vector3(0, 0, -1) # which way the cable leaves the piece (local)
var cord_covered := false # an ending sits over the cable's exit (puer + ending)
var cord = null # the Cord node
var cord_prongs := 1 # square plugs: 1 prong = singular subject, 2 = plural
var socket_kind := ""
var socket_local := Vector3.ZERO # centre of the hole's mouth
var socket_basis := Basis.IDENTITY # socket frame: the hole runs along its -x
var socket_prongs := 1
# a piece can carry several cables: [{kind, prongs, anchor, dir, rest}] (the first
# one is also in cord_kind / cord_anchor / ... above)
var cord_specs: Array = []
var cords_out: Array = [] # the Cord nodes, in cord_specs order (cord == cords_out[0])
# more holes besides socket_* (socket 0): verbs' star holes for adverbs / prepositions
var extra_sockets: Array = [] # [{kind, local, basis, prongs}]
var soldered := false
var broken := false # (career mode: a mistake broke it: it's no good for anything but the bin)
var lock_cap: Node3D = null # covers an ending that isn't unlocked yet (campaign) # delivered as a whole word: its ending is soldered on for good
# adapter cables from the bins: little pucks that change what a hole / plug does
#   modi    - triangle (ablative) in, star out: an ablative goes straight into a verb
#   neut_sg - square in (a neuter's -um), subject blade out: -um used as nominative
#   neut_pl - a two-slot subject hole (a neuter's -a) and a square hole for the
#             verb's object cable: -a used as accusative
const ADAPTERS := {
	"modi": {"label": "MODVS", "col": Color("#e8862a")},
	"neut_sg": {"label": "N·SG", "col": Color("#c9a227")},
	"neut_pl": {"label": "N·PL", "col": Color("#8a9a3a")},
	"adj": {"label": "", "col": Color("#b8923a")}, # the adjective cap: no name, just its two cables
}
const CAP_W := 0.036 # the adjective cap: how long it is...
const CAP_OVER := 0.022 # ...and how much of the end of the ending it slips over
const PUCK_R := 0.05 # (an adapter: half its length: it's a short in-line coupler on a cable)
const PUCK_H := 0.024 # its height, at the end housings
const PUCK_D := 0.022 # its depth, at the end housings
var body_c := 0.0 # verb stems: centre and length of the round body
var body_l := 0.0
var gen_holder := false # genitive: has a holder a word can be stood in
var sub_label: Label3D = null
var gen_mats: Array = [] # the holder's materials (lit when a word can go in)
# Endings with more than one use: each use's part can slide away inside the piece
# while another use is in play. amt = how far out it is now, goal = where it's going.
var gen_node: Node3D = null # the genitive holder
var gen_amt := 1.0
var gen_goal := 1.0
var port_node: Node3D = null # the accusative socket's opening
var port_amt := 1.0
var port_goal := 1.0
# the reel turns smoothly; the ending only changes once it comes to rest
var reel_pos := 0.0
var reel_goal := 0.0
var reel_idle := 0.0
var reel_labels: Array = []
var reel_cx := 0.0
var joined := false
var touch := 0 # when it was last involved in a connection (for the display)
var reel_base := "" # noun endings with a window: the fixed first letter...
var reel_opts: Array = [] # ...and what the window can show after it
var choice := 0
var reel_label: Label3D = null
var win_x := Vector2.ZERO # local x range of the prism (scroll here to turn it)
# the reel is a prism: one option on each face, turned to bring one to the top
var reel_node: Node3D = null
var reel_n := 3 # its number of faces (at least three)
var reel_a := 0.0 # its apothem (centre to the middle of a face)
var reel_w := 0.0 # its length
var reel_lamp_on: Node3D = null # the macron over the fixed letter: lit for a long ablative (ā, ō, ē, ū)
var reel_lamp_off: Node3D = null
const FACE_FONT := 60
const REEL_FACE := 0.046 # each face at least this wide (so its writing is easy to read through the window)
const REEL_PORTS := 0.062 # room at the right of each face for its cable exit and its port
const REEL_END := 0.006 # the housing's end wall
var reel_facets: Array = [] # the prism's faces (their +y is the face's outward normal)
const COL_REEL := Color("#f1e8d2")
var mats: Array = []
var insert_parts: Array = [] # verb endings: the i / u insert (hidden when tucked away)
var label: Label3D
var body: StaticBody3D


static var blind := false # (a challenge: nouns made now get no gender colour)


static func color_for(p_kind: String, p_key: String, p_cat: String) -> Color:
	if blind and p_kind == "stem" and Latin.STEMS.has(p_key) and Latin.STEMS[p_key]["pos"] == "noun":
		return Color("#6b6f78")
	if p_kind == "stem":
		match Latin.STEMS[p_key]["pos"]:
			"noun": # the whole board is the colour of the noun's gender
				return {"m": Color("#2f7a4b"), "f": Color("#a83a3a"), "n": Color("#2e5aa8")}[Latin.genders(p_key)[0]]
			"prep": return Color("#3d5a99") # prepositions: navy boards
			"adj": return Color("#b88a2e") # adjectives: gold boards
			"adv": return Color("#6b4a93") # adverbs: purple boards
		return COL_VERB
	match p_cat:
		"verb": return COL_VEND
		"decl1": return Color("#b8413f")
		"decl3": return Color("#7d4bb3")
		"decl4": return Color("#c25a8a")
		"decl5": return Color("#b8862b")
		"decl12": return Color("#3c8c8c") # -is, shared by I and II
		"decl34": return Color("#a8673a") # -ibus, shared by III and IV
		"neut": return Color("#8a9a3a") # the neuter -a
		"adjm": return Latin.GENDER_COLOR["m"].darkened(0.15) # adjective endings: the colour of their gender
		"adjf": return Latin.GENDER_COLOR["f"].darkened(0.15)
		"adjn": return Latin.GENDER_COLOR["n"].darkened(0.15)
		_: return Color("#2e63b5")


static func text_w(t: String, size: int) -> float:
	return Art.font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * PIXEL


func setup(p_kind: String, p_key: String, p_cat := "", source := false) -> Tile:
	kind = p_kind
	key = p_key
	cat = p_cat
	is_source = source
	if kind == "adapter":
		_build_adapter()
	elif kind == "stem" and Latin.STEMS[key]["pos"] in ["prep", "adv"]:
		_build_remote()
	elif kind == "stem" and Latin.STEMS[key]["pos"] == "verb":
		_build_verb_stem()
	elif kind == "ending" and cat == "verb":
		_build_verb_ending()
	else:
		_build_block()

	_setup_links()
	_make_body()
	bake_decor()
	return self


## An ending with a window, e.g. a[_]: base "a" and a reel of what can follow.
func setup_reel(base: String, p_cat: String) -> Tile:
	reel_base = base
	reel_opts = Latin.REELS[p_cat][base]
	choice = 0
	return setup("ending", Latin.reel_form(base, reel_opts[0]), p_cat)


func is_reel() -> bool:
	return reel_base != ""


func collapsed() -> bool: # (reels used to telescope shut into ā; now the piece stays the same size)
	return false


## A long-vowel option on a reel (the ablative ā, ō, ē, ū): shown as a macron.
func long_opt(o: String) -> bool:
	return Latin.is_long(o) or (cat == "decl2" and reel_base == "o" and o == "")


## Scroll the window: rebuild the piece as the new ending (it may telescope
## shut into ā, or back open). Returns the old width so the caller can animate.
func set_choice(i: int) -> float:
	var old_w := width
	choice = posmod(i, reel_opts.size())
	key = Latin.reel_form(reel_base, reel_opts[choice])
	var old_gen := gen_node
	var old_gen_amt := gen_amt
	var old_port := port_node
	var old_port_amt := port_amt
	if old_port and old_port.get_parent() != self: # (it was on the old prism: keep it where it is while it goes)
		old_port.reparent(self)
	for c in get_children():
		if c == old_gen or c == old_port:
			continue
		remove_child(c)
		c.queue_free()
	gen_node = null
	port_node = null
	reel_labels = []
	reel_node = null
	reel_facets = []
	reel_lamp_on = null
	reel_lamp_off = null
	mats = []
	insert_parts = []
	label = null
	reel_label = null
	body = null
	cord_kind = ""
	cord_prongs = 1
	cord_anchor = Vector3.ZERO
	cord_dir = Vector3(0, 0, -1)
	socket_kind = ""
	socket_local = Vector3.ZERO
	socket_basis = Basis.IDENTITY
	socket_prongs = 1
	cord_specs = []
	extra_sockets = []
	gen_holder = false
	gen_mats = []
	sub_label = null
	_build_block()
	_setup_links()
	_make_body()
	bake_decor()
	set_pickable(not in_tray)
	reel_pos = choice
	reel_goal = choice
	_layout_reel()
	# the holder / port carry on where they were, slide out new, or slide away
	gen_amt = (old_gen_amt if old_gen else 0.0) if gen_node else 1.0
	port_amt = (old_port_amt if old_port else 0.0) if port_node else 1.0
	gen_goal = 1.0
	port_goal = 1.0
	for pair in [[old_gen, gen_node != null], [old_port, port_node != null]]:
		var n: Node3D = pair[0]
		if n == null:
			continue
		if pair[1] or not is_inside_tree():
			n.queue_free()
		else:
			var tw := create_tween()
			if n == old_gen:
				tw.tween_property(n, "position:z", GEN_IN, 0.35).set_trans(Tween.TRANS_SINE)
			else:
				tw.tween_property(n, "scale", Vector3(1, 0.001, 0.001), 0.3).set_trans(Tween.TRANS_SINE)
			tw.tween_callback(n.queue_free)
	_apply_parts()
	return old_w


func _make_body() -> void:
	body = StaticBody3D.new()
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	cs.shape = pick_shape()
	cs.position = shape_offset()
	body.add_child(cs)
	body.set_meta("tile", self)
	add_child(body)


func _setup_links() -> void:
	if kind == "adapter":
		_adapter_links()
	elif kind == "stem" and is_rod:
		if Latin.STEMS[key].get("trans", false):
			cord_kind = "acc" # takes a direct object
			cord_anchor = Vector3(label.position.x, AXIS_Y, -R)
			if Latin.STEMS[key].get("dat", false): # ...and someone it's given to: a purple cable beside it
				cord_specs.append({"kind": "acc", "prongs": 1, "anchor": cord_anchor, "dir": cord_dir})
				cord_specs.append({"kind": "dat", "prongs": 1, "anchor": cord_anchor + Vector3(0.03, 0, 0), "dir": cord_dir,
						"rest": Vector3(0.09, 0, -0.14)})
		# the computer's display cable plugs into a ring-shaped socket in the left end of a verb
		socket_kind = "disp"
		socket_local = Vector3(-width * 0.5, AXIS_Y, 0)
		socket_basis = Basis(Vector3.UP, PI) # (its hole faces out of the left end)
		_ring_socket(Vector3(-width * 0.5, AXIS_Y, 0))
		# two star-shaped holes low on the front of the body: adverbs and
		# prepositions plug in here
		var a := deg_to_rad(STAR_ANGLE)
		var n := Vector3(0, cos(a), sin(a)) # out of the rod's surface
		var sb := Basis(n, Vector3(0, n.z, -n.y), Vector3(-1, 0, 0))
		var off := maxf(0.22 * body_l, 0.026) # well apart, even on a short verb
		for f in [-1.0, 1.0]:
			var loc := Vector3(clampf(body_c + f * off, -width * 0.5 + 0.012, width * 0.5 - 0.012), AXIS_Y + n.y * R, n.z * R)
			extra_sockets.append({"kind": "star", "local": loc, "basis": sb, "prongs": 1})
			_star_hole(loc, sb)
	elif kind == "stem" and Latin.STEMS[key].get("bare_nom", false):
		# puer is already its own nominative: the subject cable comes straight out of
		# its right end (and is covered up when an ending goes on)
		cord_kind = "nom"
		cord_prongs = 1
		cord_anchor = Vector3(width * 0.5, 0, -0.05 * S)
		cord_dir = Vector3.RIGHT
		if Latin.STEMS[key].get("neuter", false): # lītus, nihil: also accusative: a square hole in the back
			socket_kind = "acc"
			socket_local = Vector3(0, 0, -D * 0.5)
			socket_basis = Basis(Vector3(0, 0, -1), Vector3.UP, Vector3(1, 0, 0))
			port_node = Node3D.new()
			port_node.transform = Transform3D(socket_basis, socket_local + Vector3(0, 0, -0.001))
			add_child(port_node)
			Art.box(port_node, Vector3(0.004, Cord.ACC_PRONG + 0.006, Cord.ACC_PRONG + 0.006), Vector3.ZERO, COL_HOLE, -1)
	elif kind == "stem" and Latin.STEMS[key]["pos"] in ["prep", "adv"]:
		# a star plug for the verb, out of the back...
		cord_kind = "star"
		cord_anchor = Vector3(-width * 0.25, 0, -D * 0.5)
		cord_dir = Vector3(0, 0, -1)
		cord_specs.append({"kind": "star", "prongs": 1, "anchor": cord_anchor, "dir": cord_dir, "rest": Vector3(-0.04, 0, -0.14)})
		# ...and for a preposition, a square (+ acc.) / triangular (+ abl.) plug out of its right end
		var cases: Array = Latin.STEMS[key].get("cases", [])
		for c in cases:
			var z := 0.0 if cases.size() == 1 else (0.012 if c == "acc" else -0.012)
			cord_specs.append({"kind": c, "prongs": 1, "anchor": Vector3(width * 0.5, 0, z), "dir": Vector3.RIGHT,
					"rest": Vector3(0.1, 0, z * 5.0)})
	elif kind == "ending" and cat == "verb":
		socket_kind = "nom" # the subject plugs in here: one slot singular, two plural
		socket_prongs = 2 if Latin.VERB_ENDINGS[key]["num"] == "pl" else 1
		var sx := (width * 0.5 + 0.0105) if key in Latin.CAPS else width * 0.5
		socket_local = Vector3(sx, AXIS_Y, 0)
		for z in Cord.prong_z(socket_prongs):
			Art.box(self, Vector3(0.004, 0.0, 0.0) + Cord.prong_section(socket_prongs) + Vector3(0, 0.005, 0.005), Vector3(sx + 0.001, AXIS_Y, z), COL_HOLE, -1)
	elif kind == "ending" and cat.begins_with("adj"):
		# a gender cable (its colour: into the top of a noun stem) and an agreement
		# cable (into the top of the noun's ending: case and number must match)
		var g: String = Latin.ADJ_GENDER[cat]
		cord_kind = "aux"
		cord_anchor = Vector3(-width * 0.2, 0, -D * 0.5)
		cord_dir = Vector3(0, 0, -1)
		cord_specs.append({"kind": "aux", "prongs": 1, "anchor": cord_anchor, "dir": cord_dir, "rest": Vector3(-0.05, 0, -0.14),
				"col": Latin.GENDER_COLOR[g], "gender": g})
		cord_specs.append({"kind": "agree", "prongs": 1, "anchor": Vector3(width * 0.2, 0, -D * 0.5), "dir": cord_dir, "rest": Vector3(0.06, 0, -0.14)})
	elif kind == "ending":
		gen_holder = Latin.has_case(cat, key, "gen")
		if gen_holder:
			_build_gen_holder()
		var nom_nums := []
		for r in Latin.NOUN_ENDINGS[cat][key]:
			if r[0] == "nom":
				nom_nums.append(r[1])
			if r[0] == "acc" and cat != "neut": # neuter -a: subject cable only (N·PL makes it an object)
				socket_kind = "acc"
				socket_local = _port_local()
				socket_basis = _port_basis()
				port_node = _new_port()
				Art.box(port_node, Vector3(0.004, Cord.ACC_PRONG + 0.006, Cord.ACC_PRONG + 0.006), Vector3.ZERO, COL_HOLE, -1)
			if r[0] == "abl" and socket_kind == "": # a triangular hole: prepositions + ablative
				socket_kind = "abl"
				socket_local = _port_local()
				socket_basis = _port_basis()
				port_node = _new_port()
				Art.mesh(port_node, Cord.tri_prism(Cord.TRI_R + 0.003, 0.004), Vector3.ZERO, COL_HOLE, -1, 1.0, true)
		if not nom_nums.is_empty():
			cord_kind = "nom"
			cord_prongs = 2 if nom_nums[0] == "pl" else 1
			# the back is taken by the genitive holder: the cable leaves from the front
			cord_dir = Vector3(0, 0, 1) if gen_holder else Vector3(0, 0, -1)
			cord_anchor = Vector3(0, 0, D * 0.5 if gen_holder else -D * 0.5)
			if reel_node: # on a reel: up out of the face that's up, through the window
				cord_dir = Vector3.UP
				cord_anchor = Vector3(reel_cx + _cable_x(0, nom_nums.size()), reel_top + 0.001, 0) # (from the window's opening)
				if nom_nums.size() == 1:
					cord_specs.append({"kind": "nom", "prongs": cord_prongs, "anchor": cord_anchor, "dir": cord_dir, "rest": Vector3(-0.02, 0, -0.17)})
			if nom_nums.size() > 1 and reel_node:
				cord_specs.append({"kind": "nom", "prongs": 1, "anchor": cord_anchor, "dir": cord_dir, "rest": Vector3(-0.05, 0, -0.17)})
				cord_specs.append({"kind": "nom", "prongs": 2, "anchor": Vector3(reel_cx + _cable_x(1, 2), reel_top + 0.001, 0), "dir": cord_dir, "rest": Vector3(0.07, 0, -0.17)})
			elif nom_nums.size() > 1: # 5th decl. -ēs: singular OR plural: a cable for each
				cord_prongs = 1
				cord_anchor = Vector3(-0.025 * S, 0, -D * 0.5)
				cord_specs.append({"kind": "nom", "prongs": 1, "anchor": cord_anchor, "dir": cord_dir, "rest": Vector3(-0.05, 0, -0.14)})
				cord_specs.append({"kind": "nom", "prongs": 2, "anchor": Vector3(0.025 * S, 0, -D * 0.5), "dir": cord_dir, "rest": Vector3(0.07, 0, -0.14)})
	if cord_specs.is_empty() and cord_kind != "":
		cord_specs.append({"kind": cord_kind, "prongs": cord_prongs, "anchor": cord_anchor, "dir": cord_dir})

	# adjectives plug into nouns from above: a gender jack on every noun stem (where
	# the word is), and an agreement socket on whatever carries the noun's case
	if kind == "stem" and Latin.STEMS[key]["pos"] == "noun":
		_top_socket("aux", Vector3(-width * 0.3, H * 0.5, -D * 0.2))
		if Latin.STEMS[key].get("bare_nom", false): # puer, rēx: the bare stem is the case-bearer
			_top_socket("agree", Vector3(width * 0.3, H * 0.5, -D * 0.2))
	elif kind == "ending" and cat != "verb" and not cat.begins_with("adj"):
		var sx1 := width * 0.5 - (reel_w + REEL_END if is_reel() else 0.0) # (on the board, not over the prism)
		_top_socket("agree", Vector3(lerpf(-width * 0.5, sx1, 0.25), H * 0.5, -D * 0.25))
		if Latin.has_case(cat, key, "dat"): # a dative: a round purple-ringed hole for a dative verb's cable
			_top_socket("dat", Vector3(lerpf(-width * 0.5, sx1, 0.75), H * 0.5, -D * 0.25))


## A socket in the top face of a piece (its hole points up).
func _top_socket(k: String, loc: Vector3) -> void:
	var b := Basis(Vector3.UP, Vector3.LEFT, Vector3.BACK)
	extra_sockets.append({"kind": k, "local": loc, "basis": b, "prongs": 1})
	if k == "aux": # a jack, ringed in the noun's gender colour(s)
		var gs := Latin.genders(key)
		if blind: # (no telling)
			gs = ["x"]
		var ring := CylinderMesh.new()
		ring.top_radius = 0.011
		ring.bottom_radius = 0.011
		ring.height = 0.003
		Art.mesh(self, ring, loc + Vector3(0, 0.0012, 0), Latin.GENDER_COLOR.get(gs[0], Color("#9aa0a8")), -1)
		if gs.size() > 1: # (either gender: a dot of the other colour)
			var dot := CylinderMesh.new()
			dot.top_radius = 0.004
			dot.bottom_radius = 0.004
			dot.height = 0.0034
			Art.mesh(self, dot, loc + Vector3(0.008, 0.0013, 0), Latin.GENDER_COLOR[gs[1]], -1)
		var hole := CylinderMesh.new()
		hole.top_radius = Cord.AUX_R + 0.002
		hole.bottom_radius = Cord.AUX_R + 0.002
		hole.height = 0.0036
		Art.mesh(self, hole, loc + Vector3(0, 0.0014, 0), COL_HOLE, -1)
	elif k == "dat":
		var dr := CylinderMesh.new()
		dr.top_radius = Cord.DAT_R + 0.005
		dr.bottom_radius = Cord.DAT_R + 0.005
		dr.height = 0.003
		Art.mesh(self, dr, loc + Vector3(0, 0.0012, 0), Cord.COL["dat"], -1)
		var dh := CylinderMesh.new()
		dh.top_radius = Cord.DAT_R + 0.0015
		dh.bottom_radius = Cord.DAT_R + 0.0015
		dh.height = 0.0036
		Art.mesh(self, dh, loc + Vector3(0, 0.0014, 0), COL_HOLE, -1)
	else: # a small square socket, gold-rimmed
		Art.box(self, Vector3(Cord.AGREE_P + 0.008, 0.003, Cord.AGREE_P + 0.008), loc + Vector3(0, 0.0012, 0), COL_TRACE, -1)
		Art.box(self, Vector3(Cord.AGREE_P + 0.002, 0.0034, Cord.AGREE_P + 0.002), loc + Vector3(0, 0.0014, 0), COL_HOLE, -1)
		if kind == "stem": # (puer, vir: shut by a little cover in the board's colour once an ending goes on)
			agree_cap = Art.box(self, Vector3(Cord.AGREE_P + 0.004, 0.0038, Cord.AGREE_P + 0.004), loc + Vector3(0, 0.0015, 0), color_for(kind, key, cat), -1)
			agree_cap.visible = false


const STAR_ANGLE := 100.0 # where the star holes sit round a verb (degrees from the top, toward you)


## Socket i of this piece (0 = the main one): {kind, local, basis, prongs}.
func sock(i: int) -> Dictionary:
	if i == 0:
		return {"kind": socket_kind, "local": socket_local, "basis": socket_basis, "prongs": socket_prongs}
	return extra_sockets[i - 1]


func sock_count() -> int:
	return 1 + extra_sockets.size()


## A six-pointed star hole (seen from outside, in the socket frame's y-z plane).
func _star_hole(loc: Vector3, b: Basis) -> void:
	var n := Node3D.new()
	n.transform = Transform3D(b, loc + b.x * 0.0005)
	add_child(n)
	for k in 3:
		var arm := Art.box(n, Vector3(0.004, Cord.STAR_R * 2.0 + 0.004, Cord.STAR_T + 0.003), Vector3.ZERO, COL_HOLE, -1)
		arm.rotation.x = PI / 3.0 * k


## The genitive's holder: a little violet clamp on the back of the ending. A noun
## word stands on its side between the two jaws, its printed face toward you.
func _build_gen_holder() -> void:
	var bottom := -H * 0.5
	var back := GEN_Z - H * 0.5 - 0.009
	var front := -D * 0.5
	gen_node = Node3D.new()
	add_child(gen_node)
	gen_mats.append(Art.box(gen_node, Vector3(GEN_JAW_W, GEN_BASE, front - back), Vector3(0, bottom + GEN_BASE * 0.5, (front + back) * 0.5), COL_GEN, 0, 0.5).material_override)
	for z: float in [front - 0.004, back + 0.003]:
		gen_mats.append(Art.box(gen_node, Vector3(GEN_JAW_W, GEN_JAW_H, 0.006), Vector3(0, bottom + GEN_BASE + GEN_JAW_H * 0.5, z), COL_GEN, 0, 0.5).material_override)
	Art.box(gen_node, Vector3(GEN_JAW_W - 0.02, 0.002, H - 0.01), Vector3(0, bottom + GEN_BASE + 0.001, GEN_Z), COL_HOLE, -1) # the slot


## Centre of the bottom of the genitive slot (local).
func gen_slot() -> Vector3:
	return Vector3(0, -H * 0.5 + GEN_BASE, GEN_Z)


## Half extents of the solid box used for picking and for plugs bumping into it.
func box_half() -> Vector3:
	if kind == "adapter" and key == "adj":
		return Vector3(CAP_W, H + 0.008, D + 0.008) * 0.5
	if kind == "adapter":
		return Vector3(PUCK_R, PUCK_H * 0.5, PUCK_D * 0.5)
	return (Vector3(width, 2.0 * R, 2.0 * R) if is_rod else Vector3(width, H, D)) * 0.5


## Collision shape for picking.
func pick_shape() -> Shape3D:
	var sh := BoxShape3D.new()
	if kind == "adapter":
		sh.size = box_half() * 2.0 if key == "adj" else Vector3(PUCK_R * 2.0, PUCK_H, PUCK_D + 0.01)
		return sh
	sh.size = Vector3(width, 2.0 * R, 2.0 * R) if is_rod else Vector3(width, H, D)
	return sh


## Collision shape for physics while loose in the tray (rods really roll).
func physics_shape() -> Shape3D:
	if is_rod:
		var c := CylinderShape3D.new()
		c.radius = R
		c.height = width
		return c
	return pick_shape()


func shape_offset() -> Vector3:
	if kind == "adapter" and key == "adj":
		return Vector3.ZERO
	if kind == "adapter":
		return Vector3(0, -H * 0.5 + PUCK_H * 0.5, 0)
	return Vector3(0, AXIS_Y, 0) if is_rod else Vector3.ZERO


## A metal cylinder lying along x (like a battery). segs = 6 makes a hex nut.
func _rod(r: float, length: float, cx: float, color: Color, segs := 40, outline := 2) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = length
	cm.radial_segments = segs
	var mi := Art.mesh(self, cm, Vector3(cx, AXIS_Y, 0), color, outline, 0.7, outline < 0) # (own material: it lights up)
	mi.rotation_degrees.z = 90
	var m: ShaderMaterial = mi.material_override
	m.set_shader_parameter("spec_strength", 0.6)
	m.set_shader_parameter("rim_strength", 0.35)
	mats.append(m)
	return mi


## A dark hole bored into the end face at x = face_x.
func _hole(r: float, face_x: float) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.004
	cm.radial_segments = 32
	var mi := Art.mesh(self, cm, Vector3(face_x, AXIS_Y, 0), COL_HOLE, -1)
	mi.rotation_degrees.z = 90


## The display socket: a ring-shaped slot (a dark circle round a post) in a
## bright collar, for the computer's hollow ring plug. Faces out of the left end (-x).
func _ring_socket(at: Vector3) -> void:
	for part in [[Cord.DISP_R + 0.007, 0.003, Color("#d4dae0")], [Cord.DISP_R + 0.0015, 0.0036, COL_HOLE], [Cord.DISP_R_IN - 0.001, 0.0042, Color("#d4dae0")]]:
		var cm := CylinderMesh.new()
		cm.top_radius = part[0]
		cm.bottom_radius = part[0]
		cm.height = part[1]
		cm.radial_segments = 32
		var mi := Art.mesh(self, cm, at + Vector3(-part[1] * 0.5 + 0.001, 0, 0), part[2], -1)
		mi.rotation_degrees.z = 90


## Print text on the side of a rod of radius r, facing the camera.
func _side_label(t: String, size: int, cx: float, r: float, tilt := SIDE_TILT) -> Label3D:
	var a := deg_to_rad(tilt)
	var l := Art.label3d(t, size, PIXEL)
	l.position = Vector3(cx, AXIS_Y + cos(a) * (r + 0.002), sin(a) * (r + 0.002))
	l.rotation_degrees = Vector3(-(90.0 - tilt), 0, 0)
	add_child(l)
	return l


func _build_block() -> void:
	is_block = true
	var longest := (key + "-") if kind == "stem" else ("-" + key)
	if kind == "stem" and not Latin.takes_ending(key):
		longest = Latin.nom_form(key)
	width = maxf(0.12 * S, text_w(longest, FONT_SIZE) + 0.065 * S)
	var nom := Latin.nom_form(key) if kind == "stem" else ""
	if nom != "" and nom != key:
		width = maxf(width, text_w(nom, FONT_SIZE) + 0.065 * S)
	var w_base := 0.0
	var w_win := 0.0
	if is_reel():
		w_base = text_w("-" + reel_base, FONT_SIZE)
		for o in reel_opts:
			w_win = maxf(w_win, text_w(o, FACE_FONT))
		w_win = maxf(0.03 * S, w_win + 0.016) + REEL_PORTS # (each face: its letters, then its cable exit and port)
		width = w_base + w_win + REEL_END + 0.05 * S
	var board := color_for(kind, key, cat)
	var slab_w := width - (w_win + REEL_END if w_win > 0.0 else 0.0) # (a reel's housing takes the right end)
	var mi := Art.box(self, Vector3(slab_w, H, D), Vector3(-(width - slab_w) * 0.5, 0, 0), board, 0, 0.7)
	mats.append(mi.material_override)
	var n0 := get_child_count()
	var full := width
	width = slab_w # (the traces are on the board, not over the prism)
	_circuit(board)
	width = full
	for i in range(n0, get_child_count()):
		var dc := get_child(i)
		if dc is Node3D:
			dc.position.x -= (full - slab_w) * 0.5
	if w_win > 0.0: # the housing round the prism: a box (a bit taller than the board) with a window in its top
		var hx := width * 0.5 - REEL_END - w_win * 0.5
		var dims := _reel_dims()
		var hh: float = dims[2]
		var yc: float = dims[1]
		var fw: float = dims[3] # (the window: as wide as one face)
		var wall := (D - fw) * 0.5
		for sz in [-1.0, 1.0]:
			var wm := Art.box(self, Vector3(w_win, hh, wall), Vector3(hx, yc, sz * (fw * 0.5 + wall * 0.5)), board, 0, 0.7)
			mats.append(wm.material_override)
		var em := Art.box(self, Vector3(REEL_END, hh, D), Vector3(width * 0.5 - REEL_END * 0.5, yc, 0), board, 0, 0.7)
		mats.append(em.material_override)
		Art.box(self, Vector3(w_win, 0.003, fw), Vector3(hx, -H * 0.5 + 0.0015, 0), board.darkened(0.4), -1) # (its floor)
		var top := yc + hh * 0.5
		for sz in [-1.0, 1.0]: # a metal frame round the window
			Art.box(self, Vector3(w_win + 0.008, 0.0015, 0.004), Vector3(hx, top + 0.0008, sz * (fw * 0.5 + 0.002)), COL_TRACE, -1)
		for sx in [-1.0, 1.0]:
			Art.box(self, Vector3(0.004, 0.0015, fw + 0.008), Vector3(hx + sx * (w_win * 0.5 + 0.002), top + 0.0008, 0), COL_TRACE, -1)
	label = Art.label3d("", FONT_SIZE, PIXEL)
	label.modulate = COL_SILK
	label.outline_size = 0
	label.rotation_degrees = Vector3(-90, 0, 0)
	label.position = Vector3(0, H * 0.5 + 0.002, 0.004)
	add_child(label)
	if w_win > 0.0: # the prism, in its housing at the right end: an option on each face
		label.position.x = -width * 0.5 + 0.03 + w_base * 0.5
		var cx := width * 0.5 - REEL_END - w_win * 0.5
		win_x = Vector2(cx - w_win * 0.5, cx + w_win * 0.5)
		reel_cx = cx
		_build_prism(cx, w_win)
		# the macron over the fixed letter: it lights up for a long ablative
		var lamps := Node3D.new()
		add_child(lamps)
		reel_lamp_off = Node3D.new()
		lamps.add_child(reel_lamp_off)
		reel_lamp_on = Node3D.new()
		lamps.add_child(reel_lamp_on)
		var lw := text_w(reel_base, FONT_SIZE) * 0.8
		Art.box(reel_lamp_off, Vector3(lw, 0.0016, 0.0045), Vector3.ZERO, board.darkened(0.35), -1)
		Art.box(reel_lamp_on, Vector3(lw, 0.0024, 0.0055), Vector3.ZERO, Color("#fff27a"), -1)
		_layout_reel()
	else:
		win_x = Vector2.ZERO
	if nom != "" and nom != key: # rēx is its own nominative; its stem rēg- is printed small
		sub_label = Art.label3d(key + "-", 30, PIXEL)
		sub_label.modulate = COL_TRACE
		sub_label.outline_size = 0
		sub_label.rotation_degrees = Vector3(-90, 0, 0)
		sub_label.position = Vector3(0, H * 0.5 + 0.002, D * 0.5 - 0.022)
		add_child(sub_label)
		label.position.z = -0.012 * S
	if kind == "ending" or Latin.takes_ending(key):
		_noun_connector()
	set_joined(false)


## Circuit-board dressing on top of a noun block: gold traces running along the
## edges into round pads, a few vias, a little chip in the corner.
func _circuit(board: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind + key + cat)
	var top := H * 0.5 + 0.0008
	var hw := width * 0.5
	var e := 0.012 * S # inset of the edge traces
	var lane_z := [-D * 0.5 + e, D * 0.5 - e]
	for z: float in lane_z:
		var x0 := -hw + e
		var x1 := hw - e
		var brk := rng.randf_range(x0 + 0.02 * S, x1 - 0.02 * S)
		var dz := (e if z < 0.0 else -e)
		Art.box(self, Vector3(brk - x0, 0.0015, 0.004 * S), Vector3((x0 + brk) * 0.5, top, z), COL_TRACE, -1)
		Art.box(self, Vector3(0.004 * S, 0.0015, absf(dz)), Vector3(brk, top, z + dz * 0.5), COL_TRACE, -1)
		Art.box(self, Vector3(x1 - brk, 0.0015, 0.004 * S), Vector3((brk + x1) * 0.5, top, z + dz), COL_TRACE, -1)
		for px: float in [x0, x1]:
			_pad(Vector3(px, top, z if px == x0 else z + dz), 0.006 * S)
	for k in 2: # vias
		_pad(Vector3(rng.randf_range(-hw + 0.02 * S, hw - 0.02 * S), top, rng.randf_range(-0.02, 0.02) * S + (0.045 if k == 0 else -0.045) * S), 0.0035 * S)
	# a small chip with legs, tucked into the back-right corner clear of the lettering
	var cx := hw - 0.026 * S
	var cz := -D * 0.5 + 0.016 * S
	if width > 0.15 * S:
		Art.box(self, Vector3(0.03 * S, 0.005, 0.016 * S), Vector3(cx, top + 0.0025, cz + 0.006 * S), Color("#1b1b22"), 0, 0.4)
		for lx in [-0.009, 0.0, 0.009]:
			Art.box(self, Vector3(0.003 * S, 0.002, 0.004 * S), Vector3(cx + lx * S, top + 0.001, cz + 0.017 * S), Color("#c7ced6"), -1)
	# board edge: a thin light stripe of fibreglass between the copper layers
	Art.box(self, Vector3(width + 0.001, 0.006, D + 0.001), Vector3(0, -H * 0.5 + 0.006, 0), board.lightened(0.35), -1)


func _pad(p: Vector3, r: float) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.0016
	cm.radial_segments = 16
	Art.mesh(self, cm, p, COL_TRACE, -1)


## The connector where a noun stem meets its ending. The pins say which
## declension it is (the ending has the pins, the stem the matching holes in a
## white face):
##   I, II, V  - pins in a circle in the middle of the face (1, 2 or 5 of them)
##   III, IV   - two little squares of pins, one at each end of the face
##               (3 pins in each for III, 4 for IV)
## The shared endings have no pins, they stick on by magnets: -is (I and II) has
## a round magnet that fits the middle circle; -ibus (III and IV) has two square
## magnets that fit the two squares. That's why -ibus won't go on a I or II stem.
func _noun_connector() -> void:
	var stem := kind == "stem"
	var face := width * 0.5 if stem else -width * 0.5
	var out := 1.0 if stem else -1.0
	if not stem and cat.begins_with("adj"): # (old adjective endings: a plain round magnet face)
		_disc(Vector3(face + out * 0.0015, 0, 0), PIN_CIRCLE + 0.009 * S, 0.003, COL_MAGNET)
		return
	var adj_stem: bool = stem and Latin.STEMS[key]["pos"] == "adj" # takes the I and II endings: II's two holes (I's one pin fits the top one)
	var decl := (2 if adj_stem else int(Latin.STEMS[key]["decl"])) if stem else 0
	if not stem and not SHARED.has(cat):
		decl = int(cat.substr(4))
	if not stem and cat == "decl12": # round magnet
		_disc(Vector3(face - 0.0015, 0, 0), PIN_CIRCLE + 0.009 * S, 0.003, COL_MAGNET)
		_disc(Vector3(face - 0.003, 0, 0), PIN_CIRCLE + 0.004 * S, 0.0015, Color("#d8dde2"))
		return
	if not stem and cat == "neut": # neuter -a: a round magnet AND two square ones: fits II and III
		_disc(Vector3(face - 0.0015, 0, 0), PIN_CIRCLE + 0.009 * S, 0.003, COL_MAGNET)
		_disc(Vector3(face - 0.003, 0, 0), PIN_CIRCLE + 0.004 * S, 0.0015, Color("#d8dde2"))
	if not stem and (cat == "decl34" or cat == "neut"): # two square magnets
		for sz in [-1, 1]:
			var c := Vector3(face - 0.0015, 0, sz * SQ_Z)
			Art.box(self, Vector3(0.003, PIN_SQ * 2.6, PIN_SQ * 2.6), c, COL_MAGNET, -1)
			Art.box(self, Vector3(0.0015, PIN_SQ * 1.6, PIN_SQ * 1.6), c + Vector3(-0.0015, 0, 0), Color("#d8dde2"), -1)
		return
	var pins := [] # positions on the face (y, z)
	if decl == 3 or decl == 4:
		var corners := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
		for sz in [-1, 1]:
			Art.box(self, Vector3(0.003, PIN_SQ * 2.6, PIN_SQ * 2.6), Vector3(face + out * 0.0012, 0, sz * SQ_Z),
					Color("#f4f1e6") if stem else COL_TRACE, -1)
			for k in decl: # III leaves one corner of each square empty
				pins.append(Vector3(0, corners[k].y * PIN_SQ * 0.6, sz * SQ_Z + corners[k].x * PIN_SQ * 0.6))
	else:
		_disc(Vector3(face + out * 0.0012, 0, 0), PIN_CIRCLE + 0.009 * S, 0.003, Color("#f4f1e6") if stem else COL_TRACE)
		var r := PIN_CIRCLE * (0.8 if decl == 5 else 1.0)
		for k in decl:
			var a := PI * 0.5 + TAU * k / decl
			pins.append(Vector3(0, sin(a) * r, cos(a) * r))
	var pr := PIN_R * (0.7 if decl == 3 or decl == 4 else 1.0)
	for p in pins:
		var cm := CylinderMesh.new()
		cm.radial_segments = 10
		if stem: # holes
			cm.top_radius = pr + 0.0015
			cm.bottom_radius = pr + 0.0015
			cm.height = 0.004
			var h := Art.mesh(self, cm, p + Vector3(face + 0.002, 0, 0), Color("#050407"), -1)
			h.rotation_degrees.z = 90
		else: # gold pins sticking out to the left
			cm.top_radius = pr
			cm.bottom_radius = pr
			cm.height = PIN_L
			var pin := Art.mesh(self, cm, p + Vector3(face - PIN_L * 0.5, 0, 0), COL_TRACE, 1, 0.4)
			pin.rotation_degrees.z = 90


func _disc(c: Vector3, r: float, h: float, col: Color) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 24
	var m := Art.mesh(self, cm, c, col, -1)
	m.rotation_degrees.z = 90


func _build_verb_stem() -> void:
	is_rod = true
	var s: Dictionary = Latin.STEMS[key]
	vclass = s["vclass"]
	var bl := maxf(0.1 * S, text_w(s["cons"], 56) + 0.05 * S)
	var has_knob := KNOB_R.has(vclass)
	width = bl + (KNOB_L if has_knob else 0.0)
	var bx := -width * 0.5 + bl * 0.5
	body_c = bx
	body_l = bl
	_rod(R, bl, bx, COL_VERB)
	for gx in [bx - bl * 0.5 + 0.012, bx + bl * 0.5 - 0.012]: # machined grooves
		_rod(R + 0.0025, 0.005, gx, COL_GROOVE, 40, -1)
	label = _side_label(s["cons"], 56, bx, R)
	if has_knob:
		knob_x = -width * 0.5 + bl + KNOB_L * 0.5
		var kr: float = KNOB_R[vclass]
		_rod(kr, KNOB_L, knob_x, COL_KNOB[vclass])
		if HOLE_R.has(vclass):
			_hole(HOLE_R[vclass], knob_x + KNOB_L * 0.5)
		var small := vclass == "(i)"
		_side_label("(i)" if small else s["vowel"], 18 if small else 40, knob_x, kr)


func _build_verb_ending() -> void:
	is_rod = true
	var e: Dictionary = Latin.VERB_ENDINGS[key]
	var vcol := COL_VEND if e.get("voice", "act") == "act" else COL_PASS
	if key in Latin.CAPS: # hex cap nut with a socket in its back
		width = CAP_L if key == "ō" else maxf(CAP_L, text_w(key, 56) + 0.03 * S)
		_rod(CAP_R, width, 0.0, vcol)
		_rod(CAP_R * 0.75, 0.012, width * 0.5 + 0.004, vcol, 40) # domed end
		_hole(SOCKET_R, -width * 0.5)
		label = _side_label(key, 60 if key == "ō" else 50, 0.0, CAP_R)
		return
	plug = e["ins"]
	var bl := maxf(0.08 * S, text_w(e["body"], 56) + 0.045 * S)
	width = KNOB_L + bl
	var px := -width * 0.5 + KNOB_L * 0.5
	var bx := -width * 0.5 + KNOB_L + bl * 0.5
	insert_parts = [_rod(PLUG_R[plug], KNOB_L + 0.004, px + 0.002, COL_PLUG), _side_label(plug, 30, px, PLUG_R[plug])]
	_rod(R, bl, bx, vcol)
	_rod(R + 0.006, 0.02, bx - bl * 0.5 + 0.009, COL_NUT, 6) # hex collar (end face just proud of the copper)
	label = _side_label(e["body"], 56, bx + 0.006 * S, R)


## Tucked into a knob (or standing in for the thin (i) knob) the insert is hidden.
func set_insert_hidden(hidden: bool) -> void:
	for n in insert_parts:
		n.visible = not hidden


## Noun pieces show a dash when loose ("puell-", "-am") and hide it when glued.
var agree_cap: MeshInstance3D = null


## A bare-stem noun (puer, vir) carries its own case only while it has no ending:
## once one goes on, its agreement socket is shut (the ending has its own).
func agree_closed() -> bool:
	return agree_cap != null and joined


func set_joined(p_joined: bool) -> void:
	joined = p_joined
	if agree_cap:
		agree_cap.visible = joined
	if not is_block:
		return
	if kind == "stem" and not Latin.takes_ending(key): # a whole word: no dash ever
		label.text = Latin.nom_form(key)
	elif kind == "stem":
		var bare: bool = Latin.STEMS[key].get("bare_nom", false)
		label.text = key if joined else (Latin.nom_form(key) if bare else key + "-")
		if sub_label:
			sub_label.visible = not joined
	elif is_reel() and not collapsed():
		label.text = reel_base if joined else "-" + reel_base
	else:
		label.text = key if joined else "-" + key


func _process(delta: float) -> void:
	var moved := false
	if gen_node and not is_equal_approx(gen_amt, gen_goal):
		gen_amt = move_toward(gen_amt, gen_goal, delta * 3.0)
		moved = true
	if port_node and not is_equal_approx(port_amt, port_goal):
		port_amt = move_toward(port_amt, port_goal, delta * 3.0)
		moved = true
	if moved:
		_apply_parts()
	if is_reel() and not is_equal_approx(reel_pos, reel_goal):
		reel_pos = lerpf(reel_pos, reel_goal, minf(1.0, delta * 12.0))
		if absf(reel_pos - reel_goal) < 0.002:
			reel_pos = reel_goal
		_layout_reel()


func _apply_parts() -> void:
	if gen_node:
		gen_node.position.z = (1.0 - smoothstep(0.0, 1.0, gen_amt)) * GEN_IN
		gen_node.visible = gen_amt > 0.01
	if port_node:
		var a := maxf(0.001, smoothstep(0.0, 1.0, port_amt))
		port_node.scale = Vector3(1, a, a)


## Is the holder all the way out (usable)?
func gen_open() -> bool:
	return gen_node != null and gen_goal > 0.5 and gen_amt > 0.95


func port_open() -> bool:
	return port_node != null and port_goal > 0.5 and port_amt > 0.95


## The prism's size: [corner radius, centre height, housing height, face width]. Its
## faces are wide enough to read; the housing's bottom is level with the board's.
func _reel_dims() -> Array:
	var n := maxi(3, reel_opts.size())
	var r := maxf(H * 0.5 - 0.0012, REEL_FACE / (2.0 * sin(PI / n)))
	var hh := 2.0 * (r + 0.0012)
	return [r, -H * 0.5 + hh * 0.5, hh, 2.0 * r * sin(PI / n)]


var reel_yc := 0.0 # the prism's centre height
var reel_top := 0.0 # the top of its housing (where the window is)


## On a reel, a face's cable exits and its port sit at the right of the face, after
## its letters (prism-local x).
func _cable_x(j: int, count: int) -> float:
	return reel_w * 0.5 - REEL_PORTS + 0.012 + j * 0.014 - (0.0 if count == 1 else 0.0)


func _port_x() -> float:
	return reel_w * 0.5 - 0.016


## Where an ending's square / triangular hole is. On a reel: in the face that's up,
## through the window (its hole points up, and it turns with the prism).
func _new_port() -> Node3D:
	var pn := Node3D.new()
	if reel_node:
		pn.position = Vector3(_port_x(), reel_a + 0.0008, 0)
		pn.basis = Basis(Vector3.UP, Vector3.LEFT, Vector3.BACK) # (its x: out of the face)
		reel_facets[choice].add_child(pn)
	else:
		pn.position = Vector3(width * 0.5 + 0.001, 0, 0)
		add_child(pn)
	return pn


func _port_local() -> Vector3:
	return Vector3(reel_cx + _port_x(), reel_yc + reel_a, 0) if reel_node else Vector3(width * 0.5, 0, 0)


func _port_basis() -> Basis:
	return Basis(Vector3.UP, Vector3.LEFT, Vector3.BACK) if reel_node else Basis.IDENTITY


## The prism: an N-sided prism along x (N = the options, at least three), each
## option printed on its own face (a long ablative as a macron), turned so the
## chosen face is on top. Locked options show a cross.
func _build_prism(cx: float, plen: float) -> void:
	var n := maxi(3, reel_opts.size())
	reel_n = n
	reel_w = plen
	var dims := _reel_dims()
	var a: float = dims[0] * cos(PI / n) # (it turns inside its housing: its corners just clear the walls)
	reel_a = a
	reel_yc = dims[1]
	reel_top = dims[1] + dims[2] * 0.5
	reel_node = Node3D.new()
	reel_node.position = Vector3(cx, reel_yc, 0)
	add_child(reel_node)
	reel_facets = []
	var pm := Art.mesh(reel_node, _prism_mesh(n, a, plen), Vector3.ZERO, COL_REEL, 0, 0.6)
	mats.append(pm.material_override)
	for k in n:
		var facet := Node3D.new() # (its +y is this face's outward normal)
		facet.rotation.x = TAU * k / n
		reel_node.add_child(facet)
		reel_facets.append(facet)
		var o: String = reel_opts[k] if k < reel_opts.size() else "~"
		var tx := -plen * 0.5 + 0.008 + (plen - REEL_PORTS - 0.008) * 0.5 # (the letters: the left part of the face)
		var lab := Art.label3d("", FACE_FONT, PIXEL)
		lab.modulate = INK_REEL
		lab.outline_size = 0
		lab.rotation_degrees = Vector3(-90, 0, 0)
		lab.position = Vector3(tx, a + 0.0012, 0.0015)
		facet.add_child(lab)
		reel_labels.append(lab)
		if k < reel_opts.size() and long_opt(o): # a long ablative: a macron on its face
			var bar := Art.box(facet, Vector3((plen - REEL_PORTS) * 0.6, 0.002, 0.004), Vector3(tx, a + 0.001, 0), INK_REEL, -1)
			bar.set_meta("macron", k)
		if k < reel_opts.size() and Latin.has_case(cat, Latin.reel_form(reel_base, o), "nom"): # the hole its subject cable comes out of
			var hn := 2 if (cat == "decl5" and Latin.reel_form(reel_base, o) == "es") else 1
			for j in hn:
				Art.box(facet, Vector3(0.011, 0.001, 0.011), Vector3(_cable_x(j, hn), a + 0.0006, 0), COL_HOLE, -1)
		for side in [-1.0, 1.0]: # thin rails along the face's edges
			var ang := PI / n
			var e := Vector3(0, a, side * a * tan(ang))
			Art.box(facet, Vector3(plen, 0.0015, 0.0015), e, COL_REEL.darkened(0.25), -1)


static func _prism_mesh(n: int, a: float, plen: float) -> ArrayMesh:
	var r := a / cos(PI / n)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hx := plen * 0.5
	var corner := func(i: int, x: float) -> Vector3: # (corners between the faces)
		var t := TAU * (i + 0.5) / n
		return Vector3(x, cos(t) * r, sin(t) * r)
	for i in n: # the sides
		var nrm := Vector3(0, cos(TAU * i / n), sin(TAU * i / n))
		var c0: Vector3 = corner.call(i - 1, -hx)
		var c1: Vector3 = corner.call(i, -hx)
		var c2: Vector3 = corner.call(i, hx)
		var c3: Vector3 = corner.call(i - 1, hx)
		for v in [c0, c2, c1, c0, c3, c2]:
			st.set_normal(nrm)
			st.add_vertex(v)
	for e in [-1.0, 1.0]: # the two ends
		for i in n:
			var p0 := Vector3(e * hx, 0, 0)
			var p1: Vector3 = corner.call(i - 1, e * hx)
			var p2: Vector3 = corner.call(i, e * hx)
			var tri := [p0, p1, p2] if e > 0.0 else [p0, p2, p1]
			for v in tri:
				st.set_normal(Vector3(e, 0, 0))
				st.add_vertex(v)
	return st.commit()


const INK_REEL := Color("#2a2230")


## Turn the prism to the reel's current position, and write each face (a cross
## on the ones not unlocked yet); light the macron if a long ablative's on top.
func _layout_reel() -> void:
	if reel_node == null:
		return
	reel_node.rotation.x = -reel_pos * TAU / reel_n
	for k in reel_labels.size():
		var lab: Label3D = reel_labels[k]
		if k >= reel_opts.size():
			lab.text = ""
			continue
		var o: String = reel_opts[k]
		var ok := Latin.ending_unlocked(cat, Latin.reel_form(reel_base, o))
		lab.text = ("✕" if not ok else ("" if long_opt(o) else ("·" if o == "" else o)))
		lab.modulate = INK_REEL if ok else Color("#a09888")
	for ch in reel_node.get_children(): # (the macron bars on faces that aren't unlocked are hidden)
		for b in ch.get_children():
			if b.has_meta("macron"):
				var kk: int = b.get_meta("macron")
				b.visible = Latin.ending_unlocked(cat, Latin.reel_form(reel_base, reel_opts[kk]))
	var top := posmod(roundi(reel_pos), reel_opts.size()) if not reel_opts.is_empty() else 0
	var lit := long_opt(reel_opts[top]) and absf(reel_pos - roundf(reel_pos)) < 0.2
	if reel_lamp_on and label:
		reel_lamp_on.visible = lit
		reel_lamp_off.visible = not lit
		# over the fixed letter, at the right end of the printed "-a" / "a"
		var lp := label.position + Vector3(text_w(label.text, FONT_SIZE) * 0.5 - text_w(reel_base, FONT_SIZE) * 0.5, 0, -FONT_SIZE * PIXEL * 0.36)
		lp.y = H * 0.5 + 0.0022
		reel_lamp_on.get_parent().position = lp


## Broken by a mistake: scorched, cracked, its writing gone grey. It won't go on
## anything, and nothing plugs into it.
func set_broken() -> void:
	if broken:
		return
	broken = true
	var h := box_half()
	var o := shape_offset()
	var top := o.y + h.y + 0.0015
	var soot := Color("#1d1b1f")
	var rng := RandomNumberGenerator.new()
	rng.seed = get_instance_id()
	for k in 3: # cracks across the top, zigzagging
		var x0 := rng.randf_range(-h.x * 0.7, h.x * 0.7)
		var z := -h.z * 0.8
		for seg in 4:
			var dz := h.z * 0.42
			var dx := rng.randf_range(-0.012, 0.012)
			var crack := Art.box(self, Vector3(0.0025, 0.0012, dz * 1.15), o + Vector3(x0 + dx * 0.5, top - o.y, z + dz * 0.5), soot, -1)
			crack.rotation.y = atan2(dx, dz)
			x0 += dx
			z += dz
	for k in 5: # scorch marks
		var r := rng.randf_range(0.006, 0.014)
		Art.box(self, Vector3(r * 2.0, 0.0011, r * 1.6), o + Vector3(rng.randf_range(-h.x, h.x) * 0.8, top - o.y + 0.0002, rng.randf_range(-h.z, h.z) * 0.7), Color("#3a3036"), -1)
	if label:
		label.modulate = Color(0.45, 0.45, 0.47)
	if sub_label:
		sub_label.modulate = Color(0.45, 0.45, 0.47)


func set_highlight(on: bool) -> void:
	for m in mats:
		m.set_shader_parameter("highlight", 1.0 if on else 0.0)


## Prepositions and adverbs: a little remote control: a joystick, a couple of
## buttons, and the word printed between them (navy for prepositions, purple for adverbs).
func _build_remote() -> void:
	is_block = true
	var word := Latin.nom_form(key)
	width = maxf(0.16 * S, text_w(word, FONT_SIZE) + 0.12 * S)
	var hw := width * 0.5
	var body := color_for(kind, key, cat).darkened(0.35)
	var mi := Art.box(self, Vector3(width, H * 0.8, D), Vector3(0, -H * 0.1, 0), body, 0, 0.7)
	mats.append(mi.material_override)
	Art.box(self, Vector3(width - 0.012, 0.004, D - 0.012), Vector3(0, H * 0.3 + 0.001, 0), color_for(kind, key, cat), -1) # face plate
	var top := H * 0.3 + 0.003
	# the joystick: a base, a stick, a red ball
	var jx := -hw + 0.03 * S
	var base := CylinderMesh.new()
	base.top_radius = 0.016 * S
	base.bottom_radius = 0.02 * S
	base.height = 0.008
	Art.mesh(self, base, Vector3(jx, top + 0.004, 0), Color("#1b1b22"), 1, 0.5)
	var stick := CylinderMesh.new()
	stick.top_radius = 0.004
	stick.bottom_radius = 0.004
	stick.height = 0.03
	Art.mesh(self, stick, Vector3(jx, top + 0.02, 0), Color("#9aa4ad"), -1)
	var ball := SphereMesh.new()
	ball.radius = 0.011 * S + 0.004
	ball.height = ball.radius * 2.0
	Art.mesh(self, ball, Vector3(jx, top + 0.038, 0), Color("#e0283a"), 1, 0.6)
	# two buttons
	for b in [[Vector3(hw - 0.025 * S, top + 0.003, -0.018 * S), Color("#ffd23f")], [Vector3(hw - 0.025 * S, top + 0.003, 0.018 * S), Color("#46b450")]]:
		var bm := CylinderMesh.new()
		bm.top_radius = 0.008 * S + 0.002
		bm.bottom_radius = 0.008 * S + 0.002
		bm.height = 0.006
		Art.mesh(self, bm, b[0], b[1], 1, 0.5)
	label = Art.label3d(word, FONT_SIZE, PIXEL)
	label.modulate = COL_SILK
	label.outline_size = 0
	label.rotation_degrees = Vector3(-90, 0, 0)
	label.position = Vector3(0, top + 0.001, 0.004)
	add_child(label)


## An adapter: just a length of cable with a coupler in it: a slim sleeve in the
## adapter's colour, its name on a little flag, and a housing at each end where a
## cable comes out (or a plug goes in).
func _build_adapter() -> void:
	if key == "adj":
		_build_cap()
		return
	width = PUCK_R * 2.0
	var info: Dictionary = ADAPTERS[key]
	var y := -H * 0.5 + PUCK_H * 0.5
	var sleeve := CylinderMesh.new()
	sleeve.top_radius = 0.0075
	sleeve.bottom_radius = 0.0075
	sleeve.height = PUCK_R * 2.0 - 0.03
	sleeve.radial_segments = 10
	var mi := Art.mesh(self, sleeve, Vector3(0, y, 0), info["col"], 0, 0.5)
	mi.rotation_degrees.z = 90
	mats.append(mi.material_override)
	for sx in [-1.0, 1.0]: # the two end housings
		var hb := Art.box(self, Vector3(0.016, PUCK_H, PUCK_D), Vector3(sx * (PUCK_R - 0.008), y, 0), Color("#3a3d44"), 0, 0.5)
		mats.append(hb.material_override)
	# its name on a flag wrapped round the middle of the cable
	var tag := Art.box(self, Vector3(0.05, 0.003, 0.02), Vector3(0, y + 0.0085, 0), info["col"], 0, 0.5)
	mats.append(tag.material_override)
	label = Art.label3d(info["label"], 18, PIXEL)
	label.rotation_degrees = Vector3(-90, 0, 0)
	label.position = Vector3(0, y + 0.0105, 0)
	label.modulate = COL_SILK
	add_child(label)


## The adjective cap: a plain hollow brass cap, open on its left, that slips over
## the end of an ending (-us, -a, -um...) on an adjective's stem and makes it an
## adjective: its two cables come out of the back. No writing on it.
func _build_cap() -> void:
	width = CAP_W
	var col: Color = ADAPTERS["adj"]["col"]
	var hh := H * 0.5 + 0.004
	var hd := D * 0.5 + 0.004
	var t := 0.003
	for part in [[Vector3(CAP_W, t, hd * 2.0), Vector3(0, hh - t * 0.5, 0)], [Vector3(CAP_W, t, hd * 2.0), Vector3(0, -hh + t * 0.5, 0)],
			[Vector3(CAP_W, hh * 2.0, t), Vector3(0, 0, hd - t * 0.5)], [Vector3(CAP_W, hh * 2.0, t), Vector3(0, 0, -hd + t * 0.5)],
			[Vector3(t, hh * 2.0, hd * 2.0), Vector3(CAP_W * 0.5 - t * 0.5, 0, 0)]]:
		var m := Art.box(self, part[0], part[1], col, 0, 0.6)
		mats.append(m.material_override)
	var rim := Art.box(self, Vector3(0.004, hh * 2.0 + 0.002, hd * 2.0 + 0.002), Vector3(-CAP_W * 0.5 + 0.002, 0, 0), col.darkened(0.3), 0, 0.5)
	mats.append(rim.material_override)
	label = Label3D.new() # (nothing written on it)
	label.visible = false
	add_child(label)


func _adapter_links() -> void:
	var y := -H * 0.5 + PUCK_H * 0.5
	var left := Vector3(-PUCK_R, y, 0)
	var right := Vector3(PUCK_R, y, 0)
	match key:
		"adj": # a gender cable (into the top of the noun's stem) and an agreement cable (into the top of its ending)
			var back := Vector3(0, 0, -(D * 0.5 + 0.004))
			cord_specs = [
				{"kind": "aux", "prongs": 1, "anchor": back + Vector3(-0.009, 0, 0), "dir": Vector3(0, 0, -1), "rest": Vector3(-0.05, 0, -0.14), "col": Color("#e4e6ea")},
				{"kind": "agree", "prongs": 1, "anchor": back + Vector3(0.009, 0, 0), "dir": Vector3(0, 0, -1), "rest": Vector3(0.06, 0, -0.14)}]
		"modi":
			cord_specs = [
				{"kind": "abl", "prongs": 1, "anchor": left, "dir": Vector3.LEFT, "rest": Vector3(-0.1, 0, 0.03)},
				{"kind": "star", "prongs": 1, "anchor": right, "dir": Vector3.RIGHT, "rest": Vector3(0.1, 0, 0.03)}]
		"neut_sg":
			cord_specs = [
				{"kind": "acc", "prongs": 1, "anchor": left, "dir": Vector3.LEFT, "rest": Vector3(-0.1, 0, 0.03)},
				{"kind": "nom", "prongs": 1, "anchor": right, "dir": Vector3.RIGHT, "rest": Vector3(0.1, 0, 0.03)}]
		"neut_pl":
			socket_kind = "nom" # a plural (two-slot) subject hole on the left...
			socket_prongs = 2
			socket_local = left
			socket_basis = Basis(Vector3(-1, 0, 0), Vector3.UP, Vector3(0, 0, -1))
			for z in Cord.prong_z(2):
				Art.box(self, Vector3(0.004, 0.0, 0.0) + Cord.prong_section(2) + Vector3(0, 0.005, 0.005), left + Vector3(-0.001, 0, z), COL_HOLE, -1)
			# ...and a square hole on the right for the verb's object cable
			extra_sockets.append({"kind": "acc", "local": right, "basis": Basis.IDENTITY, "prongs": 1})
			Art.box(self, Vector3(0.004, Cord.ACC_PRONG + 0.004, Cord.ACC_PRONG + 0.004), right + Vector3(0.001, 0, 0), COL_HOLE, -1)
	if not cord_specs.is_empty():
		cord_kind = cord_specs[0]["kind"]
		cord_anchor = cord_specs[0]["anchor"]
		cord_dir = cord_specs[0]["dir"]


## Every form this ending piece can show (all of a reel's options).
func forms() -> Array:
	if is_reel():
		return reel_opts.map(func(o): return Latin.reel_form(reel_base, o))
	return [key]


## Covered over (with a red cross) while none of its forms is unlocked yet.
func set_locked(on: bool) -> void:
	if on == (lock_cap != null):
		return
	if not on:
		lock_cap.queue_free()
		lock_cap = null
		return
	lock_cap = Node3D.new()
	add_child(lock_cap)
	var h := box_half()
	var top := shape_offset().y + h.y + 0.003
	Art.box(lock_cap, Vector3(width * 0.92, 0.004, h.z * 1.6), Vector3(0, top, 0), Color("#2a2a33"), 0, 0.5)
	var x := Art.label3d("✕", 60, PIXEL)
	x.modulate = Color("#e0283a")
	x.rotation_degrees = Vector3(-90, 0, 0)
	x.position = Vector3(0, top + 0.003, 0)
	lock_cap.add_child(x)


## Soldered on: a silver bead of solder over the joint, so the ending can't come off.
func solder() -> void:
	soldered = true
	if kind != "ending":
		return
	var x := -width * 0.5
	if is_rod:
		Art.box(self, Vector3(0.008, R * 2.0 + 0.004, R * 2.0 + 0.004), Vector3(x + 0.002, AXIS_Y, 0), Color("#c9d1d9"), 0, 0.6)
	else:
		Art.box(self, Vector3(0.008, H + 0.004, D + 0.004), Vector3(x + 0.002, 0, 0), Color("#c9d1d9"), 0, 0.6)


## All the little plain decoration (traces, pads, pins, holes...) merged into one
## mesh per colour: far fewer things for the renderer to draw.
func bake_decor() -> void:
	var groups := {}
	for c in get_children():
		if c is MeshInstance3D and c.material_override and c.material_override.next_pass == null \
				and not c.material_override in mats and not c in insert_parts:
			var k = c.material_override
			if not groups.has(k):
				groups[k] = []
			groups[k].append(c)
	for mat in groups:
		var list: Array = groups[mat]
		if list.size() < 2:
			continue
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for mi: MeshInstance3D in list:
			st.append_from(mi.mesh, 0, mi.transform)
			remove_child(mi)
			mi.queue_free()
		var merged := MeshInstance3D.new()
		merged.mesh = st.commit()
		merged.material_override = mat
		merged.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(merged)


## Light up the genitive holder (a word you're holding would go in if you let go).
func set_gen_highlight(on: bool) -> void:
	for m in gen_mats:
		m.set_shader_parameter("highlight", 1.0 if on else 0.0)
		m.set_shader_parameter("albedo", Color("#ffd23f") if on else COL_GEN)


func set_pickable(on: bool) -> void:
	body.collision_layer = 1 | 4 if on else 0 # clickable, and solid to loose pieces
