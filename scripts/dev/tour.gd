extends Node
## Alat pengembang: tur otomatis yang mengambil tangkapan layar setiap layar.
## Hanya aktif dengan argumen: -- --tour=<folder>

var main: Node
var out_dir := "user://shots"
var n := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tour="):
			out_dir = a.substr(7)
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run()


func shot(shot_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if DisplayServer.get_name() == "headless":
		n += 1
		print("SHOT ", shot_name)
		return
	var img := get_viewport().get_texture().get_image()
	n += 1
	img.save_png("%s/%02d_%s.png" % [out_dir, n, shot_name])
	print("SHOT ", shot_name, " ", img.get_size())


func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func cur() -> Node:
	return main.current


func go(screen: String, p: Dictionary = {}) -> void:
	main.go(screen, p)
	await wait(1.1)


func _run() -> void:
	Game.reset_all()
	Game.settings["tts"] = false
	# splash beranimasi
	await wait(0.55)
	await shot("splash_a_slide")
	await wait(0.75)
	await shot("splash_b_meet")
	await wait(0.65)
	await shot("splash_c_ribbon")
	await wait(0.85)
	await shot("splash_d_jali")
	await wait(0.7)
	await shot("splash_e_full")
	await wait(1.6)
	await shot("title_empty")
	await go("profiles", {"create": true})
	await shot("profile_avatar")
	cur().step = 2
	cur()._render()
	await wait(0.8)
	await shot("profile_name")
	cur().step = 3
	cur()._render()
	await wait(0.8)
	await shot("profile_capacity")
	Game.add_profile("Mbah Sri", "putri", 1, 0)
	Game.add_profile("Mbah Darmo", "kakung", 0, 2)
	Game.select_profile(0)
	Game.profiles[0]["unlocked"] = 4
	Game.profiles[0]["leaves"] = {"manfaat": 3, "persiapan": 2, "pemanasan": 3}
	Game.profiles[0]["last_check"] = Game.today_str()
	Game.save_data()
	await go("profiles")
	await shot("profile_list")
	await go("map", {"welcome": true})
	await wait(0.4)
	await shot("map_welcome")
	main.close_all_dialogs()
	await wait(0.5)
	await shot("map")
	await go("map", {"opened": 3})
	await wait(2.2)
	await shot("map_walk")

	await go("station", {"index": 0})
	await shot("station_card")
	cur()._on_next_card()
	await wait(0.6)
	await shot("station_card2")
	await go("station", {"index": 2})
	cur()._go_phase(1)
	await wait(0.8)
	await shot("practice_ready")
	cur()._toggle_play()
	await wait(7.0)
	await shot("practice_playing")
	cur()._on_move_finished()
	await wait(0.5)
	await shot("practice_done")
	cur()._ask_feeling()
	await wait(0.8)
	await shot("feeling")

	await go("station", {"index": 4})
	cur().capacity = 0
	cur()._go_phase(1)
	await wait(0.5)
	cur()._toggle_play()
	await wait(6.5)
	await shot("practice_seated")

	await go("station", {"index": 3})
	cur().move_i = 1
	cur()._go_phase(1)
	await wait(0.5)
	cur()._toggle_play()
	await wait(7.5)
	await shot("practice_support")
	cur()._go_phase(2)
	await wait(0.6)
	var bal = cur()._body.get_child(0).get_child(0)
	bal._begin()
	await wait(3.0)
	await shot("balance_game")

	await go("station", {"index": 1})
	cur()._go_phase(2)
	await wait(0.8)
	await shot("tidy_game")
	await go("station", {"index": 8})
	cur()._go_phase(2)
	await wait(0.8)
	var tr = cur()._body.get_child(0).get_child(0)
	tr._on_pick(int(tr.items[0]["c"]))
	await wait(0.4)
	await shot("traffic_game")
	await go("station", {"index": 6})
	cur()._go_phase(2)
	await wait(0.9)
	var q = cur()._body.get_child(0).get_child(0)
	var wrong_card = null
	for c in q._cards:
		if int(c.get_meta("ai")) != 0:
			wrong_card = c
			break
	q._on_answer(wrong_card, int(wrong_card.get_meta("ai")))
	await wait(0.5)
	await shot("market_quiz")
	cur().moves_done = 3
	cur().ch_score = 4
	cur().ch_total = 4
	cur()._go_phase(3)
	await wait(1.8)
	await shot("result")

	await go("journal")
	await shot("journal")
	await go("test", {"kind": "pre"})
	cur()._start()
	await wait(0.8)
	await shot("pretest")
	await go("session")
	await shot("session_setup")
	cur()._start_session()
	await wait(8.0)
	await shot("session_play")
	await go("settings")
	await shot("settings")
	await go("info")
	await shot("info_about")
	cur()._show(1)
	await wait(0.6)
	await shot("info_team")
	cur()._scroll.scroll_vertical = 700
	await wait(0.4)
	await shot("info_team_bottom")
	cur()._show(2)
	await wait(0.6)
	await shot("info_partner")
	main.show_dialog("Contoh dialog", "Ini adalah contoh tampilan dialog dengan lencana ikon.", [{"text": "Batal", "style": "Button", "is_cancel": true}, {"text": "Lanjut", "style": "PrimaryButton"}], "leaf", "leaf")
	await wait(0.6)
	await shot("dialog")
	main.close_all_dialogs()
	main.toast("Contoh notifikasi singkat di bagian atas layar.", "info")
	await wait(0.6)
	await shot("toast")
	Game.set_setting("text_scale", 2)
	await go("station", {"index": 5})
	await shot("station_bigtext")
	cur()._go_phase(1)
	await wait(0.6)
	await shot("practice_bigtext")
	Game.set_setting("text_scale", 0)
	main.home()
	await wait(1.6)
	await shot("title_after")
	# transisi di tengah jalan
	main.go("info")
	await wait(0.24)
	await shot("transition")
	await wait(1.0)
	print("TOUR_DONE")
	get_tree().quit()
