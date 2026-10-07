class_name TidyChallenge
extends VBoxContainer
## "Rapikan Rumah Mbah": ketuk benda yang berbahaya agar ruang latihan aman.

signal done(score: int, total: int)

const ICONS := {
	"Karpet terlipat": "wave", "Kursi beroda": "chair", "Lantai basah": "water", "Kabel melintang": "wave",
	"Sandal licin": "user", "Gelas air putih": "water", "Kursi kayu kokoh": "chair", "Lampu terang": "sun",
}

var _bad_total := 0
var _fixed := 0
var _mistakes := 0
var _status: Label
var _msg: Label
var _finish: Button


func setup() -> void:
	add_theme_constant_override("separation", 14)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var head := UI.hbox(12)
	head.add_child(Icon.new("home", Game.TERRA, 40))
	var tl := UI.label("Rapikan Rumah Mbah", "H2")
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	_status = UI.label("", "H3")
	head.add_child(_status)
	add_child(head)
	add_child(UI.label("Ketuk benda yang BERBAHAYA saat latihan. Benda yang aman biarkan saja.", "Body", true))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(grid)
	var items: Array = Data.TIDY_ITEMS.duplicate()
	items.shuffle()
	for it in items:
		if bool(it["bad"]):
			_bad_total += 1
		grid.add_child(_tile(it))
	var bottom := UI.hbox(14)
	var mp := UI.panel("Pill")
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
	_update()


func _tile(it: Dictionary) -> Button:
	var b := Button.new()
	b.theme_type_variation = "ChoiceButton"
	b.custom_minimum_size = Vector2(200, 150)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.set("accessibility_name", str(it["name"]))
	var v := UI.vbox(6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full(v)
	b.add_child(v)
	var ic := Icon.new(str(ICONS.get(it["name"], "info")), Game.TEAL_MID, 56)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var l := UI.label(str(it["name"]), "H3", true, HORIZONTAL_ALIGNMENT_CENTER)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	b.pressed.connect(func() -> void:
		if b.has_meta("done"):
			return
		if bool(it["bad"]):
			b.set_meta("done", true)
			Sfx.play("success")
			_fixed += 1
			ic.kind = "check"
			ic.color = Game.LEAF
			ic.queue_redraw()
			l.text = "Sudah aman"
			b.disabled = true
			_msg.text = str(it["fix"])
		else:
			Sfx.play("soft_no")
			_mistakes += 1
			_msg.text = "Yang ini aman. " + str(it["fix"])
		Game.speak(_msg.text)
		_update())
	return b


func _update() -> void:
	_status.text = "%d / %d dirapikan" % [_fixed, _bad_total]
	if _fixed >= _bad_total:
		_finish.visible = true
		_msg.text = "Hebat! Ruang latihan sudah aman."
		_finish.call_deferred("grab_focus")
