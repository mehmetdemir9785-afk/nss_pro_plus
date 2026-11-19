extends SceneTree
func _initialize():
	var Pitch = load("res://scripts/pitch.gd")
	for att in [0, 1]:
		var out := {}; var shots := 0; var shot_d := 0.0; var N := 300
		for i in N:
			var P = Pitch.new()
			P.setup({"me": {"name": "A", "col": "#dc2626", "str": 60}, "op": {"name": "B", "col": "#2563eb", "str": 60}, "attack": att, "involve": "none", "auto": true})
			P.headless = true
			var shot_seen := false
			var g := 0
			while P.state != "done" and g < 3000:
				P.step(1.0/30.0); g += 1
				if P.state == "replay_wait": P.state = "end"
				if P.shot != null and not shot_seen:
					shot_seen = true; shots += 1; shot_d += P.shot.by.pos.distance_to(P._goal(P.shot.team))
			var k: String = P.res.txt
			out[k] = out.get(k, 0) + 1
			P.free()
		print("attack=", att, " shots=", shots, " avg_dist=", shot_d / max(1, shots), " ", out)
	quit()
