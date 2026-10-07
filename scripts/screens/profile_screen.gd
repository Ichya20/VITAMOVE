extends Screen
## Daftar peserta (satu perangkat dipakai bersama di Posyandu) dan pembuatan profil 3 langkah.

var step := 0  # 0 = daftar, 1 = tokoh, 2 = nama & baju, 3 = cara berlatih
var draft := {"avatar": "putri", "name": "", "capacity": 1, "outfit": 0}
var body: VBoxContainer
var _focus: Control
var _name_edit: LineEdit
var _err: Label
var _preview: ElderFigure
var _stepper: Stepper


func build() -> void:
	scene_bg("rumah", "pagi", 0.42)
	make_content(28)
	body = UI.vbox(14)
	content.add_child(body)
	step = 1 if (bool(params.get("create", false)) or Game.profiles.is_empty()) else 0
	if bool(params.get("edit", false)) and Game.has_profile():
		var p := Game.prof()
		draft = {"avatar": p["avatar"], "name": p["name"], "capacity": int(p["capacity"]), "outfit": int(p.get("outfit", 0))}
		step = 3
	_render()


func _clear() -> void:
	for c in body.get_children():
		c.queue_free()
	_focus = null


func _render() -> void:
	_clear()
	match step:
		0: _render_list()
		1: _render_avatar()
		2: _render_name()
		3: _render_capacity()


func on_back() -> bool:
	if bool(params.get("edit", false)):
		return false
	if step > 1:
		step -= 1
		_render()
		return true
	if step == 1 and not Game.profiles.is_empty() and not bool(params.get("create", false)):
		step = 0
		_render()
		return true
	return false


func default_focus() -> Control:
	return _focus


func _header(title: String, eyebrow: String) -> void:
	var bar := header(title, eyebrow)
	if step >= 1 and not bool(params.get("edit", false)):
		_stepper = Stepper.new(["Tokoh", "Nama", "Cara"])
		_stepper.set_current(step - 1)
		_stepper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header_add(bar, _stepper)
	body.add_child(bar)


# ------------------------------------------------------------------ daftar

func _render_list() -> void:
	_header("Pilih Peserta", "Satu perangkat, banyak peserta")
	var sc := UI.scroll_v()
	body.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(UI.xmargin(8, 8, 8, 16))
	sc.get_child(0).add_child(grid)
	var cards: Array = []
	for i in Game.profiles.size():
		var c := _profile_card(i)
		grid.add_child(c)
		cards.append(c)
	var add := TapCard.new()
	add.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add.custom_minimum_size = Vector2(0, 230)
	var av := UI.vbox(10)
	av.alignment = BoxContainer.ALIGNMENT_CENTER
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add.add_child(av)
	av.add_child(UI.badge("plus", Game.TERRA, 76))
	av.add_child(UI.label("Tambah Peserta", "H2", false, HORIZONTAL_ALIGNMENT_CENTER))
	av.add_child(UI.label("Lansia baru di Posyandu", "Small", false, HORIZONTAL_ALIGNMENT_CENTER))
	add.pressed.connect(func() -> void:
		Sfx.play("tap")
		draft = {"avatar": "putri", "name": "", "capacity": 1, "outfit": 0}
		step = 1
		_render())
	grid.add_child(add)
	cards.append(add)
	if _focus == null:
		_focus = add
	reveal(cards)


func _profile_card(i: int) -> Control:
	var p: Dictionary = Game.profiles[i]
	var card := TapCard.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.selected = i == Game.current
	card.set("accessibility_name", "Pilih " + str(p["name"]))
	var h := UI.hbox(12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(h)
	var fig := ElderFigure.new()
	fig.set_avatar(str(p["avatar"]), int(p.get("outfit", 0)))
	fig.custom_minimum_size = Vector2(112, 196)
	fig.show_ground = false
	fig.set_pose({"ra": 135.0, "re": 25.0, "head": 0.15, "face": "happy" if i == Game.current else "smile"})
	h.add_child(fig)
	var v := UI.vbox(6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	if i == Game.current:
		v.add_child(UI.label("Sedang dipilih", "Caption"))
	var nm := UI.label(str(p["name"]), "H2")
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.custom_minimum_size.x = 150
	v.add_child(nm)
	var lr := UI.hbox(8)
	lr.add_child(UI.leaves_row(mini(3, int(ceil(Game.total_leaves(p) / 9.0))), 3, 24))
	lr.add_child(UI.label("%d daun" % Game.total_leaves(p), "Small"))
	v.add_child(lr)
	v.add_child(UI.progress(Game.stations_done(p), Data.STATIONS.size(), 14))
	v.add_child(UI.chip(Game.CAPACITY_SHORT[int(p["capacity"])], "Chip", "chair"))
	var del := UI.btn("Hapus", "GhostButton", "close", 52, 22)
	del.size_flags_horizontal = Control.SIZE_SHRINK_END
	(del.get_meta("label") as Label).add_theme_color_override("font_color", Game.DANGER)
	(del.get_meta("icon") as Icon).color = Game.DANGER
	(del.get_meta("label") as Label).add_theme_font_size_override("font_size", Game.fs(20))
	del.pressed.connect(_confirm_delete.bind(i))
	v.add_child(del)
	card.pressed.connect(func() -> void:
		Sfx.play("success")
		Game.select_profile(i)
		main.replace_with("map"))
	if i == Game.current:
		_focus = card
	return card


func _confirm_delete(i: int) -> void:
	Sfx.play("tap")
	var p: Dictionary = Game.profiles[i]
	main.show_dialog("Hapus %s?" % p["name"], "Semua catatan latihan peserta ini akan terhapus dan tidak dapat dikembalikan.", [
		{"text": "Batal", "style": "Button", "is_cancel": true},
		{"text": "Hapus", "style": "DangerButton", "cb": _do_delete.bind(i)},
	], "close", "danger")


func _do_delete(i: int) -> void:
	Game.delete_profile(i)
	if Game.profiles.is_empty():
		step = 1
	_render()


# ------------------------------------------------------------------ langkah 1: tokoh

func _render_avatar() -> void:
	_header("Siapa yang berlatih?", "Peserta baru · langkah 1 dari 3")
	var row := UI.hbox(28)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(row)
	var cards: Array = []
	for a in [["putri", "Mbah Putri", "Berkerudung, ceria"], ["kakung", "Mbah Kakung", "Berpeci, bersemangat"]]:
		var b := TapCard.new()
		b.custom_minimum_size = Vector2(360, 0)
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.selected = draft["avatar"] == a[0]
		b.set("accessibility_name", a[1])
		var v := UI.vbox(4)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		var stage := Control.new()
		stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(stage)
		var mat := Decor.new("tikar")
		mat.anchor_left = 0.12
		mat.anchor_right = 0.88
		mat.anchor_top = 0.84
		mat.anchor_bottom = 1.0
		stage.add_child(mat)
		var fig := ElderFigure.new()
		fig.set_avatar(a[0])
		UI.full(fig)
		fig.set_pose({"ra": 140.0, "re": 25.0, "head": 0.2, "face": "happy"})
		stage.add_child(fig)
		v.add_child(UI.label(a[1], "H1", false, HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UI.label(a[2], "Small", false, HORIZONTAL_ALIGNMENT_CENTER))
		var av: String = a[0]
		b.pressed.connect(func() -> void:
			Sfx.play("pop")
			if draft["avatar"] != av:
				draft["outfit"] = 0
			draft["avatar"] = av
			if draft["name"] == "" or draft["name"] in ["Mbah Sri", "Mbah Darmo"]:
				draft["name"] = "Mbah Sri" if av == "putri" else "Mbah Darmo"
			step = 2
			_render())
		row.add_child(b)
		cards.append(b)
		if _focus == null or b.selected:
			_focus = b
	reveal(cards, 0.1)


# ------------------------------------------------------------------ langkah 2: nama & baju

func _render_name() -> void:
	_header("Nama & warna baju", "Peserta baru · langkah 2 dari 3")
	var card := UI.panel("Card")
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(card)
	var h := UI.hbox(30)
	card.add_child(h)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(300, 0)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(stage)
	var mat := Decor.new("tikar")
	mat.anchor_left = 0.06
	mat.anchor_right = 0.94
	mat.anchor_top = 0.84
	mat.anchor_bottom = 1.0
	stage.add_child(mat)
	_preview = ElderFigure.new()
	_preview.set_avatar(str(draft["avatar"]), int(draft["outfit"]))
	UI.full(_preview)
	_preview.set_pose({"la": 40.0, "ra": 40.0, "face": "smile"})
	stage.add_child(_preview)
	var v := UI.vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	v.add_child(UI.label("Nama panggilan", "H3"))
	_name_edit = LineEdit.new()
	_name_edit.text = str(draft["name"]) if draft["name"] != "" else ("Mbah Sri" if draft["avatar"] == "putri" else "Mbah Darmo")
	_name_edit.placeholder_text = "Contoh: Mbah Sri"
	_name_edit.max_length = 24
	_name_edit.custom_minimum_size = Vector2(0, 84)
	_name_edit.select_all_on_focus = true
	_name_edit.set("accessibility_name", "Nama panggilan")
	_name_edit.text_submitted.connect(func(_t: String) -> void: _name_next())
	v.add_child(_name_edit)
	_err = UI.label("", "Body", true)
	_err.add_theme_color_override("font_color", Game.DANGER)
	_err.visible = false
	v.add_child(_err)
	var chips := UI.hbox(10)
	for n in (["Mbah Sri", "Mbah Painem", "Mbah Warsini"] if draft["avatar"] == "putri" else ["Mbah Darmo", "Mbah Karto", "Mbah Slamet"]):
		var c := UI.btn(n, "ChoiceButton", "", 60)
		c.add_theme_font_size_override("font_size", Game.fs(21))
		var nn: String = n
		c.pressed.connect(func() -> void:
			Sfx.play("tap")
			_name_edit.text = nn
			_err.visible = false)
		chips.add_child(c)
	v.add_child(UI.label("Atau ketuk salah satu:", "Small"))
	v.add_child(chips)
	v.add_child(UI.label("Warna baju", "H3"))
	var sw := UI.hbox(14)
	var names := ["Hijau tosca", "Terakota", "Ungu"] if draft["avatar"] == "putri" else ["Batik merah", "Batik tosca", "Batik biru"]
	for i in 3:
		var oc: Dictionary = Game.outfit_colors(str(draft["avatar"]), i)
		var t := TapCard.new()
		t.selected = int(draft["outfit"]) == i
		t.set("accessibility_name", names[i])
		var th := UI.hbox(8)
		th.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.add_child(th)
		var dot := Control.new()
		dot.custom_minimum_size = Vector2(40, 40)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var top_c: Color = oc["top"]
		var sc_c: Color = oc["scarf"] if draft["avatar"] == "putri" else oc["motif"]
		dot.draw.connect(func() -> void:
			dot.draw_circle(Vector2(20, 20), 19, Game.OUTLINE, true, -1.0, true)
			dot.draw_circle(Vector2(20, 20), 16, top_c, true, -1.0, true)
			dot.draw_circle(Vector2(26, 13), 7, sc_c, true, -1.0, true))
		th.add_child(dot)
		var tl := UI.label(names[i], "H3")
		tl.add_theme_font_size_override("font_size", Game.fs(20))
		th.add_child(tl)
		var idx := i
		t.pressed.connect(func() -> void:
			Sfx.play("pop")
			draft["outfit"] = idx
			_preview.set_avatar(str(draft["avatar"]), idx)
			_preview.set_pose({"la": 150.0, "ra": 150.0, "face": "happy"})
			for s in sw.get_children():
				(s as TapCard).selected = s == t)
		sw.add_child(t)
	v.add_child(sw)
	var nxt := UI.btn("Lanjut", "PrimaryButton", "next", 84, 32)
	nxt.size_flags_horizontal = Control.SIZE_SHRINK_END
	nxt.pressed.connect(_name_next)
	v.add_child(nxt)
	_focus = nxt
	reveal([stage, v])


func _name_next() -> void:
	var n := _name_edit.text.strip_edges()
	if n.length() < 2:
		Sfx.play("soft_no")
		_err.text = "Nama perlu diisi, minimal 2 huruf."
		_err.visible = true
		_name_edit.grab_focus()
		return
	Sfx.play("tap")
	draft["name"] = n
	DisplayServer.virtual_keyboard_hide()
	step = 3
	_render()


# ------------------------------------------------------------------ langkah 3: cara berlatih

func _render_capacity() -> void:
	var editing := bool(params.get("edit", false))
	_header("Ubah cara berlatih" if editing else "Cara berlatih", "Pilih yang paling nyaman · bisa diubah kapan saja" if editing else "Peserta baru · langkah 3 dari 3")
	var note := UI.panel("Info")
	note.add_child(UI.label("Bila ragu, pilih bersama kader atau tenaga kesehatan.", "Body", true))
	body.add_child(note)
	var row := UI.hbox(18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(row)
	var poses := [
		{"chair": 1, "pose": {"sit": 1.0, "ra": 70.0, "la": 70.0, "face": "smile"}},
		{"chair": 2, "pose": {"la": 20.0, "face": "smile"}, "support": true},
		{"chair": 0, "pose": {"la": 160.0, "ra": 160.0, "face": "happy"}},
	]
	var cards: Array = []
	for i in 3:
		var b := TapCard.new()
		b.selected = int(draft["capacity"]) == i
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.set("accessibility_name", Game.CAPACITY_NAMES[i])
		var v := UI.vbox(6)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		var fig := ElderFigure.new()
		fig.set_avatar(str(draft["avatar"]), int(draft["outfit"]))
		fig.chair = int(poses[i]["chair"])
		fig.support_hand = bool(poses[i].get("support", false))
		fig.set_pose(poses[i]["pose"])
		fig.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fig.custom_minimum_size = Vector2(150, 140)
		v.add_child(fig)
		var tl := UI.label(Game.CAPACITY_NAMES[i], "H2", true, HORIZONTAL_ALIGNMENT_CENTER)
		tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(tl)
		var d := UI.label(Game.CAPACITY_DESC[i], "Small", true, HORIZONTAL_ALIGNMENT_CENTER)
		v.add_child(d)
		var idx := i
		b.pressed.connect(func() -> void:
			Sfx.play("success")
			draft["capacity"] = idx
			if editing and Game.has_profile():
				Game.profiles[Game.current]["capacity"] = idx
				Game.save_data()
				main.back()
				return
			Game.add_profile(str(draft["name"]), str(draft["avatar"]), idx, int(draft["outfit"]))
			main.replace_with("map", {"welcome": true}))
		row.add_child(b)
		cards.append(b)
		if i == int(draft["capacity"]):
			_focus = b
	reveal(cards)
