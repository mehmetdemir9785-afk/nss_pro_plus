extends Control
## Canlı saha: kuşbakışı 22 oyuncu, top fiziği, kaleci ve oyuncu kontrolü.
## Takım 0 (sen) yukarı, y=0 kalesine hücum eder. Takım 1 aşağı, y=105'e.
signal finished(res: Dictionary)

const PW := 68.0
const PL := 105.0
const GHW := 3.66
const GH := 2.44
const SEQ_MAX := 22.0

class Ag:
	var team := 0
	var role := "MF"
	var gk := false
	var base := Vector2()
	var pos := Vector2()
	var vel := Vector2()
	var tgt := Vector2()
	var spd := 7.0
	var pas := 50.0
	var sut := 50.0
	var drip := 50.0
	var sav := 50.0
	var user := false
	var num := 0
	var stun := 0.0
	var tk_cd := 0.0
	var run := false

var cfg := {}
var ag: Array = []
var user_ag = null
var bpos := Vector2(34, 60)
var bz := 0.0
var bvel := Vector2()
var bvz := 0.0
var bcurve := 0.0
var carrier = null
var poss := 0
var intended = null
var last_passer = null
var last_touch_team := 0
var shot = null
var t := 0.0
var dec_t := 0.0
var forced_at := 1.5
var forced_done := false
var state := "play"     # play | end | replay
var end_t := 0.0
var res := {"goal": "", "u_goal": false, "u_assist": false, "rd": 0.0, "txt": "", "u_shot": "", "u_touch": false}
var msg := ""
var msg_col := Color.WHITE
var msg_until := 0.0
var u_target = null
var u_drag := []
var u_hint := ""
var frames: Array = []
var rp_i := 0.0
var started := false
var headless := false
var ks := [0.5, 0.5]
var cols := [Color.WHITE, Color.BLACK]
var gk_cols := [Color("F2C230"), Color("38BDF8")]
var sc := 9.0
var org := Vector2.ZERO
var cam := Vector2(34, 52.5)
var view := Vector2(46, 70)
var area := Rect2()
var top_l: Label
var hint_l: Label
var fd: Font
var fb: Font

func setup(c: Dictionary) -> void:
	cfg = c
	ag = []; frames = []; u_drag = []; user_ag = null; carrier = null; shot = null; intended = null; last_passer = null
	res = {"goal": "", "u_goal": false, "u_assist": false, "rd": 0.0, "txt": "", "u_shot": "", "u_touch": false}
	state = "play"; t = 0.0
	var me_s: float = c.me.str; var op_s: float = c.op.str
	ks = [clamp(.3 + (me_s - 40) / 50.0 * .5, .28, .86), clamp(.3 + (op_s - 40) / 50.0 * .5, .28, .86)]
	cols = [Color(c.me.col), Color(c.op.col)]
	if _too_close(cols[0], cols[1]): cols[1] = Color("F8FAFC") if UI.lum(cols[0]) < .5 else Color("111827")
	var F0 := [["GK", 34, 101.5], ["DF", 10, 86], ["DF", 26, 89], ["DF", 42, 89], ["DF", 58, 86], ["MF", 10, 69], ["MF", 26, 72], ["MF", 42, 72], ["MF", 58, 69], ["FW", 27, 56], ["FW", 41, 56]]
	var nums := [1, 2, 4, 5, 3, 7, 8, 6, 11, 9, 10]
	var uidx := -1
	if c.get("involve", "none") != "none" or c.get("on", false):
		match c.get("upos", "FV"):
			"FV": uidx = 9
			"KN": uidx = 8
			"OS": uidx = 6
			"DF": uidx = 2
	for team in 2:
		var s: float = me_s if team == 0 else op_s
		for i in F0.size():
			var a := Ag.new(); a.team = team; a.role = F0[i][0]; a.gk = a.role == "GK"
			var bp := Vector2(F0[i][1], F0[i][2])
			if team == 1: bp = Vector2(PW - bp.x, PL - bp.y)
			a.base = bp; a.pos = bp; a.tgt = bp; a.num = nums[i]
			var v := s + randf_range(-6, 6)
			a.pas = v; a.sut = v + (6 if a.role == "FW" else (-8 if a.role == "DF" else 0)); a.drip = v + (4 if a.role != "DF" else -6); a.sav = v + (8 if a.role == "DF" else (-10 if a.role == "FW" else 0))
			a.spd = 6.4 + (v - 40) / 50.0 * 2.0
			if team == 0 and i == uidx:
				a.user = true; user_ag = a; a.num = c.get("unum", 10)
				var us: Dictionary = c.get("ustats", {})
				a.pas = us.get("pas", v); a.sut = us.get("sut", v); a.drip = us.get("drip", v); a.sav = us.get("sav", v)
				a.spd = 6.2 + (us.get("hiz", v) - 40) / 50.0 * 2.4
			ag.append(a)
	poss = 0 if c.get("attack", 0) == 0 else 1
	_kickoff()

func _too_close(a: Color, b: Color) -> bool:
	return abs(a.h - b.h) < .08 and abs(UI.lum(a) - UI.lum(b)) < .25 or abs(UI.lum(a) - UI.lum(b)) < .12 and a.s < .3 and b.s < .3

func _kickoff() -> void:
	# hücum eden takımın orta sahasından başla
	var f := _fwd(poss)
	var startY := 52.5 + f * randf_range(10, 22)
	var cands := []
	for a in ag:
		if a.team == poss and a.role == "MF" and not a.user: cands.append(a)
	var c = cands[randi() % cands.size()]
	if cfg.get("involve", "") == "attack" and user_ag != null:
		var best = c; var bd := 1e9
		for a in cands:
			var d: float = a.base.distance_to(user_ag.base)
			if d < bd: bd = d; best = a
		c = best
	var sx: float = clamp(c.base.x + randf_range(-6, 6), 8, 60)
	for a in ag:
		var off: float = (startY - 52.5) * .6
		a.pos = a.base + Vector2(0, off) + Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
		if a.gk: a.pos = a.base
	c.pos = Vector2(sx, startY)
	carrier = c; bpos = c.pos; last_touch_team = poss; cam = c.pos + Vector2(0, _fwd(poss) * 8)
	forced_at = randf_range(1.0, 2.2)

func _fwd(team: int) -> float: return -1.0 if team == 0 else 1.0
func _goal(team: int) -> Vector2: return Vector2(34, 0 if team == 0 else PL)
func _own_goal_y(team: int) -> float: return PL if team == 0 else 0.0

# ================= simülasyon =================
func step(dt: float) -> void:
	if state == "done": return
	if state == "end":
		end_t -= dt
		if end_t <= 0: _finish(); return
		_move_all(dt); _ball(dt)
		return
	t += dt
	if t > SEQ_MAX: _end("", "Atak sonuçsuz kaldı.", 0.6); return
	for a in ag:
		a.stun = max(0.0, a.stun - dt); a.tk_cd = max(0.0, a.tk_cd - dt)
	_targets()
	_move_all(dt)
	if carrier != null: _carrier(dt)
	_ball(dt)
	if not headless:
		frames.append(_snap())
		if frames.size() > 260: frames.pop_front()

func _snap() -> Array:
	var p := PackedVector2Array()
	for a in ag: p.append(a.pos)
	return [p, bpos, bz]

func _targets() -> void:
	var b := bpos
	var att_team := poss if carrier != null else last_touch_team
	var press := _nearest_n(1 - att_team, b, 2) if carrier != null else []
	var chase := []
	if carrier == null and shot == null:
		chase = [_nearest_team(0, b), _nearest_team(1, b)]
	for a in ag:
		if a == carrier: continue
		var tg: Vector2 = a.base
		if a.gk:
			if shot != null and shot.team != a.team: continue
			var gy := _own_goal_y(a.team)
			tg = Vector2(34 + (b.x - 34) * .14, gy - _fwd(a.team) * -1.5)
			if shot == null and b.distance_to(Vector2(34, gy)) < 14 and carrier != null and carrier.team != a.team:
				tg = Vector2(34, gy).lerp(b, .25)
			a.tgt = tg; continue
		var att: bool = a.team == att_team
		tg.y += (b.y - 52.5) * .62
		tg.x += (b.x - 34) * .22
		tg.y += _fwd(a.team) * (8.0 if att else -3.0)
		if att and a.role == "FW" and carrier != null and carrier != a:
			tg.y += _fwd(a.team) * 6
			if a.run: tg.x += (34 - tg.x) * .35
		if press.has(a):
			var i := press.find(a)
			tg = carrier.pos if i == 0 else carrier.pos.lerp(Vector2(34, _own_goal_y(a.team)), .25)
		if chase.has(a) and carrier == null:
			tg = b + bvel * .35
		if intended == a and carrier == null:
			tg = b + bvel * .3
		if a.user and u_target != null and (cfg.get("involve", "") == "defend") and not cfg.get("auto", false):
			tg = u_target
		tg.x = clamp(tg.x, 1, PW - 1); tg.y = clamp(tg.y, 1, PL - 1)
		a.tgt = tg

func _nearest_n(team: int, p: Vector2, n: int) -> Array:
	var l := []
	for a in ag:
		if a.team == team and not a.gk and a.stun <= 0: l.append(a)
	l.sort_custom(func(x, y): return x.pos.distance_squared_to(p) < y.pos.distance_squared_to(p))
	return l.slice(0, n)
func _nearest_team(team: int, p: Vector2):
	var best = null; var bd := 1e9
	for a in ag:
		if a.team != team or a.stun > 0: continue
		var d: float = a.pos.distance_squared_to(p)
		if d < bd: bd = d; best = a
	return best

func _move_all(dt: float) -> void:
	for a in ag:
		if a.stun > 0:
			a.vel = a.vel.lerp(Vector2.ZERO, dt * 5); a.pos += a.vel * dt; continue
		var d: Vector2 = a.tgt - a.pos
		var mx: float = a.spd * (.86 if a == carrier else 1.0)
		var want: Vector2 = d.normalized() * min(mx, d.length() * 2.2) if d.length() > .05 else Vector2.ZERO
		a.vel = a.vel.lerp(want, clamp(dt * 5, 0, 1))
		a.pos += a.vel * dt
		a.pos.x = clamp(a.pos.x, -2, PW + 2); a.pos.y = clamp(a.pos.y, -2, PL + 2)
	# basit çarpışma
	for i in ag.size():
		for j in range(i + 1, ag.size()):
			var a: Ag = ag[i]; var b: Ag = ag[j]
			var d := b.pos - a.pos; var l := d.length()
			if l < 1.6 and l > .001:
				var push := d / l * (1.6 - l) * .5
				a.pos -= push; b.pos += push

func _carrier(dt: float) -> void:
	var c: Ag = carrier
	bpos = c.pos + (c.vel.normalized() * .7 if c.vel.length() > .3 else Vector2(0, _fwd(c.team) * .6)); bz = 0
	# kullanıcı kontrolündeyse
	if c.user and _user_ctrl():
		if u_target != null:
			c.tgt = u_target
			if c.pos.distance_to(u_target) < 1.2: u_target = null
		else: c.tgt = c.pos
		_tackles(c); return
	# zorunlu pas: kullanıcıyı oyuna sok
	if cfg.get("involve", "") == "attack" and not forced_done and c.team == 0 and not c.user and t > forced_at and user_ag != null:
		forced_done = true; _pass(c, user_ag); return
	var g := _goal(c.team)
	var dir := (g - c.pos).normalized()
	var pr := _pressure(c)
	if cfg.get("involve", "") == "attack" and not forced_done and c.team == 0 and not c.user and user_ag != null:
		c.tgt = c.pos + dir * 3
		if pr != Vector2.ZERO and pr.length() < 2.5 and t > .5: forced_done = true; _pass(c, user_ag); return
		_tackles(c); return
	c.tgt = c.pos + dir * 6
	if pr != Vector2.ZERO and pr.length() < 4:
		c.tgt = c.pos + (dir * .8 - pr.normalized() * .6 + Vector2(dir.y, -dir.x) * (1 if randf() < .5 else -1) * .3).normalized() * 6
	dec_t -= dt
	if dec_t <= 0:
		dec_t = .28
		if c.user and cfg.get("involve", "") == "attack" and not cfg.get("auto", false): return
		var dg := c.pos.distance_to(g)
		var pl := pr.length() if pr != Vector2.ZERO else 99.0
		var ang: float = abs(c.pos.x - 34) / max(1.0, abs(c.pos.y - g.y))
		if dg < 25 and ang < 1.3 and (pl < 3.5 or dg < 17 or randf() < .22):
			_shoot(c, Vector2(34 + (1 if randf() < .5 else -1) * randf_range(1.2, 3.3), g.y), randf_range(.2, 2.1), randf_range(21, 29), 0.0); return
		var bm = null; var bs := -9.0
		for m in ag:
			if m.team != c.team or m == c or m.gk: continue
			var s := _pass_score(c, m)
			if s > bs: bs = s; bm = m
		if bm != null and ((pl < 3.2 and bs > .7) or bs > 1.7 or (randf() < .08 and bs > 1.1)):
			_pass(c, bm); return
	_tackles(c)

func _pressure(c: Ag) -> Vector2:
	var best := Vector2.ZERO; var bd := 1e9
	for a in ag:
		if a.team == c.team or a.stun > 0: continue
		var d: Vector2 = a.pos - c.pos
		if d.length() < bd: bd = d.length(); best = d
	return best

func _pass_score(c: Ag, m: Ag) -> float:
	var g := _goal(c.team)
	var prog := c.pos.distance_to(g) - m.pos.distance_to(g)
	var lane := 99.0; var open := 99.0
	for o in ag:
		if o.team == c.team: continue
		lane = min(lane, _seg_dist(o.pos, c.pos, m.pos)); open = min(open, o.pos.distance_to(m.pos))
	var dist := c.pos.distance_to(m.pos)
	return prog * .07 + clamp((lane - 1.0) / 4.0, 0, 1) * 1.2 + clamp((open - 1.5) / 5.0, 0, 1) * .9 - dist * .012 + (.5 if m.user and cfg.get("involve", "") == "attack" else 0.0)

func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a; var l2 := ab.length_squared()
	if l2 < .001: return p.distance_to(a)
	var tt: float = clamp((p - a).dot(ab) / l2, 0, 1)
	return p.distance_to(a + ab * tt)

func _tackles(c: Ag) -> void:
	for a in ag:
		if a.team == c.team or a.stun > 0 or a.tk_cd > 0 or a.gk: continue
		if a.user and cfg.get("involve", "") == "defend" and not cfg.get("auto", false): continue
		if a.pos.distance_to(c.pos) < 1.4:
			a.tk_cd = .85
			var p: float = clamp(.13 + (a.sav - c.drip) / 250.0, .05, .32)
			if c.user and _user_ctrl(): p *= 1.15
			if randf() < p:
				c.stun = .6
				if c.user: res.rd -= .15; _msg("Top kaptırıldı", UI.RED)
				_take(a); return

func _take(a: Ag) -> void:
	var prev := poss
	carrier = a; intended = null; shot = null; poss = a.team; last_touch_team = a.team; dec_t = .35
	if a.team != prev:
		var inv: String = cfg.get("involve", "none")
		if inv == "defend" and a.team == 0:
			_end("", "Tehlike savuşturuldu.", 1.0)
		elif inv != "defend" or a.team == 1:
			if cfg.get("attack", 0) != a.team: _end("", "Top rakibe geçti.", 1.0)

func _pass(c: Ag, m: Ag, to_point = null) -> void:
	var tp: Vector2 = m.pos + m.vel * .55 if to_point == null else to_point
	var d: float = c.pos.distance_to(tp)
	var dir := (tp - c.pos).normalized().rotated(randfn(0, (100 - c.pas) / 100.0 * (.04 if m != null and m.user else .09)))
	var lane := 99.0
	for o in ag:
		if o.team != c.team: lane = min(lane, _seg_dist(o.pos, c.pos, tp))
	var sp: float = clamp(5 + d * .62, 8, 28)
	bvz = 0.0
	if lane < 2.2 and d > 13:
		bvz = 5.5 + d * .1; sp *= .78
	bvel = dir * sp; bpos = c.pos + dir * .8; bz = 0.02 if bvz == 0 else .2
	if c.user: res.rd += .08
	last_passer = c; intended = m; carrier = null; last_touch_team = c.team; bcurve = 0
	if not headless: Sfx.play("kick")
	if m != null: m.run = true

func _shoot(c: Ag, aim: Vector2, az: float, sp: float, curve: float) -> void:
	var err := (100 - c.sut) / 100.0
	aim.x += randfn(0, err * 2.0); az = max(0.0, az + randfn(0, err * .8))
	var d := c.pos.distance_to(aim)
	var dir := (aim - c.pos).normalized()
	sp *= .88 + c.sut / 450.0
	var tt := d / sp
	bvel = dir * sp; bvz = (az - .1 + .5 * 9.8 * tt * tt) / tt; bz = .1; bpos = c.pos + dir * .8
	bcurve = curve
	shot = {"by": c, "team": c.team, "sp": sp, "t0": t, "saved": false}
	last_passer = last_passer if last_passer != c else null
	carrier = null; intended = null; last_touch_team = c.team
	if not headless: Sfx.play("kick")

func _ball(dt: float) -> void:
	if carrier != null: return
	var prev := bpos
	if bcurve != 0 and bvel.length() > 4:
		bvel += Vector2(-bvel.y, bvel.x).normalized() * bcurve * dt; bcurve *= exp(-1.2 * dt)
	bpos += bvel * dt
	if bz > 0 or bvz != 0:
		bz += bvz * dt; bvz -= 9.8 * dt
		if bz <= 0:
			bz = 0
			if abs(bvz) > 2: bvz = -bvz * .42
			else: bvz = 0
		bvel *= exp(-.08 * dt)
	else:
		bvel *= exp(-(.25 if shot != null else .55) * dt)
	if state != "play": return
	# kaleci kurtarışı
	if shot != null and not shot.saved:
		var dteam: int = 1 - shot.team
		var k: Ag = ag[0] if dteam == 0 else ag[11]
		var line_y := _own_goal_y(dteam) - _fwd(dteam) * -1.0
		var crossed := (prev.y - line_y) * (bpos.y - line_y) <= 0
		# kaleci topa doğru kayar
		if t - shot.t0 > .16:
			var tt: float = abs((line_y - bpos.y) / bvel.y) if abs(bvel.y) > .1 else 0.0
			var px: float = bpos.x + bvel.x * tt
			k.tgt = Vector2(clamp(px, 34 - 4.5, 34 + 4.5), line_y)
			k.spd = 5.5 + ks[dteam] * 3
		if crossed:
			var dx: float = abs(bpos.x - k.pos.x)
			var reach: float = .75 + ks[dteam] * 1.25
			var zok := bz < 2.6
			if dx < reach and zok:
				var sdiff: float = (float(cfg.op.str if dteam == 1 else cfg.me.str) - float(cfg.me.str if dteam == 1 else cfg.op.str)) / 160.0
				var p: float = clamp(.98 - dx / reach * .6 - (shot.sp - 20) / 28.0 + (ks[dteam] - .5) * .3 + sdiff, .1, .93)
				if randf() < p:
					shot.saved = true
					bvel = Vector2(randf_range(-1, 1) * 9, -_fwd(shot.team) * randf_range(3, 8)); bvz = 3; bz = .5
					if shot.by.user: res.u_shot = "save"
					_end("", "Kaleci kurtardı.", 1.1); _msg("Kurtarış", UI.RED)
					if not headless: Sfx.play("save")
					return
	# kale çizgisi / taç
	if bpos.y < 0 or bpos.y > PL:
		var team_scoring := 0 if bpos.y < 0 else 1
		if abs(bpos.x - 34) < GHW and bz < GH:
			_scored(team_scoring); return
		if abs(abs(bpos.x - 34) - GHW) < .25 and bz < GH + .2:
			if shot != null and shot.by.user: res.u_shot = "post"
			_end("", "Top direkten döndü.", 1.0); _msg("Direk", UI.YEL); return
		if shot != null and shot.by.user: res.u_shot = "miss"
		_end("", "Top auta çıktı." if shot != null else "Top oyun alanını terk etti.", .8); return
	if bpos.x < 0 or bpos.x > PW:
		_end("", "Top taça çıktı.", .7); return
	# top kontrolü
	if bz < 1.7 and (shot == null or shot.saved == false and bpos.distance_to(_goal(shot.team)) > 6):
		var spd := bvel.length()
		for a in ag:
			if a.stun > 0: continue
			var d: float = a.pos.distance_to(bpos)
			if a == intended and d < 1.5:
				_receive(a); return
			if d < 1.05:
				if shot != null and a.team == shot.team: continue
				if a.team == last_touch_team and spd < 14 and (intended == null or spd < 3):
					_receive(a); return
				if a.team != last_touch_team:
					var p: float = (.16 if spd < 10 else .035) * (a.sav / 60.0) * (.35 if intended != null and intended.user else 1.0)
					if a.gk: p = .9
					if randf() < p:
						if last_passer != null and last_passer.user: res.rd -= .15; _msg("Pas kesildi", UI.RED)
						_receive(a); return
	if shot == null and carrier == null and bvel.length() < .6 and bz == 0:
		var n = _nearest_team(last_touch_team, bpos)
		if n != null and n.pos.distance_to(bpos) < 1.6: _receive(n)

func _receive(a: Ag) -> void:
	if a.user: res.u_touch = true
	if shot != null and a.gk and a.team != shot.team:
		if shot.by.user: res.u_shot = "save"
		_end("", "Kaleci topu kontrol etti.", .9); _msg("Kurtarış", UI.RED); return
	_take(a)
	a.run = false
	if a.user and _user_ctrl(): _msg("Top sende", UI.YEL)

func _scored(team: int) -> void:
	if state != "play": return
	var by = shot.by if shot != null else null
	res.goal = "me" if team == 0 else "op"
	var txt := ""
	if team == 0:
		if by != null and by.user:
			res.u_goal = true; res.rd += 1.2; txt = "%s golü attı." % cfg.get("uname", "Sen")
		else:
			txt = "Takım arkadaşın topu ağlara gönderdi."
			if last_passer != null and last_passer.user: res.u_assist = true; res.rd += .9; txt += " Asist senden."
	else:
		txt = "Rakip golü buldu."
		if cfg.get("involve", "") == "defend": res.rd -= .3
	if by != null and by.user: res.u_shot = "goal"
	_msg("GOL", UI.YEL)
	if not headless: Sfx.play("goal"); Input.vibrate_handheld(90)
	_end(res.goal, txt, 1.4)
	if not headless and frames.size() > 30: state = "replay_wait"

func _end(goal: String, txt: String, delay: float) -> void:
	if state != "play": return
	res.txt = txt; state = "end"; end_t = delay
	carrier = null if carrier == null else carrier

func _finish() -> void:
	if state == "done": return
	state = "done"
	finished.emit(res)
	if not headless: queue_free()

func _user_ctrl() -> bool:
	return user_ag != null and not cfg.get("auto", false) and cfg.get("involve", "") == "attack"

## Hızlı mod: görsel olmadan sonuna kadar çalıştır.
func simulate() -> Dictionary:
	headless = true
	var guard := 0
	while state != "done" and guard < 4000:
		step(1.0 / 30.0); guard += 1
		if state == "replay_wait": state = "end"
	if state != "done": _finish()
	return res

# ================= görsel ve giriş =================
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	fd = UI.font(true, 900); fb = UI.font(false, 700)
	top_l = UI.lbl("", 30, UI.CHALK, true, 800, HORIZONTAL_ALIGNMENT_CENTER); add_child(top_l)
	top_l.set_anchors_and_offsets_preset(PRESET_TOP_WIDE); top_l.offset_top = 16; top_l.offset_left = 20; top_l.offset_right = -20
	top_l.text = cfg.get("title", "")
	hint_l = UI.lbl("", 25, UI.CHALK2, false, 600, HORIZONTAL_ALIGNMENT_CENTER); add_child(hint_l)
	hint_l.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE); hint_l.offset_top = -140; hint_l.offset_bottom = -14; hint_l.offset_left = 30; hint_l.offset_right = -30
	var skip := UI.btn("Geç", "out", func(): _skip(), "", 28)
	add_child(skip); skip.set_anchors_and_offsets_preset(PRESET_TOP_RIGHT); skip.offset_left = -150; skip.offset_right = -16; skip.offset_top = 62; skip.offset_bottom = 132
	started = true

func _skip() -> void:
	if state == "replay": _finish(); return
	if _user_ctrl() and carrier == user_ag: return
	cfg.auto = true
	simulate()
	queue_free()

func _process(delta: float) -> void:
	if not started or state == "done": return
	var spd := 1.0
	var inv: String = cfg.get("involve", "none")
	if inv == "none": spd = 1.6
	if _user_ctrl() and carrier == user_ag: spd = .3
	if inv == "defend" and carrier != null and carrier.team == 1 and carrier.pos.y > 62: spd = .55
	if state == "replay_wait":
		end_t -= delta
		if end_t <= .6: state = "replay"; rp_i = max(0.0, frames.size() - 150.0); _msg("Tekrar", UI.CHALK, 9)
	elif state == "replay":
		rp_i += delta * 60 * .5
		if rp_i >= frames.size() - 1: _finish(); return
	else:
		var dt: float = delta * spd / max(.0001, G.speed) if G.speed < 1 else delta * spd
		var n := int(ceil(dt / (1.0 / 60.0)))
		for i in min(n, 40):
			if state == "done": break
			step(dt / n)
	var focus := bpos
	if state == "replay" and not frames.is_empty(): focus = frames[int(clamp(rp_i, 0, frames.size() - 1))][1]
	if _user_ctrl() and carrier == user_ag and u_drag.size() > 1: focus = bpos.lerp(_P(u_drag[u_drag.size() - 1][0]), .35)
	cam = cam.lerp(focus, clamp(delta * 3.0, 0, 1))
	_update_hint()
	queue_redraw()

func _update_hint() -> void:
	var inv: String = cfg.get("involve", "none")
	var h := ""
	if _user_ctrl():
		if carrier == user_ag: h = "Takım arkadaşının üstüne sürükle: pas. Kalenin içine sürükle: şut. Boş yere dokun: topla koş."
		elif user_ag != null: h = "Sarı halkalı oyuncu sensin. Top sana gelecek."
	elif inv == "defend" and not cfg.get("auto", false):
		var c = carrier
		if c != null and c.team == 1 and user_ag.pos.distance_to(c.pos) < 2.6: h = "Şimdi rakibe dokun: kay!"
		else: h = "Dokunduğun yere koşarsın. Rakibe yaklaşınca üstüne dokunup kay."
	hint_l.text = h

func _layout() -> void:
	area = Rect2(12, 140, size.x - 24, size.y - 140 - 150)
	sc = area.size.x / 46.0
	view = area.size / sc
	var c := cam
	c.x = clamp(c.x, view.x / 2 - 3, PW + 3 - view.x / 2)
	c.y = clamp(c.y, view.y / 2 - 6, PL + 6 - view.y / 2)
	cam = c
	org = area.position + area.size / 2 - cam * sc
func _S(p: Vector2) -> Vector2: return org + p * sc
func _P(s: Vector2) -> Vector2: return (s - org) / sc

func _gui_input(e: InputEvent) -> void:
	if state != "play":
		if state == "replay" and e is InputEventMouseButton and e.pressed: _finish()
		return
	var inv: String = cfg.get("involve", "none")
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			u_drag = [[e.position, Time.get_ticks_msec()]]
		else:
			if u_drag.is_empty(): return
			u_drag.append([e.position, Time.get_ticks_msec()])
			var a: Vector2 = u_drag[0][0]; var b: Vector2 = e.position
			var ln := a.distance_to(b)
			if inv == "defend" and not cfg.get("auto", false):
				_defend_tap(_P(b))
			elif _user_ctrl() and carrier == user_ag:
				if ln < 22: u_target = _P(b)
				else: _user_release(_P(b), ln, max(30.0, u_drag[u_drag.size() - 1][1] - u_drag[0][1]))
			u_drag = []
	elif e is InputEventMouseMotion and not u_drag.is_empty():
		u_drag.append([e.position, Time.get_ticks_msec()])
		if u_drag.size() > 60: u_drag.remove_at(1)

func _defend_tap(p: Vector2) -> void:
	var c = carrier
	if c != null and c.team == 1 and p.distance_to(c.pos) < 4.5 and user_ag.pos.distance_to(c.pos) < 2.6 and user_ag.stun <= 0:
		var d: float = user_ag.pos.distance_to(c.pos)
		var pr: float = clamp(.42 + (user_ag.sav - c.drip) / 150.0 - max(0.0, d - 1.2) * .22, .1, .85)
		user_ag.tk_cd = .6
		if randf() < pr:
			res.rd += .35; _msg("Temiz müdahale", UI.YEL); c.stun = .8; _take(user_ag)
			if state != "end": _end("", "Kayarak topu temiz aldın.", .9)
		else:
			user_ag.stun = 1.0; res.rd -= .1; _msg("Kaçırdın", UI.RED)
		return
	u_target = p

func _user_release(p: Vector2, ln_px: float, dur_ms: float) -> void:
	var c: Ag = user_ag
	# kale içine bırakıldıysa şut
	var gy := 0.0
	var in_goal_zone: bool = p.y < 7.5 and abs(p.x - 34) < 14
	var mate = null; var md := 6.0
	for m in ag:
		if m.team != 0 or m == c or m.gk: continue
		var d: float = m.pos.distance_to(p)
		if d < md: md = d; mate = m
	if in_goal_zone:
		var dir := (p - c.pos).normalized()
		if dir.y >= -.05: dir.y = -.2; dir = dir.normalized()
		var tt := (c.pos.y - gy) / (-dir.y)
		var hit_x := c.pos.x + dir.x * tt
		var dev := 0.0
		var a0: Vector2 = u_drag[0][0]; var a1: Vector2 = u_drag[u_drag.size() - 1][0]
		var ch := a1 - a0
		for q in u_drag:
			var dd: float = (ch.x * (q[0].y - a0.y) - ch.y * (q[0].x - a0.x)) / max(1.0, ch.length())
			if abs(dd) > abs(dev): dev = dd
		var curve: float = clamp(-dev / max(1.0, ch.length()) * 22.0, -10, 10)
		var spd: float = clamp(16 + ln_px / dur_ms * 9.0, 16, 32)
		var az: float = clamp((2.0 - p.y) / 4.0 * 2.4, 0.05, 3.4)
		_shoot(c, Vector2(hit_x, gy), az, spd, curve)
		res.u_shot = "shot"
		return
	if mate != null: _pass(c, mate); return
	# boşluğa pas: en yakın takım arkadaşı koşsun
	var near = null; var nd := 1e9
	for m in ag:
		if m.team != 0 or m == c or m.gk: continue
		var d: float = m.pos.distance_to(p)
		if d < nd: nd = d; near = m
	_pass(c, near, p)

func _msg(t: String, col: Color, dur: float = 1.2) -> void:
	msg = t; msg_col = col; msg_until = Time.get_ticks_msec() / 1000.0 + dur

func _draw() -> void:
	_layout()
	draw_rect(Rect2(Vector2.ZERO, size), UI.DEEP)
	var fr := Rect2(_S(Vector2(-3, -4)), Vector2(PW + 6, PL + 8) * sc)
	draw_rect(fr, Color("1a7a37"))
	for i in 14:
		var y0 := PL / 14.0 * i
		draw_rect(Rect2(_S(Vector2(0, y0)), Vector2(PW, PL / 14.0) * sc), Color("1f8a3c") if i % 2 == 0 else Color("1c7f37"))
	var W := Color(1, 1, 1, .8); var lw: float = max(2.0, sc * .18)
	draw_rect(Rect2(_S(Vector2.ZERO), Vector2(PW, PL) * sc), W, false, lw)
	draw_line(_S(Vector2(0, PL / 2)), _S(Vector2(PW, PL / 2)), W, lw)
	draw_arc(_S(Vector2(34, PL / 2)), 9.15 * sc, 0, TAU, 48, W, lw)
	draw_circle(_S(Vector2(34, PL / 2)), lw, W)
	for top in [true, false]:
		var y0 := 0.0 if top else PL; var s := 1.0 if top else -1.0
		draw_rect(Rect2(_S(Vector2(34 - 20.16, y0 if top else y0 - 16.5)), Vector2(40.32, 16.5) * sc), W, false, lw)
		draw_rect(Rect2(_S(Vector2(34 - 9.16, y0 if top else y0 - 5.5)), Vector2(18.32, 5.5) * sc), W, false, lw)
		draw_circle(_S(Vector2(34, y0 + s * 11)), lw, W)
		draw_arc(_S(Vector2(34, y0 + s * 11)), 9.15 * sc, (.2 * PI if top else 1.2 * PI), (.8 * PI if top else 1.8 * PI), 24, W, lw)
		var gr := Rect2(_S(Vector2(34 - GHW, y0 - 2.2 if top else y0)), Vector2(GHW * 2, 2.2) * sc)
		draw_rect(gr, Color(1, 1, 1, .18)); draw_rect(gr, Color.WHITE, false, lw)
	# oyuncular
	var pos_list: PackedVector2Array
	var bp := bpos; var bzz := bz
	if state == "replay" and not frames.is_empty():
		var f: Array = frames[int(clamp(rp_i, 0, frames.size() - 1))]
		pos_list = f[0]; bp = f[1]; bzz = f[2]
	else:
		pos_list = PackedVector2Array()
		for a in ag: pos_list.append(a.pos)
	var r := 1.05 * sc
	for i in ag.size():
		var a: Ag = ag[i]; var p := _S(pos_list[i])
		var col: Color = gk_cols[a.team] if a.gk else cols[a.team]
		draw_circle(p + Vector2(2, 3), r, Color(0, 0, 0, .3))
		draw_circle(p, r, col)
		draw_arc(p, r, 0, TAU, 24, col.darkened(.45), max(1.5, sc * .14), true)
		var tc := UI.INK if UI.lum(col) > .6 else Color.WHITE
		draw_string(fb, p + Vector2(-r, r * .42), str(a.num), HORIZONTAL_ALIGNMENT_CENTER, r * 2, int(r * 1.05), tc)
		if a.user:
			var pul := .5 + .5 * sin(Time.get_ticks_msec() / 160.0)
			draw_arc(p, r + 4 + pul * 3, 0, TAU, 32, UI.YEL, 4, true)
			draw_string(fd, p + Vector2(-80, -r - 12), cfg.get("uname_short", "SEN"), HORIZONTAL_ALIGNMENT_CENTER, 160, 24, UI.YEL)
		if a.stun > 0: draw_arc(p, r + 3, 0, TAU, 16, Color(1, 1, 1, .5), 2)
	# sürükleme önizlemesi
	if _user_ctrl() and carrier == user_ag and u_drag.size() > 1:
		var pl := PackedVector2Array()
		for q in u_drag: pl.append(q[0])
		draw_polyline(pl, Color(UI.YEL, .9), 5, true)
		var endp := _P(u_drag[u_drag.size() - 1][0])
		for m in ag:
			if m.team == 0 and m != user_ag and not m.gk and m.pos.distance_to(endp) < 6:
				draw_arc(_S(m.pos), r + 6, 0, TAU, 28, Color.WHITE, 3)
		if endp.y < 7.5 and abs(endp.x - 34) < 14:
			draw_rect(Rect2(_S(Vector2(34 - GHW, -2.2)), Vector2(GHW * 2, 2.2) * sc), Color(UI.YEL, .45))
	if u_target != null and state == "play":
		draw_arc(_S(u_target), 10, 0, TAU, 16, Color(1, 1, 1, .7), 3)
	# top
	var bs := _S(bp)
	draw_circle(bs + Vector2(2 + bzz * sc * .3, 2 + bzz * sc * .2), .42 * sc, Color(0, 0, 0, .35))
	var br: float = .46 * sc * (1 + bzz * .09)
	var bb := bs - Vector2(0, bzz * sc * .55)
	draw_circle(bb, br, Color.WHITE); draw_arc(bb, br, 0, TAU, 16, Color("111"), 1.5)
	draw_circle(bb + Vector2(-br * .2, -br * .2), br * .38, Color("111"))
	# alan dışını ört
	draw_rect(Rect2(0, 0, size.x, area.position.y), UI.DEEP)
	draw_rect(Rect2(0, area.end.y, size.x, size.y - area.end.y), UI.DEEP)
	draw_rect(Rect2(0, 0, area.position.x, size.y), UI.DEEP)
	draw_rect(Rect2(area.end.x, 0, size.x - area.end.x, size.y), UI.DEEP)
	draw_rect(area, UI.CHALK, false, 3)
	# radar
	var ms := 1.5; var mo := Vector2(area.position.x + 10, area.position.y + 10)
	draw_rect(Rect2(mo, Vector2(PW, PL) * ms), Color(0, 0, 0, .55))
	draw_rect(Rect2(mo, Vector2(PW, PL) * ms), Color(1, 1, 1, .5), false, 1.5)
	draw_line(mo + Vector2(0, PL / 2) * ms, mo + Vector2(PW, PL / 2) * ms, Color(1, 1, 1, .35), 1)
	var vr := Rect2(mo + (cam - view / 2) * ms, view * ms)
	draw_rect(vr, Color(1, 1, 1, .7), false, 1.5)
	for i in ag.size():
		var a: Ag = ag[i]
		var pp: Vector2 = mo + pos_list[i] * ms
		draw_circle(pp, 3.2 if a.user else 2.4, UI.YEL if a.user else (gk_cols[a.team] if a.gk else cols[a.team]))
	draw_circle(mo + bp * ms, 2.2, Color.WHITE)
	var now := Time.get_ticks_msec() / 1000.0
	if msg != "" and now < msg_until:
		var big := msg == "GOL" or msg == "Tekrar"
		var fs := 120 if msg == "GOL" else (72 if big else 46)
		var y: float = size.y * .45 if big else area.position.y + 90
		draw_string_outline(fd, Vector2(0, y), msg, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, 14, UI.INK)
		draw_string(fd, Vector2(0, y), msg, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, msg_col)
