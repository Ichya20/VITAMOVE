class_name ElderFigure
extends Control
## Tokoh vektor (Mbah Putri, Mbah Kakung, Bu Kader) bergaya kartun berkontur.
## Gerak luwes: pose target dihaluskan pegas (sedikit lentur dan memantul),
## ditambah gerak diam (napas, bergoyang, berkedip) dan ekspresi wajah.

const NEUTRAL := {
	"bx": 0.0, "by": 0.0, "tilt": 0.0, "head": 0.0, "htilt": 0.0, "nod": 0.0,
	"shrug": 0.0, "breath": 0.0,
	"la": 9.0, "le": 6.0, "lf": 0.0, "ra": 9.0, "re": 6.0, "rf": 0.0,
	"ll": 0.0, "rl": 0.0, "lab": 0.0, "rab": 0.0,
	"heel": 0.0, "sit": 0.0, "squat": 0.0, "bottle": 0.0, "bags": 0.0,
}
const SNAP_KEYS := ["bottle", "bags"]
const DAMP := {
	"sit": 0.95, "squat": 0.9, "by": 0.8, "bx": 0.8, "heel": 0.85, "tilt": 0.68,
	"head": 0.52, "htilt": 0.5, "nod": 0.58, "shrug": 0.62, "breath": 0.9,
	"la": 0.6, "ra": 0.6, "le": 0.56, "re": 0.56, "lf": 0.7, "rf": 0.7,
	"ll": 0.7, "rl": 0.7, "lab": 0.72, "rab": 0.72,
}
const OMEGA := 13.0

const THIGH := 100.0
const SHIN := 98.0
const HIP := 23.0
const TORSO := 134.0
const SHW := 47.0
const HR := 45.0
const NECK := 12.0
const UA := 78.0
const FA := 72.0
const REF_H := 520.0
const OW := 3.4

@export var avatar := "putri"
@export var outfit := 0
## 0 = tanpa kursi, 1 = duduk di kursi, 2 = kursi di samping sebagai pegangan
@export var chair := 0
@export var support_hand := false
@export var show_ground := true
@export var idle := true

var pose: Dictionary = NEUTRAL.duplicate()
var face := "smile"

var _cur: Dictionary = NEUTRAL.duplicate()
var _vel: Dictionary = {}
var _t := 0.0
var _seed := 0.0
var _blink_at := 2.0
var _blink := 0.0
var _snapped := false

var _skin: Color
var _skin_dark: Color
var _top: Color
var _top_dark: Color
var _motif: Color
var _pants: Color
var _scarf: Color
var _ink := Color("2a2420")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(200, 260)
	for k in NEUTRAL.keys():
		_vel[k] = 0.0
	_seed = randf() * 10.0
	_blink_at = randf_range(1.0, 3.5)


func _ready() -> void:
	_apply_colors()


func set_avatar(a: String, o: int = -1) -> void:
	avatar = a
	if o >= 0:
		outfit = o
	_apply_colors()
	queue_redraw()


func _apply_colors() -> void:
	var oc: Dictionary = Game.outfit_colors(avatar, outfit)
	_top = oc["top"]
	_motif = oc["motif"]
	_pants = oc["pants"]
	_scarf = oc["scarf"]
	match avatar:
		"kakung":
			_skin = Color("c68a5e")
		"kader":
			_skin = Color("d9a37b")
		_:
			_skin = Color("d6a079")
	_skin_dark = _skin.darkened(0.16)
	_top_dark = _top.darkened(0.22)


func set_pose(p: Dictionary, snap: bool = false) -> void:
	pose = NEUTRAL.duplicate()
	for k in p.keys():
		if k == "face":
			face = str(p[k])
		elif pose.has(k):
			pose[k] = float(p[k])
	for k in SNAP_KEYS:
		_cur[k] = pose[k]
	if snap or not _snapped:
		snap_now()


func snap_now() -> void:
	_snapped = true
	for k in pose.keys():
		_cur[k] = pose[k]
		_vel[k] = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	var dt := minf(delta, 1.0 / 30.0)
	for k in pose.keys():
		if k in SNAP_KEYS:
			continue
		var target := float(pose[k])
		var x := float(_cur[k])
		var v := float(_vel[k])
		if absf(target - x) < 0.0005 and absf(v) < 0.0005:
			continue
		var z := float(DAMP.get(k, 0.7))
		var acc := OMEGA * OMEGA * (target - x) - 2.0 * z * OMEGA * v
		v += acc * dt
		x += v * dt
		_cur[k] = x
		_vel[k] = v
	# kedipan acak
	if _blink > 0.0:
		_blink = maxf(0.0, _blink - delta)
	elif _t >= _blink_at:
		_blink = 0.13
		_blink_at = _t + randf_range(2.4, 5.0)
	queue_redraw()


func g(k: String) -> float:
	return float(_cur.get(k, NEUTRAL.get(k, 0.0)))


static func rot(v: Vector2, deg: float) -> Vector2:
	return v.rotated(deg_to_rad(deg))


# ------------------------------------------------------------------ primitif berkontur

func _cap(a: Vector2, b: Vector2, ra: float, rb: float, c: Color) -> void:
	draw_circle(a, ra, c, true, -1.0, true)
	draw_circle(b, rb, c, true, -1.0, true)
	var d := b - a
	var l := d.length()
	if l < 0.5:
		return
	var n := Vector2(-d.y, d.x) / l
	var quad := PackedVector2Array([a + n * ra, b + n * rb, b - n * rb, a - n * ra])
	draw_colored_polygon(quad, c)
	draw_line(a + n * ra, b + n * rb, c, 1.4, true)
	draw_line(a - n * ra, b - n * rb, c, 1.4, true)


func _cap_o(a: Vector2, b: Vector2, ra: float, rb: float, c: Color) -> void:
	_cap(a, b, ra + OW, rb + OW, _ink)
	_cap(a, b, ra, rb, c)


func _poly_o(pts: PackedVector2Array, c: Color, outline: bool = true) -> void:
	if pts.size() < 3:
		return
	if outline:
		var out := Geometry2D.offset_polygon(pts, OW)
		for o in out:
			draw_colored_polygon(o, _ink)
			var closed := o.duplicate()
			closed.append(o[0])
			draw_polyline(closed, _ink, 1.6, true)
	draw_colored_polygon(pts, c)
	if not outline:
		var c2 := pts.duplicate()
		c2.append(pts[0])
		draw_polyline(c2, c, 1.4, true)


func _ell_pts(c: Vector2, rx: float, ry: float, ang: float = 0.0, n: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := float(i) / n * TAU
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(ang))
	return pts


func _ell(c: Vector2, rx: float, ry: float, col: Color, ang: float = 0.0) -> void:
	var pts := _ell_pts(c, rx, ry, ang)
	draw_colored_polygon(pts, col)
	pts.append(pts[0])
	draw_polyline(pts, col, 1.2, true)


func _ell_o(c: Vector2, rx: float, ry: float, col: Color, ang: float = 0.0) -> void:
	_ell(c, rx + OW, ry + OW, _ink, ang)
	_ell(c, rx, ry, col, ang)


static func _smooth(pts: PackedVector2Array, seg: int = 5) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	for i in n:
		var p0 := pts[(i - 1 + n) % n]
		var p1 := pts[i]
		var p2 := pts[(i + 1) % n]
		var p3 := pts[(i + 2) % n]
		for s in seg:
			var t := float(s) / seg
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	return out


# ------------------------------------------------------------------ gambar

func _draw() -> void:
	var k := minf(size.y / REF_H, size.x / 430.0)
	var origin := Vector2(size.x / 2.0, size.y - 14.0 * k)
	draw_set_transform(origin, 0.0, Vector2(k, k))
	_draw_figure()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _seat_y() -> float:
	return -(SHIN + THIGH * 0.16) + 16.0


func _side_chair_x() -> float:
	return 172.0


func _draw_chair_back(cx: float) -> void:
	var wood := Color("a8743f")
	var wood_d := Color("7a5230")
	var sy := _seat_y()
	_cap_o(Vector2(cx - 60, sy), Vector2(cx - 60, sy - 158), 7, 7, wood_d)
	_cap_o(Vector2(cx + 60, sy), Vector2(cx + 60, sy - 158), 7, 7, wood_d)
	_poly_o(PackedVector2Array([Vector2(cx - 68, sy - 170), Vector2(cx + 68, sy - 170), Vector2(cx + 66, sy - 138), Vector2(cx - 66, sy - 138)]), wood)
	_poly_o(PackedVector2Array([Vector2(cx - 62, sy - 108), Vector2(cx + 62, sy - 108), Vector2(cx + 62, sy - 94), Vector2(cx - 62, sy - 94)]), wood)
	_cap_o(Vector2(cx - 56, sy), Vector2(cx - 56, -3), 6, 6, wood_d)
	_cap_o(Vector2(cx + 56, sy), Vector2(cx + 56, -3), 6, 6, wood_d)


func _draw_chair_seat(cx: float) -> void:
	var wood := Color("c08a52")
	var wood_d := Color("7a5230")
	var sy := _seat_y()
	_cap_o(Vector2(cx - 70, sy + 18), Vector2(cx - 72, -2), 7, 7, wood_d)
	_cap_o(Vector2(cx + 70, sy + 18), Vector2(cx + 72, -2), 7, 7, wood_d)
	_poly_o(PackedVector2Array([Vector2(cx - 80, sy + 2), Vector2(cx + 80, sy + 2), Vector2(cx + 88, sy + 22), Vector2(cx - 88, sy + 22)]), wood)
	draw_line(Vector2(cx - 84, sy + 9), Vector2(cx + 84, sy + 9), Color(1, 1, 1, 0.25), 3, true)


func _draw_figure() -> void:
	var idle_k := 1.0 if idle else 0.0
	var sway := sin(_t * 0.8 + _seed) * 1.6 * idle_k
	var breath_idle := (0.5 + 0.5 * sin(_t * 1.6 + _seed)) * 0.4 * idle_k
	var sit := clampf(g("sit"), 0.0, 1.0)
	var squat := clampf(g("squat"), 0.0, 1.2)
	var heel := clampf(g("heel"), 0.0, 1.0)
	var tilt := g("tilt")
	var breath := g("breath") + breath_idle

	if show_ground:
		for i in 3:
			_ell(Vector2(g("bx") * 0.5, 4), 118.0 - i * 26.0, 15.0 - i * 3.0, Color(0.05, 0.18, 0.16, 0.07 + i * 0.03))

	if chair == 1:
		_draw_chair_back(0.0)
	if chair == 2:
		_draw_chair_back(_side_chair_x())
		_draw_chair_seat(_side_chair_x())

	var f_sup := lerpf(1.0, 0.16, sit) * (1.0 - 0.33 * squat)
	var pelvis := Vector2(g("bx") + sway, -(SHIN + THIGH * f_sup) - heel * 14.0 * (1.0 - sit) + g("by"))

	if chair == 1:
		_draw_chair_seat(0.0)

	# ---------------- kaki
	for s: int in [-1, 1]:
		var lift := g("ll") if s == -1 else g("rl")
		var ab := g("lab") if s == -1 else g("rab")
		var hip := pelvis + Vector2(s * HIP, 0)
		var f := lerpf(1.0, 0.16, sit) * (1.0 - 0.33 * squat) - lift * lerpf(0.85, 0.5, sit)
		var spread := s * (5.0 + 14.0 * sit + 24.0 * squat)
		var thigh := rot(Vector2(0, THIGH * f), -s * ab) + Vector2(spread, 0)
		var knee := hip + thigh
		var shin := rot(Vector2(0, SHIN), -s * ab * 0.6)
		var foot := knee + shin
		if sit > 0.5 and lift < 0.05 and ab < 1.0:
			foot.y = -heel * 14.0 * sit
		var ankle := foot + Vector2(0, -12)
		_cap_o(hip, knee, 20, 17, _pants)
		_cap_o(knee, ankle, 16.5, 13.5, _pants)
		draw_line(knee + Vector2(-8, -2), knee + Vector2(8, 2), Color(_pants.darkened(0.25), 0.7), 2.5, true)
		var tip := heel > 0.3
		var fc := foot + Vector2(s * 7.0, -3.0)
		if tip:
			_ell_o(fc + Vector2(0, -3), 15, 9, Color("4a3426"))
			_ell(fc + Vector2(0, -7), 11, 6, _skin)
		else:
			_ell_o(fc, 25, 9, Color("4a3426"))
			_ell(fc + Vector2(-s * 2, -5), 18, 7, _skin)
			draw_line(fc + Vector2(-12, -8), fc + Vector2(12, -8), Color("7a4b2a"), 5, true)

	# ---------------- badan
	var up := rot(Vector2(0, -1), tilt)
	var side := rot(Vector2(1, 0), tilt)
	var wk := 1.0 + 0.05 * breath
	var shrug := g("shrug") * 16.0 + breath * 3.0
	var top := pelvis + up * (TORSO + 3.0 * breath)
	var tp := func(x, yup) -> Vector2:
		return pelvis + side * float(x) * wk + up * float(yup)
	var long_top := avatar != "kakung"
	var hem := -44.0 if long_top else -16.0
	var flare := 10.0 if long_top else 2.0
	var raw := PackedVector2Array([
		tp.call(-14, TORSO + 2), tp.call(14, TORSO + 2),
		tp.call(SHW - 6, TORSO - 2 + shrug * 0.5), tp.call(SHW + 5, TORSO - 16 + shrug * 0.6),
		tp.call(SHW - 2, TORSO - 48), tp.call(SHW - 9, 62),
		tp.call(SHW + 2, 4), tp.call(SHW + flare, hem + 6),
		tp.call(0, hem), tp.call(-SHW - flare, hem + 6),
		tp.call(-SHW - 2, 4), tp.call(-SHW + 9, 62),
		tp.call(-SHW + 2, TORSO - 48), tp.call(-SHW - 5, TORSO - 16 + shrug * 0.6),
		tp.call(-SHW + 6, TORSO - 2 + shrug * 0.5),
	])
	var body := _smooth(raw, 5)
	_poly_o(body, _top)
	# bayangan samping untuk volume
	var shade := PackedVector2Array([tp.call(SHW - 16, TORSO - 30), tp.call(SHW - 4, TORSO - 46), tp.call(SHW - 8, 60), tp.call(SHW + 1, 6), tp.call(SHW + flare - 4, hem + 8), tp.call(SHW - 18, hem + 4), tp.call(SHW - 22, 40)])
	draw_colored_polygon(_smooth(shade, 3), Color(_top_dark, 0.35))
	_draw_motif(body, tp, hem)
	if avatar == "kakung":
		# kerah, kancing, saku
		_poly_o(PackedVector2Array([tp.call(-16, TORSO + 2), tp.call(-2, TORSO - 22), tp.call(-24, TORSO - 14)]), _top.lightened(0.12))
		_poly_o(PackedVector2Array([tp.call(16, TORSO + 2), tp.call(2, TORSO - 22), tp.call(24, TORSO - 14)]), _top.lightened(0.12))
		draw_line(tp.call(0, TORSO - 20), tp.call(0, hem + 6), Color(_top_dark, 0.8), 3, true)
		for i in 3:
			draw_circle(tp.call(0, TORSO - 40 - i * 34), 3.4, _motif, true, -1.0, true)
		var pk := PackedVector2Array([tp.call(-36, TORSO - 46), tp.call(-14, TORSO - 46), tp.call(-15, TORSO - 70), tp.call(-35, TORSO - 70)])
		pk.append(pk[0])
		draw_polyline(pk, Color(_top_dark, 0.85), 2.5, true)

	# ---------------- kepala
	var head_dir := rot(Vector2(0, -1), tilt + g("htilt"))
	var head_c := top + head_dir * (NECK + HR) + Vector2(0, g("nod") * 9.0)
	var hang := deg_to_rad(tilt + g("htilt"))
	var turn := clampf(g("head"), -1.0, 1.0)
	var veiled := avatar != "kakung"
	if veiled:
		_ell_o(head_c + Vector2(0, -3), HR + 13, HR + 15, _scarf, hang)
	else:
		_cap_o(top + up * 4, head_c + head_dir * -20, 15, 15, _skin_dark)
		for s: int in [-1, 1]:
			_ell_o(head_c + Vector2(s * (HR - 2) + turn * 6, 4).rotated(hang), 8, 12, _skin_dark, hang)
	_ell_o(head_c, HR * (1.0 - absf(turn) * 0.05), HR * 1.05, _skin, hang)
	if veiled:
		_draw_veil(head_c, hang, top, side, up)
	else:
		for s: int in [-1, 1]:
			var hx := head_c + Vector2(s * (HR - 6) + turn * 5, -10).rotated(hang)
			_ell(hx, 9, 15, Color("efefea"), hang)
	_draw_face(head_c, hang, turn)
	if avatar == "kakung":
		_draw_peci(head_c, hang)

	# ---------------- lengan
	var l_sh := top - side * SHW * wk + up * shrug
	var r_sh := top + side * SHW * wk + up * shrug
	var arm_idle := sin(_t * 1.6 + _seed) * 1.6 * idle_k
	for s: int in [-1, 1]:
		var sh := l_sh if s == -1 else r_sh
		var hand: Vector2
		var elbow: Vector2
		var fw := clampf(g("lf") if s == -1 else g("rf"), 0.0, 1.0)
		if s == 1 and chair == 2 and support_hand:
			var grip := Vector2(_side_chair_x() - 44.0, _seat_y() - 162.0)
			var res := _ik(sh, grip, UA, FA, 1)
			elbow = res[0]
			hand = res[1]
		else:
			var a := (g("la") if s == -1 else g("ra")) + arm_idle
			var e := g("le") if s == -1 else g("re")
			var k1 := 1.0 - 0.55 * fw
			var d1 := rot(Vector2(s * sin(deg_to_rad(a)), cos(deg_to_rad(a))), tilt)
			var a2 := a + e
			var d2 := rot(Vector2(s * sin(deg_to_rad(a2)), cos(deg_to_rad(a2))), tilt)
			elbow = sh + d1 * UA * k1
			hand = elbow + d2 * FA * k1
		_cap_o(sh, elbow, 15.5, 13.5, _top)
		if avatar == "kakung":
			var mid := elbow.lerp(hand, 0.35)
			_cap_o(elbow, hand, 11, 10, _skin)
			_cap(elbow, mid, 13.5, 12.5, _top)
			draw_line(mid + (mid - elbow).orthogonal().normalized() * 12.5, mid - (mid - elbow).orthogonal().normalized() * 12.5, _top_dark, 3, true)
		else:
			_cap_o(elbow, hand, 13, 11.5, _top)
			var cuff := hand.lerp(elbow, 0.18)
			_cap(cuff, hand.lerp(elbow, 0.05), 12.5, 12, _motif)
		var hr := 13.0 * (1.0 + 0.35 * fw)
		var thumb_dir := (hand - elbow).normalized().rotated(-s * 1.2)
		_ell_o(hand + thumb_dir * hr * 0.75, hr * 0.42, hr * 0.42, _skin)
		_ell_o(hand, hr, hr * 0.92, _skin)
		if g("bottle") > 0.5:
			var dirb := (hand - elbow).normalized()
			var perp := Vector2(-dirb.y, dirb.x)
			var b0 := hand - dirb * 2
			_poly_o(PackedVector2Array([b0 + perp * 11, b0 + perp * 11 + dirb * 50, b0 - perp * 11 + dirb * 50, b0 - perp * 11]), Color("7cc3e0"))
			draw_line(b0 + perp * 5 + dirb * 6, b0 + perp * 5 + dirb * 44, Color(1, 1, 1, 0.6), 4, true)
			_cap_o(b0 + dirb * 50, b0 + dirb * 58, 6, 6, Color("2b6c8f"))
			_ell_o(hand, hr, hr * 0.92, _skin)
		if g("bags") > 0.5:
			var bt := hand + Vector2(0, 8)
			draw_arc(bt + Vector2(0, 10), 15, PI, TAU, 14, _ink, 5, true)
			_poly_o(PackedVector2Array([bt + Vector2(-28, 10), bt + Vector2(28, 10), bt + Vector2(21, 58), bt + Vector2(-21, 58)]), Color("d8a24a"))
			for i in 3:
				draw_line(bt + Vector2(-25 + i * 2, 24 + i * 11), bt + Vector2(25 - i * 2, 24 + i * 11), Color("a8742a"), 3, true)
			_ell(bt + Vector2(-8, 4), 8, 8, Color("8cc063"))
			_ell(bt + Vector2(8, 2), 7, 7, Color("e85d3f"))
			_ell_o(hand, hr, hr * 0.92, _skin)


func _draw_motif(body: PackedVector2Array, tp: Callable, hem: float) -> void:
	var inset := Geometry2D.offset_polygon(body, -10.0)
	if inset.is_empty():
		return
	var area: PackedVector2Array = inset[0]
	if avatar == "kakung":
		# kawung rapat khas batik
		for row in range(-1, 6):
			for col in range(-3, 4):
				var p: Vector2 = tp.call(col * 22.0 + (11.0 if row % 2 == 0 else 0.0), row * 22.0 - 4.0)
				if Geometry2D.is_point_in_polygon(p, area):
					for q in 4:
						var a := q * PI / 2.0 + PI / 4.0
						_ell(p + Vector2(cos(a), sin(a)) * 5.0, 4.6, 2.6, Color(_motif, 0.9), a)
					draw_circle(p, 1.6, _top_dark, true, -1.0, true)
	else:
		# bunga kecil tersebar + pita motif di keliman
		for row in range(0, 4):
			for col in range(-2, 3):
				var p2: Vector2 = tp.call(col * 30.0 + (15.0 if row % 2 == 1 else 0.0), 18.0 + row * 30.0)
				if Geometry2D.is_point_in_polygon(p2, area):
					for q in 4:
						var a2 := q * PI / 2.0
						_ell(p2 + Vector2(cos(a2), sin(a2)) * 4.5, 4.0, 2.4, Color(_motif, 0.85), a2)
		var band := PackedVector2Array()
		for i in 13:
			var x := -SHW - 8 + i * (SHW * 2 + 16) / 12.0
			band.append(tp.call(x, hem + 18 + absf(x) * 0.06))
		draw_polyline(band, Color(_motif, 0.9), 8, true)
		for i in 12:
			var x2 := -SHW - 2 + i * (SHW * 2 + 4) / 11.0
			draw_circle(tp.call(x2, hem + 19 + absf(x2) * 0.06), 2.2, _top_dark, true, -1.0, true)


func _ik(a: Vector2, target: Vector2, l1: float, l2: float, bend: int) -> Array:
	var d := a.distance_to(target)
	d = clampf(d, absf(l1 - l2) + 1.0, l1 + l2 - 1.0)
	var dir := (target - a).normalized()
	var cos_a := (l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d)
	var ang := acos(clampf(cos_a, -1.0, 1.0)) * bend
	return [a + dir.rotated(ang) * l1, a + dir * d]


func _draw_veil(head_c: Vector2, hang: float, top: Vector2, side: Vector2, up: Vector2) -> void:
	# jatuhan kerudung membingkai wajah dan menutup bahu
	var r := HR
	var raw := PackedVector2Array([
		head_c + Vector2(-r - 12, -8).rotated(hang),
		top - side * (SHW + 6) - up * 8,
		top - side * (SHW - 4) - up * 46,
		top - up * 58,
		top + side * (SHW - 4) - up * 46,
		top + side * (SHW + 6) - up * 8,
		head_c + Vector2(r + 12, -8).rotated(hang),
		head_c + Vector2(r * 0.86, r * 0.62).rotated(hang),
		head_c + Vector2(0, r + 4).rotated(hang),
		head_c + Vector2(-r * 0.86, r * 0.62).rotated(hang),
	])
	var drape := _smooth(raw, 4)
	_poly_o(drape, _scarf)
	# lipatan kain
	var fold := _scarf.darkened(0.18)
	draw_arc(top - up * 22, 30, PI * 0.15, PI * 0.85, 12, fold, 3, true)
	draw_line(top - side * 26 - up * 12, top - side * 20 - up * 44, fold, 3, true)
	draw_line(top + side * 26 - up * 12, top + side * 20 - up * 44, fold, 3, true)
	# pita dahi
	draw_arc(head_c, r + 3, hang + PI * 1.12, hang + PI * 1.88, 24, _scarf.darkened(0.08), 9, true)


func _draw_face(c: Vector2, ang: float, turn: float) -> void:
	var off := Vector2(turn * 13.0, g("nod") * 5.0)
	var ink := Color("2b2320")
	var eye_y := -3.0
	var elder := avatar != "kader"
	var happy_eyes := face == "happy"
	for s: int in [-1, 1]:
		var ep := c + Vector2(s * 15 + off.x, eye_y + off.y).rotated(ang)
		if _blink > 0.0 or happy_eyes:
			draw_arc(ep + Vector2(0, 2).rotated(ang), 6.5, ang + PI * 1.1, ang + PI * 1.9, 10, ink, 3.2, true)
		elif face == "focus":
			_ell(ep, 4.6, 3.6, ink, ang)
		else:
			_ell(ep, 4.8, 5.8, ink, ang)
			draw_circle(ep + Vector2(1.6, -2.0).rotated(ang), 1.6, Color.WHITE, true, -1.0, true)
		var brow := Color("f1efe8") if avatar == "kakung" else (Color("3a2c22") if avatar == "kader" else Color("6a5242"))
		var lift := -2.0 if face in ["happy", "o"] else (2.0 if face == "focus" else 0.0)
		draw_line(ep + Vector2(-8, -12 + lift - (s * 1.5 if face == "focus" else 0.0)).rotated(ang), ep + Vector2(8, -13 + lift + (s * 1.5 if face == "focus" else 0.0)).rotated(ang), brow, 4.5, true)
		_ell(c + Vector2(s * 25 + off.x, 13 + off.y).rotated(ang), 7.5, 4.8, Color(0.92, 0.42, 0.4, 0.33), ang)
		if elder:
			# kerutan halus di sudut mata
			var cw := c + Vector2(s * 24 + off.x, eye_y + off.y).rotated(ang)
			draw_line(cw, cw + Vector2(s * 6, -3).rotated(ang), Color(_skin_dark, 0.9), 1.8, true)
			draw_line(cw + Vector2(0, 3).rotated(ang), cw + Vector2(s * 6, 5).rotated(ang), Color(_skin_dark, 0.9), 1.8, true)
	# hidung
	draw_arc(c + Vector2(off.x * 1.15, 7 + off.y).rotated(ang), 4.5, ang + 0.2, ang + PI - 0.2, 8, _skin_dark.darkened(0.2), 2.6, true)
	# mulut sesuai ekspresi
	var mc := c + Vector2(off.x, 19 + off.y).rotated(ang)
	var lip := Color("8a3b2e")
	match face:
		"happy":
			var mouth := PackedVector2Array()
			for i in 13:
				var a := PI * float(i) / 12.0
				mouth.append(mc + Vector2(-cos(a) * 11, sin(a) * 9 - 2).rotated(ang))
			draw_colored_polygon(mouth, lip)
			_ell(mc + Vector2(0, 4).rotated(ang), 5, 2.5, Color("e9867a"), ang)
		"o":
			_ell(mc + Vector2(0, 1).rotated(ang), 5, 6, lip, ang)
		"blow":
			_ell(mc + Vector2(2, 1).rotated(ang), 4, 3, lip, ang)
			draw_arc(mc + Vector2(13, 0).rotated(ang), 4, ang - 0.8, ang + 0.8, 6, Color(1, 1, 1, 0.8), 2, true)
		"focus":
			draw_arc(mc + Vector2(0, -3).rotated(ang), 9, ang + 0.5, ang + PI - 0.5, 10, lip, 3.4, true)
		_:
			draw_arc(mc + Vector2(0, -4).rotated(ang), 11, ang + 0.35, ang + PI - 0.35, 12, lip, 3.6, true)
	if avatar == "kakung":
		# kumis putih dan kacamata bulat
		var must := Color("f4f1ea")
		_ell(mc + Vector2(-7, -8).rotated(ang), 8, 4, must, ang - 0.15)
		_ell(mc + Vector2(7, -8).rotated(ang), 8, 4, must, ang + 0.15)
		for s: int in [-1, 1]:
			var gp := c + Vector2(s * 15 + off.x, eye_y + off.y).rotated(ang)
			draw_arc(gp, 11.5, 0, TAU, 22, Color("3a3a3a"), 2.6, true)
		draw_line(c + Vector2(-3.5 + off.x, eye_y + off.y).rotated(ang), c + Vector2(3.5 + off.x, eye_y + off.y).rotated(ang), Color("3a3a3a"), 2.6, true)
	elif elder:
		draw_arc(mc + Vector2(-17, -7).rotated(ang), 7, ang + PI * 0.55, ang + PI * 0.95, 6, Color(_skin_dark, 0.8), 1.8, true)
		draw_arc(mc + Vector2(17, -7).rotated(ang), 7, ang + PI * 0.05, ang + PI * 0.45, 6, Color(_skin_dark, 0.8), 1.8, true)


func _draw_peci(c: Vector2, ang: float) -> void:
	var raw := PackedVector2Array([
		c + Vector2(-HR + 1, -16).rotated(ang),
		c + Vector2(HR - 1, -16).rotated(ang),
		c + Vector2(HR - 5, -50).rotated(ang),
		c + Vector2(0, -55).rotated(ang),
		c + Vector2(-HR + 5, -50).rotated(ang),
	])
	_poly_o(raw, Color("232323"))
	draw_line(c + Vector2(-HR + 6, -24).rotated(ang), c + Vector2(HR - 6, -24).rotated(ang), Color("4a4a4a"), 4, true)
	draw_line(c + Vector2(-HR + 12, -44).rotated(ang), c + Vector2(-6, -48).rotated(ang), Color(1, 1, 1, 0.18), 4, true)
