extends Control
## Arayüz kökü: üst bilgi, sekmeler, alt menü, kâğıt pencereler, bildirimler.

var bg: UI.Bg
var frame: VBoxContainer
var header: PanelContainer
var scroll: ScrollContainer
var content: VBoxContainer
var nav: PanelContainer
var overlay: Control
var sheet_layer: Control
var toast_box: VBoxContainer
var top_layer: Control
var sheet_lock := false
var CR := {"pos": "FV", "n": "", "nat": "Türkiye", "num": 10}
var MatchScreen = preload("res://scripts/match_screen.gd")

func _ready() -> void:
	G.main = self
	bg = UI.Bg.new(); add_child(bg); bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	frame = UI.vbox(0); add_child(frame); frame.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	header = UI.panel(UI.DEEP, 0, 0, Color.TRANSPARENT, Vector4(32, 22, 32, 20))
	frame.add_child(header)
	scroll = ScrollContainer.new(); scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 18
	frame.add_child(scroll)
	content = UI.vbox(0); content.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(content)
	nav = UI.panel(UI.DEEP); frame.add_child(nav)
	top_layer = Control.new(); add_child(top_layer); top_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT); top_layer.mouse_filter = MOUSE_FILTER_IGNORE
	sheet_layer = Control.new(); add_child(sheet_layer); sheet_layer.set_anchors_and_offsets_preset(PRESET_FULL_RECT); sheet_layer.mouse_filter = MOUSE_FILTER_IGNORE
	toast_box = UI.vbox(10); add_child(toast_box); toast_box.mouse_filter = MOUSE_FILTER_IGNORE
	toast_box.set_anchors_and_offsets_preset(PRESET_TOP_WIDE); toast_box.offset_left = 36; toast_box.offset_right = -36; toast_box.offset_top = 30
	get_tree().root.size_changed.connect(_on_resize)
	if G.load_game():
		if G.S.ui.tab == "match": G.S.ui.tab = "hub"
		render()
		if G.S.get("sm") != null: show_season()
		else:
			if G.S.wq.is_empty(): G.start_week(); render()
			show_pending()
	else:
		show_create()

func _on_resize() -> void:
	bg.queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if sheet_layer.get_child_count() > 0 and not sheet_lock: close_sheet()
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		G.save_game()

func clear(n: Node) -> void:
	for c in n.get_children(): c.queue_free()

# ================= bildirim =================
func toast(t: String) -> void:
	var p := UI.panel(Color("1E2560"), 18, 0, Color.TRANSPARENT, Vector4(30, 20, 28, 20))
	var s: StyleBoxFlat = p.get_theme_stylebox("panel")
	s.border_width_left = 10; s.border_color = UI.ACC; s.shadow_color = Color(0, 0, 0, .45); s.shadow_size = 16; s.shadow_offset = Vector2(0, 8)
	var h := UI.hbox(16); h.add_child(UI.icon("star", 34, UI.ACC)); var l := UI.lbl(t, 28, UI.CHALK, false, 600); l.size_flags_horizontal = SIZE_EXPAND_FILL; h.add_child(l)
	p.add_child(h)
	p.mouse_filter = MOUSE_FILTER_IGNORE
	toast_box.add_child(p)
	Sfx.play("notify")
	if toast_box.get_child_count() > 3: toast_box.get_child(0).queue_free()
	p.modulate.a = 0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, .15)
	tw.tween_interval(2.6); tw.tween_property(p, "modulate:a", 0.0, .3); tw.tween_callback(p.queue_free)

# ================= kâğıt pencere =================
func open_sheet(lock := false) -> VBoxContainer:
	close_sheet(true)
	sheet_lock = lock
	var dim := ColorRect.new(); dim.color = Color(0.016, 0.07, 0.047, .72)
	sheet_layer.add_child(dim); dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and not sheet_lock: close_sheet())
	var pan := UI.panel(UI.PAPER, 34, 0, Color.TRANSPARENT, Vector4(36, 44, 36, 48))
	var st: StyleBoxFlat = pan.get_theme_stylebox("panel")
	st.corner_radius_bottom_left = 0; st.corner_radius_bottom_right = 0; st.border_width_top = 5; st.border_color = UI.ACC
	st.shadow_color = Color(0, 0, 0, .5); st.shadow_size = 30
	sheet_layer.add_child(pan)
	pan.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	var sc := ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; sc.scroll_deadzone = 18
	pan.add_child(sc)
	var v := UI.vbox(18); v.size_flags_horizontal = SIZE_EXPAND_FILL
	sc.add_child(v)
	pan.set_meta("sc", sc)
	v.resized.connect(func(): _fit_sheet(pan, v))
	pan.modulate.a = 0
	var tw := pan.create_tween(); tw.tween_property(pan, "modulate:a", 1.0, .16)
	Sfx.play("confirm")
	return v

func _fit_sheet(pan: PanelContainer, v: VBoxContainer) -> void:
	var vh := get_viewport_rect().size.y
	var want: float = min(v.size.y + 104, vh * .88)
	var sc: ScrollContainer = pan.get_meta("sc")
	sc.custom_minimum_size = Vector2(0, want - 104)
	pan.offset_top = -want; pan.offset_bottom = 0

func close_sheet(silent := false) -> void:
	for c in sheet_layer.get_children(): c.queue_free()
	sheet_lock = false
	if not silent: call_deferred("show_pending")

func sheet_title(v: VBoxContainer, t: String, body: String = "") -> void:
	v.add_child(UI.lbl(t.to_upper(), 58, UI.CHALK, true, 900))
	var bar := ColorRect.new(); bar.color = UI.ACC; bar.custom_minimum_size = Vector2(90, 6); bar.size_flags_horizontal = SIZE_SHRINK_BEGIN; v.add_child(bar)
	if body != "": v.add_child(UI.lbl(body, 30, UI.INK2, false, 500))

func show_pending() -> void:
	if G.S == null or G.S.pend.is_empty() or sheet_layer.get_child_count() > 0: return
	if G.S.ui.tab == "match": return
	var e: Dictionary = G.S.pend[0]
	var v := open_sheet(true)
	sheet_title(v, e.title, e.text)
	for i in e.ch.size():
		var c = e.ch[i]
		var idx: int = i
		v.add_child(UI.btn(c.t, "pri" if i == 0 else "out", func():
			G.S.pend.pop_front(); G.apply_fx(e.ch[idx].f); G.save_game(); close_sheet(); render(), "", 40, true, true))

# ================= ana render =================
func render() -> void:
	if G.S == null: show_create(); return
	if G.S.ui.tab == "match": return
	header.visible = true; nav.visible = true
	_header(); _nav()
	clear(content)
	var body := UI.vbox(0)
	match G.S.ui.tab:
		"hub": _hub(body)
		"dev": _dev(body)
		"life": _life(body)
		"lig": _lig(body)
		"car": _car(body)
	var m := UI.margin(body, 26, 18, 26, 60)
	content.add_child(m)
	m.modulate.a = 0
	var tw := m.create_tween(); tw.tween_property(m, "modulate:a", 1.0, .2)

func _header() -> void:
	clear(header)
	var p = G.S.p; var t := G.my_team()
	var hs: StyleBoxFlat = header.get_theme_stylebox("panel"); hs.bg_color = Color(UI.DEEP, .92); hs.border_width_bottom = 3; hs.border_color = Color(UI.ACC, .6)
	hs.content_margin_top = 20; hs.content_margin_bottom = 18; hs.content_margin_left = 26; hs.content_margin_right = 26
	var v := UI.vbox(14)
	var r1 := UI.hbox(14)
	var badge := UI.panel(UI.ACC, 14, 0, Color.TRANSPARENT, Vector4(12, 2, 12, 2))
	badge.add_child(UI.lbl(str(G.ovr()), 40, UI.DARK, true, 900, HORIZONTAL_ALIGNMENT_CENTER, false))
	badge.size_flags_vertical = SIZE_SHRINK_CENTER
	r1.add_child(badge)
	var l := UI.vbox(0); l.size_flags_horizontal = SIZE_EXPAND_FILL
	var nm := UI.hbox(10); nm.add_child(UI.lbl(str(p.name).to_upper(), 38, UI.CHALK, true, 900, HORIZONTAL_ALIGNMENT_LEFT, false))
	if p.captain: nm.add_child(UI.chip("Kaptan", "y"))
	l.add_child(nm)
	l.add_child(UI.lbl(t.name, 23, UI.CHALK2, false, 600, HORIZONTAL_ALIGNMENT_LEFT, false))
	r1.add_child(l)
	r1.add_child(_pill("money", G.fmt(p.money), UI.YEL))
	v.add_child(r1)
	var r2 := UI.hbox(20)
	r2.add_child(_meter("bolt", int(p.energy), p.energy, UI.RED if p.energy < 35 else UI.ACC))
	r2.add_child(_meter("smile", int(p.moral), p.moral, UI.RED if p.moral < 30 else UI.YEL))
	var wk := "DÜNYA ŞAMPİYONASI" if G.S.phase == "tour" else "S%d  •  H%d/%d" % [G.S.season, min(int(G.S.week), G.LEAGUE_WEEKS), G.LEAGUE_WEEKS]
	r2.add_child(UI.lbl(wk, 26, UI.CHALK2, true, 800, HORIZONTAL_ALIGNMENT_RIGHT, false))
	v.add_child(r2)
	header.add_child(v)

func _pill(ic: String, txt: String, col: Color) -> PanelContainer:
	var pl := UI.panel(Color(0, 0, 0, .35), 30, 2, Color(col, .5), Vector4(14, 6, 20, 6))
	var h := UI.hbox(8); h.add_child(UI.icon(ic, 32, col)); h.add_child(UI.lbl(txt, 32, UI.CHALK, true, 900, HORIZONTAL_ALIGNMENT_LEFT, false))
	pl.add_child(h); pl.size_flags_vertical = SIZE_SHRINK_CENTER
	return pl

func _meter(ic: String, n: int, v: float, c: Color) -> HBoxContainer:
	var m := UI.hbox(8); m.size_flags_horizontal = SIZE_EXPAND_FILL
	m.add_child(UI.icon(ic, 30, c))
	var b := UI.Bar.new(v, c, 10); b.size_flags_horizontal = SIZE_EXPAND_FILL; b.size_flags_vertical = SIZE_SHRINK_CENTER
	m.add_child(b)
	m.add_child(UI.lbl(str(n), 24, UI.CHALK, true, 800, HORIZONTAL_ALIGNMENT_LEFT, false))
	return m

func _nav() -> void:
	clear(nav)
	var ns: StyleBoxFlat = nav.get_theme_stylebox("panel"); ns.bg_color = Color(UI.DEEP, .96); ns.border_width_top = 2; ns.border_color = Color(1, 1, 1, .08)
	var h := UI.hbox(0)
	var tabs := [["hub", "home", "Ana Sayfa"], ["dev", "dev", "Gelişim"], ["life", "shop", "Yaşam"], ["lig", "table", "Lig"], ["car", "person", "Kariyer"]]
	for x in tabs:
		var on: bool = G.S.ui.tab == x[0]
		var b := Button.new(); b.flat = true; b.focus_mode = FOCUS_NONE; b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 118)
		var e := StyleBoxEmpty.new()
		for st in ["normal", "hover", "pressed", "focus"]: b.add_theme_stylebox_override(st, e)
		var v := UI.vbox(0); v.mouse_filter = MOUSE_FILTER_IGNORE; v.alignment = BoxContainer.ALIGNMENT_CENTER
		var icw := UI.panel(Color(UI.ACC, .16) if on else Color.TRANSPARENT, 30, 0, Color.TRANSPARENT, Vector4(22, 4, 22, 4))
		icw.size_flags_horizontal = SIZE_SHRINK_CENTER; icw.mouse_filter = MOUSE_FILTER_IGNORE
		icw.add_child(UI.icon(x[1], 46, UI.ACC if on else UI.CHALK2))
		v.add_child(icw)
		var txt: String = x[2]
		if x[0] == "dev" and G.S.p.gp > 0: txt += " (%d)" % G.S.p.gp
		v.add_child(UI.lbl(txt.to_upper(), 21, UI.CHALK if on else UI.CHALK2, true, 800, HORIZONTAL_ALIGNMENT_CENTER, false))
		b.add_child(v); v.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		var id: String = x[0]
		b.pressed.connect(func(): G.S.ui.tab = id; Sfx.play("tap"); render(); scroll.scroll_vertical = 0)
		h.add_child(b)
	nav.add_child(UI.margin(h, 6, 4, 6, 8))

func _sec(body: VBoxContainer, title: String, small := "", first := false) -> VBoxContainer:
	var c := UI.card()
	var s := UI.section(title, small)
	c.add_child(s)
	body.add_child(UI.margin(c, 0, 0 if first else 24, 0, 0))
	return s

# ================= SEKMELER =================
func _card_data() -> Dictionary:
	var p = G.S.p; var t := G.my_team()
	var nat3: String = str(p.nation).replace("İ", "I").to_upper().substr(0, 3)
	return {"ovr": G.ovr(), "pos": {"FV": "FV", "KN": "KN", "OS": "OS", "DF": "STP"}[p.pos], "nat3": nat3, "name": str(p.name).split(" ", false)[-1] if str(p.name).split(" ", false).size() > 0 else p.name,
		"num": int(p.num), "col": t.col, "stats": [["HIZ", G.eff("hiz")], ["ŞUT", G.eff("sut")], ["PAS", G.eff("pas")], ["DRİ", G.eff("drip")], ["DEF", G.eff("sav")], ["FİZ", G.eff("fiz")]]}

func _hub(body: VBoxContainer) -> void:
	var p = G.S.p
	var top := UI.hbox(20)
	var pc := UI.PlayerCard.new(_card_data(), 300)
	pc.size_flags_vertical = SIZE_SHRINK_BEGIN
	top.add_child(pc)
	var right := UI.vbox(14); right.size_flags_horizontal = SIZE_EXPAND_FILL
	if not G.S.wq.is_empty():
		var m = G.S.wq[0]; var sd := G.match_sides(m); var sel := G.selection(m)
		var mc := UI.card(Vector4(20, 18, 20, 20))
		var mv := UI.vbox(12)
		mv.add_child(UI.lbl(m.label.to_upper(), 22, UI.ACC, true, 800))
		var H = sd.me if sd.home else sd.op; var A = sd.op if sd.home else sd.me
		var vs := UI.hbox(4)
		vs.add_child(_side(H)); var x := UI.lbl("VS", 34, UI.CHALK2, true, 900, HORIZONTAL_ALIGNMENT_CENTER, false); x.size_flags_vertical = SIZE_SHRINK_CENTER; vs.add_child(x); vs.add_child(_side(A))
		mv.add_child(vs)
		var ch := UI.hbox(8); ch.alignment = BoxContainer.ALIGNMENT_CENTER
		ch.add_child(UI.chip(G.SELN[sel][0], {"g": "g", "y": "y", "r": "r"}[G.SELN[sel][1]]))
		if G.S.wq.size() > 1: ch.add_child(UI.chip("%d maç" % G.S.wq.size()))
		mv.add_child(ch)
		mc.add_child(mv); right.add_child(mc)
		var play := UI.btn("Oyna", "pri", func(): start_match(G.S.wq[0]), "", 52, false, false, "play")
		play.custom_minimum_size.y = 120
		right.add_child(play)
	top.add_child(right)
	body.add_child(top)
	if p.injury > 0:
		var ip := UI.card(Vector4(24, 18, 24, 18), Color(UI.RED, .22))
		var ih := UI.hbox(14); ih.add_child(UI.icon("heal", 44, UI.RED)); var il := UI.lbl("Sakatsın: %d hafta daha. Antrenman yapamazsın, maçları tribünden izlersin." % p.injury, 27, UI.CHALK, false, 600); il.size_flags_horizontal = SIZE_EXPAND_FILL; ih.add_child(il)
		ip.add_child(ih); body.add_child(UI.margin(ip, 0, 22, 0, 0))
	var s := _sec(body, "Bu hafta")
	s.get_child(0).add_child(UI.Dots.new(int(p.actions)))
	var gr := GridContainer.new(); gr.columns = 2; gr.add_theme_constant_override("h_separation", 16); gr.add_theme_constant_override("v_separation", 16)
	var acts := [["Antrenman", "-15 enerji", "train", p.injury > 0, "train", Color("00E0B8")], ["Tedavi" if p.injury > 0 else "Dinlen", "+30 enerji", "rest", false, "rest", Color("3D7BFF")],
		["Sosyal", "Ün ve ilişkiler", "social", false, "social", Color("FF3D7F")], ["Keyif", "Tatil, parti, aile", "fun", false, "fun", Color("FFC83D")]]
	for a in acts:
		var id: String = a[2]
		gr.add_child(_tile(a[0], a[1], a[4], a[5], func(): _action(id), p.actions <= 0 or a[3]))
	s.add_child(gr)
	if p.target != null and G.S.phase == "season":
		var ts := _sec(body, "Sezon hedefi", "Hocanın beklentisi")
		var tv := G.target_val(); var tg = p.target
		var row := UI.hbox(); var a1 := UI.lbl("%s %s" % [str(tg.v), tg.n], 30, UI.CHALK2); a1.size_flags_horizontal = SIZE_EXPAND_FILL; row.add_child(a1); row.add_child(UI.lbl(str(tv), 44, UI.CHALK, true, 900, HORIZONTAL_ALIGNMENT_RIGHT, false))
		ts.add_child(row)
		var pr: float = clamp(tv / float(tg.v) * 100.0, 0, 100)
		ts.add_child(UI.Bar.new(pr, Color("3DDC84") if pr >= 100 else UI.ACC, 14))
	var r: Array = p.ratings.slice(max(0, p.ratings.size() - 8))
	if not r.is_empty():
		var rs := _sec(body, "Son maçlar", "Form " + G.r1(G.form_avg()))
		rs.add_child(UI.RBars.new(r))
	var nsx := _sec(body, "Haberler")
	if G.S.news.is_empty(): nsx.add_child(UI.lbl("Henüz haber yok.", 28, UI.CHALK2))
	for i in min(6, G.S.news.size()):
		var n = G.S.news[i]
		var h := UI.hbox(14)
		var wl := UI.panel(Color(UI.ACC2, .2), 12, 0, Color.TRANSPARENT, Vector4(10, 4, 10, 4)); wl.add_child(UI.lbl(n.w, 22, UI.CHALK, true, 800, HORIZONTAL_ALIGNMENT_CENTER, false)); wl.size_flags_vertical = SIZE_SHRINK_BEGIN
		h.add_child(wl)
		var tl := UI.lbl(n.t, 27, UI.CHALK); tl.size_flags_horizontal = SIZE_EXPAND_FILL; h.add_child(tl)
		nsx.add_child(h)

func _tile(title: String, sub: String, ic: String, col: Color, cb: Callable, dis: bool) -> Button:
	var b := Button.new(); b.focus_mode = FOCUS_NONE; b.size_flags_horizontal = SIZE_EXPAND_FILL; b.custom_minimum_size = Vector2(0, 170)
	var n := UI.sb(Color(col, .12), 22, 2, Color(col, .45))
	var pr := n.duplicate(); pr.bg_color = Color(col, .28)
	for st in ["normal", "hover", "focus"]: b.add_theme_stylebox_override(st, n)
	b.add_theme_stylebox_override("pressed", pr); b.add_theme_stylebox_override("disabled", UI.sb(Color(1, 1, 1, .03), 22, 2, Color(1, 1, 1, .06)))
	var v := UI.vbox(6); v.mouse_filter = MOUSE_FILTER_IGNORE
	var icb := UI.panel(col, 40, 0, Color.TRANSPARENT, Vector4(10, 6, 10, 6)); icb.size_flags_horizontal = SIZE_SHRINK_BEGIN; icb.mouse_filter = MOUSE_FILTER_IGNORE
	icb.add_child(UI.icon(ic, 46, UI.DARK))
	v.add_child(icb)
	v.add_child(UI.lbl(title.to_upper(), 36, UI.CHALK, true, 900, HORIZONTAL_ALIGNMENT_LEFT, false))
	v.add_child(UI.lbl(sub, 22, UI.CHALK2, false, 500, HORIZONTAL_ALIGNMENT_LEFT, false))
	b.add_child(v); v.set_anchors_and_offsets_preset(PRESET_FULL_RECT); v.offset_left = 20; v.offset_top = 18; v.offset_right = -14; v.offset_bottom = -14
	b.disabled = dis; b.modulate = Color(1, 1, 1, .45) if dis else Color.WHITE
	b.pressed.connect(func(): Sfx.play("tap"); cb.call())
	return b

func _side(t) -> VBoxContainer:
	var v := UI.vbox(6); v.size_flags_horizontal = SIZE_EXPAND_FILL
	v.add_child(UI.Crest.new(t.name, Color(t.col), .72))
	v.add_child(UI.lbl(t.name, 26, UI.CHALK, true, 800, HORIZONTAL_ALIGNMENT_CENTER))
	var n: int = clamp(int(round((t.str - 35) / 11.0)), 1, 5)
	v.add_child(UI.lbl("★".repeat(n) + "☆".repeat(5 - n), 20, UI.YEL, false, 600, HORIZONTAL_ALIGNMENT_CENTER))
	return v

func _dev(body: VBoxContainer) -> void:
	var p = G.S.p; var k := G.perks(); var w: Dictionary = G.POS[p.pos].w
	var top := UI.hbox(30)
	top.add_child(UI.lbl(str(G.ovr()), 150, UI.CHALK, true, 900, HORIZONTAL_ALIGNMENT_LEFT, false))
	var tv := UI.vbox(6); tv.size_flags_horizontal = SIZE_EXPAND_FILL; tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.add_child(UI.lbl("%s, %d yaşında" % [G.POS[p.pos].n, p.age], 34, UI.CHALK, true, 800))
	tv.add_child(UI.lbl("Piyasa değeri " + G.fmt(G.market_value()), 28, UI.CHALK2))
	tv.add_child(UI.chip("%d gelişim puanı" % p.gp, "y"))
	top.add_child(tv)
	body.add_child(UI.margin(top, 0, 30, 0, 16))
	body.add_child(UI.lbl("Maçlarda iyi oynadıkça gelişim puanı kazanırsın. Antrenman ise seçtiğin özelliğin ilerleme çubuğunu doldurur; çubuk dolunca özellik bir artar.", 26, UI.CHALK2))
	var s := _sec(body, "Özellikler", "● mevkin için önemli")
	for a in G.AK:
		var v: int = p.attrs[a]; var b: int = k.bonus.get(a, 0); var c := G.gp_cost(v)
		var row := UI.hbox(20)
		var l := UI.vbox(0); l.custom_minimum_size = Vector2(190, 0)
		l.add_child(UI.lbl(G.AT[a] + (" ●" if w.get(a, 0) >= .14 else ""), 30, UI.CHALK, false, 700, HORIZONTAL_ALIGNMENT_LEFT, false))
		l.add_child(UI.lbl(("+%d ekipman" % b) if b > 0 else ("%d GP" % c), 22, UI.CHALK2, false, 500, HORIZONTAL_ALIGNMENT_LEFT, false))
		row.add_child(l)
		var vl := UI.lbl(str(v), 54, UI.YEL if v >= 80 else (UI.CHALK if v >= 50 else Color("E9798A")), true, 900, HORIZONTAL_ALIGNMENT_CENTER, false); vl.custom_minimum_size = Vector2(80, 0)
		row.add_child(vl)
		var bv := UI.vbox(6); bv.size_flags_horizontal = SIZE_EXPAND_FILL; bv.alignment = BoxContainer.ALIGNMENT_CENTER
		bv.add_child(UI.Bar.new(p.axp.get(a, 0), UI.CHALK2, 12)); bv.add_child(UI.lbl("Antrenman %%%d" % int(p.axp.get(a, 0)), 21, UI.CHALK2))
		row.add_child(bv)
		var aa: String = a
		var pl := UI.btn("+", "pri", func():
			if p.gp >= G.gp_cost(p.attrs[aa]) and p.attrs[aa] < 99:
				p.gp -= G.gp_cost(p.attrs[aa]); p.attrs[aa] += 1; G.check_ach(); G.save_game(); render(), "", 44)
		pl.custom_minimum_size = Vector2(84, 76)
		UI.set_disabled(pl, p.gp < c or v >= 99)
		row.add_child(pl)
		s.add_child(row); s.add_child(UI.rule(UI.LINE, 2))

func _life(body: VBoxContainer) -> void:
	var p = G.S.p; var k := G.perks(); var sp := G.sponsor_weekly()
	var s := _sec(body, "Haftalık gelir", "", true)
	s.add_child(UI.kv("Maaş", G.fmt(p.wage))); s.add_child(UI.kv("Sponsorlar", G.fmt(sp))); s.add_child(UI.kv("Yatırımlar", G.fmt(k.income)))
	s.add_child(UI.kv("Toplam", G.fmt(p.wage + sp + k.income))); s.add_child(UI.kv("Kontrat", "%d sezon kaldı" % p.contract))
	var ss := _sec(body, "Sponsorlar", "%d/%d" % [p.sponsors.size(), 5 if p.items.has("agent") else 4])
	if p.sponsors.is_empty(): ss.add_child(UI.lbl("Ünün arttıkça markalar kapını çalacak.", 28, UI.CHALK2))
	for x in p.sponsors: ss.add_child(UI.kv(x.n, "%s/hafta, %d sezon" % [G.fmt(x.w), x.s]))
	for cat in G.SHOP_CATS:
		var cs := _sec(body, cat[1])
		for it in G.SHOP:
			if it.cat != cat[0]: continue
			var row := UI.hbox(20)
			var d := UI.vbox(2); d.size_flags_horizontal = SIZE_EXPAND_FILL
			d.add_child(UI.lbl(it.name, 38, UI.CHALK, true, 800)); d.add_child(UI.lbl(it.desc, 25, UI.CHALK2))
			row.add_child(d)
			var own := G.owned(it.id); var sup := false
			if it.has("g") and not own:
				for y in G.SHOP:
					if y.get("g", "") == it.g and y.lv > it.lv and G.owned(y.id): sup = true
			if own: row.add_child(UI.chip("Sende", "g"))
			elif sup: row.add_child(UI.chip("Daha iyisi sende"))
			else:
				var iid: String = it.id
				var b := UI.btn(G.fmt(it.price), "pri" if p.money >= it.price else "out", func(): _buy(iid), "", 32)
				b.custom_minimum_size = Vector2(190, 76)
				UI.set_disabled(b, p.money < it.price)
				row.add_child(b)
			cs.add_child(row); cs.add_child(UI.rule(UI.LINE, 2))

func _buy(id: String) -> void:
	var it := G.item_by(id); var p = G.S.p
	if p.money < it.price or G.owned(id): return
	p.money -= it.price; p.items[id] = true
	if it.has("fame"): p.fame = clamp(p.fame + it.fame, 0, 100)
	Sfx.play("coin"); toast(it.name + " satın alındı"); G.news(it.name + " satın aldın."); G.check_ach(); G.save_game(); render()

func _lig(body: VBoxContainer) -> void:
	var lt: String = G.S.ui.lt; var t := G.tier()
	var seg := UI.panel(Color(1, 1, 1, .06), 34, 2, Color(1, 1, 1, .12), Vector4(6, 6, 6, 6))
	var sh := UI.hbox(0)
	for x in [["tablo", "Puan durumu"], ["fikstur", "Fikstür"], ["gol", "Gol krallığı"]]:
		var on: bool = lt == x[0]
		var b := Button.new(); b.focus_mode = FOCUS_NONE; b.size_flags_horizontal = SIZE_EXPAND_FILL; b.custom_minimum_size = Vector2(0, 80)
		var st := UI.sb(UI.ACC if on else Color.TRANSPARENT, 30)
		for n in ["normal", "hover", "pressed", "focus"]: b.add_theme_stylebox_override(n, st)
		var l := UI.lbl(str(x[1]).to_upper(), 30, UI.DARK if on else UI.CHALK, true, 900, HORIZONTAL_ALIGNMENT_CENTER, false); b.add_child(l); l.set_anchors_and_offsets_preset(PRESET_FULL_RECT); l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var id: String = x[0]
		b.pressed.connect(func(): G.S.ui.lt = id; render())
		sh.add_child(b)
	seg.add_child(sh)
	body.add_child(UI.margin(seg, 0, 30, 0, 10))
	if lt == "tablo":
		var s := _sec(body, G.TIERS[t].n, ("İlk 2 yükselir" if t > 0 else "Şampiyon") + (", son 2 düşer" if t < 3 else ""))
		var W := [56, 0, 50, 50, 50, 50, 64, 64]
		s.add_child(_trow(["#", "Takım", "O", "G", "B", "M", "AV", "P"], W, false, true))
		var st := G.sorted_table()
		for i in st.size():
			var id: int = st[i]; var r = G.S.table[str(id)]
			var z := ""
			if (i < 2 and t > 0) or i == 0: z = "up"
			elif i >= st.size() - 2 and t < 3: z = "down"
			s.add_child(_trow([str(i + 1), G.team(id).name, str(r.p), str(r.w), str(r.d), str(r.l), str(r.gf - r.ga), str(r.pts)], W, id == int(G.S.p.team), false, z))
	elif lt == "fikstur":
		var s := _sec(body, "Fikstürün")
		for i in G.S.fixtures.size():
			var rd: Array = G.S.fixtures[i]; var mm = null
			for x in rd:
				if int(x[0]) == int(G.S.p.team) or int(x[1]) == int(G.S.p.team): mm = x
			var res := "-"
			for x in G.S.results:
				if int(x.r) == i: res = x.s
			s.add_child(_trow([str(i + 1), G.team(mm[0]).name, res, G.team(mm[1]).name], [56, 0, 100, 0], i == int(G.S.week) - 1, false, "", [false, false, true, false]))
	else:
		var s := _sec(body, "Gol krallığı")
		var l := []
		for id in G.league_ids(t): l.append({"n": G.team(id).star.name, "t": G.team(id).name, "g": G.team(id).star.goals, "me": false})
		l.append({"n": G.S.p.name + " (sen)", "t": G.my_team().name, "g": G.S.p.season.lgoals, "me": true})
		l.sort_custom(func(a, b): return a.g > b.g)
		s.add_child(_trow(["#", "Oyuncu", "Gol"], [56, 0, 80], false, true))
		for i in min(15, l.size()):
			var x = l[i]
			s.add_child(_trow([str(i + 1), "%s\n%s" % [x.n, x.t], str(x.g)], [56, 0, 80], x.me))

func _trow(cells: Array, widths: Array, me := false, head := false, zone := "", bold := []) -> Control:
	var p := UI.panel(Color(UI.ACC, .16) if me else Color.TRANSPARENT, 10 if me else 0, 0, Color.TRANSPARENT, Vector4(10, 14, 6, 14))
	var st: StyleBoxFlat = p.get_theme_stylebox("panel")
	st.border_width_top = 0 if head else 2; st.border_color = UI.LINE
	if zone != "": st.border_width_left = 8; st.border_color = UI.ACC if zone == "up" else UI.RED
	var h := UI.hbox(4)
	for i in cells.size():
		var w: int = widths[i]
		var al := HORIZONTAL_ALIGNMENT_LEFT if w == 0 else HORIZONTAL_ALIGNMENT_CENTER
		var col := UI.CHALK2 if head else UI.CHALK
		var wt := 600 if head else (700 if (me or i == cells.size() - 1 or (bold.size() > i and bold[i])) else 500)
		var l := UI.lbl(cells[i], 24 if head else 28, col, false, wt, al, w == 0)
		if w == 0: l.size_flags_horizontal = SIZE_EXPAND_FILL
		else: l.custom_minimum_size = Vector2(w, 0)
		h.add_child(l)
	p.add_child(h)
	return p

func _car(body: VBoxContainer) -> void:
	var p = G.S.p; var c = p.career; var s = p.season
	var ps := _sec(body, "Profil", "", true)
	ps.add_child(UI.kv("Uyruk", p.nation)); ps.add_child(UI.kv("Mevki", G.POS[p.pos].n)); ps.add_child(UI.kv("Yaş", str(p.age)))
	ps.add_child(UI.kv("Takipçi", G.fmtf(G.followers()))); ps.add_child(UI.kv("Ün", "%d/100" % int(p.fame))); ps.add_child(UI.kv("Kulüpler", ", ".join(p.clubs)))
	var rs := _sec(body, "İlişkiler")
	for x in [["coach", "Teknik direktör", UI.YEL], ["team", "Takım arkadaşları", UI.CHALK], ["fans", "Taraftarlar", UI.CHALK], ["media", "Medya", UI.CHALK2]]:
		var row := UI.hbox(20)
		var l := UI.lbl(x[1], 28, UI.CHALK); l.custom_minimum_size = Vector2(250, 0); row.add_child(l)
		var b := UI.Bar.new(p.rel[x[0]], x[2], 12); b.size_flags_horizontal = SIZE_EXPAND_FILL; b.size_flags_vertical = SIZE_SHRINK_CENTER; row.add_child(b)
		var v := UI.lbl(str(int(p.rel[x[0]])), 30, UI.CHALK, false, 700, HORIZONTAL_ALIGNMENT_RIGHT, false); v.custom_minimum_size = Vector2(60, 0); row.add_child(v)
		rs.add_child(row)
	var avg := G.r2(s.rsum / s.apps) if s.apps > 0 else "-"
	var cavg := G.r2(c.rsum / c.apps) if c.apps > 0 else "-"
	_sec(body, "Bu sezon").add_child(_stats([[s.apps, "Maç"], [s.goals, "Gol"], [s.assists, "Asist"], [avg, "Ortalama"]]))
	var ks := _sec(body, "Kariyer")
	ks.add_child(_stats([[c.apps, "Maç"], [c.goals, "Gol"], [c.assists, "Asist"], [cavg, "Ortalama"]]))
	ks.add_child(_stats([[c.motm, "Maçın adamı"], [p.nat.caps, "Milli maç"], [p.nat.goals, "Milli gol"], [p.trophies.size(), "Kupa"]]))
	var ts := _sec(body, "Kupalar ve ödüller")
	var fl := HFlowContainer.new(); fl.add_theme_constant_override("h_separation", 12); fl.add_theme_constant_override("v_separation", 12)
	for x in p.trophies: fl.add_child(UI.chip(x, "y"))
	for x in p.awards: fl.add_child(UI.chip(x, "p"))
	if p.trophies.is_empty() and p.awards.is_empty(): ts.add_child(UI.lbl("Henüz yok. İlki yakında.", 28, UI.CHALK2))
	ts.add_child(fl)
	var as_ := _sec(body, "Başarımlar", "%d/%d" % [p.ach.size(), G.ACH.size()])
	var gr := GridContainer.new(); gr.columns = 3; gr.add_theme_constant_override("h_separation", 14); gr.add_theme_constant_override("v_separation", 14)
	for a in G.ACH:
		var on: bool = p.ach.has(a[0])
		var cell := UI.panel(UI.YEL if on else Color(1, 1, 1, .04), 18, 2, UI.YEL if on else UI.LINE, Vector4(10, 18, 10, 18))
		cell.size_flags_horizontal = SIZE_EXPAND_FILL
		cell.add_child(UI.lbl(str(a[1]).to_upper(), 26, UI.DARK if on else UI.CHALK2, true, 900, HORIZONTAL_ALIGNMENT_CENTER))
		var desc: String = a[2]
		cell.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed: toast(desc))
		gr.add_child(cell)
	as_.add_child(gr)
	if not p.history.is_empty():
		var hs := _sec(body, "Kariyer geçmişi")
		var W := [80, 0, 54, 54, 54, 80, 60]
		hs.add_child(_trow(["Yıl", "Takım", "M", "G", "A", "Ort", "Sıra"], W, false, true))
		for x in p.history: hs.add_child(_trow([str(x.y), x.t, str(x.a), str(x.g), str(x["as"]), str(x.r), "%d." % x.pos], W))
	var hf := G.hof()
	if not hf.is_empty():
		var fs := _sec(body, "Efsaneler salonu")
		for x in hf.slice(0, 6): fs.add_child(UI.kv("%s, %s" % [x.n, x.pos], "%s, %d gol" % [x.t, x.g]))
	var st := _sec(body, "Ayarlar")
	st.add_child(UI.btn("Ses: açık" if G.sound else "Ses: kapalı", "out", func(): G.sound = not G.sound; G.save_settings(); render()))
	st.add_child(UI.btn("Kayıt kodunu panoya kopyala", "out", func(): DisplayServer.clipboard_set(G.export_code()); toast("Kayıt kodu panoya kopyalandı")))
	st.add_child(UI.btn("Panodaki kayıt kodunu yükle", "out", func():
		if G.import_code(DisplayServer.clipboard_get()): toast("Kayıt yüklendi"); render()
		else: toast("Panodaki metin geçerli bir kayıt kodu değil")))
	if p.age >= 33: st.add_child(UI.btn("Emekliliğini açıkla", "chalk", _ask_retire))
	st.add_child(UI.btn("Yeni kariyer başlat", "red", func():
		var v := open_sheet()
		sheet_title(v, "Yeni kariyer", "Mevcut kariyerin silinecek. Bu geri alınamaz.")
		v.add_child(UI.btn("Sil ve baştan başla", "red", func(): G.delete_save(); G.S = null; close_sheet(true); show_create(), "", 40, true))
		v.add_child(UI.btn("Vazgeç", "out", func(): close_sheet(), "", 40, true))))

func _stats(items: Array) -> HBoxContainer:
	var h := UI.hbox(14)
	for it in items:
		var p := UI.panel(Color.TRANSPARENT, 0, 0, Color.TRANSPARENT, Vector4(18, 4, 4, 4))
		var st: StyleBoxFlat = p.get_theme_stylebox("panel"); st.border_width_left = 6; st.border_color = UI.LINE
		p.size_flags_horizontal = SIZE_EXPAND_FILL
		var v := UI.vbox(0)
		v.add_child(UI.lbl(str(it[0]), 62, UI.CHALK, true, 900, HORIZONTAL_ALIGNMENT_LEFT, false)); v.add_child(UI.lbl(it[1], 23, UI.CHALK2))
		p.add_child(v); h.add_child(p)
	return h

# ================= eylemler =================
func _action(id: String) -> void:
	var p = G.S.p
	if p.actions <= 0: return
	match id:
		"rest":
			p.actions -= 1; p.energy = clamp(p.energy + 30, 0, 100); p.moral = clamp(p.moral + 3, 0, 100)
			if p.injury > 1 and randf() < (.5 if p.items.has("physio") else .25):
				p.injury -= 1; toast("Tedavi iyi gidiyor, iyileşme hızlandı")
			else: toast("Dinlendin: +30 enerji")
			G.save_game(); render()
		"train":
			if p.injury > 0: return
			if p.energy < 15: toast("Antrenman için enerjin yetersiz. Önce dinlen."); return
			var v := open_sheet()
			sheet_title(v, "Antrenman", "Hangi özelliğine çalışmak istiyorsun?")
			var gr := GridContainer.new(); gr.columns = 2; gr.add_theme_constant_override("h_separation", 16); gr.add_theme_constant_override("v_separation", 16)
			for a in G.AK:
				var aa: String = a
				var b := UI.btn("%s  %d" % [G.AT[a], p.attrs[a]], "out", func(): _train2(aa), "", 36, true, true); b.size_flags_horizontal = SIZE_EXPAND_FILL
				gr.add_child(b)
			v.add_child(gr)
		"social":
			var v := open_sheet()
			sheet_title(v, "Sosyal")
			v.add_child(UI.btn("Sosyal medya paylaşımı", "out", func(): _soc("post"), "Ün kazandırır, küçük bir ters tepme riski var", 38, true))
			v.add_child(UI.btn("Taraftarlarla imza günü", "out", func(): _soc("fans"), "Taraftar sevgisi artar", 38, true))
			v.add_child(UI.btn("Takıma yemek ısmarla", "out", func(): _soc("team"), "%s, takım arkadaşları sevinir" % G.fmt(300 + p.wage * .3), 38, true))
			v.add_child(UI.btn("Hocayla birebir görüş", "out", func(): _soc("coach"), "Teknik direktörle ilişkin güçlenir", 38, true))
			v.add_child(UI.btn("Röportaj ver", "out", func(): _soc("media"), "Medya ilişkisi ve ün artar", 38, true))
		"fun":
			var tc := int(1500 + p.wage * .6); var pc := int(800 + p.wage * .25)
			var v := open_sheet()
			sheet_title(v, "Keyif")
			var b1 := UI.btn("Kısa tatil", "out", func(): _fun("trip", tc), "%s, moral +35, enerji +25" % G.fmt(tc), 38, true); UI.set_disabled(b1, p.money < tc); v.add_child(b1)
			var b2 := UI.btn("Ev partisi ver", "out", func(): _fun("party", pc), "%s, moral +20, takım +6, enerji -15" % G.fmt(pc), 38, true); UI.set_disabled(b2, p.money < pc); v.add_child(b2)
			v.add_child(UI.btn("Aileyle vakit geçir", "out", func(): _fun("family", 0), "Moral +15, enerji +10", 38, true))
			v.add_child(UI.btn("Konsol başında bir akşam", "out", func(): _fun("game", 0), "Moral +8, enerji +5", 38, true))

func _train2(a: String) -> void:
	var g := int(round(G.train_base(a)))
	var v := open_sheet()
	sheet_title(v, G.AT[a] + " antrenmanı", "Hızlı antrenmanla garantili gelişim al ya da mini oyunda başarılı olup iki katından fazlasını kap.")
	v.add_child(UI.btn("Hızlı antrenman", "out", func(): _train_run(a, false), "+%d ilerleme, 15 enerji" % g, 40, true))
	v.add_child(UI.btn("Yoğun antrenman", "pri", func(): _train_run(a, true), "Mini oyun, 20 enerji", 40, true))

func _train_run(a: String, mini: bool) -> void:
	close_sheet(true)
	var p = G.S.p; p.actions -= 1; var mult := 1.0
	if mini:
		p.energy = clamp(p.energy - 20, 0, 100)
		var sc := 0.0
		if a == "sut" or a == "duran":
			var sg = preload("res://scripts/shot.gd").new()
			sg.setup({"kind": "train", "attr": G.eff(a), "title": G.AT[a] + " antrenmanı", "fk": a == "duran"})
			top_layer.add_child(sg); sg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
			sc = float(await sg.done)
		else:
			sc = await _timing_train(a)
		mult = .5 + sc / 5.0 * 1.7
	else:
		p.energy = clamp(p.energy - 15, 0, 100)
	var amt := G.train_base(a) * mult
	var up := G.add_xp(a, amt); p.moral = clamp(p.moral + 1, 0, 100)
	if up > 0: toast("%s yükseldi: %d" % [G.AT[a], p.attrs[a]]); Sfx.play("ach")
	else: toast("%s ilerlemesi %%%d" % [G.AT[a], int(p.axp[a])])
	G.check_ach(); G.save_game(); render()

func _timing_train(a: String) -> float:
	var v := open_sheet(true)
	var box := UI.vbox(16); v.add_child(box)
	var sc := 0.0
	var Timing = preload("res://scripts/timing.gd")
	for i in 5:
		clear(box)
		var tb = Timing.new()
		tb.setup("%s antrenmanı, %d/5" % [G.AT[a], i + 1], "Beyaz çizgi yeşil alandayken bas. Sarı alan mükemmel sayılır.", .13 + G.S.p.attrs[a] / 700.0, 1.25 + i * .18, "Şimdi")
		box.add_child(tb)
		var g: String = await tb.graded
		sc += 1.2 if g == "perfect" else (.8 if g == "good" else 0.0)
	sc = min(5.0, sc)
	clear(box)
	box.add_child(UI.lbl("Antrenman bitti. Performans %%%d" % int(sc / 5 * 100), 40, UI.INK, true, 800))
	await get_tree().create_timer(.9).timeout
	close_sheet(true)
	return sc

func _soc(v: String) -> void:
	close_sheet(true)
	var p = G.S.p; p.actions -= 1; var msg := ""
	match v:
		"post":
			if randf() < .12: p.rel.media -= 5; p.rel.fans -= 3; msg = "Paylaşımın yanlış anlaşıldı, biraz tepki aldın."
			else: p.fame += G.R(.8, 2.5); msg = "Paylaşımın çok beğenildi. Takipçi: " + G.fmtf(G.followers())
		"fans": p.rel.fans += 7; p.energy -= 6; p.fame += .5; msg = "Yüzlerce taraftara imza dağıttın."
		"team": p.money -= int(300 + p.wage * .3); p.rel.team += 8; msg = "Takım arkadaşların çok mutlu oldu."
		"coach":
			var d := G.RI(2, 7); p.rel.coach += d; msg = "Hocanla verimli bir konuşma yaptın (+%d)." % d
		"media":
			p.rel.media += 6; p.fame += 1
			if randf() < .15: p.rel.coach -= 4; msg = "Röportajdaki bir sözün hocanın kulağına gitti."
			else: msg = "Röportajın çok konuşuldu."
	for k in p.rel: p.rel[k] = clamp(p.rel[k], 0, 100)
	p.fame = clamp(p.fame, 0, 100); p.energy = clamp(p.energy, 0, 100)
	toast(msg); G.check_ach(); G.save_game(); render()

func _fun(v: String, cost: int) -> void:
	close_sheet(true)
	var p = G.S.p; p.actions -= 1
	match v:
		"trip": p.money -= cost; p.moral += 35; p.energy += 25; toast("Harika bir mola verdin.")
		"party":
			p.money -= cost; p.moral += 20; p.rel.team += 6; p.energy -= 15
			if randf() < .15: p.rel.coach -= 6; toast("Parti güzeldi ama hoca duydu.")
			else: toast("Unutulmaz bir parti oldu.")
		"family": p.moral += 15; p.energy += 10; toast("Ailen seninle gurur duyuyor.")
		"game": p.moral += 8; p.energy += 5; toast("Kafa dağıttın.")
	p.moral = clamp(p.moral, 0, 100); p.energy = clamp(p.energy, 0, 100)
	p.rel.team = clamp(p.rel.team, 0, 100); p.rel.coach = clamp(p.rel.coach, 0, 100)
	G.save_game(); render()

# ================= maç =================
func start_match(m: Dictionary) -> void:
	G.S.ui.tab = "match"
	header.visible = false; nav.visible = false; clear(content)
	var ms = MatchScreen.new()
	top_layer.add_child(ms); ms.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	ms.begin(m)

func match_closed() -> void:
	G.after_match_continue()
	if G.S != null and G.S.ui.tab != "match": render()

# ================= sezon sonu =================
func show_season() -> void:
	var sm = G.S.sm; var p = G.S.p
	render()
	var v := open_sheet(true)
	if sm.get("ret", false):
		sheet_title(v, "Sezon %d bitti" % G.S.season, "\n".join(sm.lines))
		v.add_child(UI.lbl("40 yaşına geldin. Efsanevi kariyerine nokta koyma vakti.", 31, UI.INK2))
		v.add_child(UI.btn("Emekliliğini açıkla", "chalk", _do_retire, "", 44, true))
		return
	sheet_title(v, "Sezon %d sona erdi" % G.S.season, "Ligi %d. sırada bitirdin.\n%s" % [sm.pos, "\n".join(sm.lines)])
	v.add_child(UI.lbl("Transfer ve kontrat", 44, UI.INK, true, 800))
	var ren = G.renewal() if p.contract <= 0 else null
	if p.contract > 0:
		v.add_child(_offer_card(G.my_team().name + "'da kal", "%d sezon kontratın var. Maaş %s/hafta." % [p.contract, G.fmt(p.wage)], "Kulübümde kalıyorum", -1, "g"))
	elif ren != null:
		v.add_child(_offer_card(G.my_team().name + ", yeni kontrat", "%d sezon, haftalık %s." % [ren.years, G.fmt(ren.wage)], "Kontratı yenile", -2, "g"))
	else:
		v.add_child(UI.lbl("Kontratın bitti ve kulübün yenilemek istemiyor. Yeni bir takım seçmelisin.", 30, UI.INK2))
	for i in G.S.offers.size():
		var x = G.S.offers[i]; var tm := G.team(x.team)
		var n: int = clamp(int(round((tm.str - 35) / 11.0)), 1, 5)
		v.add_child(_offer_card(tm.name, "%s, güç %s\n%d sezon, haftalık %s, imza parası %s" % [G.TIERS[int(tm.tier)].n, "●".repeat(n) + "○".repeat(5 - n), x.years, G.fmt(x.wage), G.fmt(x.sign)], "İmzala", i, "p" if tm.tier < G.tier() else ""))
	if p.age >= 33: v.add_child(UI.btn("Emekli ol", "chalk", _do_retire, "", 40, true))

func _offer_card(title: String, desc: String, cta: String, idx: int, kind := "") -> VBoxContainer:
	var w := UI.vbox(10)
	w.add_child(UI.rule(Color(UI.INK, .35), 3))
	w.add_child(UI.lbl(title, 46, UI.INK, true, 800))
	w.add_child(UI.lbl(desc, 27, UI.INK2))
	w.add_child(UI.btn(cta, "pri" if kind == "g" else "out", func(): close_sheet(true); G.accept_offer(idx), "", 36, true))
	return w

func _ask_retire() -> void:
	var v := open_sheet()
	sheet_title(v, "Emeklilik", "Kramponlarını gerçekten asmak istiyor musun? Kariyerin Efsaneler Salonu'na yazılacak.")
	v.add_child(UI.btn("Evet, emekli ol", "chalk", _do_retire, "", 40, true))
	v.add_child(UI.btn("Daha oynayacağım", "out", func(): close_sheet(), "", 40, true))

func _do_retire() -> void:
	close_sheet(true)
	var r := G.retire()
	var v := open_sheet(true)
	sheet_title(v, "Bir efsane veda ediyor", "%s, %d yaşında kramponlarını astı." % [r.name, r.age])
	var h := UI.hbox(14)
	for it in [[r.apps, "Maç"], [r.goals, "Gol"], [r.assists, "Asist"], [r.trophies, "Kupa"]]:
		var c := UI.vbox(0); c.size_flags_horizontal = SIZE_EXPAND_FILL
		c.add_child(UI.lbl(str(it[0]), 62, UI.INK, true, 900)); c.add_child(UI.lbl(it[1], 24, UI.INK2)); h.add_child(c)
	v.add_child(h)
	v.add_child(UI.lbl(r.title, 56, UI.INK, true, 900, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.lbl("Miras puanı %d" % r.leg, 28, UI.INK2, false, 500, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.btn("Yeni kariyere başla", "pri", func(): close_sheet(true); show_create(), "", 44, true))

# ================= oluşturma =================
var _kitprev: UI.Jersey
func show_create() -> void:
	header.visible = false; nav.visible = false
	clear(content)
	var v := UI.vbox(24)
	var top := UI.hbox(20)
	var tl := UI.vbox(12); tl.size_flags_horizontal = SIZE_EXPAND_FILL
	tl.add_child(UI.lbl("Efsane\nYolu", 132, UI.CHALK, true, 900, HORIZONTAL_ALIGNMENT_LEFT, false))
	tl.add_child(UI.lbl("17 yaşındasın ve bölgesel ligde ilk sözleşmeni imzalamak üzeresin. Gerisi senin ayaklarında.", 29, UI.CHALK2))
	top.add_child(tl)
	_kitprev = UI.Jersey.new(CR.n if CR.n != "" else "Oyuncu", CR.num, UI.CHALK, 0, 250)
	_kitprev.size_flags_vertical = SIZE_SHRINK_CENTER
	top.add_child(_kitprev)
	v.add_child(top)
	v.add_child(UI.lbl("Formanın arkasına yazılacak isim", 26, UI.CHALK2, false, 600))
	var le := LineEdit.new(); le.placeholder_text = "Ad Soyad"; le.max_length = 22; le.text = CR.n
	_style_input(le)
	le.text_changed.connect(func(t): CR.n = t; _kitprev.set_data(t if t != "" else "Oyuncu", CR.num, UI.CHALK, 0))
	v.add_child(le)
	var row := UI.hbox(20)
	var c1 := UI.vbox(10); c1.size_flags_horizontal = SIZE_EXPAND_FILL
	c1.add_child(UI.lbl("Uyruk", 26, UI.CHALK2, false, 600))
	var ob := OptionButton.new(); _style_input(ob)
	var nats: Array = G.NATS.keys(); nats.sort()
	for i in nats.size():
		ob.add_item(nats[i])
		if nats[i] == CR.nat: ob.select(i)
	ob.item_selected.connect(func(i): CR.nat = nats[i])
	var pop := ob.get_popup(); pop.add_theme_font_override("font", UI.font(false, 600)); pop.add_theme_font_size_override("font_size", 32)
	c1.add_child(ob); row.add_child(c1)
	var c2 := UI.vbox(10); c2.custom_minimum_size = Vector2(220, 0)
	c2.add_child(UI.lbl("Forma numarası", 26, UI.CHALK2, false, 600))
	var ne := LineEdit.new(); ne.text = str(CR.num); ne.max_length = 2; ne.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	_style_input(ne)
	ne.text_changed.connect(func(t): CR.num = clamp(int(t) if t.is_valid_int() else 10, 1, 99); _kitprev.set_data(CR.n if CR.n != "" else "Oyuncu", CR.num, UI.CHALK, 0))
	c2.add_child(ne); row.add_child(c2)
	v.add_child(row)
	v.add_child(UI.lbl("Mevki", 26, UI.CHALK2, false, 600))
	var gr := GridContainer.new(); gr.columns = 2; gr.add_theme_constant_override("h_separation", 18); gr.add_theme_constant_override("v_separation", 18)
	for k in G.POS_ORDER:
		var on: bool = CR.pos == k
		var kk: String = k
		var b := UI.btn(G.POS[k].n, "out", func(): CR.pos = kk; show_create(), G.POS[k].d, 44, false, true)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		if on:
			b.kind = "chalk"
		gr.add_child(b)
	v.add_child(gr)
	v.add_child(UI.spacer(10))
	v.add_child(UI.btn("Sözleşmeyi imzala", "pri", func():
		var nm: String = CR.n.strip_edges()
		if nm.length() < 2: toast("Önce formanın arkasına yazılacak ismi gir"); return
		G.new_game(nm, CR.nat, CR.pos, CR.num); render(); _welcome(), "", 54))
	var hf := G.hof()
	if not hf.is_empty():
		v.add_child(UI.spacer(20)); v.add_child(UI.rule())
		v.add_child(UI.lbl("Efsaneler salonu", 52, UI.CHALK, true, 800))
		for x in hf.slice(0, 8): v.add_child(UI.kv("%s, %s" % [x.n, x.pos], x.t))
	content.add_child(UI.margin(v, 32, 40, 32, 60))
	scroll.scroll_vertical = 0

func _style_input(c: Control) -> void:
	var s := UI.sb(Color(1, 1, 1, .06), 18, 2, Color(1, 1, 1, .18), Vector4(22, 18, 22, 18))
	var f := s.duplicate(); f.border_color = UI.ACC
	c.add_theme_stylebox_override("normal", s); c.add_theme_stylebox_override("focus", f)
	c.add_theme_stylebox_override("hover", s); c.add_theme_stylebox_override("pressed", s)
	c.add_theme_font_override("font", UI.font(false, 600)); c.add_theme_font_size_override("font_size", 34)
	c.add_theme_color_override("font_color", UI.CHALK); c.add_theme_color_override("font_placeholder_color", Color(UI.CHALK2, .6))
	c.add_theme_color_override("font_hover_color", UI.CHALK); c.add_theme_color_override("font_pressed_color", UI.CHALK); c.add_theme_color_override("font_focus_color", UI.CHALK)
	c.custom_minimum_size = Vector2(0, 92)

func _welcome() -> void:
	var t := G.my_team()
	var v := open_sheet(true)
	sheet_title(v, "Hoş geldin, " + G.S.p.name, "17 yaşındasın ve %s formasını giyiyorsun (%s). Hedef: dünyanın en iyisi olmak." % [t.name, G.TIERS[3].n])
	v.add_child(UI.lbl("Her hafta üç eylem hakkın var: antrenman, dinlenme, sosyal etkinlik.\nMaçlarda kritik anlarda kontrol sende: kaydırarak şut, zamanlamalı pas, çalım ve müdahale.\nGelişim puanlarını özelliklerine harca, para kazan, kendine yatırım yap.\nHocanla, takım arkadaşlarınla ve taraftarla ilişkini iyi tut.", 29, UI.INK2))
	v.add_child(UI.btn("Hadi başlayalım", "pri", func(): close_sheet(), "", 44, true))
