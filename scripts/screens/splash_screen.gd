extends Screen
## Splash beranimasi: daun kertas berjatuhan, logo VITAMOVE menyatu, pita terbuka,
## lalu Jali si Jalak terbang masuk dan berkicau. Dapat dilewati kapan saja.
## Menyambung dari boot splash Godot yang juga berlatar krem, jadi tanpa kedipan.

const DUR_RAYS := 0.7
const T_LOGO := 0.45
const DUR_LOGO := 0.75
const T_MEET := T_LOGO + DUR_LOGO
const T_LEAF := T_MEET + 0.05
const T_RIBBON := T_LEAF + 0.45
const T_JALI := T_RIBBON + 0.45
const T_CHIRP := T_JALI + 0.8
const T_CREDIT := T_CHIRP + 0.1
const T_END := T_CREDIT + 0.75

var _stage: Control
var _rays: Decor
var _vita: Label
var _move: Label
var _leaf: Icon
var _ribbon: Decor
var _credit: Label
var _jali: Mascot
var _skip_btn: Button
var _tw: Tween
var _leaving := false
var _home := {}


func build() -> void:
	# latar kertas krem, sama dengan warna boot splash
	var bg := ColorRect.new()
	bg.color = Game.CREAM
	UI.full(bg)
	add_child(bg)
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full(_stage)
	add_child(_stage)

	_rays = Decor.new("rays")
	_rays.color = Game.SAFFRON
	_rays.alpha = 0.5
	_rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_rays)

	_vita = UI.label("VITA", "Display")
	_vita.add_theme_color_override("font_outline_color", Game.PAPER)
	_vita.add_theme_constant_override("outline_size", 18)
	_stage.add_child(_vita)
	_move = UI.label("MOVE", "Display")
	_move.add_theme_color_override("font_color", Game.TERRA)
	_move.add_theme_color_override("font_outline_color", Game.PAPER)
	_move.add_theme_constant_override("outline_size", 18)
	_stage.add_child(_move)
	_leaf = Icon.new("leaf", Game.LEAF, 86)
	_stage.add_child(_leaf)

	_ribbon = Decor.new("ribbon")
	_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_ribbon)
	var rl := UI.label("JELAJAH SEHAT DESA", "OnDark", false, HORIZONTAL_ALIGNMENT_CENTER)
	rl.add_theme_font_override("font", Game.font_caps)
	rl.add_theme_font_size_override("font_size", 26)
	rl.uppercase = true
	rl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rl.offset_bottom = -6
	rl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ribbon.add_child(rl)

	_credit = UI.label("Pengabdian Masyarakat Telkom University\nPosyandu Lansia Wreda Asih 2 · Desa Muntang, Purbalingga", "Small", false, HORIZONTAL_ALIGNMENT_CENTER)
	_credit.add_theme_font_size_override("font_size", Game.fs_cap(21, 1.05))
	_stage.add_child(_credit)

	_jali = Mascot.new()
	_jali.facing = -1.0
	_jali.size = Vector2(140, 140)
	_stage.add_child(_jali)

	UI.paper_grain(self, 0.4)

	var sa: Vector4 = main.safe_margins()
	_skip_btn = UI.btn("Lewati", "Button", "next", 68, 26)
	_skip_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_skip_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_skip_btn.offset_right = -24 - sa.z
	_skip_btn.offset_bottom = -20 - sa.w
	_skip_btn.offset_left = _skip_btn.offset_right - 10
	_skip_btn.offset_top = _skip_btn.offset_bottom - 10
	_skip_btn.pressed.connect(_skip)
	add_child(_skip_btn)

	resized.connect(_layout)
	_layout()
	if Game.motion():
		_animate()
	else:
		_credit.modulate.a = 1.0
		Sfx.play("gong")
		get_tree().create_timer(1.1).timeout.connect(_finish)


func _layout() -> void:
	var w := size.x
	var h := size.y
	if w < 4.0 or h < 4.0:
		return
	var cx := w / 2.0
	for l in [_vita, _move, _credit]:
		(l as Label).reset_size()
	var leaf_s := clampf(h * 0.12, 54.0, 92.0)
	_leaf.size = Vector2(leaf_s, leaf_s)
	var total := _vita.size.x + _move.size.x + leaf_s
	var logo_y := h * 0.30
	_home["vita"] = Vector2(cx - total / 2.0, logo_y)
	_home["move"] = Vector2(_home["vita"].x + _vita.size.x, logo_y)
	_home["leaf"] = Vector2(_home["move"].x + _move.size.x + 4.0, logo_y + _vita.size.y * 0.18)
	var rw := clampf(w * 0.34, 340.0, 520.0)
	_ribbon.size = Vector2(rw, 54.0)
	_ribbon.pivot_offset = _ribbon.size / 2.0
	_home["ribbon"] = Vector2(cx - rw / 2.0, logo_y + _vita.size.y + 16.0)
	_home["credit"] = Vector2(cx - _credit.size.x / 2.0, h * 0.78)
	_home["jali"] = Vector2(cx + total / 2.0 - 4.0, logo_y - 86.0)
	var d := sqrt(w * w + h * h) * 1.15
	_rays.size = Vector2(d, d)
	_rays.position = Vector2(cx - d / 2.0, logo_y + 50.0 - d / 2.0)
	if _tw == null or not _tw.is_running():
		_vita.position = _home["vita"]
		_move.position = _home["move"]
		_leaf.position = _home["leaf"]
		_ribbon.position = _home["ribbon"]
		_jali.position = _home["jali"]
	_credit.position = _home["credit"]


func _animate() -> void:
	_vita.position = _home["vita"] - Vector2(560, 0)
	_move.position = _home["move"] + Vector2(560, 0)
	_leaf.position = _home["leaf"]
	_leaf.pivot_offset = _leaf.size / 2.0
	_leaf.scale = Vector2.ZERO
	_leaf.rotation = -1.3
	_ribbon.position = _home["ribbon"]
	_ribbon.scale = Vector2(0.0, 1.0)
	_credit.modulate.a = 0.0
	_jali.position = Vector2(size.x + 180.0, _home["jali"].y - 60.0)
	_jali.flap = true
	_rays.modulate.a = 0.0

	FX.leaf_fall(_stage, 0.15)

	_tw = create_tween().set_parallel(true)
	_tw.tween_property(_rays, "modulate:a", 1.0, DUR_RAYS)
	_tw.tween_property(_vita, "position:x", _home["vita"].x, DUR_LOGO).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_delay(T_LOGO)
	_tw.tween_property(_move, "position:x", _home["move"].x, DUR_LOGO).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_delay(T_LOGO)
	_tw.tween_callback(_on_meet).set_delay(T_MEET)
	_tw.tween_property(_leaf, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(T_LEAF)
	_tw.tween_property(_leaf, "rotation", 0.0, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(T_LEAF)
	_tw.tween_callback(func() -> void: Sfx.play("page")).set_delay(T_RIBBON)
	_tw.tween_property(_ribbon, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(T_RIBBON)
	_tw.tween_property(_jali, "position", _home["jali"], 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(T_JALI)
	_tw.tween_callback(_on_land).set_delay(T_CHIRP)
	_tw.tween_property(_credit, "modulate:a", 1.0, 0.5).set_delay(T_CREDIT)
	_tw.tween_callback(_finish).set_delay(T_END)


func _on_meet() -> void:
	Sfx.play("gong")
	var c := Vector2(size.x / 2.0, _home["vita"].y + _vita.size.y * 0.5)
	FX.burst(_stage, c, 24)
	# hentakan halus pada logo
	for l in [_vita, _move]:
		var n := l as Label
		n.pivot_offset = n.size / 2.0
		var t := create_tween()
		t.tween_property(n, "scale", Vector2(1.06, 1.06), 0.09)
		t.tween_property(n, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_land() -> void:
	_jali.flap = false
	_jali.hop()
	_jali.talking = true
	Sfx.play("chirp")
	get_tree().create_timer(0.6).timeout.connect(func() -> void:
		if is_instance_valid(_jali):
			_jali.talking = false)


func _finish() -> void:
	if _leaving:
		return
	_leaving = true
	main.replace_with("title")


func _skip() -> void:
	if _leaving:
		return
	Sfx.play("tap")
	if _tw and _tw.is_valid():
		_tw.kill()
	_finish()


func on_back() -> bool:
	_skip()
	return true


func default_focus() -> Control:
	return _skip_btn


func _unhandled_input(event: InputEvent) -> void:
	if _leaving:
		return
	var tapped := false
	if event is InputEventMouseButton:
		tapped = (event as InputEventMouseButton).pressed
	elif event is InputEventScreenTouch:
		tapped = (event as InputEventScreenTouch).pressed
	elif event is InputEventKey:
		var k := event as InputEventKey
		tapped = k.pressed and not k.echo
	elif event is InputEventJoypadButton:
		tapped = (event as InputEventJoypadButton).pressed
	if tapped:
		get_viewport().set_input_as_handled()
		_skip()
