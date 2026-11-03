extends SceneTree
## Contact sheet of pictures with prepositions and passives (output path after "--").


func _init() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var n := func(stem: String, num := "sg") -> Dictionary: return {"stem": stem, "num": num}
	var sc := func(v: String, subj, obj, mods: Array, num := "sg", voice := "act") -> Dictionary:
		return {"state": "scene", "verb": v, "person": 3, "vnum": num, "subj": subj, "obj": obj, "mods": mods, "voice": voice}
	var scenes := [
		sc.call("curr", n.call("puer"), null, [{"prep": "ad", "case": "acc", "noun": n.call("riv")}]),
		sc.call("veni", n.call("naut", "pl"), null, [{"prep": "ab", "case": "abl", "noun": n.call("litor")}], "pl"),
		sc.call("ambula", n.call("puell"), null, [{"prep": "in", "case": "acc", "noun": n.call("cas")}]),
		sc.call("dormi", n.call("agricol"), null, [{"prep": "in", "case": "abl", "noun": n.call("silv")}]),
		sc.call("duc", n.call("reg"), n.call("milit", "pl"), [{"prep": "in", "case": "acc", "noun": n.call("silv")}]),
		sc.call("erra", n.call("greg"), null, [{"adv": "procul"}, {"prep": "ad", "case": "acc", "noun": n.call("riv")}]),
		sc.call("capi", n.call("puer"), null, [{"prep": "ab", "case": "abl", "noun": n.call("lup")}], "sg", "pass"),
		sc.call("ama", n.call("puell"), null, [], "sg", "pass"),
		sc.call("vide", n.call("equ", "pl"), null, [{"prep": "ab", "case": "abl", "noun": n.call("agricol")}], "pl", "pass"),
		sc.call("fugi", n.call("puer"), null, [{"prep": "ab", "case": "abl", "noun": n.call("lup")}]),
		sc.call("habita", n.call("agricol"), null, [{"prep": "in", "case": "abl", "noun": n.call("cas")}]),
		sc.call("time", n.call("puer"), n.call("lup"), [{"prep": "in", "case": "abl", "noun": n.call("silv")}]),
	]
	var cols := 3
	var s := 3
	var w := PixelArt.W * s + 6
	var h := PixelArt.H * s + 6
	var sheet := Image.create(w * cols, h * ceili(scenes.size() / float(cols)), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#222"))
	for i in scenes.size():
		var im := PixelArt.compose(scenes[i])
		im.resize(PixelArt.W * s, PixelArt.H * s, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i((i % cols) * w + 3, (i / cols) * h + 3))
	sheet.save_png(out)
	print("saved ", scenes.size())
	quit()
