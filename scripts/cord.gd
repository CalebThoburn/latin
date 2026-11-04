class_name Cord
extends Node3D
## A cable with a plug, hanging off a piece.
##   nom plug - long, flat plug on the cable of a nominative ending: ONE flat,
##              sideways blade for a singular subject, TWO upright blades for a
##              plural; slides into the slotted hole in the right end of a verb
##              ending (one slot singular, two plural)
##   acc plug - big chunky square plug on the cable of a verb stem that takes a
##              direct object; slides into the square hole in the right end of
##              an accusative ending
## Plug frame: prongs run from x = -plen() to 0, the boot from 0 to boot().x, the
## cable leaves from the back (+x). Plugged in, the plug frame == the socket frame.

const PRONG_L := 0.035 # plural blades and the square acc prong
const PRONG_L_SG := 0.03 # the singular blade: a wide flat square (nothing like the computer's round plug)
const PRONG_H := 0.012
const PRONG_T := 0.004
const ACC_PRONG := 0.03 # side of the square acc prong
const DISP_R := 0.012 # the computer's display plug: a hollow ring (a short tube)...
const DISP_R_IN := 0.0075 # ...this wide inside
const CABLE_R := 0.007
const SEGS := 34
const SIDES := 6
const STAR_R := 0.011 # star plug (adverbs / prepositions into a verb): arm reach...
const STAR_T := 0.005 # ...and arm thickness
const TRI_R := 0.014 # triangular plug (preposition + ablative)
const AUX_R := 0.0045 # an adjective's gender jack (a thin round pin)
const AGREE_P := 0.009 # an adjective's agreement plug (a small square pin)
const DAT_R := 0.0065 # a dative verb's plug (a fat round pin, into the top of a dative ending)
const COL := {"nom": Color("#3d7be0"), "acc": Color("#e0455f"), "disp": Color("#f2c230"),
		"star": Color("#46b450"), "abl": Color("#e8862a"), "aux": Color("#3fae5a"), "agree": Color("#ffd23f"), "dat": Color("#9b59d0")}


var owner_tile: Tile
var kind := ""
var prongs := 1
var interactive := true
var socket_tile: Tile = null
var socket_i := 0 # which of socket_tile's holes it's in
var anchor_local := Vector3.ZERO # where on its piece the cable leaves, and which way
var dir_local := Vector3(0, 0, -1)
var held := false
var parked := true # never put down by the player: rides along beside its piece
var free_xf := Transform3D() # where the plug is while not plugged in (world)
var floor_y := -INF
var rest_offset := Vector3(0.06, 0, -0.14)
var plug: Node3D
var tube: MeshInstance3D
var body: StaticBody3D
var _was_hidden := true
var _last_a := Vector3.INF
var _last_b := Vector3.INF
var _last_sig := INF
var path: Array[Vector3] = [] # the cable's centre line, as last built
var obstacles := Callable()
var resolve := Callable() # (basis, origin, samples) -> origin pushed clear of every piece
# the cable can be drawn back inside its piece (another use of the ending is in
# play, or the ending changed): 1 = out, 0 = all the way in
var emerge := 1.0
var emerge_goal := 1.0
var dying := false
var col := Color.WHITE # (an adjective's gender cable is the colour of its gender)
var gender := ""


## Draw the cable back into its piece for good, then go.
func retract_and_free() -> void:
	dying = true
	emerge_goal = 0.0
	if socket_tile:
		free_xf = plug.global_transform.orthonormalized()
	socket_tile = null
	socket_i = 0
	held = false # () -> [[frame, half extents], ...] of every piece on the table


static func prong_z(n: int) -> Array:
	return [-0.009, 0.009] if n == 2 else [0.0]


## Cross-section (y, z) of one blade: plural blades stand upright, the singular
## blade lies flat and is wide: a flat square.
static func prong_section(n: int) -> Vector3:
	return Vector3(0, PRONG_H, PRONG_T) if n == 2 else Vector3(0, 0.005, 0.03)


## How far the prongs stick out (= how deep they go in).
func plen() -> float:
	return PRONG_L_SG if kind == "nom" and prongs == 1 else PRONG_L


## Size of the plug's body (length, height, width): nom = long and flat,
## acc = a big square block.
func boot() -> Vector3:
	match kind:
		"nom": return Vector3(0.1, 0.014, 0.042)
		"disp": return Vector3(0.06, 0.03, 0.03)
		"star": return Vector3(0.05, 0.028, 0.028)
		"aux": return Vector3(0.05, 0.02, 0.02)
		"agree": return Vector3(0.05, 0.022, 0.026)
		"dat": return Vector3(0.05, 0.026, 0.026)
		"abl": return Vector3(0.05, 0.04, 0.04)
	return Vector3(0.05, 0.052, 0.052)


## Points (plug frame) + radii that keep the plug from passing through pieces.
func samples() -> Array:
	var L := plen()
	var bt := boot()
	var pr: float = {"nom": 0.006, "acc": ACC_PRONG * 0.5, "disp": DISP_R, "star": STAR_R, "abl": TRI_R, "aux": AUX_R, "agree": AGREE_P * 0.5, "dat": DAT_R}[kind]
	var out := [[Vector3(-L + pr, 0, 0), pr], [Vector3(-L * 0.5, 0, 0), pr]]
	var br := minf(bt.y, bt.z) * 0.5
	var n := maxi(2, ceili(bt.x / br))
	for i in n: # spheres along the body
		out.append([Vector3(br + (bt.x - 2.0 * br) * i / (n - 1), 0, 0), br])
	return out


## A triangular prism along x (point up), centred on the origin: the ablative's
## plug and the hole it goes into.
static func tri_prism(r: float, length: float) -> ArrayMesh:
	var c := []
	for k in 3:
		var a := PI * 0.5 + TAU * k / 3.0
		c.append(Vector2(cos(a), sin(a)) * r) # (z, y) of each corner
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hx := length * 0.5
	var corner := func(i: int, x: float) -> Vector3: return Vector3(x, c[i].y, c[i].x)
	for face in [[0, 1, 2, hx], [0, 2, 1, -hx]]: # the two triangle ends
		var nrm := Vector3(signf(face[3]), 0, 0)
		for i in 3:
			st.set_normal(nrm)
			st.add_vertex(corner.call(face[i], face[3]))
	for i in 3: # the three sides
		var j := (i + 1) % 3
		var a: Vector3 = corner.call(i, -hx)
		var b: Vector3 = corner.call(j, -hx)
		var nrm := (a + b).normalized()
		nrm.x = 0.0
		for v in [a, b, corner.call(j, hx), a, corner.call(j, hx), corner.call(i, hx)]:
			st.set_normal(nrm.normalized())
			st.add_vertex(v)
	return st.commit()


## The socket's frame: origin at the hole's mouth, +x pointing out of the hole.
static func socket_xf(t: Tile, i := 0) -> Transform3D:
	var d := t.sock(i)
	return Transform3D(t.global_basis.orthonormalized() * d["basis"], t.global_transform * d["local"])


## Does this plug fit hole i of t? (the shape has to match; subjects: singular
## blade into a one-slot verb ending, two blades into a two-slot one)
func fits(t: Tile, i := 0) -> bool:
	var d := t.sock(i)
	return d["kind"] == kind and (kind != "nom" or prongs == d["prongs"])


func anchor() -> Vector3:
	return owner_tile.global_transform * anchor_local


func setup(t: Tile, p_interactive: bool, p_floor_y: float, spec := {}) -> Cord:
	owner_tile = t
	kind = spec.get("kind", t.cord_kind)
	prongs = spec.get("prongs", t.cord_prongs)
	anchor_local = spec.get("anchor", t.cord_anchor)
	dir_local = spec.get("dir", t.cord_dir)
	interactive = p_interactive
	floor_y = p_floor_y
	col = spec.get("col", COL[kind])
	gender = spec.get("gender", "")
	if not interactive:
		rest_offset = Vector3(0.04, 0, -0.06)
	elif spec.has("rest"):
		rest_offset = spec["rest"]
	elif dir_local.z > 0.5: # leaves from the front of its piece: rests in front of it,
		rest_offset = Vector3(-0.02, 0, 0.17) # straight out in front, low and clear of the reel window
	tube = MeshInstance3D.new()
	tube.material_override = Art.toon(col, 1, 0.5, true)
	add_child(tube)
	plug = Node3D.new()
	add_child(plug)
	var metal := Color("#d4dae0")
	var bt := boot()
	if kind == "nom":
		var L := plen()
		for z in prong_z(prongs): # thin flat blades
			Art.box(plug, Vector3(L + 0.004, 0, 0) + prong_section(prongs), Vector3(-L * 0.5 + 0.002, 0, z), Color("#ffd23f") if prongs == 0 else metal, 0, 0.4)
	elif kind == "acc":
		Art.box(plug, Vector3(PRONG_L + 0.004, ACC_PRONG, ACC_PRONG), Vector3(-PRONG_L * 0.5 + 0.002, 0, 0), metal, 0, 0.4)
	elif kind == "star": # a six-pointed star prong
		for k in 3:
			var arm := Art.box(plug, Vector3(PRONG_L + 0.004, STAR_R * 2.0, STAR_T), Vector3(-PRONG_L * 0.5 + 0.002, 0, 0), metal, 0, 0.4)
			arm.rotation.x = PI / 3.0 * k
	elif kind == "aux": # a thin round jack pin
		var pin := CylinderMesh.new()
		pin.top_radius = AUX_R
		pin.bottom_radius = AUX_R
		pin.height = PRONG_L + 0.004
		var pm := Art.mesh(plug, pin, Vector3(-PRONG_L * 0.5 + 0.002, 0, 0), metal, -1)
		pm.rotation_degrees.z = 90
	elif kind == "dat": # a fat round pin with a purple tip
		var dpin := CylinderMesh.new()
		dpin.top_radius = DAT_R
		dpin.bottom_radius = DAT_R
		dpin.height = PRONG_L + 0.004
		var dm := Art.mesh(plug, dpin, Vector3(-PRONG_L * 0.5 + 0.002, 0, 0), metal, -1)
		dm.rotation_degrees.z = 90
	elif kind == "agree": # a small square pin
		Art.box(plug, Vector3(PRONG_L + 0.004, AGREE_P, AGREE_P), Vector3(-PRONG_L * 0.5 + 0.002, 0, 0), Color("#e2b04a"), 0, 0.4)
	elif kind == "abl": # a triangular prong, point up
		Art.mesh(plug, tri_prism(TRI_R, PRONG_L + 0.004), Vector3(-PRONG_L * 0.5 + 0.002, 0, 0), metal, -1, 0.4, true)
	if kind == "disp": # a hollow ring plug: a short metal tube (dark inside) on a round barrel
		var pin := CylinderMesh.new()
		pin.top_radius = DISP_R
		pin.bottom_radius = DISP_R
		pin.height = PRONG_L + 0.004
		var pm := Art.mesh(plug, pin, Vector3(-PRONG_L * 0.5 + 0.002, 0, 0), metal, 2, 0.4)
		pm.rotation_degrees.z = 90
		var hollow := CylinderMesh.new() # (looking into its end: a dark hole inside the ring)
		hollow.top_radius = DISP_R_IN
		hollow.bottom_radius = DISP_R_IN
		hollow.height = 0.012
		var hm := Art.mesh(plug, hollow, Vector3(-PRONG_L + 0.0055, 0, 0), Color("#0d0b10"), -1)
		hm.rotation_degrees.z = 90
		var bar := CylinderMesh.new()
		bar.top_radius = bt.y * 0.5
		bar.bottom_radius = bt.y * 0.5
		bar.height = bt.x
		var bm := Art.mesh(plug, bar, Vector3(bt.x * 0.5, 0, 0), COL[kind], 2, 0.5)
		bm.rotation_degrees.z = 90
	else:
		Art.box(plug, bt, Vector3(bt.x * 0.5, 0, 0), col, 0, 0.5)
	if kind == "nom": # grip ridges on the flat plug
		for k in 3:
			Art.box(plug, Vector3(0.006, 0.004, bt.z - 0.01), Vector3(bt.x * 0.45 + k * 0.016, bt.y * 0.5 + 0.001, 0), COL[kind].darkened(0.3), -1)
	if interactive:
		body = StaticBody3D.new()
		body.collision_mask = 0
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		# grab it by its body only, so a plugged-in plug doesn't cover the piece it's in
		sh.size = Vector3(bt.x + 0.02, maxf(bt.y, 0.04) + 0.02, maxf(bt.z, 0.04) + 0.02)
		cs.shape = sh
		cs.position = Vector3(bt.x * 0.5 + 0.005, 0, 0)
		body.add_child(cs)
		body.set_meta("plug", self)
		plug.add_child(body)
	return self


func rest_transform() -> Transform3D:
	var o := owner_tile.global_transform
	var b := o.basis.orthonormalized()
	if owner_tile.in_tray: # lying loose in the tray / a drawer: plug lies beside it
		var x := b.x
		x.y = 0.0
		x = x.normalized() if x.length() > 0.01 else Vector3.RIGHT
		var lb := Basis(x, Vector3.UP, x.cross(Vector3.UP))
		var p := o.origin + lb * Vector3(0.03, 0, -0.13)
		p.y = _ground() + boot().y * 0.5
		return Transform3D(lb, p)
	var p := o * (anchor_local + rest_offset)
	if floor_y > -INF:
		p.y = floor_y + boot().y * 0.5
	return Transform3D(b, p)


## What the cable lies on: the bench, or the floor of the tray / drawer its piece is in.
func _ground() -> float:
	if owner_tile.in_tray:
		return owner_tile.global_position.y - Tile.H * 0.5 - 0.002
	return floor_y


func _process(delta: float) -> void:
	if not is_instance_valid(owner_tile) or owner_tile.is_queued_for_deletion():
		queue_free()
		return
	var shown := owner_tile.is_inside_tree() and owner_tile.is_visible_in_tree()
	visible = shown
	if body: # plugs have their own layer; a loose piece's plug can't be grabbed
		body.collision_layer = 8 if shown and not owner_tile.in_tray else 0
	if not shown:
		socket_tile = null
		_was_hidden = true
		return
	if owner_tile.in_tray or owner_tile.cord_covered: # loose / covered: unplugged, at rest
		socket_tile = null
		parked = true
		if owner_tile.cord_covered: # an ending sits over its exit: the cable is tucked away
			visible = false
			if body:
				body.collision_layer = 0
			return
	if _was_hidden: # just came out of the tray: the plug lies beside its piece
		_was_hidden = false
		parked = true
	if socket_tile and (not is_instance_valid(socket_tile) or socket_tile.is_queued_for_deletion()
			or socket_tile.in_tray or not socket_tile.is_inside_tree()):
		socket_tile = null # its socket is gone: the plug drops where it was
		free_xf = plug.global_transform.orthonormalized()
		parked = false
	if parked and not held and not socket_tile:
		free_xf = rest_transform()
		if resolve.is_valid() and not owner_tile.in_tray: # resting plugs don't sit inside other pieces
			free_xf.origin = resolve.call(free_xf.basis, free_xf.origin, samples())
	var xf: Transform3D
	if socket_tile and not held:
		xf = socket_xf(socket_tile, socket_i)
	elif interactive:
		xf = free_xf
	else:
		xf = rest_transform()
	emerge = move_toward(emerge, emerge_goal, delta * 3.0)
	if dying and emerge <= 0.0:
		queue_free()
		return
	var e := smoothstep(0.0, 1.0, emerge)
	if e < 0.999: # sliding out of / back into its piece
		if emerge_goal < 0.5 and socket_tile and not dying:
			socket_tile = null # can't stay plugged in while it's put away
			parked = true
		xf = Transform3D(xf.basis, anchor()).interpolate_with(xf, e)
	plug.global_transform = xf
	plug.scale = Vector3.ONE * maxf(0.02, e)
	tube.visible = e > 0.03
	if body and e < 0.9:
		body.collision_layer = 0 # can't be grabbed while it's (partly) inside
	var a := anchor()
	var b: Vector3 = xf * Vector3(boot().x, 0, 0)
	var da: Vector3 = owner_tile.global_basis.orthonormalized() * dir_local
	if owner_tile.in_tray: # lying loose in a tray / drawer: a simple curve, redrawn only if it moved
		if a.distance_to(_ea) > 0.001 or b.distance_to(_eb) > 0.001 or pts.size() != NP:
			_ea = a
			_eb = b
			_init_rope(a, da, b, xf.basis.x, 0.0)
			_build_mesh()
		return
	if _simulate(a, da, b, xf.basis.x, delta):
		_build_mesh()


# ---------------------------------------------------------------- the cable as a hanging rope
## The cable is a chain of points: its two ends held by the piece and the plug
## (leaving straight out of each), the rest hanging under gravity with a little
## slack, resting on the bench / floor and draped over pieces. It goes to sleep
## when it stops moving, and wakes when an end or a piece near it moves.

const NP := 28 # points along the cable
static var world_boxes: Array = [] # every solid piece (+ the bench top), set by main each frame
static var world_ver := 0 # bumped by main whenever any of those move
var pts := PackedVector3Array()
var prv := PackedVector3Array()
var _asleep := 0
var _ver := -1
var _ea := Vector3.INF
var _eb := Vector3.INF


func _floor_at(p: Vector3) -> float:
	if owner_tile.in_tray:
		return _ground()
	if floor_y > -INF and absf(p.x) < 1.65 and absf(p.z) < 0.9: # on the bench
		return floor_y
	return 0.0 # hanging off it: down to the floor


func _simulate(a: Vector3, ta: Vector3, b: Vector3, tb: Vector3, delta: float) -> bool:
	var dist := a.distance_to(b)
	var length := clampf(dist * 1.12 + 0.05, 0.08, 4.5) # a little slack, so it sags (the computer's is long)
	var seg := length / (NP - 1)
	var ends_moved := a.distance_to(_ea) > 0.0002 or b.distance_to(_eb) > 0.0002
	if pts.size() != NP or a.distance_to(pts[0]) > 0.6 or b.distance_to(pts[NP - 1]) > 0.6:
		_init_rope(a, ta, b, tb, seg)
		ends_moved = true
	if not ends_moved and _ver == world_ver and _asleep > 20:
		return false # at rest: nothing to do
	if ends_moved or _ver != world_ver:
		_asleep = 0
	_ea = a
	_eb = b
	_ver = world_ver
	var dt := minf(delta, 1.0 / 30.0)
	var g := Vector3(0, -9.8, 0) * dt * dt
	var before := pts.duplicate()
	for i in range(2, NP - 2): # verlet: keep moving (damped) and fall
		var p := pts[i]
		var v := (p - prv[i]) * 0.8
		prv[i] = p
		pts[i] = p + v + g
	pts[0] = a
	pts[1] = a + ta * seg
	pts[NP - 1] = b
	pts[NP - 2] = b + tb * seg
	# only the pieces anywhere near this cable matter
	var lo := a.min(b) - Vector3.ONE * (length * 0.5 + 0.1)
	var hi := a.max(b) + Vector3.ONE * (length * 0.5 + 0.1)
	var near := []
	for bx in world_boxes:
		var o: Vector3 = bx[0].origin
		var r: float = bx[1].length()
		if o.x + r > lo.x and o.x - r < hi.x and o.y + r > lo.y and o.y - r < hi.y and o.z + r > lo.z and o.z - r < hi.z:
			near.append(bx)
	var cr := CABLE_R + 0.002
	for it in 12:
		for i in NP - 1: # keep the links their length
			var d := pts[i + 1] - pts[i]
			var l := d.length()
			if l < 0.000001:
				continue
			var fix_a := i <= 1
			var fix_b := i + 1 >= NP - 2
			if fix_a and fix_b:
				continue
			var corr := d * ((l - seg) / l)
			if fix_a:
				pts[i + 1] -= corr
			elif fix_b:
				pts[i] += corr
			else:
				pts[i] += corr * 0.5
				pts[i + 1] -= corr * 0.5
		for i in range(2, NP - 2): # resting on the bench / floor and over the pieces
			var p := pts[i]
			p.y = maxf(p.y, _floor_at(p) + CABLE_R)
			for bx in near:
				p = _push_box(p, bx, cr)
			pts[i] = p
	var most := 0.0 # how far anything moved this frame (after resting on things)
	for i in range(2, NP - 2):
		most = maxf(most, pts[i].distance_squared_to(before[i]))
	_asleep = _asleep + 1 if most < 0.0000001 else 0
	if _asleep > 20:
		prv = pts.duplicate() # settled: no leftover velocity
	return true


func _init_rope(a: Vector3, ta: Vector3, b: Vector3, tb: Vector3, seg: float) -> void:
	pts.resize(NP)
	var p1 := a + ta * 0.1
	var p2 := b + tb * 0.12
	for i in NP:
		var t := float(i) / (NP - 1)
		var u := 1.0 - t
		pts[i] = u * u * u * a + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * b
	prv = pts.duplicate()
	_asleep = 0


## Push a point out of a piece (over the top or round the side, whichever is
## nearer; never down through the bench).
static func _push_box(p: Vector3, bx: Array, r: float) -> Vector3:
	var bt: Transform3D = bx[0]
	var h: Vector3 = bx[1]
	var q := bt.basis.transposed() * (p - bt.origin)
	var pen := Vector3(h.x + r - absf(q.x), h.y + r - absf(q.y), h.z + r - absf(q.z))
	if pen.x <= 0.0 or pen.y <= 0.0 or pen.z <= 0.0:
		return p
	if q.y < 0.0 and h.y < 0.1:
		pen.y = INF
	var push := Vector3.ZERO
	if pen.x <= pen.y and pen.x <= pen.z:
		push.x = pen.x if q.x >= 0.0 else -pen.x
	elif pen.y <= pen.z:
		push.y = pen.y if q.y >= 0.0 else -pen.y
	else:
		push.z = pen.z if q.z >= 0.0 else -pen.z
	return p + bt.basis * push


func _build_mesh() -> void:
	path.clear()
	for p in pts:
		path.append(p)
	var rings := []
	for i in NP:
		var tan := pts[mini(i + 1, NP - 1)] - pts[maxi(i - 1, 0)]
		tan = tan.normalized() if tan.length() > 0.00001 else Vector3.RIGHT
		var n := tan.cross(Vector3.UP)
		if n.length() < 0.001:
			n = tan.cross(Vector3.RIGHT)
		n = n.normalized()
		var bn := tan.cross(n).normalized()
		var ring := []
		for j in SIDES:
			var ang := TAU * j / SIDES
			ring.append(n * cos(ang) + bn * sin(ang))
		rings.append(ring)
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	for i in NP - 1:
		for j in SIDES:
			var j2 := (j + 1) % SIDES
			for q in [[i, j], [i + 1, j], [i + 1, j2], [i, j], [i + 1, j2], [i, j2]]:
				var dir: Vector3 = rings[q[0]][q[1]]
				norms.append(dir)
				verts.append(pts[q[0]] + dir * CABLE_R)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	var m := tube.mesh as ArrayMesh
	if m == null:
		m = ArrayMesh.new()
		tube.mesh = m
	m.clear_surfaces()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
