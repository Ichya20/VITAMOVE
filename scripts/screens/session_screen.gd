extends Screen
## Mode Kader "Sesi Bersama": pilih rangkaian, catat kehadiran, lalu putar latihan
## berurutan di layar besar untuk kelompok lansia di Posyandu.

var selected: Array = []
var template_i := 0
var capacity := 1
var attendance := 10
var avatar := "putri"
var playing_i := 0
var completed := 0
var _started_at := 0

var _body: VBoxContainer
var _focus: Control
var _move_buttons := {}
var _tpl_buttons: Array[Button] = []
var _cap_buttons: Array[Button] = []
var _att_label: Label
var _sum_label: Label
var _demo: MoveDemo
var _count: Label
var _cue: Label
var _title: Label
var _sub: Label
var _rep: Label
var _play: Button
var _rest_timer: SceneTreeTimer
var _resting := false
var _rest_left := 0
var _rest_panel: PanelContainer
var _rest_label: Label


func build() -> void:
	soft_bg("posyandu", "pagi", 0.62)
	make_content(24)
	_body = UI.vbox(12)
	content.add_child(_body)
	_pick_template(0, false)
	_render_setup()


func default_focus() -> Control:
	return _focus


func on_back() -> bool:
	if _demo:
		_confirm_end()
		return true
	return false


func on_leave() -> void:
	Sfx.duck(false)
	super.on_leave()


func _clear() -> void:
	for c in _body.get_children():
		c.queue_free()
	_focus = null
	_move_buttons.clear()
	_tpl_buttons.clear()
	_cap_buttons.clear()


# ================================================================== SETUP

func _pick_template(i: int, rerender: bool = true) -> void:
	template_i = i
	var t: Dictionary = Data.SESSION_TEMPLATES[i]
	selected = (t["moves"] as Array).duplicate()
	if t.has("capacity"):
		capacity = int(t["capacity"])
	if rerender:
		_sync_setup()


func _render_setup() -> void:
	_clear()
	_demo = null
	_body.add_child(top_bar("Sesi Bersama · Mode Kader"))
	var row := UI.hbox(16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(row)

	# kiri: rangkaian
	var left := UI.panel("Card")
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.5
	row.add_child(left)
	var lv := UI.vbox(10)
	left.add_child(lv)
	lv.add_child(UI.label("1. Pilih rangkaian latihan", "H3"))
	var tr := UI.hbox(10)
	for i in Data.SESSION_TEMPLATES.size():
		var t: Dictionary = Data.SESSION_TEMPLATES[i]
		var b := UI.btn(str(t["name"]), "ChoiceButton", "", 66)
		b.add_theme_font_size_override("font_size", Game.fs(21))
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = str(t["desc"])
		b.pressed.connect(func() -> void:
			Sfx.play("tap")
			_pick_template(i))
		tr.add_child(b)
		_tpl_buttons.append(b)
	lv.add_child(tr)
	_sum_label = UI.label("", "Small", true)
	lv.add_child(_sum_label)
	var sc := UI.scroll_v()
	lv.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(grid)
	var order := ["napas", "bahu", "tengok", "jalan", "geser", "satukaki", "jinjit", "raih", "samping", "silang", "dudukberdiri", "botol", "kakisamping", "angkatbarang", "raihrak", "sandal", "napaspelan", "leher", "goyang", "peluk"]
	for id in order:
		var b := UI.btn(str(Data.MOVES[id]["name"]), "ChoiceButton", "", 64)
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", Game.fs(20))
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var mid: String = id
		b.toggled.connect(func(on: bool) -> void:
			if on and not selected.has(mid):
				selected.append(mid)
				selected.sort_custom(func(a, c): return order.find(a) < order.find(c))
			elif not on:
				selected.erase(mid)
			_sync_summary())
		grid.add_child(b)
		_move_buttons[id] = b

	# kanan: peserta
	var right := UI.panel("Cream")
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var rv := UI.vbox(8)
	right.add_child(rv)
	rv.add_child(UI.label("2. Cara berlatih kelompok", "H3"))
	var cr := UI.vbox(8)
	for i in 3:
		var b := UI.btn(Game.CAPACITY_NAMES[i], "ChoiceButton", "", 56)
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", Game.fs(22))
		b.pressed.connect(func() -> void:
			Sfx.play("tap")
			capacity = i
			_sync_setup())
		cr.add_child(b)
		_cap_buttons.append(b)
	rv.add_child(cr)
	rv.add_child(UI.label("3. Jumlah peserta hadir", "H3"))
	var ar := UI.hbox(12)
	var minus := UI.btn("", "TealButton", "minus", 68, 30)
	minus.set("accessibility_name", "Kurangi peserta")
	minus.pressed.connect(func() -> void:
		Sfx.play("tap")
		attendance = maxi(1, attendance - 1)
		_att_label.text = "%d orang" % attendance)
	ar.add_child(minus)
	_att_label = UI.label("%d orang" % attendance, "Big", false, HORIZONTAL_ALIGNMENT_CENTER)
	_att_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ar.add_child(_att_label)
	var plus := UI.btn("", "TealButton", "plus", 68, 30)
	plus.set("accessibility_name", "Tambah peserta")
	plus.pressed.connect(func() -> void:
		Sfx.play("tap")
		attendance = mini(99, attendance + 1)
		_att_label.text = "%d orang" % attendance)
	ar.add_child(plus)
	rv.add_child(ar)
	var avr := UI.hbox(10)
	avr.add_child(UI.label("Pemandu", "Body"))
	for a in [["putri", "Putri"], ["kakung", "Kakung"]]:
		var b := UI.btn(a[1], "ChoiceButton", "", 58)
		b.toggle_mode = true
		b.button_pressed = avatar == a[0]
		b.add_theme_font_size_override("font_size", Game.fs(20))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var av: String = a[0]
		b.pressed.connect(func() -> void:
			Sfx.play("tap")
			avatar = av
			for s in avr.get_children():
				if s is Button:
					(s as Button).set_pressed_no_signal(s == b))
		avr.add_child(b)
	rv.add_child(avr)
	rv.add_child(UI.spacer(false, true))
	var start := UI.btn("Mulai Sesi", "PrimaryButton", "play", 84, 36)
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.pressed.connect(_start_session)
	rv.add_child(start)
	var hist := "Belum ada sesi bersama tercatat."
	if not Game.group_log.is_empty():
		var g: Dictionary = Game.group_log.back()
		hist = "Sesi terakhir: %s, %d peserta, %d gerakan. Total %d sesi." % [Game.date_label(str(g.get("date", ""))), int(g.get("attendance", 0)), int(g.get("moves", 0)), Game.group_log.size()]
	rv.add_child(UI.label(hist, "Small", true))
	_focus = start
	_sync_setup()


func _sync_setup() -> void:
	for i in _tpl_buttons.size():
		_tpl_buttons[i].set_pressed_no_signal(i == template_i)
	for i in _cap_buttons.size():
		_cap_buttons[i].set_pressed_no_signal(i == capacity)
	for id in _move_buttons.keys():
		(_move_buttons[id] as Button).set_pressed_no_signal(selected.has(id))
	_sync_summary()


func _sync_summary() -> void:
	if _sum_label == null:
		return
	var secs := 0.0
	for id in selected:
		var m: Dictionary = Data.MOVES[id]
		var b := 0
		for x in m["beats"]:
			b += int(x)
		secs += b * int(m["reps"]) * Game.beat_seconds() + 8.0
	_sum_label.text = "%d gerakan dipilih · perkiraan %d menit. Ketuk gerakan untuk menambah atau mengurangi." % [selected.size(), int(ceil(secs / 60.0))]


# ================================================================== MEMUTAR SESI

func _start_session() -> void:
	if selected.is_empty():
		Sfx.play("soft_no")
		main.show_dialog("Belum ada gerakan", "Pilih minimal satu gerakan untuk memulai sesi.", [{"text": "Mengerti", "style": "PrimaryButton", "is_cancel": true}], "info")
		return
	Sfx.play("success")
	playing_i = 0
	completed = 0
	_started_at = int(Time.get_unix_time_from_system())
	_render_player()


func _render_player() -> void:
	_clear()
	Sfx.duck(true)
	var row := UI.hbox(16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(row)
	var stage := UI.panel("Card")
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_stretch_ratio = 1.5
	row.add_child(stage)
	var sv := Control.new()
	sv.clip_contents = true
	stage.add_child(sv)
	var floor_bg := ColorRect.new()
	floor_bg.color = Color("f6ead2")
	floor_bg.anchor_top = 0.8
	floor_bg.anchor_right = 1.0
	floor_bg.anchor_bottom = 1.0
	sv.add_child(floor_bg)
	_demo = MoveDemo.new()
	UI.full(_demo)
	sv.add_child(_demo)
	_demo.beat.connect(_on_beat)
	_demo.segment_changed.connect(func(c: String) -> void: _cue.text = c)
	_demo.rep_changed.connect(func(r: int, t: int) -> void: _rep.text = "Ulangan %d dari %d" % [r, t])
	_demo.finished.connect(_on_finished)
	_rest_panel = UI.panel("Dark")
	_rest_panel.set_anchors_preset(Control.PRESET_CENTER)
	_rest_panel.visible = false
	_rest_label = UI.label("", "OnDark", true, HORIZONTAL_ALIGNMENT_CENTER)
	_rest_label.add_theme_font_size_override("font_size", Game.fs(34))
	_rest_label.custom_minimum_size = Vector2(520, 0)
	_rest_panel.add_child(_rest_label)
	sv.add_child(_rest_panel)

	var side := UI.panel("Cream")
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(side)
	var v := UI.vbox(10)
	side.add_child(v)
	_sub = UI.label("", "H3")
	v.add_child(_sub)
	_title = UI.label("", "H1", true)
	v.add_child(_title)
	_rep = UI.label("", "Body")
	v.add_child(_rep)
	_count = UI.label("", "Counter", false, HORIZONTAL_ALIGNMENT_CENTER)
	_count.custom_minimum_size.y = 150
	v.add_child(_count)
	var cp := UI.panel("Dark")
	_cue = UI.label("", "OnDark", true, HORIZONTAL_ALIGNMENT_CENTER)
	_cue.add_theme_font_size_override("font_size", Game.fs(30))
	cp.add_child(_cue)
	v.add_child(cp)
	v.add_child(UI.spacer(false, true))
	var r1 := UI.hbox(10)
	_play = UI.btn("Jeda", "PrimaryButton", "pause", 88, 34)
	_play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play.pressed.connect(_toggle)
	r1.add_child(_play)
	var rep := UI.btn("", "Button", "replay", 88, 36)
	rep.set("accessibility_name", "Ulangi gerakan")
	rep.tooltip_text = "Ulangi gerakan"
	rep.pressed.connect(func() -> void:
		Sfx.play("tap")
		_load_move(playing_i))
	r1.add_child(rep)
	var skip := UI.btn("", "Button", "skip", 88, 36)
	skip.set("accessibility_name", "Lewati gerakan")
	skip.tooltip_text = "Lewati gerakan"
	skip.pressed.connect(func() -> void:
		Sfx.play("tap")
		_advance())
	r1.add_child(skip)
	v.add_child(r1)
	var end := UI.btn("Akhiri Sesi", "DangerButton", "stop", 76, 30)
	end.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	end.pressed.connect(_confirm_end)
	v.add_child(end)
	_focus = _play
	_load_move(0)


func _load_move(i: int) -> void:
	playing_i = i
	_resting = false
	_rest_panel.visible = false
	var id: String = selected[i]
	_demo.setup(id, capacity, avatar)
	_title.text = str(Data.MOVES[id]["name"])
	_sub.text = "Gerakan %d dari %d" % [i + 1, selected.size()]
	_rep.text = ""
	_count.text = ""
	_cue.text = str(Data.MOVES[id]["steps"][0])
	UI.set_btn_text(_play, "Jeda")
	(_play.get_meta("icon") as Icon).set_kind("pause")
	Game.speak(str(Data.MOVES[id]["name"]))
	_demo.start(true)


func _toggle() -> void:
	Sfx.play("tap")
	if _resting:
		_resting = false
		_advance()
		return
	if _demo.playing:
		_demo.pause()
		UI.set_btn_text(_play, "Lanjut")
		(_play.get_meta("icon") as Icon).set_kind("play")
	else:
		_demo.start(true)
		UI.set_btn_text(_play, "Jeda")
		(_play.get_meta("icon") as Icon).set_kind("pause")


func _on_beat(c: int, _cue_t: String) -> void:
	_count.text = str(-c) if c < 0 else str(c)
	if c < 0:
		_cue.text = "Siap..."
	_count.pivot_offset = _count.size / 2.0
	_count.scale = Vector2(1.2, 1.2)
	create_tween().tween_property(_count, "scale", Vector2.ONE, 0.25)


func _on_finished() -> void:
	completed += 1
	Sfx.play("success")
	if playing_i + 1 >= selected.size():
		_finish_session()
		return
	_resting = true
	_rest_left = 5
	var nxt: String = selected[playing_i + 1]
	_rest_panel.visible = true
	UI.set_btn_text(_play, "Lanjut sekarang")
	(_play.get_meta("icon") as Icon).set_kind("next")
	_count.text = ""
	_cue.text = "Istirahat sejenak"
	_rest_tick(nxt)


func _rest_tick(nxt: String) -> void:
	if not _resting or not is_instance_valid(_rest_label):
		return
	_rest_label.text = "Tarik napas, istirahat sejenak.\nBerikutnya: %s\n%d" % [Data.MOVES[nxt]["name"], _rest_left]
	_rest_panel.reset_size()
	_rest_panel.position = (_rest_panel.get_parent() as Control).size / 2.0 - _rest_panel.size / 2.0
	if _rest_left <= 0:
		_resting = false
		_advance()
		return
	_rest_left -= 1
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		if is_instance_valid(self) and _resting:
			_rest_tick(nxt))


func _advance() -> void:
	if playing_i + 1 >= selected.size():
		_finish_session()
	else:
		_load_move(playing_i + 1)


func _confirm_end() -> void:
	if _demo:
		_demo.pause()
	main.show_dialog("Akhiri sesi sekarang?", "%d dari %d gerakan sudah selesai. Sesi tetap dicatat." % [completed, selected.size()], [
		{"text": "Lanjutkan sesi", "style": "Button", "is_cancel": true, "cb": _resume},
		{"text": "Akhiri", "style": "PrimaryButton", "cb": _finish_session},
	], "stop")


func _resume() -> void:
	if _demo and not _resting:
		_demo.start(false)
		UI.set_btn_text(_play, "Jeda")
		(_play.get_meta("icon") as Icon).set_kind("pause")


func _finish_session() -> void:
	_resting = false
	Sfx.duck(false)
	var mins := maxi(1, int(round((Time.get_unix_time_from_system() - _started_at) / 60.0)))
	Game.log_group({
		"template": Data.SESSION_TEMPLATES[template_i]["name"], "moves": completed, "planned": selected.size(),
		"attendance": attendance, "capacity": capacity, "minutes": mins,
	})
	if Game.has_profile():
		Game.log_activity({"type": "sesi", "name": "Sesi Bersama Posyandu", "moves": completed, "score": "", "feel": "", "leaves": 0})
	_clear()
	_demo = null
	Sfx.play("leaf")
	var p := UI.panel("Cream")
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(p)
	var h := UI.hbox(24)
	p.add_child(h)
	var fig := ElderFigure.new()
	fig.set_avatar(avatar)
	fig.custom_minimum_size = Vector2(240, 0)
	fig.set_pose({"la": 150.0, "ra": 150.0, "le": 20.0, "re": 20.0})
	h.add_child(fig)
	var v := UI.vbox(14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label("Sesi bersama selesai!", "H1"))
	v.add_child(UI.label("Peserta hadir: %d orang\nGerakan selesai: %d dari %d\nDurasi: sekitar %d menit\nCara berlatih: %s" % [attendance, completed, selected.size(), mins, Game.CAPACITY_NAMES[capacity]], "H3", true))
	var np := UI.panel("Note")
	np.add_child(UI.label("Catatan kader: tulis juga di daftar hadir Posyandu, dan tanyakan apakah ada peserta yang merasa pusing atau nyeri.", "Body", true))
	v.add_child(np)
	var row := UI.hbox(12)
	var again := UI.btn("Sesi Baru", "Button", "replay", 84, 30)
	again.pressed.connect(func() -> void:
		Sfx.play("tap")
		_render_setup())
	row.add_child(again)
	var home := UI.btn("Beranda", "PrimaryButton", "home", 84, 30)
	home.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.home())
	row.add_child(home)
	v.add_child(row)
	home.call_deferred("grab_focus")
	Game.speak("Sesi bersama selesai. Terima kasih semuanya!")
