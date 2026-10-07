extends Screen
## Satu pos materi: LIHAT (kartu materi) -> IKUTI (demonstrasi gerakan) -> COBA (tantangan) -> hasil.

const PLACE_KIND := ["balai", "rumah", "sawah", "pematang", "bambu", "sumur", "pasar", "kali", "posyandu"]
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
var learned := false

var _body: Control
var _chips: HBoxContainer
var _focus: Control
var _demo: MoveDemo
var _count_label: Label
var _cue_label: Label
var _rep_label: Label
var _play_btn: Button
var _after_row: HBoxContainer
var _ctrl_row: HBoxContainer
var _prog: ProgressBar


func build() -> void:
	index = int(params.get("index", 0))
	st = Data.STATIONS[index]
	capacity = int(Game.prof()["capacity"])
	soft_bg(PLACE_KIND[index], "pagi", 0.58)
	make_content(26)
	var v := UI.vbox(12)
	content.add_child(v)
	var bar := top_bar("Pos %d · %s" % [index + 1, st["name"]])
	v.add_child(bar)
	_chips = UI.hbox(10)
	bar.add_child(_chips)
	bar.move_child(_chips, 2)
	_body = UI.vbox(12)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_body)
	_go_phase(0)


func _has_moves() -> bool:
	return not (st["moves"] as Array).is_empty()


func _refresh_chips() -> void:
	for c in _chips.get_children():
		c.queue_free()
	for i in PHASES.size():
		if i == 1 and not _has_moves():
			continue
		var p := UI.panel("Note" if i == phase else ("Leaf" if i < phase else "Pill"))
		var h := UI.hbox(6)
		p.add_child(h)
		if i < phase:
			h.add_child(Icon.new("check", Game.LEAF, 24))
		var l := UI.label(PHASES[i], "H3")
		l.add_theme_font_size_override("font_size", Game.fs(22))
		h.add_child(l)
		_chips.add_child(p)


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
	_refresh_chips()
	match p:
		0: _render_card()
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
		main.show_dialog("Keluar dari pos ini?", "Kemajuan di pos ini belum disimpan. Mbah bisa mengulang kapan saja.", [
			{"text": "Lanjutkan di sini", "style": "Button", "is_cancel": true},
			{"text": "Ke peta", "style": "PrimaryButton", "cb": main.back},
		], "home")
		return true
	return false


func on_leave() -> void:
	Sfx.duck(false)
	super.on_leave()


func default_focus() -> Control:
	return _focus


# ================================================================== LIHAT

func _render_card() -> void:
	var cards: Array = st["cards"]
	var c: Dictionary = cards[card_i]
	var row := UI.hbox(20)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(row)

	# Jali + intro di kiri
	var left := UI.vbox(8)
	left.custom_minimum_size = Vector2(250, 0)
	row.add_child(left)
	var j := Mascot.new()
	j.custom_minimum_size = Vector2(150, 150)
	j.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	j.talking = card_i == 0
	left.add_child(j)
	var bub := UI.panel("Pill")
	var bl := UI.label(str(st["intro"]) if card_i == 0 else "Kartu %d dari %d. Baca pelan-pelan, ya." % [card_i + 1, cards.size()], "Body", true)
	bl.add_theme_font_size_override("font_size", Game.fs(23))
	bub.add_child(bl)
	left.add_child(bub)

	var card := UI.panel("Card")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(card)
	var ch := UI.hbox(26)
	card.add_child(ch)
	var art := Control.new()
	art.custom_minimum_size = Vector2(230, 230)
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var col := Color(str(st["color"]))
	art.draw.connect(func() -> void:
		var cc := art.size / 2.0
		art.draw_circle(cc + Vector2(6, 8), 112, Color(Game.TEAL, 0.15), true, -1.0, true)
		art.draw_circle(cc, 112, col.lightened(0.55), true, -1.0, true)
		art.draw_circle(cc, 112, col, false, 6, true))
	var ic := Icon.new(str(c["i"]), col.darkened(0.1), 130)
	ic.position = Vector2(50, 50)
	ic.size = Vector2(130, 130)
	art.add_child(ic)
	ch.add_child(art)
	var tv := UI.vbox(14)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	ch.add_child(tv)
	var dots := UI.hbox(8)
	for i in cards.size():
		var d := Icon.new("leaf", Game.LEAF if i <= card_i else Color(Game.INK_SOFT, 0.25), 26)
		dots.add_child(d)
	tv.add_child(dots)
	var t := UI.label(str(c["t"]), "H1", true)
	tv.add_child(t)
	var x := UI.label(str(c["x"]), "Body", true)
	x.add_theme_font_size_override("font_size", Game.fs(29))
	tv.add_child(x)

	var nav := UI.hbox(14)
	_body.add_child(nav)
	var prev := UI.btn("Sebelumnya", "Button", "prev", 84, 30)
	prev.disabled = card_i == 0
	prev.pressed.connect(func() -> void:
		Sfx.play("tap")
		card_i = maxi(0, card_i - 1)
		_go_phase(0))
	nav.add_child(prev)
	var listen := UI.btn("Dengarkan", "SunButton", "speaker", 84, 32)
	listen.pressed.connect(func() -> void:
		if not Game.speak(str(c["t"]) + ". " + str(c["x"]), true):
			_toast("Suara pemandu belum tersedia di perangkat ini. Minta kader membacakan, atau pasang suara Bahasa Indonesia di pengaturan Text-to-Speech HP."))
	nav.add_child(listen)
	nav.add_child(UI.spacer())
	var last := card_i >= cards.size() - 1
	var nxt_text := "Berikutnya"
	if last:
		nxt_text = "Ikuti Gerakan" if _has_moves() else "Coba Tantangan"
	var nxt := UI.btn(nxt_text, "PrimaryButton", "next", 88, 34)
	nxt.pressed.connect(func() -> void:
		Sfx.play("tap")
		if not last:
			card_i += 1
			_go_phase(0)
		else:
			learned = true
			_go_phase(1 if _has_moves() else 2))
	nav.add_child(nxt)
	_focus = nxt
	if bool(Game.settings["tts"]):
		Game.speak((str(st["intro"]) + ". " if card_i == 0 else "") + str(c["t"]) + ". " + str(c["x"]))


func _toast(text: String) -> void:
	main.show_dialog("Info", text, [{"text": "Mengerti", "style": "PrimaryButton", "is_cancel": true}], "info")


# ================================================================== IKUTI

func _start_practice() -> void:
	var p := Game.prof()
	if str(p.get("last_check", "")) != Game.today_str():
		_safety_q1()
	else:
		_render_move()


func _safety_q1() -> void:
	main.show_dialog("Cek Badan Dulu", "Hari ini, apakah Mbah merasa nyeri dada, sesak napas, pusing, atau sedang demam?", [
		{"text": "Ya, ada", "style": "DangerButton", "cb": _safety_stop},
		{"text": "Tidak ada", "style": "TealButton", "cb": _safety_q2},
	], "shield")


func _safety_q2() -> void:
	main.show_dialog("Cek Badan Dulu", "Apakah ada nyeri sendi yang tajam, bengkak baru, atau Mbah baru saja terjatuh?", [
		{"text": "Ya, ada", "style": "DangerButton", "cb": _safety_stop},
		{"text": "Tidak ada", "style": "TealButton", "cb": _safety_ok},
	], "shield")


func _safety_ok() -> void:
	Game.profiles[Game.current]["last_check"] = Game.today_str()
	Game.save_data()
	main.show_dialog("Siap berlatih!", "Siapkan kursi kokoh di dekat Mbah dan segelas air putih. Bergerak sesuai kemampuan, ya.", [
		{"text": "Mulai", "style": "PrimaryButton", "icon": "play", "is_cancel": true, "cb": _render_move},
	], "chair")


func _safety_stop() -> void:
	main.show_dialog("Istirahat dulu hari ini", "Beri tahu kader atau tenaga kesehatan tentang keluhan Mbah. Mbah tetap bisa membaca materi dan menjawab tantangan.", [
		{"text": "Ke peta", "style": "Button", "cb": main.back},
		{"text": "Lanjut ke tantangan", "style": "PrimaryButton", "is_cancel": true, "cb": _go_phase.bind(2)},
	], "stop")


func _render_move() -> void:
	if phase != 1:
		return
	for c in _body.get_children():
		c.queue_free()
	Sfx.duck(true)
	var mid: String = st["moves"][move_i]
	var m: Dictionary = Data.MOVES[mid]
	var row := UI.hbox(18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(row)

	# ---- panggung demonstrasi
	var stage := UI.panel("Card")
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_stretch_ratio = 1.15
	row.add_child(stage)
	var sv := Control.new()
	sv.clip_contents = true
	stage.add_child(sv)
	var floor_bg := ColorRect.new()
	floor_bg.color = Color("f6ead2")
	floor_bg.anchor_top = 0.78
	floor_bg.anchor_right = 1.0
	floor_bg.anchor_bottom = 1.0
	floor_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sv.add_child(floor_bg)
	_demo = MoveDemo.new()
	_demo.anchor_left = 0.0
	_demo.anchor_right = 0.72
	_demo.anchor_top = 0.04
	_demo.anchor_bottom = 0.82
	sv.add_child(_demo)
	_demo.setup(mid, capacity, str(Game.prof()["avatar"]))
	_demo.beat.connect(_on_beat)
	_demo.rep_changed.connect(_on_rep)
	_demo.segment_changed.connect(_on_segment)
	_demo.finished.connect(_on_move_finished)

	_count_label = UI.label("", "Counter", false, HORIZONTAL_ALIGNMENT_CENTER)
	_count_label.anchor_left = 0.68
	_count_label.anchor_right = 1.0
	_count_label.anchor_top = 0.08
	_count_label.anchor_bottom = 0.5
	sv.add_child(_count_label)
	_rep_label = UI.label("", "H3", true, HORIZONTAL_ALIGNMENT_CENTER)
	_rep_label.add_theme_font_size_override("font_size", Game.fs(22))
	_rep_label.anchor_left = 0.66
	_rep_label.anchor_right = 1.0
	_rep_label.anchor_top = 0.5
	_rep_label.anchor_bottom = 0.7
	sv.add_child(_rep_label)
	var cue_panel := UI.panel("Dark")
	cue_panel.anchor_left = 0.03
	cue_panel.anchor_right = 0.97
	cue_panel.anchor_top = 1.0
	cue_panel.anchor_bottom = 1.0
	cue_panel.offset_top = -88
	cue_panel.offset_bottom = -8
	sv.add_child(cue_panel)
	_cue_label = UI.label("Tekan Mulai, lalu ikuti hitungannya.", "OnDark", true, HORIZONTAL_ALIGNMENT_CENTER)
	_cue_label.add_theme_font_size_override("font_size", Game.fs(27))
	_cue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cue_panel.add_child(_cue_label)
	_prog = ProgressBar.new()
	_prog.show_percentage = false
	_prog.max_value = 1.0
	_prog.custom_minimum_size = Vector2(0, 14)
	_prog.anchor_right = 1.0
	_prog.offset_bottom = 14
	var fill := StyleBoxFlat.new()
	fill.bg_color = Game.SAFFRON
	fill.set_corner_radius_all(7)
	var pbg := StyleBoxFlat.new()
	pbg.bg_color = Color(Game.TEAL, 0.12)
	pbg.set_corner_radius_all(7)
	_prog.add_theme_stylebox_override("fill", fill)
	_prog.add_theme_stylebox_override("background", pbg)
	sv.add_child(_prog)

	# ---- panel petunjuk
	var info := UI.panel("Cream")
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var iv := UI.vbox(10)
	info.add_child(iv)
	iv.add_child(UI.label("Gerakan %d dari %d" % [move_i + 1, (st["moves"] as Array).size()], "Small"))
	iv.add_child(UI.label(str(m["name"]), "H2", true))
	var note := str(_demo.variant.get("note", ""))
	if note != "":
		var np := UI.panel("Note")
		var nh := UI.hbox(8)
		nh.add_child(Icon.new("chair", Color("8a6212"), 30))
		var nl := UI.label(note, "Body", true)
		nl.add_theme_font_size_override("font_size", Game.fs(22))
		nh.add_child(nl)
		np.add_child(nh)
		iv.add_child(np)
	var steps: Array = m["steps"]
	for i in steps.size():
		var sh := UI.hbox(10)
		var num := Label.new()
		num.text = str(i + 1)
		num.add_theme_font_override("font", Game.font_display)
		num.add_theme_font_size_override("font_size", Game.fs(28))
		num.add_theme_color_override("font_color", Game.TERRA)
		num.custom_minimum_size.x = 26
		sh.add_child(num)
		var sl := UI.label(str(steps[i]), "Body", true)
		sl.add_theme_font_size_override("font_size", Game.fs(24))
		sh.add_child(sl)
		iv.add_child(sh)
	var sp := UI.hbox(8)
	sp.add_child(Icon.new("shield", Game.TERRA_DARK, 28))
	var sfl := UI.label(str(m["safety"]), "Small", true)
	sfl.add_theme_color_override("font_color", Game.TERRA_DARK)
	sp.add_child(sfl)
	iv.add_child(sp)
	iv.add_child(UI.spacer(false, true))

	_ctrl_row = UI.hbox(12)
	_play_btn = UI.btn("Mulai", "PrimaryButton", "play", 88, 34)
	_play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play_btn.pressed.connect(_toggle_play)
	_ctrl_row.add_child(_play_btn)
	var again := UI.btn("", "Button", "replay", 88, 36)
	again.tooltip_text = "Ulangi dari awal"
	again.set("accessibility_name", "Ulangi dari awal")
	again.pressed.connect(func() -> void:
		Sfx.play("tap")
		_after_row.visible = false
		_ctrl_row.visible = true
		_demo.restart()
		UI.set_btn_text(_play_btn, "Jeda")
		(_play_btn.get_meta("icon") as Icon).set_kind("pause"))
	_ctrl_row.add_child(again)
	var tempo := UI.btn("Lambat" if int(Game.settings["tempo"]) == 0 else "Sedang", "ChoiceButton", "", 88)
	tempo.tooltip_text = "Ubah tempo"
	tempo.pressed.connect(func() -> void:
		Sfx.play("tap")
		Game.set_setting("tempo", 1 - int(Game.settings["tempo"]))
		tempo.text = "Lambat" if int(Game.settings["tempo"]) == 0 else "Sedang")
	_ctrl_row.add_child(tempo)
	iv.add_child(_ctrl_row)

	_after_row = UI.hbox(12)
	_after_row.visible = false
	var ok := UI.btn("Saya bisa", "PrimaryButton", "check", 88, 34)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.pressed.connect(_next_move)
	_after_row.add_child(ok)
	var heavy := UI.btn("Terasa berat", "Button", "", 88)
	heavy.pressed.connect(_too_heavy)
	_after_row.add_child(heavy)
	iv.add_child(_after_row)
	_focus = _play_btn
	Game.speak(str(m["name"]) + ". " + " ".join(PackedStringArray(steps)))


func _toggle_play() -> void:
	Sfx.play("tap")
	if _demo.playing:
		_demo.pause()
		UI.set_btn_text(_play_btn, "Lanjut")
		(_play_btn.get_meta("icon") as Icon).set_kind("play")
		_cue_label.text = "Dijeda. Tekan Lanjut bila siap."
	else:
		Game.stop_speech()
		_demo.start(true)
		UI.set_btn_text(_play_btn, "Jeda")
		(_play_btn.get_meta("icon") as Icon).set_kind("pause")


func _on_beat(c: int, _cue: String) -> void:
	if c < 0:
		_count_label.text = str(-c)
		_cue_label.text = "Siap..."
	else:
		_count_label.text = str(c)
	_count_label.pivot_offset = _count_label.size / 2.0
	_count_label.scale = Vector2(1.25, 1.25)
	var tw := create_tween()
	tw.tween_property(_count_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _prog:
		_prog.value = _demo.progress()


func _on_rep(r: int, total: int) -> void:
	_rep_label.text = "Ulangan %d dari %d" % [r, total]


func _on_segment(cue: String) -> void:
	_cue_label.text = cue


func _on_move_finished() -> void:
	Sfx.play("success")
	_prog.value = 1.0
	_count_label.text = ""
	_cue_label.text = "Selesai! Bagaimana rasanya?"
	_ctrl_row.visible = false
	_after_row.visible = true
	moves_done = maxi(moves_done, move_i + 1)
	_focus = _after_row.get_child(0)
	_focus.call_deferred("grab_focus")
	Game.speak("Selesai. Bagus sekali!")


func _too_heavy() -> void:
	Sfx.play("tap")
	if capacity > 0:
		main.show_dialog("Tidak apa-apa", "Gerakan bisa dibuat lebih ringan. Coba versi \"%s\", atau lewati gerakan ini dan istirahat sejenak." % Game.CAPACITY_NAMES[capacity - 1], [
			{"text": "Lewati", "style": "Button", "cb": _next_move},
			{"text": "Coba lebih ringan", "style": "PrimaryButton", "is_cancel": true, "cb": _lighter},
		], "heart")
	else:
		main.show_dialog("Tidak apa-apa", "Kurangi jumlah ulangan atau lakukan gerakan lebih kecil. Bila terasa nyeri, berhenti dan beri tahu kader atau tenaga kesehatan.", [
			{"text": "Lanjut", "style": "PrimaryButton", "is_cancel": true, "cb": _next_move},
		], "heart")


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
	var v := UI.vbox(18)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	v.add_child(UI.label("Semua gerakan selesai! Bagaimana rasanya badan Mbah sekarang?", "H1", true, HORIZONTAL_ALIGNMENT_CENTER))
	var row := UI.hbox(22)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var opts := [["face_happy", "Segar", Color("8cc063")], ["face_ok", "Biasa saja", Color("f2b134")], ["face_tired", "Lelah", Color("e8a07a")]]
	for o in opts:
		var b := Button.new()
		b.theme_type_variation = "ChoiceButton"
		b.custom_minimum_size = Vector2(230, 220)
		b.set("accessibility_name", o[1])
		var bv := UI.vbox(8)
		bv.alignment = BoxContainer.ALIGNMENT_CENTER
		bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.full(bv)
		b.add_child(bv)
		var ic := Icon.new(o[0], o[2], 120)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		bv.add_child(ic)
		bv.add_child(UI.label(o[1], "H2", false, HORIZONTAL_ALIGNMENT_CENTER))
		var val: String = o[1]
		b.pressed.connect(func() -> void:
			Sfx.play("tap")
			feel = val
			if val == "Lelah":
				main.show_dialog("Istirahat sejenak", "Duduk dan minum air putih. Rasa lelah ringan itu wajar. Bila lelah berlebihan, nyeri, atau pusing, beri tahu kader atau tenaga kesehatan.", [
					{"text": "Mengerti", "style": "PrimaryButton", "is_cancel": true, "cb": _go_phase.bind(2)},
				], "water")
			else:
				_go_phase(2))
		row.add_child(b)
		if _focus == null:
			_focus = b
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
			q.setup(ch["q"], "Tantangan: %s" % st["name"])
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
			b.setup(str(Game.prof()["avatar"]))
			b.done.connect(_on_challenge_done)
		"traffic":
			var tr := TrafficChallenge.new()
			panel.add_child(tr)
			tr.setup()
			tr.done.connect(_on_challenge_done)


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
	var fig := ElderFigure.new()
	fig.set_avatar(str(Game.prof()["avatar"]))
	fig.custom_minimum_size = Vector2(260, 0)
	fig.set_pose({"la": 150.0, "ra": 150.0, "le": 20.0, "re": 20.0, "heel": 0.0})
	h.add_child(fig)
	var v := UI.vbox(16)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	v.add_child(UI.label("Pos %s selesai!" % st["name"], "H1", true))
	var lr := UI.hbox(14)
	for i in 3:
		var ic := Icon.new("leaf", Game.LEAF if i < leaves else Color(Game.INK_SOFT, 0.2), 86)
		ic.pivot_offset = Vector2(43, 43)
		ic.scale = Vector2(0.2, 0.2)
		lr.add_child(ic)
		var tw := create_tween()
		tw.tween_interval(0.25 + i * 0.3)
		tw.tween_property(ic, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if i < leaves:
			tw.tween_callback(func() -> void: Sfx.play("leaf"))
	v.add_child(lr)
	var lines := PackedStringArray()
	lines.append("Daun yang didapat: %d dari 3." % leaves)
	if _has_moves():
		lines.append("Gerakan diikuti: %d dari %d." % [moves_done, (st["moves"] as Array).size()])
	lines.append("Tantangan: %d dari %d benar." % [ch_score, ch_total] if str(st["challenge"]["type"]) in ["quiz", "market"] else "Tantangan selesai.")
	v.add_child(UI.label("\n".join(lines), "Body", true))
	if index + 1 < Data.STATIONS.size() and opened and before <= index + 1:
		var np := UI.panel("Leaf")
		var nl := UI.label("Pos berikutnya terbuka: %s di %s." % [Data.STATIONS[index + 1]["name"], Data.STATIONS[index + 1]["place"]], "H3", true)
		np.add_child(nl)
		v.add_child(np)
	elif index == Data.STATIONS.size() - 1:
		var np2 := UI.panel("Note")
		np2.add_child(UI.label("Selamat! Semua pos sudah dijelajahi. Lanjutkan latihan rutin bersama kader di Posyandu.", "H3", true))
		v.add_child(np2)
	var row := UI.hbox(14)
	var again := UI.btn("Ulangi Pos Ini", "Button", "replay", 88, 32)
	again.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.replace_with("station", {"index": index}))
	row.add_child(again)
	row.add_child(UI.spacer())
	var go := UI.btn("Kembali ke Peta", "PrimaryButton", "next", 88, 34)
	go.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.stack.pop_back()
		if not main.stack.is_empty() and main.stack.back()["name"] == "map":
			main.stack.pop_back()
		main.go("map", {"opened": index + 1} if opened else {}))
	row.add_child(go)
	v.add_child(row)
	_focus = go
	Sfx.play("unlock" if opened else "success")
	Game.speak("Pos %s selesai! Mbah mendapat %d daun." % [st["name"], leaves])
