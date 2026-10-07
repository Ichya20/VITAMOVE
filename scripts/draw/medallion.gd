class_name Medallion
extends BaseButton
## Penanda pos pada peta: lingkaran berwarna dengan cincin 3 daun, nomor, dan kunci.

var color := Color("c8553d")
var icon_kind := "leaf"
var number := 1
var leaves := 0
var locked := false
var current := false
var _t := 0.0
var _icon: Icon
const INK := Color("2a2420")


func _init() -> void:
	custom_minimum_size = Vector2(132, 150)
	size = custom_minimum_size
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button_down.connect(func() -> void: UI.press_anim(self, true))
	button_up.connect(func() -> void: UI.press_anim(self, false))


func setup(c: Color, ic: String, n: int, lv: int, is_locked: bool, is_current: bool) -> void:
	color = c
	icon_kind = ic
	number = n
	leaves = lv
	locked = is_locked
	current = is_current
	if _icon == null:
		_icon = Icon.new("lock" if locked else icon_kind, Color.WHITE, 52)
		add_child(_icon)
	_icon.set_kind("lock" if locked else icon_kind)
	_icon.position = Vector2(66 - 26, 82 - 26)
	_icon.size = Vector2(52, 52)
	queue_redraw()


func _process(delta: float) -> void:
	if current and not locked:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var c := Vector2(66, 82)
	var r := 52.0
	# bayangan di tanah
	for i in 3:
		draw_circle(c + Vector2(0, 50), 34.0 - i * 9.0, Color(0.05, 0.15, 0.12, 0.06 + i * 0.04), true, -1.0, true)
	if current and not locked:
		var pulse := 0.5 + 0.5 * sin(_t * 3.2)
		draw_circle(c, r + 14.0 + pulse * 6.0, Color(Game.SAFFRON, 0.25 + 0.2 * pulse), true, -1.0, true)
	var base := Color("b9b2a4") if locked else color
	var pressed := get_draw_mode() == DRAW_PRESSED
	var lift := 3.0 if pressed else 0.0
	# punggung (kesan tebal)
	draw_circle(c + Vector2(0, 6), r + 3.0, INK, true, -1.0, true)
	draw_circle(c + Vector2(0, 5), r, base.darkened(0.3), true, -1.0, true)
	draw_circle(c + Vector2(0, lift), r + 3.0, INK, true, -1.0, true)
	draw_circle(c + Vector2(0, lift), r, Game.PAPER, true, -1.0, true)
	# cincin daun: 3 ruas
	for i in 3:
		var a0 := -PI / 2.0 + i * TAU / 3.0 + 0.12
		var a1 := a0 + TAU / 3.0 - 0.24
		var col := Game.LEAF if i < leaves else Color(Game.TEAL, 0.14)
		draw_arc(c + Vector2(0, lift), r - 7.0, a0, a1, 16, col, 8.0, true)
	draw_circle(c + Vector2(0, lift), r - 15.0, base, true, -1.0, true)
	draw_arc(c + Vector2(0, lift), r - 15.0, PI * 0.15, PI * 0.85, 16, base.darkened(0.15), 6.0, true)
	draw_circle(c + Vector2(-12, -14 + lift), 10, Color(1, 1, 1, 0.22), true, -1.0, true)
	if _icon:
		_icon.position = Vector2(c.x - 26, c.y - 26 + lift)
	# nomor pos
	var nb := c + Vector2(-r + 8, -r + 10 + lift)
	draw_circle(nb, 19, INK, true, -1.0, true)
	draw_circle(nb, 16.5, Game.SAFFRON, true, -1.0, true)
	var f := Game.font_display
	var txt := str(number)
	var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	draw_string(f, nb + Vector2(-tw / 2.0, 9), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
	# bintang bila 3 daun
	if leaves >= 3:
		var sc := c + Vector2(r - 8, -r + 12 + lift)
		var pts := PackedVector2Array()
		for i in 10:
			var a := -PI / 2.0 + i * PI / 5.0
			var rr := 16.0 if i % 2 == 0 else 7.0
			pts.append(sc + Vector2(cos(a), sin(a)) * rr)
		for o in Geometry2D.offset_polygon(pts, 2.5):
			draw_colored_polygon(o, INK)
		draw_colored_polygon(pts, Game.SAFFRON)
	# panah "di sini" yang memantul
	if current and not locked:
		var by := -8.0 - absf(sin(_t * 3.2)) * 10.0
		var tipp := Vector2(c.x, c.y - r - 14 + by)
		var tri := PackedVector2Array([tipp, tipp + Vector2(-14, -20), tipp + Vector2(14, -20)])
		for o in Geometry2D.offset_polygon(tri, 2.5):
			draw_colored_polygon(o, INK)
		draw_colored_polygon(tri, Game.TERRA)
	if has_focus():
		draw_arc(c + Vector2(0, lift), r + 10.0, 0, TAU, 40, INK, 4.0, true)
