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


func shot(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	n += 1
	img.save_png("%s/%02d_%s.png" % [out_dir, n, name])
	print("SHOT ", name, " ", img.get_size())


func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func cur() -> Node:
	return main.current


func _run() -> void:
	Game.reset_all()
	Game.settings["tts"] = false
	await wait(1.2)
	await shot("title")
	main.go("profiles", {"create": true})
	await wait(0.6)
	await shot("profile_avatar")
	cur().step = 2
	cur()._render()
	await wait(0.4)
	await shot("profile_name")
	cur().step = 3
	cur()._render()
	await wait(0.4)
	await shot("profile_capacity")
	Game.add_profile("Mbah Sri", "putri", 1)
	Game.profiles[0]["unlocked"] = 4
	Game.profiles[0]["leaves"] = {"manfaat": 3, "persiapan": 2, "pemanasan": 3}
	Game.profiles[0]["last_check"] = Game.today_str()
	Game.save_data()
	main.go("map", {"welcome": true})
	await wait(1.0)
	await shot("map_welcome")
	main.close_all_dialogs()
	main.current.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
	await wait(0.6)
	await shot("map")

	main.go("station", {"index": 0})
	await wait(0.6)
	await shot("station_card")
	main.go("station", {"index": 2})
	await wait(0.4)
	cur()._go_phase(1)
	await wait(0.6)
	await shot("practice_ready")
	cur()._toggle_play()
	await wait(7.0)
	await shot("practice_playing")
	cur()._ask_feeling()
	await wait(0.4)
	await shot("feeling")

	main.go("station", {"index": 4})
	await wait(0.4)
	cur().capacity = 0
	cur()._go_phase(1)
	await wait(0.4)
	cur()._toggle_play()
	await wait(6.0)
	await shot("practice_seated")

	main.go("station", {"index": 3})
	await wait(0.4)
	cur().move_i = 1
	cur()._go_phase(1)
	await wait(0.4)
	cur()._toggle_play()
	await wait(7.5)
	await shot("practice_support")
	cur()._go_phase(2)
	await wait(0.4)
	var bal = cur()._body.get_child(0).get_child(0)
	bal._begin()
	await wait(3.0)
	await shot("balance_game")

	main.go("station", {"index": 1})
	await wait(0.4)
	cur()._go_phase(2)
	await wait(0.5)
	await shot("tidy_game")
	main.go("station", {"index": 8})
	await wait(0.4)
	cur()._go_phase(2)
	await wait(0.5)
	await shot("traffic_game")
	main.go("station", {"index": 6})
	await wait(0.4)
	cur()._go_phase(2)
	await wait(0.5)
	var q = cur()._body.get_child(0).get_child(0)
	q._on_answer(q._answers.get_child(0), 0)
	await wait(0.3)
	await shot("market_quiz")
	cur().moves_done = 3
	cur().ch_score = 3
	cur().ch_total = 4
	cur()._go_phase(3)
	await wait(1.6)
	await shot("result")

	main.go("journal")
	await wait(0.6)
	await shot("journal")
	main.go("test", {"kind": "pre"})
	await wait(0.4)
	cur()._start()
	await wait(0.4)
	await shot("pretest")
	main.go("session")
	await wait(0.6)
	await shot("session_setup")
	cur()._start_session()
	await wait(8.0)
	await shot("session_play")
	main.go("settings")
	await wait(0.6)
	await shot("settings")
	main.go("info")
	await wait(0.5)
	await shot("info_about")
	cur()._show(1)
	await wait(0.4)
	await shot("info_team")
	cur()._scroll.scroll_vertical = 600
	await wait(0.3)
	await shot("info_team_bottom")
	cur()._show(2)
	await wait(0.3)
	await shot("info_partner")
	Game.set_setting("text_scale", 2)
	main.go("station", {"index": 5})
	await wait(0.5)
	await shot("station_bigtext")
	cur()._go_phase(1)
	await wait(0.5)
	await shot("practice_bigtext")
	Game.set_setting("text_scale", 1)
	main.home()
	await wait(0.8)
	await shot("title_after")
	print("TOUR_DONE")
	get_tree().quit()
