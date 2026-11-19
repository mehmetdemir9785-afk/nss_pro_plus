extends Control
## Maç ekranı ve motoru: dakika dakika akış, kritik anlarda kontrol oyuncuda.

var m := {}
var sd := {}
var sel := "xi"
var on := false
var in_min := 0
var out_min := 90
var tl := []
var score := {"me": 0, "op": 0}
var minute := 0
var rat := 6.0
var g := 0
var a := 0
var fast := false
var auto := false
var mates := []
var ops_n := []
var pens = null
var energy0 := 100.0
var fk_goal := false
var pk := false
var home := true

var sc_l: Label
var min_l: Label
var st_l: Label
var tl_bar: UI.Bar
var mom: VBoxContainer
var feed_box: VBoxContainer
var ctl: HBoxContainer
var b_fast: Button
var b_auto: Button
var Timing = preload("res://scripts/timing.gd")
var Shot = preload("res://scripts/shot.gd")
var Pitch = preload("res://scripts/pitch.gd")

func _live(inv: String, att: int) -> void:
	var p = G.S.p
	var P = Pitch.new()
	var parts: PackedStringArray = str(p.name).strip_edges().split(" ", false)
	var short := (parts[parts.size() - 1] if parts.size() > 0 else "SEN").replace("i", "İ").to_upper()
	var H = sd.me if home else sd.op; var A = sd.op if home else sd.me
	var hs: int = score.me if home else score.op; var as_: int = score.op if home else score.me
	P.setup({"me": {"name": sd.me.name, "col": sd.me.col, "str": sd.me.str}, "op": {"name": sd.op.name, "col": sd.op.col, "str": sd.op.str}, "attack": att, "involve": inv,
		"upos": p.pos, "unum": int(p.num), "uname": p.name, "uname_short": short, "auto": auto, "on": on,
		"ustats": {"sut": G.eff("sut"), "pas": G.eff("pas"), "drip": G.eff("drip"), "hiz": G.eff("hiz"), "sav": G.eff("sav")},
		"title": "%d'   %s %d - %d %s" % [minute, H.name, hs, as_, A.name]})
	var r
	if fast and (inv == "none" or auto):
		r = P.simulate(); P.free()
	else:
		add_child(P); P.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		r = await P.finished
	if r.goal == "me":
		if on and r.u_goal: g += 1
		if on and r.u_assist: a += 1
		var txt: String = r.txt
		if r.u_goal: txt = "%s golü attı." % p.name
		_goal("me", "GOL. " + txt)
	elif r.goal == "op":
		_goal("op", "Gol: %s. %s" % [sd.op.name, r.txt])
	else:
		feed(r.txt)
	if inv != "none":
		_addr(r.rd)
		if r.u_shot == "save": feed("Şutun kaleciden döndü.")
		elif r.u_shot == "miss": feed("Şutun auta gitti.")
	elif on and (r.u_goal or r.u_assist): _addr(r.rd)
	await _wait(.05 if fast else .35)

const FILL := ["{op} tehlikeli bir korner kullandı, savunma uzaklaştırdı.", "Orta sahada sert mücadele, hakem faul çaldı.", "{me} topa sahip, oyunu sabırla kuruyor.", "{op} kalecisi uzun bir degajla oyunu başlattı.", "Tribünler coştu, müthiş bir atmosfer var.", "{op} oyuncusu sarı kart gördü.", "{me} soldan etkili bir atak geliştirdi, top auta çıktı.", "{op} uzaktan şut denedi, top üstten auta gitti.", "Oyun bir süre durdu, sakatlanan oyuncuya müdahale ediliyor.", "{me} kalecisi kritik bir kurtarış yaptı.", "{op} ofsayta yakalandı.", "Hakem avantaja bıraktı, oyun devam ediyor."]

func _wait(sec: float) -> void:
	await get_tree().create_timer(max(.001, sec * G.speed)).timeout

func begin(mm: Dictionary) -> void:
	m = mm; sd = G.match_sides(m); sel = G.selection(m); home = sd.home
	var p = G.S.p
	var me_s: float = sd.me.str; var op_s: float = sd.op.str
	var will_play := sel == "xi" or sel == "sub"
	in_min = 0 if sel == "xi" else (G.RI(55, 72) if sel == "sub" else 99)
	var lP := 3.4 * pow(me_s / op_s, .9) * (1.08 if home else .93) * (.72 if will_play else 1.0)
	var lO := 3.4 * pow(op_s / me_s, .9) * (.93 if home else 1.08) * (.8 if will_play and p.pos == "DF" else 1.0)
	var eu_me: bool = me_s >= 73 and m.type != "nat" and m.type != "tour"
	for i in 6: mates.append(G.gen_name(eu_me))
	if sd.me.has("star"): mates[0] = sd.me.star.name
	for i in 4: ops_n.append(G.gen_name(op_s >= 73))
	if sd.op.has("star"): ops_n[0] = sd.op.star.name
	for i in G.poisson(clamp(lP, .5, 7)): tl.append({"min": G.RI(2, 90), "k": "ch", "s": "me"})
	for i in G.poisson(clamp(lO, .5, 7)): tl.append({"min": G.RI(2, 90), "k": "ch", "s": "op"})
	if sel == "xi" and p.energy < 45: out_min = G.RI(62, 78)
	if will_play:
		var n := (G.RI(2, 4) - (1 if out_min < 90 else 0)) if sel == "xi" else G.RI(1, 2)
		var used := {}
		for i in n:
			var mn := 0; var tries := 0
			while true:
				mn = G.RI(max(3, in_min + 2), min(89, out_min - 1)); tries += 1
				if not (used.has(mn) or used.has(mn - 1) or used.has(mn + 1)) or tries > 30: break
			used[mn] = true
			tl.append({"min": mn, "k": "mom", "t": G.wpick(G.POS[p.pos].mom)})
		if sel == "sub": tl.append({"min": in_min, "k": "in"})
		if out_min < 90: tl.append({"min": out_min, "k": "out"})
	for i in G.RI(5, 8): tl.append({"min": G.RI(2, 89), "k": "fill"})
	tl.sort_custom(func(x, y): return x.min < y.min if x.min != y.min else (x.k == "in"))
	on = sel == "xi"; energy0 = p.energy
	_build()
	_run()

func _build() -> void:
	var bgc := UI.Bg.new(); add_child(bgc); bgc.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var sc := ScrollContainer.new(); add_child(sc); sc.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; sc.scroll_deadzone = 18
	var v := UI.vbox(22); v.size_flags_horizontal = SIZE_EXPAND_FILL
	sc.add_child(UI.margin(v, 32, 30, 32, 60))
	sc.get_child(0).size_flags_horizontal = SIZE_EXPAND_FILL
	# skorbord
	var board := UI.panel(Color("07100B"), 12, 6, Color("23332B"), Vector4(20, 22, 20, 22))
	var bv := UI.vbox(10)
	bv.add_child(UI.lbl(m.label, 26, UI.CHALK2, false, 500, HORIZONTAL_ALIGNMENT_CENTER))
	var row := UI.hbox(6)
	var H = sd.me if home else sd.op; var A = sd.op if home else sd.me
	row.add_child(_team_col(H))
	sc_l = UI.lbl("0 - 0", 136, UI.YEL, true, 900, HORIZONTAL_ALIGNMENT_CENTER, false); sc_l.custom_minimum_size = Vector2(250, 0); sc_l.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(sc_l)
	row.add_child(_team_col(A))
	bv.add_child(row)
	min_l = UI.lbl("0'", 48, UI.CHALK, true, 800, HORIZONTAL_ALIGNMENT_CENTER); bv.add_child(min_l)
	tl_bar = UI.Bar.new(0, UI.YEL, 8); tl_bar.track = Color("1B2721"); bv.add_child(tl_bar)
	st_l = UI.lbl("", 26, UI.CHALK2, false, 500, HORIZONTAL_ALIGNMENT_CENTER); bv.add_child(st_l)
	board.add_child(bv); v.add_child(board)
	mom = UI.vbox(0); v.add_child(mom)
	ctl = UI.hbox(16)
	b_fast = UI.btn("Hızlı", "out", func(): fast = not fast; _tog(b_fast, fast), "", 34); b_fast.size_flags_horizontal = SIZE_EXPAND_FILL
	b_auto = UI.btn("Anları otomatik oyna", "out", func(): auto = not auto; _tog(b_auto, auto), "", 34); b_auto.size_flags_horizontal = SIZE_EXPAND_FILL
	ctl.add_child(b_fast); ctl.add_child(b_auto); v.add_child(ctl)
	feed_box = UI.vbox(0); v.add_child(feed_box)
	_upd()

func _tog(b: Button, st: bool) -> void:
	var s: StyleBoxFlat = b.get_theme_stylebox("normal").duplicate(); s.bg_color = UI.CHALK if st else Color.TRANSPARENT
	for n in ["normal", "hover", "pressed", "focus"]: b.add_theme_stylebox_override(n, s)
	var l: Label = b.get_child(0).get_child(0); l.add_theme_color_override("font_color", UI.INK if st else UI.CHALK)

func _team_col(t) -> VBoxContainer:
	var c := UI.vbox(8); c.size_flags_horizontal = SIZE_EXPAND_FILL
	c.add_child(UI.Crest.new(t.name, Color(t.col), .8))
	c.add_child(UI.lbl(t.name, 36, UI.CHALK, true, 800, HORIZONTAL_ALIGNMENT_CENTER))
	return c

func _upd() -> void:
	var h: int = score.me if home else score.op; var aw: int = score.op if home else score.me
	sc_l.text = "%d - %d" % [h, aw]
	min_l.text = "Penaltılar" if pens != null else "%d'" % minute
	tl_bar.value = minute / 90.0 * 100; tl_bar.queue_redraw()
	if on: st_l.text = "Sahadasın. Reyting %s, %d gol, %d asist" % [G.r1(rat), g, a]
	elif sel == "sub" and minute < in_min: st_l.text = "Yedek kulübesindesin"
	elif sel == "inj": st_l.text = "Sakatsın, tribündesin"
	elif sel == "out": st_l.text = "Kadroda değilsin"
	else: st_l.text = "Oyundan çıktın. Reyting " + G.r1(rat)

func feed(t: String, cls := "") -> void:
	var row := UI.panel(Color.TRANSPARENT, 0, 0, Color.TRANSPARENT, Vector4(4 if cls == "" else 22, 16, 4, 16))
	var st: StyleBoxFlat = row.get_theme_stylebox("panel")
	st.border_width_bottom = 2; st.border_color = UI.LINE
	if cls == "goal" or cls == "og":
		st.border_width_left = 10
		var bc := UI.YEL if cls == "goal" else UI.RED
		st.border_color = bc
	var h := UI.hbox(16)
	var ml := UI.lbl("%d'" % minute, 34, UI.YEL, true, 800, HORIZONTAL_ALIGNMENT_LEFT, false); ml.custom_minimum_size = Vector2(66, 0); h.add_child(ml)
	var tx := UI.lbl(t, 29, Color("F4DE93") if cls == "me" else UI.CHALK, false, 700 if cls == "goal" else 500); tx.size_flags_horizontal = SIZE_EXPAND_FILL; h.add_child(tx)
	row.add_child(h)
	feed_box.add_child(row); feed_box.move_child(row, 0)
	if feed_box.get_child_count() > 40: feed_box.get_child(feed_box.get_child_count() - 1).queue_free()

func _run() -> void:
	Sfx.play("whistle"); feed("Hakem düdüğü çaldı, maç başladı.")
	for mn in range(1, 91):
		minute = mn; _upd()
		for ev in tl:
			if ev.min == mn: await _handle(ev)
		if mn == 45:
			feed("İlk yarı sona erdi."); await _wait(.06 if fast else .6)
		await _wait(.018 if fast else .115)
	Sfx.play("whistle"); feed("Maç sona erdi.")
	if m.ko and score.me == score.op: await _shootout()
	_finish()

func _goal(side: String, txt: String) -> void:
	score[side] += 1; _upd()
	if side == "me":
		feed(txt, "goal")
		if on: rat += .12
		if not fast: Sfx.play("goal")
	else:
		feed(txt, "og")
		if on: rat -= .3 if G.S.p.pos == "DF" else .08

func _handle(ev: Dictionary) -> void:
	match ev.k:
		"fill": feed(G.pick(FILL).replace("{me}", sd.me.name).replace("{op}", sd.op.name))
		"in": on = true; feed("Oyuna giriyorsun. %d numara sahada." % G.S.p.num, "me"); _upd()
		"out":
			if on: on = false; feed("Yorulduğun için oyundan alındın.", "me"); _upd()
		"aig":
			if ev.s == "me": _goal("me", "GOL. %s topu ağlara gönderdi (%s)." % [G.pick(mates), sd.me.name])
			else: _goal("op", "Gol: %s (%s)." % [G.pick(ops_n), sd.op.name])
			await _wait(.08 if fast else .7)
		"mom":
			if on: await _moment(ev.t)
		"ch":
			feed(("%s atağa çıkıyor." % sd.me.name) if ev.s == "me" else ("%s tehlikeli geliyor." % sd.op.name))
			await _live("none", 0 if ev.s == "me" else 1)

func _op() -> float: return sd.op.str
func _efac() -> float:
	var en: float = max(10.0, energy0 - (minute - in_min) * .25)
	return clamp(.62 + .38 * en / 100.0, .6, 1.0) * (.93 + G.S.p.moral / 700.0) * G.perks().psy
func _zone(at: String, mod := 1.0) -> float: return clamp((.13 + (G.eff(at) - _op()) / 260.0) * mod * _efac(), .06, .42)
func _spd() -> float: return .95 + _op() / 105.0
func _ks() -> float: return clamp(.3 + (_op() - 40) / 50.0 * .5, .28, .86)
func _auto_g(at: String, mod := 1.0) -> String:
	var z := _zone(at, mod); var r := randf()
	return "perfect" if r < z else ("good" if r < z * 3.4 else "fail")
func _auto_shot(at: String, k: String) -> String:
	var bonus: float = {"close": .18, "box": .04, "long": -.08, "fk": -.1, "pen": .52}.get(k, 0.0)
	var pr: float = clamp(.1 + (G.eff(at) - _op()) / 160.0 + bonus, .04, .85)
	return "goal" if randf() < pr else ["save", "save", "miss", "block"][randi() % 4]
func _addr(d: float) -> void: rat = clamp(rat + d, 3, 10); _upd()

func _paper() -> PanelContainer:
	for c in mom.get_children(): c.queue_free()
	var p := UI.panel(UI.PAPER, 12, 0, Color.TRANSPARENT, Vector4(32, 30, 32, 30))
	var st: StyleBoxFlat = p.get_theme_stylebox("panel"); st.border_width_top = 16; st.border_color = Color(G.my_team().col) if UI.lum(Color(G.my_team().col)) < .8 else UI.YEL
	mom.add_child(p)
	return p

func _tbar(title: String, desc: String, width: float, speed: float, btn_t: String) -> String:
	var p := _paper()
	var tb = Timing.new(); tb.setup(title, desc, width, speed, btn_t); p.add_child(tb)
	Sfx.play("tap")
	var gr: String = await tb.graded
	p.queue_free()
	return gr

func _shot_ui(k: String) -> String:
	var titles := {"close": "Kaleciyle karşı karşıya", "box": "Ceza sahasında şut fırsatı", "long": "Uzaktan dene", "fk": "Serbest vuruş", "pen": "Penaltı"}
	var s = Shot.new()
	s.setup({"kind": k, "attr": G.eff("duran" if k == "fk" or k == "pen" else "sut"), "ef": _efac(), "ks": _ks(), "pen": k == "pen", "title": titles[k], "sub": "%d'  %s %d - %d %s" % [minute, sd.me.name, score.me, score.op, sd.op.name]})
	add_child(s); s.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var r = await s.done
	return str(r)

func _do_shot(k: String, at: String, intro: String) -> void:
	feed(intro, "me")
	var r := ""
	if auto:
		await _wait(.05 if fast else .5); r = _auto_shot(at, k)
	else:
		r = await _shot_ui(k)
	if r == "goal":
		g += 1; _addr(1.45 if k == "long" or k == "fk" else 1.2)
		var how: String = {"close": "soğukkanlı bir bitiriş yaptı", "box": "ceza sahasından muhteşem vurdu", "long": "uzaklardan füze gibi bir gol attı", "fk": "serbest vuruştan harika bir gol attı", "pen": "penaltıyı gole çevirdi"}[k]
		_goal("me", "GOL. %s %s." % [G.S.p.name, how])
		if not auto: _flash("FRİKİK" if k == "fk" else "GOL")
		if k == "fk": fk_goal = true
		await _wait(.12 if fast else .9)
	else:
		_addr(-.05 if r == "save" else (0.0 if r == "post" else -.15))
		feed({"save": "Kaleci şutunu kurtardı.", "miss": "Şutun auta gitti.", "post": "Top direkten döndü, çok yakındı.", "block": "Şutun savunmaya çarptı."}.get(r, "Pozisyon kaçtı."))
		await _wait(.06 if fast else .4)

func _flash(t: String) -> void:
	var l := UI.lbl(t, 260, UI.YEL, true, 900, HORIZONTAL_ALIGNMENT_CENTER, false)
	l.add_theme_constant_override("outline_size", 18); l.add_theme_color_override("font_outline_color", UI.INK)
	add_child(l); l.set_anchors_and_offsets_preset(PRESET_CENTER); l.grow_horizontal = GROW_DIRECTION_BOTH; l.grow_vertical = GROW_DIRECTION_BOTH
	l.pivot_offset = l.size / 2; l.scale = Vector2(.6, .6); l.modulate.a = 0
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, .15); tw.parallel().tween_property(l, "scale", Vector2.ONE, .18)
	tw.tween_interval(.8); tw.tween_property(l, "modulate:a", 0.0, .3); tw.tween_callback(l.queue_free)

func _moment(t: String) -> void:
	var p = G.S.p
	match t:
		"shot", "dribble", "pass":
			feed("Top sana doğru geliyor, hazır ol." , "me")
			await _live("attack", 0)
		"tackle":
			feed("Rakip hücuma çıktı, savunmayı sen yöneteceksin.", "me")
			await _live("defend", 1)
		"_shot_old":
			var opts := [["close", 4], ["box", 5], ["long", 1]] if p.pos == "FV" else ([["box", 3], ["long", 6], ["close", 1]] if p.pos == "OS" else [["box", 5], ["close", 3], ["long", 2]])
			var k: String = G.wpick(opts)
			await _do_shot(k, "sut", {"close": "Savunmanın arkasına sarktın, kaleciyle karşı karşıyasın.", "box": "Ceza sahasında topla buluştun.", "long": "Ceza sahası dışında boş alan buldun."}[k])
		"penalty":
			feed("Ceza sahasında faul. Penaltı! Topun başına sen geçtin.", "me")
			await _do_shot("pen", "duran", "Penaltı noktasındasın.")
		"freekick":
			await _do_shot("fk", "duran", "Ceza sahası yayına yakın tehlikeli bir serbest vuruş.")
		"header":
			feed("Ortaya gelen topa yükseliyorsun.", "me")
			var gr: String = _auto_g("kafa") if auto else await _tbar("Kafa vuruşu", "Zamanlamayı tuttur, topa en yüksek noktada vur.", _zone("kafa"), _spd(), "Kafa")
			var pg := .75 if gr == "perfect" else (.3 if gr == "good" else 0.0)
			if randf() < pg:
				g += 1; _addr(1.2); _goal("me", "GOL. %s müthiş bir kafa vuruşuyla golü attı." % p.name)
				if not auto: _flash("GOL")
			else:
				_addr(-.15 if gr == "fail" else 0.0); feed("Topa iyi temas edemedin." if gr == "fail" else "Kafa vuruşun kaleciden döndü.")
			await _wait(.06 if fast else .6)
		"_dribble_old":
			feed("Rakip savunmacıyla bire birsin.", "me")
			var gr: String = _auto_g("drip") if auto else await _tbar("Çalım at", "Doğru anda hareket et ve rakibini geç.", _zone("drip"), _spd(), "Çalım")
			if gr == "fail":
				_addr(-.15); feed("Top ayağından kaçtı, rakip araya girdi."); return
			_addr(.35 if gr == "perfect" else .2); feed("Rakibini yerde bıraktın." if gr == "perfect" else "Rakibini geçtin.", "me")
			if gr == "perfect" or randf() < .65: await _do_shot("close" if gr == "perfect" else "box", "sut", "Şimdi şut zamanı.")
			else: feed("Ortaya çevirdin ama savunma uzaklaştırdı.")
		"_pass_old":
			feed("Topla buluştun, takım arkadaşların koşu yapıyor.", "me")
			var opt := ""
			if auto: opt = ["kisa", "ara", "orta"][randi() % 3]
			else: opt = await _pass_choice()
			var mod: float = {"kisa": 1.6, "ara": .72, "orta": 1.0}[opt]
			var gr: String = _auto_g("pas", mod) if auto else await _tbar({"kisa": "Kısa pas", "ara": "Ara pası", "orta": "Orta"}[opt], "Topu doğru anda bırak.", _zone("pas", mod), _spd(), "Pas")
			var ap: Array = {"kisa": [.12, .06], "ara": [.62, .36], "orta": [.45, .22]}[opt]
			if gr == "fail":
				_addr(-.25 if opt == "kisa" else -.15); feed("Pasın rakibe takıldı."); return
			var mate: String = G.pick(mates)
			if randf() < (ap[0] if gr == "perfect" else ap[1]):
				a += 1; _addr(.95); _goal("me", "GOL. %s golü attı, asist %s." % [mate, p.name])
			else:
				_addr(.1 if opt == "kisa" else .2); feed("Başarılı pas, top takımında." if opt == "kisa" else "%s topla buluştu ama şutu karşılandı." % mate)
			await _wait(.06 if fast else .5)
		"_tackle_old":
			var at: String = G.pick(ops_n)
			feed("%s hızla kaleye ilerliyor, müdahale et." % at, "me")
			var gr: String = _auto_g("sav") if auto else await _tbar("Müdahale", "Doğru anda kay, topu temiz al.", _zone("sav"), _spd() * 1.05, "Kay")
			if gr == "perfect":
				_addr(.45); feed("Kusursuz bir kayarak müdahale. Kontra atak başladı.", "me")
				if randf() < .18:
					var mate: String = G.pick(mates); a += 1; _addr(.8); _goal("me", "GOL. Kontrada %s golü attı, asist %s." % [mate, p.name])
			elif gr == "good":
				_addr(.25); feed("Topu uzaklaştırdın, tehlike geçti.")
			else:
				_addr(-.3)
				if randf() < .2: feed("Geç kaldın ve sarı kart gördün.", "og"); _addr(-.2)
				elif randf() < .5: _goal("op", "%s seni geçip golü attı." % at)
				else: feed("Rakibin şutu az farkla auta gitti. Şanslıydın.")
			await _wait(.06 if fast else .5)

func _pass_choice() -> String:
	var p := _paper()
	var v := UI.vbox(16); p.add_child(v)
	v.add_child(UI.lbl("Pas seçimi", 64, UI.INK, true, 900))
	v.add_child(UI.lbl("Risk ne kadar büyükse ödül de o kadar büyük.", 29, UI.INK2))
	var picked := [""]
	var done_sig := [false]
	for o in [["kisa", "Güvenli kısa pas", "Kolay, küçük katkı"], ["ara", "Ara pası", "Zor ama gol şansı yüksek"], ["orta", "Ceza sahasına orta", "Orta zorlukta"]]:
		var id: String = o[0]
		v.add_child(UI.btn(o[1], "out", func(): picked[0] = id; done_sig[0] = true, o[2], 40, true))
	while not done_sig[0]:
		await get_tree().process_frame
	p.queue_free()
	return picked[0]

func _shootout() -> void:
	pens = [0, 0]; _upd(); feed("Eşitlik bozulmadı, seri penaltı atışları.", "me")
	var me_s: float = sd.me.str; var op_s: float = sd.op.str
	var tk := [0, 0]
	var dec := func() -> bool: return pens[0] + (5 - tk[0]) < pens[1] or pens[1] + (5 - tk[1]) < pens[0]
	for i in 5:
		if dec.call(): break
		for side in [0, 1]:
			if dec.call(): break
			var mine: bool = side == 0 and i == 0
			var ok := false
			if mine and on and not auto:
				pk = true; ok = (await _shot_ui("pen")) == "goal"
			else:
				if mine and on: pk = true
				var pr := .75 + ((me_s - op_s) if side == 0 else (op_s - me_s)) / 300.0 + ((G.eff("duran") - 60) / 300.0 if mine else 0.0)
				ok = randf() < pr
			tk[side] += 1
			if ok: pens[side] += 1
			_upd()
			feed("%s%s: %s, %d-%d" % [sd.me.name if side == 0 else sd.op.name, " (sen)" if mine and on else "", "gol" if ok else "kaçtı", pens[0], pens[1]], "goal" if ok and side == 0 else "")
			await _wait(.04 if fast else .45)
	var n := 0
	while pens[0] == pens[1] and n < 12:
		n += 1
		if randf() < .75 + (me_s - op_s) / 300.0: pens[0] += 1
		if randf() < .75 + (op_s - me_s) / 300.0: pens[1] += 1
		feed("Ani ölüm: %d-%d" % [pens[0], pens[1]]); await _wait(.04 if fast else .4)
	if pens[0] == pens[1]: pens[0] += 1
	var won: bool = pens[0] > pens[1]
	feed("Penaltılarda kazandınız." if won else "Penaltılarda elendiniz.", "goal" if won else "og")
	await _wait(.9)

func _finish() -> void:
	var played := sel == "xi" or sel == "sub"
	var minutes := 0
	if sel == "xi": minutes = out_min if out_min < 90 else 90
	elif sel == "sub": minutes = 90 - in_min
	var r := G.apply_match(m, {"played": played, "sel": sel, "me": score.me, "op": score.op, "rat": rat, "g": g, "a": a, "pens": pens, "fk": fk_goal, "pk": pk, "minutes": minutes})
	ctl.visible = false
	var p := _paper()
	var v := UI.vbox(14); p.add_child(v)
	v.add_child(UI.lbl("Galibiyet" if r.won else ("Beraberlik" if r.res == "D" else "Mağlubiyet"), 72, UI.INK, true, 900))
	v.add_child(UI.lbl(r.desc, 30, UI.INK2))
	if r.extra != "": v.add_child(UI.lbl(r.extra, 44, UI.INK, true, 900))
	if played:
		var h := UI.hbox(12)
		var rc := UI.GOLDINK if r.rating >= 8 else (UI.INK if r.rating >= 5.5 else Color("C21F35"))
		for it in [[G.r1(r.rating), "Reyting", rc], [str(g), "Gol", UI.INK], [str(a), "Asist", UI.INK], ["+%d" % r.gp, "GP", UI.INK]]:
			var c := UI.panel(Color.TRANSPARENT, 0, 0, Color.TRANSPARENT, Vector4(16, 0, 0, 0))
			var cs: StyleBoxFlat = c.get_theme_stylebox("panel"); cs.border_width_left = 5; cs.border_color = Color(UI.INK, .25)
			c.size_flags_horizontal = SIZE_EXPAND_FILL
			var cv := UI.vbox(0); cv.add_child(UI.lbl(it[0], 64, it[2], true, 900, HORIZONTAL_ALIGNMENT_LEFT, false)); cv.add_child(UI.lbl(it[1], 23, UI.INK2))
			c.add_child(cv); h.add_child(c)
		v.add_child(h)
		if r.motm: v.add_child(UI.chip("Maçın adamı", "y", true))
		if r.bonus > 0: v.add_child(UI.lbl("Galibiyet primi: +" + G.fmt(r.bonus), 27, UI.INK2))
	else:
		v.add_child(UI.lbl("Sakatlığın nedeniyle oynayamadın." if sel == "inj" else ("Hoca seni kadroya almadı. Hocayla ilişkini ve formunu geliştir." if sel == "out" else "Bu maçta süre alamadın."), 29, UI.INK2))
	if r.won: Sfx.play("ach")
	v.add_child(UI.btn("Devam", "pri", func(): queue_free(); G.main.match_closed(), "", 52, true))
