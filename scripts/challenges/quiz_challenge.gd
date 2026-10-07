class_name QuizChallenge
extends VBoxContainer
## Kuis pilihan ganda tanpa batas waktu: Jali membacakan soal, jawaban berupa kartu besar.

signal done(score: int, total: int)
signal answered(correct: bool)

var questions: Array = []
var idx := 0
var score := 0
var show_feedback := true
var title_text := "Tantangan"

var _prog: Label
var _bar: ProgressBar
var _q: SpeechBubble
var _jali: Mascot
var _answers: VBoxContainer
var _fb: PanelContainer
var _fb_label: Label
var _fb_icon: Icon
var _next: Button
var _locked := false
var _cards: Array = []


func setup(qs: Array, title: String = "Tantangan", feedback: bool = true) -> void:
	questions = qs
	title_text = title
	show_feedback = feedback
	add_theme_constant_override("separation", 14)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var head := UI.hbox(12)
	head.add_child(UI.badge("quiz", Game.TERRA, 48))
	var tl := UI.label(title_text, "H2")
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	_bar = UI.progress(0, qs.size(), 14, Game.SAFFRON)
	_bar.custom_minimum_size.x = 180
	head.add_child(_bar)
	_prog = UI.label("", "H3")
	head.add_child(_prog)
	if Game.tts_available():
		var listen := UI.icon_btn("speaker", "Dengarkan soal", "SunButton", 64)
		listen.pressed.connect(_speak_current)
		head.add_child(listen)
	add_child(head)
	var qrow := UI.hbox(8)
	_jali = Mascot.new()
	_jali.custom_minimum_size = Vector2(110, 100)
	_jali.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	qrow.add_child(_jali)
	_q = SpeechBubble.new("", "left", "H2")
	_q.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_q.label.add_theme_font_size_override("font_size", Game.fs(29))
	qrow.add_child(_q)
	add_child(qrow)
	_answers = UI.vbox(12)
	add_child(_answers)
	var bottom := UI.hbox(14)
	_fb = UI.panel("Leaf")
	_fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fbh := UI.hbox(12)
	_fb_icon = Icon.new("check", Game.LEAF, 40)
	_fb_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fbh.add_child(_fb_icon)
	_fb_label = UI.label("", "H3", true)
	fbh.add_child(_fb_label)
	_fb.add_child(fbh)
	bottom.add_child(_fb)
	_next = UI.btn("Berikutnya", "PrimaryButton", "next", 84, 32)
	_next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_next.pressed.connect(_on_next)
	bottom.add_child(_next)
	add_child(bottom)
	_show(0)


func _speak_current() -> void:
	if idx >= questions.size():
		return
	var q: Dictionary = questions[idx]
	var t: String = q["q"]
	for c in _cards:
		t += ". " + str((c as TapCard).get_meta("text"))
	Game.speak(t, true)


func _show(i: int) -> void:
	idx = i
	_locked = false
	var q: Dictionary = questions[i]
	_prog.text = "%d/%d" % [i + 1, questions.size()]
	_bar.value = i
	_q.set_text(str(q["q"]))
	_q.pop()
	_jali.talking = true
	_jali.hop()
	get_tree().create_timer(1.4).timeout.connect(func() -> void:
		if is_instance_valid(_jali):
			_jali.talking = false)
	for c in _answers.get_children():
		c.queue_free()
	_cards.clear()
	var order := range(q["a"].size())
	order.shuffle()
	var letters := ["A", "B", "C", "D"]
	var letter_cols := [Game.TEAL_MID, Game.TERRA, Game.SAFFRON_DARK, Game.LEAF]
	for k in order.size():
		var ai: int = order[k]
		var card := TapCard.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.set_meta("ai", ai)
		card.set_meta("text", str(q["a"][ai]))
		card.set("accessibility_name", "%s. %s" % [letters[k], q["a"][ai]])
		var h := UI.hbox(16)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(h)
		var badge := Control.new()
		badge.custom_minimum_size = Vector2(48, 48)
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lt: String = letters[k]
		var lc: Color = letter_cols[k]
		badge.draw.connect(func() -> void:
			badge.draw_circle(Vector2(24, 24), 23, lc, true, -1.0, true)
			var f := Game.font_display
			var tw := f.get_string_size(lt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
			badge.draw_string(f, Vector2(24 - tw / 2.0, 34), lt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE))
		h.add_child(badge)
		var tlab := UI.label(str(q["a"][ai]), "H3", true)
		tlab.add_theme_font_size_override("font_size", Game.fs(26))
		tlab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(tlab)
		card.set_meta("label", tlab)
		card.pressed.connect(_on_answer.bind(card, ai))
		_answers.add_child(card)
		_cards.append(card)
	UI.pop_in(_cards, 0.15, 0.07)
	_fb.visible = false
	_next.visible = false
	if bool(Game.settings["tts"]):
		_speak_current()


func _on_answer(card: TapCard, ai: int) -> void:
	if _locked:
		return
	_locked = true
	var q: Dictionary = questions[idx]
	var ok := ai == int(q["ok"])
	if ok:
		score += 1
	answered.emit(ok)
	for c in _cards:
		var tc := c as TapCard
		var is_right := int(tc.get_meta("ai")) == int(q["ok"])
		if not show_feedback:
			tc.set_state("TileSelected" if tc == card else "TileDisabled")
		elif tc == card:
			tc.set_state("TileCorrect" if ok else "TileWrong")
		elif is_right:
			tc.set_state("TileCorrect")
		else:
			tc.set_state("TileDisabled")
		if show_feedback and (is_right or tc == card):
			# penanda selain warna: ikon dan kata
			var row := tc.get_child(0) as HBoxContainer
			var mark := UI.chip("Benar" if is_right else "Pilihan Mbah", "ChipLeaf" if is_right else "ChipTerra", "check" if is_right else "close", Game.LEAF_DARK if is_right else Game.DANGER)
			mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(mark)
		tc.focus_mode = Control.FOCUS_NONE
		tc.mouse_default_cursor_shape = Control.CURSOR_ARROW
	if show_feedback:
		_fb.visible = true
		if ok:
			Sfx.play("success")
			_fb.theme_type_variation = "Leaf"
			_fb_icon.kind = "check"
			_fb_icon.color = Game.LEAF
			_fb_label.text = "Benar! " + _praise()
			_jali.hop()
			FX.burst(card, Vector2(card.size.x * 0.15, card.size.y * 0.5), 14)
		else:
			Sfx.play("soft_no")
			_fb.theme_type_variation = "Note"
			_fb_icon.kind = "info"
			_fb_icon.color = Game.SAFFRON_DARK
			_fb_label.text = "Belum tepat. Jawaban yang benar sudah ditandai hijau."
			var tw := card.create_tween()
			card.pivot_offset = card.size / 2.0
			for k in 4:
				tw.tween_property(card, "rotation", 0.012 * (1 if k % 2 == 0 else -1), 0.05)
			tw.tween_property(card, "rotation", 0.0, 0.05)
		_fb_icon.queue_redraw()
		Game.speak(_fb_label.text)
	else:
		Sfx.play("pop")
	_next.visible = true
	UI.set_btn_text(_next, "Selesai" if idx >= questions.size() - 1 else "Berikutnya")
	_next.call_deferred("grab_focus")


func _praise() -> String:
	var p := ["Pintar sekali.", "Mantap, Mbah!", "Tepat sekali.", "Bagus!"]
	return p[randi() % p.size()]


func _on_next() -> void:
	Sfx.play("tap")
	if idx + 1 < questions.size():
		_show(idx + 1)
	else:
		_bar.value = questions.size()
		done.emit(score, questions.size())
