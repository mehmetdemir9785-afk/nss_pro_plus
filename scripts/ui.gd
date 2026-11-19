class_name UI
## FC Mobile tarzı görsel dil: lacivert-mor zemin, cam paneller, eğik gradyan butonlar, oyuncu kartı.

const BG_TOP := Color("0B1033")
const BG_BOT := Color("1C1045")
const GRASS := Color("0B1033")
const DEEP := Color("080C28")
const CHALK := Color("FFFFFF")
const CHALK2 := Color("9CA6D9")
const LINE := Color(1, 1, 1, .10)
const ACC := Color("00E0B8")
const ACC2 := Color("3D7BFF")
const YEL := Color("FFC83D")
const RED := Color("FF3D7F")
const PAPER := Color("141A4A")
const INK := Color("FFFFFF")
const INK2 := Color("C3C9EE")
const DARK := Color("070B24")
const GOLDINK := Color("FFC83D")

const IC := {"home": 0xe88a, "train": 0xeb43, "rest": 0xe53a, "social": 0xe32c, "fun": 0xeb3e, "dev": 0xe8e5, "shop": 0xea12, "trophy": 0xea23,
	"person": 0xe7fd, "ball": 0xea2f, "bolt": 0xea0b, "smile": 0xe813, "money": 0xef63, "star": 0xe838, "settings": 0xe8b8, "play": 0xe037,
	"vol": 0xe050, "mute": 0xe04f, "copy": 0xe14d, "paste": 0xe14f, "logout": 0xe9ba, "delete": 0xe872, "fast": 0xe01f, "auto": 0xf06c,
	"check": 0xe5ca, "lock": 0xe897, "medal": 0xea3f, "premium": 0xe7af, "table": 0xf20c, "calendar": 0xebcc, "news": 0xeb81, "heart": 0xe87d,
	"group": 0xe7ef, "megaphone": 0xef49, "deal": 0xebcb, "car": 0xe531, "house": 0xea44, "diamond": 0xead5, "savings": 0xe2eb, "fire": 0xef55,
	"heal": 0xe3f3, "food": 0xe56c, "zen": 0xea78, "brain": 0xea4a, "work": 0xe8f9, "watch": 0xe334, "boat": 0xe502, "plane": 0xe539, "paid": 0xf041,
	"bag": 0xf1cc, "party": 0xea65, "family": 0xf1a2, "game": 0xea28, "chev": 0xe5cc, "close": 0xe5cd, "skip": 0xe044, "up": 0xe5d8, "down": 0xe5db, "flag": 0xe153}

static var _fonts := {}

static func font(disp: bool, w: int) -> Font:
	var key := ("d" if disp else "b") + str(w)
	if _fonts.has(key): return _fonts[key]
	var f: FontFile; var ext: FontFile
	if disp:
		var ww: int = clamp(w, 700, 900)
		f = load("res://fonts/barlow-condensed-latin-%d-italic.woff2" % ww)
		ext = load("res://fonts/barlow-condensed-latin-ext-%d-italic.woff2" % ww)
	else:
		var ww: int = clamp(w, 500, 700)
		f = load("res://fonts/barlow-latin-%d-normal.woff2" % ww)
		ext = load("res://fonts/barlow-latin-ext-%d-normal.woff2" % ww)
	f.fallbacks = [ext]
	_fonts[key] = f
	return f

static func kit(w: int = 900) -> Font:
	var key := "k" + str(w)
	if _fonts.has(key): return _fonts[key]
	var f: FontFile = load("res://fonts/big-shoulders-display-latin-%d-normal.woff2" % w)
	f.fallbacks = [load("res://fonts/big-shoulders-display-latin-ext-%d-normal.woff2" % w)]
	_fonts[key] = f
	return f

static func icon_font() -> Font:
	if not _fonts.has("ic"): _fonts["ic"] = load("res://fonts/material-icons-round.woff2")
	return _fonts["ic"]

static func icon(name: String, size: int = 40, col: Color = CHALK) -> Label:
	var l := Label.new()
	l.text = String.chr(IC.get(name, 0xe838))
	l.add_theme_font_override("font", icon_font()); l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

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
	s.anti_aliasing = true
	return s

static func panel(bg: Color, radius := 0, bw := 0, bcol := Color.TRANSPARENT, pad := Vector4(0, 0, 0, 0)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sb(bg, radius, bw, bcol, pad))
	return p

## cam panel (FC tarzı kart)
static func card(pad := Vector4(28, 26, 28, 28), tint := Color.TRANSPARENT) -> PanelContainer:
	var bg := Color(1, 1, 1, .055) if tint.a == 0 else tint
	var p := panel(bg, 26, 2, Color(1, 1, 1, .10), pad)
	var s: StyleBoxFlat = p.get_theme_stylebox("panel")
	s.shadow_color = Color(0, 0, 0, .35); s.shadow_size = 18; s.shadow_offset = Vector2(0, 8)
	return p

static func vbox(sep: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", sep); return v
static func hbox(sep: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", sep); return h
static func spacer(h: int) -> Control:
	var c := Control.new(); c.custom_minimum_size = Vector2(0, h); c.mouse_filter = Control.MOUSE_FILTER_IGNORE; return c
static func fill() -> Control:
	var c := Control.new(); c.size_flags_horizontal = Control.SIZE_EXPAND_FILL; c.mouse_filter = Control.MOUSE_FILTER_IGNORE; return c
static func rule(col := LINE, h := 2) -> ColorRect:
	var r := ColorRect.new(); r.color = col; r.custom_minimum_size = Vector2(0, h); r.mouse_filter = Control.MOUSE_FILTER_IGNORE; return r
static func margin(c: Control, l := 32, t := 0, r := 32, b := 0) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l); m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r); m.add_theme_constant_override("margin_bottom", b)
	m.add_child(c); return m

# ================= eğik gradyan buton =================
class FCBtn extends Button:
	var kind := "out"
	var skew := 16.0
	func _ready() -> void:
		pivot_offset = size / 2
		resized.connect(func(): pivot_offset = size / 2)
		button_down.connect(func(): var tw := create_tween(); tw.tween_property(self, "scale", Vector2(.96, .96), .06))
		button_up.connect(func(): var tw := create_tween(); tw.tween_property(self, "scale", Vector2.ONE, .12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	func cols() -> Array:
		match kind:
			"pri": return [Color("00E0B8"), Color("62F04E")]
			"gold": return [Color("FFD45C"), Color("FF9F1C")]
			"chalk": return [Color("3D7BFF"), Color("7A5CFF")]
			"red": return [Color("FF3D7F"), Color("FF6A3D")]
		return [Color(1, 1, 1, .07), Color(1, 1, 1, .03)]
	func _draw() -> void:
		var w := size.x; var h := size.y; var k: float = min(skew, h * .3)
		var pts := PackedVector2Array([Vector2(k, 0), Vector2(w, 0), Vector2(w - k, h), Vector2(0, h)])
		var c: Array = cols()
		if disabled: c = [Color(1, 1, 1, .05), Color(1, 1, 1, .03)]
		if kind != "out" and not disabled:
			var glow := PackedVector2Array()
			for p in pts: glow.append(p + Vector2(0, 6))
			draw_colored_polygon(glow, Color(c[1], .25))
		draw_polygon(pts, PackedColorArray([c[0], c[1], c[1], c[0]]))
		if kind == "out" or disabled:
			var cl := pts.duplicate(); cl.append(pts[0])
			draw_polyline(cl, Color(1, 1, 1, .22 if not disabled else .08), 2.5, true)
		else:
			draw_line(Vector2(k + 6, 3), Vector2(w - 6, 3), Color(1, 1, 1, .45), 2)

## kind: out | pri | gold | chalk | red
static func btn(t: String, kind: String = "out", cb: Callable = Callable(), sub: String = "", size: int = 40, paper := false, left := false, ic: String = "") -> Button:
	var b := FCBtn.new()
	b.kind = kind
	b.focus_mode = Control.FOCUS_NONE
	var e := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus", "disabled"]: b.add_theme_stylebox_override(st, e)
	var fg := DARK if kind in ["pri", "gold"] else CHALK
	var h := hbox(16); h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ic != "": h.add_child(icon(ic, int(size * 1.15), fg))
	var v := vbox(0); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var al := HORIZONTAL_ALIGNMENT_LEFT if (left or sub != "" or ic != "") else HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lbl(t.to_upper() if sub == "" and not left else t, size, fg, true, 900 if kind != "out" else 800, al))
	if sub != "":
		v.add_child(lbl(sub, 24, Color(fg, .75), false, 500, al))
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	b.add_child(h)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 34; h.offset_right = -34; h.offset_top = 10; h.offset_bottom = -10
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var base_h: float = (size * 1.2 + 34) + (32 if sub != "" else 0)
	b.custom_minimum_size = Vector2(0, base_h)
	if sub != "":
		b.resized.connect(func():
			if b.size.x < 80: return
			var inner := b.size.x - 68 - (size * 1.3 if ic != "" else 0.0)
			var hsum := 0.0
			for c in v.get_children():
				var lab := c as Label
				hsum += lab.get_theme_font("font").get_multiline_string_size(lab.text, HORIZONTAL_ALIGNMENT_LEFT, inner, lab.get_theme_font_size("font_size")).y
			var need: float = max(base_h, hsum + 30)
			if abs(need - b.custom_minimum_size.y) > 1: b.custom_minimum_size.y = need)
	if cb.is_valid(): b.pressed.connect(func(): Sfx.play("tap"); cb.call())
	return b

static func set_disabled(b: Button, d: bool) -> void:
	b.disabled = d
	b.modulate = Color(1, 1, 1, .45) if d else Color.WHITE
	b.queue_redraw()

static func chip(t: String, kind := "", paper := false) -> PanelContainer:
	var bg := Color(1, 1, 1, .08); var fg := CHALK; var bd := Color(1, 1, 1, .16)
	match kind:
		"y": bg = YEL; fg = DARK; bd = YEL
		"r": bg = RED; fg = Color.WHITE; bd = RED
		"p": bg = ACC2; fg = Color.WHITE; bd = ACC2
		"g": bg = Color(ACC, .18); fg = ACC; bd = Color(ACC, .5)
	var p := panel(bg, 40, 2, bd, Vector4(18, 5, 18, 6))
	p.add_child(lbl(t.to_upper(), 22, fg, true, 800, HORIZONTAL_ALIGNMENT_LEFT, false))
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

static func kv(k: String, v: String, paper := false) -> VBoxContainer:
	var w := vbox(0)
	var h := hbox(16)
	var a := lbl(k, 28, CHALK2); a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var b := lbl(v, 28, CHALK, false, 700, HORIZONTAL_ALIGNMENT_RIGHT); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(a); h.add_child(b)
	w.add_child(UI.margin(h, 0, 12, 0, 12)); w.add_child(rule(LINE, 2))
	return w

static func section(title: String, small: String = "") -> VBoxContainer:
	var v := vbox(18)
	var h := hbox(16)
	var bar := ColorRect.new(); bar.color = ACC; bar.custom_minimum_size = Vector2(8, 36); bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(bar)
	var t := lbl(title.to_upper(), 40, CHALK, true, 900); t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	if small != "":
		var s := lbl(small, 24, CHALK2, false, 500, HORIZONTAL_ALIGNMENT_RIGHT); s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(s)
	v.add_child(h)
	return v

static func lum(c: Color) -> float: return .299 * c.r + .587 * c.g + .114 * c.b

# ================= çizim bileşenleri =================
class Bg extends Control:
	func _draw() -> void:
		var w := size.x; var h := size.y
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)]), PackedColorArray([UI.BG_TOP, UI.BG_TOP, UI.BG_BOT, UI.BG_BOT]))
		for i in 3:
			var x0 := w * (.15 + i * .38)
			var beam := PackedVector2Array([Vector2(x0, 0), Vector2(x0 + w * .16, 0), Vector2(x0 - w * .25, h), Vector2(x0 - w * .41, h)])
			draw_colored_polygon(beam, Color(UI.ACC2 if i % 2 == 0 else UI.ACC, .035))
		var y := 40.0
		while y < h:
			var x := fmod(y * 1.7, 64.0)
			while x < w:
				draw_circle(Vector2(x, y), 1.2, Color(1, 1, 1, .035)); x += 64
			y += 64

class Bar extends Control:
	var value := 0.0
	var col := UI.ACC
	var track := Color(1, 1, 1, .10)
	func _init(v: float = 0, c: Color = UI.ACC, h: int = 8) -> void:
		value = v; col = c; custom_minimum_size = Vector2(0, h); mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), track)
		var wv: float = size.x * clamp(value / 100.0, 0, 1)
		if wv > 1:
			draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(wv, 0), Vector2(wv, size.y), Vector2(0, size.y)]), PackedColorArray([col.darkened(.25), col, col, col.darkened(.25)]))
			draw_rect(Rect2(wv - 3, 0, 3, size.y), Color(1, 1, 1, .7))

class Dots extends Control:
	var n := 3
	var on := 0
	func _init(o: int, total: int = 3) -> void:
		on = o; n = total; custom_minimum_size = Vector2(total * 40, 28); mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		for i in n:
			var c := Vector2(14 + i * 40, 14)
			var pts := PackedVector2Array([c + Vector2(0, -12), c + Vector2(12, 0), c + Vector2(0, 12), c + Vector2(-12, 0)])
			if i < on: draw_colored_polygon(pts, UI.ACC)
			else:
				var cl := pts.duplicate(); cl.append(pts[0]); draw_polyline(cl, UI.CHALK2, 3, true)

class RBars extends Control:
	var vals: Array = []
	func _init(v: Array) -> void:
		vals = v; custom_minimum_size = Vector2(0, 76); mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if vals.is_empty(): return
		var n := vals.size(); var gap := 10.0; var w := (size.x - gap * (n - 1)) / n
		var f := UI.font(true, 900)
		for i in n:
			var x: float = vals[i]
			var c := Color("3DDC84") if x >= 8 else (UI.ACC if x >= 7 else (UI.YEL if x >= 6 else UI.RED))
			var r := Rect2(i * (w + gap), 8, w, size.y - 16)
			var k := 8.0
			draw_colored_polygon(PackedVector2Array([r.position + Vector2(k, 0), Vector2(r.end.x, r.position.y), Vector2(r.end.x - k, r.end.y), Vector2(r.position.x, r.end.y)]), c)
			draw_string(f, Vector2(r.position.x, r.end.y - 14), "%.1f" % x, HORIZONTAL_ALIGNMENT_CENTER, w, 30, UI.DARK)

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
		var glow := PackedVector2Array()
		for p in pts: glow.append((p - Vector2(w, h) / 2) * 1.12 + Vector2(w, h) / 2)
		draw_colored_polygon(glow, Color(1, 1, 1, .9))
		draw_polygon(pts, PackedColorArray([col.lightened(.25), col, col.darkened(.2), col.darkened(.35), col.darkened(.2), col]))
		var fc := UI.DARK if UI.lum(col) > .62 else Color.WHITE
		draw_string(UI.kit(900), Vector2(0, h * .56), txt, HORIZONTAL_ALIGNMENT_CENTER, w, int(h * .36), fc)

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
	static func shirt() -> PackedVector2Array:
		var a := PackedVector2Array([Vector2(58, 14), Vector2(84, 6)])
		for i in range(1, 8):
			var t := i / 8.0
			a.append(Vector2((1 - t) * (1 - t) * 84 + 2 * (1 - t) * t * 100 + t * t * 116, (1 - t) * (1 - t) * 6 + 2 * (1 - t) * t * 18 + t * t * 6))
		a.append_array([Vector2(116, 6), Vector2(142, 14), Vector2(192, 44), Vector2(172, 92), Vector2(150, 82), Vector2(150, 214), Vector2(50, 214), Vector2(50, 82), Vector2(28, 92), Vector2(8, 44)])
		return a
	func _draw() -> void:
		var s := size.x / 200.0
		draw_set_transform(Vector2(0, 0), 0, Vector2(s, s))
		var sh := shirt()
		var shadow := PackedVector2Array()
		for p in sh: shadow.append(p + Vector2(0, 8))
		draw_colored_polygon(shadow, Color(0, 0, 0, .3))
		draw_colored_polygon(sh, col)
		var L := UI.lum(col)
		var txt := UI.DARK if L > .6 else Color.WHITE
		var stc := Color.WHITE if L > .6 else UI.DARK
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
		for poly in Geometry2D.intersect_polygons(sh, PackedVector2Array([Vector2(130, 0), Vector2(200, 0), Vector2(200, 220), Vector2(150, 220)])):
			if not Geometry2D.is_polygon_clockwise(poly): draw_colored_polygon(poly, Color(0, 0, 0, .12))
		var closed := sh.duplicate(); closed.append(sh[0])
		draw_polyline(closed, Color(0, 0, 0, .45), 2.5, true)
		var collar := PackedVector2Array()
		for i in range(0, 9):
			var t := i / 8.0
			collar.append(Vector2((1 - t) * (1 - t) * 84 + 2 * (1 - t) * t * 100 + t * t * 116, (1 - t) * (1 - t) * 6 + 2 * (1 - t) * t * 18 + t * t * 6))
		draw_polyline(collar, stc, 5, true)
		var fd := UI.kit(800); var fn := UI.kit(900)
		var fs := 20 if sur.length() > 10 else (25 if sur.length() > 7 else 30)
		draw_string_outline(fd, Vector2(0, 64), sur, HORIZONTAL_ALIGNMENT_CENTER, 200, fs, 7, stc)
		draw_string(fd, Vector2(0, 64), sur, HORIZONTAL_ALIGNMENT_CENTER, 200, fs, txt)
		draw_string_outline(fn, Vector2(0, 180), str(num), HORIZONTAL_ALIGNMENT_CENTER, 200, 108, 10, stc)
		draw_string(fn, Vector2(0, 180), str(num), HORIZONTAL_ALIGNMENT_CENTER, 200, 108, txt)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

## FC tarzı oyuncu kartı
class PlayerCard extends Control:
	var d := {}
	func _init(data: Dictionary, w: float = 300) -> void:
		d = data; custom_minimum_size = Vector2(w, w * 1.42); mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _shape(w: float, h: float) -> PackedVector2Array:
		var p := PackedVector2Array()
		p.append_array([Vector2(w * .5, 0), Vector2(w * .78, h * .035), Vector2(w * .93, 0), Vector2(w, h * .06), Vector2(w, h * .86)])
		for i in range(1, 9):
			var a := i / 8.0
			p.append(Vector2(lerp(w, w * .5, a), lerp(h * .86, h, sin(a * PI / 2))))
		for i in range(1, 8):
			var a := i / 8.0
			p.append(Vector2(lerp(w * .5, 0.0, a), lerp(h, h * .86, 1 - cos(a * PI / 2))))
		p.append_array([Vector2(0, h * .86), Vector2(0, h * .06), Vector2(w * .07, 0), Vector2(w * .22, h * .035)])
		return p
	func _draw() -> void:
		var w := size.x; var h := size.y
		var o: int = d.get("ovr", 50)
		var c1: Color; var c2: Color; var tx: Color
		if o >= 85: c1 = Color("00E0B8"); c2 = Color("2B2A7A"); tx = Color.WHITE
		elif o >= 75: c1 = Color("FFE38A"); c2 = Color("C9922A"); tx = Color("2A1A00")
		elif o >= 65: c1 = Color("EEF1F6"); c2 = Color("8E97A8"); tx = Color("1A1F2B")
		else: c1 = Color("E6B48A"); c2 = Color("8A5530"); tx = Color("2A1608")
		var sh := _shape(w, h)
		var glow := PackedVector2Array()
		for p in sh: glow.append((p - Vector2(w, h) / 2) * 1.04 + Vector2(w, h) / 2 + Vector2(0, 6))
		draw_colored_polygon(glow, Color(c1, .25))
		var cols := PackedColorArray()
		for p in sh: cols.append(c1.lerp(c2, clamp(p.y / h * .9 + p.x / w * .25, 0, 1)))
		draw_polygon(sh, cols)
		for poly in Geometry2D.intersect_polygons(sh, PackedVector2Array([Vector2(w * .55, 0), Vector2(w * .7, 0), Vector2(w * .2, h), Vector2(w * .05, h)])):
			if not Geometry2D.is_polygon_clockwise(poly): draw_colored_polygon(poly, Color(1, 1, 1, .12))
		var cl := sh.duplicate(); cl.append(sh[0])
		draw_polyline(cl, Color(1, 1, 1, .55), 3, true)
		var fd := UI.font(true, 900); var fb := UI.font(false, 700)
		draw_string(fd, Vector2(w * .1, h * .17), str(o), HORIZONTAL_ALIGNMENT_LEFT, -1, int(w * .2), tx)
		draw_string(fd, Vector2(w * .1, h * .245), str(d.get("pos", "FV")), HORIZONTAL_ALIGNMENT_LEFT, -1, int(w * .085), tx)
		draw_line(Vector2(w * .1, h * .27), Vector2(w * .26, h * .27), Color(tx, .5), 2)
		draw_string(fb, Vector2(w * .1, h * .31), str(d.get("nat3", "TUR")), HORIZONTAL_ALIGNMENT_LEFT, -1, int(w * .055), tx)
		var js := w * .5
		draw_set_transform(Vector2(w * .38, h * .07), 0, Vector2(js / 200.0, js / 200.0))
		var shirt := UI.Jersey.shirt()
		var jc := Color(d.get("col", "#ffffff"))
		draw_colored_polygon(shirt, jc)
		draw_string(UI.kit(900), Vector2(0, 170), str(d.get("num", 10)), HORIZONTAL_ALIGNMENT_CENTER, 200, 100, UI.DARK if UI.lum(jc) > .6 else Color.WHITE)
		var shc := shirt.duplicate(); shc.append(shirt[0])
		draw_polyline(shc, Color(0, 0, 0, .35), 3, true)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		var ny := h * .58
		draw_string(fd, Vector2(0, ny), str(d.get("name", "")).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, w, int(w * .095), tx)
		draw_line(Vector2(w * .12, ny + h * .025), Vector2(w * .88, ny + h * .025), Color(tx, .35), 2)
		var st: Array = d.get("stats", [])
		for i in st.size():
			var col_i := i / 3; var row := i % 3
			var x := w * (.16 + col_i * .4); var y := ny + h * (.1 + row * .075)
			draw_string(fd, Vector2(x, y), str(st[i][1]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(w * .075), tx)
			draw_string(fb, Vector2(x + w * .13, y), str(st[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(w * .052), Color(tx, .85))
		draw_line(Vector2(w * .5, ny + h * .05), Vector2(w * .5, ny + h * .24), Color(tx, .3), 2)
