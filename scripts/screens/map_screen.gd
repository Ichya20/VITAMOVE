extends Screen
## Peta "Jelajah Desa": 9 pos di sepanjang jalan desa, latar berlapis (parallax).

const SPACING := 400.0
const MARGIN_X := 300.0
const PARALLAX := 0.28

var scroll: ScrollContainer
var world: Control
var far: Landscape
var markers: Array[Medallion] = []
var token: ElderFigure
var bubble: SpeechBubble
var jali: Mascot
var _target := 0
var _walking := false
var _t := 0.0
var _cta: Button


func build() -> void:
	var vp := get_viewport_rect().size
	var h := vp.y
	var n := Data.STATIONS.size()
	var w := MARGIN_X * 2.0 + SPACING * (n - 1)

	far = Landscape.new()
	far.layer = "far"
	far.time_of_day = "pagi"
	far.horizon = 0.48
	far.seed_value = 11
	far.span_w = vp.x + w * PARALLAX + 80.0
	UI.full(far)
	add_child(far)
	for i in 5:
		var c := Cloud.new(150.0 + (i % 3) * 50.0, 6.0 + i * 2.0)
		c.position = Vector2(i * 330.0, 26.0 + (i % 2) * 60.0)
		c.span = vp.x + 200
		add_child(c)
	var birds := Decor.new("birds")
	birds.anchor_right = 1.0
	birds.anchor_bottom = 0.32
	add_child(birds)

	scroll = ScrollContainer.new()
	UI.full(scroll)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(scroll)
	world = Control.new()
	world.custom_minimum_size = Vector2(w, h)
	world.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(world)
	scroll.get_h_scroll_bar().value_changed.connect(func(v: float) -> void:
		far.parallax_x = v * PARALLAX
		far.queue_redraw())

	var pts := PackedVector2Array()
	var places: Array = []
	pts.append(Vector2(0, h * 0.72))
	for i in n:
		var p := _marker_pos(i, h)
		pts.append(p + Vector2(0, 26))
		places.append({"kind": Data.PLACE_KIND[i], "x": p.x + 130.0, "y": p.y - 6.0, "s": 0.78 * h / 720.0})
	pts.append(Vector2(w, h * 0.72))
	var near := Landscape.new()
	near.layer = "near"
	near.horizon = 0.48
	near.show_path = true
	near.path_points = pts
	near.places = places
	near.seed_value = 11
	near.custom_minimum_size = Vector2(w, h)
	near.size = Vector2(w, h)
	world.add_child(near)

	var p := Game.prof()
	var unlocked := int(p["unlocked"])
	_target = clampi(unlocked - 1, 0, n - 1)
	for i in n:
		_add_marker(i, h, unlocked)

	token = ElderFigure.new()
	token.set_avatar(str(p["avatar"]), int(p.get("outfit", 0)))
	token.custom_minimum_size = Vector2(110, 160)
	token.size = Vector2(110, 160)
	token.set_pose({"face": "happy"})
	world.add_child(token)
	var start_i := _target
	if params.has("opened"):
		start_i = clampi(int(params["opened"]) - 1, 0, n - 1)
	_place_token(start_i, h)

	_build_hud()
	UI.paper_grain(self, 0.25)
	await get_tree().process_frame
	_scroll_to(start_i, false)
	far.parallax_x = scroll.scroll_horizontal * PARALLAX
	far.queue_redraw()
	if bool(params.get("welcome", false)):
		params.erase("welcome")
		_welcome()
	elif params.has("opened"):
		var oi := int(params["opened"])
		params.erase("opened")
		if oi < n:
			_walk_to(oi)
			_say("Pos baru terbuka: %s! Ketuk penanda yang bersinar." % Data.STATIONS[oi]["name"])
		else:
			jali.hop()
			FX.confetti(self)
			Sfx.play("cheer")
			_say("Hebat! Semua pos sudah dijelajahi. Ulangi latihan kapan saja, ya.")
	else:
		_say("Ketuk penanda yang bersinar untuk mulai belajar, %s." % p["name"])


func _marker_pos(i: int, h: float) -> Vector2:
	return Vector2(MARGIN_X + i * SPACING - 70.0, h * (0.6 if i % 2 == 0 else 0.7))


func _add_marker(i: int, h: float, unlocked: int) -> void:
	var st: Dictionary = Data.STATIONS[i]
	var pos := _marker_pos(i, h)
	var locked := i >= unlocked
	var m := Medallion.new()
	m.setup(Color(str(st["color"])), str(st["icon"]), i + 1, Game.leaves_of(str(st["id"])), locked, i == _target and not locked)
	m.position = pos - Vector2(66, 82)
	m.set("accessibility_name", "Pos %d: %s%s" % [i + 1, st["name"], " (terkunci)" if locked else ""])
	m.pressed.connect(_on_marker.bind(i))
	world.add_child(m)
	markers.append(m)
	# papan nama kayu
	var sign_p := UI.panel("Wood")
	sign_p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := UI.vbox(0)
	sign_p.add_child(v)
	var nm := UI.label(str(st["name"]), "H3", false, HORIZONTAL_ALIGNMENT_CENTER)
	nm.add_theme_color_override("font_color", Game.CREAM)
	nm.add_theme_font_size_override("font_size", Game.fs_cap(22, 1.08))
	v.add_child(nm)
	var sub := UI.label(str(st["place"]), "Small", false, HORIZONTAL_ALIGNMENT_CENTER)
	sub.add_theme_color_override("font_color", Color(Game.CREAM, 0.8))
	sub.add_theme_font_size_override("font_size", Game.fs_cap(18, 1.08))
	v.add_child(sub)
	world.add_child(sign_p)
	await get_tree().process_frame
	if is_instance_valid(sign_p):
		sign_p.position = pos + Vector2(-sign_p.size.x / 2.0, 66)
		if locked:
			sign_p.modulate = Color(1, 1, 1, 0.75)


func _place_token(i: int, h: float) -> void:
	var pos := _marker_pos(i, h)
	token.position = pos + Vector2(-190, -100)


func _walk_to(i: int) -> void:
	var h := get_viewport_rect().size.y
	var from := token.position
	var to := _marker_pos(i, h) + Vector2(-190, -100)
	_walking = true
	_scroll_to(i, true)
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_property(token, "position", to, 1.6 if Game.motion() else 0.01).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		_walking = false
		token.set_pose({"la": 150.0, "ra": 150.0, "face": "happy"})
		Sfx.play("unlock")
		FX.burst(world, markers[i].position + Vector2(66, 60), 30))
	tw.tween_interval(1.2)
	tw.tween_callback(func() -> void: token.set_pose({"face": "happy"}))
	if from.distance_to(to) < 2.0:
		_walking = false


func _build_hud() -> void:
	var sa: Vector4 = main.safe_margins()
	var vpw := get_viewport_rect().size
	var top := UI.margin(24 + sa.x, 16 + sa.y, 24 + sa.z, 0)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	var bar := UI.hbox(12)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(bar)
	var home := UI.icon_btn("home", "Beranda", "Button", 76)
	home.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.home())
	bar.add_child(home)
	var p := Game.prof()
	var chip := UI.panel("Pill")
	var ch := UI.hbox(12)
	chip.add_child(ch)
	ch.add_child(UI.badge("user", Game.TEAL_MID, 44))
	var cv := UI.vbox(2)
	var nl := UI.label(str(p["name"]), "H3")
	nl.add_theme_font_size_override("font_size", Game.fs_cap(23, 1.08))
	cv.add_child(nl)
	var pr := UI.hbox(8)
	var pb := UI.progress(Game.stations_done(), Data.STATIONS.size(), 12)
	pb.custom_minimum_size.x = 150
	pr.add_child(pb)
	var pl := UI.label("%d/%d pos" % [Game.stations_done(), Data.STATIONS.size()], "Small")
	pl.add_theme_font_size_override("font_size", Game.fs_cap(18, 1.05))
	pr.add_child(pl)
	cv.add_child(pr)
	ch.add_child(cv)
	ch.add_child(Icon.new("leaf", Game.LEAF, 28))
	var lv := UI.label(str(Game.total_leaves()), "H3")
	ch.add_child(lv)
	bar.add_child(chip)
	bar.add_child(UI.spacer())
	var cap := UI.btn(Game.CAPACITY_SHORT[int(p["capacity"])], "ChoiceButton", "chair", 76, 28)
	cap.tooltip_text = "Ubah cara berlatih"
	cap.set("accessibility_name", "Cara berlatih: %s. Ketuk untuk mengubah" % Game.CAPACITY_NAMES[int(p["capacity"])])
	cap.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("profiles", {"edit": true}))
	bar.add_child(cap)
	var jr := UI.btn("Catatan", "SunButton", "calendar", 76, 30)
	jr.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("journal"))
	bar.add_child(jr)
	var st := UI.icon_btn("gear", "Pengaturan", "Button", 76)
	st.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("settings"))
	bar.add_child(st)

	for side: int in [-1, 1]:
		var ab := UI.icon_btn("prev" if side < 0 else "next", "Pos sebelumnya" if side < 0 else "Pos berikutnya", "TealButton", 84)
		ab.position = Vector2(16 + sa.x if side < 0 else vpw.x - 100 - sa.z, vpw.y * 0.36)
		var sd: int = side
		ab.pressed.connect(func() -> void:
			Sfx.play("tap")
			_scroll_to(clampi(_view_index() + sd, 0, Data.STATIONS.size() - 1), true))
		add_child(ab)

	jali = Mascot.new()
	jali.size = Vector2(118, 118)
	jali.position = Vector2(20 + sa.x, 108 + sa.y)
	add_child(jali)
	var bwrap := VBoxContainer.new()
	bwrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bwrap.position = Vector2(150 + sa.x, 122 + sa.y)
	bwrap.size = Vector2(440, 10)
	add_child(bwrap)
	bubble = SpeechBubble.new("", "left", "H3")
	bubble.visible = false
	bwrap.add_child(bubble)

	var done_all := Game.stations_done() >= Data.STATIONS.size()
	var cta_text := "Lanjut: Pos %d" % (_target + 1)
	if done_all:
		cta_text = "Ulangi Pos Favorit"
	_cta = UI.btn(cta_text, "PrimaryButton", "play", 88, 34)
	add_child(_cta)
	_cta.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_cta.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_cta.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_cta.offset_right = -28 - sa.z
	_cta.offset_bottom = -24 - sa.w
	_cta.offset_left = _cta.offset_right - 10
	_cta.offset_top = _cta.offset_bottom - 10
	_cta.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("station", {"index": _target}))
	UI.pop_in([bar, _cta, jali], 0.1, 0.08)


func _say(text: String) -> void:
	bubble.set_text(text)
	bubble.visible = true
	bubble.pop()
	jali.talking = true
	jali.hop()
	get_tree().create_timer(2.2).timeout.connect(func() -> void:
		if is_instance_valid(jali):
			jali.talking = false)
	Game.speak(text)


func _view_index() -> int:
	var center := scroll.scroll_horizontal + scroll.size.x / 2.0
	return clampi(int(round((center - MARGIN_X + 70.0) / SPACING)), 0, Data.STATIONS.size() - 1)


func _scroll_to(i: int, animate: bool) -> void:
	var h := get_viewport_rect().size.y
	var x := _marker_pos(i, h).x - scroll.size.x / 2.0
	var maxs := maxf(0.0, world.custom_minimum_size.x - scroll.size.x)
	x = clampf(x, 0.0, maxs)
	if animate and Game.motion():
		var tw := create_tween()
		tw.tween_property(scroll, "scroll_horizontal", int(x), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		scroll.scroll_horizontal = int(x)


func _on_marker(i: int) -> void:
	var unlocked := int(Game.prof()["unlocked"])
	if i >= unlocked:
		Sfx.play("soft_no")
		markers[i].pivot_offset = markers[i].size / 2.0
		var tw := create_tween()
		for k in 4:
			tw.tween_property(markers[i], "rotation", 0.12 * (1 if k % 2 == 0 else -1), 0.06)
		tw.tween_property(markers[i], "rotation", 0.0, 0.06)
		_say("Pos %s masih terkunci. Selesaikan pos sebelumnya dulu, ya." % Data.STATIONS[i]["name"])
		return
	Sfx.play("tap")
	main.go("station", {"index": i})


func _welcome() -> void:
	var p := Game.prof()
	main.show_dialog("Halo, %s! Aku Jali." % p["name"], "Ayo jelajahi 9 pos di desa. Di setiap pos ada 3 langkah: LIHAT materi, IKUTI gerakan, lalu COBA tantangan. Kumpulkan daun dan bergeraklah sesuai kemampuan.", [
		{"text": "Ayo mulai", "style": "PrimaryButton", "icon": "play", "is_cancel": true},
	], "leaf", "leaf")


func default_focus() -> Control:
	return _cta


func _process(delta: float) -> void:
	_t += delta
	if token and _walking:
		var m := sin(_t * 9.0)
		token.set_pose({"ll": maxf(0.0, m) * 0.5, "rl": maxf(0.0, -m) * 0.5, "lf": maxf(0.0, -m) * 0.5, "rf": maxf(0.0, m) * 0.5, "le": 40.0, "re": 40.0, "face": "happy"})
