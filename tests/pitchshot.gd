extends SceneTree
func snap(n: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/gshots/%s.png" % n)
func _initialize():
	_go()
func _go():
	await process_frame
	var G = root.get_node("G")
	G.new_game("Kaan Yıldız", "Türkiye", "FV", 9)
	var Pitch = load("res://scripts/pitch.gd")
	var P = Pitch.new()
	P.setup({"me": {"name": "Liman Spor", "col": "#16a34a", "str": 55}, "op": {"name": "Ova Spor", "col": "#dc2626", "str": 55}, "attack": 0, "involve": "attack", "upos": "FV", "unum": 9, "uname": "Kaan Yıldız", "uname_short": "YILDIZ", "auto": false, "on": true, "ustats": {"sut": 60, "pas": 50, "drip": 55, "hiz": 60, "sav": 40}, "title": "34'   Liman Spor 1 - 0 Ova Spor"})
	root.add_child(P); P.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await snap("p1_start")
	var tt := 0
	while P.carrier != P.user_ag and tt < 900 and P.state == "play":
		await process_frame; tt += 1
	await snap("p2_userball")
	# sürükleme simülasyonu: kaleye doğru
	print("user has ball: ", P.carrier == P.user_ag, " state=", P.state, " t=", P.t)
	var from: Vector2 = P._S(P.user_ag.pos)
	var to: Vector2 = P._S(Vector2(37, -.8))
	P.u_drag = [[from, Time.get_ticks_msec() - 220]]
	for i in 8: P.u_drag.append([from.lerp(to, i / 8.0) + Vector2(sin(i / 8.0 * PI) * 40, 0), Time.get_ticks_msec() - 220 + i * 25])
	await snap("p3_drag")
	P._user_release(P._P(to), from.distance_to(to), 220.0)
	P.u_drag = []
	for i in 20: await process_frame
	await snap("p4_shot")
	for i in 90: await process_frame
	await snap("p5_after")
	quit()
