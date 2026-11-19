extends SceneTree
func _initialize():
	var Pitch = load("res://scripts/pitch.gd")
	var G = root.get_node("G")
	var t0 := Time.get_ticks_msec()
	for combo in [[60,60,"none",0],[60,60,"none",1],[45,75,"none",0],[75,45,"none",0],[60,60,"attack",0],[60,60,"defend",1]]:
		var goals := 0; var ug := 0; var ua := 0; var touch := 0; var N := 120; var dur := 0.0; var txts := {}
		for i in N:
			var P = Pitch.new()
			P.setup({"me": {"name": "A", "col": "#dc2626", "str": combo[0]}, "op": {"name": "B", "col": "#2563eb", "str": combo[1]}, "attack": combo[3], "involve": combo[2], "upos": "FV" if combo[2] == "attack" else "DF", "auto": true, "on": true, "ustats": {"sut": 60, "pas": 60, "drip": 60, "hiz": 60, "sav": 60}})
			var r = P.simulate()
			if r.goal != "": goals += 1
			if r.u_goal: ug += 1
			if r.u_assist: ua += 1
			if r.u_touch: touch += 1
			dur += P.t
			txts[r.txt] = txts.get(r.txt, 0) + 1
			P.free()
		print(combo, " goal%=", 100.0 * goals / N, " ugoal%=", 100.0 * ug / N, " uassist%=", 100.0 * ua / N, " touch%=", 100.0 * touch / N, " avg_t=", dur / N)
		print("   ", txts)
	print("ms=", Time.get_ticks_msec() - t0)
	quit()
