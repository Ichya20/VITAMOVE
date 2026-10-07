extends Node
## Autoload "Game": status global, penyimpanan, tema UI, dan suara pemandu (TTS).

signal settings_changed
signal profile_changed

const SAVE_PATH := "user://vitamove_save.json"
const SAVE_VERSION := 1

# Palet "papercut desa": teal pegunungan, terakota genteng, kunyit, krem kertas.
const TEAL := Color("0f4c4a")
const TEAL_MID := Color("1f6f6a")
const TEAL_SOFT := Color("cfe6df")
const TERRA := Color("c8553d")
const TERRA_DARK := Color("9c3d2a")
const SAFFRON := Color("f2b134")
const SAFFRON_SOFT := Color("fde7b0")
const LEAF := Color("4f8a3c")
const LEAF_SOFT := Color("dcebc9")
const CREAM := Color("fff6e5")
const PAPER := Color("fffdf8")
const INK := Color("23302e")
const INK_SOFT := Color("4b5a57")
const SKY := Color("bfe3ea")
const DANGER := Color("b3261e")
const DANGER_SOFT := Color("fadcd6")

const CAPACITY_NAMES := ["Duduk di kursi", "Berdiri berpegangan", "Berdiri mandiri"]
const CAPACITY_DESC := [
	"Semua gerakan dilakukan sambil duduk di kursi kokoh.",
	"Berdiri di samping kursi kokoh, satu tangan berpegangan.",
	"Berdiri tanpa pegangan, kursi tetap di dekat Mbah.",
]
const TEXT_SCALES := [1.0, 1.15, 1.32]
const TEXT_SCALE_NAMES := ["Normal", "Besar", "Sangat besar"]

var font_body: FontFile = preload("res://assets/fonts/AtkinsonHyperlegible-Regular.ttf")
var font_bold: FontFile = preload("res://assets/fonts/AtkinsonHyperlegible-Bold.ttf")
var font_display: FontFile = preload("res://assets/fonts/LilitaOne-Regular.ttf")

var settings := {
	"text_scale": 1,
	"music": 0.45,
	"sfx": 0.8,
	"tts": true,
	"tts_rate": 0.9,
	"tempo": 0,
}
var profiles: Array = []
var current := -1
var group_log: Array = []
var theme: Theme

var _voice_id := ""
var _voice_checked := false


func _ready() -> void:
	load_data()
	theme = build_theme()
	get_tree().root.theme = theme


# ---------------------------------------------------------------- penyimpanan

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
	var d := new_profile_dict(str(p.get("name", "Mbah")), str(p.get("avatar", "putri")), int(p.get("capacity", 1)))
	for k in d.keys():
		if p.has(k) and typeof(p[k]) == typeof(d[k]):
			d[k] = p[k]
	# JSON menyimpan angka sebagai float; rapikan kembali.
	d["capacity"] = clampi(int(p.get("capacity", 1)), 0, 2)
	d["unlocked"] = int(p.get("unlocked", 1))
	d["pre"] = int(p.get("pre", -1))
	d["post"] = int(p.get("post", -1))
	return d


func new_profile_dict(pname: String, avatar: String, capacity: int) -> Dictionary:
	return {
		"id": str(Time.get_unix_time_from_system()) + str(randi() % 1000),
		"name": pname,
		"avatar": avatar,
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


func add_profile(pname: String, avatar: String, capacity: int) -> void:
	profiles.append(new_profile_dict(pname, avatar, capacity))
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


func award_station(station_index: int, station_id: String, leaves: int) -> bool:
	## Mengembalikan true bila pos berikutnya baru terbuka.
	if not has_profile():
		return false
	var p: Dictionary = profiles[current]
	var old := int(p["leaves"].get(station_id, 0))
	p["leaves"][station_id] = maxi(old, leaves)
	var opened := false
	if station_index + 2 > int(p["unlocked"]):
		p["unlocked"] = station_index + 2
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


# ---------------------------------------------------------------- waktu

func today_str() -> String:
	return Time.get_date_string_from_system()


func date_label(iso: String) -> String:
	var months := ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"]
	var parts := iso.split("-")
	if parts.size() != 3:
		return iso
	return "%d %s %s" % [int(parts[2]), months[clampi(int(parts[1]) - 1, 0, 11)], parts[0]]


func days_active(p: Dictionary, days: int) -> Array:
	## Daftar boolean aktif/tidak untuk 'days' hari terakhir (lama -> baru).
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
			continue  # hari ini belum latihan tidak memutus rangkaian
		else:
			break
	return n


# ---------------------------------------------------------------- tema

func fs(base: float) -> int:
	return int(round(base * TEXT_SCALES[int(settings["text_scale"])]))


func beat_seconds() -> float:
	return 1.6 if int(settings["tempo"]) == 0 else 1.15


func set_setting(key: String, value) -> void:
	settings[key] = value
	save_data()
	if key == "text_scale":
		theme = build_theme()
		get_tree().root.theme = theme
	settings_changed.emit()


func _sb(bg: Color, radius: int = 22, border: Color = Color.TRANSPARENT, bw: int = 0, shadow: Color = Color.TRANSPARENT, sh_off: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.corner_detail = 10
	if bw > 0:
		s.border_color = border
		s.set_border_width_all(bw)
	if sh_off > 0:
		s.shadow_color = shadow
		s.shadow_size = 1
		s.shadow_offset = Vector2(0, sh_off)
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	s.anti_aliasing = true
	return s


func _button_set(t: Theme, type_name: String, bg: Color, fg: Color, border: Color, pressed_bg: Color) -> void:
	var shadow := Color(TEAL.r, TEAL.g, TEAL.b, 0.45)
	var n := _sb(bg, 24, border, 3, shadow, 6)
	var h := _sb(bg.lightened(0.08), 24, border, 3, shadow, 6)
	var p := _sb(pressed_bg, 24, border, 3, shadow, 2)
	p.content_margin_top = 16
	p.content_margin_bottom = 8
	var d := _sb(Color(bg, 0.45), 24, Color(border, 0.4), 3)
	var f := StyleBoxFlat.new()
	f.draw_center = false
	f.set_corner_radius_all(28)
	f.set_border_width_all(5)
	f.border_color = SAFFRON
	f.set_expand_margin_all(5)
	f.anti_aliasing = true
	t.set_stylebox("normal", type_name, n)
	t.set_stylebox("hover", type_name, h)
	t.set_stylebox("pressed", type_name, p)
	t.set_stylebox("hover_pressed", type_name, p)
	t.set_stylebox("disabled", type_name, d)
	t.set_stylebox("focus", type_name, f)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, type_name, fg)
	t.set_color("font_disabled_color", type_name, Color(fg, 0.5))


func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font_body
	t.default_font_size = fs(26)

	t.set_color("font_color", "Label", INK)
	t.set_constant("line_spacing", "Label", 4)

	_button_set(t, "Button", PAPER, TEAL, TEAL, TEAL_SOFT)
	t.set_font("font", "Button", font_bold)
	t.set_font_size("font_size", "Button", fs(26))

	t.set_type_variation("PrimaryButton", "Button")
	_button_set(t, "PrimaryButton", TERRA, Color.WHITE, TERRA_DARK, TERRA_DARK)
	t.set_type_variation("TealButton", "Button")
	_button_set(t, "TealButton", TEAL_MID, Color.WHITE, TEAL, TEAL)
	t.set_type_variation("SunButton", "Button")
	_button_set(t, "SunButton", SAFFRON, INK, Color("c98a12"), Color("e0a020"))
	t.set_type_variation("DangerButton", "Button")
	_button_set(t, "DangerButton", DANGER_SOFT, DANGER, DANGER, Color("f3b9ae"))
	t.set_type_variation("ChoiceButton", "Button")
	_button_set(t, "ChoiceButton", PAPER, INK, TEAL_MID, SAFFRON_SOFT)
	# Keadaan terpilih untuk tombol toggle
	var sel := _sb(SAFFRON_SOFT, 24, TERRA, 5, Color(TEAL, 0.45), 2)
	t.set_stylebox("pressed", "ChoiceButton", sel)
	t.set_stylebox("hover_pressed", "ChoiceButton", sel)

	# Label variasi
	var lv := {
		"Title": [font_display, 76, TEAL],
		"H1": [font_display, 46, TEAL],
		"H2": [font_bold, 33, INK],
		"H3": [font_bold, 28, INK],
		"Body": [font_body, 26, INK],
		"Small": [font_body, 22, INK_SOFT],
		"Big": [font_display, 40, TERRA],
		"Counter": [font_display, 120, TERRA],
		"OnDark": [font_bold, 27, Color.WHITE],
	}
	for k in lv.keys():
		t.set_type_variation(k, "Label")
		t.set_font("font", k, lv[k][0])
		t.set_font_size("font_size", k, fs(lv[k][1]))
		t.set_color("font_color", k, lv[k][2])
	t.set_color("font_outline_color", "Counter", Color.WHITE)
	t.set_constant("outline_size", "Counter", 16)
	t.set_color("font_outline_color", "Title", CREAM)
	t.set_constant("outline_size", "Title", 14)

	# Panel
	t.set_stylebox("panel", "PanelContainer", _sb(PAPER, 28, Color(TEAL, 0.25), 3, Color(TEAL, 0.25), 8))
	var panels := {
		"Card": _sb(PAPER, 28, Color(TEAL, 0.3), 3, Color(TEAL, 0.3), 8),
		"Cream": _sb(CREAM, 28, Color(TERRA, 0.35), 3, Color(TEAL, 0.25), 8),
		"Note": _sb(SAFFRON_SOFT, 22, Color("d99a1e"), 3),
		"Danger": _sb(DANGER_SOFT, 22, DANGER, 3),
		"Leaf": _sb(LEAF_SOFT, 22, LEAF, 3),
		"Dark": _sb(Color(TEAL, 0.93), 28, Color(SAFFRON, 0.8), 3, Color(0, 0, 0, 0.3), 8),
		"Bar": _sb(Color(TEAL, 0.92), 0, Color.TRANSPARENT, 0),
		"Pill": _sb(Color(PAPER, 0.92), 40, Color(TEAL, 0.35), 3),
	}
	for k in panels.keys():
		t.set_type_variation(k, "PanelContainer")
		t.set_stylebox("panel", k, panels[k])
	var bar: StyleBoxFlat = panels["Bar"]
	bar.content_margin_top = 8
	bar.content_margin_bottom = 8

	# Input teks
	var le := _sb(PAPER, 18, TEAL_MID, 3)
	var le_f := _sb(PAPER, 18, TERRA, 4)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le_f)
	t.set_font_size("font_size", "LineEdit", fs(30))
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", Color(INK_SOFT, 0.7))
	t.set_color("caret_color", "LineEdit", TERRA)
	t.set_constant("caret_width", "LineEdit", 3)

	# Scrollbar tebal agar mudah disentuh
	var grab := _sb(Color(TEAL_MID, 0.75), 10)
	grab.set_content_margin_all(0)
	var track := _sb(Color(TEAL, 0.12), 10)
	track.set_content_margin_all(7)
	for sb in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("grabber", sb, grab)
		t.set_stylebox("grabber_highlight", sb, grab)
		t.set_stylebox("grabber_pressed", sb, grab)
		t.set_stylebox("scroll", sb, track)

	# Slider
	var sl := _sb(TEAL_SOFT, 10, TEAL_MID, 2)
	sl.content_margin_top = 8
	sl.content_margin_bottom = 8
	t.set_stylebox("slider", "HSlider", sl)
	var area := _sb(SAFFRON, 10)
	area.content_margin_top = 8
	area.content_margin_bottom = 8
	t.set_stylebox("grabber_area", "HSlider", area)
	t.set_stylebox("grabber_area_highlight", "HSlider", area)
	t.set_icon("grabber", "HSlider", _circle_tex(44, TERRA))
	t.set_icon("grabber_highlight", "HSlider", _circle_tex(48, TERRA_DARK))
	t.set_constant("center_grabber", "HSlider", 1)

	t.set_constant("separation", "HBoxContainer", 16)
	t.set_constant("separation", "VBoxContainer", 14)
	return t


func _circle_tex(d: int, c: Color) -> ImageTexture:
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var r := d / 2.0
	for y in d:
		for x in d:
			var dist := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			var a := clampf(r - dist, 0.0, 1.0)
			var col := c if dist < r - 5 else Color.WHITE
			col.a = a
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------- suara pemandu

func _pick_voice() -> void:
	_voice_checked = true
	_voice_id = ""
	if DisplayServer.get_name() == "headless":
		return
	var voices: Array = []
	voices = DisplayServer.tts_get_voices()
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
