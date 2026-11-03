class_name Sfx
extends RefCounted
## Little synthesised sounds (no audio files): made once, the first time they're
## needed, then played as short 3D one-shots where things happen.
##   seat   - an ending sliding home onto its stem: a short slide, then a solid click
##   plug   - a plug pushed home: a low clunk with a click on top
##   lock   - a word dropping into a genitive holder: click + a small metallic ring
##   click  - a reel clicking onto its option
##   spark  - an electrical zap, crackle and a hiss of smoke (wrong endings)
##   chime  - "recte!": two bright tones
##   whoosh - sweeping the bench clear
##   rattle - a drawer being tidied: a run of small clicks
##   slide  - a drawer rumbling open / shut
##   step   - a footstep on the concrete floor (two, alternating)
##   place  - a piece set down on something
##   thud/clank 1-3 - a loose piece knocking into things (board pieces / metal rods)
##   paper  - a sheet of paper fluttering down
##   key    - a key on the computer's keyboard (key_enter: the big one)

const RATE := 22050
static var _cache := {}


## A sound that isn't anywhere in particular (your own footsteps, the menu).
static func play2d(parent: Node, name: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not parent.is_inside_tree():
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream(name)
	p.volume_db = volume_db
	p.pitch_scale = pitch * randf_range(0.94, 1.06)
	parent.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


static func play(parent: Node, name: String, at: Vector3, volume_db := 0.0, pitch := 1.0) -> void:
	if not parent.is_inside_tree():
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = stream(name)
	p.volume_db = volume_db
	p.pitch_scale = pitch * randf_range(0.94, 1.06)
	p.unit_size = 4.0 # (audible across the room)
	parent.add_child(p)
	p.global_position = at
	p.play()
	p.finished.connect(p.queue_free)


static func stream(name: String) -> AudioStreamWAV:
	if not _cache.has(name):
		_cache[name] = _make(name)
	return _cache[name]


static func _make(name: String) -> AudioStreamWAV:
	var s := PackedFloat32Array()
	match name:
		"seat":
			s = _mix(_noise_burst(0.045, 0.6, 0.3), _shift(_mix(_click(0.09, 2600.0, 0.9), _thunk(0.12, 170.0, 0.5)), 0.045))
		"plug":
			s = _mix(_thunk(0.16, 120.0, 0.9), _click(0.06, 3200.0, 0.6))
		"lock":
			s = _mix(_click(0.06, 2400.0, 0.8), _ring(0.35, 1650.0, 0.25))
		"click":
			s = _click(0.04, 3000.0, 0.5)
		"spark":
			s = _spark()
		"chime":
			s = _mix(_ring(0.6, 880.0, 0.35), _shift(_ring(0.7, 1320.0, 0.35), 0.09))
		"whoosh":
			s = _whoosh(0.55)
		"rattle":
			s = PackedFloat32Array()
			for k in 9:
				s = _mix(s, _shift(_click(0.03, randf_range(2200.0, 3600.0), 0.4), 0.05 * k + randf_range(0.0, 0.02)))
		"slide":
			s = _rumble(0.8)
		"step", "step2":
			s = _step(name == "step2")
		"place":
			s = _impact(false)
		"clack": # (kept for anything still asking for it)
			s = _impact(false)
		"thud1", "thud2", "thud3": # a board piece landing on something: a soft knock with some body
			s = _impact(false)
		"clank1", "clank2", "clank3": # a metal rod landing: a duller knock with a short ring
			s = _impact(true)
		"paper":
			s = _paper(0.9)
		"key", "key1", "key2", "key3", "key4":
			s = _keyclack(false)
		"key_enter":
			s = _keyclack(true)
	return _wav(s)


# ---------------------------------------------------------------- building blocks

static func _len(secs: float) -> int:
	return int(secs * RATE)


static func _click(secs: float, f: float, amp: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_len(secs))
	for i in out.size():
		var t := float(i) / RATE
		var env := exp(-t * 90.0)
		out[i] = amp * env * (0.6 * sin(TAU * f * t) + 0.4 * randf_range(-1.0, 1.0) * exp(-t * 600.0))
	return out


static func _thunk(secs: float, f: float, amp: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_len(secs))
	for i in out.size():
		var t := float(i) / RATE
		out[i] = amp * exp(-t * 28.0) * sin(TAU * f * t * (1.0 - t * 1.5))
	return out


static func _ring(secs: float, f: float, amp: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_len(secs))
	for i in out.size():
		var t := float(i) / RATE
		out[i] = amp * exp(-t * 7.0) * (sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.01 * t))
	return out


static func _noise_burst(secs: float, amp: float, smooth: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_len(secs))
	var y := 0.0
	for i in out.size():
		var t := float(i) / secs / RATE
		y = lerpf(y, randf_range(-1.0, 1.0), smooth)
		out[i] = amp * y * sin(PI * t)
	return out


static func _spark() -> PackedFloat32Array:
	var n := _len(0.9)
	var out := PackedFloat32Array()
	out.resize(n)
	var hiss := 0.0
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		if t < 0.12: # the zap: a harsh buzz
			v += 0.55 * signf(sin(TAU * 110.0 * t)) * (1.0 - t / 0.12) + 0.3 * randf_range(-1.0, 1.0)
		if randf() < 0.012 * exp(-t * 5.0): # crackle: sharp random pops
			v += randf_range(-1.0, 1.0)
		hiss = lerpf(hiss, randf_range(-1.0, 1.0), 0.5) # smoke: a soft hiss, fading
		v += 0.12 * hiss * exp(-t * 3.0) * smoothstep(0.05, 0.2, t)
		out[i] = clampf(v, -1.0, 1.0)
	for i in range(1, n): # a little smoothing on the pops
		out[i] = lerpf(out[i - 1], out[i], 0.7)
	return out


static func _whoosh(secs: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_len(secs))
	var y := 0.0
	for i in out.size():
		var t := float(i) / out.size()
		y = lerpf(y, randf_range(-1.0, 1.0), lerpf(0.05, 0.35, t)) # brightens as it goes
		out[i] = 0.7 * y * sin(PI * t)
	return out


static func _rumble(secs: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_len(secs))
	var y := 0.0
	for i in out.size():
		var t := float(i) / out.size()
		y = lerpf(y, randf_range(-1.0, 1.0), 0.04)
		out[i] = 0.5 * y * sin(PI * t) * (0.7 + 0.3 * sin(TAU * 13.0 * t))
	return out


## Something solid hitting something: a tiny burst of noise (the contact) rings a
## few damped resonances (the object's body). Each one made with its own small
## random differences, so no two variants sound quite alike.
static func _impact(metal: bool) -> PackedFloat32Array:
	var n := _len(0.32 if metal else 0.22)
	var out := PackedFloat32Array()
	out.resize(n)
	var modes := []
	if metal:
		for f in [randf_range(820, 980), randf_range(1600, 1850), randf_range(2500, 2800), randf_range(3700, 4100)]:
			modes.append([f, randf_range(16.0, 30.0), randf_range(0.05, 0.12)])
		modes.append([randf_range(170, 230), 40.0, 0.35]) # the thump
	else:
		modes = [[randf_range(120, 160), randf_range(28, 36), 0.55], [randf_range(290, 360), randf_range(40, 55), 0.3],
				[randf_range(560, 680), randf_range(65, 85), 0.16], [randf_range(1100, 1400), randf_range(100, 130), 0.06]]
	var y := 0.0
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for m in modes:
			v += m[2] * exp(-t * m[1]) * sin(TAU * m[0] * t)
		if t < 0.012: # the contact itself: a short soft burst of noise
			y = lerpf(y, randf_range(-1.0, 1.0), 0.35)
			v += 0.35 * y * (1.0 - t / 0.012)
		out[i] = v
	var peak := 0.0
	for v in out:
		peak = maxf(peak, absf(v))
	if peak > 0.0:
		for i in n:
			out[i] *= 0.8 / peak
	return out


## A mechanical keyboard key: the sharp plastic clack of the keycap bottoming out
## (a crack of bright noise ringing the cap's hollow body), the thock of the board
## underneath, and the smaller clack of it springing back up a moment later.
static func _keyclack(big: bool) -> PackedFloat32Array:
	var n := _len(0.11 if big else 0.08)
	var out := PackedFloat32Array()
	out.resize(n)
	var up_t := randf_range(0.045, 0.06) if not big else 0.07
	var cap := [randf_range(2600, 3300) * (0.8 if big else 1.0), randf_range(4800, 5600), randf_range(1300, 1600) * (0.85 if big else 1.0)]
	var thock := randf_range(380, 460) * (0.75 if big else 1.0)
	var y := 0.0
	var hp := 0.0
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for strike in [[0.0, 1.0], [up_t, 0.35]]: # down, then the spring-back
			var ts: float = t - strike[0]
			if ts < 0.0:
				continue
			var a: float = strike[1]
			v += a * (0.5 * exp(-ts * 260.0) * sin(TAU * cap[0] * ts) + 0.25 * exp(-ts * 420.0) * sin(TAU * cap[1] * ts)
					+ 0.3 * exp(-ts * 180.0) * sin(TAU * cap[2] * ts))
			if ts < 0.004: # the crack of contact: bright noise
				var nz := randf_range(-1.0, 1.0)
				hp = nz - y # (high-passed: crisp, not hissy)
				y = nz
				v += a * 0.9 * hp * (1.0 - ts / 0.004)
		v += 0.45 * exp(-t * 90.0) * sin(TAU * thock * t) # the board
		out[i] = v
	var peak := 0.0
	for v in out:
		peak = maxf(peak, absf(v))
	if peak > 0.0:
		for i in n:
			out[i] *= 0.85 / peak
	return out


## A footstep: a soft low thud and a little grit of the sole on concrete.
static func _step(alt: bool) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_len(0.16))
	var y := 0.0
	var f := 95.0 if alt else 82.0
	for i in out.size():
		var t := float(i) / RATE
		y = lerpf(y, randf_range(-1.0, 1.0), 0.18)
		out[i] = 0.55 * exp(-t * 35.0) * sin(TAU * f * t) + 0.25 * y * exp(-t * 22.0)
	return out


## Paper fluttering down: soft rustles that come and go.
static func _paper(secs: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_len(secs))
	var y := 0.0
	var amp := 0.0
	for i in out.size():
		var t := float(i) / out.size()
		if i % 900 == 0:
			amp = randf_range(0.1, 0.5) * sin(PI * t)
		y = lerpf(y, randf_range(-1.0, 1.0), 0.6)
		out[i] = amp * y * (0.5 + 0.5 * sin(TAU * 7.0 * t))
	return out


static func _shift(a: PackedFloat32Array, secs: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_len(secs))
	out.append_array(a)
	return out


static func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(maxi(a.size(), b.size()))
	for i in out.size():
		out[i] = (a[i] if i < a.size() else 0.0) + (b[i] if i < b.size() else 0.0)
	return out


static func _wav(s: PackedFloat32Array) -> AudioStreamWAV:
	var fade := mini(int(RATE * 0.002), s.size() / 2) # (2 ms in and out: no click where it starts or stops)
	for i in fade:
		var k := float(i) / fade
		s[i] *= k
		s[s.size() - 1 - i] *= k
	var bytes := PackedByteArray()
	bytes.resize(s.size() * 2)
	for i in s.size():
		bytes.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w
