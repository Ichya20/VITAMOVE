extends Screen
## Mode Kader "Sesi Bersama": pilih rangkaian, catat kehadiran, lalu putar latihan
## berurutan di layar untuk kelompok lansia di Posyandu.

const ORDER := ["napas", "bahu", "tengok", "jalan", "geser", "satukaki", "jinjit", "raih", "samping", "silang", "dudukberdiri", "botol", "kakisamping", "angkatbarang", "raihrak", "sandal", "napaspelan", "leher", "goyang", "peluk"]
const TPL_ICONS := ["sun", "run", "chair"]

var selected: Array = []
var template_i := 0
var capacity := 1
var attendance := 10
var avatar := "kader"
var playing_i := 0
var completed := 0
var _started_at := 0

var _body: VBoxContainer
var _focus: Control
var _move_cards := {}
var _tpl_cards: Array = []
var _cap_cards: Array = []
var _guide_cards: Array = []
var _att_label: Label
var _sum_label: Label
var _demo: MoveDemo
var _ring: CountRing
var _cue: Label
var _title: Label
var _sub: Label
var _play: Button
var _queue: VBoxContainer
var _resting := false
var _rest_left := 0
var _rest_panel: PanelContainer
var _rest_label: Label
var _stage: Control


func build() -> void:
	scene_bg("posyandu", "pagi", 0.45)
	make_content(24)
	_body = UI.vbox(14)
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
	_move_cards.clear()
	_tpl_cards.clear()
	_cap_cards.clear()
	_guide_cards.clear()


# ================================================================== SETUP

func _pick_template(i: int, sync: bool = true) -> void:
	template_i = i
	var t: Dictionary = Data.SESSION_TEMPLATES[i]
	selected = (t["moves"] as Array).duplicate()
	if t.has("capacity"):
		capacity = int(t["capacity"])
	if sync:
		_sync_setup()


func _section(parent: Control, num: String, title: String) -> void:
	var h := UI.hbox(10)
	var b := Control.new()
	b.custom_minimum_size = Vector2(34, 34)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.draw.connect(func() -> void:
		b.draw_circle(Vector2(17, 17), 16, Game.TERRA, true, -1.0, true)
		var f := Game.font_display
		var tw := f.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		b.draw_string(f, Vector2(17 - tw / 2.0, 25), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE))
	h.add_child(b)
	h.add_child(UI.label(title, "H3"))
	parent.add_child(h)


func _render_setup() -> void:
	_clear()
	_demo = null
	_body.add_child(header("Sesi Bersama", "Mode kader · latihan kelompok"))
	var row := UI.hbox(18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(row)

	# kiri: rangkaian
	var left := UI.panel("Card")
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.45
	row.add_child(left)
	var lv := UI.vbox(10)
	left.add_child(lv)
	_section(lv, "1", "Pilih rangkaian latihan")
	var tr := UI.hbox(12)
	for i in Data.SESSION_TEMPLATES.size():
		var t: Dictionary = Data.SESSION_TEMPLATES[i]
		var card := TapCard.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.set("accessibility_name", str(t["name"]))
		var ch := UI.hbox(10)
		ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(ch)
		ch.add_child(UI.badge(TPL_ICONS[i], [Game.SAFFRON_DARK, Game.TERRA, Game.TEAL_MID][i], 42))
		var cv := UI.vbox(0)
		cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tn := UI.label(str(t["name"]), "H3")
		tn.add_theme_font_size_override("font_size", Game.fs_cap(22))
		cv.add_child(tn)
		var td := UI.label(str(t["desc"]).split(".")[0], "Small")
		td.add_theme_font_size_override("font_size", Game.fs_cap(17))
		cv.add_child(td)
		ch.add_child(cv)
		var ii := i
		card.pressed.connect(func() -> void:
			Sfx.play("pop")
			_pick_template(ii))
		tr.add_child(card)
		_tpl_cards.append(card)
	lv.add_child(tr)
	_sum_label = UI.label("", "Small", true)
	lv.add_child(_sum_label)
	var sc := UI.scroll_v()
	lv.add_child(sc)
	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	sc.add_child(UI.xmargin(2, 2, 10, 8))
	sc.get_child(0).add_child(flow)
	for id in ORDER:
		var mc := TapCard.new()
		mc.toggle = true
		mc.set("accessibility_name", str(Data.MOVES[id]["name"]))
		var mh := UI.hbox(8)
		mh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mc.add_child(mh)
		var tick := Icon.new("check", Game.LEAF, 24)
		tick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mh.add_child(tick)
		var ml := UI.label(str(Data.MOVES[id]["name"]), "H3")
		ml.add_theme_font_size_override("font_size", Game.fs_cap(20))
		mh.add_child(ml)
		mc.set_meta("tick", tick)
		var mid: String = id
		mc.pressed.connect(func() -> void:
			Sfx.play("tap")
			if mc.selected and not selected.has(mid):
				selected.append(mid)
				selected.sort_custom(func(a, c): return ORDER.find(a) < ORDER.find(c))
			elif not mc.selected:
				selected.erase(mid)
			_sync_moves())
		flow.add_child(mc)
		_move_cards[id] = mc

	# kanan: peserta
	var right := UI.panel("Cream")
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var rsc := UI.scroll_v()
	right.add_child(rsc)
	var rv := UI.vbox(10)
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rsc.add_child(rv)
	_section(rv, "2", "Cara berlatih kelompok")
	var cr := UI.hbox(8)
	for i in 3:
		var cc := TapCard.new()
		cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cc.set("accessibility_name", Game.CAPACITY_NAMES[i])
		var cl := UI.label(Game.CAPACITY_SHORT[i], "H3", false, HORIZONTAL_ALIGNMENT_CENTER)
		cl.add_theme_font_size_override("font_size", Game.fs_cap(19))
		cc.add_child(cl)
		var ci := i
		cc.pressed.connect(func() -> void:
			Sfx.play("pop")
			capacity = ci
			_sync_setup())
		cr.add_child(cc)
		_cap_cards.append(cc)
	rv.add_child(cr)
	_section(rv, "3", "Jumlah peserta hadir")
	var ar := UI.hbox(12)
	var minus := UI.icon_btn("minus", "Kurangi peserta", "TealButton", 70)
	minus.pressed.connect(func() -> void:
		Sfx.play("tap")
		attendance = maxi(1, attendance - 1)
		_att_label.text = "%d orang" % attendance)
	ar.add_child(minus)
	_att_label = UI.label("%d orang" % attendance, "Big", false, HORIZONTAL_ALIGNMENT_CENTER)
	_att_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ar.add_child(_att_label)
	var plus := UI.icon_btn("plus", "Tambah peserta", "TealButton", 70)
	plus.pressed.connect(func() -> void:
		Sfx.play("tap")
		attendance = mini(99, attendance + 1)
		_att_label.text = "%d orang" % attendance)
	ar.add_child(plus)
	rv.add_child(ar)
	_section(rv, "4", "Pemandu di layar")
	var gr := UI.hbox(8)
	for a in [["kader", "Bu Kader"], ["putri", "Mbah Putri"], ["kakung", "Mbah Kakung"]]:
		var gc := TapCard.new()
		gc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gc.set("accessibility_name", a[1])
		var gv := UI.vbox(0)
		gv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gc.add_child(gv)
		var fig := ElderFigure.new()
		fig.set_avatar(a[0])
		fig.custom_minimum_size = Vector2(70, 92)
		fig.show_ground = false
		fig.idle = false
		gv.add_child(fig)
		var gl := UI.label(a[1], "Small", false, HORIZONTAL_ALIGNMENT_CENTER)
		gl.add_theme_font_size_override("font_size", Game.fs_cap(16))
		gv.add_child(gl)
		var av: String = a[0]
		gc.pressed.connect(func() -> void:
			Sfx.play("pop")
			avatar = av
			_sync_setup())
		gr.add_child(gc)
		_guide_cards.append([gc, av])
	rv.add_child(gr)
	var start := UI.btn("Mulai Sesi", "PrimaryButton", "play", 88, 36)
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.pressed.connect(_start_session)
	rv.add_child(start)
	var hist := "Belum ada sesi bersama tercatat."
	if not Game.group_log.is_empty():
		var g: Dictionary = Game.group_log.back()
		hist = "Sesi terakhir %s: %d peserta, %d gerakan. Total %d sesi." % [Game.date_label(str(g.get("date", ""))), int(g.get("attendance", 0)), int(g.get("moves", 0)), Game.group_log.size()]
	rv.add_child(UI.label(hist, "Small", true))
	_focus = start
	_sync_setup()
	reveal([left, right])


func _sync_setup() -> void:
	for i in _tpl_cards.size():
		(_tpl_cards[i] as TapCard).selected = i == template_i
	for i in _cap_cards.size():
		(_cap_cards[i] as TapCard).selected = i == capacity
	for g in _guide_cards:
		(g[0] as TapCard).selected = g[1] == avatar
	_sync_moves()


func _sync_moves() -> void:
	for id in _move_cards.keys():
		var mc: TapCard = _move_cards[id]
		mc.selected = selected.has(id)
		(mc.get_meta("tick") as Icon).visible = mc.selected
	if _sum_label == null:
		return
	var secs := 0.0
	for id in selected:
		var m: Dictionary = Data.MOVES[id]
		var b := 0
		for x in m["beats"]:
			b += int(x)
		secs += b * int(m["reps"]) * Game.beat_seconds() + 8.0
	_sum_label.text = "%d gerakan dipilih · sekitar %d menit. Ketuk gerakan untuk menambah atau mengurangi." % [selected.size(), int(ceil(secs / 60.0))]


# ================================================================== MEMUTAR SESI

func _start_session() -> void:
	if selected.is_empty():
		Sfx.play("soft_no")
		main.toast("Pilih minimal satu gerakan untuk memulai sesi.", "info")
		return
	Sfx.play("success")
	playing_i = 0
	completed = 0
	_started_at = int(Time.get_unix_time_from_system())
	_render_player()


func _render_player() -> void:
	_clear()
	Sfx.duck(true)
	var row := UI.hbox(18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(row)
	var stage := UI.panel("Card")
	stage.add_theme_stylebox_override("panel", Game.soft_shadow(Game.sb(Game.PAPER, 28, 0, 0), 0.15, 18, 8))
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_stretch_ratio = 1.6
	row.add_child(stage)
	_stage = Control.new()
	_stage.clip_contents = true
	stage.add_child(_stage)
	var mini_bg := Landscape.new()
	mini_bg.horizon = 0.5
	mini_bg.mountain_x = 0.35
	UI.full(mini_bg)
	mini_bg.resized.connect(func() -> void:
		mini_bg.places = [{"kind": "posyandu", "x": mini_bg.size.x * 0.82, "y": mini_bg.size.y * 0.66, "s": 0.6}])
	_stage.add_child(mini_bg)
	var vv := ColorRect.new()
	vv.color = Color(Game.CREAM, 0.3)
	vv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full(vv)
	_stage.add_child(vv)
	var mat := Decor.new("tikar")
	mat.anchor_left = 0.1
	mat.anchor_right = 0.9
	mat.anchor_top = 0.76
	mat.anchor_bottom = 0.92
	_stage.add_child(mat)
	_demo = MoveDemo.new()
	_demo.anchor_left = 0.1
	_demo.anchor_right = 0.9
	_demo.anchor_top = 0.04
	_demo.anchor_bottom = 0.88
	_stage.add_child(_demo)
	_demo.beat.connect(_on_beat)
	_demo.segment_changed.connect(func(c: String) -> void: _cue.text = c)
	_demo.rep_changed.connect(func(r: int, t: int) -> void:
		_ring.reps = t
		_ring.rep_now = r - 1
		_ring.queue_redraw())
	_demo.finished.connect(_on_finished)
	_rest_panel = UI.panel("Dark")
	_rest_panel.visible = false
	_rest_label = UI.label("", "OnDark", true, HORIZONTAL_ALIGNMENT_CENTER)
	_rest_label.add_theme_font_size_override("font_size", Game.fs(32))
	_rest_label.custom_minimum_size = Vector2(520, 0)
	_rest_panel.add_child(_rest_label)
	_stage.add_child(_rest_panel)

	var side := UI.panel("Cream")
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(side)
	var v := UI.vbox(10)
	side.add_child(v)
	_sub = UI.label("", "Caption")
	v.add_child(_sub)
	_title = UI.label("", "H1", true)
	v.add_child(_title)
	var mid := UI.hbox(12)
	_ring = CountRing.new()
	_ring.custom_minimum_size = Vector2(170, 200)
	mid.add_child(_ring)
	_queue = UI.vbox(6)
	_queue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(_queue)
	v.add_child(mid)
	var cp := UI.panel("Dark")
	_cue = UI.label("", "OnDark", true, HORIZONTAL_ALIGNMENT_CENTER)
	_cue.add_theme_font_size_override("font_size", Game.fs(27))
	cp.add_child(_cue)
	v.add_child(cp)
	v.add_child(UI.spacer(false, true))
	var r1 := UI.hbox(10)
	_play = UI.btn("Jeda", "PrimaryButton", "pause", 84, 32)
	_play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play.pressed.connect(_toggle)
	r1.add_child(_play)
	var rep := UI.icon_btn("replay", "Ulangi gerakan", "Button", 84)
	rep.pressed.connect(func() -> void:
		Sfx.play("tap")
		_load_move(playing_i))
	r1.add_child(rep)
	var skip := UI.icon_btn("skip", "Lewati gerakan", "Button", 84)
	skip.pressed.connect(func() -> void:
		Sfx.play("tap")
		_advance())
	r1.add_child(skip)
	v.add_child(r1)
	var end := UI.btn("Akhiri Sesi", "DangerButton", "stop", 72, 28)
	end.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	end.pressed.connect(_confirm_end)
	v.add_child(end)
	_focus = _play
	reveal([stage, side])
	_load_move(0)


func _refresh_queue() -> void:
	for c in _queue.get_children():
		c.queue_free()
	_queue.add_child(UI.label("Urutan gerakan", "Caption"))
	for k in range(playing_i, mini(playing_i + 3, selected.size())):
		var is_now := k == playing_i
		var p := UI.panel("ChipSun" if is_now else "Inset")
		var h := UI.hbox(8)
		p.add_child(h)
		h.add_child(Icon.new("play" if is_now else "next", Game.TERRA if is_now else Game.INK_SOFT, 20))
		var l := UI.label("%d. %s" % [k + 1, Data.MOVES[selected[k]]["name"]], "H3" if is_now else "Small", true)
		l.add_theme_font_size_override("font_size", Game.fs_cap(19))
		l.custom_minimum_size.x = 120
		h.add_child(l)
		_queue.add_child(p)


func _load_move(i: int) -> void:
	playing_i = i
	_resting = false
	_rest_panel.visible = false
	var id: String = selected[i]
	_demo.setup(id, capacity, avatar)
	_ring.reps = _demo.reps
	_ring.rep_now = 0
	_ring.progress = 0.0
	_ring.set_count("%dx" % _demo.reps, "ulangan")
	_title.text = str(Data.MOVES[id]["name"])
	_sub.text = "Gerakan %d dari %d" % [i + 1, selected.size()]
	_cue.text = str(Data.MOVES[id]["steps"][0])
	UI.set_btn_text(_play, "Jeda")
	UI.set_btn_icon(_play, "pause")
	_refresh_queue()
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
		UI.set_btn_icon(_play, "play")
	else:
		_demo.start(true)
		UI.set_btn_text(_play, "Jeda")
		UI.set_btn_icon(_play, "pause")


func _on_beat(c: int, _cue_t: String) -> void:
	if c < 0:
		_ring.set_count(str(-c), "siap")
		_cue.text = "Siap..."
	else:
		_ring.set_count(str(c), "")
	_ring.progress = _demo.progress()


func _on_finished() -> void:
	completed += 1
	Sfx.play("success")
	FX.burst(_stage, Vector2(_stage.size.x / 2.0, _stage.size.y * 0.45), 18)
	if playing_i + 1 >= selected.size():
		_finish_session()
		return
	_resting = true
	_rest_left = 5
	var nxt: String = selected[playing_i + 1]
	_rest_panel.visible = true
	UI.set_btn_text(_play, "Lanjut sekarang")
	UI.set_btn_icon(_play, "next")
	_ring.set_count("OK", "bagus")
	_cue.text = "Istirahat sejenak"
	_rest_tick(nxt)


func _rest_tick(nxt: String) -> void:
	if not _resting or not is_instance_valid(_rest_label):
		return
	_rest_label.text = "Tarik napas, istirahat sejenak.\nBerikutnya: %s\n%d" % [Data.MOVES[nxt]["name"], _rest_left]
	_rest_panel.reset_size()
	_rest_panel.position = _stage.size / 2.0 - _rest_panel.size / 2.0
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
	], "stop", "terra")


func _resume() -> void:
	if _demo and not _resting:
		_demo.start(false)
		UI.set_btn_text(_play, "Jeda")
		UI.set_btn_icon(_play, "pause")


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
	Sfx.play("cheer")
	var p := UI.panel("Cream")
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(p)
	var h := UI.hbox(26)
	p.add_child(h)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(300, 0)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(stage)
	var rays := Decor.new("rays")
	UI.full(rays)
	stage.add_child(rays)
	var fig := ElderFigure.new()
	fig.set_avatar(avatar)
	UI.full(fig)
	fig.set_pose({"la": 150.0, "ra": 150.0, "le": 20.0, "re": 20.0, "face": "happy"})
	stage.add_child(fig)
	var v := UI.vbox(14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label("Sesi bersama", "Caption"))
	v.add_child(UI.label("Latihan kelompok selesai!", "H1", true))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 10)
	chips.add_theme_constant_override("v_separation", 10)
	chips.add_child(UI.chip("%d peserta hadir" % attendance, "ChipSun", "people", Game.INK))
	chips.add_child(UI.chip("%d/%d gerakan" % [completed, selected.size()], "ChipLeaf", "run", Game.LEAF_DARK))
	chips.add_child(UI.chip("Sekitar %d menit" % mins, "Chip", "calendar", Game.TEAL))
	chips.add_child(UI.chip(Game.CAPACITY_NAMES[capacity], "ChipTerra", "chair", Game.TERRA_DARK))
	v.add_child(chips)
	var np := UI.panel("Note")
	np.add_child(UI.label("Catatan kader: tulis juga di daftar hadir Posyandu, dan tanyakan apakah ada peserta yang merasa pusing atau nyeri.", "Body", true))
	v.add_child(np)
	var row := UI.hbox(12)
	var again := UI.btn("Sesi Baru", "Button", "replay", 80, 28)
	again.pressed.connect(func() -> void:
		Sfx.play("tap")
		_render_setup())
	row.add_child(again)
	var home := UI.btn("Beranda", "PrimaryButton", "home", 80, 28)
	home.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.home())
	row.add_child(home)
	v.add_child(row)
	home.call_deferred("grab_focus")
	reveal([stage, v])
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(p):
		FX.confetti(self, 70)
	Game.speak("Sesi bersama selesai. Terima kasih semuanya!")
