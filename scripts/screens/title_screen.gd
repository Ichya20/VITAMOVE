extends Screen
## Layar judul: desa pagi di kaki Gunung Slamet.

var putri: ElderFigure
var kakung: ElderFigure
var jali: Mascot
var bubble: PanelContainer
var _t := 0.0
var _start_btn: Button


func build() -> void:
	var land := Landscape.new()
	land.time_of_day = "pagi"
	land.mountain_x = 0.62
	land.horizon = 0.52
	UI.full(land)
	land.resized.connect(func() -> void:
		var s := land.size.y / 720.0
		land.places = [
			{"kind": "rumah", "x": land.size.x * 0.56, "y": land.size.y * 0.66, "s": 0.7 * s},
			{"kind": "posyandu", "x": land.size.x * 0.90, "y": land.size.y * 0.67, "s": 0.75 * s},
		]
		land.queue_redraw())
	add_child(land)

	for i in 4:
		var c := Cloud.new(150.0 + i * 40.0, 8.0 + i * 3.0)
		c.position = Vector2(i * 360.0 + 60.0, 40.0 + (i % 2) * 70.0)
		c.span = 1600.0
		add_child(c)

	# Tokoh lansia di pematang
	var stage := Control.new()
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.anchor_left = 0.52
	stage.anchor_right = 1.0
	stage.anchor_top = 0.38
	stage.anchor_bottom = 1.0
	add_child(stage)
	putri = ElderFigure.new()
	putri.set_avatar("putri")
	putri.anchor_left = 0.05
	putri.anchor_right = 0.5
	putri.anchor_top = 0.0
	putri.anchor_bottom = 0.98
	stage.add_child(putri)
	kakung = ElderFigure.new()
	kakung.set_avatar("kakung")
	kakung.anchor_left = 0.46
	kakung.anchor_right = 0.92
	kakung.anchor_top = 0.0
	kakung.anchor_bottom = 0.98
	stage.add_child(kakung)

	jali = Mascot.new()
	jali.anchor_left = 0.80
	jali.anchor_right = 0.80
	jali.anchor_top = 0.16
	jali.anchor_bottom = 0.16
	jali.offset_left = -70
	jali.offset_right = 70
	jali.offset_top = -70
	jali.offset_bottom = 70
	jali.facing = -1.0
	add_child(jali)
	bubble = UI.panel("Pill")
	bubble.anchor_left = 0.80
	bubble.anchor_right = 0.80
	bubble.anchor_top = 0.16
	bubble.anchor_bottom = 0.16
	bubble.offset_left = -470
	bubble.offset_right = -80
	bubble.offset_top = -40
	bubble.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var bl := UI.label("Ayo bergerak bersama, Mbah!", "H3", true)
	bubble.add_child(bl)
	add_child(bubble)

	# Kolom kiri: logo dan menu, dengan kabut kertas agar teks mudah dibaca
	var veil := Control.new()
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full(veil)
	veil.draw.connect(func() -> void:
		var w := 660.0
		var h := veil.size.y
		veil.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w + 160, 0), Vector2(w + 160, h), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color(Game.CREAM, 0.85), Color(Game.CREAM, 0.6), Color(Game.CREAM, 0.0), Color(Game.CREAM, 0.0), Color(Game.CREAM, 0.6), Color(Game.CREAM, 0.85)])))
	add_child(veil)
	move_child(veil, 1)
	make_content(36)
	var col := UI.vbox(14)
	col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.custom_minimum_size = Vector2(500, 0)
	content.add_child(col)

	var pill := UI.panel("Pill")
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var pr := UI.hbox(10)
	pill.add_child(pr)
	pr.add_child(Icon.new("user", Game.TEAL, 30))
	var who := "Belum ada pemain" if not Game.has_profile() else str(Game.prof()["name"])
	pr.add_child(UI.label(who, "H3"))
	var lv := Game.total_leaves() if Game.has_profile() else 0
	if Game.has_profile():
		pr.add_child(Icon.new("leaf", Game.LEAF, 28))
		pr.add_child(UI.label(str(lv), "H3"))
	var change := UI.btn("Ganti", "ChoiceButton", "", 56)
	change.add_theme_font_size_override("font_size", Game.fs(22))
	change.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("profiles"))
	pr.add_child(change)
	col.add_child(pill)

	col.add_child(UI.gap(4))
	col.add_child(_logo())
	var sub := UI.label("Jelajah Sehat Desa", "H2")
	sub.add_theme_color_override("font_color", Game.TERRA_DARK)
	col.add_child(sub)
	var tag := UI.label("Edukasi aktivitas fisik untuk lansia: lihat, pahami, ikuti, ulangi.", "Body", true)
	tag.custom_minimum_size = Vector2(480, 0)
	col.add_child(tag)
	col.add_child(UI.gap(6))

	_start_btn = UI.btn("Mulai Jelajah", "PrimaryButton", "play", 92, 40)
	_start_btn.custom_minimum_size.x = 480
	_start_btn.pressed.connect(_on_start)
	col.add_child(_start_btn)
	var row := UI.hbox(14)
	var sess := UI.btn("Sesi Bersama", "TealButton", "people", 84, 34)
	sess.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sess.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("session"))
	row.add_child(sess)
	var jr := UI.btn("Catatan", "SunButton", "calendar", 84, 34)
	jr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jr.pressed.connect(func() -> void:
		Sfx.play("tap")
		if Game.has_profile():
			main.go("journal")
		else:
			main.go("profiles", {"create": true}))
	row.add_child(jr)
	row.custom_minimum_size.x = 480
	col.add_child(row)
	var row2 := UI.hbox(14)
	row2.custom_minimum_size.x = 480
	var st := UI.btn("Pengaturan", "Button", "gear", 76, 30)
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("settings"))
	row2.add_child(st)
	var inf := UI.btn("Info Aplikasi", "Button", "info", 76, 30)
	inf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inf.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("info"))
	row2.add_child(inf)
	col.add_child(row2)

	# masuk dengan animasi lembut
	col.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(col, "modulate:a", 1.0, 0.5)


func _logo() -> Control:
	var box := UI.hbox(0)
	box.add_theme_constant_override("separation", 0)
	var a := Label.new()
	a.text = "VITA"
	a.theme_type_variation = "Title"
	box.add_child(a)
	var b := Label.new()
	b.text = "MOVE"
	b.theme_type_variation = "Title"
	b.add_theme_color_override("font_color", Game.TERRA)
	box.add_child(b)
	var leaf := Icon.new("leaf", Game.LEAF, 60)
	leaf.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	box.add_child(leaf)
	return box


func _on_start() -> void:
	Sfx.play("tap")
	if Game.has_profile():
		main.go("map")
	else:
		main.go("profiles", {"create": true})


func default_focus() -> Control:
	return _start_btn


func _process(delta: float) -> void:
	_t += delta
	if putri == null:
		return
	# Mbah Putri melambai, Mbah Kakung jalan di tempat pelan
	var w := sin(_t * 3.0)
	putri.set_pose({"ra": 150.0, "re": 20.0 + w * 18.0, "la": 10.0, "head": 0.25, "smile": 1.0})
	var m := sin(_t * 2.2)
	kakung.set_pose({"ll": maxf(0.0, m) * 0.35, "rl": maxf(0.0, -m) * 0.35, "lf": maxf(0.0, -m) * 0.4, "rf": maxf(0.0, m) * 0.4, "le": 30.0, "re": 30.0, "head": -0.2})
	jali.talking = fmod(_t, 6.0) < 1.8
	bubble.modulate.a = clampf(1.0 - absf(fmod(_t, 6.0) - 2.0) / 3.5, 0.0, 1.0) * 0.3 + 0.7
