extends Node3D
## Latin Garage: take stems from the tray, endings from the drawers,
## fit them together into words and line words up into sentences.

const TABLE_Y := 1.04
const SNAP_DIST := 0.11
const SNAP_Z := 0.11
const WALL_Z := -1.0 # front of the pegboard wall, right behind the bench
# ending cabinets hang under the bench top: noun declensions I-II on the left,
# III-V in the middle, verb endings on the right
const CABINETS := [ # x = centre, w = width; the shared -is / -ibus drawers sit beside theirs
	{"x": -1.12, "w": 0.66, "cats": ["decl1", "decl2"]},
	{"x": -0.6, "w": 0.34, "cats": ["decl12"]},
	{"x": -0.05, "w": 0.66, "cats": ["decl3", "decl4", "decl5"]},
	{"x": 0.47, "w": 0.34, "cats": ["decl34"]},
	{"x": 1.08, "w": 0.74, "cats": ["verb", "verbp"]}, # active endings, the passive drawer beneath
]
const CAB_TOP := TABLE_Y - 0.06 # underside of the bench top
const CAB_FRONT := 0.87 # just behind the bench's front lip
# delivery chute: from a hatch in the wall down into the back of the stem tray
# big rubbish bin standing on the floor next to the bench
const TRASH_POS := Vector3(2.0, 0.0, 0.45)
const TRASH_R := 0.3
const TRASH_H := 0.82
# first person: WASD to walk, mouse to look, click / E to pick up and put down
const CAM_SPEED := 2.3 # walking speed (m/s); you ease up to it and down from it
const ACCEL := 12.0
const EYE := 1.85 # eye height
const LOOK_SENS := 0.0025
const CROUCH_EYE := 1.4 # eye height crouched
const JUMP_V := 3.2 # take-off speed: about half a metre high
const GRAVITY := 9.8
const GEN_LOCK := 0.1 # a held word this close to a lit genitive holder locks into it
const HOLD_DIST := 1.0 # a picked-up piece is held this far in front of your eyes
const CHUTE_TOP := Vector3(-1.2, 1.86, -0.97)
const CHUTE_END := Vector3(-1.2, 1.3, -0.6)
const CAB_W := 0.86
const CAB_D := 0.74
const DR_PITCH := 0.14 # height of one drawer slot
const DR_IN_W := 0.76
const DR_IN_D := 0.7
const DR_OPEN := 0.8 # drawers pull all the way out from under the bench
const CAB_Z := CAB_FRONT - CAB_D * 0.5
const DR_FRICTION := 0.25 # drawer floors are slippery: parts only move when a wall hits them
const TRAY_POS := Vector3(-1.2, TABLE_Y, -0.02)
const TRAY_W := 0.9
const TRAY_D := 1.56
const TRAY_RIGHT := -0.74 # anything dropped left of this goes back to the tray
const TRAY_STEMS := ["vide", "ama", "puer", "puell", "agricol", "reg", "man", "r", "duc"]
const COPIES := 2 # of every stem in the tray and every ending in the drawers

# physics layers
const L_PICK := 1 # pieces you can click (and the table, which blocks clicks)
const L_LOOSE := 2 # loose pieces rolling around in the tray
const L_WORLD := 4 # surfaces loose pieces collide with
const L_PLUG := 8 # cable plugs (checked first so they're always grabbable)
const L_BLOCK := 16 # solid things that only stop clicks (drawers: you can't reach through their floor or sides)

const WOOD := Color("#e0a160")
const WOOD_DARK := Color("#b8743e")
const STEEL := Color("#9aa4ad")
const STEEL_DARK := Color("#6b757f")
const INK := Color("#17121f")

var camera: Camera3D
var chunks: Array = []
var drawers: Array = []
var loose: Array = [] # tiles lying loose in the tray
var dragging: Chunk = null
var grab_local := Vector3.ZERO # where the piece was grabbed, in its own frame
var drag_mouse := Vector2.ZERO
var pusher: AnimatableBody3D = null
var hold_dist := 1.0 # how far in front of the camera the held piece is
var player := Vector3(0.0, 0.0, 1.45) # where you stand
var yaw := 0.0
var pitch := deg_to_rad(-34.0)
var crosshair: Control
var reel_cool := 0.0
var snap_lit: Array = []
var hovered: Tile = null
var cords: Array = []
var held_cord: Cord = null
var plug_mouse := Vector2.ZERO
var plug_target: Tile = null # the piece whose hole the held plug is turning to face...
var plug_target_i := 0 # ...and which of its holes
const HOVER := 0.14 # a held plug is lifted this high until it nears a hole
const TRAIL := 0.28 # how far behind a carried word its loose plug trails
const CABLE := 1.4 # cable length: a plug can't get farther than this from its piece
var touch_clock := 0
var vel_y := 0.0 # jumping
var move_vel := Vector2.ZERO # walking velocity (x, z)
var bob_t := 0.0 # head-bob: phase...
var bob_amt := 0.0 # ...and how strong (0 standing still .. 1 walking)
var roll := 0.0 # leaning into a sideways step
var land_dip := 0.0
var step_alt := false # the camera dips a little when you land
var crouch_t := 0.0 # 0 standing .. 1 crouched
var held_yaw := 0.0 # how far you've turned the piece in your hands (scroll)
var held_tilt := 0.0
var gen_lit: Tile = null # genitive holder the held word would go into if you let go
# the billboard: a stack of pictures; make the computer show the same scene and press PROBA
const PUZZLES := [
	{"verb": "ama", "person": 3, "vnum": "sg", "subj": {"stem": "puell", "num": "sg"}, "obj": {"stem": "puer", "num": "sg"}},
	{"verb": "vide", "person": 3, "vnum": "pl", "subj": {"stem": "agricol", "num": "pl"}, "obj": {"stem": "equ", "num": "sg"}},
	{"verb": "porta", "person": 3, "vnum": "sg", "subj": {"stem": "serv", "num": "sg"}, "obj": {"stem": "aqu", "num": "sg"}},
	{"verb": "curr", "person": 3, "vnum": "pl", "subj": {"stem": "can", "num": "pl"}, "obj": null},
	{"verb": "duc", "person": 3, "vnum": "sg", "subj": {"stem": "reg", "num": "sg"}, "obj": {"stem": "milit", "num": "pl"}},
	{"verb": "vide", "person": 3, "vnum": "sg", "subj": {"stem": "puer", "num": "sg"}, "obj": {"stem": "equ", "num": "sg", "own": {"stem": "puell", "num": "sg"}}},
	{"verb": "audi", "person": 3, "vnum": "sg", "subj": {"stem": "matr", "num": "sg"}, "obj": {"stem": "fili", "num": "sg"}},
	{"verb": "capi", "person": 3, "vnum": "pl", "subj": {"stem": "lup", "num": "pl"}, "obj": {"stem": "puer", "num": "pl"}},
	{"verb": "veni", "person": 3, "vnum": "pl", "subj": {"stem": "naut", "num": "pl"}, "obj": null},
	{"verb": "capi", "person": 3, "vnum": "sg", "subj": {"stem": "regin", "num": "sg"}, "obj": {"stem": "man", "num": "sg", "own": {"stem": "milit", "num": "sg"}}},
	{"verb": "mitt", "person": 3, "vnum": "sg", "subj": {"stem": "domin", "num": "sg"}, "obj": {"stem": "serv", "num": "pl"}},
	{"verb": "porta", "person": 3, "vnum": "sg", "subj": {"stem": "agricol", "num": "sg", "own": {"stem": "patr", "num": "sg"}}, "obj": {"stem": "fruct", "num": "pl"}},
	{"verb": "erra", "person": 3, "vnum": "sg", "subj": {"stem": "greg", "num": "sg"}, "obj": null, "mods": [{"adv": "procul"}]},
	{"verb": "curr", "person": 3, "vnum": "sg", "subj": {"stem": "puer", "num": "sg"}, "obj": null,
			"mods": [{"prep": "ad", "case": "acc", "noun": {"stem": "riv", "num": "sg"}}]},
	{"verb": "veni", "person": 3, "vnum": "pl", "subj": {"stem": "naut", "num": "pl"}, "obj": null,
			"mods": [{"prep": "ab", "case": "abl", "noun": {"stem": "litor", "num": "sg"}}]},
]
const BOARD_POS := Vector3(1.05, 1.82, WALL_Z + 0.03)
const BOARD_W := 0.84
var bulletin: Node3D # the corkboard on the left wall (achievements, challenge map)
var badge_slots: Array = [] # Node3D spots on it, one per future achievement
var monitor_body: Node3D # (the cables go round it)
var tab_nodes := {} # the computer's tab buttons
var map_nodes: Array = [] # stops on the challenge map
var board_i := 0 # which picture is showing
var board_list: Array = [] # the pictures of the picture-builder task being done
var board_front: MeshInstance3D = null
var board_back: MeshInstance3D = null
var board_count: Label3D
var verdict_t := 0.0 # "recte!" / "non idem" banner on the computer
var verdict_ok := false
var reel_spinning: Array = [] # ending reels being turned (they settle when you stop)
var owned_by := {} # Chunk standing in a genitive's holder -> the genitive ending Tile
var screen_tex: ImageTexture
var screen_mat: ShaderMaterial
var screen_body: StaticBody3D
var disp_cord: Cord = null # the computer's cable: plug it into a verb to see the sentence
var screen_tab := "scene" # "scene" (TABVLA) | "search" (QVAERE)
var tab_mats := {}
var query := ""
var sel := 0
var sent_msg := ""
var sent_t := 0.0
var blink_t := 0.0
var screen_key := ""
var noise_t := 0.0
# scroll-to-inspect: a whole cable-connected group turns together
const SPIN_K := 0.2 # radians per unit of trackpad travel
const PAN_SIGN := 1.0 # flip to -1.0 if the trackpad feels backwards
var insp_group: Array = []
var insp_rest := {} # chunk -> [position, quaternion] while flat on the table
var insp_pivot := Vector3.ZERO
var insp_tilt := 0.0
var insp_idle := 9.0
var pend_yaw := 0.0
var pend_tilt := 0.0
var reel_accum := 0.0
const REEL_STEP := 0.45 # trackpad travel needed to turn a reel one notch
const REEL_COOL := 0.22 # pause after each notch


func _ready() -> void:
	sounds_from = Time.get_ticks_msec() + 3500
	var a0 := OS.get_cmdline_user_args()
	campaign_on = not ("--test" in a0 or "--demo" in a0)
	Latin.level = 1 if campaign_on else 99 # the self-test and demo have everything unlocked
	Art.setup()
	_build_world()
	_build_table()
	_build_tray()
	_build_chute()
	_build_trash()
	_build_drawers()
	_build_monitor()
	_build_board()
	_build_side_wall()
	_matte_tree(bulletin)
	_build_room()
	_build_bins()
	_build_ui()
	_board_load([] if campaign_on else PUZZLES)
	_apply_locks()
	if campaign_on:
		_load_settings()
		_build_menu()
		if boot_mode == "load":
			_load_game()
			_start_play()
		elif boot_mode == "new":
			_start_play()
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				_toast("Welcome to the officina! Your tasks are the sticky notes on the board to your left.", 6.0))
		boot_mode = ""
	if "--wallview" in a0: # screenshot: the sticky notes on the board
		player = Vector3(SIDE_X + 1.2, 0, 0.9)
		yaw = deg_to_rad(90)
		pitch = deg_to_rad(-3)
		_place_camera()
	if "--noteopen" in a0: # screenshot: a note up close
		get_tree().create_timer(2.0).timeout.connect(_open_note.bind(1, "recon"))
	if "--demo" in OS.get_cmdline_user_args():
		_demo.call_deferred()
	if "--test" in OS.get_cmdline_user_args():
		_self_test.call_deferred()
	var args := OS.get_cmdline_user_args()
	if "--perf" in args: # measure: frame rate, draw calls, script time per frame
		get_tree().create_timer(7.0).timeout.connect(func() -> void:
			prof = {"on": 0}
			var frames := 0
			var t0 := Time.get_ticks_usec()
			var script_us := 0.0
			while Time.get_ticks_usec() - t0 < 3000000:
				await get_tree().process_frame
				frames += 1
				script_us += Performance.get_monitor(Performance.TIME_PROCESS) * 1e6
			var secs := (Time.get_ticks_usec() - t0) / 1e6
			print("PERF fps=", snappedf(frames / secs, 0.1), "  process ms/frame=", snappedf(script_us / frames / 1000.0, 0.01),
					"  physics ms=", snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.01),
					"  draw calls=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
					"  objects=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
					"  nodes=", Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "  cords=", cords.size(),
					"  awake=", cords.filter(func(c): return is_instance_valid(c) and c._asleep <= 20).size(), "  world_ver=", Cord.world_ver)
			for k in prof:
				if k != "on":
					print("   ", k, ": ", snappedf(prof[k] / float(frames) / 1000.0, 0.001), " ms/frame")
			get_tree().quit())
	var si := args.find("--shot")
	if si >= 0 and si + 1 < args.size(): # screenshot after a few seconds, then quit
		var path: String = args[si + 1]
		get_tree().create_timer(float(args[si + 2]) if si + 2 < args.size() and args[si + 2].is_valid_float() else 5.0).timeout.connect(func() -> void:
			RenderingServer.force_draw(false) # macOS stops drawing a covered window
			get_viewport().get_texture().get_image().save_png(path)
			get_tree().quit())


# ---------------------------------------------------------------- world

func _build_world() -> void:
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#8fd6ff")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color.BLACK
	e.ambient_light_energy = 0.0
	e.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	we.environment = e
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 8, 0) # the sun is outside, behind the garage door: it only gets in through its windows
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 16.0
	sun.shadow_bias = 0.04
	add_child(sun)

	camera = Camera3D.new()
	camera.fov = 40
	add_child(camera)
	camera.fov = 68
	_place_camera()

	# repair shop: concrete floor, pegboard wall with tools hanging on it
	_matte(Art.box(self, Vector3(16, 0.1, 12), Vector3(0, -0.05, 0), Color("#8e9296"), 0))
	_collider(self, Vector3(16, 0.1, 12), Vector3(0, -0.05, 0), "floor", L_WORLD)
	_collider(self, Vector3(16, 7, 0.1), Vector3(0, 3.5, WALL_Z - 0.05), "wall", L_WORLD)
	var wall := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(16, 7, 0.1)
	wall.mesh = wm
	var pm := ShaderMaterial.new()
	pm.shader = load("res://shaders/pegboard.gdshader")
	pm.set_shader_parameter("albedo", Color("#c9a273"))
	wall.material_override = pm
	wall.position = Vector3(0, 3.5, WALL_Z - 0.05)
	add_child(wall)
	Art.box(self, Vector3(16, 0.18, 0.06), Vector3(0, 0.09, WALL_Z + 0.03), Color("#5d6268"), 0)
	_build_tools()

	var sign := Node3D.new()
	sign.position = Vector3(-0.2, 2.45, WALL_Z + 0.02)
	sign.rotation_degrees.z = 2
	add_child(sign)
	Art.box(sign, Vector3(1.2, 0.28, 0.03), Vector3.ZERO, Color("#2f5d8a"))
	Art.box(sign, Vector3(1.26, 0.04, 0.035), Vector3(0, -0.16, 0), STEEL_DARK)
	var lab := Art.label3d("OFFICINA", 130, 0.0016)
	lab.modulate = Color("#ffd23f")
	lab.position = Vector3(0, 0, 0.018)
	sign.add_child(lab)


## A few tools hanging on the pegboard.
func _build_tools() -> void:
	var z := WALL_Z + 0.03
	var red := Color("#d8423a")
	var yel := Color("#f2b632")
	for i in 4: # screwdrivers
		var x := -0.75 + i * 0.11
		Art.box(self, Vector3(0.012, 0.22, 0.012), Vector3(x, 2.0, z), Color("#c7ced6"))
		var h := CylinderMesh.new()
		h.top_radius = 0.026
		h.bottom_radius = 0.022
		h.height = 0.14
		Art.mesh(self, h, Vector3(x, 2.17, z + 0.01), red if i % 2 == 0 else yel, 2, 0.6)
	var wr := Node3D.new() # wrench
	wr.position = Vector3(0.35, 2.12, z)
	wr.rotation_degrees.z = -35
	add_child(wr)
	Art.box(wr, Vector3(0.05, 0.42, 0.016), Vector3.ZERO, Color("#c7ced6"))
	Art.box(wr, Vector3(0.03, 0.08, 0.016), Vector3(-0.035, 0.24, 0), Color("#c7ced6"))
	Art.box(wr, Vector3(0.03, 0.08, 0.016), Vector3(0.035, 0.24, 0), Color("#c7ced6"))
	var rg := CylinderMesh.new()
	rg.top_radius = 0.045
	rg.bottom_radius = 0.045
	rg.height = 0.016
	var ring := Art.mesh(wr, rg, Vector3(0, -0.23, 0), Color("#c7ced6"), 1, 0.6)
	ring.rotation_degrees.x = 90
	var hm := Node3D.new() # hammer
	hm.position = Vector3(-0.15, 2.0, z)
	hm.rotation_degrees.z = 8
	add_child(hm)
	Art.box(hm, Vector3(0.04, 0.4, 0.03), Vector3.ZERO, WOOD)
	Art.box(hm, Vector3(0.18, 0.06, 0.05), Vector3(0.02, 0.22, 0), STEEL_DARK)
	var co := Node3D.new() # coil of cable
	co.position = Vector3(1.75, 1.95, z)
	add_child(co)
	var tm := TorusMesh.new()
	tm.inner_radius = 0.1
	tm.outer_radius = 0.13
	var coil := Art.mesh(co, tm, Vector3.ZERO, Color("#3d7be0"), 1, 0.6)
	coil.rotation_degrees.x = 90
	Art.box(self, Vector3(0.03, 0.05, 0.04), Vector3(1.75, 2.09, z), STEEL_DARK)


func _build_table() -> void:
	# grey steel workbench
	_matte(Art.box(self, Vector3(3.3, 0.06, 1.8), Vector3(0, TABLE_Y - 0.03, 0), STEEL))
	_collider(self, Vector3(3.3, 0.06, 1.8), Vector3(0, TABLE_Y - 0.03, 0), "table", L_PICK | L_WORLD)
	Art.box(self, Vector3(3.32, 0.07, 0.04), Vector3(0, TABLE_Y - 0.039, 0.91), STEEL_DARK) # front lip (just under the top, so they don't fight)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			Art.box(self, Vector3(0.08, TABLE_Y - 0.06, 0.08), Vector3(sx * 1.55, (TABLE_Y - 0.06) * 0.5, sz * 0.8), STEEL_DARK)
	Art.box(self, Vector3(3.1, 0.03, 1.5), Vector3(0, 0.2, 0), STEEL_DARK) # bottom shelf
	# grey anti-static repair mat on the work area
	var mx := -0.03
	var mz := 0.28
	Art.box(self, Vector3(1.36, 0.002, 1.1), Vector3(mx, TABLE_Y, mz), Color("#3a4148"), -1)
	for i in range(1, 7):
		Art.box(self, Vector3(0.004, 0.0025, 1.1), Vector3(mx - 0.68 + i * 0.194, TABLE_Y, mz), Color("#56606a"), -1)
	for i in range(1, 6):
		Art.box(self, Vector3(1.36, 0.0025, 0.004), Vector3(mx, TABLE_Y, mz - 0.55 + i * 0.183), Color("#56606a"), -1)


var click_only: Array[RID] = []


func _collider(parent: Node3D, size: Vector3, pos: Vector3, kind: String, layer := L_PICK) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = layer
	b.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	b.position = pos
	b.set_meta("kind", kind)
	parent.add_child(b)
	if kind in ["drawer_front", "note", "tab", "screen"]: # only there to be clicked: nothing bumps into it
		click_only.append(b.get_rid())
	return b


# ---------------------------------------------------------------- stem tray (real physics)

func _build_tray() -> void:
	var tray := Node3D.new()
	tray.position = TRAY_POS
	add_child(tray)
	var col := Color("#5fa8d3")
	var rim := Color("#8cc8ea")
	Art.box(tray, Vector3(TRAY_W, 0.02, TRAY_D), Vector3(0, 0.01, 0), col)
	_collider(tray, Vector3(TRAY_W, 0.02, TRAY_D), Vector3(0, 0.01, 0), "tray", L_WORLD)
	for sz in [-1, 1]:
		Art.box(tray, Vector3(TRAY_W, 0.055, 0.03), Vector3(0, 0.0275, sz * TRAY_D * 0.5), rim)
		_collider(tray, Vector3(TRAY_W, 0.1, 0.03), Vector3(0, 0.05, sz * TRAY_D * 0.5), "tray", L_WORLD)
	for sx in [-1, 1]:
		Art.box(tray, Vector3(0.03, 0.055, TRAY_D), Vector3(sx * TRAY_W * 0.5, 0.0275, 0), rim)
		_collider(tray, Vector3(0.03, 0.1, TRAY_D), Vector3(sx * TRAY_W * 0.5, 0.05, 0), "tray", L_WORLD)
	var plate := Node3D.new()
	plate.position = Vector3(0, 0.03, TRAY_D * 0.5 + 0.017)
	tray.add_child(plate)
	Art.box(plate, Vector3(0.32, 0.045, 0.004), Vector3.ZERO, Color("#fff6dc"), 0, 0.5)
	var lab := Art.label3d("RADICES", 38)
	lab.position = Vector3(0, 0, 0.003)
	plate.add_child(lab)

	# tip every stem in, jumbled
	var all := []
	var args := OS.get_cmdline_user_args()
	var stems: Array = TRAY_STEMS if ("--test" in args or "--demo" in args) else [] # in play the tray starts empty
	for key in stems:
		for c in COPIES:
			all.append(key)
	all.shuffle()
	var cols := 3
	var rows := ceili(all.size() / float(cols))
	for i in all.size():
		var cx := TRAY_POS.x + (i % cols - 1) * 0.2 + randf_range(-0.02, 0.02)
		var cz := TRAY_POS.z - TRAY_D * 0.5 + 0.12 + (i / cols) * (TRAY_D - 0.24) / rows + randf_range(-0.02, 0.02)
		var p := Vector3(cx, TABLE_Y + 0.08 + (i % 3) * 0.09, cz)
		_make_loose(_new_tile("stem", all[i]), p, true)


## Hand a single new tile to the physics engine at `pos` (its centre).
func _make_loose(t: Tile, pos: Vector3, toss: bool) -> void:
	var c := _new_chunk([t], Vector3.ZERO)
	c.position = pos - t.target_pos
	_make_loose_chunk(c, toss, true)


## A word (or any row) lying loose: one rigid body for the whole thing, so it
## stays the word it was. Trays and drawers are just solid places it can lie in.
func _make_loose_chunk(c: Chunk, toss := false, jumble := false) -> void:
	_remove_chunk(c)
	for t: Tile in c.tiles:
		if t.move_tween:
			t.move_tween.kill()
		t.position = t.target_pos
		t.rotation = Vector3.ZERO
		t.scale = Vector3.ONE
	var centre := Vector3(c.width * 0.5, Tile.H * 0.5, 0)
	var gxf := Transform3D(c.global_basis.orthonormalized(), c.global_position) if c.is_inside_tree() else Transform3D(Basis.IDENTITY, c.position)
	var rb := RigidBody3D.new()
	rb.collision_layer = L_LOOSE
	rb.collision_mask = L_LOOSE | L_WORLD
	rb.mass = 0.08 * c.tiles.size()
	rb.linear_damp = 0.4
	var rolls: bool = c.tiles.size() > 0 and c.tiles[0].is_rod
	rb.angular_damp = 0.6 if rolls else 2.0
	rb.continuous_cd = true
	var pm := PhysicsMaterial.new()
	pm.friction = 0.7
	pm.bounce = 0.15
	rb.physics_material_override = pm
	rb.set_meta("chunk", c)
	rb.set_meta("tile", c.tiles[0])
	rb.contact_monitor = true # knocks make a sound
	rb.max_contacts_reported = 2
	rb.body_entered.connect(_on_loose_hit.bind(rb)) # clicking any part of it picks up the whole word
	add_child(rb)
	rb.global_transform = gxf * Transform3D(Basis.IDENTITY, centre)
	if jumble:
		rb.rotation = Vector3(randf_range(-0.2, 0.2), randf_range(-0.35, 0.35), 0.0)
	if c.get_parent():
		c.get_parent().remove_child(c)
	rb.add_child(c)
	c.transform = Transform3D(Basis.IDENTITY, -centre)
	for t: Tile in c.tiles:
		t.set_pickable(false)
		t.in_tray = true
		t.loose_body = rb
		loose.append(t)
	_loose_shapes(rb)
	if toss:
		rb.linear_velocity = Vector3(randf_range(-0.4, 0.4), -0.2, randf_range(-0.4, 0.4))
		rb.angular_velocity = Vector3(randf_range(-6, 6), randf_range(-2, 2), randf_range(-1, 1))


## Words lying loose that have come to rest face down (or on their side) roll
## over face up, so you can read them.
var _right_t := 0.0


func _right_words(delta: float) -> void:
	_right_t += delta
	if _right_t < 0.4:
		return
	_right_t = 0.0
	var seen := []
	for t: Tile in loose:
		if not is_instance_valid(t) or not t.loose_body or t.loose_body in seen or not t.loose_body.visible:
			continue
		var rb := t.loose_body
		seen.append(rb)
		if rb.freeze or rb.linear_velocity.length() > 0.05 or rb.angular_velocity.length() > 0.3:
			continue
		var c: Chunk = rb.get_meta("chunk")
		if not c.tiles.any(func(x): return x.kind == "stem"):
			continue
		if rb.global_basis.y.dot(Vector3.UP) > 0.8:
			continue
		var x := rb.global_basis.x
		x.y = 0.0
		x = x.normalized() if x.length() > 0.1 else Vector3.RIGHT
		var to := Transform3D(Basis(x, Vector3.UP, x.cross(Vector3.UP)), rb.global_position + Vector3.UP * 0.04)
		var from := rb.global_transform
		rb.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		rb.freeze = true
		var tw := rb.create_tween()
		tw.tween_method(func(f: float) -> void:
			if is_instance_valid(rb):
				rb.global_transform = from.interpolate_with(to, f), 0.0, 1.0, 0.3).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func() -> void:
			if is_instance_valid(rb):
				rb.freeze = false
				rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
				rb.sleeping = false)


var sounds_from := 0 # (msec) no knocks before this: everything settling at the start would be one loud pop
var last_knock := 0


## A loose piece hits something: knock, as loud as it hit.
func _on_loose_hit(_other: Node, rb: RigidBody3D) -> void:
	if not is_instance_valid(rb):
		return
	# (by the time this is reported the bounce has already taken some speed out: count the spin too)
	var speed := rb.linear_velocity.length() + rb.angular_velocity.length() * 0.06
	var now := Time.get_ticks_msec()
	if now < sounds_from or speed < 0.15 or now - int(rb.get_meta("hit_t", 0)) < 110:
		return # (nothing at all while everything first settles, when the game starts)
	if now - last_knock < 25: # lots at once (a pile settling): just one
		return
	last_knock = now
	rb.set_meta("hit_t", now)
	var c = rb.get_meta("chunk")
	var metal: bool = is_instance_valid(c) and c is Chunk and c.tiles.any(func(x): return is_instance_valid(x) and x.is_rod)
	var nm := ("clank%d" if metal else "thud%d") % randi_range(1, 3)
	Sfx.play(self, nm, rb.global_position, linear_to_db(clampf(speed / 2.0, 0.05, 1.0)) - 12.0, randf_range(0.9, 1.12))


## (Re)build a loose body's collision from the pieces of its word.
func _loose_shapes(rb: RigidBody3D) -> void:
	for ch in rb.get_children():
		if ch is CollisionShape3D:
			rb.remove_child(ch)
			ch.queue_free()
	var c: Chunk = rb.get_meta("chunk")
	for t: Tile in c.tiles:
		var cs := CollisionShape3D.new()
		cs.shape = t.physics_shape()
		cs.position = c.transform * (t.target_pos + t.shape_offset())
		if t.is_rod:
			cs.rotation_degrees.z = 90
		rb.add_child(cs)


## Pick a loose word up: it comes back as a row on the bench (the whole word).
func _take_loose(t: Tile) -> Chunk:
	var rb := t.loose_body
	var c: Chunk = rb.get_meta("chunk")
	var gxf := c.global_transform
	rb.remove_child(c)
	add_child(c)
	c.global_transform = gxf
	for tt: Tile in c.tiles:
		loose.erase(tt)
		tt.in_tray = false
		tt.loose_body = null
		tt.set_pickable(true)
	rb.queue_free()
	chunks.append(c)
	return c


## Test/demo helper: take one loose tile out on its own.
func _take_tile(t: Tile) -> Tile:
	var c := _take_loose(t)
	var gp := t.global_position
	c.remove_child(t)
	add_child(t)
	t.global_position = gp
	c.tiles.erase(t)
	if c.tiles.is_empty():
		_remove_chunk(c)
		c.queue_free()
	else:
		c.layout(false)
	return t


## Throw a row away for good, wherever it is (on the bench or lying loose).
func _discard(c: Chunk) -> void:
	if not is_instance_valid(c):
		return
	_remove_chunk(c)
	owned_by.erase(c)
	for t: Tile in c.tiles:
		loose.erase(t)
	var p := c.get_parent()
	if p is RigidBody3D:
		p.queue_free()
	else:
		c.queue_free()


func tray_count(key: String) -> int:
	var n := 0
	for t in loose.filter(func(x): return is_instance_valid(x)):
		if t.key == key:
			n += 1
	return n


# ---------------------------------------------------------------- delivery chute

func _build_chute() -> void:
	var ch := Node3D.new()
	add_child(ch)
	ch.position = (CHUTE_TOP + CHUTE_END) * 0.5
	ch.look_at_from_position(ch.position, CHUTE_END, Vector3.UP)
	var L := CHUTE_TOP.distance_to(CHUTE_END)
	var w := 0.5 # wider than any word, so one can't wedge across it
	Art.box(ch, Vector3(w, 0.012, L), Vector3.ZERO, STEEL, 0, 0.7)
	var slick := PhysicsMaterial.new() # polished steel: things slide straight down it
	slick.friction = 0.05
	slick.bounce = 0.05
	var cb := [_collider(ch, Vector3(w, 0.03, L), Vector3(0, -0.01, 0), "chute", L_WORLD)]
	for sx in [-1, 1]:
		Art.box(ch, Vector3(0.012, 0.09, L), Vector3(sx * w * 0.5, 0.045, 0), STEEL_DARK, 0, 0.7)
		cb.append(_collider(ch, Vector3(0.03, 0.2, L), Vector3(sx * w * 0.5, 0.1, 0), "chute", L_WORLD))
	for b: StaticBody3D in cb:
		b.physics_material_override = slick
	# hatch in the wall it comes out of
	var hatch := Node3D.new()
	hatch.position = Vector3(CHUTE_TOP.x, CHUTE_TOP.y + 0.08, WALL_Z + 0.02)
	add_child(hatch)
	Art.box(hatch, Vector3(w + 0.1, 0.26, 0.04), Vector3.ZERO, STEEL_DARK)
	Art.box(hatch, Vector3(w, 0.18, 0.02), Vector3(0, -0.01, 0.015), Color("#1d1824"), -1)
	var lab := Art.label3d("TVBVS", 34)
	lab.modulate = Color("#ffd23f")
	lab.position = Vector3(0, 0.155, 0.0)
	hatch.add_child(lab)
	Art.box(hatch, Vector3(0.24, 0.06, 0.01), Vector3(0, 0.155, -0.006), Color("#2f5d8a"))


func _build_trash() -> void:
	var bin := Node3D.new()
	bin.position = TRASH_POS
	add_child(bin)
	var cm := CylinderMesh.new()
	cm.top_radius = TRASH_R
	cm.bottom_radius = TRASH_R * 0.86
	cm.height = TRASH_H
	cm.cap_top = false
	cm.radial_segments = 28
	Art.mesh(bin, cm, Vector3(0, TRASH_H * 0.5, 0), Color("#5f8f6a"), 2, 0.9, true)
	var inside := CylinderMesh.new()
	inside.top_radius = TRASH_R * 0.86 - 0.005
	inside.bottom_radius = TRASH_R * 0.86 - 0.005
	inside.height = 0.004
	Art.mesh(bin, inside, Vector3(0, 0.02, 0), Color("#1d1824"), -1)
	var rim := TorusMesh.new()
	rim.inner_radius = TRASH_R - 0.01
	rim.outer_radius = TRASH_R + 0.012
	Art.mesh(bin, rim, Vector3(0, TRASH_H, 0), STEEL, 1, 0.7)
	for y in [0.2, 0.45, 0.66]: # ribs
		var rb := TorusMesh.new()
		var r := lerpf(TRASH_R * 0.86, TRASH_R, y / TRASH_H) + 0.003
		rb.inner_radius = r - 0.005
		rb.outer_radius = r + 0.008
		Art.mesh(bin, rb, Vector3(0, y, 0), Color("#4b7656"), -1)
	var lab := Art.label3d("QVISQVILIAE", 46)
	lab.modulate = Color("#f4f1e6")
	lab.position = Vector3(-TRASH_R * 0.97, TRASH_H * 0.55, 0)
	lab.rotation_degrees = Vector3(0, -90, 0)
	bin.add_child(lab)
	# solid: a ring of wall panels and a floor (open at the top)
	for k in 14:
		var a := TAU * k / 14.0
		var wb := _collider(bin, Vector3(0.03, TRASH_H, TAU * TRASH_R / 14.0 + 0.02), Vector3(cos(a) * TRASH_R, TRASH_H * 0.5, sin(a) * TRASH_R), "bin", L_WORLD)
		wb.rotation.y = -a
	_collider(bin, Vector3(TRASH_R * 2.0, 0.03, TRASH_R * 2.0), Vector3(0, 0.015, 0), "bin", L_WORLD)


## Into the bin: the pieces drop in and are gone.
func _trash(d: Chunk) -> void:
	_remove_chunk(d)
	for t: Tile in d.tiles: # thrown-away endings turn up again in their drawers
		if t.kind == "ending" and not t.soldered:
			_restock(t)
	var tw := d.create_tween().set_parallel()
	tw.tween_property(d, "position", Vector3(TRASH_POS.x - d.width * 0.3, TRASH_POS.y + 0.05, TRASH_POS.z), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(d, "scale", Vector3.ONE * 0.6, 0.3)
	tw.chain().tween_callback(d.queue_free)


## A fresh copy of this ending, dropped back into the drawer it came from.
func _restock(t: Tile) -> void:
	var i: int = t.get_meta("drawer_i", _drawer_for(t.cat))
	if i < 0 or i >= drawers.size():
		return
	var d: Dictionary = drawers[i]
	var et := _new_tile("ending", t.reel_base + "~" if t.is_reel() else t.key, t.cat)
	et.set_meta("drawer_i", i)
	var dn: Node3D = d["node"]
	_make_loose(et, dn.global_transform * Vector3(randf_range(-0.3, 0.3) * d["iw"], 0.08, randf_range(-0.3, 0.3) * d["dd"]), false)


## A stem ordered on the computer arrives down the chute into the tray.
func _deliver(key: String) -> void:
	tut_ordered.append(key)
	var t := _new_tile("stem", key)
	var dir := (CHUTE_END - CHUTE_TOP).normalized()
	var up := Vector3(-1, 0, 0).cross(dir).normalized()
	var spawn := CHUTE_TOP + dir * 0.06 + up * 0.05
	_make_loose(t, spawn, false)
	t.loose_body.global_basis = Basis(Vector3.RIGHT, up, Vector3.RIGHT.cross(up))
	t.loose_body.global_position = spawn
	_slide_down_chute(t.loose_body, spawn)


## Something sent down the chute slides down it face up, gathering speed, tips
## level as it goes over the end and drops flat into the tray, face up. (Left to
## tumble freely off the lip, words landed any old way: face down, on their side.)
func _slide_down_chute(rb: RigidBody3D, center: Vector3) -> void:
	var dir := (CHUTE_END - CHUTE_TOP).normalized()
	var up := Vector3(-1, 0, 0).cross(dir).normalized()
	var lc := rb.global_transform.affine_inverse() * center # the piece's middle, in the body
	var lift := (center - CHUTE_TOP).dot(up)
	var b_chute := rb.global_basis
	var b_flat := Basis(Vector3.RIGHT, Vector3.UP, Vector3.RIGHT.cross(Vector3.UP))
	var lip := CHUTE_END + up * lift
	var out := lip + Vector3(0, -0.04, 0.1)
	var place := func(p: Vector3, bb: Basis) -> void:
		if is_instance_valid(rb):
			rb.global_transform = Transform3D(bb, p - bb * lc)
	rb.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	rb.freeze = true
	var secs := sqrt(2.0 * center.distance_to(lip) / 3.5) # (as if sliding under gravity, less friction)
	var tw := rb.create_tween()
	tw.tween_method(func(f: float) -> void: place.call(center.lerp(lip, f * f), b_chute), 0.0, 1.0, secs)
	tw.tween_method(func(f: float) -> void: place.call(lip.lerp(out, f), b_chute.slerp(b_flat, f)), 0.0, 1.0, 0.09)
	tw.tween_callback(func() -> void:
		if is_instance_valid(rb):
			rb.freeze = false
			rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
			rb.sleeping = false
			rb.angular_velocity = Vector3.ZERO
			# (a verb rod is round: any push forward and it rolls over onto its side)
			var c = rb.get_meta("chunk")
			var round: bool = c is Chunk and c.tiles.any(func(x): return x.is_rod)
			rb.linear_velocity = Vector3(0, -0.5, 0.0 if round else 0.35))


# ---------------------------------------------------------------- drawers

func _build_drawers() -> void:
	var red := Color("#c8473d")
	var red_dark := Color("#a83a32")
	for cab_info in CABINETS:
		var cats: Array = cab_info["cats"]
		var n := cats.size()
		var h := n * DR_PITCH + 0.02
		var cw: float = cab_info["w"]
		var cab := Node3D.new() # origin: bottom centre of the cabinet
		var top: float = cab_info.get("top", CAB_TOP)
		var yaw0: float = cab_info.get("yaw", 0.0)
		cab.position = Vector3(cab_info["x"], top - h, cab_info.get("z", CAB_Z))
		cab.rotation.y = yaw0
		add_child(cab)
		if cab_info.get("legs", false): # standing on the floor
			for lx in [-1, 1]:
				for lz in [-1, 1]:
					Art.box(cab, Vector3(0.04, top - h, 0.04), Vector3(lx * (cw * 0.5 - 0.03), -(top - h) * 0.5, lz * (CAB_D * 0.5 - 0.03)), STEEL_DARK)
			Art.box(cab, Vector3(cw, 0.02, CAB_D), Vector3(0, h + 0.01, 0), Color("#a83a32")) # a top
			_collider(cab, Vector3(cw, 0.02, CAB_D), Vector3(0, h + 0.01, 0), "cabinet", L_WORLD | L_BLOCK)
			_collider(cab, Vector3(cw, top - h + 0.02, CAB_D), Vector3(0, -(top - h) * 0.5, 0), "cabinet", L_WORLD | L_BLOCK)
		# the shell, hung from the underside of the bench top
		for sx in [-1, 1]:
			Art.box(cab, Vector3(0.025, h, CAB_D), Vector3(sx * (cw * 0.5 - 0.0125), h * 0.5, 0), red)
			_collider(cab, Vector3(0.025, h, CAB_D), Vector3(sx * (cw * 0.5 - 0.0125), h * 0.5, 0), "cabinet", L_WORLD | L_BLOCK)
		Art.box(cab, Vector3(cw, h, 0.025), Vector3(0, h * 0.5, -CAB_D * 0.5 + 0.0125), red_dark)
		_collider(cab, Vector3(cw, h, 0.025), Vector3(0, h * 0.5, -CAB_D * 0.5 + 0.0125), "cabinet", L_WORLD | L_BLOCK)
		Art.box(cab, Vector3(cw, 0.012, CAB_D), Vector3(0, 0.004, 0), red_dark)
		_collider(cab, Vector3(cw, 0.012, CAB_D), Vector3(0, 0.004, 0), "cabinet", L_WORLD | L_BLOCK)
		Art.box(cab, Vector3(cw, 0.01, CAB_D), Vector3(0, h - 0.005, 0), red_dark)
		for k in range(1, n): # shelves between the drawers
			Art.box(cab, Vector3(cw - 0.05, 0.008, CAB_D - 0.03), Vector3(0, 0.01 + k * DR_PITCH, 0), STEEL_DARK, -1)
			_collider(cab, Vector3(cw - 0.05, 0.008, CAB_D - 0.03), Vector3(0, 0.01 + k * DR_PITCH, -0.015), "cabinet", L_WORLD | L_BLOCK)
		for k in n:
			_build_drawer(cats[k], cab.position + Vector3(0, 0.01 + (n - 1 - k) * DR_PITCH + 0.008, 0), cw, yaw0) # first one on top


## One drawer: a solid (kinematic) box that slides out toward you. What lies in
## it isn't attached to it at all: its walls and floor just push things about.
func _build_drawer(id: String, closed: Vector3, cw: float, yaw := 0.0, dd: float = DR_IN_D, open_d: float = DR_OPEN) -> void:
	var dinfo: Dictionary = {}
	for info in Latin.DRAWERS:
		if info.get("id", info["cat"]) == id:
			dinfo = info
	var cat: String = dinfo["cat"]
	var iw := cw - 0.1 # inside width
	var idx := drawers.size()
	var dn := AnimatableBody3D.new()
	dn.sync_to_physics = true
	dn.collision_layer = L_WORLD | L_BLOCK
	dn.collision_mask = 0
	var pmat := PhysicsMaterial.new()
	pmat.friction = DR_FRICTION
	pmat.bounce = 0.05
	dn.physics_material_override = pmat
	dn.set_meta("kind", "drawer")
	dn.position = closed
	dn.rotation.y = yaw # (its front faces local +z)
	add_child(dn)
	var half := dd * 0.5
	var wall_h := DR_PITCH - 0.035
	var shapes := [ # [size, position]: floor, side walls, back, front
		[Vector3(iw, 0.02, dd), Vector3(0, -0.005, 0)],
		[Vector3(0.02, wall_h, dd), Vector3(-iw * 0.5, wall_h * 0.5, 0)],
		[Vector3(0.02, wall_h, dd), Vector3(iw * 0.5, wall_h * 0.5, 0)],
		[Vector3(iw, wall_h, 0.02), Vector3(0, wall_h * 0.5, -half)],
		[Vector3(iw, wall_h, 0.03), Vector3(0, wall_h * 0.5, half + 0.005)],
	]
	for sh in shapes:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = sh[0]
		cs.shape = bs
		cs.position = sh[1]
		dn.add_child(cs)
	Art.box(dn, Vector3(iw, 0.01, dd), Vector3(0, 0.0, 0), Color("#d7dde2"), -1)
	for sx in [-1, 1]:
		Art.box(dn, Vector3(0.012, wall_h, dd), Vector3(sx * iw * 0.5, wall_h * 0.5, 0), STEEL, 0, 0.6)
	Art.box(dn, Vector3(iw, wall_h, 0.012), Vector3(0, wall_h * 0.5, -half), STEEL, 0, 0.6)
	# the front fills the drawer's slot in the cabinet
	var fh := DR_PITCH - 0.012
	var fy := -0.006 + fh * 0.5
	Art.box(dn, Vector3(cw - 0.03, fh, 0.03), Vector3(0, fy, half + 0.015), Color("#e4574a"))
	Art.box(dn, Vector3(minf(0.3, cw * 0.6), 0.022, 0.03), Vector3(0, fy - 0.035, half + 0.045), Color("#c7ced6"), 0, 0.6) # handle
	var cat_col := Tile.color_for("ending", "", cat)
	Art.box(dn, Vector3(minf(0.3, cw * 0.8), 0.05, 0.006), Vector3(0, fy + 0.025, half + 0.032), cat_col, 0, 0.6)
	var lab := Art.label3d(dinfo["name"], 36 if cw > 0.5 else 26)
	lab.position = Vector3(0, fy + 0.025, half + 0.036)
	dn.add_child(lab)
	var front := _collider(dn, Vector3(cw - 0.03, fh, 0.08), Vector3(0, fy, half + 0.04), "drawer_front")
	front.set_meta("drawer", idx)
	var blank := Node3D.new() # a plain panel that fills its slot while the drawer isn't unlocked
	add_child(blank)
	blank.global_transform = dn.global_transform
	Art.box(blank, Vector3(cw - 0.03, fh, 0.03), Vector3(0, fy, half + 0.015), Color("#c8473d"))
	blank.visible = false
	drawers.append({"node": dn, "open": false, "closed": closed, "cat": cat, "id": id, "name": dinfo["name"], "w": maxf(cw, dd),
			"iw": iw, "dd": dd, "order": dinfo["endings"], "front": front, "blank": blank,
			"open_vec": Basis(Vector3.UP, yaw) * Vector3(0, 0, open_d)})

	# a finite heap of loose endings, tipped in and left to settle
	var keys := []
	for e in dinfo["endings"]:
		for c in (3 if e.ends_with("~") else COPIES):
			keys.append(e)
	keys.shuffle()
	var ncol := 3 if iw > 0.45 else (2 if iw > 0.3 else 1)
	var nrow := clampi(int(dd / 0.165), 1, 4)
	for j in keys.size():
		var col := j % ncol
		var row := (j / ncol) % nrow
		var layer := j / (ncol * nrow)
		var lp := Vector3((col - (ncol - 1) * 0.5) * 0.18, 0.05 + layer * 0.075, -dd * 0.5 + 0.08 + row * 0.165)
		var et := _new_tile("ending", keys[j], cat)
		et.set_meta("drawer_i", idx) # (which drawer it came from)
		_make_loose(et, dn.global_transform * lp, false)


func _drawer_for(cat: String) -> int:
	for i in drawers.size():
		if drawers[i]["cat"] == cat:
			return i
	return 0


func _toggle_drawer(i: int, only := true) -> void:
	var d: Dictionary = drawers[i]
	if not d["open"] and only: # one drawer out at a time
		for k in drawers.size():
			if k != i and drawers[k]["open"]:
				_toggle_drawer(k, false)
	d["open"] = not d["open"]
	var to: Vector3 = d["closed"] + (d["open_vec"] if d["open"] else Vector3.ZERO)
	var dn: AnimatableBody3D = d["node"]
	if d.has("tween") and d["tween"] and d["tween"].is_valid():
		d["tween"].kill()
	var slide := func(p: Vector3) -> void:
		dn.position = p
		for t: Tile in loose: # anything near it is awake to be pushed
			var rb := t.loose_body
			if rb and Vector2(rb.global_position.x - p.x, rb.global_position.z - p.z).length() < d["w"] + 0.5 and rb.global_position.y < p.y + 0.3:
				rb.sleeping = false
	Sfx.play(self, "slide", dn.global_position, -8.0)
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_method(slide, dn.position, to, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	d["tween"] = tw


# ---------------------------------------------------------------- chunks

func _new_tile(kind: String, key: String, cat := "") -> Tile:
	var t := Tile.new()
	if key.ends_with("~"): # an ending with a window, e.g. "a~"
		t.setup_reel(key.left(-1), cat)
	else:
		t.setup(kind, key, cat)
	if not t.cord_specs.is_empty():
		_attach_cord(t, true)
	return t


## Give a piece its cables (one per entry in its cord_specs).
func _attach_cord(t: Tile, interactive: bool, emerge0 := 1.0) -> void:
	t.cords_out = []
	for spec in t.cord_specs:
		var c := Cord.new()
		add_child(c)
		c.setup(t, interactive, TABLE_Y if interactive else -INF, spec)
		if interactive:
			c.obstacles = _solid_boxes.bind(null)
			c.resolve = func(b: Basis, o: Vector3, smp: Array) -> Vector3: return _push_out(b, o, _solid_boxes(null), smp)
		c.emerge = emerge0
		cords.append(c)
		t.cords_out.append(c)
	t.cord = t.cords_out[0] if not t.cords_out.is_empty() else null


func _touch(t: Tile) -> void:
	if is_instance_valid(t):
		touch_clock += 1
		t.touch = touch_clock


func _new_chunk(tiles: Array, pos: Vector3) -> Chunk:
	var c := Chunk.new()
	add_child(c)
	c.position = pos
	for t in tiles:
		if t.get_parent():
			t.get_parent().remove_child(t)
		c.add_child(t)
	c.tiles = tiles
	c.layout(false)
	chunks.append(c)
	return c


func _remove_chunk(c: Chunk) -> void:
	chunks.erase(c)


func _poof(n: Node3D) -> void:
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "scale", Vector3.ONE * 0.01, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(n, "position:y", n.position.y + 0.08, 0.2)
	tw.chain().tween_callback(n.queue_free)


## Pull a word (or an ending, or the whole row) out of its chunk.
func _extract(t: Tile, whole: bool) -> Chunk:
	var c: Chunk = t.get_parent()
	var i := c.tiles.find(t)
	var idxs := []
	if whole:
		idxs = range(c.tiles.size())
	elif t.kind == "ending":
		idxs = [i]
		if i + 1 < c.tiles.size() and Chunk.is_cap(c.tiles[i + 1]): # (its adjective cap stays on it)
			idxs.append(i + 1)
	else:
		idxs = [i]
		if i + 1 < c.tiles.size() and c.tiles[i + 1].kind == "ending":
			idxs.append(i + 1)
			if i + 2 < c.tiles.size() and Chunk.is_cap(c.tiles[i + 2]):
				idxs.append(i + 2)
	if idxs.size() == c.tiles.size():
		return c
	var moving := []
	for j in idxs:
		moving.append(c.tiles[j])
	var first: Tile = moving[0]
	var left := c.transform * Vector3(first.position.x - first.width * 0.5, 0, 0)
	for m in moving:
		c.tiles.erase(m)
	var d := Chunk.new()
	add_child(d)
	for m in moving:
		c.remove_child(m)
		d.add_child(m)
	d.tiles = moving
	d.layout(false)
	d.quaternion = c.quaternion
	d.position = Vector3(left.x, TABLE_Y, left.z)
	if t.kind == "ending" and not whole: # it's still on the stem: it has to slide off
		d.set_meta("unseated_from", c)
	chunks.append(d)
	c.layout(true)
	_refresh(c)
	return d


func _try_insert(d: Chunk, snap: Dictionary) -> bool:
	var c: Chunk = snap["chunk"]
	var s: Dictionary = snap["slot"]
	var new_list: Array = c.tiles.duplicate()
	var removed: Tile = null
	if s["replace"] >= 0:
		removed = new_list[s["replace"]]
		new_list[s["replace"]] = d.tiles[0]
	else:
		for j in d.tiles.size():
			new_list.insert(s["index"] + j, d.tiles[j])
	var v := Chunk.validate(new_list)
	if not v["ok"]:
		return false # it doesn't fit: the piece shakes and stays loose

	var globals := {}
	for t in c.tiles + d.tiles:
		globals[t] = t.global_position
	if s.get("before", false): # the row now starts where the new word is
		c.position = c.transform * Vector3(snap["lx"], 0, 0)
	for t in d.tiles:
		d.remove_child(t)
		c.add_child(t)
	if removed: # the ending it replaced pops off and lies in front of the word
		c.remove_child(removed)
		var pc := _new_chunk([removed], Vector3.ZERO)
		var gp: Vector3 = globals[removed]
		pc.position = Vector3(gp.x - removed.width * 0.5, TABLE_Y, gp.z)
		var tw := pc.create_tween()
		tw.tween_property(pc, "position:z", gp.z + 0.2, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	c.tiles = new_list
	for t in c.tiles:
		t.global_position = globals[t]
	c.layout(true)
	for t in d.tiles:
		_touch(t)
	_remove_chunk(d)
	d.queue_free()
	c.bounce(1.04)
	Sfx.play(self, "seat", c.global_position)
	_refresh(c)
	return true


## What's under a point: the bench (or a word lying on it), the bin, or
## anywhere else (the stem tray, a drawer, the floor, the monitor...).
func _surface_at(p: Vector3, d: Chunk = null) -> Dictionary:
	if Vector2(p.x - TRASH_POS.x, p.z - TRASH_POS.z).length() < TRASH_R and p.y > TRASH_H * 0.5:
		return {"kind": "trash"}
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.03, p + Vector3.DOWN * 5.0, L_WORLD)
	var excl: Array[RID] = click_only.duplicate()
	if is_instance_valid(pusher):
		excl.append(pusher.get_rid())
	if d:
		for c: Chunk in [d] + _owned_tree(d):
			for t: Tile in c.tiles:
				if t.body:
					excl.append(t.body.get_rid())
	q.exclude = excl
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return {"kind": "floor"}
	var col: Object = hit["collider"]
	if col.has_meta("tile"):
		return {"kind": "table"} # onto a word lying on the bench
	var k: String = col.get_meta("kind", "floor")
	if k == "bin":
		return {"kind": "trash"}
	return {"kind": k}


## Let go of a row: on the bench it drops flat onto the bench; anywhere else it
## becomes a loose body and falls (into the tray, a drawer, onto the floor...).
func _put_down(d: Chunk) -> void:
	var centre := d.transform * Vector3(d.width * 0.5, Tile.H * 0.5, 0)
	var surf := _surface_at(d.transform * Vector3(d.width * 0.5, 0, 0), d)
	match surf["kind"]:
		"table": # it lands flat on the bench
			var lq := _level_q(d.quaternion)
			d.quaternion = lq
			d.position = centre - lq * Vector3(d.width * 0.5, Tile.H * 0.5, 0)
			_shove(d, null)
			var h := d.position.y - TABLE_Y
			if h > 0.002:
				var tw := d.create_tween()
				tw.tween_property(d, "position:y", TABLE_Y, sqrt(2.0 * h / 9.8)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tw.tween_callback(func() -> void:
					_shove(d, null)
					d.bounce(1.02)
					Sfx.play(self, "place", d.global_position, -14.0))
			else:
				d.position.y = TABLE_Y
				Sfx.play(self, "place", d.global_position, -16.0)
			_refresh(d)
		"trash":
			_trash(d)
		_:
			_make_loose_chunk(d)


## A held piece turns its printed face toward you, upright, like a card held up
## (then turned however far you've scrolled it round).
func _face_q() -> Quaternion:
	var cb := camera.global_basis.orthonormalized()
	var face := Basis(cb.x, cb.z, cb.x.cross(cb.z)).get_rotation_quaternion()
	return (Quaternion(cb.y, held_yaw) * Quaternion(cb.x, held_tilt) * face).normalized()


func _turn_held(dyaw: float, dtilt: float) -> void:
	held_yaw = wrapf(held_yaw + dyaw, -PI, PI)
	held_tilt = clampf(held_tilt + dtilt, -PI * 0.5, PI * 0.5)


func _level_q(q: Quaternion) -> Quaternion:
	return _level(Basis(q)).get_rotation_quaternion()


func _refresh(c: Chunk) -> void:
	if not is_instance_valid(c) or c.tiles.is_empty():
		return
	var words := c.get_words()
	var infos := []
	for w in words:
		infos.append(Latin.word_info(w["stem"], w["cat"], w["ending"]))
	c.analysis = Latin.analyze(infos)
	var tags := []
	for info in infos: # word-level grammar only; the cables say who does what
		if info["complete"]:
			var rs := PackedStringArray()
			for r in info["readings"]:
				rs.append(Latin.reading_tag(r))
			tags.append(" / ".join(rs))
		else:
			tags.append("needs an ending" if info["stem"] != "" else "")
	c.set_tags([], words) # no grammar notes under the pieces


# ---------------------------------------------------------------- input

func _ray(pos: Vector2) -> Dictionary:
	var from := camera.project_ray_origin(pos)
	var to := from + camera.project_ray_normal(pos) * 50.0
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, L_PLUG))
	if not hit.is_empty():
		return hit
	var h2 := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, L_PICK | L_LOOSE | L_BLOCK))
	if not h2.is_empty() and h2["collider"].collision_layer & L_BLOCK: # a drawer's floor or side, a cabinet's top, in the way
		return {}
	return h2


func _plane_point(pos: Vector2, y: float) -> Vector3:
	var o := camera.project_ray_origin(pos)
	var n := camera.project_ray_normal(pos)
	var t := (y - o.y) / n.y if absf(n.y) > 0.0001 else -1.0
	if t <= 0.0 or t > 4.0: # looking away from that height: just in front of you
		t = 1.2
	return o + n * t


func _unhandled_input(event: InputEvent) -> void:
	if _menu_open():
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and game_started:
			_menu_resume()
		return
	if note_panel and note_panel.visible: # a sticky note is up close
		if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_E):
			_close_note()
		return
	if event is InputEventKey and event.pressed and screen_tab == "search":
		_search_key(event)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if campaign_on and menu_layer: # the menu
				_show_menu()
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			return
		if event.physical_keycode == KEY_E: # pick up / put down
			_use(false) # (Shift is crouch; right-click picks up a whole word)
			return
		if event.physical_keycode == KEY_SPACE: # jump (only from the floor)
			if player.y <= 0.001:
				vel_y = JUMP_V
			return
	if event is InputEventPanGesture: # Mac trackpad two-finger scroll
		var m: Vector2 = -event.delta * PAN_SIGN
		if dragging: # holding something: turn it in your hands
			_turn_held(m.x * SPIN_K, m.y * SPIN_K)
			return
		_spin_at(_aim(event.position), m.x * SPIN_K, m.y * SPIN_K) # (only ending reels turn)
		return
	if event is InputEventMouseMotion:
		_note_shake(event.relative.x if _captured() else event.relative.x)
		if _captured(): # look around
			yaw -= event.relative.x * LOOK_SENS
			pitch = clampf(pitch - event.relative.y * LOOK_SENS, deg_to_rad(-85), deg_to_rad(60))
			_place_camera()
			return
		if held_cord:
			plug_mouse = event.position
		elif dragging:
			_drag_to(event.position)
		else:
			_hover(event.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var wheel := mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN
		if mb.pressed and wheel:
			var up := mb.button_index == MOUSE_BUTTON_WHEEL_UP
			if dragging: # turn the held piece (Shift: tip it toward / away from you)
				if mb.shift_pressed:
					_turn_held(0.0, -0.15 if up else 0.15)
				else:
					_turn_held(0.15 if up else -0.15, 0.0)
			elif mb.shift_pressed:
				_spin_at(_aim(mb.position), 0.0, -0.15 if up else 0.15)
			else:
				_spin_at(_aim(mb.position), 0.15 if up else -0.15, 0.0, true)
			return
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed: # let go: no more sweeping
			sweep_on = false
		if not mb.pressed or (mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT):
			return
		if not _captured() and not OS.get_cmdline_user_args().has("--test"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # first click takes over the mouse
			return
		var was_holding := dragging != null or held_cord != null
		_use(mb.button_index == MOUSE_BUTTON_RIGHT, mb.position)
		if mb.button_index == MOUSE_BUTTON_LEFT and not was_holding and dragging == null and held_cord == null:
			# pressed on nothing: maybe the start of a sweep across the bench
			var p := _plane_point(_aim(mb.position), TABLE_Y)
			if absf(p.x) < 1.65 and absf(p.z) < 0.9:
				sweep_on = true
				sweep_x0 = p.x


# ---------------------------------------------------------------- tidying: shake a drawer, sweep the bench

var shake_sign := 0.0
var shake_revs: Array = []
var shake_last := -9.0
var sweep_on := false # button held down after pressing on an empty bit of the bench
var sweep_x0 := 0.0


## Shaking the mouse from side to side (several quick reversals).
func _note_shake(dx: float) -> void:
	if absf(dx) < 6.0 or dragging or held_cord or sweep_on:
		return
	var now := Time.get_ticks_msec() / 1000.0
	var sg := signf(dx)
	if sg != shake_sign:
		shake_sign = sg
		shake_revs.append(now)
	shake_revs = shake_revs.filter(func(t): return now - t < 0.8)
	if shake_revs.size() >= 5 and now - shake_last > 1.0:
		shake_last = now
		shake_revs.clear()
		if not _shake_drawer(_aim(drag_mouse)):
			_shake_desk(_aim(drag_mouse))


## Shook the mouse while looking at the bench: everything on it is laid out neatly.
func _shake_desk(at: Vector2) -> bool:
	var from := camera.project_ray_origin(at)
	var q := PhysicsRayQueryParameters3D.create(from, from + camera.project_ray_normal(at) * 4.0, L_WORLD | L_LOOSE | L_PICK)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return false
	var p: Vector3 = hit["position"]
	if p.x < TRAY_RIGHT or p.x > 1.65 or absf(p.z) > 0.95 or p.y < TABLE_Y - 0.03 or p.y > TABLE_Y + 0.3:
		return false
	_tidy_desk()
	return true


## Lay the bench out: each sentence (pieces joined by cables) on a row of its own,
## in a sensible order: subject, then whatever else hangs off the verb, the object,
## and the verb last; an adjective right after the noun it's plugged into. Pieces
## not connected to anything go in rows of their own at the front: words, then endings.
func _tidy_desk() -> void:
	var on := []
	var seen := []
	for t: Tile in loose.duplicate(): # words lying loose on the bench top: picked up off it
		if not is_instance_valid(t) or not t.loose_body or t.loose_body in seen:
			continue
		var rp := t.loose_body.global_position
		if rp.y > TABLE_Y - 0.01 and rp.y < TABLE_Y + 0.25 and rp.x > TRAY_RIGHT and absf(rp.x) < 1.65 and absf(rp.z) < 0.9:
			seen.append(t.loose_body)
			on.append(_take_loose(t))
	for c: Chunk in chunks:
		var cp := c.global_position
		if c != dragging and not owned_by.has(c) and not c in on and not c.tiles.is_empty() \
				and cp.x > TRAY_RIGHT - 0.05 and absf(cp.x) < 1.7 and absf(cp.z) < 0.95 and cp.y < TABLE_Y + 0.4:
			on.append(c)
	if on.is_empty():
		return
	# what each piece is doing: [role rank, the piece it belongs next to (adjectives)]
	var role := func(c: Chunk) -> Array:
		var r := 2.0
		var near: Chunk = null
		for t: Tile in c.tiles:
			if t.kind == "stem" and Latin.STEMS.has(t.key):
				var pos: String = Latin.STEMS[t.key]["pos"]
				if pos == "verb":
					r = maxf(r, 6.0)
				elif pos in ["prep", "adv"]:
					r = 4.0
			if t.kind == "adapter":
				r = 4.5
			for cd in t.cords_out:
				if not is_instance_valid(cd) or not is_instance_valid(cd.socket_tile):
					continue
				match cd.kind:
					"nom":
						r = 0.0 if not (cd.socket_tile.kind == "adapter") else 3.0
					"acc":
						r = 3.0
					"aux", "agree":
						if cd.socket_tile.get_parent() is Chunk:
							near = cd.socket_tile.get_parent()
		return [r, near]
	var groups := []
	var done := []
	for c: Chunk in on:
		if c in done:
			continue
		var g: Array = _mass(c).filter(func(x): return x in on)
		for x in g:
			done.append(x)
		groups.append(g)
	var rows := [] # [[chunk...], ...]
	var singles := []
	for g: Array in groups:
		if g.size() == 1:
			singles.append(g[0])
			continue
		var info := {}
		for c: Chunk in g:
			info[c] = role.call(c)
		var heads := g.filter(func(c): return info[c][1] == null or not info[c][1] in g)
		heads.sort_custom(func(a, b): return info[a][0] < info[b][0] or (info[a][0] == info[b][0] and a.position.x < b.position.x))
		var row := []
		for h: Chunk in heads:
			row.append(h)
			for c: Chunk in g: # its adjectives straight after it
				if info[c][1] == h and not c in row:
					row.append(c)
		for c: Chunk in g:
			if not c in row:
				row.append(c)
		rows.append(row)
	rows.sort_custom(func(a, b): return a.size() > b.size())
	var kind_rank := func(c: Chunk) -> String:
		var t: Tile = c.tiles[0]
		return ("0" if t.kind == "stem" else ("1" if t.kind == "ending" else "2")) + t.cat + t.key
	singles.sort_custom(func(a, b): return kind_rank.call(a) < kind_rank.call(b))
	if not singles.is_empty():
		rows.append(singles)
	# lay the rows out, from just in front of the monitor toward you (wrapping long ones)
	const X0 := -0.62
	const X1 := 1.5
	const GAP := 0.07
	var zs := [-0.22, 0.0, 0.22, 0.44, 0.66, 0.86, -0.46, -0.7]
	var zi := 0
	var x := X0
	var plan := []
	for row: Array in rows:
		if x > X0:
			zi += 1
			x = X0
		for c: Chunk in row:
			var x_end: float = X1 if zs[mini(zi, zs.size() - 1)] > -0.3 else -0.12 # (the monitor's behind)
			if x > X0 and x + c.width > x_end:
				zi += 1
				x = X0
			plan.append([c, Vector3(x, TABLE_Y, zs[mini(zi, zs.size() - 1)])])
			x += c.width + GAP
	var k := 0
	for pl in plan:
		var c: Chunk = pl[0]
		var tw := c.create_tween().set_parallel(true)
		tw.tween_property(c, "position", pl[1], 0.35).set_delay(0.02 * k).set_trans(Tween.TRANS_SINE)
		tw.tween_property(c, "quaternion", Quaternion.IDENTITY, 0.35).set_delay(0.02 * k).set_trans(Tween.TRANS_SINE)
		k += 1
	Sfx.play(self, "rattle", Vector3(0.4, TABLE_Y + 0.1, 0.2), -6.0)


## Shook the mouse while looking into an open drawer: tidy it.
func _shake_drawer(at: Vector2) -> bool:
	var from := camera.project_ray_origin(at)
	var q := PhysicsRayQueryParameters3D.create(from, from + camera.project_ray_normal(at) * 4.0, L_WORLD | L_LOOSE | L_PICK)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return false
	for i in drawers.size():
		var d: Dictionary = drawers[i]
		if not d["open"]:
			continue
		var lp: Vector3 = d["node"].global_transform.affine_inverse() * hit["position"]
		if absf(lp.x) < d["iw"] * 0.5 + 0.05 and absf(lp.z) < d["dd"] * 0.5 + 0.05 and lp.y > -0.05 and lp.y < 0.3:
			_organize(i)
			return true
	return false


## Every piece in the drawer lifts and settles upright, side by side, parallel,
## in the drawer's own order (ō, -s, -t, -mus, -tis, -nt...).
func _organize(i: int) -> void:
	var d: Dictionary = drawers[i]
	var dn: Node3D = d["node"]
	var inv := dn.global_transform.affine_inverse()
	var iw: float = d["iw"]
	var dd: float = d["dd"]
	var items := []
	for t: Tile in loose:
		if not is_instance_valid(t) or not t.loose_body:
			continue
		var rb := t.loose_body
		if items.any(func(x): return x[0] == rb):
			continue
		var lp := inv * rb.global_position
		if absf(lp.x) < iw * 0.5 + 0.03 and absf(lp.z) < dd * 0.5 + 0.03 and lp.y > -0.05 and lp.y < 0.35:
			items.append([rb, rb.get_meta("chunk")])
	var order: Array = d["order"]
	var rank := func(c: Chunk) -> int:
		var t: Tile = c.tiles[0]
		for k in order.size():
			var e: String = order[k]
			if e == t.key or (e.ends_with("~") and t.is_reel() and t.reel_base == e.left(-1)):
				return k
		return order.size()
	items.sort_custom(func(a, b): return [rank.call(a[1]), a[1].tiles[0].key] < [rank.call(b[1]), b[1].tiles[0].key])
	var x := -iw * 0.5 + 0.02
	var z := -dd * 0.5 + 0.02
	var y := 0.0
	var row_d := 0.0
	var k := 0
	for it in items:
		var rb: RigidBody3D = it[0]
		var c: Chunk = it[1]
		var w := c.width
		var dep := 2.0 * Tile.R if c.tiles.any(func(t): return t.is_rod) else Tile.D
		if x + w > iw * 0.5 - 0.02 and x > -iw * 0.5 + 0.03: # next row
			x = -iw * 0.5 + 0.02
			z += row_d + 0.015
			row_d = 0.0
		if z + dep > dd * 0.5 - 0.01: # drawer's full: a second layer
			z = -dd * 0.5 + 0.02
			y += 0.08
		var to := Transform3D(dn.global_basis.orthonormalized(), dn.global_transform * Vector3(x + w * 0.5, 0.005 + Tile.H * 0.5 + 0.003 + y, z + dep * 0.5))
		x += w + 0.012
		row_d = maxf(row_d, dep)
		rb.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		rb.freeze = true
		var from := rb.global_transform
		var tw := rb.create_tween()
		tw.tween_interval(0.02 * k)
		tw.tween_method(func(f: float) -> void:
			if is_instance_valid(rb):
				rb.global_transform = from.interpolate_with(to, f) * Transform3D(Basis.IDENTITY, Vector3(0, sin(f * PI) * 0.04, 0)), 0.0, 1.0, 0.35).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func() -> void:
			if is_instance_valid(rb):
				rb.global_transform = to
				rb.freeze = false
				rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
				rb.linear_velocity = Vector3.ZERO
				rb.angular_velocity = Vector3.ZERO
				rb.sleeping = true)
		k += 1
	Sfx.play(self, "rattle", dn.global_position)


## Held the button down on an empty bit of the bench and dragged all the way
## across it, left to right: everything on the bench is swept off into the bin.
func _update_sweep() -> void:
	if not sweep_on:
		return
	var p := _plane_point(_aim(drag_mouse), TABLE_Y)
	if sweep_x0 < -0.6 and p.x > 1.2 and absf(p.z) < 0.95:
		sweep_on = false
		_sweep_desk()


func _sweep_desk() -> void:
	var items := []
	for c: Chunk in chunks.duplicate():
		var cp := c.global_position
		if c != dragging and absf(cp.x) < 1.7 and absf(cp.z) < 0.95 and cp.y < TABLE_Y + 0.4 and cp.x > TRAY_RIGHT - 0.05:
			items.append(c)
	var seen := []
	for t: Tile in loose.duplicate(): # loose words lying on the bench top (not in the tray or a drawer)
		if not is_instance_valid(t) or not t.loose_body or t.loose_body in seen:
			continue
		var rp := t.loose_body.global_position
		if rp.y > TABLE_Y - 0.01 and rp.y < TABLE_Y + 0.25 and rp.x > TRAY_RIGHT and absf(rp.x) < 1.65 and absf(rp.z) < 0.9:
			seen.append(t.loose_body)
			items.append(_take_loose(t))
	items.sort_custom(func(a, b): return a.position.x > b.position.x) # the ones nearest the bin go first
	var k := 0
	for c: Chunk in items:
		owned_by.erase(c)
		_remove_chunk(c)
		var tw := c.create_tween()
		tw.tween_interval(0.03 * k)
		tw.tween_property(c, "position:x", 1.66, 0.12 + (1.66 - c.position.x) * 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(_trash.bind(c))
		k += 1
	if not items.is_empty():
		Sfx.play(self, "whoosh", Vector3(0.6, TABLE_Y + 0.2, 0.3))


## Where the player is aiming: the crosshair (or the mouse, when it's free).
func _aim(pos: Vector2) -> Vector2:
	return _center() if _captured() else pos


## Click / E: pick up what's under the crosshair, or put down what you hold.
## (Right-click picks up the whole word; Shift is crouch.)
func _use(whole: bool, pos := Vector2(-1, -1)) -> void:
	if dragging or held_cord:
		_release()
	else:
		_press(_aim(pos) if pos.x >= 0.0 else _center(), whole)


func _release() -> void:
	if held_cord:
		_drop_plug()
	elif dragging:
		_drop()


func _press(pos: Vector2, whole: bool) -> void:
	_inspect_end()
	var hit := _ray(pos)
	if hit.is_empty():
		return
	var col: Object = hit["collider"]
	if col.has_meta("note"):
		var nm: Array = col.get_meta("note")
		_open_note(nm[0], nm[1])
		return
	if col.has_meta("drawer") and drawers[col.get_meta("drawer")].get("locked", false): # not unlocked yet
		_toast("That drawer isn't unlocked yet.")
		Sfx.play(self, "click", hit["position"], -10.0, 0.6)
		return
	if col.has_meta("drawer"):
		_toggle_drawer(col.get_meta("drawer"))
		_hover(pos)
		return
	if col.has_meta("tab"):
		_set_tab(col.get_meta("tab"))
		return
	if col.has_meta("challenge"):
		_start_challenge()
		return
	if col.has_meta("screen"):
		if screen_tab == "search":
			_screen_click(hit["position"])
		return
	if col.has_meta("plug"):
		_grab_plug(col.get_meta("plug"), pos)
		return
	if not col.has_meta("tile"):
		return
	_press_tile(col.get_meta("tile"), pos, whole)


func _grab_plug(cd: Cord, pos: Vector2) -> void:
	held_cord = cd
	if held_cord.socket_tile: # grabbed while plugged in: it has to be slid back out
		_touch(held_cord.socket_tile)
		var S0 := Cord.socket_xf(held_cord.socket_tile, held_cord.socket_i)
		held_cord.free_xf = S0
		if absf(S0.basis.x.y) > 0.7: # a hole in the top of a piece (adjectives): it comes straight up out of it
			held_cord.free_xf = S0 * Transform3D(Basis.IDENTITY, Vector3(held_cord.plen() + 0.02, 0, 0))
		# (and it won't be drawn straight back in until it has been taken away from it)
		held_cord.set_meta("leaving", [held_cord.socket_tile, held_cord.socket_i])
	held_cord.socket_tile = null
	held_cord.held = true
	plug_mouse = pos
	_set_hover(null)
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)


func _press_tile(t: Tile, pos: Vector2, whole: bool) -> void:
	var d: Chunk
	if t.in_tray: # lying loose (tray, drawer, floor...): the whole word comes up
		d = _take_loose(t)
		_refresh(d)
	else:
		if t.soldered: # delivered whole: the ending can't come off
			whole = true
		if t.kind == "ending" and _holding(t) != null: # a genitive holding a word: the whole word comes,
			whole = true # and the word in its holder comes along with it
		if owned_by.has(t.get_parent()) and (whole or t.kind == "stem"): # taken out of a genitive's holder
			t.get_parent().set_meta("left_gen", owned_by[t.get_parent()]) # won't snap straight back in
			owned_by.erase(t.get_parent())
		d = _extract(t, whole)
	_begin_drag(d, pos)


func _begin_drag(d: Chunk, pos: Vector2) -> void:
	dragging = d
	drag_mouse = pos
	# like picking something up in Portal: it comes to a set spot in front of you,
	# held by its middle
	grab_local = Vector3(d.width * 0.5, Tile.H * 0.5, 0)
	hold_dist = HOLD_DIST
	held_yaw = 0.0
	held_tilt = 0.0
	_set_hover(null)
	for l in d.tags:
		l.visible = false
	# a solid stand-in that physically shoves loose pieces out of the way
	pusher = AnimatableBody3D.new()
	pusher.collision_layer = L_WORLD
	pusher.collision_mask = 0
	for t: Tile in d.tiles:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = t.box_half() * 2.0
		cs.shape = sh
		cs.position = t.target_pos + t.shape_offset()
		pusher.add_child(cs)
	d.add_child(pusher)
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)


func _drag_to(pos: Vector2) -> void:
	drag_mouse = pos
	_drag_step(1.0 / 60.0)


## Move the held piece toward the spot in front of you: it flies there smoothly,
## turns flat, shoves other pieces aside, and won't pass through anything solid.
## Near a stem's end an ending is drawn onto it; near a genitive's holder a noun
## word is drawn into it.
func _drag_step(delta: float) -> void:
	var d := dragging
	if d == null:
		return
	# held in the air in front of you, along your line of sight
	var p := camera.project_ray_origin(drag_mouse) + camera.project_ray_normal(drag_mouse) * hold_dist
	var want := p - d.quaternion * grab_local
	# (inside the room: the walls themselves stop it, this just keeps it from flying off)
	want = Vector3(clampf(want.x, SIDE_X + 0.05, RIGHT_X - 0.05 - d.width), clampf(want.y, 0.02, ROOF_Y - 0.3), clampf(want.z, WALL_Z + 0.02, FRONT_Z - 0.1))
	_light_gen(_gen_target(d))
	if d.has_meta("left_gen"): # re-armed once it's been pulled clear of the holder it came out of
		var lg = d.get_meta("left_gen")
		var vv := Vector3(d.width * 0.5, Tile.H * 0.5, 0)
		if not is_instance_valid(lg) or not lg.get_parent() is Chunk or (d.position + d.quaternion * vv).distance_to(_owned_xf(lg, d) * vv) > GEN_LOCK + 0.15:
			d.remove_meta("left_gen")
	if gen_lit: # brought close to a lit holder: drawn in, and locked once it's there
		var v := Vector3(d.width * 0.5, Tile.H * 0.5, 0)
		var seat_c := _owned_xf(gen_lit, d) * v
		var dist := (d.position + d.quaternion * v).distance_to(seat_c)
		if d.has_meta("left_gen") and d.get_meta("left_gen") == gen_lit:
			dist = INF # just came out of it (it can still be clicked back in)
		if dist < GEN_LOCK:
			_own_animated(d, gen_lit)
			return
		var k := 1.0 - smoothstep(GEN_LOCK, GEN_LOCK + 0.14, minf(dist, 9.0))
		want = want.lerp(seat_c - d.quaternion * v, k * 0.6)
	var f := _feed(d, want, delta)
	d.quaternion = f["quat"]
	if f["skip"] != null: # being fed onto a stem: the stem's guide moves it
		d.position = f["pos"]
	else:
		var to: Vector3 = d.position.lerp(f["pos"], minf(1.0, delta * 20.0))
		if to.y < TABLE_Y + 0.09: # carried low: knock bench pieces out of the way
			var keep := d.position
			d.position = to
			_shove(d, null)
			d.position = keep
		d.position = _cast_move(d, to)
		_lift_clear(d)
	if f["seat"] != null:
		_seat(d, f["seat"])
	elif d.tiles.size() == 1 and Chunk.is_cap(d.tiles[0]): # an adjective cap brought up to an ending's end: it snaps on
		var tg := _cap_target_near(d, 0.075)
		if tg:
			_cap_attach(d, tg)


## Turning to face you can swing a corner of a held piece down into whatever is
## under it: lift it back up so its lowest corner rests on that surface.
func _lift_clear(d: Chunk) -> void:
	var low := INF
	for t: Tile in d.tiles:
		var hx := t.box_half()
		for cx in [-1, 1]:
			for cy in [-1, 1]:
				for cz in [-1, 1]:
					low = minf(low, (t.global_transform * (t.shape_offset() + Vector3(cx * hx.x, cy * hx.y, cz * hx.z))).y)
	var c := d.transform * Vector3(d.width * 0.5, Tile.H * 0.5, 0)
	var q := PhysicsRayQueryParameters3D.create(c + Vector3.UP * 0.3, c + Vector3.DOWN * 3.0, L_PICK | L_WORLD)
	var excl: Array[RID] = click_only.duplicate()
	if is_instance_valid(pusher):
		excl.append(pusher.get_rid())
	for ch: Chunk in [d] + _owned_tree(d):
		for t: Tile in ch.tiles:
			if t.body:
				excl.append(t.body.get_rid())
	q.exclude = excl
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var floor_y: float = hit["position"].y if not hit.is_empty() else 0.0
	if low < floor_y:
		d.position.y += floor_y - low


## Move a held piece toward `target` without passing through anything solid:
## its shape is swept through the world (sideways, then up/down; lifting goes
## first), and it stops at whatever it meets.
func _cast_move(d: Chunk, target: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var excl: Array[RID] = click_only.duplicate()
	if is_instance_valid(pusher):
		excl.append(pusher.get_rid())
	var shapes := []
	for oc: Chunk in _owned_tree(d): # words it carries in its genitive holders
		for t: Tile in oc.tiles:
			if t.body:
				excl.append(t.body.get_rid())
	for t: Tile in d.tiles:
		if t.body:
			excl.append(t.body.get_rid())
		var bs := BoxShape3D.new()
		bs.size = t.box_half() * 2.0 - Vector3.ONE * 0.006
		shapes.append([bs, t.transform * Transform3D(Basis.IDENTITY, t.shape_offset())])
	var b := d.quaternion
	var q := PhysicsShapeQueryParameters3D.new()
	q.collision_mask = L_PICK | L_WORLD
	# anything it already overlaps (e.g. picked out of a pile) can't trap it
	for sh in shapes:
		q.shape = sh[0]
		q.transform = Transform3D(Basis(b), d.position) * sh[1]
		q.exclude = excl
		for r in space.intersect_shape(q, 8):
			excl.append(r["rid"])
	q.exclude = excl
	var pos := d.position
	var axes := [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)]
	if target.y > pos.y:
		axes = [Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)]
	for ax: Vector3 in axes:
		var mv := (target - pos) * ax
		if mv.length() < 0.00001:
			continue
		var frac := 1.0
		for sh in shapes:
			q.shape = sh[0]
			q.transform = Transform3D(Basis(b), pos) * sh[1]
			q.motion = mv
			var r := space.cast_motion(q)
			frac = minf(frac, r[0])
		pos += mv * frac
	return pos


## Feeding an ending onto a stem works like a plug: near the end of a stem the
## ending turns to line up with it, the stem's end guides it to the centre, and it
## only goes on if it's pushed all the way along the stem's axis. Endings that
## don't belong stop dead against the stem's end.
func _feed(d: Chunk, want: Vector3, delta: float) -> Dictionary:
	var lq := _face_q() # held up with its printed face toward you
	var res := {"pos": want, "quat": d.quaternion.slerp(lq, minf(1.0, delta * 12.0)).normalized(), "skip": null, "seat": null}
	if d.tiles.size() != 1 or d.tiles[0].kind != "ending":
		return res
	var e: Tile = d.tiles[0]
	var best: Chunk = null
	var bd := 0.35
	var best_want := want
	for c: Chunk in chunks:
		if c == d or c.tiles.is_empty() or c.tiles.back().kind != "stem" or c.tiles.back().soldered:
			continue
		var st: Tile = c.tiles.back()
		var tip := st.global_transform * Vector3(st.width * 0.5, 0, 0)
		# where you're aiming, at the height of that stem: that's where it's drawn to
		var aim := _plane_point(drag_mouse, st.global_position.y)
		var wc := aim - c.quaternion * grab_local
		var dd := Vector2(tip.x - wc.x, tip.z - wc.z).length()
		if dd < bd:
			bd = dd
			best = c
			best_want = wc
	if best == null:
		return res
	var stem: Tile = best.tiles.back()
	var w := 1.0 - smoothstep(0.1, 0.3, bd)
	want = want.lerp(best_want, w) # pulled down out of the air onto the stem's end
	res["pos"] = want
	var S := Transform3D(stem.global_basis.orthonormalized(), stem.global_position)
	var Si := S.affine_inverse()
	var seat := Chunk.seat(stem, e)
	var sx: float = seat["x"]
	var contact: float = seat["contact"]
	var vr := Chunk.validate(best.tiles + [e])
	var ok: bool = vr["ok"] or vr.get("neuter_bad", false) # a wrong ending on a neuter goes on... and sparks off
	# (each piece's own "up": a word standing in a genitive holder is on its side)
	var cur := Si * (d.position + d.quaternion * Vector3(0, Tile.H * 0.5, 0))
	var l := Si * (want + best.quaternion * Vector3(0, Tile.H * 0.5, 0))
	if d.has_meta("unseated_from") and d.get_meta("unseated_from") == best and cur.x >= contact - 0.001:
		d.remove_meta("unseated_from") # it has been pulled clear: it may go back on
	# (only the word it was just pulled off is blocked until it's clear of it)
	var armed: bool = not d.has_meta("unseated_from") or d.get_meta("unseated_from") != best
	var aligned := (d.quaternion * Vector3.RIGHT).dot(S.basis.x) > 0.9975
	if cur.x < contact - 0.001 and absf(cur.z) < 0.006 and absf(cur.y) < 0.01: # on the stem: slides along it only
		var lx := maxf(l.x, sx)
		res["pos"] = S * Vector3(lx, -Tile.H * 0.5, 0)
		res["quat"] = best.quaternion
		res["skip"] = best
		if armed and lx <= sx + 0.002:
			res["seat"] = best
		return res
	res["quat"] = d.quaternion.slerp(lq.slerp(best.quaternion, w), minf(1.0, delta * 14.0)).normalized()
	if w > 0.6 and l.x < contact + 0.06 and absf(l.z) < 0.06:
		res["skip"] = best # the stem's mouth guides it in
		var k := clampf((l.x - contact) / 0.06, 0.0, 1.0)
		l.z *= k
		var square := aligned and absf(cur.z) < 0.004
		if l.x < contact and not (ok and square):
			l.x = contact # wrong ending (or not lined up yet): it butts against the stem's end
		l.x = maxf(l.x, sx)
		res["pos"] = S * Vector3(l.x, -Tile.H * 0.5, l.z)
	return res


# ---------------------------------------------------------------- genitive holders

## A noun word that can stand in a genitive holder: a noun stem, with or without
## its ending (an ending can be put on, or swapped, while it stands there).
func _is_noun_word(d: Chunk) -> bool:
	if d.tiles.is_empty() or d.tiles.size() > 2:
		return false
	var st: Tile = d.tiles[0]
	if st.kind != "stem" or Latin.STEMS[st.key]["pos"] != "noun":
		return false
	if d.tiles.size() == 1:
		return true
	var e: Tile = d.tiles[1]
	return e.kind == "ending" and Latin.combine(st.key, e.cat, e.key)["ok"]


## A genitive ending's holder only works once the ending is on its stem.
func _gen_ready(t: Tile) -> bool:
	if not is_instance_valid(t) or not t.gen_holder or t.in_tray or not t.get_parent() is Chunk:
		return false
	var c: Chunk = t.get_parent()
	var i := c.tiles.find(t)
	return i >= 1 and c.tiles[i - 1].kind == "stem" and Latin.combine(c.tiles[i - 1].key, t.cat, t.key)["ok"]


## The word standing in this genitive's holder, if any.
func _holding(t: Tile) -> Chunk:
	for oc in owned_by:
		if owned_by[oc] == t:
			return oc
	return null


## Every word held (directly or down a chain of genitives) by this row.
func _owned_tree(c: Chunk) -> Array:
	var out := []
	var frontier := [c]
	while not frontier.is_empty():
		var cur: Chunk = frontier.pop_back()
		for oc in owned_by:
			if is_instance_valid(oc) and is_instance_valid(owned_by[oc]) and owned_by[oc].get_parent() == cur and not oc in out and oc != c:
				out.append(oc)
				frontier.append(oc)
	return out


## Where a word sits when it stands in this genitive's holder: on its side,
## printed face toward the genitive (and you), centred on the ending.
func _owned_xf(gt: Tile, d: Chunk) -> Transform3D:
	var o := Vector3(-d.width * 0.5, -Tile.H * 0.5 + Tile.GEN_BASE + Tile.D * 0.5, Tile.GEN_Z - Tile.H * 0.5)
	var g := Transform3D(gt.global_basis.orthonormalized(), gt.global_position)
	return g * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), o)


## Carrying a noun word: the free genitive holder you're aiming at (or near), if any.
func _gen_target(d: Chunk) -> Tile:
	if not _is_noun_word(d):
		return null
	var best: Tile = null
	var bd := 0.14
	var mine := [d] + _owned_tree(d)
	for c: Chunk in chunks:
		if c in mine:
			continue
		for t: Tile in c.tiles:
			if not _gen_ready(t) or _holding(t) != null or not t.gen_open():
				continue
			# where the crosshair meets the bench around that ending
			var sp := t.global_transform * t.gen_slot()
			var aim := _plane_point(drag_mouse, sp.y)
			var dd := Vector2(aim.x - sp.x, aim.z - sp.z).length()
			var gc := t.global_position # aiming at the genitive word's ending itself counts too
			var aim2 := _plane_point(drag_mouse, gc.y)
			dd = minf(dd, Vector2(aim2.x - gc.x, aim2.z - gc.z).length() + 0.04)
			if dd < bd:
				bd = dd
				best = t
	return best


func _light_gen(t: Tile) -> void:
	if t == gen_lit:
		return
	if is_instance_valid(gen_lit):
		gen_lit.set_gen_highlight(false)
	gen_lit = t
	if t:
		t.set_gen_highlight(true)


## Let go over a lit holder: the word swings up onto its side and drops into it.
func _own_animated(d: Chunk, gt: Tile) -> void:
	_end_drag()
	Sfx.play(self, "lock", gt.global_position)
	owned_by[d] = gt # rides along from now on; it just glides into place first
	if d.has_meta("left_gen"):
		d.remove_meta("left_gen")
	d.set_meta("settling", 0.0)
	_touch(gt)
	_refresh(d)


## All the way into the holder: the word now belongs to the genitive.
func _own(d: Chunk, gt: Tile) -> void:
	_end_drag()
	owned_by[d] = gt
	d.global_transform = _owned_xf(gt, d)
	_touch(gt)
	if gt.get_parent() is Chunk:
		gt.get_parent().bounce(1.04)
	_refresh(d)


## Held words ride along in their holders; if a holder is gone (ending pulled
## off, reel turned, word dropped in the tray...) its word falls out.
func _follow_gens() -> void:
	for pass_i in 3:
		for oc in owned_by.keys():
			var gt: Tile = owned_by[oc]
			if not is_instance_valid(oc) or not oc in chunks or oc == dragging:
				owned_by.erase(oc)
				continue
			if not _gen_ready(gt) or not gt.get_parent() in chunks:
				_release_owned(oc)
				continue
			var to := _owned_xf(gt, oc)
			if oc.has_meta("settling"): # gliding into the holder
				var k: float = minf(1.0, oc.get_meta("settling") + get_process_delta_time() / 0.25 / 3.0)
				oc.set_meta("settling", k)
				var cur := Transform3D(oc.global_basis.orthonormalized(), oc.global_position)
				to = cur.interpolate_with(to, smoothstep(0.0, 1.0, k) if k < 1.0 else 1.0)
				if k >= 1.0:
					oc.remove_meta("settling")
					if gt.get_parent() is Chunk:
						gt.get_parent().bounce(1.04)
			oc.global_transform = to


func _release_owned(oc: Chunk) -> void:
	owned_by.erase(oc)
	if is_instance_valid(oc) and oc in chunks:
		_put_down(oc)


## Fully pushed on: the ending becomes part of the word, with a little bounce.
func _seat(d: Chunk, c: Chunk) -> void:
	var vr := Chunk.validate(c.tiles + d.tiles)
	if not vr["ok"] and vr.get("neuter_bad", false):
		_neuter_reject(d, c)
		return
	_end_drag()
	_try_insert(d, {"chunk": c, "slot": {"index": c.tiles.size(), "replace": -1}})


## A masculine / feminine ending pushed onto a neuter: sparks, a puff of smoke,
## and the ending is thrown off.
func _neuter_reject(d: Chunk, c: Chunk) -> void:
	if dragging == d:
		_end_drag()
	var st: Tile = c.tiles.back()
	var b := st.global_basis.orthonormalized()
	var joint := st.global_transform * Vector3(st.width * 0.5, 0, 0)
	_sparks(joint)
	Sfx.play(self, "spark", joint, 2.0)
	if d in chunks or d.get_parent() == self:
		_make_loose_chunk(d)
	var rb: RigidBody3D = d.get_parent()
	rb.linear_velocity = b.x * 1.6 + Vector3.UP * 1.8 + b.z * randf_range(-0.3, 0.3)
	rb.angular_velocity = Vector3(randf_range(-9, 9), randf_range(-9, 9), randf_range(-9, 9))
	c.bounce(1.06)


func _sparks(at: Vector3) -> void:
	for kind in ["spark", "smoke"]:
		var p := CPUParticles3D.new()
		p.one_shot = true
		p.explosiveness = 0.9 if kind == "spark" else 0.4
		p.amount = 36 if kind == "spark" else 14
		p.lifetime = 0.45 if kind == "spark" else 1.6
		p.direction = Vector3.UP
		p.spread = 75.0 if kind == "spark" else 25.0
		p.initial_velocity_min = 1.0 if kind == "spark" else 0.08
		p.initial_velocity_max = 2.4 if kind == "spark" else 0.25
		p.gravity = Vector3(0, -9.8, 0) if kind == "spark" else Vector3(0, 0.35, 0)
		var m: Mesh
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		if kind == "spark":
			var bm := BoxMesh.new()
			bm.size = Vector3.ONE * 0.006
			m = bm
			p.color = Color("#ffd23f")
		else:
			var qm := QuadMesh.new()
			qm.size = Vector2(0.05, 0.05)
			m = qm
			mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var g := Gradient.new()
			g.set_color(0, Color(0.6, 0.6, 0.62, 0.8))
			g.set_color(1, Color(0.5, 0.5, 0.52, 0.0))
			p.color_ramp = g
			var sc := Curve.new()
			sc.max_value = 3.0
			sc.add_point(Vector2(0, 0.6))
			sc.add_point(Vector2(1, 2.4))
			p.scale_amount_curve = sc
		p.mesh = m
		p.material_override = mat
		add_child(p)
		p.global_position = at
		p.emitting = true
		get_tree().create_timer(2.5).timeout.connect(p.queue_free)


func _end_drag() -> void:
	if is_instance_valid(pusher):
		pusher.queue_free()
	pusher = null
	dragging = null
	_light_gen(null)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


## Pieces on the bench are solid: whatever the held piece runs into gets knocked
## aside (and can knock the next one along).
func _shove(d: Chunk, skip) -> void:
	var movers := [d]
	for round_i in 3:
		var next := []
		for m: Chunk in movers:
			for c: Chunk in chunks:
				if c == d or c == m or c == skip or c in movers or owned_by.has(c):
					continue
				var mtv := _overlap(m, c)
				if mtv != Vector3.ZERO:
					c.position += mtv * 1.02
					c.position.x = clampf(c.position.x, TRAY_RIGHT + 0.02, 1.65 - c.width)
					c.position.z = clampf(c.position.z, -0.85, 0.85)
					if not c in next:
						next.append(c)
		if next.is_empty():
			break
		movers = next


func _footprint(c: Chunk) -> Array:
	var u := c.basis.x
	u.y = 0.0
	u = u.normalized()
	var deep := Tile.R
	for t: Tile in c.tiles:
		if t.is_block:
			deep = Tile.D * 0.5
	return [c.transform * Vector3(c.width * 0.5, 0, 0), u, Vector3(-u.z, 0, u.x), c.width * 0.5, deep]


## How far b must move (on the bench) to stop overlapping a: separating axes.
func _overlap(a: Chunk, b: Chunk) -> Vector3:
	var A := _footprint(a)
	var B := _footprint(b)
	var dc: Vector3 = B[0] - A[0]
	dc.y = 0.0
	var best := INF
	var best_n := Vector3.ZERO
	for n: Vector3 in [A[1], A[2], B[1], B[2]]:
		var ra: float = A[3] * absf(A[1].dot(n)) + A[4] * absf(A[2].dot(n))
		var rb: float = B[3] * absf(B[1].dot(n)) + B[4] * absf(B[2].dot(n))
		var dist := dc.dot(n)
		var o := ra + rb - absf(dist)
		if o <= 0.0:
			return Vector3.ZERO
		if o < best:
			best = o
			best_n = n * (1.0 if dist >= 0.0 else -1.0)
	return best_n * best


func _clear_snap_lit() -> void:
	for t in snap_lit:
		if is_instance_valid(t):
			t.set_highlight(false)
	snap_lit.clear()


func _drop() -> void:
	var d := dragging
	if d == null:
		return
	var gt := gen_lit
	if d.tiles.size() == 1 and d.tiles[0].kind == "ending" and _click_onto_stem(d): # clicked an ending onto a stem
		return
	if d.tiles.size() == 1 and Chunk.is_cap(d.tiles[0]) and _cap_onto(d): # an adjective cap put on
		return
	_end_drag()
	_clear_snap_lit()
	if d.has_meta("left_gen"):
		d.remove_meta("left_gen")
	if gt and _gen_ready(gt) and _holding(gt) == null and _is_noun_word(d):
		_own_animated(d, gt)
		return
	# set down on whatever surface you're looking at (if it's one it can lie on)
	var spot := _aim_surface(d)
	if not spot.is_empty():
		var lq := _level_q(d.quaternion)
		var to: Vector3 = spot["pos"] - lq * Vector3(d.width * 0.5, 0, 0) + Vector3.UP * 0.002
		var from_q := d.quaternion
		var from_p := d.position
		var glide := func(k: float) -> void:
			if is_instance_valid(d) and dragging != d:
				d.quaternion = from_q.slerp(lq, k)
				d.position = from_p.lerp(to, k)
		var tw := d.create_tween()
		tw.tween_method(glide, 0.0, 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			if is_instance_valid(d) and dragging != d and d in chunks:
				_put_down(d))
		return
	_put_down(d)


## Holding an ending and clicking on a stem (on the bench, or lying loose in the
## tray or a drawer): the ending goes on it. A loose word stays where it was.
func _click_onto_stem(d: Chunk) -> bool:
	var from := camera.project_ray_origin(drag_mouse)
	var q := PhysicsRayQueryParameters3D.create(from, from + camera.project_ray_normal(drag_mouse) * 4.0, L_PICK | L_LOOSE | L_BLOCK)
	var excl: Array[RID] = click_only.duplicate()
	if is_instance_valid(pusher):
		excl.append(pusher.get_rid())
	for t: Tile in d.tiles:
		if t.body:
			excl.append(t.body.get_rid())
	q.exclude = excl
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or not hit["collider"].has_meta("tile"):
		return false
	var t: Tile = hit["collider"].get_meta("tile")
	var was_loose := t.in_tray and t.loose_body != null
	var c: Chunk = t.loose_body.get_meta("chunk") if was_loose else t.get_parent()
	if not c is Chunk or c.tiles.is_empty() or c.tiles.back().kind != "stem" or c.tiles.back().soldered or c == d:
		return false
	var vr := Chunk.validate(c.tiles + d.tiles)
	if not vr["ok"] and not vr.get("neuter_bad", false):
		_toast(vr.get("msg", "That ending doesn't fit there."))
		return false
	if was_loose:
		_take_loose(c.tiles[0])
	_seat(d, c)
	if was_loose and is_instance_valid(c) and c in chunks:
		_make_loose_chunk(c)
	return true


## Where the crosshair meets a surface a piece could be set down on (facing up,
## within reach), ignoring the held piece itself. {} if there isn't one.
func _aim_surface(d: Chunk) -> Dictionary:
	var from := camera.project_ray_origin(drag_mouse)
	var dir := camera.project_ray_normal(drag_mouse)
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 6.0, L_PICK | L_WORLD)
	var excl: Array[RID] = click_only.duplicate()
	if is_instance_valid(pusher):
		excl.append(pusher.get_rid())
	for ch: Chunk in [d] + _owned_tree(d):
		for t: Tile in ch.tiles:
			if t.body:
				excl.append(t.body.get_rid())
	q.exclude = excl
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	# aiming at (or into) the bin: in it goes
	var t := (TRASH_H - from.y) / dir.y if absf(dir.y) > 0.0001 else -1.0
	if t > 0.0 and t < 6.0:
		var at := from + dir * t
		if Vector2(at.x - TRASH_POS.x, at.z - TRASH_POS.z).length() < TRASH_R + 0.05:
			return {"pos": Vector3(TRASH_POS.x, TRASH_H + 0.05, TRASH_POS.z)}
	if not hit.is_empty() and hit["collider"].get_meta("kind", "") == "bin":
		return {"pos": Vector3(TRASH_POS.x, TRASH_H + 0.05, TRASH_POS.z)}
	if hit.is_empty() or hit["normal"].y < 0.6:
		return {}
	return {"pos": hit["position"]}


func _hover(pos: Vector2) -> void:
	var hit := _ray(pos)
	var t: Tile = null
	var clickable := false
	if not hit.is_empty():
		var col: Object = hit["collider"]
		if col.has_meta("tile"):
			t = col.get_meta("tile")
			clickable = true
		elif col.has_meta("drawer") or col.has_meta("plug") or col.has_meta("tab") or (col.has_meta("screen") and screen_tab == "search") or col.has_meta("note"):
			clickable = true
	_set_hover(t)
	if crosshair:
		crosshair.modulate = Color("#ffd23f") if clickable else Color.WHITE
	if not _captured():
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if clickable else Input.CURSOR_ARROW)


## Scroll over a piece to turn it and look at its ends (holes, plugs, sockets).
## On the table the whole connected group turns: the row it's in plus every
## row joined to it by cables. yaw = turn around the vertical (stays put),
## tilt = tip toward/away from you (springs back flat when you let go).
func _spin_at(pos: Vector2, yaw: float, tilt: float, wheel := false) -> void:
	if dragging or held_cord:
		return
	var hit := _ray(pos)
	var t: Tile = null
	if not hit.is_empty() and hit["collider"].has_meta("tile"):
		t = hit["collider"].get_meta("tile")
	elif not hit.is_empty() and hit["collider"].has_meta("plug"): # a plug turns with what it's in
		var cd: Cord = hit["collider"].get_meta("plug")
		t = cd.socket_tile if is_instance_valid(cd.socket_tile) else cd.owner_tile
	if t and (t.is_source or t.soldered): # (soldered endings can't be changed)
		return
	if t and t.is_reel(): # scrolling over an ending's window turns its reel instead
		var lp: Vector3 = t.global_transform.affine_inverse() * hit["position"]
		if t.collapsed() or (lp.x > t.win_x.x - 0.01 and lp.x < t.win_x.y + 0.01):
			# the drum turns smoothly with your fingers; the ending only changes
			# once you let go and it clicks onto the nearest option
			var v := tilt if absf(tilt) >= absf(yaw) else yaw
			if wheel: # one notch: on to the next option that's unlocked
				var n := t.reel_opts.size()
				for k in range(1, n + 1):
					var j := posmod(roundi(t.reel_goal) + int(signf(v)) * k, n)
					if Latin.ending_unlocked(t.cat, Latin.reel_form(t.reel_base, t.reel_opts[j])):
						t.reel_goal = roundf(t.reel_goal) + signf(v) * k
						break
			else:
				t.reel_goal += v / REEL_STEP
			t.reel_idle = 0.0
			if not t in reel_spinning:
				reel_spinning.append(t)
			return
	# pieces you aren't holding don't turn: pick one up to turn it in your hands


## Turn an ending's reel one notch: the piece becomes a different ending (its
## cable / hole change with it) and telescopes to its new length.
func _rechoose(t: Tile, step: int) -> void:
	var old_cords: Array = t.cords_out.filter(func(c): return is_instance_valid(c) and not c.dying)
	var old_sig := var_to_str(t.cord_specs)
	var old_w := t.set_choice(t.choice + step)
	if not old_cords.is_empty() and old_sig == var_to_str(t.cord_specs):
		t.cords_out = old_cords # the same cables: they just stay
		t.cord = old_cords[0]
	else:
		for oc: Cord in old_cords: # the old cables are drawn back in...
			oc.retract_and_free()
		t.cords_out = []
		t.cord = null
		if not t.cord_specs.is_empty(): # ...and the new ones slide out
			_attach_cord(t, true, 0.0)
	for cd in cords: # anything plugged into a hole that's gone (or changed) drops out
		if is_instance_valid(cd) and cd.socket_tile == t and not cd.fits(t, cd.socket_i):
			cd.free_xf = cd.plug.global_transform.orthonormalized()
			cd.socket_tile = null
			cd.parked = false
	var ch = t.get_parent()
	if ch is Chunk:
		ch.layout(true)
		_refresh(ch)
	if t.loose_body:
		_loose_shapes(t.loose_body)
		t.loose_body.sleeping = false
	# telescope: slide smoothly from the old length to the new one
	if not is_equal_approx(old_w, t.width):
		t.scale = Vector3(old_w / t.width, 1, 1)
		var tw := t.create_tween()
		tw.tween_property(t, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_touch(t)


## Reels that have been let go of click onto the nearest option, and only then
## does the ending become that option.
func _update_reels(delta: float) -> void:
	for t: Tile in reel_spinning.duplicate():
		if not is_instance_valid(t) or not t.is_reel():
			reel_spinning.erase(t)
			continue
		t.reel_idle += delta
		if t.reel_idle < 0.25:
			continue
		t.reel_goal = roundf(t.reel_goal) # let go: settle on a notch
		if absf(t.reel_pos - t.reel_goal) > 0.02:
			continue
		var n := t.reel_opts.size()
		var idx0 := posmod(roundi(t.reel_goal), n)
		if not Latin.ending_unlocked(t.cat, Latin.reel_form(t.reel_base, t.reel_opts[idx0])): # not unlocked: on to the next one that is
			var dirn := 1 if t.reel_goal >= t.choice else -1
			var found := false
			for k in range(1, n):
				var j := posmod(idx0 + dirn * k, n)
				if Latin.ending_unlocked(t.cat, Latin.reel_form(t.reel_base, t.reel_opts[j])):
					t.reel_goal += dirn * k
					found = true
					break
			if not found:
				t.reel_goal = t.choice
			continue
		reel_spinning.erase(t)
		var idx := posmod(roundi(t.reel_goal), n)
		var shift := t.reel_goal - idx
		t.reel_goal -= shift
		t.reel_pos = t.reel_goal
		if idx != t.choice:
			_rechoose(t, idx - t.choice)
			Sfx.play(self, "click", t.global_position, -6.0)
			_check_misfit(t)
		else:
			t._layout_reel()


## An ending turned (on its reel) into one its stem can't take: sparks, and off it flies.
func _check_misfit(t: Tile) -> void:
	var c = t.get_parent()
	if not c is Chunk or not c in chunks:
		return
	var i: int = c.tiles.find(t)
	if i < 1 or c.tiles[i - 1].kind != "stem":
		return
	var r := Latin.combine(c.tiles[i - 1].key, t.cat, t.key)
	if r["ok"] or not r.get("neuter_bad", false):
		return
	var d := _extract(t, false)
	_neuter_reject(d, c)


## Endings with more than one use (a cable, a socket, a genitive holder): while
## one is in use, the others are put away inside the piece.
func _update_functions() -> void:
	for c: Chunk in chunks:
		for t: Tile in c.tiles:
			var cs: Array = t.cords_out.filter(func(x): return is_instance_valid(x) and not x.dying)
			if t.kind == "ending" and c.cap_of(t) != null: # an adjective now: the cap does the work
				for x: Cord in cs:
					x.emerge_goal = 0.0
					if x.socket_tile or x.held:
						if x == held_cord:
							held_cord = null
						x.held = false
						x.free_xf = x.plug.global_transform.orthonormalized()
						x.socket_tile = null
						x.parked = false
				t.port_goal = 0.0
				t.gen_goal = 0.0
				continue
			var used := func(x: Cord) -> bool: return x.socket_tile != null or x.held or x.has_meta("seating")
			if t.kind == "stem" and Latin.STEMS[t.key]["pos"] == "prep":
				# a preposition's star plug works alongside its case plug; "in"'s
				# square (+acc.) and triangle (+abl.) plugs are either/or
				var case_cs := cs.filter(func(x): return x.kind == "acc" or x.kind == "abl")
				for x: Cord in case_cs:
					var other := false
					for y: Cord in case_cs:
						other = other or (y != x and used.call(y))
					x.emerge_goal = 0.0 if other else 1.0
				continue
			if t.kind == "stem" and t.is_rod: # a passive ending on: the verb's object cable goes in
				var i := c.tiles.find(t)
				var pas: bool = i + 1 < c.tiles.size() and c.tiles[i + 1].kind == "ending" \
						and Latin.VERB_ENDINGS.get(c.tiles[i + 1].key, {}).get("voice", "act") == "pass"
				for x: Cord in cs:
					if x.kind == "acc":
						x.emerge_goal = 0.0 if pas else 1.0
				continue
			if t.kind == "ending" and t.cat.begins_with("adj"): # an adjective's two cables work together
				for x: Cord in cs:
					x.emerge_goal = 1.0
				continue
			var multi := t.kind == "ending" and t.cat != "verb"
			var bare_neuter := t.kind == "stem" and t.port_node != null
			if not multi and not bare_neuter:
				continue
			var dat_used := t.kind == "ending" and _dat_into(t) != null
			var sock_used := (t.port_node != null and _cord_into(t, 0) != null) or dat_used
			var gen_used := _holding(t) != null
			var any_cord := false
			for x: Cord in cs:
				any_cord = any_cord or used.call(x)
			for x: Cord in cs:
				var other := sock_used or gen_used
				for y: Cord in cs:
					other = other or (y != x and used.call(y))
				x.emerge_goal = 0.0 if other else 1.0
			t.port_goal = 0.0 if (any_cord or gen_used or t.cord_covered) else 1.0
			t.gen_goal = 0.0 if (any_cord or sock_used) else 1.0
			if t.cord_covered and sock_used: # an ending went on lītus: its accusative hole is covered
				var pc := _cord_into(t, 0)
				pc.free_xf = pc.plug.global_transform.orthonormalized()
				pc.socket_tile = null
				pc.parked = false


## Horizontal axis pointing to the camera's right (what "tip toward you" turns around).
func _tilt_axis() -> Vector3:
	var x := camera.global_basis.x
	x.y = 0.0
	return x.normalized() if x.length() > 0.001 else Vector3.RIGHT


## Every row connected to c through cables, c included.
func _mass(c: Chunk) -> Array:
	var links := []
	for cd in cords:
		if is_instance_valid(cd) and is_instance_valid(cd.socket_tile):
			links.append([cd.owner_tile.get_parent(), cd.socket_tile.get_parent()])
	for oc in owned_by: # and words standing in genitive holders
		if is_instance_valid(oc) and is_instance_valid(owned_by[oc]):
			links.append([oc, owned_by[oc].get_parent()])
	var out := [c]
	var k := 0
	while k < out.size():
		var cur: Chunk = out[k]
		k += 1
		for ln in links:
			for pair in [[ln[0], ln[1]], [ln[1], ln[0]]]:
				if pair[0] == cur and pair[1] is Chunk and pair[1] in chunks and not pair[1] in out:
					out.append(pair[1])
	return out


func _chunk_center(c: Chunk) -> Vector3:
	return c.transform * Vector3(c.width * 0.5, Tile.H * 0.5, 0)


func _inspect_begin(group: Array) -> void:
	if not insp_group.is_empty():
		var same := group.size() == insp_group.size()
		for c in group:
			same = same and c in insp_group
		if same:
			return
	_inspect_end()
	insp_group = group
	insp_tilt = 0.0
	pend_yaw = 0.0
	pend_tilt = 0.0
	insp_pivot = Vector3.ZERO
	for c: Chunk in group:
		insp_rest[c] = [c.position, c.quaternion]
		insp_pivot += _chunk_center(c)
	insp_pivot /= group.size()


## Put the group back down flat (keeping its turn) and stop inspecting.
func _inspect_end() -> void:
	for c in insp_group:
		if is_instance_valid(c) and insp_rest.has(c):
			c.position = insp_rest[c][0]
			c.quaternion = insp_rest[c][1]
	insp_group = []
	insp_rest.clear()
	insp_tilt = 0.0
	pend_yaw = 0.0
	pend_tilt = 0.0


func _inspect_step(delta: float) -> void:
	if insp_group.is_empty():
		return
	for c in insp_group.duplicate():
		if not is_instance_valid(c) or not c in chunks or c == dragging:
			insp_group.erase(c)
			insp_rest.erase(c)
	if insp_group.is_empty():
		_inspect_end()
		return
	insp_idle += delta
	var f := minf(1.0, delta * 16.0) # ease toward the fingers, don't lag behind
	var dy := pend_yaw * f
	var dt := pend_tilt * f
	pend_yaw -= dy
	pend_tilt -= dt
	if dy != 0.0:
		var q := Quaternion(Vector3.UP, dy)
		for c in insp_group:
			var r: Array = insp_rest[c]
			r[0] = insp_pivot + q * (r[0] - insp_pivot)
			r[1] = (q * r[1]).normalized()
	insp_tilt = clampf(insp_tilt + dt, -1.15, 1.15)
	if insp_idle > 0.2 and absf(pend_tilt) < 0.001: # let go: settle back down
		insp_tilt *= exp(-delta * 9.0)
		if absf(insp_tilt) < 0.002:
			insp_tilt = 0.0
	var axis := _tilt_axis()
	var qt := Quaternion(axis, insp_tilt)
	# lift so the lowest corner never sinks into the table
	var low := 0.0
	for c: Chunk in insp_group:
		var r: Array = insp_rest[c]
		var xf := Transform3D(Basis(r[1]), r[0])
		for cx in [0.0, c.width]:
			for cz in [-Tile.D * 0.5, Tile.D * 0.5]:
				var p: Vector3 = qt * (xf * Vector3(cx, 0, cz) - insp_pivot)
				low = minf(low, p.y + Tile.H * 0.5)
	for c: Chunk in insp_group:
		var r: Array = insp_rest[c]
		c.position = insp_pivot + qt * (r[0] - insp_pivot) + Vector3.UP * -low
		c.quaternion = (qt * r[1]).normalized()
	if insp_tilt == 0.0 and absf(pend_yaw) < 0.0005 and insp_idle > 0.3:
		_inspect_end()


func _socket_taken(t: Tile, by: Cord, i := 0) -> bool:
	for c in cords:
		if c != by and is_instance_valid(c) and c.socket_tile == t and c.socket_i == i:
			return true
	return false


## Every piece on the table as a solid box: [frame, half extents]. (The full
## list is worked out once a frame and shared.)
var _boxes_frame := -1
var _boxes_cache: Array = []
var _boxes_sig := 0.0


func _solid_boxes(skip: Tile) -> Array:
	if skip == null:
		if _boxes_frame != Engine.get_process_frames():
			_boxes_frame = Engine.get_process_frames()
			_boxes_cache = _solid_boxes_build(null)
		return _boxes_cache
	return _solid_boxes_build(skip)


## Once a frame: hand the cables the solid pieces, and tell them if any moved.
func _refresh_world() -> void:
	var boxes := _solid_boxes(null)
	var sig := 0.0
	for bx in boxes:
		var t: Transform3D = bx[0]
		sig += t.origin.dot(Vector3(1.3, 3.7, 7.1)) + t.basis.x.dot(Vector3(2.9, 5.3, 1.1)) + t.basis.y.dot(Vector3(0.7, 1.9, 4.3))
	var all := boxes.duplicate()
	all.append([Transform3D(Basis.IDENTITY, Vector3(0, TABLE_Y - 0.03, 0)), Vector3(1.65, 0.03, 0.9)]) # the bench top
	if monitor_body: # the computer: its cable comes out of the back and goes round it
		var mxf := monitor_body.global_transform
		all.append([Transform3D(mxf.basis.orthonormalized(), mxf.origin), Vector3(0.4, 0.28, 0.23) * mxf.basis.get_scale().x])
	Cord.world_boxes = all
	if not is_equal_approx(sig, _boxes_sig) or boxes.size() != Cord.world_boxes.size() - 1:
		_boxes_sig = sig
		Cord.world_ver += 1


func _solid_boxes_build(skip: Tile) -> Array:
	var out := []
	for c in chunks:
		for t: Tile in c.tiles:
			if t == skip:
				continue
			var xf := t.global_transform
			out.append([Transform3D(xf.basis.orthonormalized(), xf * t.shape_offset()), t.box_half()])
	return out


## Push a plug (at origin o, turned by b) out of any piece it overlaps and up off
## the table. Pieces are solid: plugs never pass through them.
func _push_out(b: Basis, o: Vector3, boxes: Array, smp: Array) -> Vector3:
	for pass_i in 4:
		var moved := false
		for sp in smp:
			var r: float = sp[1]
			for bx in boxes:
				var bt: Transform3D = bx[0]
				var h: Vector3 = bx[1]
				var p: Vector3 = Transform3D(b, o) * sp[0]
				var q := bt.basis.transposed() * (p - bt.origin)
				var pen := Vector3(h.x + r - absf(q.x), h.y + r - absf(q.y), h.z + r - absf(q.z))
				if pen.x <= 0.0 or pen.y <= 0.0 or pen.z <= 0.0:
					continue
				if q.y < 0.0:
					pen.y = INF # never shove a plug down into the table
				var push := Vector3.ZERO
				if pen.x <= pen.y and pen.x <= pen.z:
					push.x = pen.x if q.x >= 0.0 else -pen.x
				elif pen.y <= pen.z:
					push.y = pen.y
				else:
					push.z = pen.z if q.z >= 0.0 else -pen.z
				o += bt.basis * push
				moved = true
		for sp in smp:
			var low: float = (Transform3D(b, o) * sp[0]).y - sp[1]
			if low < TABLE_Y:
				o.y += TABLE_Y - low
		if not moved:
			break
	return o


## Move a plug from its current spot toward `to` in small steps so it can't
## tunnel through a piece.
func _sweep(b: Basis, from: Vector3, to: Vector3, boxes: Array, smp: Array) -> Vector3:
	var n := maxi(1, ceili(from.distance_to(to) / 0.006))
	var o := from
	for i in n:
		o += (to - from) / n
		o = _push_out(b, o, boxes, smp)
	return o


## The nearest free hole of this plug's shape (fitting or not: a plural plug
## still turns to face a singular hole, it just won't go in).
## Returns [tile, hole index] or [null, 0].
func _facing_socket(cd: Cord, near: Vector3) -> Array:
	var best: Tile = null
	var best_i := 0
	var bd := 0.3
	for ch in chunks:
		for t: Tile in ch.tiles:
			if t == cd.owner_tile:
				continue
			for i in t.sock_count():
				if t.sock(i)["kind"] != cd.kind or _socket_taken(t, cd, i):
					continue
				if i == 0 and t.port_node and not t.port_open(): # its socket is put away just now
					continue
				if _capped(t): # an adjective's ending: covered by its cap
					continue
				if i > 0 and t.sock(i)["kind"] == "agree" and t.agree_closed(): # shut: the ending has it now
					continue
				if i > 0 and t.sock(i)["kind"] == "dat" and _busy(t): # already the subject / object / an owner
					continue
				var sp := Cord.socket_xf(t, i).origin
				var d := Vector2(sp.x - near.x, sp.z - near.z).length()
				if d < bd:
					bd = d
					best = t
					best_i = i
	return [best, best_i]


func _level(b: Basis) -> Basis:
	var x := b.x
	x.y = 0.0
	x = x.normalized() if x.length() > 0.001 else Vector3.RIGHT
	return Basis(x, Vector3.UP, x.cross(Vector3.UP))


func _update_plugs(delta: float) -> void:
	cords = cords.filter(func(c): return is_instance_valid(c) and is_instance_valid(c.owner_tile))
	for cd: Cord in cords:
		if not cd.interactive or not cd.visible or cd.socket_tile or cd._was_hidden or cd.owner_tile.in_tray or cd.dying or cd.emerge < 0.5 or cd.has_meta("seating"):
			continue
		var carried := dragging != null and cd.owner_tile.get_parent() == dragging
		if cd.parked and not cd.held:
			if not carried:
				continue
			cd.parked = false # its word is being carried off: from now on it trails behind
		if cd == held_cord:
			_update_held(cd, delta)
			continue
		# lying loose: dragged along if its piece walks off, falls onto whatever is below
		var b := _level(cd.free_xf.basis)
		var o := cd.free_xf.origin
		var a := cd.anchor()
		var d := Vector3(o.x - a.x, 0, o.z - a.z)
		var reach := TRAIL if carried else CABLE # a carried word drags its plug along behind it
		if d.length() > reach:
			var to := Vector3(a.x, o.y, a.z) + d.normalized() * reach
			o = _sweep(b, o, to, _solid_boxes(null), cd.samples())
			# the cable pulls the plug round so its tail points back at the word
			var x := -d.normalized()
			b = b.slerp(Basis(x, Vector3.UP, x.cross(Vector3.UP)), minf(1.0, delta * 8.0)).orthonormalized()
		var hit := get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(o, o + Vector3.DOWN, L_PICK))
		var rest_y: float = (hit["position"].y if not hit.is_empty() else TABLE_Y) + cd.boot().y * 0.5
		o.y = move_toward(o.y, rest_y, delta * 2.5) if o.y > rest_y else rest_y
		o = _push_out(b, o, _solid_boxes(null), cd.samples())
		cd.free_xf = Transform3D(b, o)


func _update_held(cd: Cord, delta: float) -> void:
	var cur := cd.free_xf
	var fs := _facing_socket(cd, cur.origin)
	var t: Tile = fs[0]
	var ti: int = fs[1]
	if t != plug_target or ti != plug_target_i:
		_clear_snap_lit()
		plug_target = t
		plug_target_i = ti
	var away := cur.origin - cd.anchor()
	away.y = 0.0
	var free_b := cur.basis
	if away.length() > 0.02: # prongs point away from the cable
		var x := -away.normalized()
		free_b = Basis(x, Vector3.UP, x.cross(Vector3.UP))
	if t == null:
		var m := _on_leash(cd, _plane_point(plug_mouse, cur.origin.y))
		var b0 := cur.basis.slerp(free_b, minf(1.0, delta * 14.0)).orthonormalized()
		var tp0 := Vector3(m.x, lerpf(cur.origin.y, TABLE_Y + HOVER, minf(1.0, delta * 12.0)), m.z)
		cd.free_xf = Transform3D(b0, _sweep(b0, cur.origin, cur.origin.lerp(tp0, minf(1.0, delta * 22.0)), _solid_boxes(null), cd.samples()))
		return
	var S := Cord.socket_xf(t, ti)
	var Si := S.affine_inverse()
	var cl := Si * cur.origin
	var fits := cd.fits(t, ti)
	var leaving := false
	if cd.has_meta("leaving"):
		var lv: Array = cd.get_meta("leaving")
		if lv[0] != t or lv[1] != ti or Vector2(S.origin.x - cur.origin.x, S.origin.z - cur.origin.z).length() > 0.06:
			cd.remove_meta("leaving") # taken away from the hole it came out of: it may go back in now
		else:
			leaving = true
	if leaving:
		fits = false # (just pulled out of this one: it doesn't get drawn back in)
	if leaving and cl.x < cd.plen() - 0.0005 and absf(cl.y) < 0.006 and absf(cl.z) < 0.006:
		var ml0 := Si * _plane_point(plug_mouse, S.origin.y)
		cd.free_xf = S * Transform3D(Basis.IDENTITY, Vector3(lerpf(cl.x, maxf(ml0.x, 0.0), minf(1.0, delta * 20.0)), 0, 0))
		return
	if fits and cl.x < cd.plen() - 0.0005 and absf(cl.y) < 0.006 and absf(cl.z) < 0.006:
		# prongs are in the hole: it can only slide along it, in or out
		var ml := Si * _plane_point(plug_mouse, S.origin.y)
		var lx := lerpf(cl.x, maxf(ml.x, 0.0), minf(1.0, delta * 20.0))
		cd.free_xf = S * Transform3D(Basis.IDENTITY, Vector3(lx, 0, 0))
		_light(t, true)
		if lx <= cd.plen() * 0.06: # all the way in: click, and it's let go of for you
			_drop_plug()
		return
	var dist := Vector2(S.origin.x - cur.origin.x, S.origin.z - cur.origin.z).length()
	var w := 1.0 - smoothstep(0.09, 0.26, dist) # how much it turns to face the hole
	var b := cur.basis.slerp(free_b.slerp(S.basis, w), minf(1.0, delta * 14.0)).orthonormalized()
	var m := _on_leash(cd, _plane_point(plug_mouse, cur.origin.y))
	var tp := Vector3(m.x, lerpf(TABLE_Y + HOVER, S.origin.y, w), m.z)
	var skip: Tile = null
	var l := Si * tp
	if w > 0.6 and l.x < cd.plen() + 0.05 and absf(l.z) < 0.05 and absf(l.y) < 0.05:
		# right in front of the hole: its chamfered mouth guides the prongs to centre
		skip = t
		var k := clampf((l.x - cd.plen()) / 0.05, 0.0, 1.0)
		l.y *= k
		l.z *= k
		var square := b.x.dot(S.basis.x) > 0.995 and absf(cl.z) < 0.004 and absf(cl.y) < 0.004
		if l.x < cd.plen() and not (fits and square):
			l.x = cd.plen() # wrong prongs (or not lined up yet): it butts against the face
		l.x = maxf(l.x, 0.0)
		tp = S * l
	var to := cur.origin.lerp(tp, minf(1.0, delta * 22.0))
	cd.free_xf = Transform3D(b, _sweep(b, cur.origin, to, _solid_boxes(skip), cd.samples()))
	_light(t, fits and w > 0.5)


## A held plug can't be pulled farther than the cable reaches.
func _on_leash(cd: Cord, p: Vector3) -> Vector3:
	var a := cd.anchor()
	var d := Vector3(p.x - a.x, 0, p.z - a.z)
	if d.length() <= CABLE:
		return p
	d = d.normalized() * CABLE
	return Vector3(a.x + d.x, p.y, a.z + d.z)


func _light(t: Tile, on: bool) -> void:
	if on and not t in snap_lit:
		t.set_highlight(true)
		snap_lit.append(t)
	elif not on and t in snap_lit:
		_clear_snap_lit()


## Let go of a plug: it's connected only if its prongs were pushed (nearly) all
## the way in; otherwise it stays where it is and drops onto the table.
func _drop_plug() -> void:
	var cd := held_cord
	held_cord = null
	cd.remove_meta("leaving")
	var lit := plug_target != null and plug_target in snap_lit # lined up with a socket it fits
	_clear_snap_lit()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	cd.held = false
	cd.parked = false
	var t := plug_target
	var ti := plug_target_i
	plug_target = null
	if lit and is_instance_valid(t) and cd.fits(t, ti) and not _socket_taken(t, cd, ti) and (ti > 0 or t.port_node == null or t.port_open()):
		_seat_plug(cd, t, ti) # a click with the plug lined up: it goes in for you
		return
	if t and is_instance_valid(t) and cd.fits(t, ti):
		var S := Cord.socket_xf(t, ti)
		var cl := S.affine_inverse() * cd.free_xf.origin
		if absf(cl.y) < 0.006 and absf(cl.z) < 0.006 and cl.x < cd.plen():
			if cl.x < cd.plen() * 0.3:
				if _misfit_plug(cd, t, ti):
					return
				cd.socket_tile = t
				cd.socket_i = ti
				Sfx.play(self, "plug", S.origin)
				_touch(t)
				if t.get_parent() is Chunk: # click! a little bounce
					t.get_parent().bounce(1.04)
			else: # barely started: it slides back out of the mouth
				cd.free_xf = S * Transform3D(Basis.IDENTITY, Vector3(cd.plen() + 0.002, 0, 0))
	_touch(cd.owner_tile)


## Slide a plug the rest of the way into its socket, then it's connected.
func _seat_plug(cd: Cord, t: Tile, ti := 0) -> void:
	cd.set_meta("seating", true)
	var from := cd.free_xf
	var go := func(k: float) -> void:
		if is_instance_valid(t) and is_instance_valid(cd):
			cd.free_xf = from.interpolate_with(Cord.socket_xf(t, ti), k)
	var tw := create_tween()
	tw.tween_method(go, 0.0, 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		if not is_instance_valid(cd):
			return
		cd.remove_meta("seating")
		if is_instance_valid(t) and not _socket_taken(t, cd, ti) and not t.in_tray:
			if _misfit_plug(cd, t, ti):
				return
			cd.socket_tile = t
			cd.socket_i = ti
			Sfx.play(self, "plug", Cord.socket_xf(t, ti).origin)
			_touch(t)
			if t.get_parent() is Chunk: # click! a little bounce
				t.get_parent().bounce(1.04)
		_touch(cd.owner_tile))


## The noun stem a piece belongs to (itself if it's a stem; the stem before it if it's an ending).
func _stem_of(t: Tile) -> String:
	if t.kind == "stem":
		return t.key
	var c = t.get_parent()
	if c is Chunk:
		var i: int = c.tiles.find(t)
		if i >= 1 and c.tiles[i - 1].kind == "stem":
			return c.tiles[i - 1].key
		if Chunk.is_cap(t) and i >= 2 and c.tiles[i - 1].kind == "ending" and c.tiles[i - 2].kind == "stem":
			return c.tiles[i - 2].key
	return ""


## The ending an adjective cap is on (null: it isn't on one).
func _capped_ending(cap: Tile) -> Tile:
	var c = cap.get_parent()
	if not c is Chunk:
		return null
	var i: int = c.tiles.find(cap)
	if i >= 2 and c.tiles[i - 1].kind == "ending" and c.tiles[i - 2].kind == "stem":
		return c.tiles[i - 1]
	return null


## Is this ending wearing an adjective cap (so it's an adjective, not a noun)?
func _capped(t: Tile) -> bool:
	return t.kind == "ending" and t.get_parent() is Chunk and t.get_parent().cap_of(t) != null


## The genders an adjective cap's ending can be (-a: f; -us: m; -um: m or n...).
func _cap_genders(cap: Tile) -> Array:
	var e := _capped_ending(cap)
	if e == null:
		return []
	return Latin.adj_genders(e.cat, e.key)


## An ending (on an adjective's stem, with no cap yet) a cap could go onto.
func _cap_fits(w: Tile) -> bool:
	var c = w.get_parent()
	if not c is Chunk or not c in chunks:
		return false
	var i: int = c.tiles.find(w)
	return w.kind == "ending" and i >= 1 and c.tiles[i - 1].kind == "stem" and Latin.STEMS[c.tiles[i - 1].key]["pos"] == "adj" and c.cap_of(w) == null


## The adjective ending whose end the held cap is right by (within `reach`).
func _cap_target_near(d: Chunk, reach: float) -> Tile:
	var cp := d.global_transform * Vector3(d.width * 0.5, 0, 0)
	var best: Tile = null
	var bd := reach
	for c: Chunk in chunks:
		if c == d:
			continue
		for t: Tile in c.tiles:
			if t.kind != "ending" or not _cap_fits(t):
				continue
			var tip := t.global_transform * Vector3(t.width * 0.5, 0, 0)
			var dd := cp.distance_to(tip)
			if dd < bd:
				bd = dd
				best = t
	return best


func _cap_attach(d: Chunk, target: Tile) -> bool:
	var tc: Chunk = target.get_parent()
	_end_drag()
	_clear_snap_lit()
	return _try_insert(d, {"chunk": tc, "slot": {"index": tc.tiles.find(target) + 1, "replace": -1}})


## Holding an adjective cap and letting go over (or looking at) an adjective's
## ending: the cap slips onto its end.
func _cap_onto(d: Chunk) -> bool:
	var hit := _ray(drag_mouse)
	if not hit.is_empty() and hit["collider"].has_meta("tile"):
		var w: Tile = hit["collider"].get_meta("tile")
		var c = w.get_parent()
		if w.kind == "stem" and c is Chunk and c.tiles.find(w) + 1 < c.tiles.size():
			w = c.tiles[c.tiles.find(w) + 1]
		if _cap_fits(w):
			return _cap_attach(d, w)
	var near := _cap_target_near(d, 0.2)
	return _cap_attach(d, near) if near else false


## The neuter adapters only work on neuter nouns: on anything else they spark,
## and the plug is spat back out of the hole.
func _misfit_plug(cd: Cord, t: Tile, ti: int) -> bool:
	if cd.kind == "aux": # an adjective's gender cable: the noun's colour must match
		var gs: Array = _cap_genders(cd.owner_tile) if Chunk.is_cap(cd.owner_tile) else [cd.gender]
		if t.kind == "stem" and Latin.STEMS[t.key]["pos"] == "noun" and Latin.genders(t.key).any(func(g): return g in gs):
			return false
		_eject(cd, t, ti)
		return true
	if cd.kind == "agree": # its agreement cable: case and number must match how the noun is used
		if _agrees(cd.owner_tile, t):
			return false
		_eject(cd, t, ti)
		return true
	var stem := ""
	if cd.owner_tile.kind == "adapter" and cd.owner_tile.key == "neut_sg" and cd.kind == "acc":
		stem = _stem_of(t) # N·SG pushed into some -um
	elif t.kind == "adapter" and t.key == "neut_pl" and ti == 0:
		stem = _stem_of(cd.owner_tile) # some -a plugged into N·PL
	else:
		return false
	if stem == "" or Latin.STEMS[stem].get("neuter", false):
		return false
	_eject(cd, t, ti)
	return true


## Sparks, and the plug is spat back out of the hole.
func _eject(cd: Cord, t: Tile, ti: int) -> void:
	var S := Cord.socket_xf(t, ti)
	_sparks(S.origin)
	Sfx.play(self, "spark", S.origin, 2.0)
	cd.socket_tile = null
	cd.parked = false
	cd.free_xf = S * Transform3D(Basis.IDENTITY, Vector3(cd.plen() + 0.1, 0.03, 0))
	if held_cord == cd:
		held_cord = null
		cd.held = false


## How a noun ending (or a bare stem like puer) is being used just now, from what
## it's plugged into and what's plugged into it: [[case, num], ...]. Not used at all:
## everything it could be.
func _usage(t: Tile) -> Array:
	var all := []
	if t.kind == "stem":
		all.append(["nom", "sg"])
		if Latin.STEMS[t.key].get("neuter", false):
			all.append(["acc", "sg"])
	else:
		for r in Latin.NOUN_ENDINGS.get(t.cat, {}).get(t.key, []):
			all.append([r[0], r[1]])
		if t.cat == "decl2" and t.key == "um" and Latin.STEMS.get(_stem_of(t), {}).get("neuter", false):
			all.append(["nom", "sg"])
	var used := []
	for c: Cord in t.cords_out: # its subject cable, plugged in
		if is_instance_valid(c) and c.kind == "nom" and c.socket_tile:
			if c.socket_tile.kind == "adapter" and c.socket_tile.key == "neut_pl":
				used.append(["acc", "pl"]) # (through N·PL: the object)
			else:
				used.append(["nom", "pl" if c.prongs == 2 else "sg"])
	var into := _cord_into(t, 0)
	if into and t.socket_kind in ["acc", "abl"]:
		if into.owner_tile.kind == "adapter" and into.owner_tile.key == "neut_sg":
			used.append(["nom", "sg"]) # (through N·SG: the subject)
		else:
			for a in all:
				if a[0] == t.socket_kind:
					used.append(a)
	if _holding(t) != null:
		for a in all:
			if a[0] == "gen":
				used.append(a)
	if _dat_into(t) != null:
		for a in all:
			if a[0] == "dat":
				used.append(a)
	return used if not used.is_empty() else all


## Is this ending already being used as something (its own cables plugged in,
## something in its main hole, or holding a word)?
func _busy(t: Tile) -> bool:
	if t.port_node != null and _cord_into(t, 0) != null:
		return true
	if _holding(t) != null:
		return true
	for x: Cord in t.cords_out:
		if is_instance_valid(x) and (x.socket_tile != null or x.held):
			return true
	return false


## The dative cable plugged into the top of this ending, if any.
func _dat_into(t: Tile) -> Cord:
	for i in range(1, t.sock_count()):
		if t.sock(i)["kind"] == "dat":
			return _cord_into(t, i)
	return null


## Does this adjective ending agree (case and number) with how this noun is used?
func _agrees(adj: Tile, t: Tile) -> bool:
	if not is_instance_valid(adj) or not is_instance_valid(t):
		return false
	if Chunk.is_cap(adj): # the cap: its ending's case and number, in the noun's gender
		var ce := _capped_ending(adj)
		if ce == null:
			return false
		var ngs: Array = Latin.genders(_stem_of(t)) if _stem_of(t) != "" else ["m", "f", "n"]
		var cm := []
		for r in Latin.adj_readings(ce.cat, ce.key):
			if r[2] in ngs:
				cm.append([r[0], r[1]])
		for u in _usage(t):
			if u in cm:
				return true
		return false
	var mine := []
	for r in Latin.NOUN_ENDINGS.get(adj.cat, {}).get(adj.key, []):
		mine.append([r[0], r[1]])
	for u in _usage(t):
		if u in mine:
			return true
	return false


## Every frame: an agreement cable whose noun is now used in a way it doesn't fit sparks off.
func _check_agreement() -> void:
	for c in cords:
		if not is_instance_valid(c) or c.socket_tile == null:
			continue
		if not is_instance_valid(c.socket_tile) or not is_instance_valid(c.owner_tile): # (thrown away)
			c.socket_tile = null
			c.parked = false
			continue
		if c.has_meta("seating"):
			continue
		if c.socket_tile.kind == "ending" and _capped(c.socket_tile): # a cap went on: that ending's holes are covered
			c.free_xf = Cord.socket_xf(c.socket_tile, c.socket_i) * Transform3D(Basis.IDENTITY, Vector3(c.plen() + 0.05, 0, 0))
			c.socket_tile = null
			c.parked = false
			continue
		if Chunk.is_cap(c.owner_tile) and (c.kind == "aux" or c.kind == "agree"):
			var cgs := _cap_genders(c.owner_tile)
			var st0: Tile = c.socket_tile
			var bad_g: bool = c.kind == "aux" and not (st0.kind == "stem" and Latin.genders(st0.key).any(func(g): return g in cgs))
			if cgs.is_empty() or bad_g: # the cap came off its word (or the word's gender changed): it lets go
				_eject(c, c.socket_tile, c.socket_i)
				continue
		if c.kind != "agree":
			continue
		if c.socket_tile.kind == "stem" and c.socket_tile.agree_closed():
			# an ending went on under it (puer + -um): its hole shuts, and the plug pops up
			# out of it, into the ending's own agreement socket if that one's free and it agrees
			var st: Tile = c.socket_tile
			var en = st.get_parent().tiles[st.get_parent().tiles.find(st) + 1] if st.get_parent() is Chunk else null
			var S := Cord.socket_xf(st, c.socket_i)
			c.socket_tile = null
			c.parked = false
			c.free_xf = S * Transform3D(Basis.IDENTITY, Vector3(c.plen() + 0.05, 0, 0))
			if en is Tile:
				for i in range(1, en.sock_count()):
					if en.sock(i)["kind"] == "agree" and not _socket_taken(en, c, i) and _agrees(c.owner_tile, en):
						_seat_plug(c, en, i)
						break
			continue
		if not _agrees(c.owner_tile, c.socket_tile):
			_eject(c, c.socket_tile, c.socket_i)


func _cord_into(t: Tile, i := 0) -> Cord:
	for c in cords:
		if is_instance_valid(c) and c.socket_tile == t and c.socket_i == i:
			return c
	return null


## The noun word a cable end belongs to (an ending, or a bare stem like puer),
## read in the given case.
func _noun_word(e: Tile, case: String, want_num := "") -> Dictionary:
	var w := _noun_word_bare(e, case, want_num)
	if not w.is_empty():
		var stem_t: Tile = e if e.kind == "stem" else null
		if stem_t == null and e.get_parent() is Chunk:
			var i: int = e.get_parent().tiles.find(e)
			if i >= 1:
				stem_t = e.get_parent().tiles[i - 1]
		var adjs := []
		for c in cords:
			if is_instance_valid(c) and c.kind == "aux" and c.socket_tile == stem_t:
				var a: Tile = c.owner_tile
				for c2: Cord in a.cords_out:
					if is_instance_valid(c2) and c2.kind == "agree" and c2.socket_tile == e:
						var st := _stem_of(a)
						if st != "" and not st in adjs:
							adjs.append(st)
		if not adjs.is_empty():
			adjs.sort()
			w["adj"] = adjs
	if not w.is_empty() and e.get_parent() is Chunk and owned_by.has(e.get_parent()):
		var own := _noun_word(owned_by[e.get_parent()], "gen") # whose it is
		if not own.is_empty():
			w["own"] = own
	return w


func _noun_word_bare(e: Tile, case: String, want_num := "") -> Dictionary:
	if e.kind == "stem": # puer / rēx on its own is nominative singular (lītus, nihil: accusative too)
		var bs: Dictionary = Latin.STEMS[e.key]
		if bs.get("bare_nom", false) and not e.cord_covered and (case == "nom" or (case == "acc" and bs.get("neuter", false))):
			return {"stem": e.key, "num": "sg"}
		return {}
	var c = e.get_parent()
	if not c is Chunk:
		return {}
	var i: int = c.tiles.find(e)
	if i < 1 or c.tiles[i - 1].kind != "stem":
		return {}
	var s: Tile = c.tiles[i - 1]
	var r := Latin.combine(s.key, e.cat, e.key)
	if not r["ok"]:
		return {}
	var found := {}
	for rd in r["readings"]:
		if rd["case"] == case and (found.is_empty() or rd["num"] == want_num):
			found = {"stem": s.key, "num": rd["num"]}
			if rd.has("gender"): # an adjective on its own (no cap): a substantive, "a good man", "good women"...
				found["g"] = rd["gender"]
	return found


## What the display should draw: the verb its cable is plugged into, with
## whatever subject and object are cabled to that verb.
func _scene() -> Dictionary:
	if not is_instance_valid(disp_cord) or disp_cord.socket_tile == null:
		return {"state": "idle"}
	var st: Tile = disp_cord.socket_tile
	var c = st.get_parent()
	if not c is Chunk:
		return {"state": "idle"}
	var i: int = c.tiles.find(st)
	var e: Tile = c.tiles[i + 1] if i + 1 < c.tiles.size() else null
	if e == null or e.kind != "ending" or e.cat != "verb":
		return {"state": "noend", "verb": st.key}
	var ve: Dictionary = Latin.VERB_ENDINGS[e.key]
	var sc := {"state": "scene", "verb": st.key, "person": ve["person"], "vnum": ve["num"], "subj": null, "obj": null, "mods": [],
			"voice": ve.get("voice", "act")}
	var subj := _cord_into(e)
	if subj and subj.owner_tile.kind == "adapter": # a neuter's -um, through the N·SG adapter
		var w0 := _through_adapter(subj.owner_tile, "acc")
		if w0.is_empty() or ve["person"] != 3 or w0["num"] != ve["num"]:
			sc["state"] = "error"
		if not w0.is_empty():
			sc["subj"] = w0
		subj = null
	if subj:
		var w := _noun_word(subj.owner_tile, "nom", ve["num"])
		if w.is_empty() or ve["person"] != 3 or w["num"] != ve["num"] or _holding(subj.owner_tile):
			sc["state"] = "error" # e.g. a plural subject in a singular verb, or a genitive used as one
		if not w.is_empty():
			sc["subj"] = w
	if sc["voice"] == "pass" and st.cord and st.cord.socket_tile: # passives take no object
		sc["state"] = "error"
	elif st.cord and st.cord.socket_tile and st.cord.socket_tile.kind == "adapter": # a neuter's -a, through N·PL
		var ad: Tile = st.cord.socket_tile
		var into := _cord_into(ad, 0)
		var w4 := {}
		if into and into.owner_tile.kind == "ending":
			w4 = _noun_word(into.owner_tile, "nom")
		if w4.is_empty() or not Latin.STEMS[w4["stem"]].get("neuter", false):
			sc["state"] = "error"
		else:
			sc["obj"] = w4
	elif st.cord and st.cord.socket_tile:
		var w2 := _noun_word(st.cord.socket_tile, "acc")
		if w2.is_empty() or _holding(st.cord.socket_tile):
			sc["state"] = "error"
		else:
			sc["obj"] = w2
	# a dative verb's purple cable: to whom
	for dc: Cord in st.cords_out:
		if is_instance_valid(dc) and dc.kind == "dat" and dc.socket_tile:
			var wd := _noun_word(dc.socket_tile, "dat")
			if wd.is_empty() or _holding(dc.socket_tile):
				sc["state"] = "error"
			else:
				sc["dat"] = wd
	# adverbs and prepositional phrases plugged into the verb's star holes
	for si in range(1, st.sock_count()):
		var mc := _cord_into(st, si)
		if mc == null:
			continue
		var p: Tile = mc.owner_tile
		if p.kind == "adapter": # MODVS: an ablative (means / manner) straight into the verb
			var w5 := _through_adapter(p, "abl")
			if w5.is_empty():
				sc["state"] = "error"
			sc["mods"].append({"modi": true, "case": "abl", "noun": w5 if not w5.is_empty() else null})
			continue
		if Latin.STEMS[p.key]["pos"] == "adv":
			sc["mods"].append({"adv": p.key})
			continue
		var m := {"prep": p.key, "case": "", "noun": null}
		for pc: Cord in p.cords_out:
			if is_instance_valid(pc) and (pc.kind == "acc" or pc.kind == "abl") and pc.socket_tile:
				var w3 := _noun_word(pc.socket_tile, pc.kind)
				if w3.is_empty() or m["noun"] != null:
					sc["state"] = "error"
				else:
					m["case"] = pc.kind
					m["noun"] = w3
		if m["noun"] == null:
			sc["state"] = "error" # a preposition needs its noun
		sc["mods"].append(m)
	return sc


## The noun at the far end of an adapter's other cable (the one of this kind).
## N·SG only works for neuters (their -um is nominative too).
func _through_adapter(ad: Tile, kind: String) -> Dictionary:
	for c: Cord in ad.cords_out:
		if is_instance_valid(c) and c.kind == kind and c.socket_tile:
			var w := _noun_word(c.socket_tile, kind)
			if not w.is_empty() and ad.key == "neut_sg" and not Latin.STEMS[w["stem"]].get("neuter", false):
				return {}
			return w
	return {}


# ---------------------------------------------------------------- the sentence reconstruction challenge

## Sets of whole words (endings soldered on) delivered down the chute; build
## them into one correct sentence on the computer to get the next set.
const CHALLENGE := [
	[["puell", "a", "decl1"], ["ama", "t", "verb"], ["puer", "um", "decl2"]],
	[["agricol", "ae", "decl1"], ["equ", "um", "decl2"], ["vide", "unt", "verb"]],
	[["can", "es", "decl3"], ["curr", "unt", "verb"], ["procul", "", ""]],
	[["naut", "a", "decl1"], ["ad", "", ""], ["riv", "um", "decl2"], ["ambula", "t", "verb"]],
	[["puer", "", ""], ["equ", "um", "decl2"], ["puell", "ae", "decl1"], ["vide", "t", "verb"]],
	[["pocul", "um", "decl2"], ["cad", "t", "verb"]],
	[["puer", "", ""], ["carmin", "a", "neut"], ["audi", "t", "verb"]],
	[["puer", "", ""], ["lup", "um", "decl2"], ["harundin", "e", "decl3"], ["terre", "t", "verb"]],
	[["reg", "", ""], ["milit", "es", "decl3"], ["in", "", ""], ["silv", "am", "decl1"], ["duc", "t", "verb"]],
]
var chal_on := false
var chal_i := 0
var chal_words: Array = []
var chal_label: Label3D
var chal_sets: Array = CHALLENGE # the sets of the sentence-reconstruction task being done


func _start_challenge(sets: Array = CHALLENGE) -> void:
	if chal_on:
		return
	chal_sets = sets
	chal_i = 0
	chal_on = true
	_clear_player_words()
	if screen_tab == "search":
		_set_tab("scene")
	_deliver_set()


## Starting a challenge: every word of yours (anything with a stem, on the bench or
## lying loose) vanishes. Endings in the drawers and the adapters stay.
func _clear_player_words() -> void:
	if dragging:
		_release()
	for c: Chunk in chunks.duplicate():
		if c.tiles.any(func(t): return t.kind == "stem"):
			for t: Tile in c.tiles: # its endings go back where they came from
				if t.kind == "ending" and not t.soldered:
					_restock(t)
			_remove_chunk(c)
			owned_by.erase(c)
			_poof(c)
	for t: Tile in loose.duplicate():
		if is_instance_valid(t) and t.kind == "stem" and t.loose_body:
			var c: Chunk = t.loose_body.get_meta("chunk")
			for tt: Tile in c.tiles:
				if tt.kind == "ending" and not tt.soldered:
					_restock(tt)
			for tt in c.tiles:
				loose.erase(tt)
			var rb := t.loose_body
			for tt in c.tiles:
				tt.loose_body = null
			rb.freeze = true
			rb.collision_layer = 0
			_poof(c)
			get_tree().create_timer(0.4).timeout.connect(rb.queue_free)


var chute_queue: Array = [] # words waiting to go down the chute, one at a time
var chute_wait := 0.0


func _deliver_set() -> void:
	chal_words.clear()
	for spec in chal_sets[chal_i]:
		chute_queue.append(spec)
	_chal_text()


## Send the next queued word once the top of the chute is clear.
func _update_chute(delta: float) -> void:
	chute_wait = maxf(0.0, chute_wait - delta)
	if chute_queue.is_empty() or chute_wait > 0.0:
		return
	var mouth := CHUTE_TOP.lerp(CHUTE_END, 0.35)
	var dir := (CHUTE_END - CHUTE_TOP).normalized()
	var busy := false
	for t: Tile in loose:
		if not is_instance_valid(t) or not t.loose_body:
			continue
		var rb := t.loose_body
		var along := (rb.global_position - CHUTE_TOP).dot(dir)
		var off := (rb.global_position - CHUTE_TOP - dir * along).length()
		if along > -0.05 and along < CHUTE_TOP.distance_to(CHUTE_END) and off < 0.25: # in the chute
			if rb.linear_velocity.length() < 0.05: # resting in it: give it a nudge on down
				rb.sleeping = false
				rb.apply_central_impulse(dir * 0.04 * rb.mass / 0.08)
			if rb.global_position.distance_to(mouth) < 0.32:
				busy = true
	if busy:
		chute_wait = 0.2 # still a word in the way: wait a moment
		return
	_deliver_word(chute_queue.pop_front())
	chute_wait = 0.7


## A whole word, its ending soldered on, sent down the chute into the tray.
func _deliver_word(spec: Array) -> void:
	var free: bool = spec.size() > 3 and spec[3] == "loose" # (a tutorial's pieces: not soldered, you put them together)
	Tile.blind = gender_blind # (a challenge: no gender colours on the nouns)
	var tiles := [_new_tile("stem", spec[0])]
	if spec[1] != "":
		tiles.append(_new_ending(spec[2], spec[1]))
	if spec.size() > 3 and spec[3] == "cap": # an adjective: its cap already on
		tiles.append(_new_tile("adapter", "adj"))
	Tile.blind = false
	if gender_blind:
		for t: Tile in tiles:
			t.set_meta("blind", true)
	var c := _new_chunk(tiles, Vector3.ZERO)
	for t: Tile in tiles:
		if not free:
			t.solder()
	_refresh(c)
	# sideways, lying flat on the chute (so it drops flat into the tray, not propped on the lip)
	var dir := (CHUTE_END - CHUTE_TOP).normalized()
	var up := Vector3(-1, 0, 0).cross(dir).normalized()
	var b := Basis(Vector3.RIGHT, up, Vector3.RIGHT.cross(up))
	var spawn := CHUTE_TOP + dir * 0.16 + up * 0.05
	c.global_transform = Transform3D(b, spawn - b * Vector3(c.width * 0.5, Tile.H * 0.5, 0))
	_make_loose_chunk(c)
	_slide_down_chute(c.get_parent(), spawn)
	if not free:
		chal_words.append(c)


## An ending piece showing this form (turning its reel to it if it has one).
func _new_ending(cat: String, form: String) -> Tile:
	var t := Tile.new()
	var done := false
	if cat != "verb" and Latin.REELS.has(cat):
		for base in Latin.REELS[cat]:
			var opts: Array = Latin.REELS[cat][base]
			for i in opts.size():
				if Latin.reel_form(base, opts[i]) == form and not done:
					t.setup_reel(base, cat)
					if i != 0:
						t.set_choice(i)
					done = true
	if not done:
		t.setup("ending", form, cat)
	if not t.cord_specs.is_empty():
		_attach_cord(t, true)
	return t


## Every time the computer's picture changes: is the whole set built into it?
func _check_challenge(sc: Dictionary) -> void:
	if not chal_on or chal_i >= chal_sets.size() or chal_words.size() < chal_sets[chal_i].size() or sc["state"] != "scene":
		return
	var st: Tile = disp_cord.socket_tile
	if not st or not st.get_parent() in chunks:
		return
	var mass := _mass(st.get_parent())
	for w in chal_words:
		if not is_instance_valid(w) or not w in mass:
			return
	_recte()
	var done: Array = chal_words.duplicate()
	chal_words.clear()
	chal_i += 1
	get_tree().create_timer(1.4).timeout.connect(func() -> void:
		for w in done: # the finished sentence is cleared away
			if is_instance_valid(w) and w in chunks:
				_remove_chunk(w)
				owned_by.erase(w)
				_poof(w)
		if chal_i < chal_sets.size():
			_deliver_set()
		else:
			chal_on = false
			_chal_text()
			_note_done())
	_chal_text()


func _chal_text() -> void:
	_hud_update()


# ---------------------------------------------------------------- the computer's search tab

func _set_tab(tab: String) -> void:
	if tab == "search" and chal_on: # no ordering words in the middle of a challenge
		tab_mats["search"].set_shader_parameter("albedo", Color("#d8423a"))
		get_tree().create_timer(0.4).timeout.connect(func() -> void: _set_tab(screen_tab))
		return
	screen_tab = tab
	screen_key = ""
	for k in tab_mats:
		tab_mats[k].set_shader_parameter("albedo", Color("#ffd23f") if k == tab else Color("#8a8f99"))


static func _plain(t: String) -> String:
	for pair in [["ā", "a"], ["ē", "e"], ["ī", "i"], ["ō", "o"], ["ū", "u"]]:
		t = t.replace(pair[0], pair[1])
	return t.to_lower()


## Stems that start with (or contain) what's been typed, shown as stems.
func _results() -> Array:
	var out := []
	for k in Latin.STEMS:
		var shown: String = k + "-"
		var nom := _plain(Latin.nom_form(k))
		if Latin.STEMS[k]["pos"] == "verb": # ama-re, vide-re, audi-re, capi-ere, duc-ere
			shown = k + "-" + ("re" if Latin.STEMS[k]["vclass"] in ["a", "e", "i"] else "ere")
		elif not Latin.takes_ending(k):
			shown = nom
		elif Latin.STEMS[k].get("bare_nom", false):
			shown = k if nom == k else "%s %s-" % [nom, k]
		if not Latin.word_unlocked(k):
			continue
		if query == "" or k.contains(query) or (nom != k and nom.contains(query)):
			out.append([shown, k])
	out.sort_custom(func(a, b): return a[1] < b[1])
	return out


func _order(row: int) -> void:
	var res := _results()
	if row < 0 or row >= res.size() or chal_on:
		return
	sel = row
	_deliver(res[row][1])
	sent_msg = "missum: " + res[row][0]
	sent_t = 2.0
	screen_key = ""


func _search_key(ev: InputEventKey) -> void:
	var res := _results()
	var monitor_at := screen_body.global_position if screen_body else camera.global_position
	Sfx.play(self, "key_enter" if ev.keycode in [KEY_ENTER, KEY_KP_ENTER] else "key%d" % randi_range(1, 4), monitor_at - Vector3(0, 0.2, -0.15), -10.0)
	match ev.keycode:
		KEY_BACKSPACE:
			query = query.substr(0, maxi(0, query.length() - 1))
			sel = 0
		KEY_UP:
			sel = maxi(0, sel - 1)
		KEY_DOWN:
			sel = mini(maxi(0, res.size() - 1), sel + 1)
		KEY_ENTER, KEY_KP_ENTER:
			_order(sel)
		KEY_ESCAPE:
			_set_tab("scene")
		_:
			var ch := char(ev.unicode).to_lower() if ev.unicode > 0 else ""
			if ch.length() == 1 and ch >= "a" and ch <= "z" and query.length() < 16:
				query += ch
				sel = 0
	screen_key = ""


## Clicked the screen while searching: order the stem on that row.
func _screen_click(hit_pos: Vector3) -> void:
	var lp := screen_body.global_transform.affine_inverse() * hit_pos
	var py := (0.5 - lp.y / 0.334) * PixelArt.H
	_order(PixelArt.result_row(py))


func _place_camera() -> void:
	var eye := lerpf(EYE, CROUCH_EYE, crouch_t)
	var bob_y := sin(bob_t * 2.0) * 0.022 * bob_amt # two steps per cycle
	var bob_x := sin(bob_t) * 0.012 * bob_amt
	var side := Vector3(cos(yaw), 0, -sin(yaw)) # the camera's right, on the level
	camera.position = player + Vector3(0, eye + bob_y - land_dip, 0) + side * bob_x
	camera.rotation = Vector3(pitch, yaw, roll)


## WASD walks you around (you can't walk into the bench or the bin).
func _move_camera(delta: float) -> void:
	reel_cool = maxf(0.0, reel_cool - delta)
	# jumping / falling back down, and crouching (hold Shift or C)
	var airborne := player.y > 0.0 or vel_y > 0.0
	if airborne:
		vel_y -= GRAVITY * delta
		player.y += vel_y * delta
		if player.y <= 0.0: # landed: a little dip
			land_dip = clampf(-vel_y * 0.018, 0.0, 0.07)
			Sfx.play2d(self, "step", 2.0, 0.8)
			player.y = 0.0
			vel_y = 0.0
	var typing := screen_tab == "search" or _menu_open() or (note_panel != null and note_panel.visible) # (keys aren't for walking)
	var crouching := not typing and (Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_C))
	var c0 := crouch_t
	crouch_t = move_toward(crouch_t, 1.0 if crouching else 0.0, delta * 6.0)
	var mv := Vector2.ZERO
	if not typing:
		if Input.is_physical_key_pressed(KEY_W): mv.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S): mv.y += 1.0
		if Input.is_physical_key_pressed(KEY_A): mv.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D): mv.x += 1.0
	var want := mv.normalized().rotated(-yaw) * CAM_SPEED * (0.5 if crouching else 1.0)
	move_vel = move_vel.move_toward(want, (ACCEL if mv != Vector2.ZERO else ACCEL * 1.4) * delta)
	if move_vel.length() > 0.0005:
		var np := player + Vector3(move_vel.x * delta, 0, move_vel.y * delta)
		var pr := 0.3 # how close you can get to things
		np.x = clampf(np.x, SIDE_X + pr, RIGHT_X - pr) # the walls
		np.z = clampf(np.z, WALL_Z + pr, FRONT_Z - pr)
		for box in [Rect2(-1.65, -0.9, 3.3, 1.8), # the bench
				Rect2(BIN_X - 0.25, BIN_Z0 - 0.3, 0.5, 2.1), # the bin stand
				]:
			var r: Rect2 = box.grow(pr)
			var q := Vector2(np.x, np.z)
			if r.has_point(q): # pushed back out the nearest way
				var outs := [q.x - r.position.x, r.end.x - q.x, q.y - r.position.y, r.end.y - q.y]
				var m: float = outs.min()
				match outs.find(m):
					0: np.x = r.position.x
					1: np.x = r.end.x
					2: np.z = r.position.y
					3: np.z = r.end.y
		var tb := Vector2(np.x - TRASH_POS.x, np.z - TRASH_POS.z)
		if tb.length() < TRASH_R + 0.3:
			tb = tb.normalized() * (TRASH_R + 0.3)
			np.x = TRASH_POS.x + tb.x
			np.z = TRASH_POS.z + tb.y
		if delta > 0.0: # bumping into something takes the speed out of that direction
			move_vel = Vector2(np.x - player.x, np.z - player.z) / delta
		player.x = np.x
		player.z = np.z
	# the camera: a gentle bob in step with your walking, a lean when you sidestep
	var spd := move_vel.length() / CAM_SPEED
	bob_amt = lerpf(bob_amt, 0.0 if airborne else clampf(spd, 0.0, 1.0), minf(1.0, delta * 8.0))
	var s0 := sin(bob_t)
	bob_t += delta * (4.0 + 7.0 * spd)
	if signf(sin(bob_t)) != signf(s0) and spd > 0.2 and not airborne: # a foot comes down
		step_alt = not step_alt
		Sfx.play2d(self, "step2" if step_alt else "step", linear_to_db(clampf(spd, 0.25, 1.0)) - (6.0 if crouching else 2.0))
	roll = lerpf(roll, -mv.x * 0.03, minf(1.0, delta * 6.0))
	land_dip *= exp(-delta * 8.0)
	if airborne or crouch_t != c0 or bob_amt > 0.0005 or absf(roll) > 0.0005 or land_dip > 0.0005:
		_place_camera()


func _center() -> Vector2:
	return get_viewport().get_visible_rect().size * 0.5


func _captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


var prof := {} # --perf: microseconds spent in each part of the frame
var _pt := 0


func _tick(name: String) -> void:
	if not prof.has("on"):
		return
	var now := Time.get_ticks_usec()
	prof[name] = prof.get(name, 0) + now - _pt
	_pt = now


func _process(delta: float) -> void:
	_pt = Time.get_ticks_usec()
	_refresh_world()
	_tick("world")
	_move_camera(delta)
	if _captured(): # everything is aimed with the crosshair in the middle of the screen
		drag_mouse = _center()
		plug_mouse = _center()
		if dragging == null and held_cord == null:
			_hover(_center())
	_tick("hover")
	_drag_step(delta)
	_inspect_step(delta)
	_follow_gens()
	_update_reels(delta)
	if not chute_queue.is_empty() or chal_on:
		_update_chute(delta)
	_update_sweep()
	_right_words(delta)
	_update_tut(delta)
	_tick("misc")
	_update_functions()
	_check_agreement()
	_tick("functions")
	_update_plugs(delta)
	_tick("plugs")
	if screen_tab == "search":
		blink_t += delta
		sent_t = maxf(0.0, sent_t - delta)
		var res := _results()
		var names := []
		for r in res:
			names.append(r[0])
		var blink := fmod(blink_t, 1.0) < 0.5
		var key := "search|%s|%d|%s|%s" % [query, sel, blink, sent_msg if sent_t > 0.0 else ""]
		if key != screen_key:
			screen_key = key
			_show(PixelArt.search(query, names, sel, blink, sent_msg if sent_t > 0.0 else ""))
		return
	var sc := _scene()
	_tick("scene")
	if sc["state"] == "idle":
		noise_t -= delta
		if noise_t <= 0.0:
			noise_t = 0.09
			_show(PixelArt.noise(true))
		screen_key = ""
		return
	verdict_t = maxf(0.0, verdict_t - delta)
	if screen_broken: # a challenge: the screen's broken: snow (and a tick when it's right), but it still checks
		var bkey := "broken|" + JSON.stringify(sc)
		if bkey != broken_key:
			broken_key = bkey
			if sc["state"] == "scene":
				_judge(sc)
		noise_t -= delta
		if noise_t <= 0.0 or screen_key != "broken":
			noise_t = 0.09
			screen_key = "broken"
			var nim := PixelArt.noise()
			if verdict_t > 0.0:
				PixelArt.verdict(nim, verdict_ok)
			_show(nim)
		return
	var key := JSON.stringify(sc) + ("|%s" % verdict_ok if verdict_t > 0.0 else "")
	if key != screen_key:
		screen_key = key
		var im := PixelArt.compose(sc)
		if verdict_t > 0.0:
			PixelArt.verdict(im, verdict_ok)
		_show(im)
		if sc["state"] == "scene": # every time the picture changes, check it against the board (and the challenge)
			_judge(sc)
			_check_challenge(sc)


# ---------------------------------------------------------------- the billboard

func _build_board() -> void:
	var b := Node3D.new()
	b.position = BOARD_POS
	add_child(b)
	var h := BOARD_W * PixelArt.H / PixelArt.W
	Art.box(b, Vector3(BOARD_W + 0.08, h + 0.08, 0.02), Vector3(0, 0, -0.005), Color("#5a3a20")) # frame
	Art.box(b, Vector3(BOARD_W + 0.02, h + 0.02, 0.012), Vector3(0, 0, 0.002), Color("#f4f1e6"), -1)
	var top := Art.label3d("QVID HIC FIT?", 46)
	top.modulate = Color("#ffd23f")
	top.position = Vector3(0, h * 0.5 + 0.075, 0.01)
	b.add_child(top)
	Art.box(b, Vector3(0.42, 0.07, 0.01), Vector3(0, h * 0.5 + 0.075, 0.0), Color("#2f5d8a"))
	board_count = Art.label3d("", 30)
	board_count.modulate = Color("#f4f1e6")
	board_count.position = Vector3(BOARD_W * 0.5 - 0.06, -h * 0.5 - 0.06, 0.01)
	b.add_child(board_count)
	for px in [-BOARD_W * 0.5 + 0.02, BOARD_W * 0.5 - 0.02]: # pins holding the sheets up
		var pin := CylinderMesh.new()
		pin.top_radius = 0.012
		pin.bottom_radius = 0.012
		pin.height = 0.012
		var pm := Art.mesh(b, pin, Vector3(px, h * 0.5 - 0.02, 0.03), Color("#d8423a"), 1, 0.6)
		pm.rotation_degrees.x = 90
	board_front = _board_sheet(board_i, 0.022)
	board_back = _board_sheet(board_i + 1, 0.014)
	_board_count()


# ---------------------------------------------------------------- the adapter bins (on your right)

const BIN_X := RIGHT_X - 0.3 # against the right wall
const BIN_Z0 := 1.55
const BIN_TOP := 0.85
const BINS := [["modi", "MODVS", "ablative → verb"], ["neut_sg", "NEVTRVM SG", "-um → subject"], ["neut_pl", "NEVTRVM PL", "-a → object"],
		["adj", "ADIECTIVVM", "cap: noun → adjective"]]


func _build_bins() -> void:
	# the stand: solid, except for a slot for the neuter -a drawer under the two neuter bins
	var slot_z := BIN_Z0 + 0.75
	var slot_lo := BIN_TOP - 0.2
	var slot_hi := BIN_TOP - 0.03
	Art.box(self, Vector3(0.5, slot_lo, 2.1), Vector3(BIN_X, slot_lo * 0.5, BIN_Z0 + 0.75), STEEL_DARK)
	_collider(self, Vector3(0.5, slot_lo, 2.1), Vector3(BIN_X, slot_lo * 0.5, BIN_Z0 + 0.75), "rack", L_WORLD)
	Art.box(self, Vector3(0.5, BIN_TOP - slot_hi, 2.1), Vector3(BIN_X, (BIN_TOP + slot_hi) * 0.5, BIN_Z0 + 0.75), STEEL_DARK)
	_collider(self, Vector3(0.5, BIN_TOP - slot_hi, 2.1), Vector3(BIN_X, (BIN_TOP + slot_hi) * 0.5, BIN_Z0 + 0.75), "rack", L_WORLD)
	for side in [[BIN_Z0 - 0.3, slot_z - 0.26], [slot_z + 0.26, BIN_Z0 + 1.8]]: # the stand either side of the slot
		var zc: float = (side[0] + side[1]) * 0.5
		var zl: float = side[1] - side[0]
		Art.box(self, Vector3(0.5, slot_hi - slot_lo, zl), Vector3(BIN_X, (slot_lo + slot_hi) * 0.5, zc), STEEL_DARK)
		_collider(self, Vector3(0.5, slot_hi - slot_lo, zl), Vector3(BIN_X, (slot_lo + slot_hi) * 0.5, zc), "rack", L_WORLD)
	Art.box(self, Vector3(0.48, slot_hi - slot_lo, 0.5), Vector3(BIN_X + 0.01, (slot_lo + slot_hi) * 0.5, slot_z), Color("#1d1824"), -1) # the slot's dark inside
	_build_drawer("neut", Vector3(BIN_X - 0.25 + 0.19 + 0.028, slot_lo + 0.012, slot_z), 0.5, -PI * 0.5, 0.38, 0.32) # front flush with the stand
	for i in BINS.size():
		var info: Array = BINS[i]
		var c := Vector3(BIN_X, BIN_TOP, BIN_Z0 + i * 0.5)
		var col: Color = Tile.ADAPTERS[info[0]]["col"]
		var w := 0.42
		var h := 0.16
		var bn := Node3D.new() # the whole bin (hidden while its adapter isn't unlocked)
		add_child(bn)
		bin_lids[info[0]] = bn
		Art.box(bn, Vector3(w, 0.012, w), c + Vector3(0, 0.006, 0), col.darkened(0.3))
		_collider(bn, Vector3(w, 0.03, w), c + Vector3(0, 0.0, 0), "rack", L_WORLD)
		for sx in [-1, 1]:
			Art.box(bn, Vector3(0.012, h, w), c + Vector3(sx * w * 0.5, h * 0.5, 0), col, 0, 0.6)
			_collider(bn, Vector3(0.03, h + 0.04, w), c + Vector3(sx * w * 0.5, h * 0.5, 0), "rack", L_WORLD)
			Art.box(bn, Vector3(w, h, 0.012), c + Vector3(0, h * 0.5, sx * w * 0.5), col, 0, 0.6)
			_collider(bn, Vector3(w, h + 0.04, 0.03), c + Vector3(0, h * 0.5, sx * w * 0.5), "rack", L_WORLD)
		var lab := Art.label3d(info[1], 30)
		lab.rotation_degrees = Vector3(0, -90, 0) # facing you as you walk up
		lab.position = c + Vector3(-w * 0.5 - 0.008, h * 0.62, 0)
		lab.modulate = Color("#f4f1e6")
		bn.add_child(lab)
		var sub := Art.label3d(info[2], 20)
		sub.rotation_degrees = Vector3(0, -90, 0)
		sub.position = c + Vector3(-w * 0.5 - 0.008, h * 0.3, 0)
		sub.modulate = Color("#ffd23f")
		bn.add_child(sub)
		for k in 4: # a few adapters tipped in
			_make_loose(_new_tile("adapter", info[0]), c + Vector3(randf_range(-0.1, 0.1), 0.06 + k * 0.05, randf_range(-0.1, 0.1)), true)


# ---------------------------------------------------------------- the rest of the garage

const RIGHT_X := 4.3 # the wall to your right
const FRONT_Z := 5.2 # the wall behind you, with the garage door
const ROOF_Y := 4.2
const DOOR_W := 2.6
const DOOR_H := 2.3
const DOOR_X := 0.1


## A box that's part of the building: solid, and casts no shadow (so the roof
## doesn't put the whole workshop in the dark).
func _shell(size: Vector3, pos: Vector3, col: Color, outline := 0) -> MeshInstance3D:
	var m := Art.box(self, size, pos, col, outline)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON # walls and roof keep the sun out
	_matte(m)
	return m


## Everything under a node made matte (cork boards, signs, the bench top...).
func _matte_tree(n: Node) -> void:
	if n is MeshInstance3D:
		_matte(n)
	for c in n.get_children():
		_matte_tree(c)


## Big flat surfaces: no shiny highlight spots from the lamps.
func _matte(m: MeshInstance3D) -> void:
	var mat := m.material_override as ShaderMaterial
	if mat:
		mat.set_shader_parameter("spec_strength", 0.0)
		mat.set_shader_parameter("rim_strength", 0.0)


func _build_room() -> void:
	var plaster := Color("#d9cbb0")
	var zc := (WALL_Z + FRONT_Z) * 0.5
	var zl := FRONT_Z - WALL_Z
	# right wall
	_shell(Vector3(0.1, ROOF_Y, zl), Vector3(RIGHT_X + 0.05, ROOF_Y * 0.5, zc), plaster)
	_collider(self, Vector3(0.1, ROOF_Y, zl), Vector3(RIGHT_X + 0.05, ROOF_Y * 0.5, zc), "wall", L_WORLD)
	_shell(Vector3(0.06, 0.18, zl), Vector3(RIGHT_X - 0.03, 0.09, zc), Color("#5d6268"))
	# front wall, round the garage door
	var x0 := SIDE_X
	var x1 := RIGHT_X
	var dl := DOOR_X - DOOR_W * 0.5
	var dr := DOOR_X + DOOR_W * 0.5
	for seg in [[x0, dl], [dr, x1]]:
		var w: float = seg[1] - seg[0]
		var c := Vector3((seg[0] + seg[1]) * 0.5, ROOF_Y * 0.5, FRONT_Z + 0.05)
		_shell(Vector3(w, ROOF_Y, 0.1), c, plaster)
		_collider(self, Vector3(w, ROOF_Y, 0.1), c, "wall", L_WORLD)
	var lintel := Vector3(DOOR_X, (DOOR_H + ROOF_Y) * 0.5, FRONT_Z + 0.05)
	_shell(Vector3(DOOR_W, ROOF_Y - DOOR_H, 0.1), lintel, plaster)
	_shell(Vector3(x1 - x0, 0.18, 0.06), Vector3((x0 + x1) * 0.5, 0.09, FRONT_Z - 0.03), Color("#5d6268"))
	# the garage door: four steel panels, a row of windows, a handle; tracks up the ceiling
	var door := Node3D.new()
	door.position = Vector3(DOOR_X, 0, FRONT_Z)
	add_child(door)
	var ph := DOOR_H / 4.0
	for k in 4:
		if k == 3: # the window panel: frame pieces between the windows (the glass lets the sun in)
			for j in 6:
				var fx := -DOOR_W * 0.5 + j * (DOOR_W / 5.0)
				Art.box(door, Vector3(0.06, ph - 0.01, 0.06), Vector3(fx, ph * (k + 0.5), 0), Color("#c8ccd0"))
			Art.box(door, Vector3(DOOR_W, 0.07, 0.06), Vector3(0, ph * k + 0.04, 0), Color("#c8ccd0"))
			Art.box(door, Vector3(DOOR_W, 0.07, 0.06), Vector3(0, ph * (k + 1) - 0.04, 0), Color("#c8ccd0"))
			continue
		Art.box(door, Vector3(DOOR_W, ph - 0.01, 0.06), Vector3(0, ph * (k + 0.5), 0), Color("#c8ccd0"))
		for j in 3: # pressed ribs on each panel
			Art.box(door, Vector3(DOOR_W - 0.1, 0.012, 0.004), Vector3(0, ph * k + ph * (0.25 + j * 0.25), -0.032), Color("#aeb3b8"), -1)
	var wy := ph * 3.5 # windows in the top panel
	for j in 5: # windows in the third panel up
		var wx := (j - 2) * (DOOR_W / 5.0)
		var fr := Art.box(door, Vector3(DOOR_W / 5.0 - 0.1, ph - 0.16, 0.07), Vector3(wx, wy, 0), Color("#7f8890"), -1) # frame
		fr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var glass := Art.box(door, Vector3(DOOR_W / 5.0 - 0.16, ph - 0.22, 0.075), Vector3(wx, wy, 0), Color("#bfe6ff"), -1)
		glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Art.box(door, Vector3(0.01, ph - 0.22, 0.08), Vector3(wx, wy, 0), Color("#7f8890"), -1) # glazing bar
	Art.box(door, Vector3(0.3, 0.04, 0.05), Vector3(0, 0.55, -0.05), STEEL_DARK) # handle
	_collider(door, Vector3(DOOR_W, DOOR_H, 0.08), Vector3(0, DOOR_H * 0.5, 0), "wall", L_WORLD)
	for sx in [-1, 1]: # vertical tracks, and the rails it rolls up into along the ceiling
		var rail_y := ROOF_Y - 0.35 # the rails it rolls up into run just under the roof
		_shell(Vector3(0.06, rail_y, 0.06), Vector3(DOOR_X + sx * (DOOR_W * 0.5 + 0.05), rail_y * 0.5, FRONT_Z - 0.05), STEEL_DARK)
		_shell(Vector3(0.06, 0.06, 2.4), Vector3(DOOR_X + sx * (DOOR_W * 0.5 + 0.05), rail_y, FRONT_Z - 1.2), STEEL_DARK)
		for k in 2: # hangers holding the rail up to the roof
			_shell(Vector3(0.03, 0.35, 0.03), Vector3(DOOR_X + sx * (DOOR_W * 0.5 + 0.05), ROOF_Y - 0.175, FRONT_Z - 0.6 - k * 1.4), STEEL_DARK)
	# the roof: a ceiling, with rafters and two strip lights
	_shell(Vector3(x1 - x0 + 0.2, 0.12, zl + 0.2), Vector3((x0 + x1) * 0.5, ROOF_Y + 0.06, zc), Color("#e8e2d4"))
	_collider(self, Vector3(x1 - x0 + 0.2, 0.12, zl + 0.2), Vector3((x0 + x1) * 0.5, ROOF_Y + 0.06, zc), "wall", L_WORLD)
	for k in 5:
		var rz := WALL_Z + 0.4 + k * (zl - 0.8) / 4.0
		_shell(Vector3(x1 - x0, 0.16, 0.1), Vector3((x0 + x1) * 0.5, ROOF_Y - 0.08, rz), Color("#a07850"))
	var hang := 0.9 # the strip lights hang this far below the ceiling
	for lp in [Vector2(-1.4, 0.7), Vector2(1.4, 0.7), Vector2(0.0, 3.0)]:
		var ly := ROOF_Y - hang
		var f := _shell(Vector3(1.2, 0.06, 0.16), Vector3(lp.x, ly, lp.y), STEEL_DARK)
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var tube := Art.box(self, Vector3(1.1, 0.03, 0.08), Vector3(lp.x, ly - 0.045, lp.y), Color("#fff6dc"), -1)
		tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		(tube.material_override as ShaderMaterial).set_shader_parameter("highlight", 2.5) # glowing
		for sx in [-0.5, 0.5]: # hanging chains
			var ch := _shell(Vector3(0.008, hang, 0.008), Vector3(lp.x + sx, ROOF_Y - hang * 0.5, lp.y), STEEL_DARK, -1)
			ch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# the light in here comes from the garage lights (they light the whole room: two lamps, half strength each)
	for lp in [Vector3(-1.2, ROOF_Y - 1.0, 1.2), Vector3(1.6, ROOF_Y - 1.0, 2.2)]:
		var lamp := OmniLight3D.new()
		lamp.position = lp
		lamp.omni_range = 14.0
		lamp.omni_attenuation = 0.0
		lamp.light_energy = 0.55
		lamp.light_color = Color("#fff4e0")
		lamp.shadow_enabled = false
		add_child(lamp)


# ---------------------------------------------------------------- the left wall

const SIDE_X := -4.2 # the wall to your left


func _build_side_wall() -> void:
	_matte(Art.box(self, Vector3(0.1, 7, 12), Vector3(SIDE_X - 0.05, 3.5, 2.0), Color("#d9cbb0")))
	_collider(self, Vector3(0.1, 7, 12), Vector3(SIDE_X - 0.05, 3.5, 2.0), "wall", L_WORLD)
	Art.box(self, Vector3(0.06, 0.18, 12), Vector3(SIDE_X + 0.03, 0.09, 2.0), Color("#5d6268"), 0) # skirting
	bulletin = Node3D.new()
	bulletin.position = Vector3(SIDE_X + 0.01, 1.7, 0.9)
	bulletin.rotation_degrees.y = 90 # faces into the room
	add_child(bulletin)
	var bw := 1.9
	var bh := 1.1
	Art.box(bulletin, Vector3(bw + 0.1, bh + 0.1, 0.03), Vector3(0, 0, 0.0), Color("#7a4a26")) # frame
	Art.box(bulletin, Vector3(bw, bh, 0.012), Vector3(0, 0, 0.02), Color("#c49a6c"), -1) # cork
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 90: # cork speckle
		Art.box(bulletin, Vector3(0.012, 0.008, 0.002), Vector3(rng.randf_range(-bw, bw) * 0.48, rng.randf_range(-bh, bh) * 0.48, 0.027),
				Color("#a77e52") if k % 2 == 0 else Color("#d8b488"), -1)
	var title := Art.label3d("TABVLA NVNTIA", 60)
	title.modulate = Color("#ffd23f")
	title.position = Vector3(0, bh * 0.5 + 0.12, 0.02)
	bulletin.add_child(title)
	Art.box(bulletin, Vector3(0.75, 0.13, 0.01), Vector3(0, bh * 0.5 + 0.12, 0.012), Color("#2f5d8a"))
	# left half: achievements, a grid of empty badge spots
	_pinned_card(Vector3(-bw * 0.27, bh * 0.5 - 0.1, 0), Vector2(0.42, 0.09), "PRAEMIA", Color("#f4f1e6"))
	for r in 3:
		for c in 4:
			var spot := Node3D.new()
			spot.position = Vector3(-bw * 0.45 + 0.08 + c * 0.2, bh * 0.5 - 0.3 - r * 0.24, 0.03)
			bulletin.add_child(spot)
			var ring := CylinderMesh.new()
			ring.top_radius = 0.07
			ring.bottom_radius = 0.07
			ring.height = 0.004
			var rm := Art.mesh(spot, ring, Vector3.ZERO, Color("#b08a5e"), -1)
			rm.rotation_degrees.x = 90
			var q := Art.label3d("?", 40)
			q.modulate = Color(1, 1, 1, 0.35)
			q.position = Vector3(0, 0, 0.004)
			spot.add_child(q)
			badge_slots.append(spot)
	# right half: the challenge map, a pinned sheet with a dotted route of empty stops
	var map := Node3D.new()
	map.position = Vector3(bw * 0.24, -0.04, 0.03)
	bulletin.add_child(map)
	Art.box(map, Vector3(0.85, 0.85, 0.004), Vector3.ZERO, Color("#efe2bf"), -1)
	_pinned_card(Vector3(bw * 0.24, bh * 0.5 - 0.1, 0), Vector2(0.6, 0.09), "TABVLA CERTAMINVM", Color("#f4f1e6"))
	_build_notes(map)


## A paper card pinned to the bulletin board, with a heading on it.
func _pinned_card(pos: Vector3, size: Vector2, text: String, col: Color) -> void:
	Art.box(bulletin, Vector3(size.x, size.y, 0.004), pos + Vector3(0, 0, 0.03), col, -1)
	var l := Art.label3d(text, 34)
	l.modulate = Art.INK
	l.outline_size = 0
	l.position = pos + Vector3(0, 0, 0.034)
	bulletin.add_child(l)
	var pin := CylinderMesh.new()
	pin.top_radius = 0.012
	pin.bottom_radius = 0.012
	pin.height = 0.012
	var pm := Art.mesh(bulletin, pin, pos + Vector3(-size.x * 0.5 + 0.03, size.y * 0.3, 0.04), Color("#d8423a"), 1, 0.6)
	pm.rotation_degrees.x = 90


## One picture sheet on the board (past the last one: a "finis" sheet).
func _board_sheet(i: int, z: float) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(BOARD_W, BOARD_W * PixelArt.H / PixelArt.W)
	var m := MeshInstance3D.new()
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var im: Image
	if i < board_list.size():
		var sc: Dictionary = board_list[i].duplicate()
		sc["state"] = "scene"
		im = PixelArt.compose(sc)
	elif board_list.is_empty():
		im = PixelArt.idle_board()
	else:
		im = PixelArt.finis()
	mat.albedo_texture = ImageTexture.create_from_image(im)
	m.material_override = mat
	m.position = BOARD_POS + Vector3(0, 0, z)
	add_child(m)
	return m


func _board_count() -> void:
	if board_list.is_empty():
		board_count.text = ""
		return
	board_count.text = "%d / %d" % [mini(board_i + 1, board_list.size()), board_list.size()] if board_i < board_list.size() else "FINIS"


## Does the computer's scene match a puzzle picture?
static func _same_scene(sc: Dictionary, want: Dictionary) -> bool:
	if sc.get("state", "") != "scene":
		return false
	for k in ["verb", "person", "vnum", "subj", "obj", "mods", "voice", "dat"]:
		var dflt = [] if k == "mods" else ("act" if k == "voice" else null)
		if JSON.stringify(sc.get(k, dflt), "", true) != JSON.stringify(want.get(k, dflt), "", true):
			return false
	return true


## PROBA on the computer: if its picture matches the board, the sheet slides off.
func _submit() -> void:
	_judge(_scene())


func _judge(sc: Dictionary) -> bool:
	var ok := board_i < board_list.size() and _same_scene(sc, board_list[board_i])
	if ok: # "recte!" on the computer, and the sheet slides off the board
		_recte()
		_board_next()
	return ok


func _recte() -> void:
	Sfx.play(self, "chime", camera.global_position + camera.global_basis * Vector3(0.4, 0, -1.0), -4.0)
	verdict_ok = true
	verdict_t = 1.6
	screen_key = ""


func _board_next() -> void:
	var old := board_front
	Sfx.play(self, "paper", old.global_position, -2.0)
	var tw := old.create_tween().set_parallel()
	tw.tween_property(old, "position", old.position + Vector3(0.25, -1.4, 0.15), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(old, "rotation:z", -0.9, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(old, "transparency", 1.0, 0.9).set_delay(0.3)
	tw.chain().tween_callback(old.queue_free)
	board_i += 1
	board_front = board_back
	var tw2 := board_front.create_tween()
	tw2.tween_property(board_front, "position:z", BOARD_POS.z + 0.022, 0.3).set_delay(0.3)
	board_back = _board_sheet(board_i + 1, 0.014) if board_i < board_list.size() else null
	_board_count()
	if board_i >= board_list.size(): # every picture matched
		_note_done()


## Pin up a new stack of pictures on the board.
func _board_load(list: Array) -> void:
	board_list = list
	board_i = 0
	for sh in [board_front, board_back]:
		if is_instance_valid(sh):
			sh.queue_free()
	board_front = _board_sheet(0, 0.022)
	board_back = _board_sheet(1, 0.014) if not list.is_empty() else null
	_board_count()


## Where on the screen PROBA is drawn.
func _on_submit(hit_pos: Vector3) -> bool:
	if screen_tab != "scene" or _scene()["state"] == "idle":
		return false
	var lp := screen_body.global_transform.affine_inverse() * hit_pos
	var px := (lp.x / 0.62 + 0.5) * PixelArt.W
	var py := (0.5 - lp.y / 0.334) * PixelArt.H
	return PixelArt.on_button(px, py)


func _show(im: Image) -> void:
	screen_tex.update(im)


func _build_monitor() -> void:
	var m := Node3D.new()
	m.position = Vector3(0.36, TABLE_Y, -0.6)
	m.rotation_degrees.y = -20
	m.scale = Vector3.ONE * 0.85
	add_child(m)
	var shell := Color("#e9e0c8")
	Art.box(m, Vector3(0.5, 0.03, 0.32), Vector3(0, 0.015, 0), Color("#cfc6ae"))
	Art.box(m, Vector3(0.12, 0.07, 0.1), Vector3(0, 0.065, 0), Color("#cfc6ae"))
	var body := Node3D.new()
	body.position = Vector3(0, 0.38, 0)
	body.rotation_degrees.x = -12
	m.add_child(body)
	Art.box(body, Vector3(0.8, 0.56, 0.46), Vector3.ZERO, shell)
	_collider(body, Vector3(0.8, 0.56, 0.46), Vector3.ZERO, "monitor", L_WORLD)
	_collider(m, Vector3(0.5, 0.11, 0.32), Vector3(0, 0.055, 0), "monitor", L_WORLD)
	Art.box(body, Vector3(0.68, 0.4, 0.02), Vector3(0, 0.03, 0.234), Color("#2a2a33"))
	# two tab buttons under the screen: the picture, and the stem search
	for tb in [["scene", "TABVLA", 0.1], ["search", "QVAERE", 0.26]]:
		var bm := Art.box(body, Vector3(0.14, 0.045, 0.02), Vector3(tb[2], -0.225, 0.235), Color("#8a8f99"), 0, 0.5)
		tab_mats[tb[0]] = bm.material_override
		tab_nodes[tb[0]] = bm
		var bl := Art.label3d(tb[1], 22)
		bl.position = Vector3(tb[2], -0.225, 0.2465)
		body.add_child(bl)
		var bb := _collider(body, Vector3(0.14, 0.045, 0.03), Vector3(tb[2], -0.225, 0.235), "tab")
		bb.set_meta("tab", tb[0])
	var brand := Art.label3d("COMPVTATRVM", 24)
	brand.position = Vector3(-0.2, -0.22, 0.232)
	body.add_child(brand)
	screen_tex = ImageTexture.create_from_image(PixelArt.noise())
	var q := QuadMesh.new()
	q.size = Vector2(0.62, 0.334)
	var scr := MeshInstance3D.new()
	scr.mesh = q
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/crt.gdshader")
	sm.set_shader_parameter("img", screen_tex)
	screen_mat = sm
	sm.set_shader_parameter("res", Vector2(PixelArt.W, PixelArt.H))
	scr.material_override = sm
	scr.position = Vector3(0, 0.03, 0.246)
	body.add_child(scr)
	screen_body = _collider(body, Vector3(0.62, 0.334, 0.01), Vector3(0, 0.03, 0.246), "screen")
	screen_body.set_meta("screen", true)
	_set_tab("scene")
	# its display cable: plug it into the left end of a verb to show that sentence
	# (it comes out of a socket in the back of the computer, and lies on the bench to its right)
	var port := Tile.new()
	port.cord_kind = "disp"
	port.cord_dir = Vector3(0, 0, -1)
	port.cord_specs = [{"kind": "disp", "prongs": 1, "anchor": Vector3.ZERO, "dir": Vector3(0, 0, -1)}]
	port.position = Vector3(0.26, -0.16, -0.236)
	body.add_child(port)
	Art.box(body, Vector3(0.07, 0.05, 0.02), Vector3(0.26, -0.16, -0.235), Color("#8a8f99"))
	_attach_cord(port, true)
	disp_cord = port.cord
	disp_cord.rest_offset = Vector3(0.38, 0, 0.62)
	monitor_body = body


func _set_hover(t: Tile) -> void:
	if hovered and is_instance_valid(hovered) and t != hovered:
		hovered.set_highlight(false)
	hovered = t
	if t:
		t.set_highlight(true)


# ---------------------------------------------------------------- the campaign: sticky notes, money, levels

## Each level: a sentence-reconstruction note ("recon": soldered words come down
## the chute, build each set into one sentence) and a picture-builder note
## ("picture": make the computer show each picture on the board, from words you
## order yourself). Doing both unlocks the next level.
static func _p(v: String, subj, obj, extra := {}) -> Dictionary:
	var d := {"verb": v, "person": 3, "vnum": "sg", "subj": subj, "obj": obj}
	d.merge(extra, true)
	return d


static func _n(stem: String, num := "sg", own = null) -> Dictionary:
	var d := {"stem": stem, "num": num}
	if own:
		d["own"] = own
	return d


var CAMPAIGN := [
	{ # I: nominative; 3rd person; 1st and 2nd declensions
		"recon": {"title": "Prima Verba", "pay": 10, "text": "Three sentences have come apart. Their words will slide down the chute, endings already soldered on. Plug each subject's blue cable into its verb's ending, and connect the computer to the verb. One person: -t. More than one: -nt.",
			"sets": [[["puell", "a", "decl1"], ["curr", "t", "verb"]],
				[["serv", "i", "decl2"], ["ambula", "unt", "verb"]],
				[["puer", "", ""], ["dormi", "t", "verb"]]]},
		"picture": {"title": "Quis?", "pay": 10, "text": "Make the computer's picture match the picture on the board. Order the stems you need from the computer (QVAERE), take endings from the drawers, and wire up the sentence.",
			"puzzles": [_p("curr", _n("puer"), null), _p("ambula", _n("agricol", "pl"), null, {"vnum": "pl"}), _p("erra", _n("naut"), null)]},
	},
	{ # II: accusative
		"recon": {"title": "Quem? Quid?", "pay": 15, "text": "The accusative: what the verb is done to. -am, -ās, -um, -ōs have a square hole for the verb's red cable.",
			"sets": [[["puell", "a", "decl1"], ["uv", "as", "decl1"], ["habe", "t", "verb"]],
				[["agricol", "ae", "decl1"], ["equ", "os", "decl2"], ["vide", "unt", "verb"]],
				[["puer", "", ""], ["case", "um", "decl2"], ["habe", "t", "verb"]]]},
		"picture": {"title": "Quid Vides?", "pay": 15, "text": "Who does what to whom?",
			"puzzles": [_p("habe", _n("puer"), _n("case")), _p("ama", _n("puell", "pl"), _n("puer"), {"vnum": "pl"}), _p("vide", _n("serv"), _n("equ", "pl"))]},
	},
	{ # III: 3rd, 4th and 5th declensions
		"recon": {"title": "Declinationes", "pay": 20, "text": "The 3rd, 4th and 5th declensions: rēx, mīles, manus, rēs. In the 3rd the bare stem piece is the nominative; the endings are in the middle drawers.",
			"sets": [[["reg", "", ""], ["milit", "es", "decl3"], ["duc", "t", "verb"]],
				[["can", "es", "decl3"], ["curr", "unt", "verb"]],
				[["matr", "", ""], ["fili", "am", "decl1"], ["voca", "t", "verb"]]]},
		"picture": {"title": "Reges et Leones", "pay": 20, "text": "Kings, dogs and lions.",
			"puzzles": [_p("duc", _n("reg"), _n("milit", "pl")), _p("time", _n("puer"), _n("leon")), _p("veni", _n("di"), null)]},
	},
	{ # IV: neuter
		"recon": {"title": "Neutrum", "pay": 25, "text": "Neuter nouns use the same form for subject and object. Use the NEVTRVM adapters from the bins on the right, and the -a in the NEVTRA drawer.",
			"sets": [[["pocul", "um", "decl2"], ["cad", "t", "verb"]],
				[["puer", "", ""], ["carmin", "a", "neut"], ["audi", "t", "verb"]],
				[["puell", "a", "decl1"], ["pocul", "um", "decl2"], ["habe", "t", "verb"]]]},
		"picture": {"title": "Pocula et Carmina", "pay": 25, "text": "Cups and songs.",
			"puzzles": [_p("vide", _n("puer"), _n("pocul")), _p("audi", _n("puell"), _n("carmin", "pl")), _p("cad", _n("pocul"), null)]},
	},
	{ # V: adjectives
		"recon": {"title": "Qualis?", "pay": 30, "text": "Adjectives: bonus, bona, bonum. They take the same endings as the 1st and 2nd declension nouns, so on its own bonus is a noun: a good man. To make it describe a noun, put an ADIECTIVVM cap (the bins on the right) on the end of its ending. The cap's white cable goes into the top of the noun's stem, the gold one into the top of the noun's ending. Wrong gender, case or number: sparks.",
			"sets": [[["puer", "", ""], ["bon", "us", "decl2", "cap"], ["curr", "t", "verb"]],
				[["puell", "a", "decl1"], ["magn", "a", "decl1", "cap"], ["equ", "um", "decl2"], ["vide", "t", "verb"]],
				[["bon", "i", "decl2"], ["ambula", "unt", "verb"]]]},
		"picture": {"title": "Magni et Parvi", "pay": 30, "text": "Big, small, good, bad, happy: build the pictures, adjectives and all. (One of them has no noun at all.)",
			"puzzles": [_p("curr", _a(_n("puer"), ["bon"]), null), _p("vide", _a(_n("puell"), ["magn"]), _n("equ")),
				_p("ambula", {"stem": "laet", "num": "pl", "g": "f"}, null, {"vnum": "pl"})]},
	},
	{ # VI: ablative
		"recon": {"title": "Quo Modo?", "pay": 35, "text": "The ablative: by what means, or how. An ablative ending has a triangular hole; the MODVS adapter (in the bins) plugs it into one of the verb's star holes.",
			"sets": [[["puer", "", ""], ["lup", "um", "decl2"], ["harundin", "e", "decl3"], ["terre", "t", "verb"]],
				[["puell", "a", "decl1"], ["uv", "am", "decl1"], ["man", "ū", "decl4"], ["capi", "t", "verb"]],
				[["agricol", "ae", "decl1"], ["equ", "os", "decl2"], ["harundin", "e", "decl3"], ["duc", "unt", "verb"]]]},
		"picture": {"title": "Harundine", "pay": 35, "text": "Doing things with things.",
			"puzzles": [_p("terre", _n("puer"), _n("lup"), {"mods": [{"modi": true, "case": "abl", "noun": _n("harundin")}]}),
				_p("capi", _n("puell"), _n("uv"), {"mods": [{"modi": true, "case": "abl", "noun": _n("man")}]}),
				_p("duc", _n("agricol"), _n("equ"), {"mods": [{"modi": true, "case": "abl", "noun": _n("harundin")}]})]},
	},
	{ # VII: prepositions
		"recon": {"title": "Quo? Ubi? Unde?", "pay": 40, "text": "Prepositions: ab, ad, in. Each plugs into one of the verb's star holes, and its square (+ acc.) or triangular (+ abl.) plug into its noun.",
			"sets": [[["naut", "a", "decl1"], ["ad", "", ""], ["riv", "um", "decl2"], ["curr", "t", "verb"]],
				[["lup", "us", "decl2"], ["in", "", ""], ["silv", "ā", "decl1"], ["erra", "t", "verb"]],
				[["puer", "", ""], ["ab", "", ""], ["cas", "ā", "decl1"], ["ambula", "t", "verb"]]]},
		"picture": {"title": "Itinera", "pay": 40, "text": "Where is everyone going?",
			"puzzles": [_p("curr", _n("puer"), null, {"mods": [{"prep": "in", "case": "acc", "noun": _n("cas")}]}),
				_p("ambula", _n("agricol"), null, {"mods": [{"prep": "ad", "case": "acc", "noun": _n("riv")}]}),
				_p("erra", _n("lup"), null, {"mods": [{"prep": "in", "case": "abl", "noun": _n("silv")}]})]},
	},
	{ # VIII: passive
		"recon": {"title": "Patiens", "pay": 45, "text": "Passive endings, -tur and -ntur: the subject has the thing done to it. Who does it? Plug ab + ablative into the verb.",
			"sets": [[["puer", "", ""], ["ab", "", ""], ["lup", "o", "decl2"], ["capi", "itur", "verb"]],
				[["puell", "a", "decl1"], ["ama", "itur", "verb"]],
				[["equ", "i", "decl2"], ["ab", "", ""], ["agricol", "ā", "decl1"], ["duc", "untur", "verb"]]]},
		"picture": {"title": "Ab Aliquo", "pay": 45, "text": "Build these as passives: the one on the receiving end is the subject.",
			"puzzles": [_p("capi", _n("puer"), null, {"voice": "pass", "mods": [{"prep": "ab", "case": "abl", "noun": _n("lup")}]}),
				_p("ama", _n("puell"), null, {"voice": "pass"}),
				_p("vide", _n("equ", "pl"), null, {"voice": "pass", "vnum": "pl", "mods": [{"prep": "ab", "case": "abl", "noun": _n("agricol")}]})]},
	},
	{ # IX: genitive
		"recon": {"title": "Cuius?", "pay": 50, "text": "The genitive: whose. A genitive ending has a holder on its back: stand the word it owns in it.",
			"sets": [[["puer", "", ""], ["equ", "um", "decl2"], ["puell", "ae", "decl1"], ["vide", "t", "verb"]],
				[["regin", "a", "decl1"], ["man", "um", "decl4"], ["milit", "is", "decl3"], ["capi", "t", "verb"]],
				[["serv", "us", "decl2"], ["cas", "am", "decl1"], ["domin", "i", "decl2"], ["specta", "t", "verb"]]]},
		"picture": {"title": "Res Alienae", "pay": 50, "text": "Whose is it?",
			"puzzles": [_p("duc", _n("agricol"), _n("equ", "sg", _n("puell"))), _p("capi", _n("regin"), _n("man", "sg", _n("milit"))),
				_p("vide", _n("puer"), _n("cas", "sg", _n("domin")))]},
	},
	{ # X: 1st person
		"recon": {"title": "Ego et Nos", "pay": 55, "text": "I and we: -ō, -mus (passive -or, -mur). A verb with these endings needs no subject word: the ending says who it is.",
			"sets": [[["ama", "ō", "verb"], ["puell", "am", "decl1"]],
				[["vide", "imus", "verb"], ["equ", "os", "decl2"]],
				[["voca", "or", "verb"]]]},
		"picture": {"title": "Oculis Meis", "pay": 55, "text": "These pictures are seen through your own eyes. Build what you are doing.",
			"puzzles": [_p("porta", null, _n("aqu"), {"person": 1}), _p("dormi", null, null, {"person": 1, "vnum": "pl"}), _p("ama", null, _n("puell"), {"person": 1})]},
	},
	{ # XI: 2nd person
		"recon": {"title": "Tu et Vos", "pay": 60, "text": "You: -s, and you all: -tis (passive -ris, -minī).",
			"sets": [[["vide", "is", "verb"], ["lup", "um", "decl2"]],
				[["curr", "itis", "verb"], ["procul", "", ""]],
				[["ab", "", ""], ["puer", "o", "decl2"], ["ama", "eris", "verb"]]]},
		"picture": {"title": "Tu!", "pay": 60, "text": "The picture is of you.",
			"puzzles": [_p("vide", null, _n("lup"), {"person": 2}), _p("curr", null, null, {"person": 2, "vnum": "pl"}), _p("porta", null, _n("aqu"), {"person": 2})]},
	},
	{ # XII: dative
		"recon": {"title": "Cui?", "pay": 70, "text": "The dative: to whom. dare (give), mōnstrāre (show) and nārrāre (tell) have a purple cable: plug it into the round purple hole in the top of a dative ending (-ae, -ō, -ī, -īs, -ibus...).",
			"sets": [[["puell", "a", "decl1"], ["puer", "o", "decl2"], ["uv", "am", "decl1"], ["da", "t", "verb"]],
				[["agricol", "a", "decl1"], ["fili", "ae", "decl1"], ["equ", "um", "decl2"], ["monstra", "t", "verb"]],
				[["poet", "a", "decl1"], ["reg", "i", "decl3"], ["carmin", "", ""], ["narra", "t", "verb"]]]},
		"picture": {"title": "Dona", "pay": 70, "text": "Who gives what to whom?",
			"puzzles": [_p("da", _n("puell"), _n("uv"), {"dat": _n("puer")}), _p("monstra", _n("agricol"), _n("equ"), {"dat": _n("fili")}),
				_p("narra", _n("poet"), _n("carmin"), {"dat": _n("reg")})]},
	},
]


static func _blind_col() -> String:
	Tile.blind = true
	var c := Tile.color_for("stem", "puell", "").to_html(false)
	Tile.blind = false
	return c


static func _with_state(pz: Dictionary) -> Dictionary:
	var d := pz.duplicate()
	d["state"] = "scene"
	return d


static func _a(w: Dictionary, adjs: Array) -> Dictionary:
	w["adj"] = adjs
	return w
var money := 0
var notes_done := {} # "level:kind" -> true
var active_note := "" # the note being worked on ("" = none)
var note_nodes := {} # "level:kind" -> {mesh, label}
var note_open := "" # the note shown up close
var campaign_on := false # (off for the self-test / demo: everything unlocked)


func _note_key(L: int, kind: String) -> String:
	return "%d:%s" % [L, kind]


## Tutorials: one note each, before the first level's notes. Their pieces come down the chute.
var TUTORIALS := [
	{"title": "Verbum Primum", "pay": 5, "text": "Your first verb. A verb stem will come down the chute into the tray on the left of the bench. Put it on the bench, plug the computer's yellow cable into it, and give it an ending from the ACTIVA drawer: the computer draws what it means.",
		"deliver": [["curr", "", "", "loose"]],
		"steps": [
			{"text": "Take the verb curr- out of the tray and put it on the bench.", "check": "on_bench:curr", "hl": ["tile:curr"]},
			{"text": "Pick up the yellow cable coming out of the back of the computer and plug it into the left end of curr-.", "check": "disp:curr", "hl": ["plug:disp", "tile:curr"]},
			{"text": "Open the ACTIVA drawer under the right of the bench and slide a -t onto the end of curr-.", "check": "ending:curr:t", "hl": ["drawer:verb", "tile:curr"]},
			{"text": "Look at the computer: currit, someone is running.", "check": "scene:curr", "hl": ["screen"]}]},
	{"title": "Quis Currit?", "pay": 5, "text": "A noun can be the one doing the verb. Give puell- an ending, and plug its blue cable into the verb's ending: now the picture shows who's walking.",
		"deliver": [["puell", "", "", "loose"], ["ambula", "t", "verb", "loose"]],
		"steps": [
			{"text": "Put puell- and ambulat from the tray on the bench.", "check": "on_bench:puell,ambula", "hl": ["tile:puell", "tile:ambula"]},
			{"text": "Open the DECL. I drawer under the left of the bench and slide an -a onto puell-.", "check": "ending:puell:a", "hl": ["drawer:decl1", "tile:puell"]},
			{"text": "Plug the computer's yellow cable into the left end of ambulat.", "check": "disp:ambula", "hl": ["plug:disp", "tile:ambula"]},
			{"text": "Plug puella's blue cable into the end of ambulat: she's the one walking.", "check": "subj:puell", "hl": ["plugof:puell", "end:ambula"]}]},
	{"title": "Quaere!", "pay": 5, "text": "You can order any word you know from the computer. Click QVAERE, type the start of a word and press Enter: it comes down the chute.",
		"deliver": [],
		"steps": [
			{"text": "Click QVAERE under the computer's screen.", "check": "tab:search", "hl": ["tab:search"]},
			{"text": "Type puer and press Enter.", "check": "ordered:puer", "hl": ["screen"]},
			{"text": "Now look up curr and order it too.", "check": "ordered:curr", "hl": ["screen"]},
			{"text": "Build puer currit: put both on the bench, -t on curr-, the computer into currit, and puer's blue cable into -t. (Click TABVLA to see the picture.)", "check": "subj:puer", "hl": ["tile:puer", "tile:curr", "tab:scene"]}]},
]

## Challenges: extra notes, not needed to go on. They stay up until they're done;
## some open a second, harder one.
var CERTAMINA := [
	{"title": "Sine Coloribus", "pay": 40, "level": 5, "after": "", "type": "recon", "blind": true,
		"text": "CERTAMEN. Adjectives again, but the nouns' boards aren't coloured by gender this time. Agricola is masculine, whatever its ending says...",
		"sets": [[["agricol", "a", "decl1"], ["bon", "us", "decl2", "cap"], ["puell", "am", "decl1"], ["magn", "am", "decl1", "cap"], ["vide", "t", "verb"]],
			[["naut", "ae", "decl1"], ["laet", "i", "decl2", "cap"], ["equ", "um", "decl2"], ["parv", "um", "decl2", "cap"], ["duc", "unt", "verb"]],
			[["femin", "a", "decl1"], ["mal", "a", "decl1", "cap"], ["serv", "os", "decl2"], ["bon", "os", "decl2", "cap"], ["voca", "t", "verb"]]]},
	{"title": "Sine Coloribus II", "pay": 60, "level": 5, "after": "1:chal", "type": "recon", "blind": true,
		"text": "CERTAMEN. Harder: 3rd declension nouns, whose endings don't tell you their gender, and a neuter.",
		"sets": [[["reg", "", ""], ["magn", "us", "decl2", "cap"], ["matr", "em", "decl3"], ["bon", "am", "decl1", "cap"], ["ama", "t", "verb"]],
			[["can", "es", "decl3"], ["parv", "i", "decl2", "cap"], ["leon", "em", "decl3"], ["mal", "um", "decl2", "cap"], ["time", "unt", "verb"]],
			[["puer", "", ""], ["laet", "us", "decl2", "cap"], ["pocul", "um", "decl2"], ["magn", "um", "decl2", "cap"], ["habe", "t", "verb"]]]},
	{"title": "Tabula Fracta", "pay": 35, "level": 3, "after": "", "type": "picture", "broken": true,
		"text": "CERTAMEN. The computer's screen is broken: it won't show you what you've built. Match the pictures on the board anyway. It still chimes when you get one right.",
		"puzzles": [_p("vide", _n("reg"), _n("can", "pl")), _p("ama", _n("matr"), _n("fili")), _p("time", _n("milit", "pl"), _n("leon"), {"vnum": "pl"})]},
	{"title": "Tabula Fracta II", "pay": 55, "level": 7, "after": "3:chal", "type": "picture", "broken": true,
		"text": "CERTAMEN. The screen's still broken, and the pictures are harder: where people go, and what they do things with.",
		"puzzles": [_p("curr", _n("can", "pl"), null, {"vnum": "pl", "mods": [{"prep": "ad", "case": "acc", "noun": _n("riv")}]}),
			_p("terre", _n("lup"), _n("puer", "pl"), {"mods": [{"modi": true, "case": "abl", "noun": _n("harundin")}]}),
			_p("ambula", _n("reg"), null, {"mods": [{"prep": "in", "case": "abl", "noun": _n("silv")}]})]},
]


## What a note is: {title, pay, text, ...} and which sort of task it is.
func _note_info(L: int, kind: String) -> Dictionary:
	match kind:
		"tut": return TUTORIALS[L - 1]
		"chal": return CERTAMINA[L - 1]
	return CAMPAIGN[L - 1][kind]


func _note_type(L: int, kind: String) -> String:
	match kind:
		"tut": return "tut"
		"chal": return CERTAMINA[L - 1]["type"]
	return kind


func _tuts_done() -> bool:
	return notes_done.has(_note_key(TUTORIALS.size(), "tut"))


func _note_state(L: int, kind: String) -> String:
	var k := _note_key(L, kind)
	if notes_done.has(k):
		return "done"
	if k == active_note:
		return "active"
	match kind:
		"tut":
			return "open" if L == 1 or notes_done.has(_note_key(L - 1, "tut")) else "locked"
		"chal":
			var ci: Dictionary = CERTAMINA[L - 1]
			if not _tuts_done() or Latin.level < int(ci["level"]) or (ci["after"] != "" and not notes_done.has(ci["after"])):
				return "locked"
			return "open"
	if L > Latin.level or not _tuts_done():
		return "locked"
	return "open"


## Every note there is, in the order they're pinned up.
func _all_notes() -> Array:
	var out := []
	for i in TUTORIALS.size():
		out.append([i + 1, "tut"])
	for i in CAMPAIGN.size():
		out.append([i + 1, "recon"])
		out.append([i + 1, "picture"])
	for i in CERTAMINA.size():
		out.append([i + 1, "chal"])
	return out


## The sticky notes on the challenge map: only the ones you can take on now are
## pinned up, in a row along the top of the sheet, a little crooked. While you're
## doing one, they're taken down and the sheet shows what to do, ticked off as you go.
var map_heading: Label3D
var checklist: Label3D


func _build_notes(map: Node3D) -> void:
	map_heading = Art.label3d("", 44)
	map_heading.visible = false # (no telling you which level you're on)
	map_heading.modulate = Art.INK
	map_heading.outline_size = 0
	map_heading.position = Vector3(0, 0.3, 0.008)
	map.add_child(map_heading)
	checklist = Art.label3d("", 22)
	checklist.modulate = Art.INK
	checklist.outline_size = 0
	checklist.width = 760
	checklist.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	checklist.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	checklist.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	checklist.position = Vector3(0, 0.39, 0.006)
	checklist.visible = false
	map.add_child(checklist)
	for nk in _all_notes():
		var note := Node3D.new()
		note.visible = false
		map.add_child(note)
		var m := Art.box(note, Vector3(0.13, 0.13, 0.004), Vector3.ZERO, Color.WHITE, 0, 0.5) # an ordinary sticky note
		Art.box(note, Vector3(0.05, 0.015, 0.005), Vector3(0, 0.06, 0.001), Color(1, 1, 1, 1), -1) # tape
		var tl := Art.label3d("", 18)
		tl.modulate = Art.INK
		tl.outline_size = 0
		tl.position = Vector3(0, 0.012, 0.004)
		tl.width = 110
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.add_child(tl)
		var sub := Art.label3d("", 11)
		sub.modulate = Color("#5a4a3a")
		sub.outline_size = 0
		sub.position = Vector3(0, -0.04, 0.004)
		note.add_child(sub)
		var hot := _collider(note, Vector3(0.13, 0.13, 0.03), Vector3.ZERO, "note")
		hot.set_meta("note", nk)
		note_nodes[_note_key(nk[0], nk[1])] = {"node": note, "mesh": m, "label": tl, "sub": sub, "hot": hot}
	_refresh_notes()


const NOTE_COL := {"tut": Color("#b6e3a0"), "recon": Color("#ffe066"), "picture": Color("#ffb3c7"), "chal": Color("#9fd0ff")}
const NOTE_TILT := [-5.0, 3.5, -2.0, 4.5, -3.5, 2.0]


func _refresh_notes() -> void:
	if map_heading:
		map_heading.text = "GRADVS " + Latin.ROMAN[clampi(Latin.level, 1, CAMPAIGN.size()) - 1] if Latin.level <= CAMPAIGN.size() else "OMNIA PERFECTA"
	var shown := []
	for nk in _all_notes():
		var n: Dictionary = note_nodes.get(_note_key(nk[0], nk[1]), {})
		if n.is_empty():
			continue
		var st := _note_state(nk[0], nk[1])
		var show := st == "open" and active_note == "" # (while you're on a task, the sheet shows its steps instead)
		n["node"].visible = show
		n["hot"].collision_layer = L_PICK if show else 0
		if not show:
			continue
		shown.append(n)
		var info := _note_info(nk[0], nk[1])
		(n["mesh"].material_override as ShaderMaterial).set_shader_parameter("albedo", NOTE_COL[nk[1]])
		n["label"].text = info["title"]
		var what: String = {"tut": "disce", "recon": "sententiae", "picture": "picturae", "chal": "certamen"}[nk[1]]
		n["sub"].text = what + "   %d den." % info["pay"]
	for k in shown.size(): # a row along the top of the sheet
		var nd: Node3D = shown[k]["node"]
		nd.position = Vector3((k - (shown.size() - 1) * 0.5) * 0.16, 0.31 - (k % 2) * 0.012, 0.01)
		nd.rotation_degrees.z = NOTE_TILT[k % NOTE_TILT.size()]
	if checklist:
		checklist.visible = active_note != ""
		_update_checklist()


## What the sheet says while you're on a task: each thing to do, ticked off.
func _update_checklist() -> void:
	if not checklist or active_note == "":
		return
	var parts := active_note.split(":")
	var L := int(parts[0])
	var info := _note_info(L, parts[1])
	var lines := PackedStringArray([info["title"].to_upper(), ""])
	match _note_type(L, parts[1]):
		"tut":
			var steps: Array = info["steps"]
			for k in steps.size():
				var mark := "[✓]" if k < tut_step else ("[ ] →" if k == tut_step else "[ ]")
				lines.append("%s %s" % [mark, steps[k]["text"]])
		"recon":
			lines.append("The words come down the chute into the tray. Rebuild each sentence: wire it up and plug in the computer.")
			if info.get("blind", false):
				lines.append("(No gender colours: you have to know them.)")
			for k in chal_sets.size():
				var mark := "[✓]" if k < chal_i else ("[ ] →" if k == chal_i else "[ ]")
				lines.append("%s Sententia %s" % [mark, Latin.ROMAN[k]])
		"picture":
			lines.append("Make the computer's picture match the one on the billboard.")
			if info.get("broken", false):
				lines.append("(The screen is broken: you can't see what you've built.)")
			for k in board_list.size():
				var mark := "[✓]" if k < board_i else ("[ ] →" if k == board_i else "[ ]")
				lines.append("%s Pictura %s" % [mark, Latin.ROMAN[k]])
	checklist.text = "\n".join(lines)


## Click a sticky note: it comes up close, readable, with what it pays and an accept button.
func _open_note(L: int, kind: String) -> void:
	note_open = _note_key(L, kind)
	var info := _note_info(L, kind)
	var st := _note_state(L, kind)
	var ty := _note_type(L, kind)
	note_title.text = info["title"]
	note_kind.text = {"tut": "DISCE", "recon": "SENTENTIAS RESTITVE", "picture": "PICTVRAM FAC"}[ty]
	if kind == "chal":
		note_kind.text = "CERTAMEN · " + note_kind.text
	note_body.text = info["text"] if st != "locked" else "Finish the notes before this one to unlock it."
	note_pay.text = "MERCES: %d denarii" % info["pay"]
	note_accept.text = {"open": "ACCIPE", "active": "IN PROGRESS", "done": "DONE ✓", "locked": "LOCKED"}[st]
	note_accept.disabled = st != "open"
	var style := note_panel.get_theme_stylebox("panel") as StyleBoxFlat
	style.bg_color = NOTE_COL[kind].lightened(0.15)
	note_panel.visible = true
	note_dim.visible = true
	note_panel.scale = Vector2.ONE * 0.6
	note_panel.pivot_offset = note_panel.size * 0.5
	var tw := note_panel.create_tween()
	tw.tween_property(note_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_note() -> void:
	note_open = ""
	note_panel.visible = false
	note_dim.visible = false
	if not OS.get_cmdline_user_args().has("--test"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _accept_open_note() -> void:
	var parts := note_open.split(":")
	_close_note()
	_accept_note(int(parts[0]), parts[1])


var gender_blind := false # a challenge: the nouns delivered have no gender colours
var broken_key := ""
var screen_broken := false # a challenge: the screen won't show your picture


## Take on a note's task (only one at a time).
func _accept_note(L: int, kind: String) -> bool:
	if active_note != "":
		_toast("Finish the note you're on first.")
		return false
	if _note_state(L, kind) != "open":
		return false
	active_note = _note_key(L, kind)
	var info := _note_info(L, kind)
	gender_blind = info.get("blind", false)
	screen_broken = info.get("broken", false)
	screen_key = ""
	match _note_type(L, kind):
		"tut":
			_start_tut(info)
		"recon":
			_start_challenge(info["sets"])
		_:
			_board_load(info["puzzles"])
	_refresh_notes()
	_hud_update()
	_toast(info["title"])
	return true


## The task's done: you're paid; with both notes of the level done, the next level opens.
func _note_done() -> void:
	if active_note == "":
		return
	var parts := active_note.split(":")
	var L := int(parts[0])
	var info := _note_info(L, parts[1])
	var ty := _note_type(L, parts[1])
	notes_done[active_note] = true
	active_note = ""
	gender_blind = false
	screen_broken = false
	screen_key = ""
	_tut_end()
	money += int(info["pay"])
	Sfx.play(self, "chime", camera.global_position, -2.0, 1.25)
	_toast("+%d denarii   ·   %s ✓" % [info["pay"], info["title"]])
	if ty == "picture":
		get_tree().create_timer(2.0).timeout.connect(_board_load.bind([]))
	if parts[1] in ["recon", "picture"] and notes_done.has(_note_key(L, "recon")) and notes_done.has(_note_key(L, "picture")) and L == Latin.level:
		_level_up()
	elif parts[1] == "tut" and _tuts_done():
		get_tree().create_timer(2.5).timeout.connect(func() -> void: _toast("You know the basics! New notes on the board.", 6.0))
	for ci in CERTAMINA.size(): # a challenge this one opened
		if CERTAMINA[ci]["after"] == active_note_was(parts) and _note_state(ci + 1, "chal") == "open":
			get_tree().create_timer(2.5).timeout.connect(func() -> void: _toast("A new challenge on the board: %s" % CERTAMINA[ci]["title"], 5.0))
	_refresh_notes()
	_hud_update()
	_save_game()


func active_note_was(parts: PackedStringArray) -> String:
	return "%s:%s" % [parts[0], parts[1]]


# ---------------------------------------------------------------- tutorials: steps, ticked off, and arrows

var tut_info := {}
var tut_step := 0
var tut_ordered := [] # words ordered from the computer since the tutorial started
var tut_t := 0.0
var tut_arrows: Array = []
var tut_lit: Array = []


func _start_tut(info: Dictionary) -> void:
	tut_info = info
	tut_step = 0
	tut_ordered.clear()
	for spec in info["deliver"]:
		chute_queue.append(spec)


func _tut_end() -> void:
	tut_info = {}
	for a in tut_arrows:
		a.visible = false
	for t in tut_lit:
		if is_instance_valid(t):
			t.set_highlight(false)
	tut_lit.clear()


func _update_tut(delta: float) -> void:
	if tut_info.is_empty():
		return
	for k in tut_arrows.size(): # the arrows bob up and down
		var a: Node3D = tut_arrows[k]
		if a.visible:
			a.get_child(0).position.y = 0.03 * sin(Time.get_ticks_msec() * 0.006 + k)
	tut_t -= delta
	if tut_t > 0.0:
		return
	tut_t = 0.2
	var steps: Array = tut_info["steps"]
	var moved := false
	while tut_step < steps.size() and _tut_check(steps[tut_step]["check"]): # (one done: on to the next)
		tut_step += 1
		moved = true
	if moved:
		Sfx.play2d(self, "click", -4.0, 1.3)
		_update_checklist()
		if tut_step >= steps.size():
			var done_info := tut_info
			_tut_end()
			get_tree().create_timer(1.2).timeout.connect(func() -> void:
				if active_note != "" and _note_info(int(active_note.split(":")[0]), active_note.split(":")[1]) == done_info:
					_note_done())
			return
	_tut_highlight(steps[tut_step]["hl"] if tut_step < steps.size() else [])


func _stem_tile(key: String) -> Tile:
	for c: Chunk in chunks:
		for t: Tile in c.tiles:
			if t.kind == "stem" and t.key == key:
				return t
	for t: Tile in loose:
		if is_instance_valid(t) and t.kind == "stem" and t.key == key:
			return t
	return null


func _tut_check(what: String) -> bool:
	var p := what.split(":")
	match p[0]:
		"on_bench":
			for key in p[1].split(","):
				var t := _stem_tile(key)
				if t == null or t.in_tray or t.loose_body or not t.get_parent() in chunks or t.get_parent() == dragging:
					return false
			return true
		"disp":
			return is_instance_valid(disp_cord) and disp_cord.socket_tile != null and disp_cord.socket_tile.kind == "stem" and disp_cord.socket_tile.key == p[1]
		"ending":
			var t := _stem_tile(p[1])
			if t == null or not t.get_parent() is Chunk:
				return false
			var c: Chunk = t.get_parent()
			var i := c.tiles.find(t)
			return i + 1 < c.tiles.size() and c.tiles[i + 1].kind == "ending" and c.tiles[i + 1].key == p[2]
		"scene":
			var sc := _scene()
			return sc["state"] == "scene" and sc.get("verb", "") == p[1]
		"subj":
			var sc := _scene()
			return sc["state"] == "scene" and sc.get("subj") is Dictionary and sc["subj"]["stem"] == p[1]
		"tab":
			return screen_tab == p[1]
		"ordered":
			return p[1] in tut_ordered
	return false


## Point things out: an arrow bobbing over each, and the pieces lit up.
func _tut_highlight(targets: Array) -> void:
	var spots := []
	var lit := []
	for tg: String in targets:
		var p := tg.split(":")
		var at = null
		match p[0]:
			"tile":
				var t := _stem_tile(p[1])
				if t:
					lit.append(t)
					at = t.global_position + Vector3(0, 0.14, 0)
			"end":
				var t := _stem_tile(p[1])
				if t and t.get_parent() is Chunk:
					var c: Chunk = t.get_parent()
					var i := c.tiles.find(t)
					if i + 1 < c.tiles.size():
						lit.append(c.tiles[i + 1])
						at = c.tiles[i + 1].global_position + Vector3(0, 0.14, 0)
			"plug":
				if is_instance_valid(disp_cord) and disp_cord.socket_tile == null:
					at = disp_cord.plug.global_position + Vector3(0, 0.12, 0)
			"plugof":
				var t := _stem_tile(p[1])
				if t and t.get_parent() is Chunk:
					var c: Chunk = t.get_parent()
					for x: Tile in c.tiles:
						for cd: Cord in x.cords_out:
							if is_instance_valid(cd) and cd.kind == "nom" and cd.socket_tile == null and cd.visible:
								at = cd.plug.global_position + Vector3(0, 0.12, 0)
			"drawer":
				for d: Dictionary in drawers:
					if d["id"] == p[1] or d["cat"] == p[1]:
						var f: Node3D = d["front"]
						at = f.global_position + f.global_basis.z * 0.12 + Vector3(0, 0.1, 0)
						break
			"tab":
				if tab_nodes.has(p[1]) and screen_tab != p[1]:
					at = tab_nodes[p[1]].global_position + Vector3(0, 0.12, 0)
			"screen":
				if screen_body:
					at = screen_body.global_position + Vector3(0, 0.3, 0)
		if at != null:
			spots.append(at)
	while tut_arrows.size() < spots.size():
		var a := Node3D.new()
		add_child(a)
		var inner := Node3D.new()
		a.add_child(inner)
		var cone := CylinderMesh.new()
		cone.top_radius = 0.035
		cone.bottom_radius = 0.0
		cone.height = 0.07
		Art.mesh(inner, cone, Vector3.ZERO, Color("#ffd23f"), 2, 0.6)
		var stalk := CylinderMesh.new()
		stalk.top_radius = 0.012
		stalk.bottom_radius = 0.012
		stalk.height = 0.06
		Art.mesh(inner, stalk, Vector3(0, 0.06, 0), Color("#ffd23f"), 2, 0.6)
		tut_arrows.append(a)
	for k in tut_arrows.size():
		tut_arrows[k].visible = k < spots.size()
		if k < spots.size():
			tut_arrows[k].global_position = spots[k] + Vector3(0, 0.04, 0)
	for t in tut_lit:
		if is_instance_valid(t) and not t in lit:
			t.set_highlight(false)
	for t: Tile in lit:
		t.set_highlight(true)
	tut_lit = lit


func _level_up() -> void:
	_award_medal(Latin.level)
	Latin.level += 1
	_level_unlocked()


func _award_medal(L: int) -> void:
	if L - 1 < badge_slots.size() and badge_slots[L - 1].get_child_count() <= 2: # a medal on the board for the level
		var b: Node3D = badge_slots[L - 1]
		var cm := CylinderMesh.new()
		cm.top_radius = 0.06
		cm.bottom_radius = 0.06
		cm.height = 0.01
		var m := Art.mesh(b, cm, Vector3(0, 0, 0.006), Color("#ffd23f"), 2, 0.6)
		m.rotation_degrees.x = 90
		var r := Art.label3d("★", 40) # (a plain medal: no level number)
		r.modulate = Art.INK
		r.outline_size = 0
		r.position = Vector3(0, 0, 0.013)
		b.add_child(r)


func _level_unlocked() -> void:
	_apply_locks()
	var lv := Latin.level
	if lv <= CAMPAIGN.size():
		get_tree().create_timer(2.5).timeout.connect(func() -> void:
			_toast("New notes on the board!\n%s" % Latin.unlock_text(lv), 7.0))
	else:
		get_tree().create_timer(2.5).timeout.connect(func() -> void: _toast("OMNIA PERFECTA! Every note is done.", 7.0))


# ---------------------------------------------------------------- saving, and the main menu

const SAVE_PATH := "user://latin_garage_save.json" # (the old single save: becomes slot I)
const SLOTS := 3
static var slot := 1 # the save slot being played
var save_path := "" # (the self-test points this at its own file)


func _slot_path(n: int) -> String:
	return "user://latin_garage_slot%d.json" % n


func _read_slot(n: int) -> Dictionary:
	var p := _slot_path(n)
	if not FileAccess.file_exists(p):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	return d if d is Dictionary else {}
static var boot_mode := "" # after a reload from the menu: "new" or "load" (skip the menu)
var menu_layer: CanvasLayer
var menu_resume: Button
var menu_continue: Button
var slot_rows: Array = [] # [label, continue button, new button] per save slot
var game_started := false


func _save_game() -> void:
	if not campaign_on:
		return
	var f := FileAccess.open(save_path if save_path != "" else _slot_path(slot), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"level": Latin.level, "money": money, "notes_done": notes_done.keys()}))


func _read_save() -> Dictionary:
	if save_path == "":
		return _read_slot(slot)
	if not FileAccess.file_exists(save_path):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	return d if d is Dictionary else {}


func _load_game() -> void:
	var d := _read_save()
	if d.is_empty():
		return
	Latin.level = int(d.get("level", 1))
	money = int(d.get("money", 0))
	notes_done.clear()
	for k in d.get("notes_done", []):
		notes_done[k] = true
	if Latin.level > 1 or notes_done.has("1:recon") or notes_done.has("1:picture"): # (a game from before the tutorials)
		for i in TUTORIALS.size():
			notes_done[_note_key(i + 1, "tut")] = true
	for L in range(1, Latin.level): # medals for the levels already done
		_award_medal(L)
	_apply_locks()
	_refresh_notes()
	_hud_update()


func _build_menu() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 10
	add_child(menu_layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = Art.make_theme()
	menu_layer.add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.06, 0.05, 0.09, 0.78)
	root.add_child(dim)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.position = Vector2(-270, -290)
	vb.size = Vector2(540, 580)
	vb.add_theme_constant_override("separation", 16)
	root.add_child(vb)
	var title := Label.new()
	title.text = "LATIN GARAGE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color("#ffd23f"))
	title.add_theme_color_override("font_outline_color", INK)
	title.add_theme_constant_override("outline_size", 12)
	vb.add_child(title)
	var sub := Label.new()
	sub.text = "officina grammatica"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color("#f4f1e6"))
	vb.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 20)
	vb.add_child(gap)
	menu_resume = _menu_button(vb, "PERGE", _menu_resume) # resume
	if FileAccess.file_exists(SAVE_PATH) and not FileAccess.file_exists(_slot_path(1)): # an old single save: slot I
		DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(_slot_path(1)))
	for n in range(1, SLOTS + 1): # each save slot: what's in it, carry on, or a new game there
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		vb.add_child(row)
		var lab := Label.new()
		lab.custom_minimum_size = Vector2(250, 56)
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lab.add_theme_font_size_override("font_size", 22)
		lab.add_theme_color_override("font_color", Color("#f4f1e6"))
		row.add_child(lab)
		var cont := _menu_button(row, "CONTINVA", _menu_continue.bind(n))
		cont.custom_minimum_size = Vector2(150, 56)
		cont.add_theme_font_size_override("font_size", 20)
		var nw := _menu_button(row, "NOVVM", _menu_new.bind(n))
		nw.custom_minimum_size = Vector2(110, 56)
		nw.add_theme_font_size_override("font_size", 20)
		slot_rows.append([lab, cont, nw])
	var vrow := HBoxContainer.new() # settings: the volume
	vrow.add_theme_constant_override("separation", 14)
	vb.add_child(vrow)
	var vl := Label.new()
	vl.text = "VOLVMEN"
	vl.custom_minimum_size = Vector2(150, 44)
	vl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vl.add_theme_font_size_override("font_size", 22)
	vl.add_theme_color_override("font_color", Color("#f4f1e6"))
	vrow.add_child(vl)
	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.step = 1
	volume_slider.value = volume * 100.0
	volume_slider.custom_minimum_size = Vector2(300, 44)
	volume_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vrow.add_child(volume_slider)
	volume_pct = Label.new()
	volume_pct.custom_minimum_size = Vector2(60, 44)
	volume_pct.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	volume_pct.add_theme_font_size_override("font_size", 20)
	volume_pct.add_theme_color_override("font_color", Color("#ffd23f"))
	volume_pct.text = "%d%%" % roundi(volume * 100.0)
	vrow.add_child(volume_pct)
	volume_slider.value_changed.connect(func(v: float) -> void:
		_set_volume(v / 100.0)
		volume_pct.text = "%d%%" % roundi(v)
		Sfx.play2d(self, "click", -4.0)) # (hear it as you go)
	volume_slider.drag_ended.connect(func(_c: bool) -> void: _save_settings())
	_menu_button(vb, "EXI", _menu_quit) # quit
	_show_menu()


# ---------------------------------------------------------------- settings

const SETTINGS_PATH := "user://latin_garage_settings.json"
var volume := 0.8
var volume_slider: HSlider
var volume_pct: Label


func _set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, volume <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.001)))


func _load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var d = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
		if d is Dictionary:
			volume = float(d.get("volume", volume))
	_set_volume(volume)


func _save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"volume": volume}))


func _menu_button(parent: Control, text: String, fn: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(440, 60)
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(func() -> void:
		Sfx.play2d(self, "key_enter", -6.0)
		fn.call())
	parent.add_child(b)
	return b


func _show_menu() -> void:
	for n in range(1, SLOTS + 1):
		var r: Array = slot_rows[n - 1]
		var sv := _read_slot(n)
		var here := game_started and n == slot
		r[0].text = ("%s · " % Latin.ROMAN[n - 1]) + ("vacuum" if sv.is_empty() else "%d denarii" % int(sv.get("money", 0))) + ("  ◂" if here else "")
		r[1].disabled = sv.is_empty()
	menu_resume.visible = game_started
	menu_layer.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _menu_open() -> bool:
	return menu_layer != null and menu_layer.visible


func _start_play() -> void:
	game_started = true
	menu_layer.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_hud_update()


func _menu_resume() -> void:
	_start_play()


func _menu_continue(n: int) -> void:
	if game_started: # mid-game: start afresh from that save
		_save_game()
		slot = n
		boot_mode = "load"
		get_tree().reload_current_scene()
		return
	slot = n
	_load_game()
	_start_play()
	_toast("%d denarii" % money)


func _menu_new(n: int) -> void:
	if game_started and n != slot:
		_save_game() # (keep the game you were playing, in its own slot)
	slot = n
	if FileAccess.file_exists(_slot_path(n)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_slot_path(n)))
	if game_started:
		boot_mode = "new"
		get_tree().reload_current_scene()
		return
	_start_play()
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		_toast("Welcome to the officina! Your tasks are the sticky notes on the board to your left.", 6.0))


func _menu_quit() -> void:
	_save_settings()
	_save_game()
	get_tree().quit()


# ---------------------------------------------------------------- what's locked at this level

func _drawer_locked(i: int) -> bool:
	var d: Dictionary = drawers[i]
	var dinfo: Dictionary = {}
	for info in Latin.DRAWERS:
		if info.get("id", info["cat"]) == d["id"]:
			dinfo = info
	for e: String in dinfo["endings"]:
		if e.ends_with("~"):
			for o in Latin.REELS[d["cat"]][e.left(-1)]:
				if Latin.ending_unlocked(d["cat"], Latin.reel_form(e.left(-1), o)):
					return false
		elif Latin.ending_unlocked(d["cat"], e):
			return false
	return true


## Padlocks on drawers, lids on bins, covers on endings that aren't unlocked yet.
func _apply_locks() -> void:
	for i in drawers.size(): # drawers that aren't unlocked aren't there: a blank panel fills the slot
		var d: Dictionary = drawers[i]
		var locked := _drawer_locked(i)
		d["locked"] = locked
		if locked and d["open"]:
			_toggle_drawer(i, false)
		var dn: AnimatableBody3D = d["node"]
		dn.visible = not locked
		dn.collision_layer = 0 if locked else (L_WORLD | L_BLOCK)
		d["front"].collision_layer = 0 if locked else L_PICK
		d["blank"].visible = locked
	for t: Tile in loose.duplicate(): # endings (and adapters) that aren't unlocked aren't there either
		if not is_instance_valid(t) or not t.loose_body:
			continue
		var show := true
		if t.kind == "ending":
			show = t.forms().any(func(f): return Latin.ending_unlocked(t.cat, f))
		elif t.kind == "adapter":
			show = Latin.adapter_unlocked(t.key)
		else:
			continue
		var rb := t.loose_body
		if rb.visible != show:
			rb.visible = show
			rb.collision_layer = L_LOOSE if show else 0
			rb.freeze = not show
			var di: int = t.get_meta("drawer_i", -1)
			if show and di >= 0 and di < drawers.size(): # (it waited, frozen, where the drawer used to be: put it back in)
				var dd: Dictionary = drawers[di]
				var dn2: Node3D = dd["node"]
				rb.global_transform = Transform3D(dn2.global_basis, dn2.global_transform * Vector3(randf_range(-0.3, 0.3) * dd["iw"], 0.08, randf_range(-0.3, 0.3) * dd["dd"]))
				rb.linear_velocity = Vector3.ZERO
				rb.sleeping = false
	for t: Tile in _all_tiles():
		if t.is_reel():
			t._layout_reel()
	for key in bin_lids: # adapter bins
		var bn: Node3D = bin_lids[key]
		var show := Latin.adapter_unlocked(key)
		bn.visible = show
		for ch in bn.get_children():
			if ch is StaticBody3D:
				ch.collision_layer = L_WORLD if show else 0


func _all_tiles() -> Array:
	var out := []
	for c: Chunk in chunks:
		out.append_array(c.tiles)
	for t in loose:
		if is_instance_valid(t) and not t in out:
			out.append(t)
	return out


var bin_lids := {} # adapter key -> lid (shut while that adapter isn't unlocked)


# ---------------------------------------------------------------- HUD: money, level, task, messages

var hud_money: Label
var hud_task: Label
var toast_label: Label
var note_dim: ColorRect
var note_panel: Panel
var note_title: Label
var note_kind: Label
var note_body: Label
var note_pay: Label
var note_accept: Button


func _build_campaign_ui(root: Control) -> void:
	hud_money = Label.new()
	hud_money.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hud_money.position = Vector2(-300, 14)
	hud_money.size = Vector2(286, 40)
	hud_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_money.add_theme_font_size_override("font_size", 26)
	hud_money.add_theme_color_override("font_color", Color("#ffd23f"))
	hud_money.add_theme_color_override("font_outline_color", INK)
	hud_money.add_theme_constant_override("outline_size", 8)
	hud_money.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud_money)
	hud_task = Label.new()
	hud_task.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud_task.position = Vector2(16, 14)
	hud_task.add_theme_font_size_override("font_size", 20)
	hud_task.add_theme_color_override("font_color", Color.WHITE)
	hud_task.add_theme_color_override("font_outline_color", INK)
	hud_task.add_theme_constant_override("outline_size", 7)
	hud_task.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud_task)
	toast_label = Label.new()
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_label.position = Vector2(-420, 70)
	toast_label.size = Vector2(840, 120)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_font_size_override("font_size", 24)
	toast_label.add_theme_color_override("font_color", Color("#fff6dc"))
	toast_label.add_theme_color_override("font_outline_color", INK)
	toast_label.add_theme_constant_override("outline_size", 8)
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label.modulate.a = 0.0
	root.add_child(toast_label)
	# the sticky note, up close
	note_dim = ColorRect.new()
	note_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	note_dim.color = Color(0, 0, 0, 0.45)
	note_dim.visible = false
	note_dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_close_note())
	root.add_child(note_dim)
	note_panel = Panel.new()
	note_panel.set_anchors_preset(Control.PRESET_CENTER)
	note_panel.size = Vector2(560, 470)
	note_panel.position = Vector2(-280, -235)
	note_panel.rotation = deg_to_rad(-1.5)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#ffe680")
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(6, 8)
	note_panel.add_theme_stylebox_override("panel", sb)
	note_panel.visible = false
	root.add_child(note_panel)
	var tape := ColorRect.new() # a strip of tape across the top
	tape.color = Color(1, 1, 1, 0.45)
	tape.size = Vector2(140, 30)
	tape.position = Vector2(210, -12)
	tape.rotation = deg_to_rad(3)
	note_panel.add_child(tape)
	var vb := VBoxContainer.new()
	vb.position = Vector2(34, 30)
	vb.size = Vector2(492, 410)
	vb.add_theme_constant_override("separation", 12)
	note_panel.add_child(vb)
	note_kind = _note_label(16, Color("#6a5a3a"))
	vb.add_child(note_kind)
	note_title = _note_label(38, INK)
	vb.add_child(note_title)
	note_body = _note_label(21, Color("#2a2430"))
	note_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_body.custom_minimum_size = Vector2(492, 170)
	vb.add_child(note_body)
	note_pay = _note_label(24, Color("#3a7a2a"))
	vb.add_child(note_pay)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	vb.add_child(hb)
	note_accept = Button.new()
	note_accept.custom_minimum_size = Vector2(200, 52)
	note_accept.add_theme_font_size_override("font_size", 24)
	note_accept.pressed.connect(_accept_open_note)
	hb.add_child(note_accept)
	var close := Button.new()
	close.text = "CLAVDE"
	close.custom_minimum_size = Vector2(140, 52)
	close.add_theme_font_size_override("font_size", 20)
	close.pressed.connect(_close_note)
	hb.add_child(close)
	_hud_update()


func _note_label(size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


func _hud_update() -> void:
	if not hud_money:
		return
	hud_money.visible = campaign_on
	hud_task.visible = campaign_on
	hud_money.text = "%d denarii" % money
	if active_note == "":
		hud_task.text = "No task: pick a sticky note on the board to your left."
		return
	var parts := active_note.split(":")
	var info := _note_info(int(parts[0]), parts[1])
	match _note_type(int(parts[0]), parts[1]):
		"recon":
			hud_task.text = "%s   ·   sentence %d / %d" % [info["title"], mini(chal_i + 1, chal_sets.size()), chal_sets.size()]
		"picture":
			hud_task.text = "%s   ·   picture %d / %d" % [info["title"], mini(board_i + 1, board_list.size()), board_list.size()]
		_:
			hud_task.text = "%s   ·   step %d / %d" % [info["title"], mini(tut_step + 1, info["steps"].size()), info["steps"].size()]
	_update_checklist()


func _toast(msg: String, secs := 3.0) -> void:
	if not toast_label:
		return
	toast_label.text = msg
	var tw := toast_label.create_tween()
	toast_label.modulate.a = 0.0
	tw.tween_property(toast_label, "modulate:a", 1.0, 0.2)
	tw.tween_interval(secs)
	tw.tween_property(toast_label, "modulate:a", 0.0, 0.6)


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	var post_layer := CanvasLayer.new()
	post_layer.layer = 1
	add_child(post_layer)
	var post := ColorRect.new()
	post.set_anchors_preset(Control.PRESET_FULL_RECT)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pm := ShaderMaterial.new()
	pm.shader = load("res://shaders/paper.gdshader")
	post.material = pm
	post_layer.add_child(post)

	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Art.make_theme()
	layer.add_child(root)
	crosshair = Control.new() # a small dot in the middle of the screen
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(crosshair)
	for r in [[Vector2(-4, -4), Vector2(8, 8), INK], [Vector2(-2, -2), Vector2(4, 4), Color.WHITE]]:
		var dot := ColorRect.new()
		dot.position = r[0]
		dot.size = r[1]
		dot.color = r[2]
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crosshair.add_child(dot)
	_build_campaign_ui(root)
	if not OS.get_cmdline_user_args().has("--test"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED



# ---------------------------------------------------------------- demo (for screenshots)

func _loose_of(key: String, kind := "stem") -> Tile:
	for t in loose.filter(func(x): return is_instance_valid(x)):
		if t.key == key and t.kind == kind:
			return t
	return null


func _demo() -> void:
	await get_tree().create_timer(2.7).timeout # let the drawers settle first
	_toggle_drawer(0)
	var specs := [["puell", "ae"], ["ama", "unt"], ["puer", "os"], ["vide", "t"], ["agricol", "a"], ["ama", "ō"]]
	var pos := [Vector3(-0.6, TABLE_Y, 0.45), Vector3(-0.2, TABLE_Y, 0.0), Vector3(0.1, TABLE_Y, 0.5),
			Vector3(-0.15, TABLE_Y, -0.5), Vector3(-0.62, TABLE_Y, -0.3), Vector3(0.25, TABLE_Y, -0.15)]
	var made := []
	for i in specs.size():
		var st := _take_tile(_loose_of(specs[i][0]))
		var en := _take_tile(_ending_piece(specs[i][1], Latin.cat_for_stem(specs[i][0])))
		_set_form(en, specs[i][1])
		var c := _new_chunk([st, en], pos[i])
		_refresh(c)
		made.append(c)
	# puellae --nom--> amant ; amant --acc--> puerōs
	made[0].tiles[1].cord.socket_tile = made[1].tiles[1]
	made[1].tiles[0].cord.socket_tile = made[2].tiles[1]
	disp_cord.socket_tile = made[1].tiles[0] # the computer shows amant's sentence
	_touch(made[1].tiles[1])
	if "--hold" in OS.get_cmdline_user_args(): # screenshot of a word being held up
		var hp := _screen(made[2].tiles[0].global_position)
		_press(hp, true)
		_drag_to(hp + Vector2(-60, -40))
	if "--search" in OS.get_cmdline_user_args(): # screenshot of the search tab after ordering
		_set_tab("search")
		query = "a"
		_order(1)
	if "--adjcap" in OS.get_cmdline_user_args(): # screenshot: magnus (capped) plugged into puer, and bonae on its own
		var pu := _new_chunk([_new_tile("stem", "puer")], Vector3(-0.35, TABLE_Y, 0.25))
		var cp := _new_tile("adapter", "adj")
		var mg := _new_chunk([_new_tile("stem", "magn"), _new_ending("decl2", "us"), cp], Vector3(-0.3, TABLE_Y, 0.55))
		var bn := _new_chunk([_new_tile("stem", "bon"), _new_ending("decl1", "ae")], Vector3(0.25, TABLE_Y, 0.5))
		var lone := _new_chunk([_new_tile("adapter", "adj")], Vector3(0.35, TABLE_Y, 0.25))
		for c in [pu, mg, bn, lone]:
			_refresh(c)
		await get_tree().create_timer(0.4).timeout
		for cd: Cord in cp.cords_out:
			for i in pu.tiles[0].sock_count():
				if pu.tiles[0].sock(i)["kind"] == cd.kind:
					_seat_plug(cd, pu.tiles[0], i)
		player = Vector3(0.0, 0, 1.35)
		pitch = deg_to_rad(-52)
		_place_camera()
	if "--gen" in OS.get_cmdline_user_args(): # screenshot: rēx standing in puellae's holder, looking down
		var rex := _new_chunk([_take_tile(_loose_of("reg"))], Vector3.ZERO)
		owned_by[rex] = made[0].tiles[1]
		pitch = deg_to_rad(-58)
		_place_camera()
	if "--mods" in OS.get_cmdline_user_args(): # screenshot: puer ad rīvum procul currit
		for m in made: # clear the usual demo off the bench
			_remove_chunk(m)
			m.queue_free()
		var vb := _new_chunk([_new_tile("stem", "curr"), _new_tile("ending", "t", "verb")], Vector3(-0.15, TABLE_Y, 0.15))
		var pu := _new_chunk([_take_tile(_loose_of("puer"))], Vector3(-0.6, TABLE_Y, 0.15))
		var pc := _new_chunk([_new_tile("stem", "procul")], Vector3(-0.3, TABLE_Y, 0.45))
		var adw := _new_chunk([_new_tile("stem", "ad")], Vector3(0.05, TABLE_Y, 0.45))
		var re := _new_tile("ending", "u~", "decl2")
		_set_form(re, "um")
		var rv := _new_chunk([_new_tile("stem", "riv"), re], Vector3(0.3, TABLE_Y, 0.15))
		var es := _new_tile("ending", "e~", "decl5")
		_set_form(es, "es")
		var rs := _new_chunk([_new_tile("stem", "r"), es], Vector3(0.35, TABLE_Y, -0.2))
		for c in [vb, pu, pc, adw, rv, rs]:
			_refresh(c)
		pu.tiles[0].cord.socket_tile = vb.tiles[1]
		pc.tiles[0].cord.socket_tile = vb.tiles[0]
		pc.tiles[0].cord.socket_i = 1
		adw.tiles[0].cords_out[0].socket_tile = vb.tiles[0]
		adw.tiles[0].cords_out[0].socket_i = 2
		adw.tiles[0].cords_out[1].socket_tile = re
		disp_cord.socket_tile = vb.tiles[0]
		disp_cord.socket_i = 0
		player = Vector3(-0.05, 0, 1.15)
		yaw = 0.0
		pitch = deg_to_rad(-52)
		crouch_t = 0.6
		_place_camera()
	if "--hang" in OS.get_cmdline_user_args(): # screenshot: a cable hanging off the front of the bench
		var pw: Chunk = made[0]
		pw.position = Vector3(-0.5, TABLE_Y, 0.72)
		var hc: Cord = pw.tiles[1].cord
		hc.socket_tile = null
		hc.parked = false
		hc.free_xf = Transform3D(Basis.IDENTITY, Vector3(-0.35, 0.6, 1.0))
		player = Vector3(0.2, 0, 1.9)
		yaw = deg_to_rad(15)
		pitch = deg_to_rad(-30)
		_place_camera()
	if "--door" in OS.get_cmdline_user_args(): # screenshot: turned round, the garage door
		player = Vector3(-0.3, 0, 1.3)
		yaw = deg_to_rad(180 - 25)
		pitch = deg_to_rad(8)
		_place_camera()
	if "--bins" in OS.get_cmdline_user_args(): # screenshot: the adapter bins on the right
		player = Vector3(1.6, 0, 2.0) if not "--binsclose" in OS.get_cmdline_user_args() else Vector3(3.35, 0, 1.75)
		yaw = deg_to_rad(-90)
		pitch = deg_to_rad(-35) if not "--binsclose" in OS.get_cmdline_user_args() else deg_to_rad(-62)
		_place_camera()
	if "--wall" in OS.get_cmdline_user_args(): # screenshot: the bulletin board on the left wall
		player = Vector3(-1.2, 0, 0.9)
		yaw = deg_to_rad(90)
		pitch = deg_to_rad(-4)
		_place_camera()
	if "--drawers" in OS.get_cmdline_user_args(): # screenshot: the cabinets under the bench
		player = Vector3(-0.3, 0, 2.3)
		yaw = 0.0
		pitch = deg_to_rad(-22)
		crouch_t = 1.0
		_place_camera()
	if "--board" in OS.get_cmdline_user_args(): # screenshot: looking up at the billboard
		player = Vector3(0.9, 0, 1.3)
		_place_camera()
		camera.look_at(BOARD_POS + Vector3(0, -0.15, 0))
		if "--hold" in OS.get_cmdline_user_args():
			pass
	if "--close" in OS.get_cmdline_user_args():
		camera.position = Vector3(0.0, 1.95, 1.55)
		camera.look_at(Vector3(0.0, TABLE_Y + 0.1, 0.0))


# ---------------------------------------------------------------- self test (drives the real input handlers)

func _screen(p: Vector3) -> Vector2:
	return camera.unproject_position(p)


## A loose stem (tray) or ending (drawer, opened if needed) the mouse can reach.
## A loose ending piece that can make this form (a plain one, or a windowed
## one whose reel can show it).
func _ending_piece(form: String, cat: String, need_click := false) -> Tile:
	for t in loose.filter(func(x): return is_instance_valid(x)):
		if t.kind != "ending" or (cat != "" and t.cat != cat):
			continue
		var can: bool = t.key == form
		if t.is_reel():
			for o in t.reel_opts:
				if Latin.reel_form(t.reel_base, o) == form:
					can = true
		if can and (not need_click or _clickable(t)):
			return t
	return null


## Turn a windowed ending's reel until it shows this form.
func _set_form(t: Tile, form: String) -> void:
	if not t.is_reel() or t.key == form:
		return
	for i in t.reel_opts.size():
		if Latin.reel_form(t.reel_base, t.reel_opts[i]) == form:
			_rechoose(t, i - t.choice)
			t.gen_amt = t.gen_goal # (test/demo: no waiting for parts to slide out)
			t.port_amt = t.port_goal
			if is_instance_valid(t.cord):
				t.cord.emerge = 1.0
			t._apply_parts()
			return


func _clickable(t: Tile) -> bool:
	var hit := _ray(_src_pos(t))
	if hit.is_empty():
		return false
	var col: Object = hit["collider"]
	return (col.has_meta("tile") and col.get_meta("tile") == t) or (t.loose_body != null and col == t.loose_body)


## A loose stem (tray) or ending (drawer, opened if needed) the mouse can reach,
## with an ending's window already turned to the asked-for form.
func _source(kind: String, key: String, cat := "") -> Tile:
	if kind == "ending":
		var any := _ending_piece(key, cat)
		if any == null:
			return null
		var i: int = any.get_meta("drawer_i", _drawer_for(any.cat))
		if not drawers[i]["open"]:
			_toggle_drawer(i)
			await get_tree().create_timer(1.2).timeout
		var t := _ending_piece(key, any.cat, true)
		if t:
			_set_form(t, key)
			await get_tree().create_timer(0.3).timeout
		if t == null or not _clickable(t): # buried or rolled behind the front: (test only) set one in the middle
			t = _ending_piece(key, any.cat)
			_set_form(t, key)
			var dn: Node3D = drawers[i]["node"]
			t.loose_body.global_position = dn.global_transform * Vector3(0.0, 0.05, 0.05)
			t.loose_body.global_basis = dn.global_basis
			t.loose_body.linear_velocity = Vector3.ZERO
			t.loose_body.angular_velocity = Vector3.ZERO
			await get_tree().create_timer(0.6).timeout
		return t
	for t in loose.filter(func(x): return is_instance_valid(x)):
		if t.key == key and t.kind == kind and _clickable(t):
			return t
	for t in loose.filter(func(x): return is_instance_valid(x)): # buried under others: (test only) lift one onto the top of the pile
		if t.key == key and t.kind == kind and t.loose_body:
			t.loose_body.global_position = TRAY_POS + Vector3(0.15, 0.25, 0.3)
			t.loose_body.rotation = Vector3.ZERO
			t.loose_body.linear_velocity = Vector3.ZERO
			await get_tree().create_timer(1.0).timeout
			return t if _clickable(t) else null
	return null


func _src_pos(t: Tile) -> Vector2:
	if t.is_rod:
		return _screen(t.global_transform * Vector3(0, Tile.AXIS_Y, 0))
	return _screen(t.global_position)


func _drag(from: Vector2, to: Vector3, whole := false, want: Tile = null) -> void:
	if want:
		_grab(want, whole)
	else:
		_press(from, whole)
	await _carry(to)
	_drop()
	await get_tree().create_timer(0.45).timeout


## Test helper: pick up exactly this piece (the whole word if `whole`). Clicks
## it if the click would really land on it; otherwise picks it up directly.
func _grab(e: Tile, whole := false) -> void:
	var sp := _screen(e.global_transform * Vector3(0, Tile.AXIS_Y if e.is_rod else 0.0, 0))
	var hit := _ray(sp)
	if not hit.is_empty() and hit["collider"].has_meta("tile") and hit["collider"].get_meta("tile") == e:
		_press(sp, whole)
	if dragging == null or not e in dragging.tiles or (not whole and dragging.tiles.size() > 1 and e.kind == "ending"):
		if dragging:
			_release()
		if e.in_tray:
			_begin_drag(_take_loose(e), sp)
		else:
			_begin_drag(_extract(e, whole), sp)


## Test helper: carry the held piece up, over and down to `to` (it can't go
## through things, so it has to be lifted out of drawers and over walls).
func _carry(to: Vector3) -> void:
	if dragging == null:
		return
	var cur := dragging.position + dragging.quaternion * grab_local
	var high := maxf(cur.y, to.y) + 0.17
	# up, out to the clear front of the bench, across, back in, and down
	var lane := 0.7
	for wp: Vector3 in [Vector3(cur.x, high, cur.z), Vector3(cur.x, high, lane), Vector3(to.x, high, lane), Vector3(to.x, high, to.z), to]:
		hold_dist = camera.global_position.distance_to(wp)
		for f in 12: # the held piece eases toward where you aim: give it time to get there
			_drag_to(_screen(wp))
			await get_tree().process_frame


func _at_left(x: float, w: float, z: float) -> Vector3:
	return Vector3(x + w * 0.5, TABLE_Y, z)


func _table_text() -> String:
	var out := PackedStringArray()
	for c in chunks:
		out.append("[%s] %s %s" % [c.analysis.get("latin", "?"), c.analysis.get("status", ""), c.analysis.get("msg", "")])
	return " | ".join(out)


## Test helper: pick up a plug, bring it over a hole, then push it in along the hole.
func _plug_drag(cd: Cord, target: Tile, ti := 0) -> void:
	_press(_screen(cd.plug.global_transform * Vector3(cd.boot().x * 0.5, 0, 0)), false)
	if held_cord != cd: # (test only) the click landed on something else: take hold of it directly
		if dragging:
			_release()
		held_cord = cd
		cd.socket_tile = null
		cd.held = true
	var S := Cord.socket_xf(target, ti)
	var mm := InputEventMouseMotion.new()
	for x in [0.3, 0.2, 0.12, 0.08, 0.06, 0.045, 0.035, 0.025, 0.015, 0.005, -0.01]:
		mm.position = _screen(S * Vector3(x, 0, 0))
		_unhandled_input(mm)
		await get_tree().create_timer(0.25 if x > 0.1 else 0.12).timeout
		if OS.get_environment("DBGF") != "" and ti > 0 and held_cord:
			var cl := Cord.socket_xf(target, ti).affine_inverse() * held_cord.free_xf.origin
			print("   dbg star x=", x, " target=", plug_target == target, " ti=", plug_target_i, " cl=", cl.snappedf(0.001), " ang=", snappedf(held_cord.free_xf.basis.x.dot(Cord.socket_xf(target, ti).basis.x), 0.0001), " lit=", target in snap_lit)
	_release()
	await get_tree().create_timer(0.3).timeout


## Test helper: feed an ending onto the end of a word's stem, pushing it along
## the stem's axis like a plug. Returns true if it went on.
func _feed_drag(e: Tile, c: Chunk) -> bool:
	var stem: Tile = c.tiles.back()
	_grab(e)
	if dragging == null:
		return false
	var d := dragging
	var seat := Chunk.seat(stem, e)
	var travel: float = seat["contact"] - seat["x"]
	var xs := [0.3, 0.2, 0.12, 0.08, 0.06, 0.04, 0.025, 0.012, 0.0, -travel * 0.5, -travel - 0.01]
	for x in xs:
		if dragging == null:
			break
		var S := Transform3D(stem.global_basis.orthonormalized(), stem.global_position)
		var L: float = seat["contact"] + x
		var p := S * Vector3(L, -Tile.H * 0.5, 0) + c.quaternion * grab_local
		hold_dist = camera.global_position.distance_to(p)
		_drag_to(_screen(p))
		for f in 8:
			await get_tree().process_frame
		if OS.get_environment("DBGF") != "" and owned_by.has(c) and dragging:
			var Sx := Transform3D(stem.global_basis.orthonormalized(), stem.global_position)
			print("   dbg feed x=", snappedf(x, 0.001), " cur=", (Sx.affine_inverse() * (dragging.position + Vector3(0, Tile.H * 0.5, 0))).snappedf(0.001), " align=", snappedf((dragging.quaternion * Vector3.RIGHT).dot(Sx.basis.x), 0.0001), " upd=", snappedf((dragging.quaternion * Vector3.UP).dot(Sx.basis.y), 0.001), " contact=", seat["contact"])
	if dragging == d:
		_release()
	await get_tree().create_timer(0.4).timeout
	return e.get_parent() == c


## Test helper: grab an ending that's on a word and slide it back off the stem.
func _pull_off(e: Tile) -> Chunk:
	var c: Chunk = e.get_parent()
	var stem: Tile = c.tiles[c.tiles.find(e) - 1]
	_grab(e)
	var d := dragging
	for x in [0.02, 0.06, 0.12, 0.2, 0.25]:
		var S := Transform3D(stem.global_basis.orthonormalized(), stem.global_position)
		var pp := S * Vector3(stem.width * 0.5 + x, -Tile.H * 0.5, 0) + d.quaternion * grab_local
		hold_dist = camera.global_position.distance_to(pp)
		_drag_to(_screen(pp))
		for f in 6:
			await get_tree().process_frame
	# then carry it well away and put it down
	hold_dist = camera.global_position.distance_to(Vector3(0.45, TABLE_Y, -0.3))
	_drag_to(_screen(Vector3(0.45, TABLE_Y, -0.3)))
	for f in 4:
		await get_tree().process_frame
	_release()
	await get_tree().create_timer(0.3).timeout
	return d


func _self_test() -> void:
	get_tree().create_timer(200.0).timeout.connect(get_tree().quit)
	await get_tree().create_timer(3.0).timeout
	# build puella, puerum, amat: stems from the tray, endings fed on from the drawers
	var spots := [Vector3(-0.45, TABLE_Y, 0.5), Vector3(0.3, TABLE_Y, 0.55), Vector3(-0.2, TABLE_Y, 0.0)]
	var words := [["puell", "a"], ["puer", "um"], ["ama", "t"]]
	var made := []
	var fed := []
	for k in 3:
		var st: Tile = await _source("stem", words[k][0])
		if st == null:
			print("SKIP: no clickable ", words[k][0])
			get_tree().quit()
			return
		await _drag(_src_pos(st), spots[k], false, st)
		var c: Chunk = st.get_parent()
		var src: Tile = await _source("ending", words[k][1])
		await _drag(_src_pos(src), spots[k] + Vector3(c.width + 0.3, 0, 0.0), false, src)
		fed.append(await _feed_drag(src, c))
		made.append(c)
	print("T1 endings fed on: ", fed, "  words: ", _table_text())
	print("T2 computer unplugged: ", _scene()["state"])
	await _plug_drag(disp_cord, made[2].tiles[0])
	print("T2b computer cable into amat: plugged=", disp_cord.socket_tile == made[2].tiles[0], "  ", JSON.stringify(_scene()))
	await _plug_drag(made[0].tiles[1].cord, made[2].tiles[1])
	print("T3 subject plugged: ", JSON.stringify(_scene()))
	await _plug_drag(made[2].tiles[0].cord, made[1].tiles[1])
	print("T4 object plugged: ", JSON.stringify(_scene()))
	# the board's first picture is "puella puerum amat": the computer checks by itself
	await get_tree().create_timer(0.5).timeout
	print("T4b the computer checked the matching scene by itself: board moved on=", board_i >= 1, "  verdict ", verdict_ok)
	# take -t off (the subject cable goes with it) and feed -unt on instead
	var t_end: Tile = made[2].tiles[1]
	await _pull_off(t_end)
	var unt: Tile = await _source("ending", "unt")
	await _drag(_src_pos(unt), Vector3(0.3, TABLE_Y, -0.05), false, unt)
	var ok_unt := await _feed_drag(unt, made[2])
	print("T5 -t pulled off, -unt fed on: ", ok_unt, "  ", JSON.stringify(_scene()))
	var sg: Cord = made[0].tiles[1].cord
	await _plug_drag(sg, made[2].tiles[1])
	var gap := (Cord.socket_xf(made[2].tiles[1]).affine_inverse() * sg.free_xf.origin).x
	print("T5b one-prong puella into two-slot -unt: went in=", sg.socket_tile == made[2].tiles[1], "  stopped at the face: ", gap >= sg.plen() - 0.002)
	# a wrong ending stops dead against the stem's end
	var wrong: Tile = await _source("ending", "ae")
	await _drag(_src_pos(wrong), Vector3(0.5, TABLE_Y, 0.3), false, wrong)
	var lone := _new_chunk([_take_tile(_loose_of("vide"))], Vector3(-0.1, TABLE_Y, -0.5))
	var went := await _feed_drag(wrong, lone)
	print("T6 noun ending -ae won't go onto the verb stem vid-: ", not went)
	_discard(lone) # clear it away so it doesn't attract later endings
	# puer on its own is a nominative: its cable comes out of its right end
	var puer2 := _new_chunk([_take_tile(_loose_of("puer"))], Vector3(-0.55, TABLE_Y, -0.25))
	var pcd: Cord = puer2.tiles[0].cord
	await get_tree().create_timer(0.3).timeout
	print("T7 bare puer has a subject cable: ", pcd != null and pcd.visible)
	var us: Tile = await _source("ending", "um")
	if us:
		await _drag(_src_pos(us), Vector3(0.0, TABLE_Y, -0.35), false, us)
		await _feed_drag(us, puer2)
		await get_tree().create_timer(0.3).timeout
		print("T8 ending fed onto puer covers its cable: hidden=", not pcd.visible, "  word ", puer2.analysis.get("latin", "?"))
	# shove: carry a word into another one and it gets knocked aside
	var a: Chunk = made[0]
	var b: Chunk = made[1]
	var b0 := b.position
	_grab(a.tiles[0], true)
	var grab_off := (a.position + a.quaternion * grab_local) - a.transform * Vector3(a.width * 0.5, 0, 0)
	var bc := b.transform * Vector3(b.width * 0.5, 0, 0)
	for k in 20:
		var ac := a.transform * Vector3(a.width * 0.5, 0, 0)
		var tgt := ac.lerp(bc, 0.3) + grab_off
		tgt.y = TABLE_Y
		hold_dist = camera.global_position.distance_to(tgt)
		_drag_to(_screen(tgt))
		await get_tree().process_frame
	_release()
	print("T9 knocked out of the way: moved ", snappedf(b.position.distance_to(b0), 0.01), "  still overlapping: ", _overlap(a, b) != Vector3.ZERO)
	# rotation by trackpad still turns the cable-connected group
	var q_verb: Quaternion = made[2].quaternion
	var pg := InputEventPanGesture.new()
	pg.position = _screen(made[2].tiles[0].global_transform * Vector3(0, Tile.AXIS_Y, 0))
	for k in 6:
		pg.delta = Vector2(-0.6, 0)
		_unhandled_input(pg)
		await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	print("T10 scrolling over a word on the bench doesn't turn it: ", snappedf(rad_to_deg(made[2].quaternion.angle_to(q_verb)), 0.1), " deg")
	# feeding onto a turned word still works (the ending lines itself up)
	var off: Chunk = await _pull_off(made[2].tiles[1])
	if is_instance_valid(off): # set it aside so it isn't in the way
		_discard(off)
	await _drag(_src_pos(t_end), Vector3(0.45, TABLE_Y, 0.1))
	print("T11 ending fed onto a turned word: ", await _feed_drag(t_end, made[2]))
	# computer: search tab, type, deliver down the chute into the tray
	_set_tab("search")
	for ch in "aud":
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.unicode = ch.unicode_at(0)
		_unhandled_input(ev)
	var n_before := tray_count("audi")
	var enter := InputEventKey.new()
	enter.pressed = true
	enter.keycode = KEY_ENTER
	_unhandled_input(enter)
	await get_tree().create_timer(3.0).timeout
	var arrived := false
	for t in loose.filter(func(x): return is_instance_valid(x)):
		if t.key == "audi" and absf(t.global_position.x - TRAY_POS.x) < TRAY_W * 0.5 and absf(t.global_position.z - TRAY_POS.z) < TRAY_D * 0.5 and t.global_position.y < TABLE_Y + 0.2:
			arrived = true
	print("T12 search 'aud' + Enter: results ", _results().size(), "  delivered ", tray_count("audi") - n_before, "  landed in the tray: ", arrived)
	_set_tab("scene")
	var n_end := 0
	for t in loose.filter(func(x): return is_instance_valid(x)):
		if t.kind == "ending":
			n_end += 1
	for c in chunks:
		for t: Tile in c.tiles:
			if t.kind == "ending":
				n_end += 1
	var n_made := 0
	for info in Latin.DRAWERS:
		for e in info["endings"]:
			n_made += 3 if e.ends_with("~") else COPIES
	print("T13 endings are finite (%d made, 1 set aside by the test): " % n_made, n_end)
	var worst := 0.0
	for cd2 in cords:
		if not is_instance_valid(cd2) or not cd2.visible or cd2.path.is_empty() or cd2.owner_tile.in_tray:
			continue
		for j in range(2, cd2.path.size() - 2):
			for bx in _solid_boxes(null):
				var q: Vector3 = bx[0].basis.transposed() * (cd2.path[j] - bx[0].origin)
				var h: Vector3 = bx[1]
				var pen := minf(h.x - absf(q.x), minf(h.y - absf(q.y), h.z - absf(q.z)))
				if pen > 0.001 and OS.get_environment("DBGF") != "":
					print("   dbg T14 cable ", cd2.kind, " of ", cd2.owner_tile.key, " point ", j, "/", cd2.path.size(), " in box at ", bx[0].origin.snappedf(0.01), " by ", snappedf(pen, 0.001), " socket ", cd2.socket_tile.key if cd2.socket_tile else "-")
				worst = maxf(worst, pen)
	print("T14 deepest cable point inside a piece: ", snappedf(worst * 1000.0, 0.1), " mm")
	# the a-ending's window: scroll it on the word and the word changes
	var pa: Tile = made[0].tiles[1]
	var forms := [pa.key]
	var had_cable := pa.cord != null
	var w0 := pa.width
	for k in pa.reel_opts.size():
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP
		wheel.pressed = true
		var wx := (pa.win_x.x + pa.win_x.y) * 0.5 if not pa.collapsed() else 0.0
		wheel.position = _screen(pa.global_transform * Vector3(wx, Tile.H * 0.5, 0))
		var key0 := pa.key
		_unhandled_input(wheel)
		var mid := pa.key # the ending must not change while the reel is still turning
		await get_tree().create_timer(0.7).timeout
		if mid != key0:
			print("   T15 changed before the reel settled!")
		if pa.key == key0 and OS.get_environment("DBGF") != "":
			var hh := _ray(wheel.position)
			print("   dbg T15 notch missed: kind ", hh["collider"].get_meta("kind", "?") if not hh.is_empty() else null, " tile_layer=", pa.body.collision_layer, " pos=", pa.global_position, " basis=", pa.global_basis.y, " plug=", hh["collider"].has_meta("plug") if not hh.is_empty() else false, " cool=", reel_cool)
		forms.append(made[0].analysis.get("latin", "?") + (" (" + str(snappedf(pa.width, 0.001)) + ")" if pa.collapsed() else ""))
	print("T15 scrolling puella's window: ", forms, "  nom cable at -a: ", had_cable, "  collapsed to ā narrower: ", w0)
	# search is by stem
	query = "aud"
	print("T16 search 'aud': ", _results())
	query = ""
	# picking up really lifts the piece; letting go over the bin throws it away
	var vic: Chunk = made[1]
	_grab(vic.tiles[0], true)
	await get_tree().process_frame
	await get_tree().process_frame
	var lifted := vic.position.y - TABLE_Y
	await _carry(TRASH_POS + Vector3(-vic.width * 0.4, TRASH_H + 0.12, 0))
	if OS.get_environment("DBGF") != "":
		print("   dbg T17 vic at ", vic.position.snappedf(0.01), " held ", dragging == vic)
	var over_bin: String = _surface_at(vic.position + Vector3(vic.width * 0.5, 0, 0))["kind"]
	_release()
	await get_tree().create_timer(0.6).timeout
	print("T17 picked-up word lifted ", snappedf(lifted, 0.001), " off the bench;  held over: ", over_bin, "  thrown in the bin: gone=", not is_instance_valid(vic))
	# WASD walks the view
	var c0 := camera.global_position
	# collisions: a held piece can't be pushed down through the bench or into the monitor
	var probe_st: Tile = await _source("stem", "agricol")
	if probe_st:
		await _drag(_src_pos(probe_st), Vector3(-0.3, TABLE_Y, 0.3))
		_press(_screen(probe_st.global_position), false)
		await get_tree().process_frame
		var pc: Chunk = dragging
		hold_dist = camera.global_position.distance_to(Vector3(-0.3, TABLE_Y - 0.3, 0.3))
		_drag_to(_screen(Vector3(-0.3, TABLE_Y - 0.3, 0.3)))
		var low := INF # lowest corner of the held piece
		for t: Tile in pc.tiles:
			var hx := t.box_half()
			for cx in [-1, 1]:
				for cy in [-1, 1]:
					for cz in [-1, 1]:
						low = minf(low, (t.global_transform * (t.shape_offset() + Vector3(cx * hx.x, cy * hx.y, cz * hx.z))).y)
		low += 0.0
		var mon := Vector3(0.36, TABLE_Y + 0.35, -0.6)
		await _carry(mon)
		var mp := pc.position + pc.quaternion * Vector3(pc.width * 0.5, 0, 0)
		print("T19 held piece pushed into the bench stops on top: ", snappedf(low - TABLE_Y, 0.001), "  pushed into the monitor stops in front of it: ", mp.z > -0.45, " (z ", snappedf(mp.z, 0.01), ")")
		_release()
		await get_tree().create_timer(0.6).timeout
	# genitive: rēx (a bare 3rd-decl. nominative) stood in puellae's holder
	var gst := _take_tile(_loose_of("puell"))
	var gen := _take_tile(_ending_piece("ae", "decl1"))
	_set_form(gen, "ae")
	var gw := _new_chunk([gst, gen], Vector3(-0.55, TABLE_Y, 0.15))
	_refresh(gw)
	var rex := _new_chunk([_take_tile(_loose_of("reg"))], Vector3(0.1, TABLE_Y, 0.35))
	_refresh(rex)
	print("T20 rēx alone reads: ", rex.analysis.get("latin", "?"), "  puellae has a holder: ", gen.gen_holder, "  its cable leaves the front: ", gen.cord_dir.z > 0.5)
	_grab(rex.tiles[0], true)
	var lit_far := false
	for f in 10: # aimed somewhere else: nothing lit
		_drag_to(_screen(Vector3(0.6, TABLE_Y, 0.6)))
		await get_tree().process_frame
	lit_far = float(gen.gen_mats[0].get_shader_parameter("highlight") if gen.gen_mats[0].get_shader_parameter("highlight") != null else 0.0) > 0.5
	for f in 10: # aimed at puellae's holder: it lights up
		_drag_to(_screen(gen.global_transform * gen.gen_slot()))
		await get_tree().process_frame
	var lit: bool = gen_lit == gen and float(gen.gen_mats[0].get_shader_parameter("highlight") if gen.gen_mats[0].get_shader_parameter("highlight") != null else 0.0) > 0.5
	_release() # one click puts it in
	await get_tree().create_timer(0.6).timeout
	print("T20b holder lit only when aimed at: ", lit and not lit_far, "  click put it in: owned=", owned_by.get(rex) == gen, "  standing up: ", snappedf(rad_to_deg(rex.global_basis.y.angle_to(Vector3.UP)), 1.0), " deg  light off: ", float(gen.gen_mats[0].get_shader_parameter("highlight") if gen.gen_mats[0].get_shader_parameter("highlight") != null else 0.0) < 0.5)
	var off0 := rex.global_position - gen.global_position
	_grab(gst, true)
	await _carry(Vector3(-0.2, TABLE_Y + 0.05, 0.3))
	_release()
	await get_tree().create_timer(0.6).timeout
	print("T23 puellae holding rēx draws its cable in: ", is_instance_valid(gen.cord) and gen.cord.emerge < 0.05, "  holder still out: ", gen.gen_open())
	print("T20c carrying puellae carries rēx along: ", (rex.global_position - gen.global_position).distance_to(off0) < 0.01, "  still owned: ", owned_by.get(rex) == gen)
	# lifted out of the holder it doesn't jump straight back; brought back close, it locks in
	_grab(rex.tiles[0], true)
	for f in 8:
		await get_tree().process_frame
	var stayed_out := not owned_by.has(rex)
	var away := gen.global_transform * gen.gen_slot() + Vector3(0.45, 0.25, 0.3)
	hold_dist = camera.global_position.distance_to(away)
	for f in 15:
		_drag_to(_screen(away))
		await get_tree().process_frame
	for f in 40:
		if dragging == null:
			break
		var sc := _owned_xf(gen, rex) * Vector3(rex.width * 0.5, Tile.H * 0.5, 0)
		hold_dist = camera.global_position.distance_to(sc)
		_drag_to(_screen(sc))
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	print("T24 lifted out, didn't snap back: ", stayed_out, "  brought close, locked in by itself: ", owned_by.get(rex) == gen and dragging == null)
	# an ending fed onto rēx while it stands in the holder
	var em: Tile = await _source("ending", "em", "decl3")
	var fed_ok := false
	if em:
		await _drag(_src_pos(em), Vector3(0.35, TABLE_Y, 0.0), false, em)
		fed_ok = await _feed_drag(em, rex)
		await get_tree().create_timer(0.4).timeout
	# picking up the genitive by its ending brings the whole word, and the word in its holder
	_press(_screen(gen.global_position), false)
	await get_tree().create_timer(0.3).timeout
	var faced := dragging != null and (dragging.quaternion * Vector3.UP).dot(camera.global_basis.z) > 0.9
	print("T28 picked puellae up by its ending: whole word=", dragging == gw, "  rēx still in its holder: ", owned_by.get(rex) == gen, "  held facing you: ", faced)
	if dragging:
		_release()
		await get_tree().create_timer(0.6).timeout
	print("T25 ending fed onto a word in a genitive holder: ", fed_ok, "  word ", rex.analysis.get("latin", "?"), "  still owned: ", owned_by.get(rex) == gen, "  still standing: ", snappedf(rad_to_deg(rex.global_basis.y.angle_to(Vector3.UP)), 1.0))
	# a plug brought up to a socket it fits and clicked goes in by itself
	var t26n := _new_chunk([_new_tile("stem", "puell"), _new_ending("decl1", "a")], Vector3(1.05, TABLE_Y, 0.05))
	var t26v := _new_chunk([_new_tile("stem", "ama"), _new_tile("ending", "t", "verb")], Vector3(1.05, TABLE_Y, -0.35))
	_refresh(t26n)
	_refresh(t26v)
	var pcd3: Cord = t26n.tiles[1].cord
	var vsock: Tile = t26v.tiles[1]
	if is_instance_valid(pcd3):
		for other in cords:
			if is_instance_valid(other) and other.socket_tile == vsock:
				other.socket_tile = null
				other.parked = true
		pcd3.socket_tile = null
		pcd3.parked = true
		await get_tree().create_timer(0.3).timeout
		_press(_screen(pcd3.plug.global_transform * Vector3(pcd3.boot().x * 0.5, 0, 0)), false)
		var S0 := Cord.socket_xf(vsock)
		var mm := InputEventMouseMotion.new()
		for x in [0.3, 0.2, 0.14, 0.1]: # stops short of the mouth
			mm.position = _screen(S0 * Vector3(x, 0, 0))
			_unhandled_input(mm)
			await get_tree().create_timer(0.25).timeout
		var was_in := pcd3.socket_tile == vsock
		if OS.get_environment("DBGF") != "":
			print("   dbg T26 held=", held_cord == pcd3, " held_cord=", held_cord, " target=", plug_target, " vsock=", vsock, " lit=", plug_target in snap_lit, " fits=", pcd3.fits(vsock), " taken=", _socket_taken(vsock, pcd3), " origin_local=", (Cord.socket_xf(vsock).affine_inverse() * pcd3.free_xf.origin).snappedf(0.001))
		_release()
		await get_tree().create_timer(0.5).timeout
		print("T26 plug lined up short of the socket, clicked: connected=", pcd3.socket_tile == vsock, " (not in before the click: ", not was_in, ")")
	var bi := board_i
	var wrong_ok := _judge({"state": "scene", "verb": "ama", "person": 3, "vnum": "pl", "subj": null, "obj": null})
	var after_wrong := board_i
	var want_sc: Dictionary = board_list[board_i].duplicate()
	want_sc["state"] = "scene"
	var right := _judge(want_sc)
	print("T27 board: a different scene is rejected: ", not wrong_ok and after_wrong == bi, "  the matching one accepted: ", right, "  showing ", board_count.text)
	# shared endings: -is fits I and II but not III; -ibus fits III and IV but not I
	print("T29 -is on puell-/domin-/reg-: ", Latin.combine("puell", "decl12", "is")["ok"], "/", Latin.combine("domin", "decl12", "is")["ok"], "/", Latin.combine("reg", "decl12", "is")["ok"],
			"   -ibus on reg-/man-/puell-: ", Latin.combine("reg", "decl34", "ibus")["ok"], "/", Latin.combine("man", "decl34", "ibus")["ok"], "/", Latin.combine("puell", "decl34", "ibus")["ok"],
			"   reads: ", Latin.combine("puell", "decl12", "is")["latin"], " ", Latin.combine("reg", "decl34", "ibus")["latin"])
	# drawers: what's in them isn't attached; they're just solid boxes that push things
	var di := _drawer_for("decl2")
	var dn: Node3D = drawers[di]["node"]
	var z0: float = drawers[di]["closed"].z
	if not drawers[di]["open"]:
		_toggle_drawer(di)
	await get_tree().create_timer(1.6).timeout
	var inside := 0
	var free := 0
	var reach := 0
	for t: Tile in loose:
		if t.cat == "decl2" and t.loose_body:
			inside += 1
			if t.loose_body.get_parent() == self:
				free += 1
			if t.loose_body.global_position.z > 0.9:
				reach += 1
	print("T21 drawer slid out ", snappedf(dn.position.z - z0, 0.01), "  parts not attached to it: ", free, "/", inside, "  parts out past the bench edge: ", reach)
	_toggle_drawer(di)
	await get_tree().create_timer(1.2).timeout
	# 5th decl. -ēs: a singular AND a plural subject cable
	var res_t := _new_tile("stem", "r")
	var es := _new_tile("ending", "e~", "decl5")
	_set_form(es, "es")
	var rw := _new_chunk([res_t, es], Vector3(-0.5, TABLE_Y, -0.3))
	_refresh(rw)
	var sg_slot := _new_tile("ending", "t", "verb")
	var pl_slot := _new_tile("ending", "unt", "verb")
	var prongs := []
	for x: Cord in es.cords_out:
		prongs.append([x.kind, x.prongs])
	print("T30 rēs: cables ", prongs, "  sg cable fits -t: ", es.cords_out[0].fits(sg_slot), " not -unt: ", not es.cords_out[0].fits(pl_slot),
			"  pl cable fits -unt: ", es.cords_out[1].fits(pl_slot), "  has acc socket: ", es.socket_kind)
	sg_slot.queue_free()
	pl_slot.queue_free()
	# a verb with star holes; procul plugged in by hand, ad + rīvum by hand too
	var vb := _new_chunk([_new_tile("stem", "curr"), _new_tile("ending", "t", "verb")], Vector3(0.75, TABLE_Y, 0.2))
	_refresh(vb)
	var pc_w := _new_chunk([_new_tile("stem", "procul")], Vector3(0.7, TABLE_Y, 0.6))
	var ad_w := _new_chunk([_new_tile("stem", "ad")], Vector3(1.05, TABLE_Y, 0.6))
	var riv_end := _new_tile("ending", "u~", "decl2")
	_set_form(riv_end, "um")
	var rv := _new_chunk([_new_tile("stem", "riv"), riv_end], Vector3(1.2, TABLE_Y, 0.2))
	_refresh(rv)
	for cd_old in cords: # the computer shows this verb
		pass
	disp_cord.socket_tile = vb.tiles[0]
	disp_cord.socket_i = 0
	await get_tree().create_timer(0.8).timeout
	print("T31 verb stem holes: ", vb.tiles[0].sock_count() - 1, " star  ad's cables: ", ad_w.tiles[0].cords_out.map(func(x): return x.kind), "  in's: ", Latin.STEMS["in"]["cases"])
	await _plug_drag(pc_w.tiles[0].cord, vb.tiles[0], 1)
	print("T32 procul's star plug pushed into the verb: in=", pc_w.tiles[0].cord.socket_tile == vb.tiles[0], "  scene mods ", JSON.stringify(_scene().get("mods")))
	await _plug_drag(ad_w.tiles[0].cords_out[0], vb.tiles[0], 2)
	await _plug_drag(ad_w.tiles[0].cords_out[1], riv_end)
	var sc2 := _scene()
	print("T33 ad's star in: ", ad_w.tiles[0].cords_out[0].socket_tile == vb.tiles[0], "  square into rīvum's -um: ", ad_w.tiles[0].cords_out[1].socket_tile == riv_end, "  mods ", JSON.stringify(sc2.get("mods")), " state ", sc2["state"])
	print("T34 words: aspicit=", Latin.combine("aspici", "verb", "t")["latin"], " arrigit=", Latin.combine("arrig", "verb", "t")["latin"], " inspīrat=", Latin.combine("inspira", "verb", "t")["latin"],
			" aspiciunt=", Latin.combine("aspici", "verb", "unt")["latin"], "  lītora ok=", Latin.combine("litor", "neut", "a")["ok"], " lītorem refused=", not Latin.combine("litor", "decl3", "em")["ok"],
			" aurum refused=", not Latin.combine("aur", "decl3", "um")["ok"], " nihil+is refused=", not Latin.combine("nihil", "decl12", "is")["ok"],
			"  lītus bare has acc hole: ", _new_tile("stem", "litor").socket_kind, "  -e has abl hole: ", _new_tile("ending", "e", "decl3").socket_kind, "  -is (I·II) has abl hole: ", _new_tile("ending", "is", "decl12").socket_kind)
	# scrolling while holding a piece turns it in your hands (and doesn't push it away)
	var spun := _new_chunk([_new_tile("stem", "riv")], Vector3(0.9, TABLE_Y, 0.5))
	_grab(spun.tiles[0], true)
	for f in 20:
		await get_tree().process_frame
	var q0 := spun.quaternion
	var hd := hold_dist
	for k in 6:
		var wh := InputEventMouseButton.new()
		wh.button_index = MOUSE_BUTTON_WHEEL_UP
		wh.pressed = true
		_unhandled_input(wh)
	for f in 30:
		await get_tree().process_frame
	print("T35 held piece scrolled: turned ", snappedf(rad_to_deg(spun.quaternion.angle_to(q0)), 1.0), " deg  hold distance unchanged: ", is_equal_approx(hd, hold_dist), " (", hold_dist, " m)")
	_release()
	await get_tree().create_timer(0.5).timeout
	# a masculine ending pushed onto a neuter: sparks, smoke, and it's thrown off
	var pw := _new_chunk([_new_tile("stem", "pocul")], Vector3(0.75, TABLE_Y, -0.2))
	_refresh(pw)
	var bad := _new_ending("decl2", "us")
	var bad_c := _new_chunk([bad], Vector3(1.0, TABLE_Y, -0.05))
	_refresh(bad_c)
	await get_tree().create_timer(0.3).timeout
	var tip: Vector3 = pw.tiles[0].global_transform * Vector3(pw.tiles[0].width * 0.5, 0, 0)
	await _feed_drag(bad, pw)
	await get_tree().create_timer(0.2).timeout
	var flew: bool = bad.in_tray and bad.global_position.distance_to(tip) > 0.12
	var smoke := 0
	for ch in get_children():
		if ch is CPUParticles3D:
			smoke += 1
	print("T36 -us on pōcul-: stayed off=", bad.get_parent() != pw, "  thrown off flying=", flew, "  sparks+smoke emitters=", smoke)
	# adapters: N·SG makes pōculum (-um) a subject; N·PL makes carmina (-a) an object; MODVS takes an ablative
	var good := _new_ending("decl2", "um")
	var pocw := _new_chunk([_new_tile("stem", "pocul"), good], Vector3(-0.6, TABLE_Y, 0.55))
	var cadw := _new_chunk([_new_tile("stem", "cad"), _new_tile("ending", "t", "verb")], Vector3(-0.2, TABLE_Y, 0.4))
	var nsg := _new_chunk([_new_tile("adapter", "neut_sg")], Vector3(-0.4, TABLE_Y, 0.7))
	for c in [pocw, cadw, nsg]:
		_refresh(c)
	nsg.tiles[0].cords_out[0].socket_tile = good
	nsg.tiles[0].cords_out[1].socket_tile = cadw.tiles[1]
	disp_cord.socket_tile = cadw.tiles[0]
	disp_cord.socket_i = 0
	await get_tree().create_timer(0.4).timeout
	var s1 := _scene()
	var carw := _new_chunk([_new_tile("stem", "carmin"), _new_ending("neut", "a")], Vector3(0.6, TABLE_Y, 0.65))
	var audw := _new_chunk([_new_tile("stem", "audi"), _new_tile("ending", "t", "verb")], Vector3(0.3, TABLE_Y, 0.45))
	var npl := _new_chunk([_new_tile("adapter", "neut_pl")], Vector3(0.55, TABLE_Y, 0.85))
	var hw := _new_chunk([_new_tile("stem", "harundin"), _new_ending("decl3", "e")], Vector3(0.0, TABLE_Y, 0.8))
	var mod := _new_chunk([_new_tile("adapter", "modi")], Vector3(0.2, TABLE_Y, 0.85))
	for c in [carw, audw, npl, hw, mod]:
		_refresh(c)
	carw.tiles[1].cord.socket_tile = npl.tiles[0]
	audw.tiles[0].cord.socket_tile = npl.tiles[0]
	audw.tiles[0].cord.socket_i = 1
	mod.tiles[0].cords_out[0].socket_tile = hw.tiles[1]
	mod.tiles[0].cords_out[1].socket_tile = audw.tiles[0]
	mod.tiles[0].cords_out[1].socket_i = 1
	disp_cord.socket_tile = audw.tiles[0]
	await get_tree().create_timer(0.4).timeout
	var s2 := _scene()
	print("T37 pōculum (-um) + N·SG as subject: ", JSON.stringify(s1.get("subj")), " ", s1["state"], "   carmina (-a) + N·PL as object: ", JSON.stringify(s2.get("obj")),
			"  MODVS harundine: ", JSON.stringify(s2.get("mods")), " ", s2["state"], "  -a has no acc hole: ", carw.tiles[1].socket_kind == "")
	# sentence reconstruction: start it from the bulletin board, the first set comes down the chute soldered
	var mine_before := chunks.filter(func(c): return c.tiles.any(func(t): return t.kind == "stem")).size()
	_start_challenge()
	await get_tree().create_timer(0.6).timeout
	var mine_after := chunks.filter(func(c): return c.tiles.any(func(t): return t.kind == "stem")).size()
	_set_tab("search")
	var search_locked := screen_tab == "scene"
	print("T43 starting the challenge: your words on the bench ", mine_before, " -> ", mine_after, "  search locked: ", search_locked)
	for f in 80:
		if chute_queue.is_empty() and chal_words.size() == 3:
			break
		await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(2.0).timeout
	if OS.get_environment("DBGF") != "":
		print("   dbg chute queue=", chute_queue.size(), " wait=", chute_wait, " chal_on=", chal_on)
		for c in chal_words:
			var rb = c.get_parent()
			print("   dbg word ", c.tiles[0].key, " at ", (c.tiles[0].global_position).snappedf(0.01), " loose=", c.tiles[0].in_tray, " vel=", (rb.linear_velocity.length() if rb is RigidBody3D else -1.0), " sleeping=", (rb.sleeping if rb is RigidBody3D else false))
	var got := chal_words.map(func(c): return c.analysis.get("latin", "?") if is_instance_valid(c) else "?")
	var sold: bool = chal_words.size() > 0 and chal_words[0].tiles.back().soldered
	var in_tray := 0
	for c in chal_words:
		if c.tiles[0].in_tray:
			in_tray += 1
	# a soldered ending can't be pulled off: clicking it takes the whole word
	var pa_w: Chunk = chal_words[0]
	var pa_e: Tile = pa_w.tiles.back()
	_grab(pa_e, false)
	var whole_w: bool = dragging != null and pa_w.tiles.size() == 2
	# put it down by looking at a spot on the bench: it goes there
	var spot := Vector3(-0.5, TABLE_Y, 0.35)
	_drag_to(_screen(spot))
	for f in 10:
		await get_tree().process_frame
	_release()
	await get_tree().create_timer(0.6).timeout
	var placed := (pa_w.transform * Vector3(pa_w.width * 0.5, 0, 0)).distance_to(spot)
	print("T38 challenge set 1 delivered: ", got, "  soldered: ", sold, "  landed in the tray: ", in_tray, "/", chal_words.size(), "  ending click took whole word: ", whole_w, "  set down where looked: ", snappedf(placed, 0.01), " m off")
	# build it (cables by hand): puella -> amat <- puerum
	var ws := {}
	for c in chal_words:
		if c.tiles[0].in_tray:
			_take_loose(c.tiles[0])
		ws[c.tiles[0].key] = c
	ws["puell"].position = Vector3(-0.6, TABLE_Y, 0.2)
	ws["ama"].position = Vector3(-0.2, TABLE_Y, 0.0)
	ws["puer"].position = Vector3(0.2, TABLE_Y, 0.2)
	ws["puell"].tiles[1].cord.socket_tile = ws["ama"].tiles[1]
	ws["ama"].tiles[0].cord.socket_tile = ws["puer"].tiles[1]
	disp_cord.socket_tile = ws["ama"].tiles[0]
	disp_cord.socket_i = 0
	await get_tree().create_timer(3.8).timeout
	print("T39 set 1 built: next set=", chal_i == 1, "  next words arriving: ", chal_words.size() + chute_queue.size(), "  progress: ", hud_task.text if hud_task else "")
	# a long set (5 words) all makes it down the chute into the tray
	for f in 100:
		if chute_queue.is_empty():
			break
		await get_tree().create_timer(0.1).timeout
	for spec in CHALLENGE[8]:
		chute_queue.append(spec)
	for f in 150:
		if chute_queue.is_empty():
			break
		await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(2.5).timeout
	var landed := 0
	for c in chal_words:
		if is_instance_valid(c) and c.tiles[0].in_tray and absf(c.tiles[0].global_position.x - TRAY_POS.x) < TRAY_W * 0.5 \
				and absf(c.tiles[0].global_position.z - TRAY_POS.z) < TRAY_D * 0.5 and c.tiles[0].global_position.y < TABLE_Y + 0.25:
			landed += 1
	print("T44 every delivered word got down the chute into the tray: ", landed, "/", chal_words.size(),
			"   neuter -a: pōcula ", Latin.combine("pocul", "neut", "a")["ok"], " carmina ", Latin.combine("carmin", "neut", "a")["ok"], " puera refused ", not Latin.combine("puer", "neut", "a")["ok"],
			"  its drawer: ", drawers.filter(func(d): return d["id"] == "neut").size())
	# passive endings: forms for every kind of stem, and a passive scene with an agent
	var pforms := []
	for v in ["ama", "vide", "audi", "capi", "duc"]:
		var row := []
		for en in ["or", "eris", "itur", "imur", "imini", "untur"]:
			row.append(Latin.verb_form(v, en))
		pforms.append(" ".join(row))
	print("T40 passive forms: ", " | ".join(pforms))
	var pv := _new_chunk([_new_tile("stem", "capi"), _new_tile("ending", "itur", "verb")], Vector3(-0.4, TABLE_Y, -0.3))
	var pb := _new_chunk([_new_tile("stem", "puer")], Vector3(-0.9, TABLE_Y, -0.2))
	var abw := _new_chunk([_new_tile("stem", "ab")], Vector3(-0.5, TABLE_Y, 0.1))
	var lupo := _new_ending("decl2", "o")
	var lw := _new_chunk([_new_tile("stem", "lup"), lupo], Vector3(-0.1, TABLE_Y, 0.15))
	for c in [pv, pb, abw, lw]:
		_refresh(c)
	pb.tiles[0].cord.socket_tile = pv.tiles[1]
	abw.tiles[0].cords_out[0].socket_tile = pv.tiles[0]
	abw.tiles[0].cords_out[0].socket_i = 1
	abw.tiles[0].cords_out[1].socket_tile = lupo
	disp_cord.socket_tile = pv.tiles[0]
	disp_cord.socket_i = 0
	await get_tree().create_timer(0.4).timeout
	var ps := _scene()
	print("T41 puer ab lupō capitur: ", pv.analysis.get("latin", "?"), "  voice ", ps.get("voice"), " subj ", JSON.stringify(ps.get("subj")), " mods ", JSON.stringify(ps.get("mods")), " ", ps["state"],
			"  drawn as the wolf grabbing: ", JSON.stringify(PixelArt._activate(ps).get("subj")))
	query = "capi"
	var r1 := _results()
	query = "ama"
	var r2 := _results()
	query = ""
	print("T42 search shows the infinitive: ", r1[0][0], "  ", r2[0][0], "  passive drawer: ", drawers.filter(func(d): return d["id"] == "verbp").size() == 1)
	# first person: every staged verb draws through your own eyes (active and passive) without trouble
	var drawn := 0
	for v in PixelArt.ACT:
		for vo in ["act", "pass"]:
			var im := PixelArt.compose({"state": "scene", "verb": v, "person": 1, "vnum": "sg", "subj": null,
					"obj": {"stem": "puell", "num": "sg"} if vo == "act" else null, "mods": [], "voice": vo})
			if im.get_width() == PixelArt.W:
				drawn += 1
	var snd := 0
	for nm in ["seat", "plug", "lock", "click", "spark", "chime", "whoosh", "rattle", "slide"]:
		if Sfx.stream(nm).data.size() > 1000:
			snd += 1
	print("T45 first-person pictures drawn: ", drawn, "/", PixelArt.ACT.size() * 2, "   sounds made: ", snd, "/9")
	# a passive ending on: the verb's object cable goes back in (and comes out of any socket)
	var obj_w := _new_chunk([_new_tile("stem", "puer"), _new_ending("decl2", "um")], Vector3(0.6, TABLE_Y, 0.3))
	var pvb := _new_chunk([_new_tile("stem", "ama"), _new_tile("ending", "t", "verb")], Vector3(0.2, TABLE_Y, 0.1))
	_refresh(obj_w)
	_refresh(pvb)
	pvb.tiles[0].cord.socket_tile = obj_w.tiles[1]
	await get_tree().create_timer(0.3).timeout
	var t_old: Tile = pvb.tiles[1]
	pvb.tiles.erase(t_old)
	pvb.remove_child(t_old)
	t_old.queue_free()
	var pas_end := _new_tile("ending", "itur", "verb")
	pvb.add_child(pas_end)
	pvb.tiles.append(pas_end)
	pvb.layout(false)
	_refresh(pvb)
	await get_tree().create_timer(0.8).timeout
	var acc_c: Cord = pvb.tiles[0].cord
	print("T46 passive -itur on amā-: ", pvb.analysis.get("latin", "?"), "  object cable drawn in: ", acc_c.emerge < 0.05, "  unplugged: ", acc_c.socket_tile == null)
	# *puerus: -us pushed onto puer sparks off; and a neuter's reel scrolled to -us throws it off
	var pu2 := _new_chunk([_new_tile("stem", "puer")], Vector3(-0.6, TABLE_Y, 0.55))
	var us_e := _new_ending("decl2", "us")
	var us_c := _new_chunk([us_e], Vector3(-0.3, TABLE_Y, 0.75))
	_refresh(pu2)
	_refresh(us_c)
	await get_tree().create_timer(0.3).timeout
	await _feed_drag(us_e, pu2)
	var puerus_off: bool = us_e.get_parent() != pu2
	var nr := _new_ending("decl2", "um")
	var nw := _new_chunk([_new_tile("stem", "pocul"), nr], Vector3(0.0, TABLE_Y, 0.6))
	_refresh(nw)
	var us_i: int = nr.reel_opts.find("s")
	nr.reel_goal = float(us_i)
	nr.reel_idle = 1.0
	reel_spinning.append(nr)
	await get_tree().create_timer(1.2).timeout
	print("T47 *puerus sparks off: ", puerus_off, "   pōculum's reel turned to -us: thrown off=", nr.get_parent() != nw, " flying loose=", nr.in_tray, "  stem left: ", nw.tiles.size())
	# shake the mouse while looking into a drawer: everything in it upright, side by side, in order
	var vi := _drawer_for("verb")
	if not drawers[vi]["open"]:
		_toggle_drawer(vi)
	await get_tree().create_timer(1.3).timeout
	_organize(vi)
	await get_tree().create_timer(1.2).timeout
	var vdn: Node3D = drawers[vi]["node"]
	var inv := vdn.global_transform.affine_inverse()
	var upright := 0
	var ins := []
	for t: Tile in loose:
		if is_instance_valid(t) and t.loose_body and t.cat == "verb":
			var lp := inv * t.loose_body.global_position
			if absf(lp.x) < drawers[vi]["iw"] * 0.5 + 0.05 and absf(lp.z) < drawers[vi]["dd"] * 0.5 + 0.05:
				ins.append([lp.z, lp.x, t.key])
				if (t.loose_body.global_basis.x).dot(vdn.global_basis.x) > 0.99 and t.loose_body.global_basis.y.dot(Vector3.UP) > 0.99:
					upright += 1
	ins.sort()
	print("T48 verb drawer tidied: upright & parallel ", upright, "/", ins.size(), "  in order: ", ins.map(func(e): return e[2]))
	_toggle_drawer(vi)
	await get_tree().create_timer(1.1).timeout
	# hold the button and sweep the bench from left to right: it all goes in the bin
	var on_bench := chunks.size()
	sweep_on = true
	sweep_x0 = -1.0
	drag_mouse = _screen(Vector3(1.4, TABLE_Y, 0.2))
	_update_sweep()
	await get_tree().create_timer(2.0).timeout
	print("T49 swept the bench: pieces on it ", on_bench, " -> ", chunks.size())
	if OS.get_environment("DBGF") != "":
		for c in chunks:
			print("   dbg left: ", c.tiles.map(func(t): return t.key), " at ", c.global_position.snappedf(0.01), " dragging=", c == dragging, " owned=", owned_by.has(c))
	# the campaign: level I locks, sticky notes, one task at a time, money, level II
	save_path = "user://latin_garage_selftest.json" # (never touch the real save)
	Latin.level = 1
	campaign_on = true
	for ti in TUTORIALS.size(): # (past the tutorials: they're tested on their own below)
		notes_done[_note_key(ti + 1, "tut")] = true
	_apply_locks()
	query = ""
	var l1 := _results().map(func(r): return r[1])
	var d3: Dictionary = drawers.filter(func(d): return d["cat"] == "decl3")[0]
	var dact: Dictionary = drawers.filter(func(d): return d["id"] == "verb")[0]
	var dpas: Dictionary = drawers.filter(func(d): return d["id"] == "verbp")[0]
	var o_reel: Tile = null
	for t in loose:
		if is_instance_valid(t) and t.is_reel() and t.reel_base == "o" and t.cat == "decl2":
			o_reel = t
	var unt_ok := Chunk.validate([_new_tile("stem", "ama"), _new_tile("ending", "imus", "verb")])
	print("T50 level I: words ", l1, "  DECL.III locked=", d3["locked"], " ACTIVA locked=", dact["locked"], " PASSIVA locked=", dpas["locked"],
			"  -o/-os/-orum piece hidden=", o_reel != null and not o_reel.loose_body.visible, "  -mus refused: ", unt_ok.get("msg", "ok"),
			"  DECL.III drawer hidden=", not d3["node"].visible, " (blank panel ", d3["blank"].visible, ")")
	var a_reel := _new_ending("decl1", "a")
	var ar := _new_chunk([a_reel], Vector3(0.8, TABLE_Y, 0.5))
	a_reel.reel_goal = 1.0 # -am: not unlocked yet
	a_reel.reel_idle = 1.0
	reel_spinning.append(a_reel)
	await get_tree().create_timer(1.5).timeout
	print("T51 a reel turned to the locked -am skips on to an unlocked form: ", a_reel.key, "  locked options shown on its drum: ",
			a_reel.reel_labels.filter(func(l): return l.visible and not Latin.ending_unlocked("decl1", l.text) and not Latin.ending_unlocked("decl1", "a" + l.text)).size())
	_discard(ar)
	_open_note(1, "recon")
	var panel_up: bool = note_panel.visible and note_accept.text == "ACCIPE"
	_accept_open_note()
	var second := _accept_note(1, "picture")
	print("T52 note I/recon up close: ", panel_up, " (", note_title.text, ")  accepted: ", active_note, "  a second note refused: ", not second,
			"  locked note II: ", _note_state(2, "recon"))
	await get_tree().create_timer(0.5).timeout
	chal_on = false
	chute_queue.clear()
	_note_done() # (as if the three sentences were built)
	var m1 := money
	_accept_note(1, "picture")
	for pz in board_list.duplicate():
		var want: Dictionary = pz.duplicate()
		want["state"] = "scene"
		_judge(want)
	await get_tree().create_timer(0.5).timeout
	query = ""
	var l2 := _results().map(func(r): return r[1])
	print("T53 notes done: money ", m1, " -> ", money, "  level ", Latin.level, "  ama unlocked: ", "ama" in l2, "  -am unlocked: ", Latin.ending_unlocked("decl1", "am"),
			"  note II open: ", _note_state(2, "recon"), "  medal: ", badge_slots[0].get_child_count() > 2)
	# saving: level, money and the notes done come back as they were
	var lv0 := Latin.level
	var m0 := money
	var nd0 := notes_done.keys()
	_save_game()
	Latin.level = 1
	money = 0
	notes_done.clear()
	_load_game()
	print("T54 saved and loaded: level ", lv0, "->", Latin.level, "  money ", m0, "->", money, "  notes ", nd0.size(), "->", notes_done.size())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	save_path = ""
	Latin.level = 99 # (back to everything unlocked for the rest of the test)
	campaign_on = false
	_board_load(PUZZLES)
	_apply_locks()
	# the neuter adapter on a masculine -um sparks, and the plug won't stay in
	var nsg2 := _new_chunk([_new_tile("adapter", "neut_sg")], Vector3(0.7, TABLE_Y, 0.55))
	var masc_um := _new_ending("decl2", "um")
	var mw := _new_chunk([_new_tile("stem", "serv"), masc_um], Vector3(0.95, TABLE_Y, 0.25))
	_refresh(nsg2)
	_refresh(mw)
	await get_tree().create_timer(0.4).timeout
	await _plug_drag(nsg2.tiles[0].cords_out[0], masc_um)
	var neut_um := _new_ending("decl2", "um")
	var pw2 := _new_chunk([_new_tile("stem", "pocul"), neut_um], Vector3(0.95, TABLE_Y, -0.15))
	_refresh(pw2)
	await get_tree().create_timer(0.3).timeout
	await _plug_drag(nsg2.tiles[0].cords_out[0], neut_um)
	var sounds := 0
	for nm in ["seat", "plug", "lock", "click", "spark", "chime", "whoosh", "rattle", "slide", "step", "step2", "place", "clack", "paper", "key", "key_enter"]:
		if Sfx.stream(nm).data.size() > 500:
			sounds += 1
	print("T55 N·SG into servum: refused=", nsg2.tiles[0].cords_out[0].socket_tile != masc_um, "   into pōculum: in=", nsg2.tiles[0].cords_out[0].socket_tile == neut_um, "   sounds made: ", sounds, "/16")
	# adjectives: gender cable into the noun's stem, agreement cable into its ending
	var sock_of := func(t: Tile, k: String) -> int:
		for i in t.sock_count():
			if t.sock(i)["kind"] == k:
				return i
		return -1
	var pu := _new_chunk([_new_tile("stem", "puer")], Vector3(-0.6, TABLE_Y, -0.3))
	var bonus_e := _new_tile("adapter", "adj") # (the cap on bon-us)
	var bw := _new_chunk([_new_tile("stem", "bon"), _new_ending("decl2", "us"), bonus_e], Vector3(-0.6, TABLE_Y, 0.1))
	var cv := _new_chunk([_new_tile("stem", "curr"), _new_tile("ending", "t", "verb")], Vector3(-0.1, TABLE_Y, -0.3))
	var pella_w := _new_chunk([_new_tile("stem", "puell"), _new_ending("decl1", "a")], Vector3(0.4, TABLE_Y, -0.3))
	for c in [pu, bw, cv, pella_w]:
		_refresh(c)
	await get_tree().create_timer(0.3).timeout
	var aux_c: Cord = bonus_e.cords_out[0]
	var agr_c: Cord = bonus_e.cords_out[1]
	var wrong_gender: bool = _misfit_plug(aux_c, pella_w.tiles[0], sock_of.call(pella_w.tiles[0], "aux"))
	var right_gender: bool = not _misfit_plug(aux_c, pu.tiles[0], sock_of.call(pu.tiles[0], "aux"))
	aux_c.socket_tile = pu.tiles[0]
	aux_c.socket_i = sock_of.call(pu.tiles[0], "aux")
	pu.tiles[0].cord.socket_tile = cv.tiles[1] # puer is the subject
	var agrees: bool = not _misfit_plug(agr_c, pu.tiles[0], sock_of.call(pu.tiles[0], "agree"))
	agr_c.socket_tile = pu.tiles[0]
	agr_c.socket_i = sock_of.call(pu.tiles[0], "agree")
	disp_cord.socket_tile = cv.tiles[0]
	disp_cord.socket_i = 0
	await get_tree().create_timer(0.4).timeout
	var bum := _new_tile("adapter", "adj")
	var bum_w := _new_chunk([_new_tile("stem", "bon"), _new_ending("decl2", "um"), bum], Vector3(0.0, TABLE_Y, 0.3))
	_refresh(bum_w)
	var acc_refused: bool = _misfit_plug(bum.cords_out[1], pu.tiles[0], sock_of.call(pu.tiles[0], "agree"))
	print("T56 bonus into puellae's stem: sparks=", wrong_gender, "  into puer's: in=", right_gender, "   bonus agrees with subject puer: ", agrees,
			"  bonum refused: ", acc_refused, "   scene: ", JSON.stringify(_scene().get("subj")))
	# it's checked again whenever the noun's use changes: bonōs (acc. pl.) on rēgēs is fine
	# while rēgēs could be the object... until rēgēs is plugged in as the (plural) subject
	var pae := _new_ending("decl3", "es")
	var pae_w := _new_chunk([_new_tile("stem", "reg"), pae], Vector3(0.5, TABLE_Y, 0.25))
	var bono := _new_tile("adapter", "adj")
	var bono_w := _new_chunk([_new_tile("stem", "bon"), _new_ending("decl2", "os"), bono], Vector3(0.9, TABLE_Y, 0.4))
	var vunt := _new_chunk([_new_tile("stem", "ama"), _new_tile("ending", "unt", "verb")], Vector3(0.9, TABLE_Y, -0.1))
	for c in [pae_w, bono_w, vunt]:
		_refresh(c)
	await get_tree().create_timer(0.3).timeout
	var ok_unused: bool = not _misfit_plug(bono.cords_out[1], pae, sock_of.call(pae, "agree"))
	bono.cords_out[1].socket_tile = pae
	bono.cords_out[1].socket_i = sock_of.call(pae, "agree")
	await get_tree().create_timer(0.3).timeout
	var still_in: bool = bono.cords_out[1].socket_tile == pae
	for pc6: Cord in pae.cords_out:
		if pc6.kind == "nom" and pc6.prongs == 2:
			pc6.socket_tile = vunt.tiles[1] # now rēgēs is the (plural) subject
	await get_tree().create_timer(0.4).timeout
	print("T57 bonōs on rēgēs: fine while unused=", ok_unused and still_in, "  sparked off once rēgēs became the subject: ", bono.cords_out[1].socket_tile == null,
			"   adjective drawers left: ", drawers.filter(func(d): return d["cat"].begins_with("adj")).size(),
			"   picture with adjectives drawn: ", PixelArt.compose({"state": "scene", "verb": "vide", "person": 3, "vnum": "sg", "subj": {"stem": "puell", "num": "sg", "adj": ["magn", "bon"]},
					"obj": {"stem": "equ", "num": "sg", "adj": ["parv", "mal", "laet"]}, "mods": []}).get_width() == PixelArt.W)
	# holding an ending and clicking on a stem lying in the tray: it goes on (and stays in the tray)
	_make_loose(_new_tile("stem", "puell"), TRAY_POS + Vector3(0.1, 0.06, 0.3), false)
	var tray_stem: Tile = loose.filter(func(x): return is_instance_valid(x) and x.key == "puell" and x.kind == "stem").back()
	tray_stem.loose_body.global_transform = Transform3D(Basis.IDENTITY, TRAY_POS + Vector3(0.1, 0.06, 0.3))
	await get_tree().create_timer(1.0).timeout
	var am := _new_ending("decl1", "am")
	var amc := _new_chunk([am], Vector3(0.3, TABLE_Y, 0.5))
	_refresh(amc)
	_grab(am)
	for f in 5:
		await get_tree().process_frame
	drag_mouse = _screen(tray_stem.global_position)
	_release()
	await get_tree().create_timer(0.6).timeout
	var tw_c = tray_stem.loose_body.get_meta("chunk") if tray_stem.loose_body else tray_stem.get_parent()
	print("T58 -am clicked onto puell- in the tray: on=", am.get_parent() == tw_c, "  still lying in the tray: ", tray_stem.in_tray, "  word: ", tw_c.analysis.get("latin", "?") if tw_c is Chunk else "?")
	# a word lying face down rolls over face up; nouns are the colour of their gender
	_make_loose(_new_tile("stem", "puer"), TRAY_POS + Vector3(-0.15, 0.08, -0.3), false)
	var fd: Tile = loose.filter(func(x): return is_instance_valid(x) and x.key == "puer").back()
	fd.loose_body.global_transform = Transform3D(Basis(Vector3.RIGHT, PI), TRAY_POS + Vector3(-0.15, 0.06, -0.3))
	await get_tree().create_timer(2.5).timeout
	print("T59 face-down puer rolled face up: ", fd.loose_body.global_basis.y.dot(Vector3.UP) > 0.8,
			"   board colours: puer ", Tile.color_for("stem", "puer", "").to_html(false), " puella ", Tile.color_for("stem", "puell", "").to_html(false), " pōculum ", Tile.color_for("stem", "pocul", "").to_html(false))
	# an adjective's plug pulled out of the top of a noun stays out (it used to drop straight back in)
	var pu6 := _new_chunk([_new_tile("stem", "puer")], Vector3(-0.3, TABLE_Y, -0.1))
	var bi6 := _new_tile("adapter", "adj")
	var bw6 := _new_chunk([_new_tile("stem", "bon"), _new_ending("decl2", "us"), bi6], Vector3(-0.3, TABLE_Y, 0.3))
	_refresh(pu6)
	_refresh(bw6)
	await get_tree().create_timer(0.5).timeout
	var ag6: Cord = bi6.cords_out[1]
	var ax6: Cord = bi6.cords_out[0]
	_seat_plug(ag6, pu6.tiles[0], sock_of.call(pu6.tiles[0], "agree"))
	_seat_plug(ax6, pu6.tiles[0], sock_of.call(pu6.tiles[0], "aux"))
	await get_tree().create_timer(0.6).timeout
	var was_in: bool = ax6.socket_tile == pu6.tiles[0]
	_grab_plug(ax6, _screen(Cord.socket_xf(pu6.tiles[0], ax6.socket_i).origin))
	for f in 20:
		await get_tree().process_frame
	var out_held: bool = ax6.socket_tile == null and held_cord == ax6
	plug_mouse = _screen(Cord.socket_xf(pu6.tiles[0], sock_of.call(pu6.tiles[0], "aux")).origin + Vector3(0.2, 0, 0.1))
	for f in 30:
		await get_tree().process_frame
	_release()
	await get_tree().create_timer(0.3).timeout
	print("T60 adjective plug pulled out of puer: was in=", was_in, "  came out and stayed out: ", out_held and ax6.socket_tile == null)
	# an ending put on puer- shuts its own gold agreement hole: the plug moves up into the ending's
	var pi6 := _new_ending("decl2", "i")
	var pic := _new_chunk([pi6], Vector3(0.4, TABLE_Y, -0.1))
	_refresh(pic)
	var closed0: bool = pu6.tiles[0].agree_closed()
	var ag_was: bool = ag6.socket_tile == pu6.tiles[0]
	_seat(pic, pu6)
	await get_tree().create_timer(0.6).timeout
	print("T61 -ī on puer-: gold hole shut=", pu6.tiles[0].agree_closed(), " (open before: ", not closed0, ")  bonus's plug was in: ", ag_was, "  popped out of the shut hole: ", ag6.socket_tile != pu6.tiles[0],
			"  cover showing: ", pu6.tiles[0].agree_cap.visible)
	# shaking over the bench lays everything out: a sentence on a row of its own, nothing overlapping
	_seat_plug(ax6, pu6.tiles[0], sock_of.call(pu6.tiles[0], "aux"))
	var vb6 := _new_chunk([_new_tile("stem", "ama"), _new_tile("ending", "t", "verb")], Vector3(1.0, TABLE_Y, 0.6))
	_refresh(vb6)
	await get_tree().create_timer(0.3).timeout
	for cd: Cord in pi6.cords_out:
		if cd.kind == "nom":
			_seat_plug(cd, vb6.tiles[1], 0)
	var rnd := _new_chunk([_new_tile("stem", "equ")], Vector3(0.9, TABLE_Y, -0.2))
	rnd.rotation.y = 0.7
	for c in [rnd]:
		_refresh(c)
	await get_tree().create_timer(0.5).timeout
	_tidy_desk()
	await get_tree().create_timer(1.2).timeout
	var bench := chunks.filter(func(c): return c.position.y < TABLE_Y + 0.05 and c.position.x > TRAY_RIGHT and not owned_by.has(c))
	var overl := 0
	for a6 in bench:
		for b6 in bench:
			if a6 != b6 and absf(a6.position.z - b6.position.z) < 0.1 and a6.position.x < b6.position.x + b6.width and b6.position.x < a6.position.x + a6.width:
				overl += 1
	var same_row: bool = absf(pu6.position.z - vb6.position.z) < 0.01 and absf(bw6.position.z - pu6.position.z) < 0.01
	var ordered: bool = pu6.position.x < bw6.position.x and bw6.position.x < vb6.position.x
	print("T62 bench tidied: ", bench.size(), " pieces  overlapping: ", overl / 2, "  sentence on one row: ", same_row, "  puerī bonus amat in order: ", ordered,
			"  all straight: ", bench.all(func(c): return c.quaternion.is_equal_approx(Quaternion.IDENTITY)))
	# you can't reach a piece in a drawer through the drawer's floor
	var dr0: Dictionary = drawers[0]
	var dpiece: Tile = null
	for t6: Tile in loose:
		if is_instance_valid(t6) and t6.loose_body and t6.get_meta("drawer_i", -1) == 0:
			dpiece = t6
			break
	var blocked := false
	if dpiece:
		var tp6 := dpiece.loose_body.global_position
		var q6 := PhysicsRayQueryParameters3D.create(Vector3(tp6.x, dr0["node"].global_position.y - 0.04, tp6.z), tp6, L_PICK | L_LOOSE | L_BLOCK)
		var h6 := get_world_3d().direct_space_state.intersect_ray(q6)
		blocked = not h6.is_empty() and h6["collider"] == dr0["node"]
		if not blocked:
			print("   dbg T63 hit ", h6.get("collider"), " ", h6.get("collider").get_meta("kind", "") if h6.get("collider") else "", " at ", h6.get("position"), " piece at ", tp6, " drawer y ", dr0["node"].global_position.y)
	print("T63 a drawer's piece can't be clicked from underneath: ", blocked)
	# adjectives take the I / II endings: on its own bonae is a noun ("good women"); a cap makes it an adjective
	var lv7 := Latin.level
	Latin.level = 99
	var sb_e := _new_ending("decl1", "ae")
	var sb_w := _new_chunk([_new_tile("stem", "bon"), sb_e], Vector3(-0.5, TABLE_Y, 0.55))
	var sb_v := _new_chunk([_new_tile("stem", "ambula"), _new_tile("ending", "unt", "verb")], Vector3(0.3, TABLE_Y, 0.55))
	_refresh(sb_w)
	_refresh(sb_v)
	await get_tree().create_timer(0.5).timeout
	var sb_nom: Cord = null
	for x7: Cord in sb_e.cords_out:
		if x7.kind == "nom":
			sb_nom = x7
	var has_nom: bool = sb_nom != null
	if sb_nom:
		_seat_plug(sb_nom, sb_v.tiles[1], 0)
	_seat_plug(disp_cord, sb_v.tiles[0], 0)
	await get_tree().create_timer(0.5).timeout
	var sub_sc := _scene()
	# a cap held over its end and let go: on it goes; the ending's own cable goes away
	var cap7 := _new_tile("adapter", "adj")
	var cap_c := _new_chunk([cap7], sb_e.global_position + Vector3(0.1, 0, 0.05))
	_refresh(cap_c)
	await get_tree().create_timer(0.3).timeout
	_grab(cap7)
	for f in 4:
		await get_tree().process_frame
	drag_mouse = _screen(sb_e.global_position)
	_release()
	await get_tree().create_timer(0.8).timeout
	var on7: bool = cap7.get_parent() == sb_w and sb_w.tiles.find(cap7) == 2
	var cable_gone: bool = sb_nom == null or (sb_nom.socket_tile == null and sb_nom.emerge_goal == 0.0)
	print("T66 bonae alone: subject cable ", has_nom, "  scene subj ", JSON.stringify(sub_sc.get("subj")), "  picture drawn: ", PixelArt.compose(sub_sc).get_width() == PixelArt.W,
			"   cap put on the end: ", on7, "  its own cable put away: ", cable_gone, "  cap cables: ", cap7.cords_out.map(func(x): return x.kind),
			"  genders -a/-um/-ōrum: ", Latin.adj_genders("decl1", "a"), Latin.adj_genders("decl2", "um"), Latin.adj_genders("decl2", "orum"),
			"  bon-is (III) refused: ", not Latin.combine("bon", "decl3", "is")["ok"])
	Latin.level = lv7
	# the tutorials: one note at a time, steps ticked off, arrows pointing at things
	var keep_nd := notes_done.duplicate()
	var keep_lv := Latin.level
	var keep_cam := campaign_on
	_clear_player_words()
	disp_cord.socket_tile = null
	await get_tree().create_timer(0.6).timeout
	notes_done.clear()
	active_note = ""
	Latin.level = 1
	campaign_on = true
	_apply_locks()
	_refresh_notes()
	var shown0 := note_nodes.keys().filter(func(k): return note_nodes[k]["node"].visible)
	var row_top: bool = shown0.size() > 0 and note_nodes[shown0[0]]["node"].position.y > 0.25 and absf(note_nodes[shown0[0]]["node"].rotation_degrees.z) > 1.0
	_accept_note(1, "tut")
	var notes_hidden: bool = note_nodes.keys().all(func(k): return not note_nodes[k]["node"].visible) and checklist.visible
	for f8 in 60:
		await get_tree().create_timer(0.1).timeout
		var ct8 := _stem_tile("curr")
		if ct8 and ct8.loose_body and ct8.loose_body.linear_velocity.length() < 0.05 and not ct8.loose_body.freeze:
			break
	await get_tree().create_timer(0.6).timeout
	var arrow_on: bool = tut_arrows.size() > 0 and tut_arrows[0].visible
	var ct := _stem_tile("curr")
	var cc := _take_loose(ct)
	cc.global_transform = Transform3D(Basis.IDENTITY, Vector3(0.1, TABLE_Y, 0.4))
	_refresh(cc)
	await get_tree().create_timer(0.6).timeout
	var step1 := tut_step
	_seat_plug(disp_cord, ct, 0)
	await get_tree().create_timer(0.6).timeout
	var te := _new_tile("ending", "t", "verb")
	var tcn := _new_chunk([te], Vector3(0.8, TABLE_Y, 0.4))
	_refresh(tcn)
	_seat(tcn, cc)
	await get_tree().create_timer(0.6).timeout
	var ticks := checklist.text.count("[✓]")
	await get_tree().create_timer(2.0).timeout
	print("T67 tutorial I: notes up first ", shown0, "  in a row at the top, tilted: ", row_top, "  taken down for the steps: ", notes_hidden,
			"  arrow out: ", arrow_on, "  step after putting curr- on the bench: ", step1, "  ticks: ", ticks, "  done: ", notes_done.has("1:tut"),
			"  next: II ", _note_state(2, "tut"), ", level I ", _note_state(1, "recon"))
	# challenges: at level V the gender-less adjectives and the broken screen are up; the second ones wait
	_clear_player_words()
	disp_cord.socket_tile = null
	for ti in TUTORIALS.size():
		notes_done[_note_key(ti + 1, "tut")] = true
	Latin.level = 5
	_apply_locks()
	_refresh_notes()
	var up5 := note_nodes.keys().filter(func(k): return note_nodes[k]["node"].visible)
	_accept_note(1, "chal")
	await get_tree().create_timer(4.0).timeout
	var blind_ok: bool = not chal_words.is_empty() and chal_words.all(func(c): return is_instance_valid(c) and c.tiles[0].has_meta("blind"))
	chal_on = false
	chute_queue.clear()
	_clear_player_words()
	chal_words.clear()
	active_note = ""
	gender_blind = false
	_accept_note(3, "chal")
	var vb8 := _new_chunk([_new_tile("stem", "vide"), _new_tile("ending", "t", "verb")], Vector3(0.2, TABLE_Y, 0.3))
	_refresh(vb8)
	await get_tree().create_timer(0.3).timeout
	_seat_plug(disp_cord, vb8.tiles[0], 0)
	await get_tree().create_timer(0.5).timeout
	var broken_ok: bool = screen_broken and screen_key == "broken"
	board_i = board_list.size() - 1
	_board_next() # (as if the last picture was matched)
	await get_tree().create_timer(0.5).timeout
	var second_locked := _note_state(4, "chal")
	Latin.level = 7
	print("T68 challenges up at level V: ", up5, "  gender-less nouns delivered: ", blind_ok, "  broken screen shows snow: ", broken_ok,
			"  Tabula Fracta II at level V: ", second_locked, ", at VII: ", _note_state(4, "chal"), "   Sine Coloribus II: ", _note_state(2, "chal"),
			"  colour of a blind noun: ", _blind_col())
	# an adjective cap brought up to the end of an ending snaps on by itself
	Latin.level = 99
	var aw := _new_chunk([_new_tile("stem", "bon"), _new_ending("decl1", "a")], Vector3(-0.3, TABLE_Y, 0.5))
	var capt := _new_tile("adapter", "adj")
	var capc := _new_chunk([capt], Vector3(0.3, TABLE_Y, 0.5))
	_refresh(aw)
	_refresh(capc)
	await get_tree().create_timer(0.3).timeout
	_grab(capt)
	var tip8: Vector3 = aw.tiles[1].global_transform * Vector3(aw.tiles[1].width * 0.5, 0, 0)
	for x8 in [0.25, 0.15, 0.08, 0.04, 0.02]:
		if dragging == null:
			break
		var wp := tip8 + Vector3(x8, 0.02, 0)
		hold_dist = camera.global_position.distance_to(wp)
		_drag_to(_screen(wp))
		for f in 8:
			await get_tree().process_frame
	var snapped: bool = capt.get_parent() == aw and dragging == null
	if dragging:
		_release()
	print("T69 cap brought to -a's end snaps on without a click: ", snapped,
			"   T70 the computer's cable comes out of its back: ", disp_cord.anchor().z < monitor_body.global_position.z - 0.05)
	notes_done = keep_nd
	Latin.level = keep_lv
	campaign_on = keep_cam
	active_note = ""
	_apply_locks()
	# the dative: puella puerō ūvam dat
	var lv_keep := Latin.level
	Latin.level = 99
	var d_pa := _new_ending("decl1", "a")
	var d_subj := _new_chunk([_new_tile("stem", "puell"), d_pa], Vector3(-0.5, TABLE_Y, 0.4))
	var d_po := _new_ending("decl2", "o")
	var d_dat := _new_chunk([_new_tile("stem", "puer"), d_po], Vector3(-0.1, TABLE_Y, 0.4))
	var d_uam := _new_ending("decl1", "am")
	var d_obj := _new_chunk([_new_tile("stem", "uv"), d_uam], Vector3(0.3, TABLE_Y, 0.4))
	var d_vt := _new_tile("ending", "t", "verb")
	var d_v := _new_chunk([_new_tile("stem", "da"), d_vt], Vector3(0.8, TABLE_Y, 0.4))
	for c in [d_subj, d_dat, d_obj, d_v]:
		_refresh(c)
	await get_tree().create_timer(0.5).timeout
	var d_rod: Tile = d_v.tiles[0]
	var kinds := d_rod.cords_out.map(func(x): return x.kind)
	_seat_plug(d_pa.cords_out[0], d_vt, 0)
	for cd: Cord in d_rod.cords_out:
		if cd.kind == "acc":
			_seat_plug(cd, d_uam, 0)
		elif cd.kind == "dat":
			_seat_plug(cd, d_po, sock_of.call(d_po, "dat"))
	_seat_plug(disp_cord, d_rod, 0)
	await get_tree().create_timer(0.6).timeout
	var dsc := _scene()
	var want_d: Dictionary = CAMPAIGN[11]["picture"]["puzzles"][0].duplicate()
	print("T64 dative: dō's cables ", kinds, "  puerō has a dative hole: ", sock_of.call(d_po, "dat") > 0, "  -am has none: ", sock_of.call(d_uam, "dat") < 0,
			"  scene dat ", JSON.stringify(dsc.get("dat")), "  matches the 'Dona' picture: ", _same_scene(dsc, want_d), "  form: ", d_v.analysis.get("latin", "?"),
			"  damus: ", Latin.verb_form("da", "imus"))
	# the campaign: every task only needs what its level has unlocked; every word belongs to a level
	var badc := []
	for L in CAMPAIGN.size():
		Latin.level = L + 1
		for spec in CAMPAIGN[L]["recon"]["sets"].reduce(func(acc, x): return acc + x, []):
			if not Latin.word_unlocked(spec[0]):
				badc.append("%d:%s" % [L + 1, spec[0]])
			if spec[1] != "" and not Latin.ending_unlocked(spec[2], spec[1]):
				badc.append("%d:-%s(%s)" % [L + 1, spec[1], spec[2]])
		for pz in CAMPAIGN[L]["picture"]["puzzles"]:
			var pzs := JSON.stringify(pz)
			for st6 in Latin.STEMS:
				if pzs.contains('"%s"' % st6) and not Latin.word_unlocked(st6):
					badc.append("%d:pic %s" % [L + 1, st6])
			var img6: Image = PixelArt.compose(_with_state(pz))
			if img6 == null:
				badc.append("%d:pic draw" % [L + 1])
	Latin.level = CAMPAIGN.size()
	var orphans := Latin.STEMS.keys().filter(func(k): return not Latin.word_unlocked(k))
	Latin.level = lv_keep
	print("T65 campaign: ", CAMPAIGN.size(), " levels  anything used before it's unlocked: ", badc, "  words in no level: ", orphans)
	var e0 := camera.global_position.y
	var sp := InputEventKey.new()
	sp.physical_keycode = KEY_SPACE
	sp.pressed = true
	_unhandled_input(sp)
	var top := e0
	for f in 30:
		await get_tree().process_frame
		top = maxf(top, camera.global_position.y)
	await get_tree().create_timer(1.0).timeout
	var kc := InputEventKey.new()
	kc.physical_keycode = KEY_SHIFT
	kc.keycode = KEY_SHIFT
	kc.pressed = true
	Input.parse_input_event(kc)
	await get_tree().create_timer(0.5).timeout
	var low := camera.global_position.y
	kc.pressed = false
	Input.parse_input_event(kc)
	await get_tree().create_timer(0.5).timeout
	print("T22 jump rose ", snappedf(top - e0, 0.01), " and landed: ", absf(camera.global_position.y - e0) < 0.003, "  crouch eye ", snappedf(low, 0.01), " (stand ", snappedf(e0, 0.01), ")")
	var kw := InputEventKey.new()
	kw.physical_keycode = KEY_D
	kw.keycode = KEY_D
	kw.pressed = true
	Input.parse_input_event(kw)
	await get_tree().create_timer(0.5).timeout
	kw.pressed = false
	Input.parse_input_event(kw)
	print("T18 holding D moves the camera right: ", snappedf(camera.global_position.x - c0.x, 0.01))
	get_tree().quit()
