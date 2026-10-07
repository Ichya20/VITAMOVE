extends Screen
## Pengaturan: ukuran tulisan, tempo, animasi, suara, suara pemandu, dan data.

var _focus: Control


func build() -> void:
	scene_bg("", "siang", 0.6)
	make_content(26)
	var v := UI.vbox(14)
	content.add_child(v)
	v.add_child(header("Pengaturan", "Atur sesuai kenyamanan Mbah"))
	var sc := UI.scroll_v()
	v.add_child(sc)
	var row := UI.hbox(18)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(UI.xmargin(4, 4, 12, 12))
	sc.get_child(0).add_child(row)
	var left := UI.vbox(16)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var right := UI.vbox(16)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)

	var tp := _section(left, "Ukuran tulisan", "book", Game.TEAL_MID)
	var opts: Array = []
	for i in 3:
		opts.append(Game.TEXT_SCALE_NAMES[i])
	var on_scale := func(i: int) -> void:
		Game.set_setting("text_scale", i)
		main.refresh()
	tp.add_child(_segmented(opts, int(Game.settings["text_scale"]), on_scale, [20, 23, 26]))
	var prev := UI.panel("Inset")
	prev.add_child(UI.label("Contoh: Tarik napas pelan, lalu hembuskan.", "Body", true))
	tp.add_child(prev)

	var tm := _section(left, "Tempo latihan", "run", Game.TERRA)
	tm.add_child(_segmented(["Lambat", "Sedang"], int(Game.settings["tempo"]), func(i: int) -> void: Game.set_setting("tempo", i)))
	tm.add_child(UI.label("Tempo lambat disarankan untuk awal latihan.", "Small", true))

	var mo := _section(left, "Animasi", "sun", Game.SAFFRON_DARK)
	mo.add_child(_segmented(["Penuh", "Dikurangi"], 1 if bool(Game.settings["reduce_motion"]) else 0, func(i: int) -> void: Game.set_setting("reduce_motion", i == 1)))
	mo.add_child(UI.label("Pilih \"Dikurangi\" bila gerakan layar terasa mengganggu atau membuat pusing.", "Small", true))

	var dp := _section(left, "Data peserta", "user", Color("5b6b78"))
	dp.add_child(UI.label("Data tersimpan hanya di perangkat ini. Peserta: %d · sesi bersama: %d." % [Game.profiles.size(), Game.group_log.size()], "Body", true))
	var dr := UI.hbox(10)
	var manage := UI.btn("Kelola Peserta", "TealButton", "people", 72, 28)
	manage.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("profiles"))
	dr.add_child(manage)
	var reset := UI.btn("Hapus Data", "DangerButton", "close", 72, 26)
	reset.pressed.connect(_confirm_reset)
	dr.add_child(reset)
	dp.add_child(dr)

	var sp := _section(right, "Suara", "speaker", Game.LEAF)
	sp.add_child(_slider("Musik gamelan", "music"))
	sp.add_child(_slider("Efek suara & hitungan", "sfx"))

	var vp := _section(right, "Suara pemandu", "speaker", Game.TEAL_MID)
	var avail := Game.tts_available()
	vp.add_child(_segmented(["Nyala", "Mati"], 0 if bool(Game.settings["tts"]) else 1, func(i: int) -> void:
		Game.set_setting("tts", i == 0)
		if i == 1:
			Game.stop_speech()))
	var test := UI.btn("Coba suara", "SunButton", "play", 72, 28)
	test.pressed.connect(func() -> void:
		if not Game.speak("Sugeng enjang, Mbah. Ayo bergerak bersama VITAMOVE.", true):
			main.show_dialog("Suara belum tersedia", "HP ini belum memiliki suara Bahasa Indonesia. Buka Pengaturan HP > Aksesibilitas > Keluaran Text-to-Speech, lalu unduh Bahasa Indonesia.", [{"text": "Mengerti", "style": "PrimaryButton", "is_cancel": true}], "speaker"))
	vp.add_child(test)
	var status := UI.panel("Leaf" if avail else "Note")
	status.add_child(UI.label("Suara Bahasa Indonesia tersedia." if avail else "Suara Bahasa Indonesia belum terdeteksi. Teks tetap tampil di layar.", "Small", true))
	vp.add_child(status)
	vp.add_child(_slider("Kecepatan bicara", "tts_rate", 0.6, 1.3))
	reveal([left, right])


func default_focus() -> Control:
	return _focus


func _section(parent: Control, title: String, icon: String, col: Color) -> VBoxContainer:
	var p := UI.panel("Card")
	parent.add_child(p)
	var v := UI.vbox(12)
	p.add_child(v)
	var h := UI.hbox(12)
	h.add_child(UI.badge(icon, col, 44))
	h.add_child(UI.label(title, "H3"))
	v.add_child(h)
	return v


func _segmented(options: Array, current: int, cb: Callable, sizes: Array = []) -> HBoxContainer:
	var h := UI.hbox(10)
	var cards: Array = []
	for i in options.size():
		var t := TapCard.new()
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.selected = i == current
		t.set("accessibility_name", str(options[i]))
		var l := UI.label(str(options[i]), "H3", false, HORIZONTAL_ALIGNMENT_CENTER)
		if sizes.size() > i:
			l.add_theme_font_size_override("font_size", int(sizes[i]))
		t.add_child(l)
		var idx := i
		t.pressed.connect(func() -> void:
			Sfx.play("pop")
			for c in cards:
				(c as TapCard).selected = c == t
			cb.call(idx))
		h.add_child(t)
		cards.append(t)
		if _focus == null:
			_focus = t
	return h


func _slider(title: String, key: String, mn: float = 0.0, mx: float = 1.0) -> Control:
	var v := UI.vbox(4)
	var h := UI.hbox(10)
	h.add_child(UI.label(title, "Body"))
	h.add_child(UI.spacer())
	var val := UI.label("", "H3")
	h.add_child(val)
	v.add_child(h)
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = 0.05
	s.value = float(Game.settings[key])
	s.custom_minimum_size = Vector2(0, 58)
	s.set("accessibility_name", title)
	var fmt := func(x: float) -> String:
		if key == "tts_rate":
			return "%.2fx" % x
		return "%d%%" % int(round(x * 100.0))
	val.text = fmt.call(s.value)
	s.value_changed.connect(func(x: float) -> void:
		val.text = fmt.call(x)
		Game.settings[key] = x
		Game.save_data()
		Sfx.apply_volume())
	s.drag_ended.connect(func(_c: bool) -> void: Sfx.play("tap"))
	v.add_child(s)
	return v


func _confirm_reset() -> void:
	Sfx.play("tap")
	main.show_dialog("Hapus semua data?", "Semua peserta, daun, catatan latihan, hasil kuis, dan riwayat sesi bersama akan terhapus dari perangkat ini.", [
		{"text": "Batal", "style": "Button", "is_cancel": true},
		{"text": "Hapus semua", "style": "DangerButton", "cb": _do_reset},
	], "close", "danger")


func _do_reset() -> void:
	Game.reset_all()
	main.home()
