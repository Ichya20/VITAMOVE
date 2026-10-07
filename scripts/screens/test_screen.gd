extends Screen
## Kuis pengetahuan awal (pretest) dan akhir (posttest) untuk evaluasi program.

var kind := "pre"
var _box: VBoxContainer
var _focus: Control


func build() -> void:
	kind = str(params.get("kind", "pre"))
	soft_bg("posyandu", "siang", 0.6)
	make_content(26)
	var v := UI.vbox(12)
	content.add_child(v)
	v.add_child(top_bar("Kuis Awal" if kind == "pre" else "Kuis Akhir"))
	_box = UI.vbox(12)
	_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_box)
	_intro()


func default_focus() -> Control:
	return _focus


func _intro() -> void:
	var p := UI.panel("Card")
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box.add_child(p)
	var h := UI.hbox(24)
	p.add_child(h)
	var j := Mascot.new()
	j.custom_minimum_size = Vector2(200, 200)
	j.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(j)
	var v := UI.vbox(16)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label("10 pertanyaan singkat", "H1"))
	var txt := "Kuis ini membantu kader melihat pemahaman Mbah sebelum belajar. Jawab sebisanya, tidak ada nilai buruk." if kind == "pre" else "Kuis ini sama dengan kuis awal. Hasilnya dibandingkan untuk melihat kemajuan pemahaman Mbah."
	v.add_child(UI.label(txt, "Body", true))
	v.add_child(UI.label("Tidak ada batas waktu. Kader boleh membacakan pertanyaan.", "Small", true))
	var go := UI.btn("Mulai Kuis", "PrimaryButton", "play", 88, 34)
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	go.pressed.connect(func() -> void:
		Sfx.play("tap")
		_start())
	v.add_child(go)
	_focus = go
	Game.speak(txt)


func _start() -> void:
	for c in _box.get_children():
		c.queue_free()
	var p := UI.panel("Card")
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box.add_child(p)
	var q := QuizChallenge.new()
	p.add_child(q)
	q.setup(Data.KNOWLEDGE_TEST, "Kuis Pengetahuan", kind == "post")
	q.done.connect(_finish)


func _finish(score: int, total: int) -> void:
	if Game.has_profile():
		var pr: Dictionary = Game.profiles[Game.current]
		pr[kind] = score
		pr[kind + "_date"] = Game.today_str()
		Game.save_data()
		Game.log_activity({"type": "kuis", "name": "Kuis Awal" if kind == "pre" else "Kuis Akhir", "score": "%d/%d" % [score, total], "feel": "", "leaves": 0, "moves": 0})
	for c in _box.get_children():
		c.queue_free()
	Sfx.play("leaf")
	var p := UI.panel("Cream")
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box.add_child(p)
	var v := UI.vbox(16)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	v.add_child(UI.label("Terima kasih!", "H1", false, HORIZONTAL_ALIGNMENT_CENTER))
	var big := UI.label("%d / %d" % [score, total], "Counter", false, HORIZONTAL_ALIGNMENT_CENTER)
	big.add_theme_font_size_override("font_size", Game.fs(96))
	v.add_child(big)
	var pr2 := Game.prof()
	var msg := "Jawaban benar. Ayo jelajahi pos-pos di desa untuk belajar lebih banyak."
	if kind == "post" and int(pr2["pre"]) >= 0:
		var pre := int(pr2["pre"])
		var diff := score - pre
		var pct := (float(diff) / maxf(1.0, pre)) * 100.0
		msg = "Kuis awal: %d, kuis akhir: %d. " % [pre, score]
		if diff > 0:
			msg += "Pemahaman naik %d%%. Luar biasa!" % int(round(pct))
		elif diff == 0:
			msg += "Pemahaman tetap terjaga. Bagus!"
		else:
			msg += "Tidak apa-apa, mari ulangi materi bersama kader."
	v.add_child(UI.label(msg, "H3", true, HORIZONTAL_ALIGNMENT_CENTER))
	var b := UI.btn("Selesai", "PrimaryButton", "check", 88, 34)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.back())
	v.add_child(b)
	b.call_deferred("grab_focus")
	Game.speak("Terima kasih. " + msg)
