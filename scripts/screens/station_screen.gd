extends Screen
## Satu pos materi: LIHAT (kartu) -> IKUTI (demonstrasi gerakan) -> COBA (tantangan) -> hasil.

const PHASES := ["Lihat", "Ikuti", "Coba"]

var index := 0
var st: Dictionary
var phase := 0
var card_i := 0
var move_i := 0
var capacity := 1
var moves_done := 0
var feel := ""
var ch_score := 0
var ch_total := 0

var _body: VBoxContainer
var _stepper: Stepper
var _focus: Control
var _demo: MoveDemo
var _ring: CountRing
var _cue_label: Label
var _play_btn: Button
var _after_row: HBoxContainer
var _ctrl_row: HBoxContainer
var _prog: ProgressBar
var _stage: Control
var _card_wrap: Control
var _card: PanelContainer
var _bubble: SpeechBubble
var _jali: Mascot
var _dots: Control
var _prev_btn: Button
var _next_btn: Button


func build() -> void:
	index = int(params.get("index", 0))
	st = Data.STATIONS[index]
	capacity = int(Game.prof()["capacity"])
	scene_bg(Data.PLACE_KIND[index], "pagi", 0.42)
	make_content(26)
	var v := UI.vbox(14)
	content.add_child(v)
	var bar := header(str(st["name"]), "Pos %d · %s" % [index + 1, st["place"]])
	_stepper = Stepper.new(PHASES if _has_moves() else ["Lihat", "Coba"])
	_stepper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header_add(bar, _stepper)
	v.add_child(bar)
	_body = UI.vbox(14)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_body)
	_go_phase(0)


func _has_moves() -> bool:
	return not (st["moves"] as Array).is_empty()


func _step_index(p: int) -> int:
	if _has_moves():
		return p
	return 0 if p == 0 else (1 if p == 2 else 2)


func _clear() -> void:
	if _demo:
		_demo.pause()
	Game.stop_speech()
	Sfx.duck(false)
	for c in _body.get_children():
		c.queue_free()
	_demo = null
	_focus = null


func _go_phase(p: int) -> void:
	phase = p
	_clear()
	_stepper.set_current(_step_index(mini(p, 3)))
	match p:
		0: _render_learn()
		1: _start_practice()
		2: _render_challenge()
		3: _render_result()
	if _focus and get_viewport().gui_get_focus_owner() != null:
		_focus.call_deferred("grab_focus")


func on_back() -> bool:
	if phase == 1 and _demo and _demo.playing:
		_toggle_play()
		return true
	if phase in [1, 2]:
		main.show_dialog("Keluar dari pos ini?", "Kemajuan di pos ini belum tersimpan. Mbah bisa mengulang kapan saja.", [
			{"text": "Lanjutkan di sini", "style": "Button", "is_cancel": true},
			{"text": "Ke peta", "style": "PrimaryButton", "cb": main.back},
		], "home", "terra")
		return true
	return false


func on_leave() -> void:
	Sfx.duck(false)
	super.on_leave()


func default_focus() -> Control:
	return _focus


# ================================================================== LIHAT

func _render_learn() -> void:
	var row := UI.hbox(22)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(row)
	var left := UI.vbox(10)
	left.custom_minimum_size = Vector2(270, 0)
	row.add_child(left)
	_jali = Mascot.new()
	_jali.custom_minimum_size = Vector2(150, 140)
	_jali.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left.add_child(_jali)
	_bubble = SpeechBubble.new("", "top", "Body")
	_bubble.tail_at = 0.5
	_bubble.label.add_theme_font_size_override("font_size", Game.fs(23))
	left.add_child(_bubble)

	_card_wrap = Control.new()
	_card_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_card_wrap.clip_contents = false
	row.add_child(_card_wrap)

	var nav := UI.hbox(14)
	_body.add_child(nav)
	_prev_btn = UI.btn("Sebelumnya", "Button", "prev", 80, 28)
	_prev_btn.pressed.connect(func() -> void:
		if card_i > 0:
			Sfx.play("page")
			_show_card(card_i - 1, -1.0))
	nav.add_child(_prev_btn)
	var listen := UI.btn("Dengarkan", "SunButton", "speaker", 80, 30)
	listen.pressed.connect(func() -> void:
		var c: Dictionary = st["cards"][card_i]
		if not Game.speak(str(c["t"]) + ". " + str(c["x"]), true):
			main.toast("Suara pemandu belum tersedia di HP ini. Minta kader membacakan, atau pasang suara Bahasa Indonesia di pengaturan Text-to-Speech.", "speaker"))
	nav.add_child(listen)
	_dots = Control.new()
	_dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dots.custom_minimum_size = Vector2(120, 40)
	_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dots.draw.connect(_draw_dots)
	nav.add_child(_dots)
	_next_btn = UI.btn("Berikutnya", "PrimaryButton", "next", 84, 32)
	_next_btn.pressed.connect(_on_next_card)
	nav.add_child(_next_btn)
	_focus = _next_btn
	reveal([left, _card_wrap, nav])
	_show_card(card_i, 0.0)


func _draw_dots() -> void:
	var n := (st["cards"] as Array).size()
	var gapx := 30.0
	var x0 := _dots.size.x / 2.0 - gapx * (n - 1) / 2.0
	for i in n:
		var p := Vector2(x0 + i * gapx, _dots.size.y / 2.0)
		if i == card_i:
			_dots.draw_rect(Rect2(p - Vector2(14, 7), Vector2(28, 14)), Game.TERRA, true)
			_dots.draw_circle(p - Vector2(7, 0), 7, Game.TERRA, true, -1.0, true)
			_dots.draw_circle(p + Vector2(7, 0), 7, Game.TERRA, true, -1.0, true)
		else:
			_dots.draw_circle(p, 7, Game.LEAF if i < card_i else Color(Game.TEAL, 0.2), true, -1.0, true)


func _show_card(i: int, dir: float) -> void:
	card_i = i
	var cards: Array = st["cards"]
	var c: Dictionary = cards[i]
	var old := _card
	_card = UI.panel("Card")
	UI.full(_card)
	_card_wrap.add_child(_card)
	var ch := UI.hbox(28)
	_card.add_child(ch)
	var col := Color(str(st["color"]))
	var art := Control.new()
	art.custom_minimum_size = Vector2(250, 250)
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.draw.connect(func() -> void:
		var cc := art.size / 2.0
		var pts := PackedVector2Array()
		for k in 40:
			var a := float(k) / 40.0 * TAU
			var rr := 112.0 + sin(a * 3.0 + float(i)) * 4.5 + sin(a * 5.0) * 2.0
			pts.append(cc + Vector2(cos(a), sin(a)) * rr)
		var sh := PackedVector2Array()
		for q in pts:
			sh.append(q + Vector2(8, 10))
		art.draw_colored_polygon(sh, Color(Game.TEAL, 0.12))
		art.draw_colored_polygon(pts, col.lightened(0.62))
		pts.append(pts[0])
		art.draw_polyline(pts, col, 5.0, true)
		for k in 3:
			var a2 := -0.6 + k * 0.9
			art.draw_circle(cc + Vector2(cos(a2), sin(a2)) * 128.0, 9.0 - k * 2.0, col.lightened(0.2), true, -1.0, true))
	var ic := Icon.new(str(c["i"]), col.darkened(0.15), 136)
	ic.position = Vector2(57, 57)
	ic.size = Vector2(136, 136)
	art.add_child(ic)
	ch.add_child(art)
	var tv := UI.vbox(14)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	ch.add_child(tv)
	tv.add_child(UI.chip("Kartu %d dari %d" % [i + 1, cards.size()], "ChipSun", "book", Game.INK))
	tv.add_child(UI.label(str(c["t"]), "H1", true))
	var x := UI.label(str(c["x"]), "Lead", true)
	tv.add_child(x)
	(tv.get_child(0) as Control).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	_bubble.set_text(str(st["intro"]) if i == 0 else ["Baca pelan-pelan, ya.", "Mbah hebat, terus lanjut!", "Ini penting untuk diingat.", "Sedikit lagi, Mbah!"][i % 4])
	_bubble.pop()
	_jali.talking = true
	_jali.hop()
	get_tree().create_timer(1.6).timeout.connect(func() -> void:
		if is_instance_valid(_jali):
			_jali.talking = false)
	_prev_btn.disabled = i == 0
	var last := i >= cards.size() - 1
	UI.set_btn_text(_next_btn, ("Ikuti Gerakan" if _has_moves() else "Coba Tantangan") if last else "Berikutnya")
	_dots.queue_redraw()
	if bool(Game.settings["tts"]):
		Game.speak((str(st["intro"]) + ". " if i == 0 else "") + str(c["t"]) + ". " + str(c["x"]))
	if dir != 0.0 and Game.motion():
		_card.modulate.a = 0.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_card, "position:x", 0.0, 0.32).from(80.0 * dir).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(_card, "modulate:a", 1.0, 0.22)
	if is_instance_valid(old):
		if dir != 0.0 and Game.motion():
			var tw2 := create_tween().set_parallel(true)
			tw2.tween_property(old, "position:x", -80.0 * dir, 0.25).set_ease(Tween.EASE_IN)
			tw2.tween_property(old, "modulate:a", 0.0, 0.2)
			tw2.chain().tween_callback(old.queue_free)
		else:
			old.queue_free()


func _on_next_card() -> void:
	var cards: Array = st["cards"]
	if card_i < cards.size() - 1:
		Sfx.play("page")
		_show_card(card_i + 1, 1.0)
	else:
		Sfx.play("tap")
		_go_phase(1 if _has_moves() else 2)


# ================================================================== IKUTI

func _start_practice() -> void:
	var p := Game.prof()
	if str(p.get("last_check", "")) != Game.today_str():
		_safety_q1()
	else:
		_render_move()


func _safety_q1() -> void:
	main.show_dialog("Cek badan dulu, ya", "Hari ini, apakah Mbah merasa nyeri dada, sesak napas, pusing, atau sedang demam?", [
		{"text": "Ya, ada", "style": "DangerButton", "cb": _safety_stop},
		{"text": "Tidak ada", "style": "TealButton", "cb": _safety_q2},
	], "shield", "teal")


func _safety_q2() -> void:
	main.show_dialog("Satu pertanyaan lagi", "Apakah ada nyeri sendi yang tajam, bengkak baru, atau Mbah baru saja terjatuh?", [
		{"text": "Ya, ada", "style": "DangerButton", "cb": _safety_stop},
		{"text": "Tidak ada", "style": "TealButton", "cb": _safety_ok},
	], "shield", "teal")


func _safety_ok() -> void:
	Game.profiles[Game.current]["last_check"] = Game.today_str()
	Game.save_data()
	main.show_dialog("Siap berlatih!", "Siapkan kursi kokoh di dekat Mbah dan segelas air putih. Bergerak sesuai kemampuan, ya.", [
		{"text": "Mulai", "style": "PrimaryButton", "icon": "play", "is_cancel": true, "cb": _render_move},
	], "chair", "leaf")


func _safety_stop() -> void:
	main.show_dialog("Istirahat dulu hari ini", "Beri tahu kader atau tenaga kesehatan tentang keluhan Mbah. Mbah tetap bisa membaca materi dan menjawab tantangan.", [
		{"text": "Ke peta", "style": "Button", "cb": main.back},
		{"text": "Ke tantangan", "style": "PrimaryButton", "is_cancel": true, "cb": _go_phase.bind(2)},
	], "stop", "danger")


func _render_move() -> void:
	if phase != 1:
		return
	for c in _body.get_children():
		c.queue_free()
	Sfx.duck(true)
	var moves: Array = st["moves"]
	var mid: String = moves[move_i]
	var m: Dictionary = Data.MOVES[mid]
	var row := UI.hbox(18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(row)

	# ---- panggung
	var stage := UI.panel("Card")
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_stretch_ratio = 1.2
	var ssb := Game.soft_shadow(Game.sb(Game.PAPER, 28, 0, 0), 0.15, 18, 8)
	stage.add_theme_stylebox_override("panel", ssb)
	row.add_child(stage)
	_stage = Control.new()
	_stage.clip_contents = true
	stage.add_child(_stage)
	var mini_bg := Landscape.new()
	mini_bg.time_of_day = "pagi"
	mini_bg.horizon = 0.5
	mini_bg.mountain_x = 0.3
	UI.full(mini_bg)
	_stage.add_child(mini_bg)
	var vv := ColorRect.new()
	vv.color = Color(Game.CREAM, 0.35)
	vv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full(vv)
	_stage.add_child(vv)
	var mat := Decor.new("tikar")
	mat.anchor_left = 0.02
	mat.anchor_right = 0.72
	mat.anchor_top = 0.74
	mat.anchor_bottom = 0.88
	_stage.add_child(mat)
	_demo = MoveDemo.new()
	_demo.anchor_right = 0.74
	_demo.anchor_top = 0.05
	_demo.anchor_bottom = 0.84
	_stage.add_child(_demo)
	var p := Game.prof()
	_demo.setup(mid, capacity, str(p["avatar"]), -1, int(p.get("outfit", 0)))
	_demo.beat.connect(_on_beat)
	_demo.rep_changed.connect(_on_rep)
	_demo.segment_changed.connect(func(cue: String) -> void: _cue_label.text = cue)
	_demo.finished.connect(_on_move_finished)
	_ring = CountRing.new()
	_ring.anchor_left = 0.71
	_ring.anchor_right = 0.99
	_ring.anchor_top = 0.08
	_ring.anchor_bottom = 0.62
	_ring.reps = _demo.reps
	_ring.set_count("%dx" % _demo.reps, "ulangan")
	_stage.add_child(_ring)
	var cue_panel := UI.panel("Dark")
	cue_panel.anchor_left = 0.03
	cue_panel.anchor_right = 0.97
	cue_panel.anchor_top = 1.0
	cue_panel.anchor_bottom = 1.0
	cue_panel.offset_top = -80
	cue_panel.offset_bottom = -12
	cue_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_stage.add_child(cue_panel)
	var ch := UI.hbox(12)
	cue_panel.add_child(ch)
	ch.add_child(Icon.new("speaker", Game.SAFFRON, 34))
	_cue_label = UI.label("Tekan Mulai, lalu ikuti hitungannya.", "OnDark", true)
	_cue_label.add_theme_font_size_override("font_size", Game.fs_cap(27, 1.12))
	_cue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ch.add_child(_cue_label)
	_prog = UI.progress(0.0, 1.0, 12, Game.SAFFRON)
	_prog.anchor_left = 0.03
	_prog.anchor_right = 0.97
	_prog.offset_top = 14
	_prog.offset_bottom = 26
	_stage.add_child(_prog)

	# ---- panel petunjuk
	var info := UI.panel("Cream")
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var iv := UI.vbox(10)
	info.add_child(iv)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	chips.add_child(UI.chip("Gerakan %d/%d" % [move_i + 1, moves.size()], "ChipSun", "run", Game.INK))
	chips.add_child(UI.chip("%d× ulangan" % _demo.reps, "Chip", "replay", Game.TEAL))
	var vchair := int(_demo.variant["chair"])
	chips.add_child(UI.chip("Sambil duduk" if vchair == 1 else ("Berpegangan" if vchair == 2 else "Berdiri"), "ChipLeaf", "chair", Game.LEAF_DARK))
	iv.add_child(chips)
	iv.add_child(UI.label(str(m["name"]), "H1", true))
	var sc := UI.scroll_v()
	iv.add_child(sc)
	var sv := UI.vbox(10)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(sv)
	var note := str(_demo.variant.get("note", ""))
	if note != "":
		var np := UI.panel("Info")
		var nl := UI.label(note, "Body", true)
		nl.add_theme_font_size_override("font_size", Game.fs(22))
		np.add_child(nl)
		sv.add_child(np)
	var steps: Array = m["steps"]
	for i in steps.size():
		var sh := UI.hbox(12)
		var num := Control.new()
		num.custom_minimum_size = Vector2(38, 38)
		num.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var nn := str(i + 1)
		num.draw.connect(func() -> void:
			num.draw_circle(Vector2(19, 19), 18, Game.TERRA, true, -1.0, true)
			var f := Game.font_display
			var tw := f.get_string_size(nn, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
			num.draw_string(f, Vector2(19 - tw / 2.0, 28), nn, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE))
		sh.add_child(num)
		var sl := UI.label(str(steps[i]), "Body", true)
		sl.add_theme_font_size_override("font_size", Game.fs(24))
		sh.add_child(sl)
		sv.add_child(sh)
	var bp := UI.panel("Leaf")
	var bl := UI.label("Manfaat: " + str(m["benefit"]), "Small", true)
	bl.add_theme_color_override("font_color", Game.LEAF_DARK)
	bp.add_child(bl)
	sv.add_child(bp)
	var sp := UI.panel("Note")
	var sfl := UI.label("Aman: " + str(m["safety"]), "Small", true)
	sfl.add_theme_color_override("font_color", Color("6b4a0c"))
	sp.add_child(sfl)
	sv.add_child(sp)

	_ctrl_row = UI.hbox(12)
	_play_btn = UI.btn("Mulai", "PrimaryButton", "play", 84, 32)
	_play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play_btn.pressed.connect(_toggle_play)
	_ctrl_row.add_child(_play_btn)
	var again := UI.icon_btn("replay", "Ulangi dari awal", "Button", 84)
	again.pressed.connect(func() -> void:
		Sfx.play("tap")
		_after_row.visible = false
		_ctrl_row.visible = true
		_demo.restart()
		UI.set_btn_text(_play_btn, "Jeda")
		UI.set_btn_icon(_play_btn, "pause"))
	_ctrl_row.add_child(again)
	var tempo := UI.btn("Lambat" if int(Game.settings["tempo"]) == 0 else "Sedang", "ChoiceButton", "", 84)
	tempo.tooltip_text = "Ubah tempo"
	tempo.pressed.connect(func() -> void:
		Sfx.play("tap")
		Game.set_setting("tempo", 1 - int(Game.settings["tempo"]))
		tempo.text = "Lambat" if int(Game.settings["tempo"]) == 0 else "Sedang")
	_ctrl_row.add_child(tempo)
	iv.add_child(_ctrl_row)

	_after_row = UI.hbox(12)
	_after_row.visible = false
	var ok := UI.btn("Saya bisa!", "LeafButton", "check", 84, 32)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.pressed.connect(_next_move)
	_after_row.add_child(ok)
	var heavy := UI.btn("Terasa berat", "Button", "", 84)
	heavy.pressed.connect(_too_heavy)
	_after_row.add_child(heavy)
	iv.add_child(_after_row)
	_focus = _play_btn
	reveal([stage, info])
	Game.speak(str(m["name"]) + ". " + " ".join(PackedStringArray(steps)))


func _toggle_play() -> void:
	Sfx.play("tap")
	if _demo.playing:
		_demo.pause()
		UI.set_btn_text(_play_btn, "Lanjut")
		UI.set_btn_icon(_play_btn, "play")
		_cue_label.text = "Dijeda. Tekan Lanjut bila siap."
	else:
		Game.stop_speech()
		_demo.start(true)
		UI.set_btn_text(_play_btn, "Jeda")
		UI.set_btn_icon(_play_btn, "pause")


func _on_beat(c: int, _cue: String) -> void:
	if c < 0:
		_ring.set_count(str(-c), "siap")
		_cue_label.text = "Siap..."
	else:
		_ring.set_count(str(c), "")
	_ring.progress = _demo.progress()
	_prog.value = _demo.progress()


func _on_rep(r: int, total: int) -> void:
	_ring.reps = total
	_ring.rep_now = r - 1
	_ring.queue_redraw()


func _on_move_finished() -> void:
	Sfx.play("success")
	_prog.value = 1.0
	_ring.progress = 1.0
	_ring.rep_now = _ring.reps
	_ring.set_count("OK", "selesai")
	_cue_label.text = "Selesai! Bagaimana rasanya?"
	_ctrl_row.visible = false
	_after_row.visible = true
	moves_done = maxi(moves_done, move_i + 1)
	FX.burst(_stage, Vector2(_stage.size.x * 0.36, _stage.size.y * 0.5), 22)
	FX.float_text(_stage, Vector2(_stage.size.x * 0.36, _stage.size.y * 0.3), "Hebat!")
	_focus = _after_row.get_child(0)
	_focus.call_deferred("grab_focus")
	Game.speak("Selesai. Bagus sekali!")


func _too_heavy() -> void:
	Sfx.play("tap")
	if capacity > 0:
		main.show_dialog("Tidak apa-apa", "Gerakan bisa dibuat lebih ringan. Coba versi \"%s\", atau lewati dan istirahat sejenak." % Game.CAPACITY_NAMES[capacity - 1], [
			{"text": "Lewati", "style": "Button", "cb": _next_move},
			{"text": "Coba lebih ringan", "style": "PrimaryButton", "is_cancel": true, "cb": _lighter},
		], "heart", "terra")
	else:
		main.show_dialog("Tidak apa-apa", "Kurangi jumlah ulangan atau buat gerakan lebih kecil. Bila terasa nyeri, berhenti dan beri tahu kader atau tenaga kesehatan.", [
			{"text": "Lanjut", "style": "PrimaryButton", "is_cancel": true, "cb": _next_move},
		], "heart", "terra")


func _lighter() -> void:
	capacity = maxi(0, capacity - 1)
	_render_move()


func _next_move() -> void:
	Sfx.play("tap")
	moves_done = maxi(moves_done, move_i + 1)
	if move_i + 1 < (st["moves"] as Array).size():
		move_i += 1
		_render_move()
	else:
		_ask_feeling()


func _ask_feeling() -> void:
	Sfx.duck(false)
	for c in _body.get_children():
		c.queue_free()
	var panel := UI.panel("Card")
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(panel)
	var v := UI.vbox(22)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	v.add_child(UI.label("Semua gerakan selesai!", "Caption", false, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.label("Bagaimana rasanya badan Mbah sekarang?", "H1", true, HORIZONTAL_ALIGNMENT_CENTER))
	var row := UI.hbox(24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var opts := [["face_happy", "Segar", Color("8cc063")], ["face_ok", "Biasa saja", Color("f2b134")], ["face_tired", "Lelah", Color("e8a07a")]]
	var cards: Array = []
	for o in opts:
		var b := TapCard.new()
		b.custom_minimum_size = Vector2(250, 230)
		b.set("accessibility_name", o[1])
		var bv := UI.vbox(10)
		bv.alignment = BoxContainer.ALIGNMENT_CENTER
		bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(bv)
		var ic := Icon.new(o[0], o[2], 120)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		bv.add_child(ic)
		bv.add_child(UI.label(o[1], "H2", false, HORIZONTAL_ALIGNMENT_CENTER))
		var val: String = o[1]
		b.pressed.connect(func() -> void:
			Sfx.play("pop")
			feel = val
			if val == "Lelah":
				main.show_dialog("Istirahat sejenak", "Duduk dan minum air putih. Lelah ringan itu wajar. Bila lelah berlebihan, nyeri, atau pusing, beri tahu kader atau tenaga kesehatan.", [
					{"text": "Mengerti", "style": "PrimaryButton", "is_cancel": true, "cb": _go_phase.bind(2)},
				], "water", "teal")
			else:
				_go_phase(2))
		row.add_child(b)
		cards.append(b)
		if _focus == null:
			_focus = b
	reveal(cards, 0.1)
	Game.speak("Semua gerakan selesai! Bagaimana rasanya badan Mbah sekarang?")


# ================================================================== COBA

func _render_challenge() -> void:
	var ch: Dictionary = st["challenge"]
	var panel := UI.panel("Card")
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(panel)
	match str(ch["type"]):
		"quiz":
			var q := QuizChallenge.new()
			panel.add_child(q)
			q.setup(ch["q"], "Tantangan %s" % st["name"])
			q.done.connect(_on_challenge_done)
		"market":
			var q2 := QuizChallenge.new()
			panel.add_child(q2)
			q2.setup(Data.MARKET, "Belanja Aman di Pasar")
			q2.done.connect(_on_challenge_done)
		"tidy":
			var t := TidyChallenge.new()
			panel.add_child(t)
			t.setup()
			t.done.connect(_on_challenge_done)
		"balance":
			var b := BalanceChallenge.new()
			panel.add_child(b)
			var p := Game.prof()
			b.setup(str(p["avatar"]), int(p.get("outfit", 0)))
			b.done.connect(_on_challenge_done)
		"traffic":
			var tr := TrafficChallenge.new()
			panel.add_child(tr)
			tr.setup()
			tr.done.connect(_on_challenge_done)
	reveal([panel])


func _on_challenge_done(score: int, total: int) -> void:
	ch_score = score
	ch_total = total
	_go_phase(3)


# ================================================================== HASIL

func _render_result() -> void:
	var leaves := 1
	if _has_moves():
		if moves_done >= (st["moves"] as Array).size():
			leaves += 1
	else:
		leaves += 1
	if ch_total > 0 and float(ch_score) / ch_total >= 0.66:
		leaves += 1
	var before := int(Game.prof()["unlocked"])
	var opened := Game.award_station(index, str(st["id"]), leaves)
	Game.log_activity({
		"type": "pos", "station": st["id"], "name": st["name"], "moves": moves_done,
		"score": "%d/%d" % [ch_score, ch_total], "feel": feel, "leaves": leaves,
	})
	var panel := UI.panel("Cream")
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(panel)
	var h := UI.hbox(30)
	panel.add_child(h)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(330, 0)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(stage)
	var rays := Decor.new("rays")
	rays.color = Game.SAFFRON
	UI.full(rays)
	stage.add_child(rays)
	var mat := Decor.new("tikar")
	mat.anchor_left = 0.08
	mat.anchor_right = 0.92
	mat.anchor_top = 0.84
	mat.anchor_bottom = 1.0
	stage.add_child(mat)
	var fig := ElderFigure.new()
	var p := Game.prof()
	fig.set_avatar(str(p["avatar"]), int(p.get("outfit", 0)))
	UI.full(fig)
	fig.set_pose({"face": "happy"})
	stage.add_child(fig)
	stage.set_meta("fig", fig)
	var v := UI.vbox(16)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	v.add_child(UI.label("Pos %d selesai" % (index + 1), "Caption"))
	v.add_child(UI.label("%s tuntas!" % st["name"], "H1", true))
	var lr := UI.hbox(14)
	var leaf_icons: Array = []
	for i in 3:
		var ic := Icon.new("leaf", Game.LEAF if i < leaves else Color(Game.INK_SOFT, 0.2), 92)
		ic.pivot_offset = Vector2(46, 46)
		lr.add_child(ic)
		leaf_icons.append(ic)
	v.add_child(lr)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 10)
	chips.add_theme_constant_override("v_separation", 10)
	chips.add_child(UI.chip("%d dari 3 daun" % leaves, "ChipLeaf", "leaf", Game.LEAF_DARK))
	if _has_moves():
		chips.add_child(UI.chip("%d/%d gerakan" % [moves_done, (st["moves"] as Array).size()], "ChipSun", "run", Game.INK))
	if str(st["challenge"]["type"]) in ["quiz", "market"]:
		chips.add_child(UI.chip("Tantangan %d/%d benar" % [ch_score, ch_total], "Chip", "quiz", Game.TEAL))
	else:
		chips.add_child(UI.chip("Tantangan selesai", "Chip", "check", Game.TEAL))
	v.add_child(chips)
	if index + 1 < Data.STATIONS.size() and opened and before <= index + 1:
		var np := UI.panel("Leaf")
		np.add_child(UI.label("Pos berikutnya terbuka: %s di %s." % [Data.STATIONS[index + 1]["name"], Data.STATIONS[index + 1]["place"]], "H3", true))
		v.add_child(np)
	elif index == Data.STATIONS.size() - 1:
		var np2 := UI.panel("Note")
		np2.add_child(UI.label("Selamat! Semua pos sudah dijelajahi. Lanjutkan latihan rutin bersama kader di Posyandu.", "H3", true))
		v.add_child(np2)
	var row := UI.hbox(14)
	var again := UI.btn("Ulangi Pos Ini", "Button", "replay", 84, 30)
	again.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.replace_with("station", {"index": index}))
	row.add_child(again)
	row.add_child(UI.spacer())
	var go := UI.btn("Kembali ke Peta", "PrimaryButton", "next", 84, 32)
	go.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.stack.pop_back()
		if not main.stack.is_empty() and main.stack.back()["name"] == "map":
			main.stack.pop_back()
		main.go("map", {"opened": index + 1} if opened else {}))
	row.add_child(go)
	v.add_child(row)
	_focus = go
	reveal([stage, v.get_child(0), v.get_child(1), chips, row], 0.05)
	# animasi perayaan
	for i in 3:
		var ic2: Icon = leaf_icons[i]
		ic2.scale = Vector2(0.15, 0.15)
		var tw := create_tween()
		tw.tween_interval(0.35 + i * 0.32)
		tw.tween_property(ic2, "scale", Vector2(1.15, 1.15), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(ic2, "scale", Vector2.ONE, 0.15)
		if i < leaves:
			tw.tween_callback(func() -> void:
				Sfx.play("leaf", 1.0 + i * 0.12)
				FX.burst(self, ic2.get_global_rect().get_center() - get_global_rect().position, 10))
	Sfx.play("cheer" if leaves >= 3 else "success")
	await get_tree().create_timer(0.4).timeout
	if is_instance_valid(panel):
		FX.confetti(self, 80 if leaves >= 3 else 40)
	Game.speak("%s tuntas! Mbah mendapat %d daun." % [st["name"], leaves])


func _process(_delta: float) -> void:
	if phase == 3 and _body.get_child_count() > 0:
		var panel := _body.get_child(0)
		if panel and panel.get_child_count() > 0:
			var h := panel.get_child(0)
			if h and h.get_child_count() > 0 and h.get_child(0).has_meta("fig"):
				var fig: ElderFigure = h.get_child(0).get_meta("fig")
				var t := Time.get_ticks_msec() / 1000.0
				var up := fmod(t, 1.2) < 0.6
				fig.set_pose({"la": 160.0 if up else 120.0, "ra": 160.0 if up else 120.0, "le": 10.0, "re": 10.0, "by": -14.0 if up else 0.0, "face": "happy"})
