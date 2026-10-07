extends Screen
## Catatan aktivitas: rangkaian hari aktif, kemajuan pos, hasil kuis, dan riwayat latihan.

var _focus: Control


func build() -> void:
	soft_bg("", "pagi", 0.7)
	make_content(26)
	var p := Game.prof()
	var v := UI.vbox(12)
	content.add_child(v)
	v.add_child(top_bar("Catatan · %s" % p["name"]))
	var row := UI.hbox(16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(row)

	# ---------------- kolom kiri: ringkasan
	var lsc := UI.scroll_v()
	row.add_child(lsc)
	var left := UI.vbox(12)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lsc.add_child(left)
	var stats := UI.hbox(12)
	left.add_child(stats)
	var sessions := 0
	for e in p["log"]:
		if str(e.get("type", "")) == "pos":
			sessions += 1
	stats.add_child(_stat("sun", str(Game.streak(p)), "hari beruntun", Game.SAFFRON))
	stats.add_child(_stat("run", str(sessions), "pos diselesaikan", Game.TERRA))
	stats.add_child(_stat("leaf", "%d/%d" % [Game.total_leaves(p), Data.STATIONS.size() * 3], "daun", Game.LEAF))

	var cal := UI.panel("Card")
	var cv := UI.vbox(8)
	cal.add_child(cv)
	cv.add_child(UI.label("14 hari terakhir", "H3"))
	var days := Game.days_active(p, 14)
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	cv.add_child(grid)
	var names := ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"]
	for d in days:
		var parts: PackedStringArray = str(d["date"]).split("-")
		var unix := Time.get_unix_time_from_datetime_string(str(d["date"]) + "T12:00:00")
		var wd := int(Time.get_datetime_dict_from_unix_time(unix)["weekday"])
		var cell := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(14)
		sb.bg_color = Game.LEAF if d["active"] else Color(Game.TEAL, 0.08)
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		cell.add_theme_stylebox_override("panel", sb)
		cell.custom_minimum_size = Vector2(70, 54)
		cell.set("accessibility_name", "%s %s: %s" % [names[wd], d["date"], "aktif" if d["active"] else "belum"])
		var cl := UI.label("%s\n%s" % [names[wd], parts[2] if parts.size() == 3 else "?"], "Small", false, HORIZONTAL_ALIGNMENT_CENTER)
		cl.add_theme_color_override("font_color", Color.WHITE if d["active"] else Game.INK_SOFT)
		cl.add_theme_font_size_override("font_size", Game.fs(18))
		cell.add_child(cl)
		grid.add_child(cell)
	var legend := UI.hbox(8)
	legend.add_child(Icon.new("leaf", Game.LEAF, 22))
	legend.add_child(UI.label("Hijau = hari Mbah berlatih", "Small"))
	cv.add_child(legend)
	left.add_child(cal)

	# hasil kuis pengetahuan
	var kp := UI.panel("Cream")
	var kv := UI.vbox(10)
	kp.add_child(kv)
	kv.add_child(UI.label("Kuis Pengetahuan", "H3"))
	var kr := UI.hbox(14)
	kv.add_child(kr)
	var pre := int(p["pre"])
	var post := int(p["post"])
	kr.add_child(_score_box("Awal", pre, str(p.get("pre_date", ""))))
	kr.add_child(_score_box("Akhir", post, str(p.get("post_date", ""))))
	var imp := UI.label("", "H3", true)
	imp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if pre >= 0 and post >= 0:
		var pct := (float(post - pre) / maxf(1.0, pre)) * 100.0
		imp.text = "Peningkatan: %+d%%" % int(round(pct))
		imp.add_theme_color_override("font_color", Game.LEAF if post >= pre else Game.TERRA_DARK)
	else:
		imp.text = "Kerjakan kuis awal sebelum belajar dan kuis akhir setelah semua pos."
		imp.add_theme_font_size_override("font_size", Game.fs(21))
	kr.add_child(imp)
	var kb := UI.vbox(10)
	var bpre := UI.btn("Kuis Awal" if pre < 0 else "Ulangi Kuis Awal", "TealButton" if pre < 0 else "Button", "quiz", 76, 30)
	bpre.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("test", {"kind": "pre"}))
	kb.add_child(bpre)
	var bpost := UI.btn("Kuis Akhir", "PrimaryButton" if pre >= 0 else "Button", "quiz", 76, 30)
	bpost.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("test", {"kind": "post"}))
	kb.add_child(bpost)
	kr.add_child(kb)
	left.add_child(kp)
	_focus = bpre if pre < 0 else bpost

	# ---------------- kolom kanan: riwayat
	var right := UI.panel("Card")
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 0.85
	row.add_child(right)
	var rv := UI.vbox(10)
	right.add_child(rv)
	rv.add_child(UI.label("Riwayat Latihan", "H3"))
	var sc := UI.scroll_v()
	rv.add_child(sc)
	var list := UI.vbox(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	var logs: Array = p["log"]
	if logs.is_empty():
		var empty := UI.vbox(10)
		empty.add_child(Mascot.new())
		empty.add_child(UI.label("Belum ada catatan. Selesaikan satu pos di peta, nanti catatannya muncul di sini.", "Body", true))
		var go := UI.btn("Buka Peta", "PrimaryButton", "next", 76, 30)
		go.pressed.connect(func() -> void:
			Sfx.play("tap")
			main.go("map"))
		empty.add_child(go)
		list.add_child(empty)
	for i in range(logs.size() - 1, maxi(-1, logs.size() - 41), -1):
		list.add_child(_log_row(logs[i]))


func default_focus() -> Control:
	return _focus


func _stat(icon: String, big: String, small: String, col: Color) -> Control:
	var p := UI.panel("Card")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := UI.hbox(10)
	p.add_child(h)
	h.add_child(Icon.new(icon, col, 44))
	var v := UI.vbox(0)
	h.add_child(v)
	var b := UI.label(big, "Big")
	b.add_theme_color_override("font_color", col.darkened(0.25))
	v.add_child(b)
	var s := UI.label(small, "Small")
	v.add_child(s)
	return p


func _score_box(title: String, val: int, date: String) -> Control:
	var p := UI.panel("Pill")
	var v := UI.vbox(0)
	p.add_child(v)
	v.add_child(UI.label(title, "Small", false, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.label("-" if val < 0 else "%d/10" % val, "Big", false, HORIZONTAL_ALIGNMENT_CENTER))
	if date != "":
		var d := UI.label(Game.date_label(date), "Small", false, HORIZONTAL_ALIGNMENT_CENTER)
		d.add_theme_font_size_override("font_size", Game.fs(17))
		v.add_child(d)
	return p


func _log_row(e: Dictionary) -> Control:
	var p := UI.panel("Pill")
	var h := UI.hbox(12)
	p.add_child(h)
	var feel := str(e.get("feel", ""))
	var face := "face_happy" if feel == "Segar" else ("face_ok" if feel == "Biasa saja" else ("face_tired" if feel == "Lelah" else ""))
	if face != "":
		h.add_child(Icon.new(face, Color("8cc063") if face == "face_happy" else (Color("f2b134") if face == "face_ok" else Color("e8a07a")), 44))
	else:
		h.add_child(Icon.new("quiz" if str(e.get("type", "")) == "kuis" else "check", Game.TEAL_MID, 40))
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var t := UI.label(str(e.get("name", "Latihan")), "H3", true)
	t.add_theme_font_size_override("font_size", Game.fs(23))
	v.add_child(t)
	var detail := "%s · %s" % [Game.date_label(str(e.get("date", ""))), str(e.get("time", ""))]
	if int(e.get("moves", 0)) > 0:
		detail += " · %d gerakan" % int(e.get("moves", 0))
	if str(e.get("score", "")) != "":
		detail += " · skor %s" % e.get("score", "")
	if feel != "":
		detail += " · " + feel
	var d := UI.label(detail, "Small", true)
	d.add_theme_font_size_override("font_size", Game.fs(19))
	v.add_child(d)
	var lv := int(e.get("leaves", 0))
	if lv > 0:
		h.add_child(UI.leaves_row(lv, 3, 22))
	return p
