class_name UI
## Görsel dil: biçilmiş çim, tebeşir çizgileri, sarı/kırmızı kart, kâğıt pencereler.

const GRASS := Color("0F3D2E")
const DEEP := Color("0A2A20")
const CHALK := Color("EEF1E8")
const CHALK2 := Color("A9BDB0")
const LINE := Color(0.933, 0.945, 0.91, 0.22)
const YEL := Color("F2C230")
const RED := Color("D7263D")
const PAPER := Color("EDEFE7")
const INK := Color("0B231A")
const INK2 := Color("3A5146")
const GOLDINK := Color("8A6400")

static var _fonts := {}

static func font(disp: bool, w: int) -> Font:
	var key := ("d" if disp else "b") + str(w)
	if _fonts.has(key): return _fonts[key]
	var base := "big-shoulders-display" if disp else "barlow"
	var f: FontFile = load("res://fonts/%s-latin-%d-normal.woff2" % [base, w])
	var ext: FontFile = load("res://fonts/%s-latin-ext-%d-normal.woff2" % [base, w])
	f.fallbacks = [ext]
	_fonts[key] = f
	return f

static func lbl(t: String, size: int = 30, col: Color = CHALK, disp: bool = false, w: int = 500, align := HORIZONTAL_ALIGNMENT_LEFT, wrap := true) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", font(disp, w))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if wrap: l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func sb(bg: Color, radius: int = 0, bw: int = 0, bcol := Color.TRANSPARENT, pad := Vector4(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(bw)
	s.border_color = bcol
	s.content_margin_left = pad.x; s.content_margin_top = pad.y; s.content_margin_right = pad.z; s.content_margin_bottom = pad.w
	return s

static func panel(bg: Color, radius := 0, bw := 0, bcol := Color.TRANSPARENT, pad := Vector4(0, 0, 0, 0)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sb(bg, radius, bw, bcol, pad))
	return p

static func vbox(sep: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", sep); return v
static func hbox(sep: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", sep); return h
static func spacer(h: int) -> Control:
	var c := Control.new(); c.custom_minimum_size = Vector2(0, h); c.mouse_filter = Control.MOUSE_FILTER_IGNORE; return c
static func fill() -> Control:
	var c := Control.new(); c.size_flags_horizontal = Control.SIZE_EXPAND_FILL; c.mouse_filter = Control.MOUSE_FILTER_IGNORE; return c
static func rule(col := LINE, h := 4) -> ColorRect:
	var r := ColorRect.new(); r.color = col; r.custom_minimum_size = Vector2(0, h); r.mouse_filter = Control.MOUSE_FILTER_IGNORE; return r
static func margin(c: Control, l := 32, t := 0, r := 32, b := 0) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l); m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r); m.add_theme_constant_override("margin_bottom", b)
	m.add_child(c); return m

## kind: out | pri | chalk | red ; paper: kâğıt zemin üzerinde mi
static func btn(t: String, kind: String = "out", cb: Callable = Callable(), sub: String = "", size: int = 40, paper := false, left := false) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	var bg := Color.TRANSPARENT; var fg := INK if paper else CHALK; var bd := (INK if paper else Color(CHALK, .6))
	match kind:
		"pri": bg = YEL; fg = INK; bd = INK if paper else YEL
		"chalk": bg = INK if paper else CHALK; fg = PAPER if paper else INK; bd = bg
		"red": bg = RED; fg = Color.WHITE; bd = RED
	var n := sb(bg, 8, 4, bd, Vector4(24, 18, 24, 18))
	var pr := n.duplicate(); pr.bg_color = bg.darkened(.12) if bg.a > 0 else Color(fg, .12)
	b.add_theme_stylebox_override("normal", n); b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", pr); b.add_theme_stylebox_override("focus", n)
	var dis := n.duplicate(); dis.bg_color = Color(bg, bg.a * .35); dis.border_color = Color(bd, .3)
	b.add_theme_stylebox_override("disabled", dis)
	var v := vbox(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var al := HORIZONTAL_ALIGNMENT_LEFT if (left or sub != "") else HORIZONTAL_ALIGNMENT_CENTER
	var tl := lbl(t, size, fg, true, 800, al)
	v.add_child(tl)
	if sub != "":
		v.add_child(lbl(sub, 25, Color(fg, .72), false, 500, al))
	b.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 24; v.offset_right = -24; v.offset_top = 14; v.offset_bottom = -14
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var base_h: float = (size * 1.25 + 30) + (34 if sub != "" else 0)
	b.custom_minimum_size = Vector2(0, base_h)
	if sub != "":
		b.resized.connect(func():
			if b.size.x < 80: return
			var inner := b.size.x - 48
			var hsum := 0.0
			for c in v.get_children():
				var lab := c as Label
				var f := lab.get_theme_font("font"); var fs := lab.get_theme_font_size("font_size")
				hsum += f.get_multiline_string_size(lab.text, HORIZONTAL_ALIGNMENT_LEFT, inner, fs).y
			var need: float = max(base_h, hsum + 2 + 32)
			if abs(need - b.custom_minimum_size.y) > 1: b.custom_minimum_size.y = need)
	if cb.is_valid(): b.pressed.connect(func(): Sfx.play("tap"); cb.call())
	b.set_meta("fg", fg)
	return b

static func set_disabled(b: Button, d: bool) -> void:
	b.disabled = d
	b.modulate = Color(1, 1, 1, .4) if d else Color.WHITE

static func chip(t: String, kind := "", paper := false) -> PanelContainer:
	var bg := Color.TRANSPARENT; var fg := INK if paper else CHALK; var bd := INK if paper else CHALK2
	match kind:
		"y": bg = YEL; fg = INK; bd = YEL if not paper else INK
		"r": bg = RED; fg = Color.WHITE; bd = RED
		"p": bg = INK if paper else CHALK; fg = PAPER if paper else INK; bd = bg
		"g": bd = INK if paper else CHALK
	var p := panel(bg, 6, 3, bd, Vector4(14, 4, 14, 4))
	p.add_child(lbl(t, 24, fg, false, 700, HORIZONTAL_ALIGNMENT_LEFT, false))
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

static func kv(k: String, v: String, paper := false) -> VBoxContainer:
	var w := vbox(0)
	var h := hbox(16)
	var a := lbl(k, 29, INK2 if paper else CHALK2); a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var b := lbl(v, 29, INK if paper else CHALK, false, 700, HORIZONTAL_ALIGNMENT_RIGHT); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(a); h.add_child(b)
	w.add_child(UI.margin(h, 0, 12, 0, 12)); w.add_child(rule(Color(INK, .15) if paper else LINE, 2))
	return w

static func section(title: String, small: String = "") -> VBoxContainer:
	var v := vbox(18)
	var h := hbox(16)
	var t := lbl(title, 52, CHALK, true, 800); t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	if small != "":
		var s := lbl(small, 25, CHALK2, false, 500, HORIZONTAL_ALIGNMENT_RIGHT); s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(s)
	v.add_child(h)
	return v

static func lum(c: Color) -> float: return .299 * c.r + .587 * c.g + .114 * c.b

# ================= çizim bileşenleri =================
class Bg extends Control:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), UI.GRASS)
		var y := 0.0; var i := 0
		while y < size.y:
			if i % 2 == 1: draw_rect(Rect2(0, y, size.x, 220), Color(1, 1, 1, .04))
			y += 220; i += 1

class Bar extends Control:
	var value := 0.0
	var col := UI.CHALK
	var track := Color(0.933, 0.945, 0.91, .15)
	func _init(v: float = 0, c: Color = UI.CHALK, h: int = 8) -> void:
		value = v; col = c; custom_minimum_size = Vector2(0, h); mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), track)
		draw_rect(Rect2(0, 0, size.x * clamp(value / 100.0, 0, 1), size.y), col)

class Dots extends Control:
	var n := 3
	var on := 0
	func _init(o: int, total: int = 3) -> void:
		on = o; n = total; custom_minimum_size = Vector2(total * 40, 28); mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		for i in n:
			var c := Vector2(14 + i * 40, 14)
			if i < on: draw_circle(c, 12, UI.YEL)
			else: draw_arc(c, 10, 0, TAU, 32, UI.CHALK2, 4, true)

class RBars extends Control:
	var vals: Array = []
	func _init(v: Array) -> void:
		vals = v; custom_minimum_size = Vector2(0, 112); mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if vals.is_empty(): return
		var n := vals.size(); var gap := 10.0; var w := (size.x - gap * (n - 1)) / n
		var f := UI.font(true, 800)
		for i in n:
			var x: float = vals[i]
			var h: float = clamp((x - 3) / 7.0, .15, 1) * size.y
			var c := UI.YEL if x >= 8 else (UI.CHALK if x >= 6.5 else (UI.CHALK2 if x >= 5.5 else UI.RED))
			var r := Rect2(i * (w + gap), size.y - h, w, h)
			draw_rect(r, c)
			draw_string(f, Vector2(r.position.x, size.y - 8), "%.1f" % x, HORIZONTAL_ALIGNMENT_CENTER, w, 26, UI.INK)

class Crest extends Control:
	var col := Color.GRAY
	var txt := ""
	func _init(name: String, c: Color, s: float = 1.0) -> void:
		col = c
		var parts := name.split(" ", false)
		for p in parts: txt += p.substr(0, 1)
		txt = txt.substr(0, 2).to_upper()
		custom_minimum_size = Vector2(88, 104) * s
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var w := size.x; var h := size.y
		var pts := PackedVector2Array([Vector2(w * .5, 0), Vector2(w, h * .1), Vector2(w, h * .58), Vector2(w * .5, h), Vector2(0, h * .58), Vector2(0, h * .1)])
		draw_colored_polygon(pts, col)
		var fc := UI.INK if UI.lum(col) > .62 else Color.WHITE
		draw_string(UI.font(true, 900), Vector2(0, h * .56), txt, HORIZONTAL_ALIGNMENT_CENTER, w, int(h * .36), fc)

class Jersey extends Control:
	var sur := ""
	var num := 10
	var col := Color.WHITE
	var pat := 0
	func _init(nm: String, n: int, c: Color, p: int, w: float = 300) -> void:
		set_data(nm, n, c, p)
		custom_minimum_size = Vector2(w, w * 1.1)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func set_data(nm: String, n: int, c: Color, p: int) -> void:
		var parts := nm.strip_edges().split(" ", false)
		sur = (parts[parts.size() - 1] if parts.size() > 0 else "").replace("i", "İ").to_upper()
		num = n; col = c; pat = p; queue_redraw()
	func _shirt() -> PackedVector2Array:
		var a := PackedVector2Array([Vector2(58, 14), Vector2(84, 6)])
		for i in range(1, 8):
			var t := i / 8.0
			a.append(Vector2((1 - t) * (1 - t) * 84 + 2 * (1 - t) * t * 100 + t * t * 116, (1 - t) * (1 - t) * 6 + 2 * (1 - t) * t * 18 + t * t * 6))
		a.append_array([Vector2(116, 6), Vector2(142, 14), Vector2(192, 44), Vector2(172, 92), Vector2(150, 82), Vector2(150, 214), Vector2(50, 214), Vector2(50, 82), Vector2(28, 92), Vector2(8, 44)])
		return a
	func _draw() -> void:
		var s := size.x / 200.0
		draw_set_transform(Vector2(0, 0), 0, Vector2(s, s))
		var sh := _shirt()
		var shadow := PackedVector2Array()
		for p in sh: shadow.append(p + Vector2(0, 8))
		draw_colored_polygon(shadow, Color(0, 0, 0, .22))
		draw_colored_polygon(sh, col)
		var L := UI.lum(col)
		var txt := UI.INK if L > .6 else Color.WHITE
		var stc := Color.WHITE if L > .6 else UI.INK
		var shapes := []
		if pat == 1:
			var x := 50
			while x < 150:
				shapes.append(PackedVector2Array([Vector2(x, 0), Vector2(x + 12, 0), Vector2(x + 12, 220), Vector2(x, 220)])); x += 26
		elif pat == 2:
			var y := 26
			while y < 220:
				shapes.append(PackedVector2Array([Vector2(0, y), Vector2(200, y), Vector2(200, y + 15), Vector2(0, y + 15)])); y += 38
		elif pat == 3: shapes.append(PackedVector2Array([Vector2(30, 0), Vector2(62, 0), Vector2(200, 178), Vector2(200, 214), Vector2(168, 214)]))
		elif pat == 4: shapes.append(PackedVector2Array([Vector2(100, 0), Vector2(200, 0), Vector2(200, 220), Vector2(100, 220)]))
		for shp in shapes:
			for poly in Geometry2D.intersect_polygons(sh, shp):
				if not Geometry2D.is_polygon_clockwise(poly): draw_colored_polygon(poly, txt)
		var closed := sh.duplicate(); closed.append(sh[0])
		draw_polyline(closed, Color(0, 0, 0, .4), 2.5, true)
		var collar := PackedVector2Array()
		for i in range(0, 9):
			var t := i / 8.0
			collar.append(Vector2((1 - t) * (1 - t) * 84 + 2 * (1 - t) * t * 100 + t * t * 116, (1 - t) * (1 - t) * 6 + 2 * (1 - t) * t * 18 + t * t * 6))
		draw_polyline(collar, stc, 5, true)
		var fd := UI.font(true, 800); var fn := UI.font(true, 900)
		var fs := 20 if sur.length() > 10 else (25 if sur.length() > 7 else 30)
		draw_string_outline(fd, Vector2(0, 64), sur, HORIZONTAL_ALIGNMENT_CENTER, 200, fs, 7, stc)
		draw_string(fd, Vector2(0, 64), sur, HORIZONTAL_ALIGNMENT_CENTER, 200, fs, txt)
		draw_string_outline(fn, Vector2(0, 180), str(num), HORIZONTAL_ALIGNMENT_CENTER, 200, 108, 10, stc)
		draw_string(fn, Vector2(0, 180), str(num), HORIZONTAL_ALIGNMENT_CENTER, 200, 108, txt)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
