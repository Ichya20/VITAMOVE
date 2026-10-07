extends Screen
## Pengaturan: ukuran teks, suara, suara pemandu, tempo, dan pengelolaan data.

var _focus: Control


func build() -> void:
	soft_bg("", "siang", 0.7)
	make_content(26)
	var v := UI.vbox(12)
	content.add_child(v)
	v.add_child(top_bar("Pengaturan"))
	var sc := UI.scroll_v()
	v.add_child(sc)
	var row := UI.hbox(16)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(row)

	var left := UI.vbox(14)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var right := UI.vbox(14)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)

	# ukuran teks
	var tp := _section(left, "Ukuran tulisan", "book")
	var tr := UI.hbox(10)
	for i in 3:
		var b := UI.btn(Game.TEXT_SCALE_NAMES[i], "ChoiceButton", "", 76)
		b.toggle_mode = true
		b.button_pressed = int(Game.settings["text_scale"]) == i
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", int(22 * Game.TEXT_SCALES[i]))
		b.pressed.connect(func() -> void:
			Sfx.play("tap")
			Game.set_setting("text_scale", i)
			main.refresh())
		tr.add_child(b)
		if _focus == null:
			_focus = b
	tp.add_child(tr)
	tp.add_child(UI.label("Contoh: Tarik napas pelan, lalu hembuskan.", "Body", true))

	# tempo
	var tm := _section(left, "Tempo latihan", "run")
	var tmr := UI.hbox(10)
	for i in 2:
		var b := UI.btn(["Lambat", "Sedang"][i], "ChoiceButton", "", 76)
		b.toggle_mode = true
		b.button_pressed = int(Game.settings["tempo"]) == i
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			Sfx.play("tap")
			Game.set_setting("tempo", i)
			for s in tmr.get_children():
				(s as Button).set_pressed_no_signal(s == b))
		tmr.add_child(b)
	tm.add_child(tmr)
	tm.add_child(UI.label("Tempo lambat disarankan untuk awal latihan.", "Small", true))

	# data
	var dp := _section(left, "Data peserta", "user")
	dp.add_child(UI.label("Data tersimpan hanya di perangkat ini. Peserta: %d, sesi bersama: %d." % [Game.profiles.size(), Game.group_log.size()], "Body", true))
	var dr := UI.hbox(10)
	var manage := UI.btn("Kelola Peserta", "TealButton", "people", 76, 30)
	manage.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("profiles"))
	dr.add_child(manage)
	var reset := UI.btn("Hapus Data", "DangerButton", "close", 76, 28)
	reset.pressed.connect(_confirm_reset)
	dr.add_child(reset)
	dp.add_child(dr)

	# suara
	var sp := _section(right, "Suara", "speaker")
	sp.add_child(_slider("Musik gamelan", "music"))
	sp.add_child(_slider("Efek suara & hitungan", "sfx"))

	var vp := _section(right, "Suara pemandu", "speaker")
	var avail := Game.tts_available()
	var tg := UI.hbox(10)
	for i in 2:
		var on := i == 0
		var b := UI.btn("Nyala" if on else "Mati", "ChoiceButton", "", 72)
		b.toggle_mode = true
		b.button_pressed = bool(Game.settings["tts"]) == on
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			Sfx.play("tap")
			Game.set_setting("tts", on)
			if not on:
				Game.stop_speech()
			for s in tg.get_children():
				(s as Button).set_pressed_no_signal(s == b))
		tg.add_child(b)
	vp.add_child(tg)
	var test := UI.btn("Coba suara", "SunButton", "play", 72, 28)
	test.pressed.connect(func() -> void:
		if not Game.speak("Sugeng enjang, Mbah. Ayo bergerak bersama VITAMOVE.", true):
			main.show_dialog("Suara belum tersedia", "Perangkat ini belum memiliki suara Bahasa Indonesia. Buka Pengaturan HP > Aksesibilitas > Keluaran Text-to-Speech, lalu unduh Bahasa Indonesia.", [{"text": "Mengerti", "style": "PrimaryButton", "is_cancel": true}], "speaker"))
	vp.add_child(test)
	var status := UI.label("Suara Bahasa Indonesia tersedia." if avail else "Suara Bahasa Indonesia belum terdeteksi di perangkat ini. Teks tetap tampil di layar.", "Small", true)
	vp.add_child(status)
	vp.add_child(_slider("Kecepatan bicara", "tts_rate", 0.6, 1.3))


func default_focus() -> Control:
	return _focus


func _section(parent: Control, title: String, icon: String) -> VBoxContainer:
	var p := UI.panel("Card")
	parent.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	var h := UI.hbox(10)
	h.add_child(Icon.new(icon, Game.TERRA, 34))
	h.add_child(UI.label(title, "H3"))
	v.add_child(h)
	return v


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
	s.custom_minimum_size = Vector2(0, 56)
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
	s.drag_ended.connect(func(_c: bool) -> void:
		Game.set_setting(key, s.value)
		Sfx.play("tap"))
	v.add_child(s)
	return v


func _confirm_reset() -> void:
	Sfx.play("tap")
	main.show_dialog("Hapus semua data?", "Semua peserta, daun, catatan latihan, hasil kuis, dan riwayat sesi bersama akan terhapus dari perangkat ini.", [
		{"text": "Batal", "style": "Button", "is_cancel": true},
		{"text": "Hapus semua", "style": "DangerButton", "cb": _do_reset},
	], "close")


func _do_reset() -> void:
	Game.reset_all()
	main.home()
