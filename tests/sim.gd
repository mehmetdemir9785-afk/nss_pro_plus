extends SceneTree
var main
var G
func _initialize():
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_drive()
func _btns(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Button and not c.disabled and c.is_visible_in_tree(): out.append(c)
		_btns(c, out)
func _drive():
	await process_frame
	G = root.get_node("G"); G.speed = 0.0003
	G.new_game("Kaan Yıldız", "Türkiye", "FV", 9); main.render()
	var it := 0; var seasons_seen := 1; var matches := 0
	while it < 40000:
		it += 1
		await process_frame
		if G.S == null: print("RETIRED"); break
		if G.S.season > 6: break
		var ms = null
		for c in main.top_layer.get_children():
			if c.has_method("begin"): ms = c
		if ms != null:
			ms.auto = true; ms.fast = true
			var b := []; _btns(ms.mom, b)
			if b.size() > 0: b[0].pressed.emit(); matches += 1
			continue
		if main.sheet_layer.get_child_count() > 0:
			var b := []; _btns(main.sheet_layer, b)
			if b.size() > 0: b[0].pressed.emit()
			continue
		var p = G.S.p
		if p.gp > 0:
			for a in G.POS[p.pos].main:
				if p.gp >= G.gp_cost(p.attrs[a]) and p.attrs[a] < 99: p.gp -= G.gp_cost(p.attrs[a]); p.attrs[a] += 1
			if p.gp > 0 and p.gp >= G.gp_cost(p.attrs["fiz"]): p.gp -= G.gp_cost(p.attrs["fiz"]); p.attrs["fiz"] += 1
		for x in G.SHOP:
			if not p.items.has(x.id) and p.money > x.price * 2: main._buy(x.id); break
		if p.actions > 0 and p.injury == 0 and p.energy > 40: main._soc("coach") ; continue
		if not G.S.wq.is_empty(): main.start_match(G.S.wq[0])
	var p = G.S.p if G.S else null
	if p: print("RESULT season=%d week=%d age=%d ovr=%d team=%s tier=%d apps=%d goals=%d assists=%d caps=%d money=%d trophies=%s awards=%s ach=%d matches=%d" % [G.S.season, G.S.week, p.age, G.ovr(), G.my_team().name, G.tier(), p.career.apps, p.career.goals, p.career.assists, p.nat.caps, p.money, str(p.trophies), str(p.awards), p.ach.size(), matches])
	quit()
