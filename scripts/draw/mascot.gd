class_name Mascot
extends Control
## Jali si Jalak Bali: pemandu ceria yang memberi petunjuk.

@export var flap := true
@export var facing := 1.0
var _t := 0.0
var talking := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(120, 120)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var k := minf(size.x, size.y) / 120.0
	var bob := sin(_t * 2.4) * 4.0
	draw_set_transform(size / 2.0 + Vector2(0, bob * k), 0.0, Vector2(k * facing, k))
	var white := Color("fbfbf7")
	var shade := Color("dcdcd2")
	var blue := Color("2f7fd1")
	var beak := Color("f2b134")
	# ekor
	draw_colored_polygon(PackedVector2Array([Vector2(-30, 10), Vector2(-58, 2), Vector2(-60, 22), Vector2(-28, 24)]), Color("2b2b2b"))
	# badan
	_ell(Vector2(0, 12), 36, 30, white)
	_ell(Vector2(4, 24), 26, 14, shade)
	# sayap mengepak
	var wa := sin(_t * (9.0 if flap else 2.0)) * (0.5 if flap else 0.12)
	var wing := PackedVector2Array([Vector2(-8, 4), Vector2(-40, -18), Vector2(-46, -2), Vector2(-14, 22)])
	for i in wing.size():
		wing[i] = (wing[i] - Vector2(-8, 4)).rotated(wa) + Vector2(-8, 4)
	draw_colored_polygon(wing, Color("eeeee6"))
	draw_line(wing[1], wing[2], Color("2b2b2b"), 5, true)
	# kepala & jambul
	_ell(Vector2(22, -18), 24, 22, white)
	for i in 4:
		draw_line(Vector2(14 + i * 4, -36), Vector2(4 + i * 6, -54 - (i % 2) * 6), white.darkened(0.06), 5, true)
	# kulit biru di sekitar mata (ciri jalak bali)
	_ell(Vector2(30, -20), 11, 9, blue)
	var blink := fmod(_t, 3.6) > 3.45
	if blink:
		draw_line(Vector2(26, -20), Vector2(34, -20), Color("1a1a1a"), 3, true)
	else:
		draw_circle(Vector2(30, -20), 5, Color("1a1a1a"), true, -1.0, true)
		draw_circle(Vector2(31.5, -22), 1.8, Color.WHITE, true, -1.0, true)
	# paruh
	var open := 4.0 if talking and fmod(_t, 0.3) < 0.15 else 0.0
	draw_colored_polygon(PackedVector2Array([Vector2(42, -16), Vector2(60, -10 + open * 0.3), Vector2(42, -8)]), beak)
	if open > 0.0:
		draw_colored_polygon(PackedVector2Array([Vector2(42, -8), Vector2(56, -4 + open), Vector2(42, -4)]), beak.darkened(0.15))
	# pipi
	_ell(Vector2(26, -6), 6, 4, Color(1, 0.5, 0.5, 0.45))
	# kaki
	draw_line(Vector2(-4, 40), Vector2(-6, 52), beak.darkened(0.2), 4, true)
	draw_line(Vector2(8, 40), Vector2(10, 52), beak.darkened(0.2), 4, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ell(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := float(i) / 24.0 * TAU
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)
