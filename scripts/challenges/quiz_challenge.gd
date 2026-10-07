class_name QuizChallenge
extends VBoxContainer
## Kuis pilihan ganda tanpa batas waktu, dengan umpan balik yang ramah.

signal done(score: int, total: int)
signal answered(correct: bool)

var questions: Array = []
var idx := 0
var score := 0
var show_feedback := true
var title_text := "Tantangan"
var answers_log: Array = []

var _prog: Label
var _q: Label
var _answers: VBoxContainer
var _fb: PanelContainer
var _fb_label: Label
var _fb_icon: Icon
var _next: Button
var _locked := false


func setup(qs: Array, title: String = "Tantangan", feedback: bool = true) -> void:
	questions = qs
	title_text = title
	show_feedback = feedback
	add_theme_constant_override("separation", 14)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var head := UI.hbox(12)
	head.add_child(Icon.new("quiz", Game.TERRA, 40))
	var tl := UI.label(title_text, "H2")
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	_prog = UI.label("", "H3")
	head.add_child(_prog)
	var listen := UI.btn("Dengar", "Button", "speaker", 72, 28)
	listen.pressed.connect(_speak_current)
	listen.visible = Game.tts_available()
	head.add_child(listen)
	add_child(head)
	var qp := UI.panel("Cream")
	_q = UI.label("", "H2", true)
	qp.add_child(_q)
	add_child(qp)
	_answers = UI.vbox(12)
	add_child(_answers)
	var bottom := UI.hbox(14)
	_fb = UI.panel("Leaf")
	_fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fbh := UI.hbox(12)
	_fb_icon = Icon.new("check", Game.LEAF, 40)
	fbh.add_child(_fb_icon)
	_fb_label = UI.label("", "H3", true)
	fbh.add_child(_fb_label)
	_fb.add_child(fbh)
	bottom.add_child(_fb)
	_next = UI.btn("Berikutnya", "PrimaryButton", "next", 84, 32)
	_next.pressed.connect(_on_next)
	bottom.add_child(_next)
	add_child(bottom)
	_show(0)


func _speak_current() -> void:
	if idx >= questions.size():
		return
	var q: Dictionary = questions[idx]
	var t: String = q["q"]
	for i in _answers.get_child_count():
		var b := _answers.get_child(i) as Button
		t += ". " + b.text
	Game.speak(t, true)


func _show(i: int) -> void:
	idx = i
	_locked = false
	var q: Dictionary = questions[i]
	_prog.text = "%d / %d" % [i + 1, questions.size()]
	_q.text = str(q["q"])
	for c in _answers.get_children():
		c.queue_free()
	var order := range(q["a"].size())
	order.shuffle()
	var letters := ["A", "B", "C", "D"]
	for k in order.size():
		var ai: int = order[k]
		var b := UI.btn("%s.  %s" % [letters[k], q["a"][ai]], "ChoiceButton", "", 80)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.toggle_mode = true
		b.set_meta("ai", ai)
		b.pressed.connect(_on_answer.bind(b, ai))
		_answers.add_child(b)
		if k == 0 and is_inside_tree() and get_viewport().gui_get_focus_owner() != null:
			b.call_deferred("grab_focus")
	_fb.visible = false
	_next.visible = false
	if bool(Game.settings["tts"]):
		_speak_current()


func _on_answer(b: Button, ai: int) -> void:
	if _locked:
		b.button_pressed = false
		return
	_locked = true
	var q: Dictionary = questions[idx]
	var ok := ai == int(q["ok"])
	answers_log.append(ok)
	if ok:
		score += 1
	answered.emit(ok)
	for c in _answers.get_children():
		var bb := c as Button
		bb.disabled = bb != b
		if show_feedback and int(bb.get_meta("ai", -1)) == int(q["ok"]):
			var g := StyleBoxFlat.new()
			g.bg_color = Game.LEAF_SOFT
			g.border_color = Game.LEAF
			g.set_border_width_all(5)
			g.set_corner_radius_all(24)
			g.content_margin_left = 22
			g.content_margin_right = 22
			for stn in ["normal", "disabled", "pressed", "hover", "hover_pressed"]:
				bb.add_theme_stylebox_override(stn, g)
			bb.add_theme_color_override("font_disabled_color", Game.INK)
			bb.text = bb.text + "   (jawaban benar)"
	if show_feedback:
		_fb.visible = true
		if ok:
			Sfx.play("success")
			_fb.theme_type_variation = "Leaf"
			_fb_icon.kind = "check"
			_fb_icon.color = Game.LEAF
			_fb_label.text = "Benar! " + _praise()
		else:
			Sfx.play("soft_no")
			_fb.theme_type_variation = "Note"
			_fb_icon.kind = "info"
			_fb_icon.color = Color("b07c12")
			_fb_label.text = "Belum tepat. Jawaban yang benar: " + str(q["a"][int(q["ok"])])
		_fb_icon.queue_redraw()
		Game.speak(_fb_label.text)
	else:
		Sfx.play("tap")
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
		done.emit(score, questions.size())
