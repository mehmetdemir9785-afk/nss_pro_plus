extends SceneTree
var main
var G
func _initialize():
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	_go()
func snap(n: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/gshots/%s.png" % n)
func _go():
	G = root.get_node("G")
	await snap("0_create")
	main.CR.n = "Kaan Yıldız"; main.show_create(); await snap("0b_create")
	G.new_game("Kaan Yıldız", "Türkiye", "FV", 9); main.render(); main._welcome(); await snap("1_welcome")
	main.close_sheet(true); main.render(); await snap("2_hub")
	G.S.ui.tab = "dev"; main.render(); await snap("3_dev")
	G.S.ui.tab = "life"; main.render(); await snap("4_life")
	G.S.ui.tab = "lig"; main.render(); await snap("5_lig")
	G.S.ui.tab = "car"; main.render(); await snap("6_car")
	G.S.ui.tab = "hub"; main.render(); G.S.pend.append(G.rand_event()); main.show_pending(); await snap("7_event")
	main.close_sheet(true)
	var sg = load("res://scripts/shot.gd").new(); sg.setup({"kind": "fk", "attr": 60, "ks": .4, "title": "Serbest vuruş", "sub": "34'  Kızılırmak 1 - 0 Ova"})
	main.top_layer.add_child(sg); sg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); await snap("8_shot")
	sg.queue_free()
	var tb = load("res://scripts/timing.gd").new()
	main.start_match(G.S.wq[0])
	var ms = main.top_layer.get_child(main.top_layer.get_child_count() - 1)
	ms.fast = true
	for i in 120: await process_frame
	ms.auto = true
	await snap("9_match")
	quit()
