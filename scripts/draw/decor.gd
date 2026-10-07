class_name Decor
extends Control
## Elemen hias kecil yang bergerak: burung, tikar anyaman, sinar mentari, pita judul.

@export var kind := "birds"   # birds | tikar | rays | ribbon | sparkles
@export var color := Color("f2b134")
@export var text := ""
@export var alpha := 1.0
var speed := 30.0
var _t := 0.0
var _seed := 0.0


func _init(k: String = "birds") -> void:
	kind = k
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seed = randf() * 100.0
	clip_contents = k == "rays"


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if kind in ["birds", "rays", "sparkles"]:
		_t += delta
		queue_redraw()


func _draw() -> void:
	match kind:
		"birds":
			_draw_birds()
		"tikar":
			_draw_tikar()
		"rays":
			_draw_rays()
		"ribbon":
			_draw_ribbon()
		"sparkles":
			_draw_sparkles()


func _draw_birds() -> void:
	var w := size.x
	for i in 4:
		var x := fmod(_t * speed * (0.8 + i * 0.12) + _seed * 37.0 + i * 70.0, w + 200.0) - 100.0
		var y := size.y * (0.2 + 0.18 * i) + sin(_t * 0.8 + i) * 10.0
		var f := sin(_t * 7.0 + i * 1.3) * 7.0
		var s := 1.0 - i * 0.12
		var c := Color(0.15, 0.25, 0.25, 0.55)
		draw_polyline(PackedVector2Array([Vector2(x - 14 * s, y - f * s), Vector2(x - 4 * s, y - 2), Vector2(x, y), Vector2(x + 4 * s, y - 2), Vector2(x + 14 * s, y - f * s)]), c, 3.0, true)


func _draw_tikar() -> void:
	## Tikar pandan dalam perspektif; alas latihan yang akrab bagi lansia desa.
	var w := size.x
	var h := size.y
	var tl := Vector2(w * 0.16, 0)
	var tr := Vector2(w * 0.84, 0)
	var br := Vector2(w, h)
	var bl := Vector2(0, h)
	draw_colored_polygon(PackedVector2Array([tl + Vector2(6, 8), tr + Vector2(6, 8), br + Vector2(6, 8), bl + Vector2(6, 8)]), Color(0.05, 0.15, 0.12, 0.18))
	draw_colored_polygon(PackedVector2Array([tl, tr, br, bl]), Color("dcb878"))
	var rows := 7
	for r in rows:
		var t0 := float(r) / rows
		var t1 := float(r + 1) / rows
		var cols := 12
		for cidx in cols:
			if (r + cidx) % 2 == 0:
				continue
			var u0 := float(cidx) / cols
			var u1 := float(cidx + 1) / cols
			var a := tl.lerp(tr, u0).lerp(bl.lerp(br, u0), t0)
			var b := tl.lerp(tr, u1).lerp(bl.lerp(br, u1), t0)
			var c2 := tl.lerp(tr, u1).lerp(bl.lerp(br, u1), t1)
			var d := tl.lerp(tr, u0).lerp(bl.lerp(br, u0), t1)
			draw_colored_polygon(PackedVector2Array([a, b, c2, d]), Color("c99d58"))
	var edge := Color("9c3d2a")
	draw_polyline(PackedVector2Array([tl, tr, br, bl, tl]), edge, 7.0, true)
	draw_polyline(PackedVector2Array([tl.lerp(br, 0.03), tr.lerp(bl, 0.03), br.lerp(tl, 0.03), bl.lerp(tr, 0.03), tl.lerp(br, 0.03)]), Color("f2b134"), 2.5, true)


func _draw_rays() -> void:
	var c := size / 2.0
	var r := maxf(size.x, size.y) * 0.7
	var n := 16
	for i in n:
		var a0 := _t * 0.18 + i * TAU / n
		var a1 := a0 + TAU / n * 0.5
		draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * r, c + Vector2(cos(a1), sin(a1)) * r]), Color(color, 0.22 * alpha))
	for i in 4:
		draw_circle(c, r * (0.22 + i * 0.07), Color(color, 0.12 * alpha), true, -1.0, true)


func _draw_ribbon() -> void:
	var w := size.x
	var h := size.y
	var notch := h * 0.32
	var body := Color("c8553d")
	var fold := Color("9c3d2a")
	# ujung pita
	draw_colored_polygon(PackedVector2Array([Vector2(-notch * 1.4, h * 0.18), Vector2(notch * 0.8, h * 0.18), Vector2(notch * 0.8, h * 1.12), Vector2(-notch * 1.4, h * 1.12), Vector2(-notch * 0.6, h * 0.65)]), fold)
	draw_colored_polygon(PackedVector2Array([Vector2(w + notch * 1.4, h * 0.18), Vector2(w - notch * 0.8, h * 0.18), Vector2(w - notch * 0.8, h * 1.12), Vector2(w + notch * 1.4, h * 1.12), Vector2(w + notch * 0.6, h * 0.65)]), fold)
	draw_colored_polygon(PackedVector2Array([Vector2(0, h * 0.12), Vector2(w, h * 0.12), Vector2(w, h), Vector2(0, h)]), Color(0.05, 0.15, 0.12, 0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.9), Vector2(0, h * 0.9)]), body)
	draw_line(Vector2(6, h * 0.12), Vector2(w - 6, h * 0.12), Color(1, 1, 1, 0.25), 2.0, true)
	draw_line(Vector2(6, h * 0.78), Vector2(w - 6, h * 0.78), Color(0, 0, 0, 0.15), 2.0, true)


func _draw_sparkles() -> void:
	for i in 6:
		var ph := fmod(_t * 0.6 + i * 0.37 + _seed, 1.0)
		var p := Vector2(fmod(i * 97.0 + _seed * 13.0, size.x), fmod(i * 53.0 + _seed * 7.0, size.y))
		var s := sin(ph * PI) * 9.0
		if s <= 0.5:
			continue
		var c := Color(color, sin(ph * PI))
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.28, -s * 0.28), p + Vector2(s, 0), p + Vector2(s * 0.28, s * 0.28), p + Vector2(0, s), p + Vector2(-s * 0.28, s * 0.28), p + Vector2(-s, 0), p + Vector2(-s * 0.28, -s * 0.28)]), c)
