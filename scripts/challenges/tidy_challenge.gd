class_name TidyChallenge
extends VBoxContainer
## "Rapikan Rumah Mbah": ketuk benda yang berbahaya agar ruang latihan aman.

signal done(score: int, total: int)

const ART := {
	"Karpet terlipat": "karpet", "Kursi beroda": "kursi_roda", "Lantai basah": "lantai_basah", "Kabel melintang": "kabel",
	"Sandal licin": "sandal_licin", "Gelas air putih": "gelas", "Kursi kayu kokoh": "kursi_kayu", "Lampu terang": "lampu",
}

var _bad_total := 0
var _fixed := 0
var _mistakes := 0
var _status: Label
var _bar: ProgressBar
var _msg: Label
var _finish: Button


func setup() -> void:
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var head := UI.hbox(12)
	head.add_child(UI.badge("home", Game.TERRA, 48))
	var hv := UI.vbox(0)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(UI.label("Rapikan Rumah Mbah", "H2"))
	hv.add_child(UI.label("Ketuk benda yang BERBAHAYA saat latihan. Benda yang aman biarkan saja.", "Small", true))
	head.add_child(hv)
	_bar = UI.progress(0, 1, 14, Game.LEAF)
	_bar.custom_minimum_size.x = 170
	head.add_child(_bar)
	_status = UI.label("", "H3")
	head.add_child(_status)
	add_child(head)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(grid)
	var items: Array = Data.TIDY_ITEMS.duplicate()
	items.shuffle()
	var tiles: Array = []
	for it in items:
		if bool(it["bad"]):
			_bad_total += 1
		var t := _tile(it)
		grid.add_child(t)
		tiles.append(t)
	_bar.max_value = _bad_total
	var bottom := UI.hbox(14)
	var mp := UI.panel("Info")
	mp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_msg = UI.label("Ada %d benda berbahaya. Ayo cari!" % _bad_total, "H3", true)
	mp.add_child(_msg)
	bottom.add_child(mp)
	_finish = UI.btn("Selesai", "PrimaryButton", "check", 84, 32)
	_finish.visible = false
	_finish.pressed.connect(func() -> void:
		Sfx.play("tap")
		var sc := 3 if _mistakes == 0 else (2 if _mistakes <= 2 else 1)
		done.emit(sc, 3))
	bottom.add_child(_finish)
	add_child(bottom)
	UI.pop_in(tiles, 0.1, 0.05)
	_update()


func _tile(it: Dictionary) -> TapCard:
	var b := TapCard.new()
	b.custom_minimum_size = Vector2(200, 150)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.set("accessibility_name", str(it["name"]))
	var v := UI.vbox(4)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var art := PropArt.new(str(ART.get(it["name"], "")))
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(art)
	var l := UI.label(str(it["name"]), "H3", true, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_font_size_override("font_size", Game.fs(22))
	v.add_child(l)
	b.pressed.connect(func() -> void:
		if b.has_meta("done"):
			return
		if bool(it["bad"]):
			b.set_meta("done", true)
			Sfx.play("success")
			_fixed += 1
			art.fixed = true
			art.queue_redraw()
			l.text = "Sudah aman"
			b.set_state("TileCorrect")
			b.focus_mode = Control.FOCUS_NONE
			_msg.text = str(it["fix"])
			FX.burst(b, b.size / 2.0, 12)
		else:
			Sfx.play("soft_no")
			_mistakes += 1
			_msg.text = "Yang ini aman. " + str(it["fix"])
			var tw := b.create_tween()
			b.pivot_offset = b.size / 2.0
			for k in 4:
				tw.tween_property(b, "rotation", 0.05 * (1 if k % 2 == 0 else -1), 0.05)
			tw.tween_property(b, "rotation", 0.0, 0.05)
		Game.speak(_msg.text)
		_update())
	return b


func _update() -> void:
	_status.text = "%d/%d" % [_fixed, _bad_total]
	_bar.value = _fixed
	if _fixed >= _bad_total:
		_finish.visible = true
		_msg.text = "Hebat! Ruang latihan sudah aman."
		_finish.call_deferred("grab_focus")
