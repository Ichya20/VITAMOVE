class_name Mascot
extends Control
## Jali si Jalak Bali: pemandu ceria. Bergoyang, berbicara, melompat senang, dan terbang.

@export var flap := false
@export var facing := 1.0
var talking := false
var _t := 0.0
var _hop := 0.0
var _seed := 0.0
const INK := Color("2a2420")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(120, 120)
	_seed = randf() * 6.0


func hop() -> void:
	_hop = 1.0


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	_hop = maxf(0.0, _hop - delta * 2.2)
	queue_redraw()


func _ell(c: Vector2, rx: float, ry: float, col: Color, ang: float = 0.0, outline: bool = false) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := float(i) / 28.0 * TAU
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(ang))
	if outline:
		var o := Geometry2D.offset_polygon(pts, 3.0)
		for q in o:
			draw_colored_polygon(q, INK)
	draw_colored_polygon(pts, col)
	pts.append(pts[0])
	draw_polyline(pts, col, 1.2, true)


func _poly(pts: PackedVector2Array, col: Color, outline: bool = true) -> void:
	if outline:
		for q in Geometry2D.offset_polygon(pts, 3.0):
			draw_colored_polygon(q, INK)
	draw_colored_polygon(pts, col)


func _draw() -> void:
	var k := minf(size.x, size.y) / 130.0
	var bob := sin(_t * 2.4 + _seed) * 3.0
	var jump := -sin(_hop * PI) * 26.0
	var squash := 1.0 + 0.08 * sin(_hop * PI * 2.0)
	draw_set_transform(size / 2.0 + Vector2(0, (bob + jump) * k), 0.0, Vector2(k * facing, k / squash))
	var white := Color("fbfbf7")
	var shade := Color("dfe0d6")
	var blue := Color("2f7fd1")
	var beak := Color("f2b134")
	# ekor berujung hitam
	_poly(PackedVector2Array([Vector2(-28, 12), Vector2(-60, 0), Vector2(-64, 14), Vector2(-60, 26), Vector2(-28, 26)]), white)
	_poly(PackedVector2Array([Vector2(-50, 4), Vector2(-60, 0), Vector2(-64, 14), Vector2(-60, 26), Vector2(-50, 24)]), Color("2b2b2b"), false)
	# kaki
	draw_line(Vector2(-6, 40), Vector2(-8, 54), beak.darkened(0.25), 5, true)
	draw_line(Vector2(9, 40), Vector2(11, 54), beak.darkened(0.25), 5, true)
	draw_line(Vector2(-14, 55), Vector2(0, 55), beak.darkened(0.25), 4, true)
	draw_line(Vector2(4, 55), Vector2(18, 55), beak.darkened(0.25), 4, true)
	# badan
	_ell(Vector2(0, 12), 37, 31, white, 0.0, true)
	_ell(Vector2(5, 25), 25, 13, shade)
	# sayap: bentuk tetes memanjang yang menempel di badan, ujungnya hitam
	var speed := 14.0 if flap else 2.2
	var amp := 0.62 if flap else 0.1
	var wa := sin(_t * speed) * amp - (0.22 if talking else 0.0)
	var pivot := Vector2(-2, -2)
	var wing := PackedVector2Array([
		Vector2(2, -6), Vector2(-16, -17), Vector2(-38, -15), Vector2(-54, -2),
		Vector2(-40, 11), Vector2(-18, 17), Vector2(-4, 12),
	])
	var tipw := PackedVector2Array([Vector2(-36, -15), Vector2(-54, -2), Vector2(-41, 10), Vector2(-31, -3)])
	var quill := [[Vector2(-10, -9), Vector2(-36, -8)], [Vector2(-9, -2), Vector2(-33, -1)], [Vector2(-8, 5), Vector2(-28, 6)]]
	for i in wing.size():
		wing[i] = (wing[i] - pivot).rotated(wa) + pivot
	for i in tipw.size():
		tipw[i] = (tipw[i] - pivot).rotated(wa) + pivot
	_poly(wing, Color("f2f2eb"))
	_poly(tipw, Color("2b2b2b"), false)
	for q in quill:
		draw_line((q[0] - pivot).rotated(wa) + pivot, (q[1] - pivot).rotated(wa) + pivot, Color("d8d8cd"), 2.0, true)
	# kepala & jambul
	for i in 5:
		var base := Vector2(12 + i * 4, -36)
		var tipp := Vector2(2 + i * 7, -58 - (i % 2) * 7 + sin(_t * 3.0 + i) * 1.5)
		draw_line(base, tipp, INK, 7, true)
		draw_line(base, tipp, white, 4, true)
	_ell(Vector2(22, -18), 25, 23, white, 0.0, true)
	_ell(Vector2(31, -20), 11.5, 9.5, blue)
	var blink := fmod(_t + _seed, 3.6) > 3.45
	if blink:
		draw_line(Vector2(26, -20), Vector2(36, -20), Color("1a1a1a"), 3, true)
	else:
		draw_circle(Vector2(31, -20), 5.2, Color("1a1a1a"), true, -1.0, true)
		draw_circle(Vector2(32.6, -22.2), 1.9, Color.WHITE, true, -1.0, true)
	var open := 5.0 if talking and fmod(_t, 0.28) < 0.14 else 0.0
	_poly(PackedVector2Array([Vector2(43, -17), Vector2(63, -11 + open * 0.2), Vector2(43, -8)]), beak)
	if open > 0.0:
		_poly(PackedVector2Array([Vector2(43, -8), Vector2(58, -4 + open), Vector2(43, -3)]), beak.darkened(0.18))
	_ell(Vector2(26, -5), 6, 4, Color(1, 0.5, 0.5, 0.45))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
