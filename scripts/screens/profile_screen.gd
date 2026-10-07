extends Screen
## Daftar peserta (satu perangkat dapat dipakai bersama di Posyandu) dan pembuatan profil.

var step := 0  # 0 = daftar, 1 = avatar, 2 = nama, 3 = kemampuan
var draft := {"avatar": "putri", "name": "", "capacity": 1}
var body: VBoxContainer
var _focus: Control
var _name_edit: LineEdit
var _err: Label


func build() -> void:
	soft_bg("rumah", "pagi", 0.62)
	make_content(30)
	body = UI.vbox(16)
	content.add_child(body)
	step = 1 if (bool(params.get("create", false)) or Game.profiles.is_empty()) else 0
	if bool(params.get("edit", false)) and Game.has_profile():
		var p := Game.prof()
		draft = {"avatar": p["avatar"], "name": p["name"], "capacity": int(p["capacity"])}
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


func _header(title: String, sub: String) -> void:
	var bar := top_bar(title)
	body.add_child(bar)
	if step >= 1:
		var back: Button = bar.get_meta("back")
		for c in back.pressed.get_connections():
			back.pressed.disconnect(c["callable"])
		back.pressed.connect(func() -> void:
			Sfx.play("tap")
			if not on_back():
				main.back())
	if sub != "":
		body.add_child(UI.label(sub, "Body", true))


# ------------------------------------------------------------------ daftar

func _render_list() -> void:
	_header("Pilih Peserta", "Satu perangkat bisa dipakai beberapa lansia. Ketuk nama untuk mulai.")
	var sc := UI.scroll_v()
	body.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(grid)
	for i in Game.profiles.size():
		grid.add_child(_profile_card(i))
	var add := UI.btn("Tambah Peserta", "PrimaryButton", "plus", 120, 40)
	add.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add.custom_minimum_size.y = 230
	add.pressed.connect(func() -> void:
		Sfx.play("tap")
		draft = {"avatar": "putri", "name": "", "capacity": 1}
		step = 1
		_render())
	grid.add_child(add)
	if Game.profiles.size() > 0:
		_focus = null


func _profile_card(i: int) -> Control:
	var p: Dictionary = Game.profiles[i]
	var card := UI.panel("Cream" if i == Game.current else "Card")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := UI.hbox(10)
	card.add_child(h)
	var fig := ElderFigure.new()
	fig.set_avatar(str(p["avatar"]))
	fig.custom_minimum_size = Vector2(110, 190)
	fig.show_ground = false
	h.add_child(fig)
	var v := UI.vbox(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var nm := UI.label(str(p["name"]), "H2")
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.custom_minimum_size.x = 150
	v.add_child(nm)
	var lr := UI.hbox(6)
	lr.add_child(Icon.new("leaf", Game.LEAF, 28))
	lr.add_child(UI.label("%d daun" % Game.total_leaves(p), "Body"))
	v.add_child(lr)
	var cap := UI.label(Game.CAPACITY_NAMES[int(p["capacity"])], "Small", true)
	v.add_child(cap)
	var br := UI.hbox(10)
	var pick := UI.btn("Pilih", "TealButton", "check", 72, 28)
	pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pick.pressed.connect(func() -> void:
		Sfx.play("success")
		Game.select_profile(i)
		main.replace_with("map"))
	br.add_child(pick)
	var del := UI.btn("", "DangerButton", "close", 72, 28)
	del.tooltip_text = "Hapus peserta"
	del.set("accessibility_name", "Hapus " + str(p["name"]))
	del.pressed.connect(_confirm_delete.bind(i))
	br.add_child(del)
	v.add_child(br)
	if _focus == null:
		_focus = pick
	return card


func _confirm_delete(i: int) -> void:
	Sfx.play("tap")
	var p: Dictionary = Game.profiles[i]
	main.show_dialog("Hapus %s?" % p["name"], "Semua catatan latihan peserta ini akan terhapus dan tidak dapat dikembalikan.", [
		{"text": "Batal", "style": "Button", "is_cancel": true},
		{"text": "Hapus", "style": "DangerButton", "cb": _do_delete.bind(i)},
	], "close")


func _do_delete(i: int) -> void:
	Game.delete_profile(i)
	if Game.profiles.is_empty():
		step = 1
	_render()


# ------------------------------------------------------------------ langkah 1: avatar

func _render_avatar() -> void:
	_header("Peserta Baru  (1/3)", "Siapa yang akan berlatih? Pilih tokoh yang paling mirip.")
	var row := UI.hbox(26)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(row)
	for a in [["putri", "Mbah Putri"], ["kakung", "Mbah Kakung"]]:
		var b := Button.new()
		b.theme_type_variation = "ChoiceButton"
		b.toggle_mode = true
		b.button_pressed = draft["avatar"] == a[0]
		b.custom_minimum_size = Vector2(330, 0)
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.set("accessibility_name", a[1])
		var v := UI.vbox(4)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.full(v)
		b.add_child(v)
		var fig := ElderFigure.new()
		fig.set_avatar(a[0])
		fig.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fig.set_pose({"ra": 140.0, "re": 25.0, "head": 0.2})
		v.add_child(fig)
		var l := UI.label(a[1], "H2", false, HORIZONTAL_ALIGNMENT_CENTER)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
		v.add_child(UI.gap(8))
		var av: String = a[0]
		b.pressed.connect(func() -> void:
			Sfx.play("tap")
			draft["avatar"] = av
			if draft["name"] == "" or draft["name"] in ["Mbah Sri", "Mbah Darmo"]:
				draft["name"] = "Mbah Sri" if av == "putri" else "Mbah Darmo"
			step = 2
			_render())
		row.add_child(b)
		if _focus == null:
			_focus = b


# ------------------------------------------------------------------ langkah 2: nama

func _render_name() -> void:
	_header("Peserta Baru  (2/3)", "Tulis nama panggilan. Boleh dibantu kader.")
	var card := UI.panel("Card")
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(card)
	var h := UI.hbox(30)
	card.add_child(h)
	var fig := ElderFigure.new()
	fig.set_avatar(str(draft["avatar"]))
	fig.custom_minimum_size = Vector2(240, 0)
	h.add_child(fig)
	var v := UI.vbox(16)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	var lab := UI.label("Nama panggilan", "H3")
	v.add_child(lab)
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
	v.add_child(_err)
	var chips := UI.hbox(12)
	for n in (["Mbah Sri", "Mbah Painem", "Mbah Warsini"] if draft["avatar"] == "putri" else ["Mbah Darmo", "Mbah Karto", "Mbah Slamet"]):
		var c := UI.btn(n, "ChoiceButton", "", 64)
		c.add_theme_font_size_override("font_size", Game.fs(22))
		var nn: String = n
		c.pressed.connect(func() -> void:
			Sfx.play("tap")
			_name_edit.text = nn
			_err.text = "")
		chips.add_child(c)
	v.add_child(UI.label("Atau ketuk salah satu:", "Small"))
	v.add_child(chips)
	var nxt := UI.btn("Lanjut", "PrimaryButton", "next", 88, 34)
	nxt.size_flags_horizontal = Control.SIZE_SHRINK_END
	nxt.pressed.connect(_name_next)
	v.add_child(nxt)
	_focus = nxt


func _name_next() -> void:
	var n := _name_edit.text.strip_edges()
	if n.length() < 2:
		Sfx.play("soft_no")
		_err.text = "Nama perlu diisi, minimal 2 huruf."
		_name_edit.grab_focus()
		return
	Sfx.play("tap")
	draft["name"] = n
	DisplayServer.virtual_keyboard_hide()
	step = 3
	_render()


# ------------------------------------------------------------------ langkah 3: kemampuan

func _render_capacity() -> void:
	_header("Ubah Cara Berlatih" if bool(params.get("edit", false)) else "Peserta Baru  (3/3)", "Pilih cara berlatih yang paling nyaman. Bila ragu, tanyakan kader atau tenaga kesehatan. Bisa diubah kapan saja.")
	var row := UI.hbox(18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(row)
	var poses := [
		{"chair": 1, "pose": {"sit": 1.0, "ra": 60.0, "la": 60.0}},
		{"chair": 2, "pose": {"heel": 0.0}, "support": true},
		{"chair": 0, "pose": {"la": 70.0, "ra": 70.0}},
	]
	for i in 3:
		var b := Button.new()
		b.theme_type_variation = "ChoiceButton"
		b.toggle_mode = true
		b.button_pressed = int(draft["capacity"]) == i
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.set("accessibility_name", Game.CAPACITY_NAMES[i])
		var v := UI.vbox(6)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := UI.margin(12, 10, 12, 12)
		m.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.full(m)
		m.add_child(v)
		b.add_child(m)
		var fig := ElderFigure.new()
		fig.set_avatar(str(draft["avatar"]))
		fig.chair = int(poses[i]["chair"])
		fig.support_hand = bool(poses[i].get("support", false))
		fig.set_pose(poses[i]["pose"])
		fig.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fig.custom_minimum_size = Vector2(150, 150)
		v.add_child(fig)
		var t := UI.label(Game.CAPACITY_NAMES[i], "H3", true, HORIZONTAL_ALIGNMENT_CENTER)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(t)
		var d := UI.label(Game.CAPACITY_DESC[i], "Small", true, HORIZONTAL_ALIGNMENT_CENTER)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(d)
		var idx := i
		b.pressed.connect(func() -> void:
			Sfx.play("success")
			draft["capacity"] = idx
			if bool(params.get("edit", false)) and Game.has_profile():
				Game.profiles[Game.current]["capacity"] = idx
				Game.save_data()
				main.back()
				return
			Game.add_profile(str(draft["name"]), str(draft["avatar"]), idx)
			main.replace_with("map", {"welcome": true}))
		row.add_child(b)
		if i == int(draft["capacity"]):
			_focus = b
