extends SceneTree
var Pitch
func mk():
	var P = Pitch.new()
	P.setup({"me": {"name": "A", "col": "#16a34a", "str": 60}, "op": {"name": "B", "col": "#dc2626", "str": 55}, "attack": 0, "involve": "attack", "upos": "FV", "unum": 9, "uname": "Test", "uname_short": "TEST", "auto": false, "on": true, "ustats": {"sut": 70, "pas": 65, "drip": 70, "hiz": 70, "sav": 40}, "title": "t"})
	root.add_child(P); P.size = Vector2(720, 1280)
	return P
func ev_btn(P, pos: Vector2, pressed: bool):
	var e := InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_LEFT; e.pressed = pressed; e.position = pos; P._gui_input(e)
func ev_move(P, pos: Vector2):
	var e := InputEventMouseMotion.new(); e.position = pos; P._gui_input(e)
func wait_ms(ms: float):
	await create_timer(ms / 1000.0).timeout
func wait_ball(P) -> bool:
	var n := 0
	while P.carrier != P.user_ag and n < 900 and P.state == "play":
		await process_frame; n += 1
	return P.carrier == P.user_ag
func _initialize():
	Pitch = load("res://scripts/pitch.gd")
	_go()
func _go():
	await process_frame
	root.get_node("G").new_game("Test Oyuncu", "Türkiye", "FV", 9)
	# 1) basılı sürükle = top sür
	var P = mk()
	print("1 ball:", await wait_ball(P), " st=", P.state, " txt=", P.res.txt, " t=", snapped(P.t,.1), " forced=", P.forced_done)
	if P.carrier == P.user_ag:
		var s0: Vector2 = P._S(P.user_ag.pos); var start: Vector2 = P.user_ag.pos
		var tgtw: Vector2 = P.user_ag.pos + Vector2(-8, -6)
		ev_btn(P, s0, true)
		for i in 20:
			await wait_ms(45); ev_move(P, P._S(start.lerp(tgtw, (i + 1) / 20.0)))
		await wait_ms(400)
		print("  follow=", P.follow, " moved=", snapped(P.user_ag.pos.distance_to(start), .1), "m carrier_is_user=", P.carrier == P.user_ag)
		ev_btn(P, P._S(tgtw), false)
	P.queue_free(); await process_frame
	# 2) kavisli fiske = şut
	P = mk()
	print("2 ball:", await wait_ball(P), " st=", P.state, " txt=", P.res.txt, " t=", snapped(P.t,.1), " forced=", P.forced_done)
	if P.carrier == P.user_ag:
		var a: Vector2 = P._S(P.user_ag.pos)
		var goal: Vector2 = P._S(P.user_ag.pos.lerp(Vector2(38, -1), .55))
		ev_btn(P, a, true)
		for i in 6:
			await wait_ms(25); var f := (i + 1) / 6.0
			ev_move(P, a.lerp(goal, f) + Vector2(sin(f * PI) * 70, 0))
		ev_btn(P, goal, false)
		print("  shot=", P.shot != null, " curve=", snapped(P.bcurve, .1), " u_shot=", P.res.u_shot)
		var n := 0
		while P.state == "play" and n < 600: await process_frame; n += 1
		print("  result=", P.res.txt, " goal=", P.res.goal, " ugoal=", P.res.u_goal)
	P.queue_free(); await process_frame
	# 3) kısa kaydırma = çalım
	P = mk()
	print("3 ball:", await wait_ball(P))
	if P.carrier == P.user_ag:
		var a: Vector2 = P._S(P.user_ag.pos)
		ev_btn(P, a, true); await wait_ms(40); ev_move(P, a + Vector2(20, -10)); await wait_ms(40); ev_btn(P, a + Vector2(34, -14), false)
		print("  burst=", snapped(P.burst, .01), " msg=", P.msg)
	P.queue_free(); await process_frame
	# 4) arkadaşa dokun = pas
	P = mk()
	print("4 ball:", await wait_ball(P))
	if P.carrier == P.user_ag:
		var mate = null
		for m in P.ag:
			if m.team == 0 and not m.user and not m.gk and (mate == null or m.pos.distance_to(P.user_ag.pos) < mate.pos.distance_to(P.user_ag.pos)): mate = m
		var mp: Vector2 = P._S(mate.pos)
		ev_btn(P, mp, true); await wait_ms(60); ev_btn(P, mp, false)
		print("  passed=", P.carrier == null and P.intended == mate)
	P.queue_free(); await process_frame
	quit()
