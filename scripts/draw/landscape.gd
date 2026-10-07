class_name Landscape
extends Control
## Latar desa bergaya potongan kertas (papercut): langit, Gunung Slamet, bukit,
## sawah berundak, dan bangunan khas desa. Digambar vektor agar tajam di semua layar.

@export var places: Array = []        # [{ "kind": "pasar", "x": 1200.0 }]
@export var horizon := 0.56           # posisi cakrawala (proporsi tinggi)
@export var mountain_x := 0.5         # posisi gunung (proporsi lebar)
@export var time_of_day := "pagi"     # pagi | siang | senja
@export var seed_value := 7
@export var show_path := false
@export var path_points: PackedVector2Array = PackedVector2Array()

const PAPER_SHADOW := Color(0.04, 0.16, 0.15, 0.22)

var font: Font


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	font = Game.font_display
	resized.connect(queue_redraw)


func _sky_colors() -> Array:
	match time_of_day:
		"senja":
			return [Color("f6b26b"), Color("fde7b0"), Color("e98e5a")]
		"siang":
			return [Color("8fd0de"), Color("e3f4f1"), Color("fff1c4")]
		_:
			return [Color("9fd6df"), Color("fff1d6"), Color("ffd27a")]


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 2 or h < 2:
		return
	var sky: Array = _sky_colors()
	var hy := h * horizon
	# langit gradasi
	var sky_poly := PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, hy + 40), Vector2(0, hy + 40)])
	draw_polygon(sky_poly, PackedColorArray([sky[0], sky[0], sky[1], sky[1]]))
	# matahari dengan cincin lembut
	var sun := Vector2(w * clampf(mountain_x + 0.18, 0.1, 0.9), hy * 0.36)
	if w > h * 3.0:
		sun = Vector2(minf(w * 0.12, 700.0), hy * 0.32)
	for i in 4:
		draw_circle(sun, 70.0 + i * 26.0, Color(sky[2], 0.16 - i * 0.03), true, -1.0, true)
	draw_circle(sun, 58, sky[2].lightened(0.15), true, -1.0, true)

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	# Gunung Slamet (satu atau beberapa bila latar lebar)
	var mounts: Array = []
	if w > h * 3.0:
		var n := int(w / 1500.0) + 1
		for i in n:
			mounts.append(w * (i + 0.5) / n)
	else:
		mounts.append(w * mountain_x)
	for mx in mounts:
		_mountain(Vector2(mx + 160, hy + 10), h * 0.30, h * 0.75, Color("8fb8b0"))
		_mountain(Vector2(mx, hy + 10), h * 0.42, h * 0.95, Color("5f8f8a"))

	# bukit berlapis (papercut)
	_hills(hy - h * 0.02, h * 0.06, 0.004, 1.3, Color("7fb07a"))
	_hills(hy + h * 0.04, h * 0.05, 0.006, 4.1, Color("5f9a55"))
	# pohon kelapa jauh
	var x := 30.0
	while x < w:
		_palm(Vector2(x + rng.randf_range(-20, 20), hy + h * 0.05), h * rng.randf_range(0.10, 0.14), Color("3f6f3a"))
		x += rng.randf_range(180, 360)
	_hills(hy + h * 0.10, h * 0.035, 0.009, 2.2, Color("8cc063"))
	# sawah berundak
	_terraces(hy + h * 0.13, h)

	if show_path and path_points.size() > 1:
		_draw_path()

	for p in places:
		_place(str(p.get("kind", "")), float(p.get("x", 0.0)), float(p.get("y", h * 0.80)), float(p.get("s", 1.0)))


func _mountain(base: Vector2, height: float, width: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 40
	for i in steps + 1:
		var t := float(i) / steps
		var xx := base.x - width / 2.0 + width * t
		var k := 1.0 - absf(t - 0.5) * 2.0
		var yy := base.y - height * pow(k, 1.6) * (1.0 - 0.06 * sin(t * 40.0))
		if absf(t - 0.5) < 0.04:
			yy = base.y - height * 0.97
		pts.append(Vector2(xx, yy))
	var shadow := pts.duplicate()
	for i in shadow.size():
		shadow[i] += Vector2(8, -6)
	draw_colored_polygon(shadow, PAPER_SHADOW)
	draw_colored_polygon(pts, col)
	# guratan lereng
	var top := Vector2(base.x, base.y - height * 0.97)
	for i in 5:
		var off := (i - 2) * width * 0.08
		draw_line(top + Vector2(off * 0.15, 6), Vector2(base.x + off, base.y - height * 0.35), col.darkened(0.12), 4, true)


func _hills(base_y: float, amp: float, freq: float, phase: float, col: Color) -> void:
	var w := size.x
	var pts := PackedVector2Array()
	pts.append(Vector2(0, size.y))
	var x := 0.0
	while x <= w + 24:
		var y := base_y - amp * (0.6 + 0.4 * sin(x * freq + phase)) - amp * 0.35 * sin(x * freq * 2.7 + phase * 2.0)
		pts.append(Vector2(x, y))
		x += 24.0
	pts.append(Vector2(w + 24, size.y))
	var shadow := pts.duplicate()
	for i in range(1, shadow.size() - 1):
		shadow[i] += Vector2(0, -9)
	draw_colored_polygon(shadow, PAPER_SHADOW)
	draw_colored_polygon(pts, col)


func _terraces(top_y: float, h: float) -> void:
	var w := size.x
	var cols := [Color("a7cf6b"), Color("93c25b"), Color("b6d97a"), Color("86b84f")]
	var band := (h - top_y) / 4.0
	for i in 4:
		var y0 := top_y + i * band
		var pts := PackedVector2Array()
		pts.append(Vector2(0, h))
		var x := 0.0
		while x <= w + 30:
			pts.append(Vector2(x, y0 + 10.0 * sin(x * 0.004 + i * 1.7)))
			x += 30.0
		pts.append(Vector2(w + 30, h))
		var shadow := pts.duplicate()
		for j in range(1, shadow.size() - 1):
			shadow[j] += Vector2(0, -7)
		draw_colored_polygon(shadow, PAPER_SHADOW)
		draw_colored_polygon(pts, cols[i])
		# baris tanaman padi
		var c2: Color = cols[i].darkened(0.12)
		var xx := 20.0 + i * 13.0
		while xx < w:
			var yy := y0 + 10.0 * sin(xx * 0.004 + i * 1.7) + band * 0.45
			draw_line(Vector2(xx, yy), Vector2(xx - 4, yy - 12), c2, 3, true)
			draw_line(Vector2(xx, yy), Vector2(xx + 5, yy - 11), c2, 3, true)
			xx += 46.0


func _palm(base: Vector2, hgt: float, col: Color) -> void:
	var top := base + Vector2(hgt * 0.12, -hgt)
	draw_line(base, top, col.darkened(0.1), maxf(3.0, hgt * 0.05), true)
	for i in 6:
		var a := -PI * 0.95 + i * PI * 0.38
		var tip := top + Vector2(cos(a), sin(a) * 0.55 + 0.25) * hgt * 0.42
		var mid := (top + tip) / 2.0 + Vector2(0, -hgt * 0.06)
		draw_polyline(PackedVector2Array([top, mid, tip]), col, maxf(3.0, hgt * 0.06), true)


func _draw_path() -> void:
	var sand := Color("f3dcaa")
	var edge := Color("d6b47a")
	var pts := PackedVector2Array()
	for i in path_points.size() - 1:
		var p0 := path_points[maxi(i - 1, 0)]
		var p1 := path_points[i]
		var p2 := path_points[i + 1]
		var p3 := path_points[mini(i + 2, path_points.size() - 1)]
		for s in 16:
			var t := float(s) / 16.0
			pts.append(_catmull(p0, p1, p2, p3, t))
	pts.append(path_points[path_points.size() - 1])
	draw_polyline(pts, PAPER_SHADOW, 64, true)
	draw_polyline(pts, edge, 58, true)
	draw_polyline(pts, sand, 46, true)
	# jejak langkah putus-putus
	for i in range(0, pts.size() - 1, 3):
		draw_line(pts[i], pts[mini(i + 1, pts.size() - 1)], Color(edge, 0.9), 6, true)


static func _catmull(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


# ------------------------------------------------------------------ bangunan & tempat

func _rect(r: Rect2, c: Color) -> void:
	draw_rect(r, c, true)


func _poly(pts: Array, c: Color) -> void:
	draw_colored_polygon(PackedVector2Array(pts), c)


func _shadowed(pts: Array, c: Color) -> void:
	var sh: Array = []
	for p in pts:
		sh.append(p + Vector2(7, 7))
	_poly(sh, PAPER_SHADOW)
	_poly(pts, c)


func _joglo_roof(cx: float, y: float, w: float, c: Color) -> void:
	# atap joglo: brunjung tinggi di tengah dan penanggap melebar
	_shadowed([Vector2(cx - w * 0.6, y), Vector2(cx + w * 0.6, y), Vector2(cx + w * 0.3, y - w * 0.22), Vector2(cx - w * 0.3, y - w * 0.22)], c)
	_shadowed([Vector2(cx - w * 0.3, y - w * 0.2), Vector2(cx + w * 0.3, y - w * 0.2), Vector2(cx + w * 0.1, y - w * 0.5), Vector2(cx - w * 0.1, y - w * 0.5)], c.darkened(0.1))
	for i in 6:
		var yy := y - 4 - i * w * 0.035
		draw_line(Vector2(cx - w * (0.58 - i * 0.05), yy), Vector2(cx + w * (0.58 - i * 0.05), yy), c.darkened(0.22), 2, true)


func _place(kind: String, x: float, y: float, s: float) -> void:
	match kind:
		"balai":
			var w := 260.0 * s
			_rect(Rect2(x - w * 0.55, y - 14 * s, w * 1.1, 18 * s), Color("d9c4a0"))
			for i in 4:
				var px := x - w * 0.42 + i * w * 0.28
				_rect(Rect2(px - 6 * s, y - 120 * s, 12 * s, 108 * s), Color("7a4b2a"))
			_joglo_roof(x, y - 116 * s, w, Color("b4532a"))
			_banner(Vector2(x, y - 40 * s), "BALAI DESA", s)
		"rumah":
			var w := 220.0 * s
			_shadowed([Vector2(x - w * 0.45, y), Vector2(x + w * 0.45, y), Vector2(x + w * 0.45, y - 100 * s), Vector2(x - w * 0.45, y - 100 * s)], Color("f2e4c9"))
			_rect(Rect2(x - 22 * s, y - 70 * s, 44 * s, 70 * s), Color("8a5a34"))
			for sx: int in [-1, 1]:
				_rect(Rect2(x + sx * 62 * s - 20 * s, y - 78 * s, 40 * s, 34 * s), Color("6aa6b8"))
				draw_line(Vector2(x + sx * 62 * s, y - 78 * s), Vector2(x + sx * 62 * s, y - 44 * s), Color("f2e4c9"), 3, true)
			_joglo_roof(x, y - 96 * s, w * 0.95, Color("c8553d"))
			for i in 7:
				var fx := x - w * 0.75 + i * 18 * s
				if fx > x - w * 0.47:
					break
				draw_line(Vector2(fx, y), Vector2(fx, y - 34 * s), Color("ffffff"), 5 * s, true)
			draw_line(Vector2(x - w * 0.75, y - 24 * s), Vector2(x - w * 0.47, y - 24 * s), Color("ffffff"), 4 * s, true)
		"sawah":
			# gubuk sawah dan orang-orangan sawah
			_rect(Rect2(x - 60 * s, y - 70 * s, 8 * s, 70 * s), Color("7a4b2a"))
			_rect(Rect2(x + 52 * s, y - 70 * s, 8 * s, 70 * s), Color("7a4b2a"))
			_rect(Rect2(x - 64 * s, y - 34 * s, 128 * s, 10 * s), Color("b07c4a"))
			_shadowed([Vector2(x - 90 * s, y - 66 * s), Vector2(x + 90 * s, y - 66 * s), Vector2(x, y - 130 * s)], Color("d9b45a"))
			var sx := x + 140 * s
			draw_line(Vector2(sx, y), Vector2(sx, y - 110 * s), Color("7a4b2a"), 6 * s, true)
			draw_line(Vector2(sx - 40 * s, y - 80 * s), Vector2(sx + 40 * s, y - 80 * s), Color("7a4b2a"), 6 * s, true)
			draw_circle(Vector2(sx, y - 116 * s), 16 * s, Color("e8c98d"), true, -1.0, true)
			_poly([Vector2(sx - 30 * s, y - 120 * s), Vector2(sx + 30 * s, y - 120 * s), Vector2(sx, y - 146 * s)], Color("c79a3a"))
			_poly([Vector2(sx - 22 * s, y - 92 * s), Vector2(sx + 22 * s, y - 92 * s), Vector2(sx + 16 * s, y - 40 * s), Vector2(sx - 16 * s, y - 40 * s)], Color("c8553d"))
		"pematang":
			for side: int in [-1, 1]:
				_poly([Vector2(x + side * 20 * s, y + 10 * s), Vector2(x + side * 180 * s, y + 10 * s), Vector2(x + side * 150 * s, y - 50 * s), Vector2(x + side * 20 * s, y - 50 * s)], Color("8fc4c0"))
				for i in 3:
					draw_line(Vector2(x + side * (40 + i * 40) * s, y - 30 * s + i * 10 * s), Vector2(x + side * (60 + i * 40) * s, y - 30 * s + i * 10 * s), Color("ffffff", 0.6), 3, true)
			_poly([Vector2(x - 16 * s, y + 10 * s), Vector2(x + 16 * s, y + 10 * s), Vector2(x + 8 * s, y - 52 * s), Vector2(x - 8 * s, y - 52 * s)], Color("7a9a4a"))
			for i in 5:
				var yy := y - 40 * s + i * 11 * s
				draw_line(Vector2(x - 120 * s, yy), Vector2(x - 116 * s, yy - 12 * s), Color("4f8a3c"), 3, true)
				draw_line(Vector2(x + 110 * s, yy), Vector2(x + 114 * s, yy - 12 * s), Color("4f8a3c"), 3, true)
		"bambu":
			for i in 7:
				var bx := x - 90 * s + i * 30 * s
				var top := y - (200 + (i % 3) * 40) * s
				draw_line(Vector2(bx, y), Vector2(bx + (i - 3) * 8 * s, top), Color("6f9a3a"), 12 * s, true)
				var segs := 6
				for k in segs:
					var t := float(k + 1) / (segs + 1)
					var p := Vector2(bx, y).lerp(Vector2(bx + (i - 3) * 8 * s, top), t)
					draw_line(p + Vector2(-7 * s, 0), p + Vector2(7 * s, 0), Color("4d7a2a"), 3, true)
				for k in 3:
					var p2 := Vector2(bx, y).lerp(Vector2(bx + (i - 3) * 8 * s, top), 0.6 + k * 0.15)
					var dir := -1.0 if (i + k) % 2 == 0 else 1.0
					_poly([p2, p2 + Vector2(dir * 46 * s, -10 * s), p2 + Vector2(dir * 40 * s, 4 * s)], Color("7fb04a"))
		"sumur":
			_shadowed([Vector2(x - 60 * s, y), Vector2(x + 60 * s, y), Vector2(x + 60 * s, y - 60 * s), Vector2(x - 60 * s, y - 60 * s)], Color("b9a68c"))
			for i in 3:
				draw_line(Vector2(x - 60 * s, y - 20 * s * (i + 1)), Vector2(x + 60 * s, y - 20 * s * (i + 1)), Color("8f7c62"), 3, true)
			_rect(Rect2(x - 56 * s, y - 160 * s, 10 * s, 100 * s), Color("7a4b2a"))
			_rect(Rect2(x + 46 * s, y - 160 * s, 10 * s, 100 * s), Color("7a4b2a"))
			_rect(Rect2(x - 56 * s, y - 132 * s, 112 * s, 8 * s), Color("6f4a2a"))
			_joglo_roof(x, y - 156 * s, 160 * s, Color("c8553d"))
			draw_line(Vector2(x, y - 128 * s), Vector2(x, y - 86 * s), Color("4a3426"), 3, true)
			_poly([Vector2(x - 16 * s, y - 88 * s), Vector2(x + 16 * s, y - 88 * s), Vector2(x + 12 * s, y - 64 * s), Vector2(x - 12 * s, y - 64 * s)], Color("5fb3d6"))
		"pasar":
			var colors := [Color("c8553d"), Color("f2b134"), Color("1f6f6a")]
			for i in 3:
				var px := x + (i - 1) * 130 * s
				_rect(Rect2(px - 52 * s, y - 50 * s, 104 * s, 50 * s), Color("b07c4a"))
				_rect(Rect2(px - 56 * s, y - 56 * s, 112 * s, 10 * s), Color("8a5a34"))
				for f in 4:
					draw_circle(Vector2(px - 36 * s + f * 24 * s, y - 64 * s), 11 * s, [Color("e85d3f"), Color("f2b134"), Color("8cc063"), Color("f08a4b")][f], true, -1.0, true)
				_rect(Rect2(px - 50 * s, y - 140 * s, 6 * s, 90 * s), Color("6f4a2a"))
				_rect(Rect2(px + 44 * s, y - 140 * s, 6 * s, 90 * s), Color("6f4a2a"))
				var c: Color = colors[i]
				for k in 5:
					var x0 := px - 64 * s + k * 25.6 * s
					_poly([Vector2(x0, y - 120 * s), Vector2(x0 + 25.6 * s, y - 120 * s), Vector2(x0 + 25.6 * s, y - 150 * s), Vector2(x0, y - 150 * s)], c if k % 2 == 0 else Color("fff6e5"))
					draw_arc(Vector2(x0 + 12.8 * s, y - 120 * s), 12.8 * s, 0, PI, 8, c if k % 2 == 0 else Color("fff6e5"), 4, true)
			_banner(Vector2(x, y - 168 * s), "PASAR DESA", s)
		"kali":
			var pts := PackedVector2Array()
			for i in 21:
				var t := float(i) / 20.0
				pts.append(Vector2(x - 220 * s + 440 * s * t, y - 30 * s + sin(t * 6.0) * 6 * s))
			for i in range(20, -1, -1):
				var t := float(i) / 20.0
				pts.append(Vector2(x - 240 * s + 480 * s * t, y + 30 * s + sin(t * 5.0) * 6 * s))
			draw_colored_polygon(pts, Color("5fb3d6"))
			for i in 4:
				var yy := y - 14 * s + i * 12 * s
				draw_line(Vector2(x - 150 * s + i * 30 * s, yy), Vector2(x - 90 * s + i * 30 * s, yy), Color(1, 1, 1, 0.7), 3, true)
				draw_line(Vector2(x + 40 * s - i * 20 * s, yy), Vector2(x + 100 * s - i * 20 * s, yy), Color(1, 1, 1, 0.6), 3, true)
			for i in 4:
				draw_circle(Vector2(x - 200 * s + i * 120 * s, y + 36 * s), (14 + (i % 2) * 6) * s, Color("9a9a8c"), true, -1.0, true)
			# jembatan bambu
			draw_line(Vector2(x - 90 * s, y - 50 * s), Vector2(x + 90 * s, y - 50 * s), Color("7a4b2a"), 10 * s, true)
			draw_line(Vector2(x - 90 * s, y - 80 * s), Vector2(x + 90 * s, y - 80 * s), Color("9a6a3f"), 6 * s, true)
			for i in 5:
				draw_line(Vector2(x - 90 * s + i * 45 * s, y - 50 * s), Vector2(x - 90 * s + i * 45 * s, y - 82 * s), Color("9a6a3f"), 5 * s, true)
		"posyandu":
			var w := 240.0 * s
			_shadowed([Vector2(x - w * 0.5, y), Vector2(x + w * 0.5, y), Vector2(x + w * 0.5, y - 110 * s), Vector2(x - w * 0.5, y - 110 * s)], Color("fffdf8"))
			_rect(Rect2(x - 26 * s, y - 76 * s, 52 * s, 76 * s), Color("1f6f6a"))
			for sx: int in [-1, 1]:
				_rect(Rect2(x + sx * 76 * s - 22 * s, y - 84 * s, 44 * s, 36 * s), Color("9fd6df"))
			_shadowed([Vector2(x - w * 0.6, y - 106 * s), Vector2(x + w * 0.6, y - 106 * s), Vector2(x + w * 0.4, y - 160 * s), Vector2(x - w * 0.4, y - 160 * s)], Color("2f8a5a"))
			_banner(Vector2(x, y - 128 * s), "POSYANDU LANSIA", s)
			# tiang bendera
			draw_line(Vector2(x + w * 0.62, y), Vector2(x + w * 0.62, y - 200 * s), Color("8f8f8f"), 4, true)
			_poly([Vector2(x + w * 0.62, y - 200 * s), Vector2(x + w * 0.62 + 50 * s, y - 192 * s), Vector2(x + w * 0.62, y - 184 * s)], Color("c8553d"))
			_poly([Vector2(x + w * 0.62, y - 184 * s), Vector2(x + w * 0.62 + 50 * s, y - 176 * s), Vector2(x + w * 0.62, y - 168 * s)], Color("ffffff"))


func _banner(c: Vector2, text: String, s: float) -> void:
	if font == null:
		return
	var fsz := int(20 * s)
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
	var r := Rect2(c.x - tw / 2.0 - 12 * s, c.y - fsz * 0.9, tw + 24 * s, fsz * 1.35)
	draw_rect(r, Color("fff6e5"), true)
	draw_rect(r, Color("9c3d2a"), false, 3)
	draw_string(font, Vector2(c.x - tw / 2.0, c.y + fsz * 0.2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color("9c3d2a"))
