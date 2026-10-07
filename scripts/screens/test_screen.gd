extends Screen
## Kuis pengetahuan awal (pretest) dan akhir (posttest) untuk evaluasi program.

var kind := "pre"
var _box: VBoxContainer
var _focus: Control


func build() -> void:
	kind = str(params.get("kind", "pre"))
	scene_bg("posyandu", "siang", 0.45)
	make_content(26)
	var v := UI.vbox(14)
	content.add_child(v)
	v.add_child(header("Kuis Awal" if kind == "pre" else "Kuis Akhir", "Kuis pengetahuan · 10 soal"))
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
	var h := UI.hbox(30)
	p.add_child(h)
	var j := Mascot.new()
	j.custom_minimum_size = Vector2(230, 230)
	j.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(j)
	var v := UI.vbox(16)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label("Sebelum belajar" if kind == "pre" else "Setelah belajar", "Caption"))
	v.add_child(UI.label("10 pertanyaan singkat", "H1"))
	var txt := "Kuis ini membantu kader melihat pemahaman Mbah sebelum belajar. Jawab sebisanya, tidak ada nilai buruk." if kind == "pre" else "Kuis ini sama dengan kuis awal. Hasilnya dibandingkan untuk melihat kemajuan pemahaman Mbah."
	v.add_child(UI.label(txt, "Lead", true))
	var chips := UI.hbox(10)
	chips.add_child(UI.chip("Tanpa batas waktu", "ChipLeaf", "check", Game.LEAF_DARK))
	chips.add_child(UI.chip("Boleh dibacakan kader", "Chip", "people", Game.TEAL))
	v.add_child(chips)
	var go := UI.btn("Mulai Kuis", "PrimaryButton", "play", 88, 34)
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	go.pressed.connect(func() -> void:
		Sfx.play("tap")
		_start())
	v.add_child(go)
	_focus = go
	reveal([j, v])
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
	Sfx.play("cheer")
	var p := UI.panel("Cream")
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box.add_child(p)
	var h := UI.hbox(30)
	p.add_child(h)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(300, 0)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(stage)
	var rays := Decor.new("rays")
	UI.full(rays)
	stage.add_child(rays)
	var ring := CountRing.new()
	ring.anchor_left = 0.1
	ring.anchor_right = 0.9
	ring.anchor_top = 0.15
	ring.anchor_bottom = 0.85
	ring.progress = float(score) / total
	ring.set_count("%d/%d" % [score, total], "benar")
	stage.add_child(ring)
	var v := UI.vbox(16)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label("Kuis selesai", "Caption"))
	v.add_child(UI.label("Terima kasih, Mbah!", "H1"))
	var pr2 := Game.prof()
	var msg := "Jawaban sudah tersimpan. Ayo jelajahi pos-pos di desa untuk belajar lebih banyak."
	if kind == "post" and int(pr2["pre"]) >= 0:
		var pre := int(pr2["pre"])
		var diff := score - pre
		var pct := (float(diff) / maxf(1.0, pre)) * 100.0
		msg = "Kuis awal %d, kuis akhir %d. " % [pre, score]
		if diff > 0:
			msg += "Pemahaman naik %d%%. Luar biasa!" % int(round(pct))
		elif diff == 0:
			msg += "Pemahaman tetap terjaga. Bagus!"
		else:
			msg += "Tidak apa-apa, mari ulangi materi bersama kader."
	v.add_child(UI.label(msg, "Lead", true))
	var b := UI.btn("Selesai", "PrimaryButton", "check", 84, 32)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.back())
	v.add_child(b)
	b.call_deferred("grab_focus")
	reveal([stage, v])
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(p):
		FX.confetti(self, 60)
	Game.speak("Terima kasih. " + msg)
