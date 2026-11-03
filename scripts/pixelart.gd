class_name PixelArt
extends RefCounted
## Tiny procedural pixel art for the CRT display: people, a horse, verb icons.

const W := 104
const H := 56
const SKY := Color("#2b5d7a")
const GROUND := Color("#3f8a4a")
const INK := Color("#0e0b14")
const SKIN := Color("#f2c49b")
const CLEAR := Color(0, 0, 0, 0)

const PEOPLE := {
	"puell": {"hair": "long", "hair_c": "#f6c945", "shirt": "#e0485a", "legs": "#f2c49b", "dress": true},
	"puer": {"hair": "short", "hair_c": "#7a4a26", "shirt": "#3f7fd9", "legs": "#2d3550"},
	"agricol": {"hair": "hat", "hair_c": "#e8c25a", "shirt": "#5aa04a", "legs": "#7a5230", "fork": true},
	"domin": {"hair": "short", "hair_c": "#d0d0d0", "shirt": "#f4f1e8", "legs": "#f2c49b", "stripe": "#7a3fb0", "laurel": true},
	"naut": {"hair": "hat", "hair_c": "#2d3550", "shirt": "#f4f1e8", "legs": "#3f7fd9", "stripe": "#3f7fd9"},
	"poet": {"hair": "short", "hair_c": "#5a3a20", "shirt": "#d9c38a", "legs": "#f2c49b", "laurel": true},
	"regin": {"hair": "long", "hair_c": "#7a4a26", "shirt": "#9b3fd0", "legs": "#f2c49b", "dress": true, "crown": true},
	"fili": {"hair": "long", "hair_c": "#e88a3a", "shirt": "#f29bb8", "legs": "#f2c49b", "dress": true},
	"femin": {"hair": "long", "hair_c": "#3a2a20", "shirt": "#3fae9a", "legs": "#f2c49b", "dress": true},
	"vir": {"hair": "short", "hair_c": "#3a2a20", "shirt": "#a0643a", "legs": "#2d3550"},
	"magistr": {"hair": "short", "hair_c": "#e0e0e0", "shirt": "#5a5f8a", "legs": "#2d3550", "stripe": "#d0d0d0"},
	"serv": {"hair": "short", "hair_c": "#2a1a10", "shirt": "#8a7a5a", "legs": "#5a4a30"},
	"amic": {"hair": "short", "hair_c": "#f6c945", "shirt": "#e0485a", "legs": "#2d3550"},
	"discipul": {"hair": "short", "hair_c": "#7a4a26", "shirt": "#f2b632", "legs": "#2d3550"},
	"reg": {"hair": "short", "hair_c": "#5a3a20", "shirt": "#c0283a", "legs": "#f2c49b", "stripe": "#ffd23f", "crown": true},
	"milit": {"hair": "helmet", "hair_c": "#b8bec6", "shirt": "#c0283a", "legs": "#f2c49b"},
	"exercit": {"hair": "helmet", "hair_c": "#b8bec6", "shirt": "#8a2030", "legs": "#f2c49b"},
	"matr": {"hair": "long", "hair_c": "#5a3a20", "shirt": "#7a3fb0", "legs": "#f2c49b", "dress": true},
	"patr": {"hair": "short", "hair_c": "#5a5a5a", "shirt": "#3a6a4a", "legs": "#2d3550"},
	"fratr": {"hair": "short", "hair_c": "#e8c25a", "shirt": "#3f7fd9", "legs": "#5a4a30"},
	"soror": {"hair": "long", "hair_c": "#f6c945", "shirt": "#5aa04a", "legs": "#f2c49b", "dress": true},
	"uxor": {"hair": "long", "hair_c": "#2a1a10", "shirt": "#e0485a", "legs": "#f2c49b", "dress": true},
	"homin": {"hair": "short", "hair_c": "#3a2a20", "shirt": "#9aa4ae", "legs": "#2d3550"},
	"imperator": {"hair": "short", "hair_c": "#3a2a20", "shirt": "#7a3fb0", "legs": "#f2c49b", "stripe": "#ffd23f", "laurel": true},
	"pauper": {"hair": "short", "hair_c": "#5a4a3a", "shirt": "#8a7a62", "legs": "#5a4a30", "stripe": "#5a4a3a"},
	"sever": {"hair": "short", "hair_c": "#9a9a9a", "shirt": "#2d3550", "legs": "#1b1b22"},
	"senat": {"hair": "short", "hair_c": "#d0d0d0", "shirt": "#f4f1e8", "legs": "#f2c49b", "stripe": "#c0283a"},
}
## four-legged animals: body colour, dark colour
const BEASTS := {
	"equ": ["#a0643a", "#5a3520"],
	"lup": ["#8a8f99", "#4a4f59"],
	"can": ["#d0a060", "#7a5230"],
	"leon": ["#e8b040", "#a0601a"],
}

const DIGITS := {
	1: [".#.", "##.", ".#.", ".#.", "###"],
	2: ["##.", "..#", ".#.", "#..", "###"],
	3: ["##.", "..#", ".#.", "..#", "##."],
}


# 3x5 pixel font (Roman capitals: the screen writes V for U, as on inscriptions)
const FONT := {
	"a": [".#.", "#.#", "###", "#.#", "#.#"], "b": ["##.", "#.#", "##.", "#.#", "##."],
	"c": [".##", "#..", "#..", "#..", ".##"], "d": ["##.", "#.#", "#.#", "#.#", "##."],
	"e": ["###", "#..", "##.", "#..", "###"], "f": ["###", "#..", "##.", "#..", "#.."],
	"g": [".##", "#..", "#.#", "#.#", ".##"], "h": ["#.#", "#.#", "###", "#.#", "#.#"],
	"i": ["###", ".#.", ".#.", ".#.", "###"], "j": ["..#", "..#", "..#", "#.#", ".#."],
	"k": ["#.#", "#.#", "##.", "#.#", "#.#"], "l": ["#..", "#..", "#..", "#..", "###"],
	"m": ["#.#", "###", "###", "#.#", "#.#"], "n": ["##.", "#.#", "#.#", "#.#", "#.#"],
	"o": [".#.", "#.#", "#.#", "#.#", ".#."], "p": ["##.", "#.#", "##.", "#..", "#.."],
	"q": [".#.", "#.#", "#.#", "##.", ".##"], "r": ["##.", "#.#", "##.", "#.#", "#.#"],
	"s": [".##", "#..", ".#.", "..#", "##."], "t": ["###", ".#.", ".#.", ".#.", ".#."],
	"u": ["#.#", "#.#", "#.#", "#.#", ".#."], "v": ["#.#", "#.#", "#.#", "#.#", ".#."],
	"w": ["#.#", "#.#", "###", "###", "#.#"], "x": ["#.#", "#.#", ".#.", "#.#", "#.#"],
	"y": ["#.#", "#.#", ".#.", ".#.", ".#."], "z": ["###", "..#", ".#.", "#..", "###"],
	",": ["...", "...", "...", ".#.", "#.."], ".": ["...", "...", "...", "...", ".#."],
	"(": [".#.", "#..", "#..", "#..", ".#."], ")": [".#.", "..#", "..#", "..#", ".#."],
	":": ["...", ".#.", "...", ".#.", "..."], ">": ["#..", ".#.", "..#", ".#.", "#.."],
	"_": ["...", "...", "...", "...", "###"], "-": ["...", "...", "###", "...", "..."],
	"?": ["##.", "..#", ".#.", "...", ".#."], "!": [".#.", ".#.", ".#.", "...", ".#."],
}
const PHOSPHOR := Color("#8dffb0")
const ROW0 := 19 # first result row on the search screen
const ROW_H := 7


static func text(im: Image, t: String, x: int, y: int, c: Color) -> void:
	for ch in t.to_lower():
		var g: Array = FONT.get(ch, [])
		for r in g.size():
			for k in 3:
				if g[r][k] == "#":
					_px(im, x + k, y + r, c)
		x += 4


## The search tab: what's typed, then matching dictionary entries.
static func search(q: String, names: Array, sel: int, blink: bool, msg: String) -> Image:
	var im := _img(W, H)
	im.fill(Color("#0d1f17"))
	text(im, "qvaere radicem", 2, 2, PHOSPHOR)
	_rect(im, 0, 8, W, 1, PHOSPHOR.darkened(0.5))
	text(im, "> " + q + ("_" if blink else ""), 2, 11, Color.WHITE)
	var first := maxi(0, sel - 4)
	for i in range(first, mini(names.size(), first + 5)):
		var y := ROW0 + (i - first) * ROW_H
		if i == sel:
			_rect(im, 0, y - 1, W, ROW_H, PHOSPHOR.darkened(0.55))
		text(im, names[i], 2, y, PHOSPHOR if i != sel else Color.WHITE)
	if names.is_empty():
		text(im, "nihil", 2, ROW0, PHOSPHOR.darkened(0.3))
	if msg != "":
		_rect(im, 0, H - 8, W, 8, Color("#ffd23f"))
		text(im, msg, 2, H - 7, Color("#1b1b22"))
	return im


## Which result row a pixel row on the search screen is (-1 = none).
static func result_row(py: float) -> int:
	if py < ROW0 - 1:
		return -1
	return int((py - ROW0 + 1) / ROW_H)


static func _img(w: int, h: int) -> Image:
	var im := Image.create(w, h, false, Image.FORMAT_RGBA8)
	im.fill(CLEAR)
	return im


static func _rect(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx >= 0 and yy >= 0 and xx < im.get_width() and yy < im.get_height():
				im.set_pixel(xx, yy, c)


static func _px(im: Image, x: int, y: int, c: Color) -> void:
	_rect(im, x, y, 1, 1, c)


static func _solid(im: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height() and im.get_pixel(x, y).a > 0.5


## Adds a 1px black outline around a sprite (classic pixel-art look).
static func outline(src: Image) -> Image:
	var out := _img(src.get_width() + 2, src.get_height() + 2)
	for y in out.get_height():
		for x in out.get_width():
			var sx := x - 1
			var sy := y - 1
			if _solid(src, sx, sy):
				out.set_pixel(x, y, src.get_pixel(sx, sy))
			elif _solid(src, sx + 1, sy) or _solid(src, sx - 1, sy) or _solid(src, sx, sy + 1) or _solid(src, sx, sy - 1):
				out.set_pixel(x, y, INK)
	return out


## A person sprite in a pose: stand | walk | run | reach | carry | listen | look |
## throw | lead | point | cower | sit | sleep. (16 x 18 before the outline; the
## figure stands in the middle, arms can reach out to either side.)
static func person(cfg: Dictionary, mono := CLEAR, pose := "stand") -> Image:
	var im := _img(16, 18)
	var o := 2 # the body's left edge, so arms have room on both sides
	var hair := Color(cfg["hair_c"])
	var shirt := Color(cfg["shirt"])
	var legs := Color(cfg["legs"])
	var shoe := Color("#3a2a20")
	match pose: # legs
		"walk":
			_rect(im, o + 3, 13, 2, 2, legs)
			_rect(im, o + 2, 15, 2, 2, legs)
			_rect(im, o + 7, 13, 2, 2, legs)
			_rect(im, o + 8, 15, 2, 2, legs)
			_rect(im, o + 1, 17, 3, 1, shoe)
			_rect(im, o + 8, 17, 3, 1, shoe)
		"run":
			_rect(im, o + 3, 13, 2, 1, legs)
			_rect(im, o + 1, 14, 2, 2, legs)
			_rect(im, o + 0, 16, 2, 1, legs)
			_rect(im, o + 7, 13, 2, 1, legs)
			_rect(im, o + 9, 14, 2, 2, legs)
			_rect(im, o + 10, 16, 2, 1, legs)
			_rect(im, o - 1, 17, 3, 1, shoe)
			_rect(im, o + 10, 17, 3, 1, shoe)
		"sit":
			_rect(im, o + 4, 13, 6, 2, legs)
			_rect(im, o + 9, 15, 2, 2, legs)
			_rect(im, o + 9, 17, 3, 1, shoe)
		_:
			_rect(im, o + 4, 13, 2, 4, legs)
			_rect(im, o + 7, 13, 2, 4, legs)
			_rect(im, o + 4, 17, 2, 1, shoe)
			_rect(im, o + 7, 17, 2, 1, shoe)
	if cfg.get("dress", false) and pose != "sit" and pose != "run":
		for y in range(7, 15):
			var half := 2 + (y - 7) / 2
			_rect(im, o + 6 - half, y, half * 2 + 1, 1, shirt)
	else:
		_rect(im, o + 3, 7, 7, 6, shirt)
	if cfg.has("stripe"):
		for i in 6:
			_px(im, o + 3 + i, 7 + i, Color(cfg["stripe"]))
	# arms: [x, y, w, h] of the sleeve, then the hand
	var arms := [[o + 2, 8, 1, 4, o + 2, 12], [o + 10, 8, 1, 4, o + 10, 12]] # left, right
	match pose:
		"run":
			arms = [[o, 9, 3, 1, o - 1, 10], [o + 10, 7, 3, 1, o + 13, 6]]
		"reach":
			arms[1] = [o + 10, 8, 4, 1, o + 14, 8]
		"carry": # holding something in front of the chest
			arms = [[o + 2, 8, 1, 2, o + 3, 10], [o + 10, 8, 1, 2, o + 9, 10]]
		"listen": # hand cupped to the ear
			arms[1] = [o + 10, 4, 1, 5, o + 9, 4]
		"look": # hand shading the eyes
			arms[1] = [o + 10, 4, 1, 5, o + 7, 3]
		"throw":
			arms = [[o, 9, 3, 1, o - 1, 9], [o + 10, 2, 1, 7, o + 10, 1]]
		"lead": # one hand held out behind, holding a rope
			arms[0] = [o - 1, 9, 4, 1, o - 2, 9]
		"point":
			arms[1] = [o + 10, 6, 1, 3, o + 11, 5]
			_px(im, o + 12, 4, SKIN)
		"cower": # arms up in front of the face
			arms = [[o + 3, 4, 1, 4, o + 4, 3], [o + 9, 4, 1, 4, o + 8, 3]]
	for a in arms:
		_rect(im, a[0], a[1], a[2], a[3], shirt)
		_px(im, a[4], a[5], SKIN)
	_rect(im, o + 4, 2, 5, 5, SKIN)
	if pose == "sleep":
		_rect(im, o + 5, 4, 1, 1, INK)
		_rect(im, o + 7, 4, 1, 1, INK)
	elif pose == "cower":
		_px(im, o + 5, 4, INK)
		_px(im, o + 7, 4, INK)
		_rect(im, o + 5, 6, 3, 1, Color("#c0605a")) # a worried mouth
	else:
		_px(im, o + 5, 4, INK)
		_px(im, o + 7, 4, INK)
		_px(im, o + 6, 6, Color("#c0605a"))
	match cfg["hair"]:
		"long":
			_rect(im, o + 4, 1, 5, 2, hair)
			_rect(im, o + 3, 2, 1, 7, hair)
			_rect(im, o + 9, 2, 1, 7, hair)
		"short":
			_rect(im, o + 4, 1, 5, 2, hair)
		"hat":
			_rect(im, o + 2, 2, 9, 1, hair)
			_rect(im, o + 4, 0, 5, 2, hair)
		"helmet":
			_rect(im, o + 3, 0, 7, 3, hair)
			_rect(im, o + 5, 0, 3, 1, Color("#e0283a")) # crest
	if cfg.get("crown", false):
		_rect(im, o + 4, 1, 5, 1, Color("#ffd23f"))
		for x in [4, 6, 8]:
			_px(im, o + x, 0, Color("#ffd23f"))
	if cfg.get("laurel", false):
		for p in [Vector2i(3, 2), Vector2i(3, 3), Vector2i(9, 2), Vector2i(9, 3)]:
			_px(im, o + p.x, p.y, Color("#4caf50"))
	if cfg.get("fork", false) and pose in ["stand", "walk", "look", "listen"]:
		_rect(im, o + 11, 3, 1, 12, Color("#9a7a50"))
		_rect(im, o + 10, 0, 1, 3, Color("#b8bec6"))
		_px(im, o + 11, 1, Color("#b8bec6"))
	if mono.a > 0.0:
		for y in im.get_height():
			for x in im.get_width():
				if im.get_pixel(x, y).a > 0.5:
					im.set_pixel(x, y, mono)
	if pose == "sleep": # lying down
		im.rotate_90(COUNTERCLOCKWISE)
	return outline(im)


## Four-legged animals: standing, running (legs stretched out) or lying down asleep.
static func horse(body := "#a0643a", dark := "#5a3520", pose := "stand") -> Image:
	var im := _img(16, 12)
	var b := Color(body)
	var d := Color(dark)
	var y0 := 3 if pose == "sleep" else 0
	_rect(im, 2, 4 + y0, 10, 4, b)
	_rect(im, 10, 1 + y0, 2, 5, b)
	_rect(im, 11, 0 + y0, 4, 3, b)
	_px(im, 13, 1 + y0, b if pose == "sleep" else INK)
	_rect(im, 10, 0 + y0, 1, 4, d)
	_rect(im, 0, 4 + y0, 2, 4, d)
	match pose:
		"sleep":
			_rect(im, 3, 11, 8, 1, b)
		"run", "walk":
			for leg in [[2, -1], [4, 1], [8, -1], [10, 1]]:
				_rect(im, leg[0], 8, 1, 1, b)
				_rect(im, leg[0] + leg[1], 9, 1, 2, b)
				_px(im, leg[0] + leg[1], 11, INK)
		_:
			for x in [3, 5, 9, 11]:
				_rect(im, x, 8, 1, 3, b)
				_px(im, x, 11, INK)
	return outline(im)


static func noun(stem: String, pose := "stand") -> Image:
	if Latin.STEMS.has(stem) and Latin.STEMS[stem]["pos"] == "adj": # (a substantive drawn without its gender: a man)
		stem = "vir"
	if BEASTS.has(stem):
		return horse(BEASTS[stem][0], BEASTS[stem][1], pose)
	if PEOPLE.has(stem):
		return person(PEOPLE[stem], CLEAR, pose)
	return thing(stem)


## A noun with its adjectives: magnus bigger, parvus smaller; bonus gets a star,
## malus a storm cloud, laetus little hearts, above it.
static func noun_w(w: Dictionary, pose := "stand") -> Image:
	var adj: Array = w.get("adj", [])
	if Latin.STEMS.has(w["stem"]) and Latin.STEMS[w["stem"]]["pos"] == "adj": # a substantive: bonus "a good man",
		adj = adj + [w["stem"]] # bonae "good women", bonum "a good thing": the person / thing, with the adjective on
		w = {"stem": {"m": "vir", "f": "femin", "n": "r"}[w.get("g", "m")], "num": w.get("num", "sg"), "adj": adj}
	var spr := noun(w["stem"], pose)
	if adj.is_empty():
		return spr
	var plural_meta = spr.get_meta("plural") if spr.has_meta("plural") else null
	if "magn" in adj or "parv" in adj:
		var f := 1.4 if "magn" in adj else 0.65
		spr = spr.duplicate()
		spr.resize(maxi(4, int(spr.get_width() * f)), maxi(4, int(spr.get_height() * f)), Image.INTERPOLATE_NEAREST)
	if "bon" in adj or "mal" in adj or "laet" in adj: # marks in the sprite's empty top corners (never off the screen)
		spr = spr.duplicate()
		var sw := spr.get_width()
		if "bon" in adj:
			_star(spr, 2, 2, Color("#ffd23f"))
		if "mal" in adj:
			_rect(spr, sw - 7, 0, 7, 2, Color("#4a4a58"))
			_rect(spr, sw - 6, 2, 5, 1, Color("#4a4a58"))
			_px(spr, sw - 5, 4, Color("#7ec8ff"))
			_px(spr, sw - 2, 4, Color("#7ec8ff"))
		if "laet" in adj:
			for hx in [1, sw - 4]:
				_rect(spr, hx, 1, 3, 1, Color("#ff5a8a"))
				_px(spr, hx, 0, Color("#ff5a8a"))
				_px(spr, hx + 2, 0, Color("#ff5a8a"))
				_px(spr, hx + 1, 2, Color("#ff5a8a"))
	if plural_meta != null:
		spr.set_meta("plural", plural_meta)
	return spr


static func is_creature(stem: String) -> bool:
	return BEASTS.has(stem) or PEOPLE.has(stem)


## Things (and anything without a picture of its own: a little sign with its name).
static func thing(stem: String) -> Image:
	var im := _img(14, 14)
	match stem:
		"cas": # house
			_rect(im, 2, 7, 10, 7, Color("#e0c090"))
			for i in 6:
				_rect(im, 1 + i, 6 - i, 12 - 2 * i, 1, Color("#c0402a"))
			_rect(im, 6, 10, 2, 4, Color("#6a4020"))
		"aqu": # drop of water
			for y in 14:
				for x in 14:
					var r := Vector2(x - 6.5, y - 8.5).length()
					if r < 4.6 or (y < 8 and absf(x - 6.5) < (y - 1) * 0.6):
						_px(im, x, y, Color("#4aa0f0"))
		"silv": # trees
			for tx in [3, 9]:
				_rect(im, tx, 10, 2, 4, Color("#6a4020"))
				for i in 5:
					_rect(im, tx - 2 + i / 2, 2 + i * 2, 6 - i / 2 * 2, 2, Color("#2f8a3a"))
		"insul", "terr": # island / land
			_rect(im, 0, 11, 14, 3, Color("#3a7bd5"))
			_rect(im, 3, 8, 8, 4, Color("#d8b070") if stem == "insul" else Color("#5aa04a"))
			_rect(im, 6, 4, 1, 5, Color("#6a4020"))
			_rect(im, 4, 3, 5, 2, Color("#2f8a3a"))
		"vi": # road
			for y in 14:
				var hw := 2 + y / 3
				_rect(im, 7 - hw, y, hw * 2, 1, Color("#9a9a9a"))
				if y % 4 < 2:
					_px(im, 7, y, Color.WHITE)
		"agr": # field of wheat
			_rect(im, 0, 11, 14, 3, Color("#7a5230"))
			for x in [1, 4, 7, 10, 13]:
				_rect(im, x, 4, 1, 7, Color("#e8c25a"))
				_rect(im, x - 1, 3, 1, 3, Color("#f2d870"))
		"r": # a thing: a crate
			_rect(im, 1, 3, 12, 10, Color("#b07a3a"))
			_rect(im, 1, 7, 12, 1, Color("#7a5226"))
			_rect(im, 6, 3, 1, 10, Color("#7a5226"))
		"di": # sun
			for y in 14:
				for x in 14:
					var r := Vector2(x - 6.5, y - 6.5).length()
					if r < 3.6 or ((x + y) % 3 == 0 and r < 6.5 and r > 4.8):
						_px(im, x, y, Color("#ffd23f"))
		"sp": # star of hope
			for y in 14:
				for x in 14:
					if absf(x - 6.5) + absf(y - 6.5) * 2.2 < 4.0 or absf(x - 6.5) * 2.2 + absf(y - 6.5) < 4.0:
						_px(im, x, y, Color("#fff6a0"))
		"fid": # clasped hands
			_rect(im, 0, 6, 6, 3, SKIN)
			_rect(im, 8, 6, 6, 3, Color("#d8a070"))
			_rect(im, 5, 5, 4, 5, SKIN)
			_rect(im, 6, 6, 2, 3, Color("#d8a070"))
		"man": # hand
			_rect(im, 3, 6, 7, 7, SKIN)
			for x in [3, 5, 7, 9]:
				_rect(im, x, 1, 1, 5, SKIN)
			_rect(im, 10, 7, 2, 1, SKIN)
			_rect(im, 11, 6, 1, 1, SKIN)
		"fruct": # apple
			for y in 14:
				for x in 14:
					if Vector2(x - 6.5, y - 8.0).length() < 5.0:
						_px(im, x, y, Color("#e0283a"))
			_rect(im, 7, 1, 1, 3, Color("#6a4020"))
			_rect(im, 8, 1, 3, 2, Color("#4caf50"))
		"port": # harbour: a boat on the water
			_rect(im, 0, 11, 14, 3, Color("#3a7bd5"))
			_rect(im, 2, 8, 10, 3, Color("#a0643a"))
			_rect(im, 6, 1, 1, 7, Color("#6a4020"))
			_rect(im, 7, 2, 4, 5, Color.WHITE)
		"caud": # a tail
			for i in 10:
				_rect(im, 2 + i, 10 - int(sin(i * 0.5) * 6.0), 2, 2, Color("#a0643a"))
			_rect(im, 11, 1, 3, 3, Color("#5a3520"))
		"aur": # an ear
			for y in 14:
				for x in 14:
					var r := Vector2((x - 7.0) * 1.3, y - 7.0).length()
					if r < 6.5:
						_px(im, x, y, SKIN)
					if r < 3.5 and x > 6:
						_px(im, x, y, Color("#c08a6a"))
		"greg": # a flock of sheep
			for p in [Vector2i(0, 5), Vector2i(6, 2), Vector2i(5, 8)]:
				_rect(im, p.x + 1, p.y, 7, 4, Color("#f4f1e6"))
				_rect(im, p.x, p.y + 1, 2, 2, Color("#3a3a3a"))
				_rect(im, p.x + 2, p.y + 4, 1, 2, Color("#3a3a3a"))
				_rect(im, p.x + 6, p.y + 4, 1, 2, Color("#3a3a3a"))
		"harundin": # reeds
			for x in [2, 5, 8, 11]:
				_rect(im, x, 3 + x % 3, 1, 11 - x % 3, Color("#7aa040"))
				_rect(im, x - 1, 2 + x % 3, 2, 3, Color("#7a5230"))
		"litor": # the shore: sand meeting the sea
			_rect(im, 0, 8, 14, 6, Color("#3a7bd5"))
			for x in 14:
				_rect(im, 0, 8 + x / 3, 14 - x, 1, Color("#e8d08a"))
			_rect(im, 0, 7, 14, 1, Color.WHITE)
		"riv": # a stream
			for y in 14:
				_rect(im, 4 + int(sin(y * 0.6) * 2.5), y, 5, 1, Color("#4aa0f0"))
				_px(im, 6 + int(sin(y * 0.6) * 2.5), y, Color.WHITE if y % 4 == 0 else Color("#4aa0f0"))
		"case": # a wedge of cheese, with holes
			for y in range(4, 13):
				var w := 2 + (y - 4) * 3 / 2
				_rect(im, 1, y, mini(w, 13), 1, Color("#f2c94c"))
			_rect(im, 1, 12, 13, 1, Color("#d9a92e"))
			for h in [Vector2i(4, 9), Vector2i(8, 10), Vector2i(3, 6), Vector2i(10, 12)]:
				_rect(im, h.x, h.y, 2, 1, Color("#c08a1e"))
		"uv": # a grape (and, for more than one, a bunch: see _place)
			for y in 14:
				for x in 14:
					if Vector2(x - 6.5, y - 8.0).length() < 4.6:
						_px(im, x, y, Color("#7a3fb0"))
			_rect(im, 5, 5, 2, 2, Color("#b07ad8"))
			_rect(im, 6, 1, 1, 3, Color("#5a3a20"))
			_rect(im, 7, 1, 3, 2, Color("#4caf50"))
		"pocul": # a cup
			_rect(im, 3, 3, 8, 1, Color("#d8d8e0"))
			_rect(im, 4, 4, 6, 4, Color("#c8a040"))
			_rect(im, 5, 8, 4, 1, Color("#c8a040"))
			_rect(im, 6, 9, 2, 3, Color("#c8a040"))
			_rect(im, 4, 12, 6, 1, Color("#c8a040"))
			_rect(im, 5, 4, 4, 1, Color("#a03050"))
		"carmin": # a song: musical notes
			for n in [[3, 9], [9, 7]]:
				_rect(im, n[0], n[1], 3, 3, Color.WHITE)
				_rect(im, n[0] + 2, n[1] - 7, 1, 7, Color.WHITE)
			_rect(im, 5, 2, 7, 1, Color.WHITE)
			_rect(im, 5, 3, 7, 1, Color.WHITE)
		"nihil": # nothing: an empty dotted outline
			for i in range(0, 14, 2):
				_px(im, i, 1, Color.WHITE)
				_px(im, i, 12, Color.WHITE)
				_px(im, 0, i, Color.WHITE)
				_px(im, 13, i, Color.WHITE)
		_: # a sign with the start of the word on it
			_rect(im, 0, 2, 14, 9, Color("#f4f1e6"))
			_rect(im, 6, 11, 2, 3, Color("#6a4020"))
			text(im, stem.left(3), 1, 4, INK)
	if stem == "uv":
		var out := outline(im)
		out.set_meta("plural", _grape_bunch())
		return out
	return outline(im)


## A bunch of grapes: what more than one ūva looks like.
static func _grape_bunch() -> Image:
	var im := _img(16, 18)
	var rows := [[3, 5, 7, 9, 11], [4, 6, 8, 10], [4, 6, 8, 10], [5, 7, 9], [6, 8], [7]]
	for r in rows.size():
		for x in rows[r]:
			_rect(im, x, 4 + r * 2, 2, 2, Color("#7a3fb0") if (x + r) % 2 == 0 else Color("#9a5fd0"))
	_rect(im, 7, 0, 1, 4, Color("#5a3a20"))
	_rect(im, 8, 1, 4, 2, Color("#4caf50"))
	return outline(im)


const ICONS := ["ama", "vide", "audi", "porta", "capi", "duc", "mitt", "veni", "curr"]


static func icon(stem: String) -> Image:
	var im := _img(12, 12)
	match stem:
		"ama": # heart
			for y in 12:
				for x in 12:
					var fx := (x - 5.5) / 5.0
					var fy := -(y - 5.0) / 5.0
					var q := fx * fx + fy * fy - 1.0
					if q * q * q - fx * fx * fy * fy * fy <= 0.0:
						_px(im, x, y, Color("#ff3b5c"))
		"vide": # eye
			for y in 12:
				for x in 12:
					var ex := (x - 5.5) / 5.5
					var ey := (y - 5.5) / 3.4
					if ex * ex + ey * ey <= 1.0:
						_px(im, x, y, Color.WHITE)
					var r := Vector2(x - 5.5, y - 5.5).length()
					if r <= 2.6:
						_px(im, x, y, Color("#3a7bd5"))
					if r <= 1.2:
						_px(im, x, y, INK)
		"audi", "veni_": # sound waves
			for y in 12:
				for x in 12:
					var r := Vector2(x - 1, y - 6).length()
					if x > 1 and (absf(r - 3.0) < 0.6 or absf(r - 6.0) < 0.6 or absf(r - 9.0) < 0.6):
						_px(im, x, y, Color("#ffd23f"))
			_rect(im, 0, 5, 2, 3, SKIN)
		"porta": # crate held up
			_rect(im, 2, 5, 8, 7, Color("#b07a3a"))
			_rect(im, 2, 8, 8, 1, Color("#7a5226"))
			_rect(im, 5, 1, 2, 4, Color.WHITE)
			_rect(im, 4, 1, 4, 1, Color.WHITE)
			_rect(im, 5, 0, 2, 1, Color.WHITE)
		"capi": # grabbing hand
			_rect(im, 3, 6, 6, 5, SKIN)
			_rect(im, 3, 2, 1, 4, SKIN)
			_rect(im, 5, 1, 1, 5, SKIN)
			_rect(im, 7, 2, 1, 4, SKIN)
			_rect(im, 9, 6, 2, 1, SKIN)
			_rect(im, 10, 5, 1, 1, SKIN)
		"duc": # rope leading forward
			for x in 9:
				var y := 6 + int(round(sin(x * 0.9) * 1.5))
				_rect(im, x, y, 1, 2, Color("#d8b070"))
			_rect(im, 9, 3, 1, 7, Color.WHITE)
			_rect(im, 10, 4, 1, 5, Color.WHITE)
			_rect(im, 11, 5, 1, 3, Color.WHITE)
		"mitt": # envelope
			_rect(im, 1, 3, 10, 7, Color.WHITE)
			for i in 5:
				_px(im, 1 + i, 3 + i, Color("#9aa4ae"))
				_px(im, 10 - i, 3 + i, Color("#9aa4ae"))
		"veni": # footprints
			_rect(im, 2, 6, 3, 5, Color.WHITE)
			_rect(im, 7, 1, 3, 5, Color.WHITE)
			_rect(im, 2, 4, 1, 1, Color.WHITE)
			_rect(im, 4, 4, 1, 1, Color.WHITE)
			_rect(im, 7, 0, 1, 1, Color.WHITE)
			_rect(im, 9, 0, 1, 1, Color.WHITE)
		"curr": # running shoe with speed lines
			_rect(im, 5, 5, 3, 1, Color("#ff3b5c"))
			_rect(im, 5, 6, 6, 3, Color("#ff3b5c"))
			_rect(im, 5, 9, 7, 1, Color.WHITE)
			_rect(im, 0, 5, 4, 1, Color.WHITE)
			_rect(im, 1, 7, 3, 1, Color.WHITE)
			_rect(im, 0, 9, 4, 1, Color.WHITE)
	return outline(im)


static func _blit(im: Image, spr: Image, x: int, bottom: int, s: int) -> void:
	var top := bottom - spr.get_height() * s
	for py in spr.get_height():
		for px in spr.get_width():
			var c := spr.get_pixel(px, py)
			if c.a > 0.5:
				_rect(im, x + px * s, top + py * s, s, s, c)


static func _place(im: Image, spr: Image, x: int, bottom: int, plural: bool) -> void:
	if plural and spr.has_meta("plural"): # some things look different when there are more (a bunch of grapes)
		_blit(im, spr.get_meta("plural"), x, bottom, 2)
		return
	if plural:
		_blit(im, spr, x + 8, bottom - 3, 2)
	_blit(im, spr, x, bottom, 2)


static func _digit(im: Image, n: int, x: int, y: int, c: Color) -> void:
	var rows: Array = DIGITS.get(n, [])
	for r in rows.size():
		for col in 3:
			if rows[r][col] == "#":
				_rect(im, x + col * 2, y + r * 2, 2, 2, c)


## Adverbs and prepositional phrases, as little pictures along the top right:
## procul = far-off hills; ad = arrow to the noun; ab = arrow away from it;
## in + acc. = arrow into a box round it; in + abl. = it inside a box.
static func _mods(im: Image, mods: Array) -> void:
	var x := 62
	for m in mods:
		if m.has("modi"): # by means of: the thing, with a little "using it" spark
			var mn = m.get("noun")
			var ms := noun(mn["stem"]) if mn else _img(1, 1)
			_blit(im, ms, x, 21, 1)
			_star(im, x + ms.get_width() + 2, 6, Color("#ffd23f"))
			x += ms.get_width() + 9
			continue
		if m.has("adv"):
			for i in 9: # far-away hills
				_rect(im, x + 4 + i, 14 - mini(i, 8 - i), 1, mini(i, 8 - i) + 1, Color("#7a8a9a"))
			for k in 3:
				_px(im, x + 1 + k * 2, 16, Color.WHITE)
			x += 18
			continue
		var n = m.get("noun")
		var spr := noun(n["stem"]) if n else _img(1, 1)
		var arrow := Color("#ffd23f")
		match m["prep"]:
			"ad":
				_rect(im, x, 11, 5, 1, arrow)
				_px(im, x + 4, 10, arrow)
				_px(im, x + 4, 12, arrow)
				_blit(im, spr, x + 7, 21, 1)
			"ab":
				_blit(im, spr, x, 21, 1)
				var ax := x + spr.get_width() + 1
				_rect(im, ax, 11, 5, 1, arrow)
				_px(im, ax + 4, 10, arrow)
				_px(im, ax + 4, 12, arrow)
			"in":
				var bx := x + (6 if m["case"] == "acc" else 0)
				_blit(im, spr, bx + 1, 20, 1)
				for i in range(0, spr.get_width() + 2): # the box round it
					_px(im, bx + i, 0, arrow)
					_px(im, bx + i, 21, arrow)
				for j in 22:
					_px(im, bx, j, arrow)
					_px(im, bx + spr.get_width() + 1, j, arrow)
				if m["case"] == "acc": # moving into it
					_rect(im, x, 11, 5, 1, arrow)
					_px(im, x + 4, 10, arrow)
					_px(im, x + 4, 12, arrow)
		x += spr.get_width() + 9


static func _background() -> Image:
	var im := _img(W, H)
	im.fill(SKY)
	_rect(im, 0, 46, W, H - 46, GROUND)
	_rect(im, 0, 46, W, 1, Color("#6cc070"))
	_rect(im, 86, 4, 8, 8, Color("#ffe066"))
	return im


## sc: {state, verb, person, vnum, subj: {stem,num} | null, obj: {stem,num} | null}
## The verb: its picture, or (for verbs without one) its name on a sign.
static func _verb(im: Image, verb: String) -> void:
	if verb in ICONS:
		_blit(im, icon(verb), 38, 34, 2)
		return
	var t := _plain(Latin.head(verb))
	var w := t.length() * 4 + 3
	var x := 52 - w / 2
	_rect(im, x - 1, 15, w + 2, 11, INK)
	_rect(im, x, 16, w, 9, Color("#f4f1e6"))
	text(im, t, x + 2, 18, INK)


static func _plain(t: String) -> String:
	for pair in [["ā", "a"], ["ē", "e"], ["ī", "i"], ["ō", "o"], ["ū", "u"]]:
		t = t.replace(pair[0], pair[1])
	return t.to_lower()


## A noun on the screen; if it belongs to someone (genitive), its owner stands
## small in front of it with a little gold key.
static func _noun_at(im: Image, w: Dictionary, x: int, bottom: int) -> void:
	_place(im, noun_w(w), x, bottom, w["num"] == "pl")
	if w.has("own"):
		var own: Dictionary = w["own"]
		var spr := noun(own["stem"])
		var ox := x + 14
		_blit(im, spr, ox, bottom + 1, 1)
		if own["num"] == "pl":
			_blit(im, spr, ox + 6, bottom + 1, 1)
		_rect(im, ox - 3, bottom - 12, 3, 3, Color("#ffd23f")) # key: "belongs to"
		_rect(im, ox - 2, bottom - 9, 1, 4, Color("#ffd23f"))


## How each verb is staged: the subject's pose, what happens on screen ("fx"),
## and the object's pose. Verbs not listed get the plain icon (or name) picture.
const ACT := {
	"ama": {"fx": "heart", "pose": "reach"},
	"vide": {"fx": "gaze", "pose": "look"}, "specta": {"fx": "gaze", "pose": "look"}, "aspici": {"fx": "gaze", "pose": "look"},
	"audi": {"fx": "sound", "pose": "listen"},
	"porta": {"fx": "carry", "pose": "carry"},
	"capi": {"fx": "grab", "pose": "reach"}, "rapi": {"fx": "grab", "pose": "reach"}, "accipi": {"fx": "grab", "pose": "reach"},
	"habe": {"fx": "grab", "pose": "reach"}, "tene": {"fx": "grab", "pose": "reach"},
	"duc": {"fx": "lead", "pose": "lead", "opose": "walk"},
	"mitt": {"fx": "throw", "pose": "throw"}, "iaci": {"fx": "throw", "pose": "throw"},
	"veni": {"fx": "arrive", "pose": "walk"},
	"curr": {"fx": "speed", "pose": "run"},
	"fugi": {"fx": "flee", "pose": "run"},
	"ambula": {"fx": "steps", "pose": "walk"},
	"erra": {"fx": "wander", "pose": "walk"},
	"dormi": {"fx": "zzz", "pose": "sleep"},
	"bala": {"fx": "say", "say": "baa"},
	"voca": {"fx": "say", "say": "heus!", "pose": "point"},
	"lauda": {"fx": "say", "say": "*", "pose": "point"},
	"mone": {"fx": "say", "say": "!", "pose": "point"},
	"dic": {"fx": "say", "say": "..."},
	"doce": {"fx": "say", "say": "abc", "pose": "point"},
	"fla": {"fx": "wind"}, "inspira": {"fx": "wind", "pose": "reach"},
	"time": {"fx": "fear", "pose": "cower"},
	"terre": {"fx": "scare", "pose": "throw", "opose": "cower"},
	"iuva": {"fx": "help", "pose": "reach"},
	"arrig": {"fx": "raise"},
	"bib": {"fx": "drink", "pose": "listen"},
	"pugna": {"fx": "swords", "pose": "reach"}, "oppugna": {"fx": "swords", "pose": "reach"}, "neca": {"fx": "swords", "pose": "reach"},
	"sede": {"pose": "sit"},
	# with a dative: someone on the right it's given / shown / told to
	"da": {"fx": "give", "pose": "reach"},
	"monstra": {"fx": "show", "pose": "point"},
	"narra": {"fx": "say", "say": "...", "pose": "point"},
}
const YEL := Color("#ffd23f")


static func _line(im: Image, a: Vector2, b: Vector2, c: Color, step := 1) -> void:
	var n := maxi(1, int(a.distance_to(b)))
	for i in range(0, n + 1, step):
		var p := a.lerp(b, float(i) / n)
		_px(im, int(p.x), int(p.y), c)


static func _arc(im: Image, cx: float, cy: float, r: float, a0: float, a1: float, c: Color) -> void:
	for k in 24:
		var a := deg_to_rad(lerpf(a0, a1, k / 23.0))
		_px(im, int(cx + cos(a) * r), int(cy + sin(a) * r), c)


static func _star(im: Image, x: int, y: int, c: Color) -> void:
	_rect(im, x - 2, y, 5, 1, c)
	_rect(im, x, y - 2, 1, 5, c)
	_px(im, x - 1, y - 1, c)
	_px(im, x + 1, y - 1, c)
	_px(im, x - 1, y + 1, c)
	_px(im, x + 1, y + 1, c)


## A speech bubble with words (or a star) in it, its tail pointing at (tx, ty).
static func _bubble(im: Image, x: int, y: int, t: String, tx: int, ty: int) -> void:
	var w := (7 if t == "*" else t.length() * 4 + 3)
	_rect(im, x - 1, y - 1, w + 2, 11, INK)
	_rect(im, x, y, w, 9, Color.WHITE)
	_line(im, Vector2(x + 2, y + 9), Vector2(tx, ty), Color.WHITE)
	if t == "*":
		_star(im, x + 3, y + 4, YEL)
	else:
		text(im, t, x + 2, y + 2, INK)


## The little owner standing in front of a noun that belongs to someone (genitive).
static func _owner(im: Image, w, x: int, bottom: int) -> void:
	if w == null or not w.has("own"):
		return
	var own: Dictionary = w["own"]
	var spr := noun(own["stem"])
	var ox := x + 14
	_blit(im, spr, ox, bottom + 1, 1)
	if own["num"] == "pl":
		_blit(im, spr, ox + 6, bottom + 1, 1)
	_rect(im, ox - 3, bottom - 12, 3, 3, YEL) # key: "belongs to"
	_rect(im, ox - 2, bottom - 9, 1, 4, YEL)


## A passive picture is drawn from the doer's side: "puer ab lupō capitur" is the
## wolf grabbing the boy. (No "ab" agent: a grey "?" someone does it.)
static func _activate(sc: Dictionary) -> Dictionary:
	if sc.get("voice", "act") != "pass" or sc["state"] == "noend":
		return sc
	var out := sc.duplicate(true)
	out["obj"] = sc.get("subj")
	out["subj"] = null
	out["agentless"] = true
	var rest := []
	for m in sc.get("mods", []):
		if out["agentless"] and m.get("prep", "") == "ab" and m.get("noun") != null and is_creature(m["noun"]["stem"]):
			out["subj"] = m["noun"]
			out["agentless"] = false
		else:
			rest.append(m)
	out["mods"] = rest
	return out


## Pull out the first prepositional phrase: it becomes part of the scene.
static func _prep_of(sc: Dictionary) -> Array:
	var pm := {}
	var rest := []
	for m in sc.get("mods", []):
		if pm.is_empty() and m.has("prep") and m.get("noun") != null:
			pm = m
		else:
			rest.append(m)
	return [pm, rest]


static func _arrow(im: Image, x0: int, x1: int, y: int) -> void: # dotted, pointing right
	for x in range(x0, x1 - 2, 3):
		_px(im, x, y, Color.WHITE)
	_px(im, x1 - 2, y - 1, Color.WHITE)
	_px(im, x1 - 1, y, Color.WHITE)
	_px(im, x1 - 2, y + 1, Color.WHITE)


# ---------------------------------------------------------------- first person: through your own eyes

const SLEEVE := Color("#6a7a8a") # your sleeves
const SLEEVE2 := Color("#3f7fd9") # a friend's (for "we")


## A forearm coming up from the edge of the screen (from) to a hand (at).
static func _fore(im: Image, from: Vector2, at: Vector2, sleeve: Color) -> void:
	var n := maxi(1, int(from.distance_to(at)))
	for i in n + 1:
		var p := from.lerp(at, float(i) / n)
		_rect(im, int(p.x) - 4, int(p.y) - 4, 9, 9, INK)
	for i in n + 1:
		var p := from.lerp(at, float(i) / n)
		_rect(im, int(p.x) - 3, int(p.y) - 3, 7, 7, sleeve)
	var h := Vector2i(int(at.x), int(at.y))
	_rect(im, h.x - 5, h.y - 5, 11, 10, INK)
	_rect(im, h.x - 4, h.y - 4, 9, 8, SKIN)
	for f in 4: # fingers
		_rect(im, h.x - 4 + f * 2 + (f / 2), h.y - 7, 2, 3, SKIN)
		_px(im, h.x - 4 + f * 2 + (f / 2), h.y - 8, INK)


static func _hands_for(pose: String) -> Array: # [[from, at], [from, at]]: left hand, right hand
	match pose:
		"reach", "point":
			return [[Vector2(10, 62), Vector2(18, 50)], [Vector2(92, 62), Vector2(64, 32)]]
		"carry":
			return [[Vector2(22, 62), Vector2(38, 44)], [Vector2(82, 62), Vector2(66, 44)]]
		"look":
			return [[Vector2(10, 62), Vector2(16, 52)], [Vector2(104, 40), Vector2(82, 8)]]
		"listen":
			return [[Vector2(10, 62), Vector2(16, 52)], [Vector2(106, 52), Vector2(100, 24)]]
		"throw":
			return [[Vector2(10, 62), Vector2(26, 46)], [Vector2(100, 58), Vector2(92, 12)]]
		"lead":
			return [[Vector2(10, 62), Vector2(16, 52)], [Vector2(96, 62), Vector2(80, 46)]]
		"cower":
			return [[Vector2(20, 62), Vector2(38, 26)], [Vector2(84, 62), Vector2(66, 26)]]
		"run":
			return [[Vector2(6, 62), Vector2(14, 44)], [Vector2(98, 62), Vector2(90, 54)]]
	return [[Vector2(8, 62), Vector2(16, 52)], [Vector2(96, 62), Vector2(88, 52)]]


static func _compose_pov(sc: Dictionary, passive: bool) -> Image:
	var im := _background()
	var act: Dictionary = ACT.get(sc.get("verb", ""), {})
	var fx: String = act.get("fx", "")
	var pose: String = act.get("pose", "stand")
	var we: bool = sc.get("vnum", "sg") == "pl"
	var pp := _prep_of(sc)
	var pm: Dictionary = pp[0]
	if pm.get("prep", "") == "ad" or (pm.get("prep", "") == "in" and pm.get("case", "") == "acc"): # heading there
		_blit(im, noun(pm["noun"]["stem"]), 45, 46, 1)
		_line(im, Vector2(40, 56), Vector2(50, 46), Color.WHITE, 3)
		_line(im, Vector2(64, 56), Vector2(56, 46), Color.WHITE, 3)
	if passive: # someone does it to you: they face you, the action comes at you
		var ag = sc.get("subj")
		var spr := noun(ag["stem"], pose) if ag else person(PEOPLE["puer"], Color("#8796a6"), pose)
		_place(im, spr, 34, 47, ag != null and ag["num"] == "pl")
		if ag == null:
			text(im, "?", 50, 2, Color.WHITE)
		match fx:
			"heart":
				_blit(im, icon("ama"), 62, 44, 1)
				_line(im, Vector2(62, 30), Vector2(70, 40), Color.WHITE, 2)
			"gaze":
				_blit(im, icon("vide"), 70, 14, 1)
				_line(im, Vector2(54, 16), Vector2(52, 56), Color.WHITE, 3)
			"sound":
				for r in [5.0, 9.0, 13.0]:
					_arc(im, 52, 30, r, 40, 140, YEL)
			"grab", "lead", "throw", "swords", "scare":
				if ag != null and BEASTS.has(ag["stem"]): # claws, coming at you
					for k in 3:
						_line(im, Vector2(58 + k * 5, 30), Vector2(54 + k * 5, 50), Color.WHITE)
				else: # their hand, reaching out at you
					_fore(im, Vector2(64, 30), Vector2(56, 50), Color("#8a6a4a"))
			_:
				_line(im, Vector2(56, 34), Vector2(52, 56), Color.WHITE, 3)
		var cower := [[Vector2(18, 62), Vector2(30, 46)], [Vector2(86, 62), Vector2(74, 46)]] if fx in ["grab", "scare", "swords", "throw"] else _hands_for("stand")
		for k in 2:
			_fore(im, cower[k][0], cower[k][1], SLEEVE)
		_mods(im, pp[1])
		if sc["state"] == "error":
			_error_x(im)
		return im
	# you do it: what you're doing it to is in front of you, your hands come up from below
	var obj = sc.get("obj")
	var hands := _hands_for(pose)
	if obj:
		var ostem: String = obj["stem"]
		var opl: bool = obj["num"] == "pl"
		match fx:
			"carry": # held in your hands
				_blit(im, noun(ostem), 42, 46, 1)
			"grab": # held up in your outstretched hand
				_blit(im, noun(ostem, "cower"), 56, 26, 1)
			"lead": # out ahead of you on a rope
				_place(im, noun(ostem, "walk"), 30, 44, opl)
				_line(im, hands[1][1], Vector2(50, 26), Color("#c8a060"))
			"throw": # flying away from you
				_line(im, Vector2(88, 10), Vector2(56, 18), Color.WHITE, 3)
				_blit(im, noun(ostem), 44, 26, 1)
			"raise":
				_blit(im, noun(ostem), 66, 14, 1)
			_:
				_place(im, noun_w(obj, act.get("opose", "stand")), 34, 46, opl)
				_owner(im, obj, 34, 46)
	match fx:
		"heart":
			_blit(im, icon("ama"), 70, 26, 1)
		"gaze": # what you're looking at, in focus
			for c in [[30, 4], [70, 4], [30, 44], [70, 44]]:
				_rect(im, c[0], c[1], 4, 1, Color.WHITE)
				_rect(im, c[0] + (3 if c[0] > 50 else 0), c[1] - (3 if c[1] > 20 else 0), 1, 4, Color.WHITE)
		"sound":
			for r in [6.0, 10.0, 14.0]:
				_arc(im, 52, 26, r, -60, 60, YEL)
		"say":
			_bubble(im, 34, 4, act.get("say", "..."), 52, 54)
		"wind", "fear", "help":
			pass
		"speed", "flee":
			for y in [10, 20, 30]:
				_rect(im, 0, y, 8, 1, Color.WHITE)
				_rect(im, 96, y + 4, 8, 1, Color.WHITE)
		"arrive", "steps", "wander":
			for k in 6: # the way ahead, getting smaller
				var y := 54 - k * 3
				var hw := 10 - k
				_rect(im, 52 - hw, y, 2, 1, Color("#e8d8a8"))
				_rect(im, 52 + hw, y, 2, 1, Color("#e8d8a8"))
			if fx == "arrive":
				_rect(im, 52, 26, 1, 12, Color("#d0d0d0"))
				_rect(im, 53, 26, 4, 3, Color("#e0283a"))
			if fx == "wander":
				text(im, "?", 50, 4, Color.WHITE)
	if fx == "wind": # breath / wind going out ahead of you
		for k in 3:
			for y in range(18, 52):
				_px(im, 44 + k * 6 + int(sin(y * 0.5 + k) * 2.0), y, Color("#cfe8ff"))
	if fx == "help":
		for p in [Vector2i(30, 10), Vector2i(74, 12), Vector2i(72, 34)]:
			_star(im, p.x, p.y, YEL)
	if fx == "drink": # the cup at your lips
		_rect(im, 30, 46, 44, 10, Color("#b07a3a"))
		_rect(im, 32, 46, 40, 3, Color("#7ec8ff"))
	elif pose == "sit": # your knees
		_rect(im, 30, 48, 18, 8, Color("#2d3550"))
		_rect(im, 56, 48, 18, 8, Color("#2d3550"))
	if fx != "drink" and pose != "sleep":
		if we: # a friend's hand too: "we"
			_fore(im, Vector2(-4, 40), Vector2(10, 30), SLEEVE2)
		for k in 2:
			_fore(im, hands[k][0], hands[k][1], SLEEVE)
	if fx == "fear":
		for side in [0, 1]:
			for k in 3:
				_rect(im, 4 + side * 92 + k * 2 * (1 - 2 * side), 12 + k * 10, 1, 6, Color.WHITE)
	if fx == "swords":
		_line(im, hands[1][1], Vector2(54, 6), Color("#d0d0d0"))
		_line(im, hands[1][1] + Vector2(1, 0), Vector2(55, 6), Color("#d0d0d0"))
	if pose == "sleep" or fx == "zzz": # eyes closing
		_rect(im, 0, 0, W, 20, Color("#1a1a24"))
		_rect(im, 0, 38, W, 18, Color("#1a1a24"))
		for k in 3:
			text(im, "z", 60 + k * 6, 30 - k * 4, Color.WHITE)
	_mods(im, pp[1])
	if sc["state"] == "error":
		_error_x(im)
	return im


static func compose(sc_in: Dictionary) -> Image:
	var sc := _activate(sc_in)
	if sc_in.get("person", 3) == 1 and sc_in["state"] != "noend": # I / we: seen through your own eyes
		return _compose_pov(sc, sc_in.get("voice", "act") == "pass")
	var verb: String = sc.get("verb", "")
	if sc["state"] == "noend" or not ACT.has(verb):
		return _compose_plain(sc)
	var im := _background()
	var pp := _prep_of(sc)
	var pm: Dictionary = pp[0]
	var dest: bool = pm.get("prep", "") == "ad" or (pm.get("prep", "") == "in" and pm.get("case", "") == "acc")
	var origin: bool = pm.get("prep", "") == "ab"
	var inside: bool = pm.get("prep", "") == "in" and pm.get("case", "") == "abl"
	var act: Dictionary = ACT[verb]
	var fx: String = act.get("fx", "")
	var pose: String = act.get("pose", "stand")
	var opose: String = act.get("opose", "stand")
	var subj = sc.get("subj")
	var obj = sc.get("obj")
	var spl: bool = subj["num"] == "pl" if subj else sc["vnum"] == "pl"
	var sx := 2
	match fx:
		"lead", "arrive": sx = 58
		"flee": sx = 62
		"speed": sx = 16
		"carry": sx = 22
		"wander", "steps": sx = 40
	var obj0 = sc.get("obj")
	if origin: # coming away from a place: it's behind them, on the left
		sx = maxi(sx, 40)
		_place(im, noun(pm["noun"]["stem"]), 0, 47, pm["noun"]["num"] == "pl")
		_arrow(im, 30, sx, 44)
	if dest and obj0 == null: # going to a place: it's ahead of them, on the right
		sx = mini(sx, 24)
		var dx := 68
		_place(im, noun(pm["noun"]["stem"]), dx, 47, pm["noun"]["num"] == "pl")
		if pm["prep"] == "in": # into it: a doorway round it
			_rect(im, dx - 3, 6, 1, 41, YEL)
			_rect(im, dx + 34, 6, 1, 41, YEL)
			_rect(im, dx - 3, 6, 38, 1, YEL)
		_arrow(im, sx + 34, dx - 2, 44)
	elif dest: # there's an object too: the place sits small, top right
		_blit(im, noun(pm["noun"]["stem"]), 86, 20, 1)
		_arrow(im, 70, 85, 12)
	if inside: # in a place: they're in it (it's drawn round / behind them)
		_place(im, noun(pm["noun"]["stem"]), sx - 4, 47, false)
	var sspr := noun_w(subj, pose) if subj else person(PEOPLE["puer"], Color("#8796a6"), pose)
	var head := Vector2(sx + 18, 17) # where things on a person are, at screen scale
	var mouth := Vector2(sx + 21, 21)
	var hand := Vector2(sx + 34, 25)
	# --- what happens, drawn behind the figures
	match fx:
		"speed":
			for y in [20, 28, 36]:
				_rect(im, sx - 14, y, 10, 1, Color.WHITE)
		"flee":
			for y in [22, 30, 38]:
				_rect(im, sx - 12, y, 8, 1, Color.WHITE)
		"steps", "arrive":
			for x in range(4, sx - 2, 7):
				_rect(im, x, 47 + (x / 7) % 2 * 2, 3, 1, Color("#e8d8a8"))
			if fx == "arrive": # where they're arriving: a little flag
				_rect(im, 98, 20, 1, 27, Color("#d0d0d0"))
				_rect(im, 99, 20, 5, 4, Color("#e0283a"))
		"wander":
			for x in range(2, sx, 2):
				_px(im, x, 42 + int(sin(x * 0.35) * 3.0), Color.WHITE)
	# --- the object
	var opl: bool = obj != null and obj["num"] == "pl"
	var dat = sc.get("dat")
	if dat: # the one it's for, on the right, facing them
		var dpl: bool = dat["num"] == "pl"
		var dspr := noun_w(dat, "reach" if fx == "give" else "stand")
		dspr.flip_x() # (turned to face the giver)
		_place(im, dspr, 70 if not dpl else 64, 47, dpl)
		_owner(im, dat, 70 if not dpl else 64, 47)
	if obj and dat: # what's given / shown / told, passing between them
		var ost: String = obj["stem"]
		_blit(im, noun(ost), 44, 40, 1)
		if opl:
			_blit(im, noun(ost), 50, 38, 1)
		if fx == "give":
			_arrow(im, 40, 68, 44)
		elif fx == "show":
			for p in [Vector2i(46, 14), Vector2i(58, 10)]:
				_star(im, p.x, p.y, YEL)
	elif obj:
		var ostem: String = obj["stem"]
		match fx:
			"carry": # carried in front, in the arms
				_place(im, sspr, sx, 47, spl)
				_blit(im, noun(ostem), sx + 9, 39, 1)
				if opl:
					_blit(im, noun(ostem), sx + 15, 37, 1)
				for y in [24, 30, 36]:
					_rect(im, sx - 12, y, 8, 1, Color.WHITE)
				sspr = null
			"grab": # held out in the hand
				_blit(im, noun(ostem, "cower"), int(hand.x) - 4, int(hand.y) + 12, 1)
				if opl:
					_blit(im, noun(ostem, "cower"), int(hand.x) + 4, int(hand.y) + 10, 1)
				text(im, "!", int(hand.x) + 4, 4, YEL)
			"lead": # following behind on a rope
				_place(im, noun(ostem, opose), 4, 47, opl)
				_line(im, Vector2(sx + 2, 25), Vector2(34, 27), Color("#c8a060"))
			"throw":
				if is_creature(ostem): # people / animals are sent off: walking away, an arrow after them
					_place(im, noun(ostem, "walk"), 64 if not opl else 58, 47, opl)
					_rect(im, 40, 39, 18, 2, Color.WHITE)
					_rect(im, 56, 37, 2, 6, Color.WHITE)
				else: # things fly through the air
					_line(im, Vector2(hand.x - 14, 8), Vector2(54, 14), Color.WHITE, 3)
					_blit(im, noun(ostem), 54, 28, 1)
			"flee":
				_place(im, noun(ostem, "stand"), 4, 47, opl)
			_:
				_place(im, noun_w(obj, opose), 66 if not opl else 60, 47, opl)
				_owner(im, obj, 66 if not opl else 60, 47)
	# --- the subject
	if sspr:
		if pose == "sleep":
			_blit(im, sspr, sx, 47, 2)
		else:
			_place(im, sspr, sx, 47, spl)
	_owner(im, subj, sx, 47)
	if subj == null and sc.get("agentless", false):
		text(im, "?", sx + 16, 2, Color.WHITE) # someone (we're not told who) does it
	elif subj == null:
		_digit(im, sc["person"], sx + 8, 2, Color.WHITE)
	# --- what happens, drawn in front
	var ohead := Vector2(66 + 18, 17)
	match fx:
		"heart":
			_blit(im, icon("ama"), 40, 34, 2)
		"gaze":
			_line(im, head + Vector2(4, -2), Vector2(ohead.x - 6, ohead.y - 2) if obj else Vector2(100, 15), Color.WHITE, 3)
			_blit(im, icon("vide"), 44, 12, 1)
		"sound":
			for r in [5.0, 9.0, 13.0]:
				_arc(im, 66, 22, r, 140, 220, YEL)
		"zzz":
			for k in 3:
				text(im, "z", sx + 30 + k * 6, 14 - k * 5, Color.WHITE)
		"say":
			_bubble(im, sx + 30, 3, act.get("say", "..."), int(mouth.x), int(mouth.y))
		"wind":
			for k in 3:
				for x in range(int(mouth.x) + 2, 64, 1):
					_px(im, x, int(mouth.y) - 4 + k * 4 + int(sin(x * 0.5 + k) * 1.5), Color("#cfe8ff"))
		"fear": # shaking, sweating
			for side in [-1, 1]:
				for k in 3:
					_rect(im, int(head.x) + side * (14 + k * 3), int(head.y) + 2 + k * 6, 1, 4, Color.WHITE)
			_rect(im, int(head.x) + 9, int(head.y) - 6, 1, 2, Color("#7ec8ff"))
			_rect(im, int(head.x) + 10, int(head.y) - 4, 2, 2, Color("#7ec8ff"))
		"scare":
			text(im, "!", 50, 14, Color("#ff5a5a"))
			text(im, "!", 56, 10, Color("#ff5a5a"))
		"help":
			for p in [Vector2i(64, 12), Vector2i(98, 8), Vector2i(96, 26)]:
				_star(im, p.x, p.y, YEL)
		"raise":
			_rect(im, int(head.x) + 12, 6, 1, 12, YEL)
			_px(im, int(head.x) + 11, 7, YEL)
			_px(im, int(head.x) + 13, 7, YEL)
		"drink":
			_rect(im, int(mouth.x), int(mouth.y) - 2, 4, 4, Color("#b07a3a"))
			_rect(im, int(mouth.x) + 1, int(mouth.y) - 2, 2, 1, Color("#7ec8ff"))
		"swords":
			_line(im, Vector2(42, 16), Vector2(60, 36), Color("#d0d0d0"))
			_line(im, Vector2(60, 16), Vector2(42, 36), Color("#d0d0d0"))
			_star(im, 51, 26, YEL)
		"wander":
			text(im, "?", int(head.x) + 8, 2, Color.WHITE)
	_mods(im, pp[1])
	if sc["state"] == "error":
		_error_x(im)
	return im


static func _error_x(im: Image) -> void: # big red X: the cables say something ungrammatical
	for i in range(-16, 17):
		_rect(im, W / 2 + i - 1, H / 2 + i - 1, 3, 3, Color("#ff2a2a"))
		_rect(im, W / 2 + i - 1, H / 2 - i - 1, 3, 3, Color("#ff2a2a"))


## Verbs without their own staging: subject, the verb's icon (or name), an arrow, the object.
static func _compose_plain(sc: Dictionary) -> Image:
	var im := _background()
	if sc["state"] == "noend": # a verb with no ending yet: who's doing it?
		_verb(im, sc["verb"])
		text(im, "?", 70, 14, Color.WHITE)
		return im
	var pp := _prep_of(sc)
	var pm: Dictionary = pp[0]
	var obj = sc.get("obj")
	if pm.get("prep", "") == "ab" or (pm.get("prep", "") == "in" and pm.get("case", "") == "abl"):
		_blit(im, noun(pm["noun"]["stem"]), 0, 47, 1) # where they are / come from, small behind them
	var subj = sc.get("subj")
	if subj:
		_noun_at(im, subj, 2, 47)
	else: # no noun subject: grey stand-in, numbered by person (or "?" for a passive)
		_place(im, person(PEOPLE["puer"], Color("#8796a6")), 2, 47, sc["vnum"] == "pl")
		if sc.get("agentless", false):
			text(im, "?", 18, 2, Color.WHITE)
		else:
			_digit(im, sc["person"], 10, 2, Color.WHITE)
	_verb(im, sc["verb"])
	if obj:
		_rect(im, 40, 39, 20, 2, Color.WHITE)
		_rect(im, 58, 37, 2, 6, Color.WHITE)
		_rect(im, 60, 38, 2, 4, Color.WHITE)
		_noun_at(im, obj, 66, 47)
	elif pm.get("prep", "") == "ad" or (pm.get("prep", "") == "in" and pm.get("case", "") == "acc"): # where they're going
		_place(im, noun(pm["noun"]["stem"]), 68, 47, false)
		_arrow(im, 40, 66, 44)
	_mods(im, pp[1])
	if sc["state"] == "error":
		_error_x(im)
	return im


## The PROBA ("test it") button in the bottom-right corner of the picture.
const BTN := Rect2i(79, 48, 24, 8)


static func submit_button(im: Image) -> void:
	_rect(im, BTN.position.x - 1, BTN.position.y - 1, BTN.size.x + 2, BTN.size.y + 2, INK)
	_rect(im, BTN.position.x, BTN.position.y, BTN.size.x, BTN.size.y, Color("#ffd23f"))
	text(im, "proba", BTN.position.x + 2, BTN.position.y + 2, INK)


static func on_button(px: float, py: float) -> bool:
	return Rect2(BTN).grow(1.0).has_point(Vector2(px, py))


static func verdict(im: Image, ok: bool) -> void:
	var c := Color("#3fae5a") if ok else Color("#d8423a")
	_rect(im, 0, 0, W, 10, INK)
	_rect(im, 0, 0, W, 9, c)
	var t := "recte!" if ok else "non idem"
	text(im, t, (W - t.length() * 4) / 2, 2, Color.WHITE)


## The board with no picture task on: "take a note" (from the board on the left).
static func idle_board() -> Image:
	var im := _background()
	_rect(im, 22, 14, 60, 22, Color("#ffe066"))
	_rect(im, 22, 14, 60, 1, INK)
	text(im, "accipe", 40, 18, INK)
	text(im, "chartam", 38, 26, INK)
	return im


## The last sheet on the billboard.
static func finis() -> Image:
	var im := _background()
	text(im, "finis!", 40, 20, Color.WHITE)
	text(im, "optime", 38, 28, Color("#ffd23f"))
	return im


static func noise(hint := false) -> Image:
	var im := _img(W, H)
	for y in H:
		for x in W:
			var v := randf() * 0.35 + 0.05
			im.set_pixel(x, y, Color(v, v * 1.1, v * 1.15))
	if hint: # "connect the cable to a verb"
		_rect(im, 14, 18, 76, 20, Color("#0d1f17"))
		text(im, "adnecte filvm", 26, 21, PHOSPHOR)
		text(im, "ad verbvm", 34, 29, PHOSPHOR)
	return im
