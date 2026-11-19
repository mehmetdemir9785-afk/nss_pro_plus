extends Control
## Kaydırarak şut: yön = nişan, uzunluk = yükseklik, hız = sertlik, kavis = falso.
signal done(result)

const GL := 80.0
const GR := 280.0
const GB := 150.0
const GT := 80.0
const GW := 200.0
const GH := 70.0
const LW := 360.0
const LH := 560.0

var o := {}
var train := false
var kind := "box"
var bx := 180.0
var by := 400.0
var obst := []
var targets := []
var shots := 0
var hits := 0
var max_shots := 1
var ks := .5
var kx := .5
var kxT := .5
var kAng := 0.0
var kAngT := 0.0
var kLift := 0.0
var kLiftT := 0.0
var phase := "aim"
var pts := []
var anim = null
var msg := ""
var msg_col := Color.WHITE
var msg_t := 0
var flash := 0.0
var net_shake := 0.0
var pid := .5
var sc := 1.0
var off := Vector2.ZERO
var fd: Font
var fb: Font
var title_l: Label
var sub_l: Label
var help_l: Label
var finished := false

func setup(opts: Dictionary) -> void:
	o = opts
	train = o.get("kind", "") == "train"
	kind = o.get("kind", "box")
	ks = o.get("ks", .5)
	max_shots = 5 if train else 1
	if o.get("pen", false): pid = [.2, .2, .5, .8, .8][randi() % 5]

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	fd = UI.font(true, 900); fb = UI.font(false, 600)
	var top := UI.vbox(4); add_child(top)
	top.set_anchors_and_offsets_preset(PRESET_TOP_WIDE); top.offset_top = 26; top.offset_left = 24; top.offset_right = -24
	title_l = UI.lbl(o.get("title", "Şut"), 60, UI.CHALK, true, 900, HORIZONTAL_ALIGNMENT_CENTER); top.add_child(title_l)
	sub_l = UI.lbl(o.get("sub", ""), 26, UI.CHALK2, false, 500, HORIZONTAL_ALIGNMENT_CENTER); top.add_child(sub_l)
	help_l = UI.lbl("", 25, UI.CHALK2, false, 500, HORIZONTAL_ALIGNMENT_CENTER); add_child(help_l)
	help_l.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE); help_l.offset_top = -150; help_l.offset_bottom = -24; help_l.offset_left = 36; help_l.offset_right = -36
	help_l.text = "Kaydır: nişan. Uzun: yüksek. Hızlı: sert. Kavisli: falso." if G.S.tut.shot else "Parmağını ekrana koy ve kaleye doğru kaydır.\nKaydırma yönü nişan, uzunluğu yükseklik, hızı şut sertliği. Kavisli çizersen top falso alır."
	_place(); _setup_obst()

func _place() -> void:
	match kind:
		"close": by = 330; bx = randf_range(120, 240)
		"box": by = 395; bx = randf_range(100, 260)
		"long": by = 480; bx = randf_range(95, 265)
		"fk": by = 455; bx = randf_range(115, 245)
		"pen": by = 345; bx = 180
		_:
			if o.get("fk", false): by = 455; bx = randf_range(115, 245)
			else: by = 420; bx = randf_range(130, 230)

func _setup_obst() -> void:
	obst = []; targets = []
	if kind == "box": obst.append({"x": bx + randf_range(-18, 18) + (180 - bx) * .35, "y": by - randf_range(80, 120), "hw": 13.0, "h": .7, "wall": false})
	if kind == "long":
		for i in 2: obst.append({"x": bx + (180 - bx) * randf_range(.2, .6) + randf_range(-40, 40), "y": by - randf_range(90, 230), "hw": 13.0, "h": .7, "wall": false})
	if kind == "fk" or (train and o.get("fk", false)):
		var wy := by - 95; var f := (by - wy) / (by - GB)
		var wx := bx + (180 - bx) * f + (-1 if bx < 180 else 1) * randf_range(4, 12)
		for i in [-1.5, -.5, .5, 1.5]: obst.append({"x": wx + i * 17, "y": wy, "hw": 9.0, "h": .82, "wall": true})
	if train:
		for i in 2:
			targets.append({"gx": [randf_range(.08, .22), randf_range(.78, .92), randf_range(.4, .6)][randi() % 3], "gy": [randf_range(.15, .3), randf_range(.65, .85)][randi() % 2], "hit": false})

func _layout() -> void:
	var avail := size - Vector2(0, 360)
	sc = min(size.x / LW, avail.y / LH)
	off = Vector2((size.x - LW * sc) / 2, 170 + (avail.y - LH * sc) / 2)

func _to_l(p: Vector2) -> Vector2: return (p - off) / sc

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed and phase == "aim":
			pts = [[_to_l(e.position), Time.get_ticks_msec()]]; phase = "drag"
		elif not e.pressed and phase == "drag":
			pts.append([_to_l(e.position), Time.get_ticks_msec()]); _shoot()
	elif e is InputEventMouseMotion and phase == "drag":
		pts.append([_to_l(e.position), Time.get_ticks_msec()])
		if pts.size() > 80: pts.remove_at(1)

func _hh(f: float, gy: float, loft: float) -> float: return gy * f + loft * 4 * f * (1 - f)

func _shoot() -> void:
	var a: Vector2 = pts[0][0]; var b: Vector2 = pts[pts.size() - 1][0]
	var v := b - a; var ln := v.length(); var dur: float = max(40, pts[pts.size() - 1][1] - pts[0][1])
	if ln < 28 or v.y > -18:
		phase = "aim"; pts = []; msg = "Kaleye doğru yukarı kaydır"; msg_col = UI.YEL; msg_t = Time.get_ticks_msec(); return
	G.S.tut.shot = true
	var dev := 0.0
	for q in pts:
		var d: float = (v.x * (q[0].y - a.y) - v.y * (q[0].x - a.x)) / ln
		if abs(d) > abs(dev): dev = d
	var curve: float = clamp(-dev / ln, -.45, .45)
	var pace: float = clamp((ln / dur) / 1.15, .35, 1.35)
	var t := (by - GB) / (-v.y); var hit_x := bx + v.x * t
	var gx := (hit_x - GL) / GW
	var gy: float = max(0.0, (ln / 300.0 - .25) / .6)
	var attr: float = o.get("attr", 50); var ef: float = o.get("ef", 1.0)
	var sd: float = (.018 + (100 - attr) / 100.0 * .085) * (1 + max(0.0, pace - .85) * .7) / ef
	gx += randfn(0, 1) * sd; gy = max(0.0, gy + randfn(0, 1) * sd * 1.2)
	if kind == "pen": gx = .5 + (gx - .5) * .95
	var loft: float = max(0.0, gy - .15) * 1.3
	var tx := GL + gx * GW
	var C := Vector2((bx + tx) / 2 + curve * 170, (by + GB) / 2)
	var S0 := Vector2(bx, by); var T := Vector2(tx, GB)
	var block = null
	for ob in obst:
		for i in range(1, 60):
			var f := i / 60.0
			var q := _bez(S0, C, T, f)
			if q.y <= ob.y:
				if abs(q.x - ob.x) < ob.hw + 5 and _hh(f, gy, loft) < ob.h: block = {"f": f}
				break
		if block != null: break
	var res := ""
	var in_g := gx >= 0 and gx <= 1 and gy <= 1
	if block != null: res = "block"
	elif train:
		res = "goal" if in_g else ("post" if (gx > -.035 and gx < 1.035 and gy < 1.06) else "miss")
		if in_g:
			for tg in targets:
				if not tg.hit and Vector2((tg.gx - gx) * GW, (tg.gy - gy) * GH).length() < 19: tg.hit = true; hits += 1
	elif not in_g:
		res = "post" if (gx > -.035 and gx < 1.035 and gy < 1.06) else "miss"
	else:
		if kind == "pen":
			var reach: float = .15 + ks * .07 - (.05 if gy > .8 else 0.0) - (.03 if pace > 1 else 0.0)
			var save: bool = abs(gx - pid) < reach or (pace < .55 and abs(gx - .5) < .25) or (pid == .5 and abs(gx - .5) < .2 and gy < .6)
			res = "save" if save else "goal"; kxT = pid
		else:
			var reach: float = .17 + ks * .24 - pace * .07 - abs(curve) * .16 - (.03 if kind == "close" else 0.0) + (.06 if kind == "long" else 0.0) + (.03 if kind == "fk" else 0.0)
			var d: float = abs(gx - .5)
			if gy > .72 and d > .25: d += .07
			if gy < .15 and d > .3: d += .03
			var save: bool = d < reach * randf_range(.82, 1.15) or (pace < .5 and d < reach + .12)
			res = "save" if save else "goal"
			kxT = gx if save else .5 + sign(gx - .5) * min(abs(gx - .5), reach * .95)
		kAngT = (kxT - .5) * 2.2; kLiftT = clamp(gy - .3, 0, .7) * (1.0 if res == "save" else .6)
	if (res == "goal" or res == "post" or res == "miss") and not train and kind != "pen":
		kxT = .5 + (gx - .5) * .4; kAngT = (kxT - .5) * 1.8
	var flight: float = clamp(780 / (pace + .35), 420, 1300)
	anim = {"S": S0, "C": C, "T": T, "gy": gy, "loft": loft, "f": 0.0, "dur": flight, "res": res, "block": block, "gx": gx, "t0": Time.get_ticks_msec(), "done": false, "bm": false}
	phase = "fly"; Sfx.play("kick"); Input.vibrate_handheld(20)

func _bez(a: Vector2, c: Vector2, b: Vector2, f: float) -> Vector2:
	return (1 - f) * (1 - f) * a + 2 * (1 - f) * f * c + f * f * b

func _process(_dt: float) -> void:
	if finished: return
	var now := Time.get_ticks_msec()
	if anim != null:
		anim.f = (now - anim.t0) / anim.dur
		if anim.block != null and anim.f >= anim.block.f and not anim.bm:
			anim.bm = true; msg = "Bloklandı"; msg_col = UI.RED; msg_t = now; Sfx.play("save")
		if anim.f >= 1 and not anim.done:
			anim.done = true; var r: String = anim.res
			if anim.block == null:
				match r:
					"goal":
						msg = "İsabet" if train else "GOL"; msg_col = UI.YEL; net_shake = 4; flash = .35; Sfx.play("tap" if train else "goal"); Input.vibrate_handheld(80)
					"save": msg = "Kurtarış"; msg_col = UI.RED; Sfx.play("save")
					"post": msg = "Direk"; msg_col = UI.YEL; Sfx.play("bad")
					_: msg = "Dışarı"; msg_col = UI.RED; Sfx.play("bad")
				msg_t = now
		if anim.f >= 2.1:
			var r: String = anim.res
			anim = null; shots += 1
			if train and shots < max_shots:
				phase = "aim"; _place(); _setup_obst(); kx = .5; kxT = .5; kAngT = 0; kLiftT = 0; sub_l.text = "%d isabet" % hits
			else:
				phase = "res"; finished = true
				await get_tree().create_timer((.5 if train else .25) * G.speed).timeout
				done.emit(min(5, hits) if train else r)
				queue_free()
				return
	kx += (kxT - kx) * .12; kAng += (kAngT - kAng) * .12; kLift += (kLiftT - kLift) * .12
	net_shake *= .94; flash *= .85
	queue_redraw()

func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var p := PackedVector2Array()
	for i in 24: p.append(c + Vector2(cos(i * TAU / 24) * rx, sin(i * TAU / 24) * ry))
	draw_colored_polygon(p, col)

func _base() -> Transform2D: return Transform2D(0, Vector2(sc, sc), 0, off)

func _fig(x: float, y: float, col: Color, s: float, ang: float, arms: bool, keeper: bool) -> void:
	draw_set_transform_matrix(_base() * Transform2D(ang, Vector2(s, s), 0, Vector2(x, y)))
	_ellipse(Vector2.ZERO, 13, 4, Color(0, 0, 0, .25))
	draw_rect(Rect2(-7, -20, 5, 20), Color("1f2937")); draw_rect(Rect2(2, -20, 5, 20), Color("1f2937"))
	draw_rect(Rect2(-10, -42, 20, 24), col)
	if arms:
		draw_line(Vector2(-9, -38), Vector2(-22, -56), col, 5); draw_line(Vector2(9, -38), Vector2(22, -56), col, 5)
		if keeper: draw_circle(Vector2(-22, -57), 3.5, Color.WHITE); draw_circle(Vector2(22, -57), 3.5, Color.WHITE)
	else:
		draw_line(Vector2(-9, -38), Vector2(-13, -22), col, 5); draw_line(Vector2(9, -38), Vector2(13, -22), col, 5)
	draw_circle(Vector2(0, -49), 7, Color("f1c27d"))
	draw_set_transform_matrix(_base())

func _draw() -> void:
	_layout()
	draw_rect(Rect2(Vector2.ZERO, size), UI.DEEP)
	draw_set_transform_matrix(_base())
	var now := Time.get_ticks_msec()
	# tribün ve reklam panosu
	draw_rect(Rect2(0, 0, LW, 72), Color("0d1a14"))
	for i in 140:
		draw_rect(Rect2(fmod(i * 37.0, LW), 8 + fmod(i * 13.0, 50), 3, 3), Color([Color("64748b"), Color("94a3b8"), Color("ef4444"), Color("facc15"), Color("e2e8f0")][i % 5], .35))
	draw_rect(Rect2(0, 62, LW, 12), Color("07100b"))
	var adw := fd.get_string_size("EFSANE YOLU", HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 14
	var ax := 8.0
	while ax + adw - 14 < LW:
		draw_string(fd, Vector2(ax, 71), "EFSANE YOLU", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, UI.YEL); ax += adw
	# çim
	for i in 12: draw_rect(Rect2(0, 74 + i * 42, LW, min(42.0, LH - (74 + i * 42))), Color("1c7a35") if i % 2 else Color("1f8a3c"))
	var W := Color(1, 1, 1, .75)
	draw_line(Vector2(0, GB), Vector2(LW, GB), W, 2)
	draw_polyline(PackedVector2Array([Vector2(115, GB), Vector2(105, 190), Vector2(255, 190), Vector2(245, GB)]), W, 2)
	draw_polyline(PackedVector2Array([Vector2(42, GB), Vector2(10, 275), Vector2(350, 275), Vector2(318, GB)]), W, 2)
	var arc := PackedVector2Array()
	for i in 21: arc.append(Vector2(180 + cos(PI * i / 20.0) * 52, 280 + sin(PI * i / 20.0) * 20))
	draw_polyline(arc, W, 2)
	_ellipse(Vector2(180, 232), 3, 1.6, Color.WHITE)
	# kale
	var sh := sin(now / 25.0) * net_shake
	draw_rect(Rect2(GL, GT, GW, GH), Color(1, 1, 1, .08))
	var NC := Color(1, 1, 1, .28)
	var x := GL
	while x <= GR: draw_line(Vector2(x + sh, GT), Vector2(x + sh * .5, GB), NC, 1); x += 10
	var y := GT
	while y <= GB: draw_line(Vector2(GL, y + sh * .4), Vector2(GR, y + sh * .4), NC, 1); y += 10
	draw_polyline(PackedVector2Array([Vector2(GL, GB), Vector2(GL, GT), Vector2(GR, GT), Vector2(GR, GB)]), Color.WHITE, 5)
	for tg in targets:
		var c := Vector2(GL + tg.gx * GW, GB - tg.gy * GH)
		var cc := Color("22c55e") if tg.hit else UI.YEL
		draw_arc(c, 17, 0, TAU, 32, cc, 3); draw_arc(c, 7, 0, TAU, 24, cc, 3)
		if tg.hit: draw_circle(c, 15, Color(.13, .77, .37, .35))
	if not train: _fig(GL + kx * GW, GB - kLift * 40, Color("eab308"), 1, kAng, phase == "fly" or phase == "res", true)
	for ob in obst: _fig(ob.x, ob.y, UI.RED, .85 + (ob.y - GB) / 600.0, 0, ob.wall and phase != "aim" and phase != "drag", false)
	# top
	var bxx := bx; var byy := by; var br := 9.0; var hh := 0.0; var in_net := false
	if anim != null:
		var f: float = min(anim.f, 1.0)
		var q := _bez(anim.S, anim.C, anim.T, f); hh = _hh(f, anim.gy, anim.loft); bxx = q.x; byy = q.y; br = 9 - 4.2 * f * (by - GB) / 330.0
		if anim.f > 1:
			var ex: float = anim.f - 1
			match anim.res:
				"goal": byy = GB - anim.gy * GH - ex * 12; br *= 1 - ex * .3; hh = 0; in_net = true
				"miss": bxx += (-1 if anim.gx < 0 else (1 if anim.gx > 1 else 0)) * ex * 80; byy -= ex * 60; hh = anim.gy
				_: bxx += (-1 if anim.gx < .5 else 1) * ex * 90; byy += ex * 70; hh = max(0.0, anim.gy - ex)
		if anim.block != null and anim.f >= anim.block.f:
			var ex2: float = anim.f - anim.block.f; var q2 := _bez(anim.S, anim.C, anim.T, anim.block.f)
			bxx = q2.x + ex2 * 120 * (-1 if q2.x < 180 else 1); byy = q2.y + ex2 * 160; hh = max(0.0, _hh(anim.block.f, anim.gy, anim.loft) - ex2); br = 8; in_net = false
	var lift: float = 0.0 if (anim == null or in_net) else hh * GH * (.55 + .45 * min(anim.f, 1.0))
	var ry: float = byy if in_net else byy - lift
	_ellipse(Vector2(bxx, byy + 2), br * 1.1, br * .4, Color(0, 0, 0, .35))
	draw_circle(Vector2(bxx, ry), br, Color.WHITE)
	draw_arc(Vector2(bxx, ry), br, 0, TAU, 24, Color("111111"), 1.2)
	draw_circle(Vector2(bxx - br * .25, ry - br * .2), br * .32, Color("111111"))
	if phase == "drag" and pts.size() > 1:
		var pl := PackedVector2Array()
		for q in pts: pl.append(q[0])
		draw_polyline(pl, Color(UI.YEL, .85), 5, true)
	if phase == "aim" and not G.S.tut.shot:
		var k := fmod(now / 900.0, 1.0)
		draw_circle(Vector2(bx, by - 20 - k * 120), 10, Color(UI.YEL, 1 - k))
	if train:
		draw_rect(Rect2(10, LH - 36, 130, 26), Color(0, 0, 0, .5))
		draw_string(fd, Vector2(18, LH - 17), "Şut %d/%d, isabet %d" % [min(shots + 1, max_shots), max_shots, hits], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	if msg != "" and now - msg_t < 1600:
		draw_string_outline(fd, Vector2(0, 340), msg, HORIZONTAL_ALIGNMENT_CENTER, LW, 46, 8, Color(0, 0, 0, .6))
		draw_string(fd, Vector2(0, 340), msg, HORIZONTAL_ALIGNMENT_CENTER, LW, 46, msg_col)
	draw_rect(Rect2(0, 0, LW, LH), UI.CHALK, false, 3)
	if flash > .01: draw_rect(Rect2(0, 0, LW, LH), Color(1, 1, 1, flash))
	draw_set_transform_matrix(Transform2D.IDENTITY)
