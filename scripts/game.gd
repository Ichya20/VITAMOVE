extends Node
## Autoload "Game": status global, penyimpanan, tema UI v2, dan suara pemandu (TTS).

signal settings_changed
signal profile_changed

const SAVE_PATH := "user://vitamove_save.json"
const SAVE_VERSION := 2

# ------------------------------------------------------------------ palet "papercut desa"
const TEAL := Color("0f4c4a")
const TEAL_MID := Color("1e6b66")
const TEAL_SOFT := Color("d3eae4")
const TERRA := Color("c8553d")
const TERRA_DARK := Color("9c3d2a")
const TERRA_SOFT := Color("f7d9cf")
const SAFFRON := Color("f2b134")
const SAFFRON_DARK := Color("c98a12")
const SAFFRON_SOFT := Color("fde7b0")
const LEAF := Color("4f8a3c")
const LEAF_DARK := Color("3a6a2b")
const LEAF_SOFT := Color("dcebc9")
const CREAM := Color("fff6e5")
const PAPER := Color("fffdf8")
const INK := Color("23302e")
const INK_SOFT := Color("52615e")
const SKY := Color("bfe3ea")
const DANGER := Color("b3261e")
const DANGER_SOFT := Color("fadcd6")
const WOOD := Color("9a6a3f")
const WOOD_DARK := Color("6f4a2a")
const OUTLINE := Color("2a2420")

const CAPACITY_NAMES := ["Duduk di kursi", "Berdiri berpegangan", "Berdiri mandiri"]
const CAPACITY_SHORT := ["Duduk", "Berpegangan", "Mandiri"]
const CAPACITY_DESC := [
	"Semua gerakan dilakukan sambil duduk di kursi kokoh.",
	"Berdiri di samping kursi kokoh, satu tangan berpegangan.",
	"Berdiri tanpa pegangan, kursi tetap di dekat Mbah.",
]
const TEXT_SCALES := [1.0, 1.14, 1.28]
const TEXT_SCALE_NAMES := ["Normal", "Besar", "Sangat besar"]

var font_body: FontFile = preload("res://assets/fonts/AtkinsonHyperlegible-Regular.ttf")
var font_bold: FontFile = preload("res://assets/fonts/AtkinsonHyperlegible-Bold.ttf")
var font_display: FontFile = preload("res://assets/fonts/LilitaOne-Regular.ttf")
var font_caps: FontVariation

var settings := {
	"text_scale": 0,
	"music": 0.45,
	"sfx": 0.8,
	"tts": true,
	"tts_rate": 0.9,
	"tempo": 0,
	"reduce_motion": false,
}
var profiles: Array = []
var current := -1
var group_log: Array = []
var theme: Theme

var _voice_id := ""
var _voice_checked := false


func _ready() -> void:
	font_caps = FontVariation.new()
	font_caps.base_font = font_bold
	font_caps.set_spacing(TextServer.SPACING_GLYPH, 2)
	load_data()
	theme = build_theme()
	get_tree().root.theme = theme


# ------------------------------------------------------------------ penyimpanan

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	var s = data.get("settings", {})
	if typeof(s) == TYPE_DICTIONARY:
		for k in s.keys():
			if settings.has(k):
				settings[k] = s[k]
	settings["text_scale"] = clampi(int(settings["text_scale"]), 0, 2)
	settings["tempo"] = clampi(int(settings["tempo"]), 0, 1)
	settings["reduce_motion"] = bool(settings["reduce_motion"])
	settings["tts"] = bool(settings["tts"])
	var p = data.get("profiles", [])
	if typeof(p) == TYPE_ARRAY:
		for item in p:
			if typeof(item) == TYPE_DICTIONARY:
				profiles.append(_normalize_profile(item))
	current = clampi(int(data.get("current", -1)), -1, profiles.size() - 1)
	var g = data.get("group_log", [])
	if typeof(g) == TYPE_ARRAY:
		group_log = g


func save_data() -> void:
	var data := {
		"version": SAVE_VERSION,
		"settings": settings,
		"profiles": profiles,
		"current": current,
		"group_log": group_log,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


func _normalize_profile(p: Dictionary) -> Dictionary:
	var d := new_profile_dict(str(p.get("name", "Mbah")), str(p.get("avatar", "putri")), int(p.get("capacity", 1)), int(p.get("outfit", 0)))
	for k in d.keys():
		if p.has(k) and typeof(p[k]) == typeof(d[k]):
			d[k] = p[k]
	d["capacity"] = clampi(int(p.get("capacity", 1)), 0, 2)
	d["outfit"] = clampi(int(p.get("outfit", 0)), 0, 2)
	d["unlocked"] = int(p.get("unlocked", 1))
	d["pre"] = int(p.get("pre", -1))
	d["post"] = int(p.get("post", -1))
	if not d["avatar"] in ["putri", "kakung"]:
		d["avatar"] = "putri"
	return d


func new_profile_dict(pname: String, avatar: String, capacity: int, outfit: int = 0) -> Dictionary:
	return {
		"id": str(Time.get_unix_time_from_system()) + str(randi() % 1000),
		"name": pname,
		"avatar": avatar,
		"outfit": outfit,
		"capacity": capacity,
		"unlocked": 1,
		"leaves": {},
		"log": [],
		"pre": -1,
		"post": -1,
		"pre_date": "",
		"post_date": "",
		"last_check": "",
		"created": today_str(),
	}


func add_profile(pname: String, avatar: String, capacity: int, outfit: int = 0) -> void:
	profiles.append(new_profile_dict(pname, avatar, capacity, outfit))
	current = profiles.size() - 1
	save_data()
	profile_changed.emit()


func select_profile(i: int) -> void:
	current = clampi(i, -1, profiles.size() - 1)
	save_data()
	profile_changed.emit()


func delete_profile(i: int) -> void:
	if i < 0 or i >= profiles.size():
		return
	profiles.remove_at(i)
	if current >= profiles.size():
		current = profiles.size() - 1
	save_data()
	profile_changed.emit()


func has_profile() -> bool:
	return current >= 0 and current < profiles.size()


func prof() -> Dictionary:
	if has_profile():
		return profiles[current]
	return new_profile_dict("Tamu", "putri", 1)


func leaves_of(station_id: String) -> int:
	return int(prof().get("leaves", {}).get(station_id, 0))


func total_leaves(p: Dictionary = {}) -> int:
	var pp: Dictionary = p if not p.is_empty() else prof()
	var n := 0
	for v in pp.get("leaves", {}).values():
		n += int(v)
	return n


func stations_done(p: Dictionary = {}) -> int:
	var pp: Dictionary = p if not p.is_empty() else prof()
	return pp.get("leaves", {}).size()


func award_station(station_index: int, station_id: String, leaves: int) -> bool:
	## true bila pos berikutnya baru terbuka.
	if not has_profile():
		return false
	var p: Dictionary = profiles[current]
	var old := int(p["leaves"].get(station_id, 0))
	p["leaves"][station_id] = maxi(old, leaves)
	var opened := false
	if station_index + 2 > int(p["unlocked"]):
		p["unlocked"] = mini(station_index + 2, 10)
		opened = true
	save_data()
	return opened


func log_activity(entry: Dictionary) -> void:
	if not has_profile():
		return
	entry["date"] = today_str()
	entry["time"] = Time.get_time_string_from_system().substr(0, 5)
	var log_arr: Array = profiles[current]["log"]
	log_arr.append(entry)
	if log_arr.size() > 300:
		log_arr.remove_at(0)
	save_data()


func log_group(entry: Dictionary) -> void:
	entry["date"] = today_str()
	entry["time"] = Time.get_time_string_from_system().substr(0, 5)
	group_log.append(entry)
	if group_log.size() > 300:
		group_log.remove_at(0)
	save_data()


func reset_all() -> void:
	profiles.clear()
	group_log.clear()
	current = -1
	save_data()
	profile_changed.emit()


# ------------------------------------------------------------------ waktu

func today_str() -> String:
	return Time.get_date_string_from_system()


func date_label(iso: String) -> String:
	var months := ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"]
	var parts := iso.split("-")
	if parts.size() != 3:
		return iso
	return "%d %s %s" % [int(parts[2]), months[clampi(int(parts[1]) - 1, 0, 11)], parts[0]]


func days_active(p: Dictionary, days: int) -> Array:
	var active := {}
	for e in p.get("log", []):
		active[str(e.get("date", ""))] = true
	var out: Array = []
	var now := int(Time.get_unix_time_from_system())
	for i in range(days - 1, -1, -1):
		var d := Time.get_date_string_from_unix_time(now - i * 86400)
		out.append({"date": d, "active": active.has(d)})
	return out


func streak(p: Dictionary) -> int:
	var arr := days_active(p, 60)
	var n := 0
	for i in range(arr.size() - 1, -1, -1):
		if arr[i]["active"]:
			n += 1
		elif i == arr.size() - 1:
			continue
		else:
			break
	return n


# ------------------------------------------------------------------ tema

func fs(base: float) -> int:
	return int(round(base * TEXT_SCALES[int(settings["text_scale"])]))


func fs_cap(base: float, max_scale: float = 1.1) -> int:
	return int(round(base * minf(TEXT_SCALES[int(settings["text_scale"])], max_scale)))


func motion() -> bool:
	return not bool(settings["reduce_motion"])


func beat_seconds() -> float:
	return 1.6 if int(settings["tempo"]) == 0 else 1.15


func set_setting(key: String, value) -> void:
	settings[key] = value
	save_data()
	if key == "text_scale":
		theme = build_theme()
		get_tree().root.theme = theme
	settings_changed.emit()


func sb(bg: Color, radius: int = 24, margin_h: int = 24, margin_v: int = 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.corner_detail = 12
	s.anti_aliasing = true
	s.content_margin_left = margin_h
	s.content_margin_right = margin_h
	s.content_margin_top = margin_v
	s.content_margin_bottom = margin_v
	return s


func soft_shadow(s: StyleBoxFlat, alpha: float = 0.16, size: int = 16, oy: int = 8) -> StyleBoxFlat:
	s.shadow_color = Color(TEAL.r, TEAL.g, TEAL.b, alpha)
	s.shadow_size = size
	s.shadow_offset = Vector2(0, oy)
	return s


func _tactile(t: Theme, type_name: String, bg: Color, bevel: Color, fg: Color, radius: int = 24) -> void:
	## Tombol "taktil" bergaya permainan: punggung tebal di bawah, turun saat ditekan.
	var n := sb(bg, radius, 26, 12)
	n.border_width_bottom = 7
	n.border_color = bevel
	n.content_margin_bottom = 12
	soft_shadow(n, 0.18, 10, 5)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = bg.lightened(0.07)
	var p := n.duplicate() as StyleBoxFlat
	p.bg_color = bg.darkened(0.05)
	p.border_width_bottom = 2
	p.content_margin_top = 17
	p.content_margin_bottom = 12
	p.shadow_size = 4
	p.shadow_offset = Vector2(0, 2)
	var d := n.duplicate() as StyleBoxFlat
	d.bg_color = Color(bg, 0.45)
	d.border_color = Color(bevel, 0.3)
	d.shadow_size = 0
	var f := StyleBoxFlat.new()
	f.draw_center = false
	f.set_corner_radius_all(radius + 6)
	f.set_border_width_all(4)
	f.border_color = INK
	f.set_expand_margin_all(6)
	f.anti_aliasing = true
	t.set_stylebox("normal", type_name, n)
	t.set_stylebox("hover", type_name, h)
	t.set_stylebox("pressed", type_name, p)
	t.set_stylebox("hover_pressed", type_name, p)
	t.set_stylebox("disabled", type_name, d)
	t.set_stylebox("focus", type_name, f)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, type_name, fg)
	t.set_color("font_disabled_color", type_name, Color(fg, 0.45))
	t.set_font("font", type_name, font_bold)
	t.set_font_size("font_size", type_name, fs(26))


func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font_body
	t.default_font_size = fs(26)

	t.set_color("font_color", "Label", INK)
	t.set_constant("line_spacing", "Label", 5)

	_tactile(t, "Button", PAPER, Color("c7dbd5"), TEAL)
	for v in [["PrimaryButton", TERRA, TERRA_DARK, Color.WHITE], ["TealButton", TEAL_MID, TEAL, Color.WHITE],
			["SunButton", SAFFRON, SAFFRON_DARK, INK], ["DangerButton", DANGER_SOFT, Color("e2a194"), DANGER],
			["LeafButton", LEAF, LEAF_DARK, Color.WHITE], ["ChoiceButton", PAPER, Color("cfe0db"), INK]]:
		t.set_type_variation(v[0], "Button")
		_tactile(t, v[0], v[1], v[2], v[3])
	# keadaan terpilih untuk tombol pilihan (toggle)
	var sel := sb(SAFFRON_SOFT, 24, 26, 12)
	sel.border_width_bottom = 7
	sel.border_width_top = 3
	sel.border_width_left = 3
	sel.border_width_right = 3
	sel.border_color = SAFFRON_DARK
	soft_shadow(sel, 0.18, 10, 5)
	t.set_stylebox("pressed", "ChoiceButton", sel)
	t.set_stylebox("hover_pressed", "ChoiceButton", sel)
	# tombol tanpa latar
	t.set_type_variation("GhostButton", "Button")
	var g := sb(Color(1, 1, 1, 0), 20, 16, 10)
	var gh := sb(Color(TEAL, 0.08), 20, 16, 10)
	t.set_stylebox("normal", "GhostButton", g)
	t.set_stylebox("hover", "GhostButton", gh)
	t.set_stylebox("pressed", "GhostButton", gh)
	t.set_stylebox("hover_pressed", "GhostButton", gh)
	t.set_color("font_color", "GhostButton", TEAL)
	t.set_color("font_hover_color", "GhostButton", TEAL)
	t.set_color("font_pressed_color", "GhostButton", TEAL)

	# label
	var lv := {
		"Display": [font_display, 90, TEAL],
		"H1": [font_display, 44, TEAL],
		"H2": [font_bold, 31, INK],
		"H3": [font_bold, 26, INK],
		"Body": [font_body, 26, INK],
		"Lead": [font_body, 29, INK],
		"Small": [font_body, 22, INK_SOFT],
		"Caption": [font_caps, 19, TERRA],
		"Big": [font_display, 42, TERRA],
		"Counter": [font_display, 120, TERRA],
		"OnDark": [font_bold, 27, Color.WHITE],
		"OnDarkSmall": [font_body, 22, Color(1, 1, 1, 0.85)],
	}
	for k in lv.keys():
		t.set_type_variation(k, "Label")
		t.set_font("font", k, lv[k][0])
		t.set_font_size("font_size", k, fs(lv[k][1]))
		t.set_color("font_color", k, lv[k][2])
	t.set_constant("line_spacing", "Body", 7)
	t.set_constant("line_spacing", "Lead", 8)
	t.set_constant("line_spacing", "Small", 5)

	# panel
	var panels := {
		"Card": soft_shadow(sb(PAPER, 28, 24, 20), 0.15, 18, 8),
		"Cream": soft_shadow(sb(CREAM, 28, 24, 20), 0.15, 18, 8),
		"Glass": soft_shadow(sb(Color(PAPER, 0.92), 28, 22, 16), 0.12, 14, 6),
		"Pill": soft_shadow(sb(Color(PAPER, 0.96), 40, 18, 8), 0.14, 10, 4),
		"Dark": soft_shadow(sb(Color(TEAL, 0.96), 26, 24, 14), 0.25, 14, 6),
		"Chip": sb(TEAL_SOFT, 30, 14, 5),
		"ChipSun": sb(SAFFRON_SOFT, 30, 14, 5),
		"ChipLeaf": sb(LEAF_SOFT, 30, 14, 5),
		"ChipTerra": sb(TERRA_SOFT, 30, 14, 5),
		"Inset": sb(Color(TEAL, 0.06), 22, 18, 14),
	}
	for k in ["Note", "Leaf", "Danger", "Info"]:
		var cc: Color = {"Note": SAFFRON_SOFT, "Leaf": LEAF_SOFT, "Danger": DANGER_SOFT, "Info": TEAL_SOFT}[k]
		var ac: Color = {"Note": SAFFRON_DARK, "Leaf": LEAF, "Danger": DANGER, "Info": TEAL_MID}[k]
		var s := sb(cc, 20, 20, 12)
		s.border_width_left = 9
		s.border_color = ac
		panels[k] = s
	var wood := sb(WOOD, 14, 18, 8)
	wood.border_width_bottom = 6
	wood.border_color = WOOD_DARK
	soft_shadow(wood, 0.25, 6, 4)
	panels["Wood"] = wood
	t.set_stylebox("panel", "PanelContainer", panels["Card"])
	for k in panels.keys():
		t.set_type_variation(k, "PanelContainer")
		t.set_stylebox("panel", k, panels[k])

	# kartu yang dapat diketuk (TapCard)
	var tile := sb(PAPER, 26, 22, 16)
	tile.border_width_bottom = 7
	tile.border_color = Color("d5e3df")
	soft_shadow(tile, 0.14, 12, 6)
	var tile_p := tile.duplicate() as StyleBoxFlat
	tile_p.bg_color = Color("f3f7f5")
	tile_p.border_width_bottom = 2
	tile_p.content_margin_top = 21
	tile_p.content_margin_bottom = 16
	tile_p.shadow_size = 4
	var tile_s := tile.duplicate() as StyleBoxFlat
	tile_s.bg_color = SAFFRON_SOFT
	tile_s.border_color = SAFFRON_DARK
	tile_s.border_width_top = 4
	tile_s.border_width_left = 4
	tile_s.border_width_right = 4
	var tile_ok := tile_s.duplicate() as StyleBoxFlat
	tile_ok.bg_color = LEAF_SOFT
	tile_ok.border_color = LEAF
	var tile_no := tile_s.duplicate() as StyleBoxFlat
	tile_no.bg_color = DANGER_SOFT
	tile_no.border_color = DANGER
	var tile_d := tile.duplicate() as StyleBoxFlat
	tile_d.bg_color = Color(PAPER, 0.55)
	tile_d.border_color = Color("d5e3df", 0.5)
	tile_d.shadow_size = 0
	for pair in [["Tile", tile], ["TilePressed", tile_p], ["TileSelected", tile_s], ["TileCorrect", tile_ok], ["TileWrong", tile_no], ["TileDisabled", tile_d]]:
		t.set_type_variation(pair[0], "PanelContainer")
		t.set_stylebox("panel", pair[0], pair[1])

	# input teks
	var le := sb(PAPER, 18, 20, 12)
	le.set_border_width_all(3)
	le.border_color = Color("9fc3bb")
	var le_f := le.duplicate() as StyleBoxFlat
	le_f.border_color = TERRA
	le_f.set_border_width_all(4)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le_f)
	t.set_font_size("font_size", "LineEdit", fs(32))
	t.set_font("font", "LineEdit", font_bold)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", Color(INK_SOFT, 0.6))
	t.set_color("caret_color", "LineEdit", TERRA)
	t.set_constant("caret_width", "LineEdit", 3)

	# scrollbar tebal
	var grab := sb(Color(TEAL_MID, 0.55), 10, 0, 0)
	var grab_h := sb(Color(TEAL_MID, 0.8), 10, 0, 0)
	var track := sb(Color(TEAL, 0.07), 10, 6, 6)
	for sbn in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("grabber", sbn, grab)
		t.set_stylebox("grabber_highlight", sbn, grab_h)
		t.set_stylebox("grabber_pressed", sbn, grab_h)
		t.set_stylebox("scroll", sbn, track)
		t.set_stylebox("scroll_focus", sbn, track)

	# slider
	var sl := sb(TEAL_SOFT, 12, 0, 9)
	var area := sb(SAFFRON, 12, 0, 9)
	t.set_stylebox("slider", "HSlider", sl)
	t.set_stylebox("grabber_area", "HSlider", area)
	t.set_stylebox("grabber_area_highlight", "HSlider", area)
	t.set_icon("grabber", "HSlider", _knob_tex(48, TERRA))
	t.set_icon("grabber_highlight", "HSlider", _knob_tex(52, TERRA_DARK))
	t.set_constant("center_grabber", "HSlider", 1)
	var slf := StyleBoxFlat.new()
	slf.draw_center = false
	slf.set_border_width_all(4)
	slf.border_color = INK
	slf.set_corner_radius_all(16)
	slf.set_expand_margin_all(8)
	t.set_stylebox("focus", "HSlider", slf)

	# progress bar
	var pb_bg := sb(Color(TEAL, 0.1), 12, 0, 0)
	var pb_fill := sb(LEAF, 12, 0, 0)
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill", "ProgressBar", pb_fill)

	t.set_constant("separation", "HBoxContainer", 16)
	t.set_constant("separation", "VBoxContainer", 14)
	t.set_constant("h_separation", "GridContainer", 16)
	t.set_constant("v_separation", "GridContainer", 16)

	t.set_stylebox("panel", "TooltipPanel", sb(TEAL, 12, 12, 8))
	t.set_color("font_color", "TooltipLabel", Color.WHITE)
	t.set_font_size("font_size", "TooltipLabel", fs(20))
	return t


func _knob_tex(d: int, c: Color) -> ImageTexture:
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var r := d / 2.0
	for y in d:
		for x in d:
			var dist := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			var a := clampf(r - dist, 0.0, 1.0)
			var col := c
			if dist > r - 6:
				col = Color.WHITE
			elif dist < r * 0.32:
				col = c.lightened(0.25)
			col.a = a
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ pakaian tokoh

func outfit_colors(avatar: String, outfit: int) -> Dictionary:
	match avatar:
		"kakung":
			var tops := [Color("b4532a"), Color("1e6b66"), Color("2e4a7a")]
			var motifs := [Color("f2b134"), Color("fde7b0"), Color("f2b134")]
			return {"top": tops[clampi(outfit, 0, 2)], "motif": motifs[clampi(outfit, 0, 2)], "pants": Color("3d4a57"), "scarf": Color("232323")}
		"kader":
			return {"top": Color("e0952a"), "motif": Color("fff1c9"), "pants": Color("35505c"), "scarf": Color("1e6b66")}
		_:
			var tops2 := [Color("1e6b66"), Color("c8553d"), Color("6b4c9a")]
			var scarfs := [Color("f2b134"), Color("f6e3c3"), Color("e8a0b4")]
			var motifs2 := [Color("fde7b0"), Color("fde7b0"), Color("f7d9ef")]
			return {"top": tops2[clampi(outfit, 0, 2)], "motif": motifs2[clampi(outfit, 0, 2)], "pants": Color("5b3f35"), "scarf": scarfs[clampi(outfit, 0, 2)]}


# ------------------------------------------------------------------ suara pemandu

func _pick_voice() -> void:
	_voice_checked = true
	_voice_id = ""
	if DisplayServer.get_name() == "headless":
		return
	if OS.get_name() == "Linux" and not FileAccess.file_exists("/usr/lib64/libspeechd.so.2") and not FileAccess.file_exists("/usr/lib/x86_64-linux-gnu/libspeechd.so.2"):
		return
	var voices: Array = DisplayServer.tts_get_voices()
	for v in voices:
		var lang := str(v.get("language", "")).to_lower()
		if lang.begins_with("id") or lang.begins_with("in_") or lang.begins_with("in-") or lang == "in":
			_voice_id = str(v.get("id", ""))
			return


func tts_available() -> bool:
	if not _voice_checked:
		_pick_voice()
	return _voice_id != ""


func speak(text: String, force := false) -> bool:
	if not force and not bool(settings["tts"]):
		return false
	if not tts_available():
		return false
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, _voice_id, 100, 1.0, float(settings["tts_rate"]))
	return true


func stop_speech() -> void:
	if _voice_checked and _voice_id != "":
		DisplayServer.tts_stop()
