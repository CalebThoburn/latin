extends SceneTree
## Contact sheet of first-person pictures (I / we, active and passive). Output path after "--".


func _init() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var n := func(stem: String, num := "sg") -> Dictionary: return {"stem": stem, "num": num}
	var sc := func(v: String, obj, num := "sg", voice := "act", mods := []) -> Dictionary:
		return {"state": "scene", "verb": v, "person": 1, "vnum": num, "subj": null, "obj": obj, "mods": mods, "voice": voice}
	var scenes := [
		sc.call("ama", n.call("puell")), sc.call("vide", n.call("equ")), sc.call("porta", n.call("aqu")),
		sc.call("capi", n.call("fruct")), sc.call("audi", n.call("matr")), sc.call("duc", n.call("equ")),
		sc.call("iaci", n.call("fruct")), sc.call("curr", null, "pl"), sc.call("dormi", null),
		sc.call("voca", n.call("serv"), "pl"), sc.call("ama", null, "sg", "pass", [{"prep": "ab", "case": "abl", "noun": n.call("puell")}]),
		sc.call("capi", null, "pl", "pass", [{"prep": "ab", "case": "abl", "noun": n.call("lup")}]),
		sc.call("vide", null, "sg", "pass"), sc.call("ambula", null, "sg", "act", [{"prep": "ad", "case": "acc", "noun": n.call("cas")}]),
		sc.call("bib", n.call("aqu")),
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
