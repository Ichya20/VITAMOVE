class_name TrafficChallenge
extends VBoxContainer
## "Lampu Tubuh": pilih Lanjutkan / Pelankan / Berhenti untuk tiap keadaan tubuh.

signal done(score: int, total: int)

const COLORS := [Color("2f8a3c"), Color("d99a1e"), Color("b3261e")]
const ICONS := ["check", "pause", "stop"]
const EXPLAIN := [
	"Ini tanda wajar saat bergerak. Lanjutkan pelan-pelan.",
	"Pelankan gerakan atau duduk istirahat sebentar sambil minum.",
	"Berhenti, duduk, dan segera beri tahu kader atau tenaga kesehatan.",
]

var items: Array = []
var idx := 0
var score := 0
var _card: Label
var _prog: Label
var _fb: Label
var _fb_panel: PanelContainer
var _buttons: Array[Button] = []
var _next: Button
var _locked := false


func setup() -> void:
	add_theme_constant_override("separation", 14)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	items = Data.TRAFFIC.duplicate()
	items.shuffle()
	items = items.slice(0, 6)
	var head := UI.hbox(12)
	head.add_child(Icon.new("shield", Game.DANGER, 40))
	var tl := UI.label("Lampu Tubuh", "H2")
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	_prog = UI.label("", "H3")
	head.add_child(_prog)
	add_child(head)
	add_child(UI.label("Saat latihan Mbah merasakan hal di bawah ini. Apa yang sebaiknya dilakukan?", "Body", true))
	var cp := UI.panel("Cream")
	cp.custom_minimum_size.y = 120
	_card = UI.label("", "H1", true, HORIZONTAL_ALIGNMENT_CENTER)
	_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card.add_theme_font_size_override("font_size", Game.fs(38))
	cp.add_child(_card)
	add_child(cp)
	var row := UI.hbox(16)
	for i in 3:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 150)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_ALL
		b.set("accessibility_name", Data.TRAFFIC_LABELS[i])
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var sb := StyleBoxFlat.new()
			sb.set_corner_radius_all(24)
			sb.anti_aliasing = true
			var c: Color = COLORS[i]
			sb.bg_color = c.lightened(0.08) if state == "hover" else (c.darkened(0.15) if state.contains("pressed") else c)
			if state == "disabled":
				sb.bg_color = Color(c, 0.35)
			sb.shadow_color = Color(Game.TEAL, 0.35)
			sb.shadow_size = 1
			sb.shadow_offset = Vector2(0, 5)
			b.add_theme_stylebox_override(state, sb)
		var fsb := StyleBoxFlat.new()
		fsb.draw_center = false
		fsb.set_corner_radius_all(28)
		fsb.set_border_width_all(5)
		fsb.border_color = Game.INK
		fsb.set_expand_margin_all(6)
		b.add_theme_stylebox_override("focus", fsb)
		var h := UI.hbox(12)
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UI.full(h)
		var ic := Icon.new(ICONS[i], Color.WHITE, 46)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ic)
		var l := UI.label(Data.TRAFFIC_LABELS[i], "OnDark")
		l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(l)
		b.add_child(h)
		b.pressed.connect(_on_pick.bind(i))
		row.add_child(b)
		_buttons.append(b)
	add_child(row)
	var bottom := UI.hbox(14)
	_fb_panel = UI.panel("Leaf")
	_fb_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fb = UI.label("", "H3", true)
	_fb_panel.add_child(_fb)
	bottom.add_child(_fb_panel)
	_next = UI.btn("Berikutnya", "PrimaryButton", "next", 84, 32)
	_next.pressed.connect(_on_next)
	bottom.add_child(_next)
	add_child(bottom)
	_show(0)


func _show(i: int) -> void:
	idx = i
	_locked = false
	_prog.text = "%d / %d" % [i + 1, items.size()]
	_card.text = "\u201c" + str(items[i]["t"]) + "\u201d"
	_fb_panel.visible = false
	_next.visible = false
	for b in _buttons:
		b.disabled = false
	Game.speak(str(items[i]["t"]))


func _on_pick(c: int) -> void:
	if _locked:
		return
	_locked = true
	var right := int(items[idx]["c"])
	var ok := c == right
	if ok:
		score += 1
		Sfx.play("success")
		_fb_panel.theme_type_variation = "Leaf"
		_fb.text = "Tepat! " + EXPLAIN[right]
	else:
		Sfx.play("soft_no")
		_fb_panel.theme_type_variation = "Note"
		_fb.text = "Sebaiknya \"%s\". %s" % [Data.TRAFFIC_LABELS[right], EXPLAIN[right]]
	for i in _buttons.size():
		_buttons[i].disabled = i != right
	_fb_panel.visible = true
	_next.visible = true
	UI.set_btn_text(_next, "Selesai" if idx >= items.size() - 1 else "Berikutnya")
	_next.call_deferred("grab_focus")
	Game.speak(_fb.text)


func _on_next() -> void:
	Sfx.play("tap")
	if idx + 1 < items.size():
		_show(idx + 1)
	else:
		var sc := int(round(3.0 * score / items.size()))
		done.emit(sc, 3)
