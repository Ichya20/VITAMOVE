class_name ElderFigure
extends Control
## Tokoh lansia vektor yang dapat digerakkan dengan parameter pose.
## Tampak depan, seperti instruktur yang berhadapan (gerakan dicerminkan).

const NEUTRAL := {
	"bx": 0.0, "by": 0.0, "tilt": 0.0, "head": 0.0, "htilt": 0.0, "nod": 0.0,
	"shrug": 0.0, "breath": 0.0,
	"la": 8.0, "le": 0.0, "lf": 0.0, "ra": 8.0, "re": 0.0, "rf": 0.0,
	"ll": 0.0, "rl": 0.0, "lab": 0.0, "rab": 0.0,
	"heel": 0.0, "sit": 0.0, "squat": 0.0, "bottle": 0.0, "bags": 0.0, "smile": 1.0,
}

const L1 := 105.0
const L2 := 105.0
const HW := 25.0
const TORSO := 150.0
const SHW := 50.0
const HEAD_R := 40.0
const UA := 84.0
const FA := 80.0
const REF_H := 560.0

@export var avatar := "putri"
## 0 = tanpa kursi, 1 = duduk di kursi, 2 = kursi di samping sebagai pegangan
@export var chair := 0
@export var support_hand := false
@export var show_ground := true

var pose: Dictionary = NEUTRAL.duplicate()
var blink := 0.0
var _t := 0.0

var _skin: Color
var _skin_dark: Color
var _top: Color
var _top_dark: Color
var _motif: Color
var _pants: Color
var _shoe: Color


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(220, 300)


func _ready() -> void:
	_apply_colors()


func set_avatar(a: String) -> void:
	avatar = a
	_apply_colors()
	queue_redraw()


func _apply_colors() -> void:
	if avatar == "kakung":
		_skin = Color("c68a5e")
		_top = Color("b4532a")
		_motif = Color("f2b134")
		_pants = Color("34495e")
		_shoe = Color("4a3426")
	else:
		_skin = Color("d6a079")
		_top = Color("1f6f6a")
		_motif = Color("fde7b0")
		_pants = Color("5b3f35")
		_shoe = Color("3b2c25")
	_skin_dark = _skin.darkened(0.18)
	_top_dark = _top.darkened(0.25)


func set_pose(p: Dictionary) -> void:
	pose = NEUTRAL.duplicate()
	for k in p.keys():
		pose[k] = p[k]
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	# kedip sesekali
	var phase := fmod(_t, 4.2)
	var nb := 1.0 if phase > 4.05 else 0.0
	if nb != blink:
		blink = nb
		queue_redraw()


func g(k: String) -> float:
	return float(pose.get(k, NEUTRAL.get(k, 0.0)))


static func rot(v: Vector2, deg: float) -> Vector2:
	return v.rotated(deg_to_rad(deg))


func _limb(a: Vector2, b: Vector2, w: float, c: Color) -> void:
	draw_line(a, b, c, w, true)
	draw_circle(a, w * 0.5, c, true, -1.0, true)
	draw_circle(b, w * 0.5, c, true, -1.0, true)


func _ellipse(c: Vector2, rx: float, ry: float, col: Color, ang: float = 0.0) -> void:
	var pts := PackedVector2Array()
	for i in 28:
		var a := float(i) / 28.0 * TAU
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(ang))
	draw_colored_polygon(pts, col)


func _draw() -> void:
	var k := minf(size.y / REF_H, size.x / 430.0)
	var origin := Vector2(size.x / 2.0, size.y - 18.0 * k)
	draw_set_transform(origin, 0.0, Vector2(k, k))
	_draw_figure()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _seat_y() -> float:
	return -(L2 + L1 * 0.15) + 14.0


func _draw_chair_back(cx: float) -> void:
	var wood := Color("9a6a3f")
	var wood_d := Color("6f4a2a")
	var sy := _seat_y()
	# sandaran
	_limb(Vector2(cx - 62, sy), Vector2(cx - 62, sy - 160), 14, wood_d)
	_limb(Vector2(cx + 62, sy), Vector2(cx + 62, sy - 160), 14, wood_d)
	draw_rect(Rect2(cx - 66, sy - 168, 132, 30), wood, true)
	draw_rect(Rect2(cx - 66, sy - 112, 132, 16), wood, true)
	# kaki kursi belakang
	_limb(Vector2(cx - 58, sy), Vector2(cx - 58, -2), 12, wood_d)
	_limb(Vector2(cx + 58, sy), Vector2(cx + 58, -2), 12, wood_d)


func _draw_chair_seat(cx: float) -> void:
	var wood := Color("b07c4a")
	var wood_d := Color("6f4a2a")
	var sy := _seat_y()
	_limb(Vector2(cx - 70, sy + 16), Vector2(cx - 70, 0), 13, wood_d)
	_limb(Vector2(cx + 70, sy + 16), Vector2(cx + 70, 0), 13, wood_d)
	var seat := PackedVector2Array([Vector2(cx - 80, sy + 4), Vector2(cx + 80, sy + 4), Vector2(cx + 86, sy + 22), Vector2(cx - 86, sy + 22)])
	draw_colored_polygon(seat, wood)
	draw_line(Vector2(cx - 86, sy + 22), Vector2(cx + 86, sy + 22), wood_d, 4, true)


func _side_chair_x() -> float:
	return 175.0


func _draw_figure() -> void:
	var sit := clampf(g("sit"), 0.0, 1.0)
	var squat := clampf(g("squat"), 0.0, 1.0)
	var heel := clampf(g("heel"), 0.0, 1.0)
	var tilt := g("tilt")
	var breath := g("breath")

	if show_ground:
		_ellipse(Vector2(g("bx") * 0.6, 4), 120, 16, Color(0.06, 0.2, 0.18, 0.18))

	if chair == 1:
		_draw_chair_back(0.0)
	if chair == 2:
		_draw_chair_back(_side_chair_x())
		_draw_chair_seat(_side_chair_x())

	var f_sup := lerpf(1.0, 0.15, sit) * (1.0 - 0.33 * squat)
	var pelvis := Vector2(g("bx"), -(L2 + L1 * f_sup) - heel * 14.0 * (1.0 - sit) + g("by"))

	if chair == 1:
		_draw_chair_seat(0.0)

	# ---------------- kaki
	var leg_w := 34.0
	for s: int in [-1, 1]:
		var lift := g("ll") if s == -1 else g("rl")
		var ab := g("lab") if s == -1 else g("rab")
		var hip := pelvis + Vector2(s * HW, 0)
		var f := lerpf(1.0, 0.15, sit) * (1.0 - 0.33 * squat) - lift * lerpf(0.85, 0.5, sit)
		var spread := s * (6.0 + 14.0 * sit + 26.0 * squat)
		var thigh := rot(Vector2(0, L1 * f), -s * ab) + Vector2(spread, 0)
		var knee := hip + thigh
		var shin := rot(Vector2(0, L2), -s * ab * 0.6)
		var foot := knee + shin
		if sit > 0.5 and lift < 0.05 and ab < 1.0:
			foot.y = -heel * 14.0 * sit
		# celana
		_limb(hip, knee, leg_w, _pants)
		_limb(knee, foot + Vector2(0, -10), leg_w * 0.9, _pants)
		# sepatu / sandal
		var tip := heel > 0.3
		var fc := foot + Vector2(s * 8.0, -2.0)
		if tip:
			_ellipse(fc + Vector2(0, -2), 20, 13, _shoe)
		else:
			_ellipse(fc, 26, 12, _shoe)

	# ---------------- badan
	var up := rot(Vector2(0, -1), tilt)
	var side := rot(Vector2(1, 0), tilt)
	var width_k := 1.0 + 0.06 * breath
	var top := pelvis + up * (TORSO + 4.0 * breath)
	var shrug := g("shrug") * 16.0 + breath * 4.0
	var l_sh := top - side * SHW * width_k - up * (-shrug)
	var r_sh := top + side * SHW * width_k - up * (-shrug)
	var hipL := pelvis - side * (HW + 12)
	var hipR := pelvis + side * (HW + 12)
	var waistL := pelvis + up * 60 - side * (SHW - 8) * width_k
	var waistR := pelvis + up * 60 + side * (SHW - 8) * width_k
	var body := PackedVector2Array([hipL - up * 22, waistL, l_sh + up * 2, l_sh + side * 18 + up * 14, top + up * 10, r_sh - side * 18 + up * 14, r_sh + up * 2, waistR, hipR - up * 22])
	draw_colored_polygon(body, _top)
	# lipatan dan motif batik sederhana (kawung)
	var mid := pelvis + up * 70
	for row in 3:
		for col in [-1, 0, 1]:
			var c: Vector2 = mid + up * (row * 34 - 34) + side * (col * 28 + (14 if row % 2 == 1 else 0))
			if absf(col * 28 + (14 if row % 2 == 1 else 0)) > 36:
				continue
			for q in 4:
				var a := q * PI / 2.0 + deg_to_rad(tilt)
				_ellipse(c + Vector2(cos(a), sin(a)) * 6.0, 5.5, 3.2, Color(_motif, 0.85), a)
	draw_line(top + up * 6, pelvis + up * 20, Color(_top_dark, 0.6), 3, true)

	# ---------------- kepala
	var head_c := top + rot(Vector2(0, -1), tilt + g("htilt")) * (18 + HEAD_R) + Vector2(0, g("nod") * 10)
	var neck_b := top + up * 6
	_limb(neck_b, head_c + Vector2(0, 20), 26, _skin_dark)
	if avatar == "putri":
		_draw_kerudung(head_c, top, side, up)
	_ellipse(head_c, HEAD_R * (1.0 - absf(g("head")) * 0.05), HEAD_R * 1.05, _skin, deg_to_rad(tilt + g("htilt")))
	_draw_face(head_c, tilt + g("htilt"))
	if avatar == "kakung":
		_draw_peci(head_c, tilt + g("htilt"))

	# ---------------- lengan
	var arm_w := 24.0
	var sleeve := _top.lightened(0.05)
	for s: int in [-1, 1]:
		var sh := l_sh if s == -1 else r_sh
		var hand: Vector2
		var elbow: Vector2
		if s == 1 and chair == 2 and support_hand:
			var grip := Vector2(_side_chair_x() - 40.0, _seat_y() - 160.0)
			var res := _ik(sh, grip, UA, FA, 1)
			elbow = res[0]
			hand = res[1]
		else:
			var a := g("la") if s == -1 else g("ra")
			var e := g("le") if s == -1 else g("re")
			var fw := clampf(g("lf") if s == -1 else g("rf"), 0.0, 1.0)
			var k1 := 1.0 - 0.55 * fw
			var d1 := rot(Vector2(s * sin(deg_to_rad(a)), cos(deg_to_rad(a))), tilt)
			var a2 := a + e
			var d2 := rot(Vector2(s * sin(deg_to_rad(a2)), cos(deg_to_rad(a2))), tilt)
			elbow = sh + d1 * UA * k1
			hand = elbow + d2 * FA * k1
		_limb(sh, elbow, arm_w + 4, sleeve)
		_limb(elbow, hand, arm_w - 2, _skin)
		var hr := 13.0 * (1.0 + 0.35 * clampf(g("lf") if s == -1 else g("rf"), 0.0, 1.0))
		draw_circle(hand, hr, _skin_dark, true, -1.0, true)
		draw_circle(hand, hr - 3, _skin, true, -1.0, true)
		if g("bottle") > 0.5:
			var dirb := (hand - elbow).normalized()
			var perp := Vector2(-dirb.y, dirb.x)
			var b0 := hand - dirb * 4
			var pts := PackedVector2Array([b0 + perp * 11, b0 + perp * 11 + dirb * 46, b0 - perp * 11 + dirb * 46, b0 - perp * 11])
			draw_colored_polygon(pts, Color("5fb3d6"))
			draw_line(b0 + dirb * 46, b0 + dirb * 54, Color("2b6c8f"), 12, true)
			draw_circle(hand, hr - 3, _skin, true, -1.0, true)
		if g("bags") > 0.5:
			var bag_top := hand + Vector2(0, 8)
			draw_arc(bag_top + Vector2(0, 8), 14, PI, TAU, 12, Color("6f4a2a"), 4, true)
			var bag := PackedVector2Array([bag_top + Vector2(-26, 10), bag_top + Vector2(26, 10), bag_top + Vector2(20, 54), bag_top + Vector2(-20, 54)])
			draw_colored_polygon(bag, Color("d8a24a"))
			for i in 3:
				draw_line(bag_top + Vector2(-24 + i * 2, 22 + i * 11), bag_top + Vector2(24 - i * 2, 22 + i * 11), Color("a8742a"), 3, true)
			draw_circle(hand, hr - 3, _skin, true, -1.0, true)


func _ik(a: Vector2, target: Vector2, l1: float, l2: float, bend: int) -> Array:
	var d := a.distance_to(target)
	d = clampf(d, absf(l1 - l2) + 1.0, l1 + l2 - 1.0)
	var dir := (target - a).normalized()
	var cos_a := (l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d)
	var ang := acos(clampf(cos_a, -1.0, 1.0)) * bend
	var elbow := a + dir.rotated(ang) * l1
	var hand := a + dir * d
	return [elbow, hand]


func _draw_kerudung(head_c: Vector2, top: Vector2, side: Vector2, up: Vector2) -> void:
	var c := Color("f2b134")
	var c2 := Color("d48f16")
	# jatuhan kerudung ke bahu
	var drape := PackedVector2Array([
		head_c + Vector2(-HEAD_R - 8, -6),
		head_c + Vector2(HEAD_R + 8, -6),
		top + side * 44 + up * -26,
		top + side * 24 + up * -46,
		top - side * 24 + up * -46,
		top - side * 44 + up * -26,
	])
	draw_colored_polygon(drape, c2)
	_ellipse(head_c + Vector2(0, -2), HEAD_R + 11, HEAD_R + 14, c)


func _draw_face(c: Vector2, ang: float) -> void:
	var turn := clampf(g("head"), -1.0, 1.0)
	var r := deg_to_rad(ang)
	var off := Vector2(turn * 14.0, g("nod") * 6.0)
	var eye_y := -2.0
	var ink := Color("2b2320")
	for s: int in [-1, 1]:
		var ep := c + Vector2(s * 14 + off.x, eye_y + off.y).rotated(r)
		if blink > 0.5:
			draw_line(ep + Vector2(-6, 0).rotated(r), ep + Vector2(6, 0).rotated(r), ink, 3, true)
		else:
			_ellipse(ep, 4.5, 5.5, ink, r)
		# alis
		var brow := Color("f4f1ea") if avatar == "kakung" else Color("5a4636")
		draw_line(ep + Vector2(-8, -11).rotated(r), ep + Vector2(7, -13).rotated(r), brow, 4, true)
		# pipi
		_ellipse(c + Vector2(s * 24 + off.x, 14 + off.y).rotated(r), 7, 4.5, Color(0.9, 0.42, 0.38, 0.35), r)
	# hidung
	draw_line(c + Vector2(off.x * 1.2, 2 + off.y).rotated(r), c + Vector2(off.x * 1.2 + 2, 11 + off.y).rotated(r), _skin_dark.darkened(0.15), 3, true)
	# senyum
	var smile_c := c + Vector2(off.x, 16 + off.y).rotated(r)
	draw_arc(smile_c, 11, r + 0.35, r + PI - 0.35, 12, Color("8a3b2e"), 3.5, true)
	if avatar == "kakung":
		# kumis putih dan kacamata
		draw_line(smile_c + Vector2(-12, -4).rotated(r), smile_c + Vector2(-1, -6).rotated(r), Color("f4f1ea"), 5, true)
		draw_line(smile_c + Vector2(1, -6).rotated(r), smile_c + Vector2(12, -4).rotated(r), Color("f4f1ea"), 5, true)
		for s: int in [-1, 1]:
			var gp := c + Vector2(s * 14 + off.x, eye_y + off.y).rotated(r)
			draw_arc(gp, 11, 0, TAU, 20, Color("3a3a3a"), 2.5, true)
		draw_line(c + Vector2(-3 + off.x, eye_y + off.y).rotated(r), c + Vector2(3 + off.x, eye_y + off.y).rotated(r), Color("3a3a3a"), 2.5, true)
		# rambut putih di sisi
		for s: int in [-1, 1]:
			_ellipse(c + Vector2(s * (HEAD_R - 4), -4).rotated(r), 8, 14, Color("eeeeea"), r)


func _draw_peci(c: Vector2, ang: float) -> void:
	var r := deg_to_rad(ang)
	var pts := PackedVector2Array([
		c + Vector2(-HEAD_R + 2, -18).rotated(r),
		c + Vector2(HEAD_R - 2, -18).rotated(r),
		c + Vector2(HEAD_R - 6, -50).rotated(r),
		c + Vector2(-HEAD_R + 6, -50).rotated(r),
	])
	draw_colored_polygon(pts, Color("232323"))
	draw_line(c + Vector2(-HEAD_R + 4, -22).rotated(r), c + Vector2(HEAD_R - 4, -22).rotated(r), Color("444444"), 3, true)
