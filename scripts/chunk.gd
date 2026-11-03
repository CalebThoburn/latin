class_name Chunk
extends Node3D
## A row of pieces lying on the table. Stem+ending pairs are words; a row of
## words is a sentence. The node's origin is the row's left edge.

const GAP_WORD := 0.13 # room for a plug to slide in between words
const GAP_JOIN := 0.003

var tiles: Array = []
var width := 0.0
var analysis := {}
var tags: Array = []


func layout(animate := true) -> void:
	var right := 0.0
	for i in tiles.size():
		var t: Tile = tiles[i]
		t.set_insert_hidden(false)
		var left := 0.0
		if i > 0:
			var p: Tile = tiles[i - 1]
			if t.kind == "ending" and p.kind == "stem":
				var mode := "beside"
				if t.cat == "verb" and p.vclass != "":
					mode = Latin.join_mode(p.key, t.key)
				t.set_insert_hidden(mode == "tuck")
				match mode:
					"tuck": # the plug slides fully inside the vowel knob
						left = p.target_pos.x + p.knob_x - Tile.KNOB_L * 0.5
					"over": # the ō cap slips over the whole ā knob
						left = p.target_pos.x + p.knob_x - Tile.KNOB_L * 0.5 + 0.001
					_:
						left = right + GAP_JOIN
			elif is_cap(t) and p.kind == "ending": # the adjective cap slips over the end of the ending
				left = right - Tile.CAP_OVER
			else:
				left = right + GAP_WORD
		t.target_pos = Vector3(left + t.width * 0.5, Tile.H * 0.5, 0)
		right = maxf(right, left + t.width)
		if t.move_tween:
			t.move_tween.kill()
		if animate:
			t.move_tween = t.create_tween().set_parallel()
			t.move_tween.tween_property(t, "position", t.target_pos, 0.22) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.move_tween.tween_property(t, "scale", Vector3.ONE, 0.15)
		else:
			t.position = t.target_pos
			t.scale = Vector3.ONE
		t.rotation = Vector3.ZERO
	width = right
	for i in tiles.size():
		var t: Tile = tiles[i]
		t.cord_covered = t.kind == "stem" and t.cord_dir == Vector3.RIGHT and i + 1 < tiles.size() and tiles[i + 1].kind == "ending"
		if t.kind == "stem":
			t.set_joined(i + 1 < tiles.size() and tiles[i + 1].kind == "ending")
		else:
			t.set_joined(i > 0 and tiles[i - 1].kind == "stem")


## Where an ending's left edge sits (stem-local x) once it is fully on the stem,
## and how far it slides while going on (insert into a knob, pins into holes...).
static func seat(stem: Tile, ending: Tile) -> Dictionary:
	var right := stem.width * 0.5
	if ending.cat == "verb" and stem.vclass != "":
		match Latin.join_mode(stem.key, ending.key):
			"tuck": return {"x": stem.knob_x - Tile.KNOB_L * 0.5, "contact": right}
			"over": return {"x": stem.knob_x - Tile.KNOB_L * 0.5 + 0.001, "contact": right}
		return {"x": right + GAP_JOIN, "contact": right + 0.012}
	if Latin.SHARED.has(ending.cat): # magnets: no pins, it just clicks flat onto the face
		return {"x": right + GAP_JOIN, "contact": right + 0.006}
	if ending.cat != "verb": # noun ending: its pins slide into the stem's holes
		return {"x": right + GAP_JOIN, "contact": right + Tile.PIN_L}
	return {"x": right + GAP_JOIN, "contact": right + 0.012}


static func is_cap(t) -> bool:
	return t is Tile and t.kind == "adapter" and t.key == "adj"


## The cap on this ending (or on the ending of this stem), if it has one.
func cap_of(t: Tile) -> Tile:
	var i := tiles.find(t)
	if i < 0:
		return null
	if t.kind == "stem" and i + 1 < tiles.size() and tiles[i + 1].kind == "ending":
		i += 1
	if i + 1 < tiles.size() and is_cap(tiles[i + 1]) and tiles[i].kind == "ending":
		return tiles[i + 1]
	return null


func get_words() -> Array:
	var out := []
	var i := 0
	while i < tiles.size():
		var t: Tile = tiles[i]
		if t.kind == "stem":
			var w := {"stem": t.key, "ending": "", "cat": "", "tiles": [t]}
			if i + 1 < tiles.size() and tiles[i + 1].kind == "ending":
				var e: Tile = tiles[i + 1]
				w["ending"] = e.key
				w["cat"] = e.cat
				w["tiles"].append(e)
				i += 1
				if i + 1 < tiles.size() and is_cap(tiles[i + 1]): # an adjective: its cap goes with it
					w["tiles"].append(tiles[i + 1])
					w["cap"] = true
					i += 1
			out.append(w)
		else:
			out.append({"stem": "", "ending": t.key, "cat": t.cat, "tiles": [t]})
		i += 1
	return out


## Little handwritten notes on the table under each word.
func set_tags(texts: Array, words: Array) -> void:
	for l in tags:
		l.queue_free()
	tags.clear()
	for i in words.size():
		if i >= texts.size() or texts[i] == "":
			continue
		var x0 := INF
		var x1 := -INF
		for t: Tile in words[i]["tiles"]:
			x0 = minf(x0, t.target_pos.x - t.width * 0.5)
			x1 = maxf(x1, t.target_pos.x + t.width * 0.5)
		var l := Art.label3d(texts[i], 40, 0.001)
		l.rotation_degrees = Vector3(-90, 0, 0)
		l.position = Vector3((x0 + x1) * 0.5, 0.002, Tile.D * 0.5 + 0.045)
		l.modulate = Color(Art.INK, 0.85)
		add_child(l)
		tags.append(l)


## Where a dragged row of width `w` could go. Each slot gives the local x
## the dragged row's left edge should be near.
func slots(for_ending: bool, w: float) -> Array:
	var out := []
	if for_ending:
		for i in tiles.size():
			var t: Tile = tiles[i]
			if t.kind != "stem":
				continue
			var has_end: bool = i + 1 < tiles.size() and tiles[i + 1].kind == "ending"
			var right := t.target_pos.x + t.width * 0.5
			out.append({"index": i + 1, "x": right + GAP_JOIN, "replace": i + 1 if has_end else -1})
			if has_end:
				var e: Tile = tiles[i + 1]
				out.append({"index": i + 1, "x": e.target_pos.x + e.width * 0.5 + GAP_JOIN, "replace": i + 1})
	else:
		out.append({"index": 0, "x": -GAP_WORD - w, "replace": -1, "before": true})
		for k in range(1, tiles.size() + 1):
			if k < tiles.size() and tiles[k].kind == "ending":
				continue
			var right := 0.0
			for j in k: # right edge of everything before the slot (ō may overhang)
				var p: Tile = tiles[j]
				right = maxf(right, p.target_pos.x + p.width * 0.5)
			out.append({"index": k, "x": right + GAP_WORD, "replace": -1})
	return out


static func validate(list: Array) -> Dictionary:
	for i in list.size():
		var t: Tile = list[i]
		if t.broken:
			return {"ok": false, "broken": true, "msg": "It's broken. Throw it in the bin."}
		if t.kind != "ending":
			continue
		if i == 0:
			return {"ok": false, "msg": "An ending needs a stem in front of it."}
		var p: Tile = list[i - 1]
		if p.kind == "ending":
			return {"ok": false, "msg": "That word already has an ending."}
		var r := Latin.combine(p.key, t.cat, t.key)
		if not r["ok"]:
			return r
		if not Latin.ending_unlocked(t.cat, t.key) and not t.soldered:
			return {"ok": false, "msg": "-%s isn't unlocked yet." % t.key}
	return {"ok": true}


func bounce(amount := 1.08) -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * amount, 0.08)
	tw.tween_property(self, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func shake() -> void:
	var x0 := position.x
	var tw := create_tween()
	for i in 4:
		tw.tween_property(self, "position:x", x0 + (0.025 if i % 2 == 0 else -0.025), 0.04)
	tw.tween_property(self, "position:x", x0, 0.04)
