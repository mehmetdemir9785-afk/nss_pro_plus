extends VBoxContainer
## Zamanlama çubuğu: ibre yeşil alandayken bas. Kâğıt zemin üzerinde kullanılır.
signal graded(g: String)

var zw := .15
var pz := .04
var zc := .5
var x := 0.0
var dir := 1.0
var spd := 1.3
var done := false
var bar: Control
var grade_l: Label
var go: Button

class TBar extends Control:
	var t
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color("D3D9CD"))
		draw_rect(Rect2(size.x * (t.zc - t.zw / 2), 0, size.x * t.zw, size.y), Color("2E7D4F"))
		draw_rect(Rect2(size.x * (t.zc - t.pz / 2), 0, size.x * t.pz, size.y), UI.YEL)
		draw_rect(Rect2(size.x * t.x - 4, 0, 8, size.y), UI.INK)
		draw_rect(r, UI.INK, false, 4)

func setup(title: String, desc: String, width: float, speed: float, btn_text: String = "Şimdi") -> void:
	add_theme_constant_override("separation", 16)
	zw = clamp(width, .05, .5); pz = max(.022, min(.06, zw / 3.2)); zc = randf_range(zw / 2 + .04, 1 - zw / 2 - .04)
	spd = speed
	x = 0.0 if randf() < .5 else 1.0; dir = -1.0 if x > .5 else 1.0
	add_child(UI.lbl(title, 64, UI.INK, true, 900))
	if desc != "": add_child(UI.lbl(desc, 29, UI.INK2))
	bar = TBar.new(); bar.t = self; bar.custom_minimum_size = Vector2(0, 104)
	bar.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: _go())
	add_child(bar)
	go = UI.btn(btn_text, "pri", _go, "", 52, true)
	add_child(go)
	grade_l = UI.lbl(" ", 56, UI.INK, true, 900, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(grade_l)

func _process(dt: float) -> void:
	if done: return
	dt = min(dt, .05)
	x += dir * spd * dt
	if x > 1: x = 1; dir = -1
	if x < 0: x = 0; dir = 1
	bar.queue_redraw()

func _go() -> void:
	if done: return
	done = true
	var d: float = abs(x - zc)
	var g := "perfect" if d <= pz / 2 + .004 else ("good" if d <= zw / 2 else "fail")
	grade_l.text = "Mükemmel" if g == "perfect" else ("İyi" if g == "good" else "Kaçtı")
	grade_l.add_theme_color_override("font_color", UI.GOLDINK if g == "perfect" else (Color("1F6B40") if g == "good" else Color("C21F35")))
	Sfx.play("bad" if g == "fail" else "tap")
	Input.vibrate_handheld(60 if g == "fail" else 25)
	UI.set_disabled(go, true)
	await get_tree().create_timer(.7 * G.speed).timeout
	graded.emit(g)
