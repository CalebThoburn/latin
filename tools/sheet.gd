extends SceneTree
## Renders a contact sheet of computer pictures (one per verb, plus the board's
## puzzles) to the PNG path given after "--". Run:
##   godot --headless --path . --script tools/sheet.gd -- out.png


func _init() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "sheet.png"
	var scenes := []
	var s := {"num": "sg"}
	var mk := func(v: String, subj: String, obj, num := "sg", onum := "sg") -> Dictionary:
		return {"state": "scene", "verb": v, "person": 3, "vnum": num, "subj": {"stem": subj, "num": num},
				"obj": ({"stem": obj, "num": onum} if obj else null), "mods": []}
	for e in [["ama", "puell", "puer"], ["vide", "agricol", "equ"], ["audi", "matr", "fili"], ["porta", "serv", "aqu"],
			["capi", "lup", "puer"], ["duc", "reg", "milit"], ["mitt", "domin", "serv"], ["iaci", "puer", "fruct"],
			["veni", "naut", null], ["curr", "can", null], ["fugi", "puell", "lup"], ["erra", "greg", null],
			["dormi", "puer", null], ["bala", "greg", null], ["voca", "matr", "fili"], ["lauda", "regin", "poet"],
			["fla", "puer", null], ["time", "puer", "lup"], ["terre", "leon", "naut"], ["iuva", "amic", "pauper"],
			["arrig", "equ", "aur"], ["bib", "agricol", "aqu"], ["pugna", "milit", null], ["sede", "magistr", null],
			["dormi", "can", null], ["curr", "equ", null]]:
		scenes.append(mk.call(e[0], e[1], e[2]))
	var pl: Dictionary = mk.call("porta", "agricol", "fruct", "sg", "pl")
	scenes.append(pl)
	var cap: Dictionary = mk.call("capi", "lup", "puer", "pl", "pl")
	scenes.append(cap)
	var cols := 4
	var sc := 3
	var w := PixelArt.W * sc + 6
	var h := PixelArt.H * sc + 6
	var rows := ceili(scenes.size() / float(cols))
	var sheet := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#222"))
	for i in scenes.size():
		var im := PixelArt.compose(scenes[i])
		im.resize(PixelArt.W * sc, PixelArt.H * sc, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i((i % cols) * w + 3, (i / cols) * h + 3))
	sheet.save_png(out)
	print("saved ", scenes.size(), " pictures to ", out)
	quit()
