extends Screen
## Layar judul: desa pagi di kaki Gunung Slamet, dua lansia senam di atas tikar.

var putri: ElderFigure
var kakung: ElderFigure
var jali: Mascot
var bubble: SpeechBubble
var _bwrap: VBoxContainer
var _t := 0.0
var _step := -1
var _tip := 0
var _start_btn: Button
var _jali_home := Vector2.ZERO

const CHOREO := [
	{"la": 160.0, "ra": 160.0, "breath": 0.8, "face": "o"},
	{"face": "smile"},
	{"ra": 150.0, "re": 12.0, "tilt": -9.0, "face": "focus"},
	{"face": "smile"},
	{"la": 150.0, "le": 12.0, "tilt": 9.0, "face": "focus"},
	{"face": "happy"},
	{"rl": 0.45, "lf": 0.4, "le": 40.0, "face": "smile"},
	{"ll": 0.45, "rf": 0.4, "re": 40.0, "face": "smile"},
]


func build() -> void:
	var land := Landscape.new()
	land.time_of_day = "pagi"
	land.mountain_x = 0.64
	land.horizon = 0.52
	UI.full(land)
	land.resized.connect(func() -> void:
		var s := land.size.y / 720.0
		land.places = [
			{"kind": "rumah", "x": land.size.x * 0.55, "y": land.size.y * 0.655, "s": 0.66 * s},
			{"kind": "posyandu", "x": land.size.x * 0.92, "y": land.size.y * 0.665, "s": 0.7 * s},
		]
		land.queue_redraw())
	add_child(land)
	for i in 4:
		var c := Cloud.new(150.0 + i * 40.0, 7.0 + i * 3.0)
		c.position = Vector2(i * 380.0 + 60.0, 34.0 + (i % 2) * 64.0)
		c.span = 1700.0
		add_child(c)
	var birds := Decor.new("birds")
	birds.anchor_left = 0.4
	birds.anchor_right = 1.0
	birds.anchor_bottom = 0.4
	add_child(birds)

	# kabut kertas di kiri agar menu mudah dibaca
	var veil := Control.new()
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full(veil)
	veil.draw.connect(func() -> void:
		var w := 640.0
		var h := veil.size.y
		var c0 := Color(Game.CREAM, 0.9)
		var c1 := Color(Game.CREAM, 0.72)
		var c2 := Color(Game.CREAM, 0.0)
		veil.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]), PackedColorArray([c0, c1, c1, c0]))
		veil.draw_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w + 220, 0), Vector2(w + 220, h), Vector2(w, h)]), PackedColorArray([c1, c2, c2, c1])))
	add_child(veil)

	# panggung tokoh
	var stage := Control.new()
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.anchor_left = 0.5
	stage.anchor_right = 1.0
	stage.anchor_top = 0.36
	stage.anchor_bottom = 1.0
	add_child(stage)
	var mat := Decor.new("tikar")
	mat.anchor_left = 0.08
	mat.anchor_right = 0.98
	mat.anchor_top = 0.80
	mat.anchor_bottom = 0.98
	stage.add_child(mat)
	var p := Game.prof()
	putri = ElderFigure.new()
	putri.set_avatar("putri", int(p.get("outfit", 0)) if str(p.get("avatar", "")) == "putri" else 0)
	putri.anchor_left = 0.08
	putri.anchor_right = 0.54
	putri.anchor_bottom = 0.95
	stage.add_child(putri)
	kakung = ElderFigure.new()
	kakung.set_avatar("kakung", int(p.get("outfit", 0)) if str(p.get("avatar", "")) == "kakung" else 0)
	kakung.anchor_left = 0.5
	kakung.anchor_right = 0.96
	kakung.anchor_bottom = 0.95
	stage.add_child(kakung)

	jali = Mascot.new()
	jali.size = Vector2(130, 130)
	jali.facing = -1.0
	add_child(jali)
	_bwrap = VBoxContainer.new()
	_bwrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bwrap.size = Vector2(330, 10)
	add_child(_bwrap)
	bubble = SpeechBubble.new(Data.TIPS[0], "right", "H3")
	_bwrap.add_child(bubble)

	# kolom kiri
	make_content(40)
	var col := UI.vbox(12)
	col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.custom_minimum_size = Vector2(540, 0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(col)

	col.add_child(_profile_chip())
	var logo := _logo()
	col.add_child(logo)
	var rib := Decor.new("ribbon")
	rib.custom_minimum_size = Vector2(360, 50)
	rib.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var rl := UI.label("JELAJAH SEHAT DESA", "OnDark", false, HORIZONTAL_ALIGNMENT_CENTER)
	rl.add_theme_font_override("font", Game.font_caps)
	rl.add_theme_font_size_override("font_size", 22)
	rl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rl.offset_bottom = -5
	rl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rib.add_child(rl)
	var rib_wrap := UI.margin(26, 0, 0, 0)
	rib_wrap.add_child(rib)
	col.add_child(rib_wrap)
	var tag := UI.label("Belajar gerak aman untuk lansia: lihat, pahami, ikuti, lalu ulangi.", "Body", true)
	tag.add_theme_font_size_override("font_size", Game.fs_cap(25))
	col.add_child(tag)
	col.add_child(UI.gap(2))

	_start_btn = UI.btn("Mulai Jelajah", "PrimaryButton", "play", 92, 38)
	_start_btn.custom_minimum_size.x = 540
	(_start_btn.get_meta("label") as Label).add_theme_font_size_override("font_size", Game.fs_cap(30))
	_start_btn.pressed.connect(_on_start)
	col.add_child(_start_btn)
	var nxt := UI.label(_next_hint(), "Small", true)
	nxt.add_theme_font_size_override("font_size", Game.fs_cap(21))
	col.add_child(nxt)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	col.add_child(grid)
	grid.add_child(_tile("Sesi Bersama", "Untuk kader Posyandu", "people", Game.TEAL_MID, func() -> void: main.go("session")))
	grid.add_child(_tile("Catatan", "Riwayat & kuis", "calendar", Game.SAFFRON_DARK, func() -> void:
		if Game.has_profile():
			main.go("journal")
		else:
			main.go("profiles", {"create": true})))
	grid.add_child(_tile("Pengaturan", "Suara & tulisan", "gear", Color("5b6b78"), func() -> void: main.go("settings")))
	grid.add_child(_tile("Info Aplikasi", "Tim & mitra", "info", Game.TERRA, func() -> void: main.go("info")))

	reveal([col.get_child(0), logo, rib_wrap, tag, _start_btn, nxt, grid])
	if Game.motion():
		logo.pivot_offset = Vector2(0, 50)


func _profile_chip() -> Control:
	var row := UI.hbox(10)
	var chip := UI.panel("Pill")
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var h := UI.hbox(10)
	chip.add_child(h)
	var p := Game.prof()
	h.add_child(UI.badge("user", Game.TEAL_MID if Game.has_profile() else Color("9aa5a3"), 40))
	var who := "Belum ada peserta" if not Game.has_profile() else str(p["name"])
	var nl := UI.label(who, "H3")
	nl.add_theme_font_size_override("font_size", Game.fs_cap(24))
	h.add_child(nl)
	if Game.has_profile():
		h.add_child(Icon.new("leaf", Game.LEAF, 26))
		var lv := UI.label(str(Game.total_leaves()), "H3")
		lv.add_theme_font_size_override("font_size", Game.fs_cap(24))
		h.add_child(lv)
	row.add_child(chip)
	var change := UI.btn("Ganti peserta" if Game.has_profile() else "Buat peserta", "GhostButton", "people", 60, 26)
	change.pressed.connect(func() -> void:
		Sfx.play("tap")
		main.go("profiles", {} if Game.has_profile() else {"create": true}))
	row.add_child(change)
	return row


func _logo() -> Control:
	var box := UI.hbox(0)
	box.add_theme_constant_override("separation", 0)
	var a := UI.label("VITA", "Display")
	a.add_theme_color_override("font_outline_color", Game.PAPER)
	a.add_theme_constant_override("outline_size", 16)
	box.add_child(a)
	var b := UI.label("MOVE", "Display")
	b.add_theme_color_override("font_color", Game.TERRA)
	b.add_theme_color_override("font_outline_color", Game.PAPER)
	b.add_theme_constant_override("outline_size", 16)
	box.add_child(b)
	var leaf := Icon.new("leaf", Game.LEAF, 64)
	leaf.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	box.add_child(leaf)
	var sp := Decor.new("sparkles")
	sp.color = Game.SAFFRON
	sp.custom_minimum_size = Vector2(60, 90)
	box.add_child(sp)
	return box


func _tile(title: String, sub: String, icon: String, col: Color, cb: Callable) -> TapCard:
	var t := TapCard.new()
	t.custom_minimum_size = Vector2(263, 0)
	t.set("accessibility_name", title)
	var h := UI.hbox(12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_child(h)
	h.add_child(UI.badge(icon, col, 52))
	var v := UI.vbox(0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var tl := UI.label(title, "H3")
	tl.add_theme_font_size_override("font_size", Game.fs_cap(24))
	v.add_child(tl)
	var sl := UI.label(sub, "Small")
	sl.add_theme_font_size_override("font_size", Game.fs_cap(19))
	v.add_child(sl)
	h.add_child(v)
	t.pressed.connect(func() -> void:
		Sfx.play("tap")
		cb.call())
	return t


func _next_hint() -> String:
	if not Game.has_profile():
		return "Mulai dengan membuat peserta. Ditemani Jali si Jalak!"
	var u := clampi(int(Game.prof()["unlocked"]) - 1, 0, Data.STATIONS.size() - 1)
	if Game.stations_done() >= Data.STATIONS.size():
		return "Semua pos selesai. Ulangi latihan favorit Mbah kapan saja."
	return "Berikutnya: Pos %d · %s di %s" % [u + 1, Data.STATIONS[u]["name"], Data.STATIONS[u]["place"]]


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
	var period := 1.9
	var s := int(_t / period) % CHOREO.size()
	if s != _step:
		_step = s
		putri.set_pose(CHOREO[s])
		var k2: Dictionary = CHOREO[(s + 1) % CHOREO.size()] if s % 2 == 1 else CHOREO[s]
		kakung.set_pose(k2)
	# Jali melayang pelan membentuk angka delapan
	var vp := size
	_jali_home = Vector2(vp.x * 0.86, vp.y * 0.2)
	var amp := 26.0 if Game.motion() else 0.0
	jali.position = _jali_home + Vector2(sin(_t * 0.6) * amp * 1.6, sin(_t * 1.2) * amp * 0.6) - jali.size / 2.0
	jali.flap = true
	jali.talking = fmod(_t, 7.0) < 1.6
	_bwrap.position = Vector2(_jali_home.x - _bwrap.size.x - 70, _jali_home.y - _bwrap.size.y / 2.0 - 6)
	var ti := int(_t / 7.0) % Data.TIPS.size()
	if ti != _tip:
		_tip = ti
		bubble.set_text(Data.TIPS[ti])
		_bwrap.size = Vector2(330, 10)
		bubble.pop()
