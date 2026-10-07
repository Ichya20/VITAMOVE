extends Screen
## Catatan aktivitas: hari aktif, kemajuan, hasil kuis awal-akhir, dan riwayat latihan.

var _focus: Control


func build() -> void:
	scene_bg("", "siang", 0.55)
	make_content(26)
	var p := Game.prof()
	var v := UI.vbox(14)
	content.add_child(v)
	v.add_child(header("Catatan Latihan", str(p["name"])))
	var row := UI.hbox(18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(row)

	# ---------------- kiri: ringkasan
	var lsc := UI.scroll_v()
	lsc.size_flags_stretch_ratio = 1.15
	row.add_child(lsc)
	var left := UI.vbox(14)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lsc.add_child(UI.xmargin(4, 4, 12, 12))
	lsc.get_child(0).add_child(left)
	var stats := UI.hbox(12)
	left.add_child(stats)
	var sessions := 0
	for e in p["log"]:
		if str(e.get("type", "")) in ["pos", "sesi"]:
			sessions += 1
	stats.add_child(_stat("sun", str(Game.streak(p)), "hari beruntun", Game.SAFFRON_DARK))
	stats.add_child(_stat("run", str(sessions), "latihan", Game.TERRA))
	stats.add_child(_stat("leaf", "%d" % Game.total_leaves(p), "daun dari 27", Game.LEAF))

	var cal := UI.panel("Card")
	var cv := UI.vbox(10)
	cal.add_child(cv)
	var ch := UI.hbox(10)
	ch.add_child(UI.badge("calendar", Game.TEAL_MID, 40))
	ch.add_child(UI.label("14 hari terakhir", "H3"))
	cv.add_child(ch)
	var days := Game.days_active(p, 14)
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	cv.add_child(grid)
	var names := ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"]
	var today := Game.today_str()
	for d in days:
		var parts: PackedStringArray = str(d["date"]).split("-")
		var unix := Time.get_unix_time_from_datetime_string(str(d["date"]) + "T12:00:00")
		var wd := int(Time.get_datetime_dict_from_unix_time(unix)["weekday"])
		var active: bool = d["active"]
		var is_today := str(d["date"]) == today
		var cell := Control.new()
		cell.custom_minimum_size = Vector2(66, 66)
		cell.set("accessibility_name", "%s %s: %s" % [names[wd], d["date"], "berlatih" if active else "belum"])
		var dn := parts[2] if parts.size() == 3 else "?"
		var dname: String = names[wd]
		cell.draw.connect(func() -> void:
			var c := cell.size / 2.0
			if active:
				cell.draw_circle(c + Vector2(0, 3), 30, Game.LEAF_DARK, true, -1.0, true)
				cell.draw_circle(c, 30, Game.LEAF, true, -1.0, true)
			else:
				cell.draw_circle(c, 30, Color(Game.TEAL, 0.07), true, -1.0, true)
			if is_today:
				cell.draw_arc(c, 32, 0, TAU, 32, Game.TERRA, 3.5, true)
			var f := Game.font_bold
			var col := Color.WHITE if active else Game.INK_SOFT
			var w1 := f.get_string_size(dname, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			cell.draw_string(f, Vector2(c.x - w1 / 2.0, c.y - 4), dname, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)
			var f2 := Game.font_display
			var w2 := f2.get_string_size(dn, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			cell.draw_string(f2, Vector2(c.x - w2 / 2.0, c.y + 18), dn, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, col))
		grid.add_child(cell)
	var legend := UI.hbox(14)
	legend.add_child(UI.chip("Hijau = berlatih", "ChipLeaf", "leaf", Game.LEAF_DARK))
	legend.add_child(UI.chip("Lingkar merah = hari ini", "ChipTerra", "", Game.TERRA_DARK))
	cv.add_child(legend)
	left.add_child(cal)

	# kuis pengetahuan dengan grafik batang
	var kp := UI.panel("Cream")
	var kv := UI.vbox(12)
	kp.add_child(kv)
	var kh := UI.hbox(10)
	kh.add_child(UI.badge("quiz", Game.TERRA, 40))
	kh.add_child(UI.label("Kuis Pengetahuan", "H3"))
	kv.add_child(kh)
	var pre := int(p["pre"])
	var post := int(p["post"])
	var kr := UI.hbox(18)
	kv.add_child(kr)
	var chart := Control.new()
	chart.custom_minimum_size = Vector2(250, 170)
	chart.draw.connect(func() -> void:
		var base_y := chart.size.y - 34.0
		var max_h := chart.size.y - 70.0
		var bars := [["Awal", pre, Game.TEAL_MID], ["Akhir", post, Game.TERRA]]
		for i in 2:
			var x := 30.0 + i * 110.0
			var val: int = bars[i][1]
			var hh := max_h * (maxf(0.0, float(val)) / 10.0)
			chart.draw_rect(Rect2(x, base_y - max_h, 72, max_h), Color(Game.TEAL, 0.06), true)
			if val >= 0:
				chart.draw_rect(Rect2(x, base_y - hh, 72, hh), bars[i][2], true)
			var f := Game.font_display
			var txt := "-" if val < 0 else str(val)
			var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
			chart.draw_string(f, Vector2(x + 36 - tw / 2.0, base_y - hh - 8), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Game.INK)
			var fb := Game.font_bold
			var lw := fb.get_string_size(bars[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
			chart.draw_string(fb, Vector2(x + 36 - lw / 2.0, base_y + 26), bars[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Game.INK_SOFT)
		chart.draw_line(Vector2(16, base_y), Vector2(chart.size.x - 10, base_y), Color(Game.TEAL, 0.3), 3.0, true))
	kr.add_child(chart)
	var kb := UI.vbox(10)
	kb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kb.alignment = BoxContainer.ALIGNMENT_CENTER
	var imp := UI.label("", "H3", true)
	if pre >= 0 and post >= 0:
		var pct := (float(post - pre) / maxf(1.0, pre)) * 100.0
		imp.text = "Peningkatan pemahaman: %+d%%" % int(round(pct))
		imp.add_theme_color_override("font_color", Game.LEAF_DARK if post >= pre else Game.TERRA_DARK)
	else:
		imp.text = "Kerjakan kuis awal sebelum belajar, lalu kuis akhir setelah semua pos."
		imp.add_theme_font_size_override("font_size", Game.fs(21))
	kb.add_child(imp)
	var bpre := UI.btn("Kuis Awal" if pre < 0 else "Ulangi Kuis Awal", "TealButton" if pre < 0 else "Button", "quiz", 72, 28)
	bpre.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("test", {"kind": "pre"}))
	kb.add_child(bpre)
	var bpost := UI.btn("Kuis Akhir", "PrimaryButton" if pre >= 0 else "Button", "quiz", 72, 28)
	bpost.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("test", {"kind": "post"}))
	kb.add_child(bpost)
	kr.add_child(kb)
	left.add_child(kp)
	_focus = bpre if pre < 0 else bpost

	# ---------------- kanan: riwayat
	var right := UI.panel("Card")
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var rv := UI.vbox(10)
	right.add_child(rv)
	var rh := UI.hbox(10)
	rh.add_child(UI.badge("book", Game.SAFFRON_DARK, 40))
	rh.add_child(UI.label("Riwayat Latihan", "H3"))
	rv.add_child(rh)
	var sc := UI.scroll_v()
	rv.add_child(sc)
	var list := UI.vbox(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	var logs: Array = p["log"]
	if logs.is_empty():
		var empty := UI.vbox(12)
		empty.alignment = BoxContainer.ALIGNMENT_CENTER
		var j := Mascot.new()
		j.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		empty.add_child(j)
		empty.add_child(UI.label("Belum ada catatan. Selesaikan satu pos di peta, nanti catatannya muncul di sini.", "Body", true, HORIZONTAL_ALIGNMENT_CENTER))
		var go := UI.btn("Buka Peta", "PrimaryButton", "next", 72, 28)
		go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		go.pressed.connect(func() -> void:
			Sfx.play("tap")
			main.go("map"))
		empty.add_child(go)
		list.add_child(empty)
	var rows: Array = []
	for i in range(logs.size() - 1, maxi(-1, logs.size() - 41), -1):
		var r := _log_row(logs[i])
		list.add_child(r)
		if rows.size() < 6:
			rows.append(r)
	reveal([stats, cal, kp, right] + rows, 0.05)


func default_focus() -> Control:
	return _focus


func _stat(icon: String, big: String, small: String, col: Color) -> Control:
	var p := UI.panel("Card")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := UI.hbox(12)
	p.add_child(h)
	h.add_child(UI.badge(icon, col, 52))
	var v := UI.vbox(0)
	h.add_child(v)
	var b := UI.label(big, "Big")
	b.add_theme_color_override("font_color", col.darkened(0.15))
	v.add_child(b)
	var s := UI.label(small, "Small")
	s.add_theme_font_size_override("font_size", Game.fs(19))
	v.add_child(s)
	return p


func _log_row(e: Dictionary) -> Control:
	var p := UI.panel("Inset")
	var h := UI.hbox(12)
	p.add_child(h)
	var feel := str(e.get("feel", ""))
	var face := "face_happy" if feel == "Segar" else ("face_ok" if feel == "Biasa saja" else ("face_tired" if feel == "Lelah" else ""))
	if face != "":
		h.add_child(Icon.new(face, Color("8cc063") if face == "face_happy" else (Color("f2b134") if face == "face_ok" else Color("e8a07a")), 46))
	else:
		var t0 := str(e.get("type", ""))
		h.add_child(UI.badge("quiz" if t0 == "kuis" else ("people" if t0 == "sesi" else "check"), Game.TEAL_MID, 44))
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
		h.add_child(UI.leaves_row(lv, 3, 24))
	return p
