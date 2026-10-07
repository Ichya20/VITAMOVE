class_name BalanceChallenge
extends VBoxContainer
## "Titian Pematang": jaga jarum keseimbangan di zona hijau agar Mbah terus melangkah.
## Tanpa kalah: bila keluar zona, Mbah hanya berhenti sebentar.

signal done(score: int, total: int)

const ZONE := 0.32

var avatar := "putri"
var _needle := 0.0
var _vel := 0.0
var _drift := 0.0
var _progress := 0.0
var _out_time := 0.0
var _t := 0.0
var _running := false
var _finished := false
var _push := 0.0

var _stage: Control
var _fig: ElderFigure
var _meter: Control
var _bar: ProgressBar
var _hint: Label
var _start: Button
var _left: Button
var _right: Button
var _rng := RandomNumberGenerator.new()


func setup(av: String) -> void:
	avatar = av
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rng.randomize()
	var head := UI.hbox(12)
	head.add_child(Icon.new("balance", Game.LEAF, 40))
	var tl := UI.label("Titian Pematang", "H2")
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(260, 34)
	_bar.show_percentage = false
	_bar.max_value = 1.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Game.LEAF
	fill.set_corner_radius_all(14)
	var bgsb := StyleBoxFlat.new()
	bgsb.bg_color = Color(Game.TEAL, 0.15)
	bgsb.set_corner_radius_all(14)
	_bar.add_theme_stylebox_override("fill", fill)
	_bar.add_theme_stylebox_override("background", bgsb)
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_bar)
	add_child(head)
	_hint = UI.label("Mbah berjalan di pematang. Bila jarum condong, tekan tombol ke arah sebaliknya agar tetap di zona hijau.", "Body", true)
	add_child(_hint)

	var row := UI.hbox(16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(row)
	_left = UI.btn("Condong Kiri", "TealButton", "prev", 120, 50)
	_left.custom_minimum_size = Vector2(190, 0)
	_left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left.button_down.connect(func() -> void: _push = -1.0)
	_left.button_up.connect(func() -> void: _push = 0.0)
	row.add_child(_left)

	var mid := UI.vbox(8)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mid)
	_meter = Control.new()
	_meter.custom_minimum_size = Vector2(0, 70)
	_meter.draw.connect(_draw_meter)
	mid.add_child(_meter)
	_stage = Control.new()
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.clip_contents = true
	_stage.draw.connect(_draw_stage)
	mid.add_child(_stage)
	_fig = ElderFigure.new()
	_fig.set_avatar(avatar)
	_fig.anchor_left = 0.3
	_fig.anchor_right = 0.7
	_fig.anchor_top = 0.02
	_fig.anchor_bottom = 0.92
	_fig.show_ground = false
	_stage.add_child(_fig)

	_right = UI.btn("Condong Kanan", "TealButton", "next", 120, 50)
	_right.custom_minimum_size = Vector2(190, 0)
	_right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right.button_down.connect(func() -> void: _push = 1.0)
	_right.button_up.connect(func() -> void: _push = 0.0)
	row.add_child(_right)

	_start = UI.btn("Mulai Berjalan", "PrimaryButton", "play", 84, 32)
	_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_start.pressed.connect(_begin)
	add_child(_start)
	set_process(true)


func _begin() -> void:
	Sfx.play("tap")
	if _finished:
		var sc := 3 if _out_time < 4.0 else (2 if _out_time < 10.0 else 1)
		done.emit(sc, 3)
		return
	_running = true
	_start.visible = false
	_left.call_deferred("grab_focus")
	Game.speak("Ayo berjalan pelan di pematang.")


func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	if event.is_action_pressed("ui_left"):
		_push = -1.0
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_push = 1.0
		get_viewport().set_input_as_handled()
	elif event.is_action_released("ui_left") or event.is_action_released("ui_right"):
		_push = 0.0


func _process(delta: float) -> void:
	_t += delta
	if _running:
		# angin lembut mengubah arah secara perlahan
		if fmod(_t, 2.4) < delta:
			_drift = _rng.randf_range(-0.26, 0.26)
		_vel += (_drift * 0.55 + _needle * 0.35 + _push * 0.95) * delta
		_vel *= pow(0.25, delta)
		_needle = clampf(_needle + _vel * delta * 1.6, -1.0, 1.0)
		if absf(_needle) >= 1.0:
			_vel = 0.0
		var in_zone := absf(_needle) <= ZONE
		if in_zone:
			_progress = minf(1.0, _progress + delta / 26.0)
			_hint.text = "Bagus, terus seimbang..."
		else:
			_out_time += delta
			_hint.text = "Mbah berhenti sebentar. Tekan tombol %s." % ("Condong Kanan" if _needle < 0 else "Condong Kiri")
		_bar.value = _progress
		var step := sin(_t * 4.0) if in_zone else 0.0
		_fig.set_pose({"tilt": _needle * 14.0, "la": 60.0 + _needle * 20.0, "ra": 60.0 - _needle * 20.0,
			"ll": maxf(0.0, step) * 0.3, "rl": maxf(0.0, -step) * 0.3})
		if _progress >= 1.0:
			_running = false
			_finished = true
			_push = 0.0
			Sfx.play("leaf")
			_hint.text = "Sampai di ujung pematang! Keseimbangan Mbah hebat."
			Game.speak(_hint.text)
			_start.visible = true
			UI.set_btn_text(_start, "Selesai")
			_start.call_deferred("grab_focus")
	_meter.queue_redraw()
	_stage.queue_redraw()


func _draw_meter() -> void:
	var w := _meter.size.x
	var h := _meter.size.y
	var r := Rect2(20, h * 0.3, w - 40, h * 0.4)
	_meter.draw_rect(r, Color("e8d9b8"), true)
	var zw := r.size.x * ZONE
	_meter.draw_rect(Rect2(r.get_center().x - zw / 2.0, r.position.y, zw, r.size.y), Color("8cc063"), true)
	var red_w := r.size.x * 0.15
	_meter.draw_rect(Rect2(r.position.x, r.position.y, red_w, r.size.y), Color("e8a07a"), true)
	_meter.draw_rect(Rect2(r.end.x - red_w, r.position.y, red_w, r.size.y), Color("e8a07a"), true)
	var nx := r.get_center().x + _needle * r.size.x / 2.0
	_meter.draw_line(Vector2(nx, 4), Vector2(nx, h - 4), Game.INK, 8, true)
	_meter.draw_circle(Vector2(nx, 8), 10, Game.TERRA, true, -1.0, true)


func _draw_stage() -> void:
	var w := _stage.size.x
	var h := _stage.size.y
	_stage.draw_rect(Rect2(0, 0, w, h), Color("cfe9e3"), true)
	# sawah berair di kiri-kanan, pematang di tengah dengan perspektif
	var cx := w / 2.0
	var top := h * 0.3
	_stage.draw_colored_polygon(PackedVector2Array([Vector2(0, top), Vector2(w, top), Vector2(w, h), Vector2(0, h)]), Color("8fc4c0"))
	_stage.draw_colored_polygon(PackedVector2Array([Vector2(cx - 18, top), Vector2(cx + 18, top), Vector2(cx + 120, h), Vector2(cx - 120, h)]), Color("7a9a4a"))
	var off := fmod(_progress * 2600.0, 60.0)
	for i in 12:
		var t := (i * 60.0 + off) / 720.0
		var yy := top + (h - top) * t
		var half := lerpf(18.0, 120.0, t)
		_stage.draw_line(Vector2(cx - half, yy), Vector2(cx + half, yy), Color("6a8a3e"), 3, true)
		for sx: int in [-1, 1]:
			var px: float = cx + sx * (half + 40 + t * 120)
			_stage.draw_line(Vector2(px, yy), Vector2(px - 5, yy - 14 * (0.5 + t)), Color("4f8a3c"), 3, true)
			_stage.draw_line(Vector2(px, yy), Vector2(px + 6, yy - 13 * (0.5 + t)), Color("4f8a3c"), 3, true)
	_stage.draw_rect(Rect2(0, 0, w, top), Color("bfe3ea"), true)
	_stage.draw_circle(Vector2(w * 0.8, top * 0.5), 26, Color("ffd27a"), true, -1.0, true)
