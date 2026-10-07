extends Screen
## Peta "Jelajah Desa": 9 pos materi di sepanjang jalan desa.

const SPACING := 400.0
const MARGIN_X := 300.0
const KINDS := ["balai", "rumah", "sawah", "pematang", "bambu", "sumur", "pasar", "kali", "posyandu"]

var scroll: ScrollContainer
var world: Control
var markers: Array[Button] = []
var token: ElderFigure
var bubble_label: Label
var bubble: PanelContainer
var jali: Mascot
var _target := 0
var _pulse: Array = []
var _t := 0.0
var _focus: Control


func build() -> void:
	var vp := get_viewport_rect().size
	var h := vp.y
	var n := Data.STATIONS.size()
	var w := MARGIN_X * 2.0 + SPACING * (n - 1)

	scroll = ScrollContainer.new()
	UI.full(scroll)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(scroll)
	world = Control.new()
	world.custom_minimum_size = Vector2(w, h)
	world.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(world)

	var pts := PackedVector2Array()
	var places: Array = []
	pts.append(Vector2(0, h * 0.70))
	for i in n:
		var p := _marker_pos(i, h)
		pts.append(p)
		places.append({"kind": KINDS[i], "x": p.x + 120.0, "y": p.y - 26.0, "s": 0.78 * h / 720.0})
	pts.append(Vector2(w, h * 0.70))

	var land := Landscape.new()
	land.time_of_day = "pagi"
	land.horizon = 0.48
	land.show_path = true
	land.path_points = pts
	land.places = places
	land.seed_value = 11
	land.custom_minimum_size = Vector2(w, h)
	land.size = Vector2(w, h)
	world.add_child(land)

	for i in 6:
		var c := Cloud.new(160.0 + (i % 3) * 50.0, 6.0 + i * 2.0)
		c.position = Vector2(i * 640.0, 30.0 + (i % 2) * 60.0)
		c.span = w
		world.add_child(c)

	var p := Game.prof()
	var unlocked := int(p["unlocked"])
	_target = clampi(unlocked - 1, 0, n - 1)
	for i in n:
		_add_marker(i, h, unlocked)

	token = ElderFigure.new()
	token.set_avatar(str(p["avatar"]))
	token.show_ground = true
	token.custom_minimum_size = Vector2(100, 150)
	token.size = Vector2(100, 150)
	world.add_child(token)
	_place_token(_target, h)

	_build_overlay()
	await get_tree().process_frame
	_scroll_to(_target, false)
	if bool(params.get("welcome", false)):
		params.erase("welcome")
		_welcome()
	elif params.has("opened"):
		var oi := int(params["opened"])
		params.erase("opened")
		if oi < n:
			Sfx.play("unlock")
			_say("Pos baru terbuka: %s! Ketuk untuk melanjutkan." % Data.STATIONS[oi]["name"])
			_scroll_to(oi, true)
		else:
			_say("Hebat! Semua pos sudah dijelajahi. Ulangi latihan kapan saja, ya.")
	else:
		_say("Ketuk pos yang bersinar untuk mulai belajar, %s." % p["name"])


func _marker_pos(i: int, h: float) -> Vector2:
	return Vector2(MARGIN_X + i * SPACING - 60.0, h * (0.64 if i % 2 == 0 else 0.76))


func _add_marker(i: int, h: float, unlocked: int) -> void:
	var st: Dictionary = Data.STATIONS[i]
	var pos := _marker_pos(i, h)
	var locked := i >= unlocked
	var col := Color(str(st["color"]))
	var ring := Control.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.size = Vector2(170, 170)
	ring.position = pos - Vector2(85, 85)
	ring.draw.connect(func() -> void:
		if i == _target and not locked:
			var a := 0.35 + 0.25 * sin(_t * 3.0)
			ring.draw_circle(Vector2(85, 85), 72.0 + 6.0 * sin(_t * 3.0), Color(Game.SAFFRON, a), true, -1.0, true))
	world.add_child(ring)
	_pulse.append(ring)

	var b := Button.new()
	b.custom_minimum_size = Vector2(112, 112)
	b.size = Vector2(112, 112)
	b.position = pos - Vector2(56, 56)
	b.focus_mode = Control.FOCUS_ALL
	b.set("accessibility_name", "Pos %d: %s%s" % [i + 1, st["name"], " (terkunci)" if locked else ""])
	var bg := col if not locked else Color("b9b2a4")
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(56)
		sb.corner_detail = 16
		sb.anti_aliasing = true
		if state == "focus":
			sb.draw_center = false
			sb.set_border_width_all(6)
			sb.border_color = Game.SAFFRON
			sb.set_expand_margin_all(8)
		else:
			sb.bg_color = bg.lightened(0.1) if state == "hover" else (bg.darkened(0.12) if state.begins_with("pressed") or state == "hover_pressed" else bg)
			sb.set_border_width_all(6)
			sb.border_color = Game.PAPER
			sb.shadow_color = Color(Game.TEAL, 0.4)
			sb.shadow_size = 1
			sb.shadow_offset = Vector2(0, 6)
		b.add_theme_stylebox_override(state, sb)
	var ic := Icon.new("lock" if locked else str(st["icon"]), Color.WHITE, 54)
	ic.position = Vector2(29, 29)
	ic.size = Vector2(54, 54)
	b.add_child(ic)
	# nomor pos
	var num := Label.new()
	num.text = str(i + 1)
	num.add_theme_font_override("font", Game.font_display)
	num.add_theme_font_size_override("font_size", 26)
	num.add_theme_color_override("font_color", Game.INK)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.size = Vector2(40, 40)
	num.position = Vector2(-6, -6)
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge := Panel.new()
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Game.SAFFRON
	bsb.set_corner_radius_all(20)
	bsb.border_color = Game.PAPER
	bsb.set_border_width_all(3)
	badge.add_theme_stylebox_override("panel", bsb)
	badge.size = Vector2(40, 40)
	badge.position = Vector2(-6, -6)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(badge)
	b.add_child(num)
	b.pressed.connect(_on_marker.bind(i))
	world.add_child(b)
	markers.append(b)

	# label nama pos
	var pill := UI.panel("Pill")
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := UI.vbox(2)
	pill.add_child(v)
	var nm := UI.label(str(st["name"]), "H3", false, HORIZONTAL_ALIGNMENT_CENTER)
	nm.add_theme_font_size_override("font_size", Game.fs(23))
	v.add_child(nm)
	if not locked:
		var lr := UI.leaves_row(Game.leaves_of(str(st["id"])), 3, 24)
		lr.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_child(lr)
	else:
		var pl := UI.label(str(st["place"]), "Small", false, HORIZONTAL_ALIGNMENT_CENTER)
		v.add_child(pl)
	world.add_child(pill)
	await get_tree().process_frame
	if is_instance_valid(pill):
		pill.position = pos + Vector2(-pill.size.x / 2.0, 64)


func _place_token(i: int, h: float) -> void:
	var pos := _marker_pos(i, h)
	token.position = pos + Vector2(-175, -110)


func _build_overlay() -> void:
	var sa: Vector4 = main.safe_margins()
	var top := UI.margin(22 + sa.x, 14 + sa.y, 22 + sa.z, 0)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	var bar := UI.hbox(12)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(bar)
	var home := UI.btn("Beranda", "Button", "home", 76, 30)
	home.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.home())
	bar.add_child(home)
	var pill := UI.panel("Pill")
	var pr := UI.hbox(10)
	pill.add_child(pr)
	var p := Game.prof()
	pr.add_child(Icon.new("user", Game.TEAL, 30))
	var nm := UI.label(str(p["name"]), "H3")
	pr.add_child(nm)
	pr.add_child(Icon.new("leaf", Game.LEAF, 28))
	pr.add_child(UI.label("%d / %d" % [Game.total_leaves(), Data.STATIONS.size() * 3], "H3"))
	bar.add_child(pill)
	var cap := UI.btn(Game.CAPACITY_NAMES[int(p["capacity"])], "ChoiceButton", "chair", 70, 28)
	cap.tooltip_text = "Ubah cara berlatih"
	cap.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("profiles", {"edit": true}))
	bar.add_child(cap)
	bar.add_child(UI.spacer())
	var jr := UI.btn("Catatan", "SunButton", "calendar", 76, 30)
	jr.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("journal"))
	bar.add_child(jr)
	var st := UI.btn("", "Button", "gear", 76, 34)
	st.tooltip_text = "Pengaturan"
	st.set("accessibility_name", "Pengaturan")
	st.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("settings"))
	bar.add_child(st)

	# tombol geser peta (alternatif selain usap)
	for side: int in [-1, 1]:
		var ab := UI.btn("", "TealButton", "prev" if side < 0 else "next", 96, 46)
		ab.set("accessibility_name", "Pos sebelumnya" if side < 0 else "Pos berikutnya")
		ab.tooltip_text = "Pos sebelumnya" if side < 0 else "Pos berikutnya"
		var vpw := get_viewport_rect().size
		ab.position = Vector2(16 + sa.x if side < 0 else vpw.x - 112 - sa.z, vpw.y * 0.40)
		var sd: int = side
		ab.pressed.connect(func() -> void:
			Sfx.play("tap")
			_scroll_to(clampi(_view_index() + sd, 0, Data.STATIONS.size() - 1), true))
		add_child(ab)

	# Jali dan gelembung bicara di kiri bawah
	jali = Mascot.new()
	jali.size = Vector2(120, 120)
	jali.position = Vector2(18 + sa.x, 104 + sa.y)
	add_child(jali)
	bubble = UI.panel("Cream")
	bubble.position = Vector2(140 + sa.x, 116 + sa.y)
	bubble.visible = false
	bubble.custom_minimum_size = Vector2(520, 0)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble_label = UI.label("", "H3", true)
	bubble_label.custom_minimum_size = Vector2(480, 0)
	bubble.add_child(bubble_label)
	add_child(bubble)


func _say(text: String) -> void:
	bubble_label.text = text
	bubble.visible = true
	bubble.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(bubble, "modulate:a", 1.0, 0.25)
	jali.talking = true
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		if is_instance_valid(jali):
			jali.talking = false)
	Game.speak(text)


func _view_index() -> int:
	var center := scroll.scroll_horizontal + scroll.size.x / 2.0
	return clampi(int(round((center - MARGIN_X + 60.0) / SPACING)), 0, Data.STATIONS.size() - 1)


func _scroll_to(i: int, animate: bool) -> void:
	var h := get_viewport_rect().size.y
	var x := _marker_pos(i, h).x + 60.0 - scroll.size.x / 2.0
	var maxs := maxf(0.0, world.custom_minimum_size.x - scroll.size.x)
	x = clampf(x, 0.0, maxs)
	if animate:
		var tw := create_tween()
		tw.tween_property(scroll, "scroll_horizontal", int(x), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		scroll.scroll_horizontal = int(x)


func _on_marker(i: int) -> void:
	var unlocked := int(Game.prof()["unlocked"])
	if i >= unlocked:
		Sfx.play("soft_no")
		_say("Pos %s masih terkunci. Selesaikan pos sebelumnya dulu, ya." % Data.STATIONS[i]["name"])
		return
	Sfx.play("tap")
	main.go("station", {"index": i})


func _welcome() -> void:
	var p := Game.prof()
	main.show_dialog("Halo, %s! Aku Jali." % p["name"], "Kita akan menjelajah 9 pos di desa. Di setiap pos ada 3 langkah: LIHAT materi, IKUTI gerakan, lalu COBA tantangan. Kumpulkan daun di tiap pos. Bergeraklah sesuai kemampuan, tidak perlu terburu-buru.", [
		{"text": "Ayo mulai", "style": "PrimaryButton", "icon": "play", "is_cancel": true},
	], "leaf")


func default_focus() -> Control:
	return markers[_target] if _target < markers.size() else null


func _process(delta: float) -> void:
	_t += delta
	if _target < _pulse.size():
		(_pulse[_target] as Control).queue_redraw()
