extends Screen
## Info aplikasi: tentang VITAMOVE, tim pengusul, mitra & program, dan cara memakai.

const KETUA := {"name": "Aminatus Sa'adah, S.Si., M.Si.", "role": "Ketua Tim · Koordinator", "detail": "Asisten Ahli · S1 Teknik Informatika, Telkom University Kampus Purwokerto"}
const ANGGOTA := [
	{"name": "Evia Zunita Dwi Pratiwi, S.T., M.Sc.", "role": "Anggota Tim · Dosen"},
	{"name": "Yohani Setiya Rafika Nur, S.Kom., M.Kom", "role": "Anggota Tim · Dosen"},
]
const MAHASISWA := [
	{"name": "Ichya Ulumiddiin", "nim": "103112400076"},
	{"name": "Muhammad Zakiy Mubarok", "nim": "103022400120"},
	{"name": "Muhammad Nafal Fiqrian", "nim": "101132400003"},
	{"name": "Elisa Kusumaningsih", "nim": "101132400034"},
]

var _tabs: Array = []
var _page: VBoxContainer
var _tab := 0
var _scroll: ScrollContainer


func build() -> void:
	scene_bg("balai", "pagi", 0.5)
	make_content(26)
	var v := UI.vbox(14)
	content.add_child(v)
	v.add_child(header("Info Aplikasi", "VITAMOVE · versi 1.1"))
	var row := UI.hbox(18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(row)
	var side := UI.vbox(12)
	side.custom_minimum_size = Vector2(310, 0)
	row.add_child(side)
	var tabs := [["Tentang VITAMOVE", "leaf", Game.LEAF], ["Tim Pengusul", "people", Game.TERRA], ["Mitra & Program", "home", Game.TEAL_MID], ["Cara Memakai", "book", Game.SAFFRON_DARK]]
	for i in tabs.size():
		var t := TapCard.new()
		t.set("accessibility_name", tabs[i][0])
		var h := UI.hbox(12)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.add_child(h)
		h.add_child(UI.badge(tabs[i][1], tabs[i][2], 44))
		var l := UI.label(tabs[i][0], "H3", true)
		l.add_theme_font_size_override("font_size", Game.fs_cap(22))
		h.add_child(l)
		var ii := i
		t.pressed.connect(func() -> void:
			Sfx.play("page")
			_show(ii))
		side.add_child(t)
		_tabs.append(t)
	side.add_child(UI.spacer(false, true))
	var logo := UI.hbox(6)
	logo.add_child(Icon.new("leaf", Game.LEAF, 30))
	logo.add_child(UI.label("Telkom University · Kampus Purwokerto", "Small", true))
	side.add_child(logo)
	var card := UI.panel("Card")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(card)
	_scroll = UI.scroll_v()
	card.add_child(_scroll)
	_page = UI.vbox(14)
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(UI.xmargin(4, 4, 14, 8))
	_scroll.get_child(0).add_child(_page)
	reveal([side, card])
	_show(0)


func default_focus() -> Control:
	return _tabs[_tab]


func _show(i: int) -> void:
	_tab = i
	for k in _tabs.size():
		(_tabs[k] as TapCard).selected = k == i
	for c in _page.get_children():
		c.queue_free()
	_scroll.scroll_vertical = 0
	match i:
		0: _about()
		1: _team()
		2: _partner()
		3: _howto()
	UI.pop_in(_page.get_children(), 0.0, 0.04)


func _p(text: String, variation: String = "Body") -> Label:
	var l := UI.label(text, variation, true)
	_page.add_child(l)
	return l


func _about() -> void:
	var h := UI.hbox(18)
	var j := Mascot.new()
	j.custom_minimum_size = Vector2(130, 130)
	h.add_child(j)
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(UI.label("Multimedia interaktif", "Caption"))
	v.add_child(UI.label("VITAMOVE", "H1"))
	v.add_child(UI.label("Edukasi Aktivitas Fisik untuk Peningkatan Kemandirian Lansia", "H3", true))
	h.add_child(v)
	_page.add_child(h)
	_p("VITAMOVE membantu lansia melihat, memahami, mempraktikkan, mengevaluasi, dan mengulang aktivitas fisik secara aman. Materi disajikan dengan teks ringkas, ilustrasi, suara, demonstrasi gerakan yang dapat diulang, dan latihan interaktif.")
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	for s in ["Manfaat bergerak", "Persiapan", "Pemanasan", "Keseimbangan", "Kelenturan", "Kekuatan ringan", "Aktivitas sehari-hari", "Pendinginan", "Keselamatan"]:
		flow.add_child(UI.chip(s, "ChipLeaf", "leaf", Game.LEAF_DARK))
	_page.add_child(flow)
	var np := UI.panel("Note")
	np.add_child(UI.label("Penting: VITAMOVE adalah sarana edukasi, bukan pengganti pemeriksaan atau rekomendasi medis. Penyesuaian latihan tetap mengikuti arahan tenaga kesehatan.", "Body", true))
	_page.add_child(np)
	_p("Kredit: fon Atkinson Hyperlegible (Braille Institute) dan Lilita One, berlisensi SIL Open Font License. Ilustrasi, musik gamelan, dan efek suara dibuat khusus untuk aplikasi ini.", "Small")


func _person(pname: String, role: String, detail: String, col: Color, big: bool = false) -> Control:
	var p := UI.panel("Cream" if big else "Inset")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := UI.hbox(14)
	p.add_child(h)
	var badge := Control.new()
	var sz := 76.0 if big else 56.0
	badge.custom_minimum_size = Vector2(sz, sz)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var initials := ""
	for w in pname.replace(",", " ").split(" ", false):
		if initials.length() < 2 and w.length() > 0 and w[0] == w[0].to_upper() and not w.contains("."):
			initials += w[0]
	badge.draw.connect(func() -> void:
		var c := badge.size / 2.0
		badge.draw_circle(c + Vector2(0, 3), sz / 2.0, col.darkened(0.3), true, -1.0, true)
		badge.draw_circle(c, sz / 2.0, col, true, -1.0, true)
		var f := Game.font_display
		var fsz := int(sz * 0.42)
		var tw := f.get_string_size(initials, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
		badge.draw_string(f, Vector2(c.x - tw / 2.0, c.y + fsz * 0.36), initials, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color.WHITE))
	h.add_child(badge)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var rl := UI.label(role, "Caption")
	rl.add_theme_color_override("font_color", col.darkened(0.15))
	v.add_child(rl)
	v.add_child(UI.label(pname, "H2" if big else "H3", true))
	if detail != "":
		v.add_child(UI.label(detail, "Small", true))
	return p


func _team() -> void:
	_page.add_child(UI.label("Ketua Tim", "H2"))
	_page.add_child(_person(KETUA["name"], KETUA["role"], KETUA["detail"], Game.TERRA, true))
	_page.add_child(UI.label("Anggota Tim", "H2"))
	for a in ANGGOTA:
		_page.add_child(_person(a["name"], a["role"], "Telkom University Kampus Purwokerto", Game.TEAL_MID))
	_page.add_child(UI.label("Tim Mahasiswa", "H2"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for m in MAHASISWA:
		grid.add_child(_person(m["name"], "Mahasiswa", "NIM %s" % m["nim"], Game.SAFFRON_DARK))
	_page.add_child(grid)
	_p("Direktorat Kampus Purwokerto · Kelompok Keahlian Data Science and Optimization", "Small")


func _partner() -> void:
	_page.add_child(UI.label("Mitra sasaran", "Caption"))
	_page.add_child(UI.label("Posyandu Lansia Wreda Asih 2", "H1", true))
	_p("Desa Muntang, Kecamatan Kemangkon, Kabupaten Purbalingga, Jawa Tengah.")
	var row := UI.hbox(12)
	for s in [["30", "lansia", Game.TERRA, "user"], ["10", "kader", Game.TEAL_MID, "people"], ["2", "tenaga kesehatan", Game.LEAF, "shield"]]:
		var p := UI.panel("Inset")
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h := UI.hbox(10)
		p.add_child(h)
		h.add_child(UI.badge(s[3], s[2], 48))
		var v := UI.vbox(0)
		var b := UI.label(s[0], "Big")
		b.add_theme_color_override("font_color", s[2])
		v.add_child(b)
		v.add_child(UI.label(s[1], "Small"))
		h.add_child(v)
		row.add_child(p)
	_page.add_child(row)
	_page.add_child(UI.label("Program", "H2"))
	_p("Pengabdian kepada Masyarakat Telkom University · Tahun 2026, Periode 2 · Skema Teknologi Tepat Guna (TTG) · Bidang fokus Kesehatan · SDG 3 dan SDG 4.")
	var steps := ["Sosialisasi & pemetaan", "Pelatihan", "Penerapan teknologi", "Pendampingan & evaluasi", "Keberlanjutan"]
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	for i in steps.size():
		flow.add_child(UI.chip("%d. %s" % [i + 1, steps[i]], "ChipSun", "", Game.INK))
	_page.add_child(flow)
	_page.add_child(UI.label("Peran", "H2"))
	for r in [["user", "Lansia", "Pengguna utama yang belajar dan berlatih.", Game.TERRA], ["people", "Kader", "Operator dan pemandu sesi lewat menu Sesi Bersama.", Game.TEAL_MID], ["shield", "Tenaga kesehatan", "Pengarah materi dan keselamatan latihan.", Game.LEAF]]:
		var h2 := UI.hbox(12)
		h2.add_child(UI.badge(r[0], r[3], 44))
		var v2 := UI.vbox(0)
		v2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v2.add_child(UI.label(r[1], "H3"))
		v2.add_child(UI.label(r[2], "Small", true))
		h2.add_child(v2)
		_page.add_child(h2)


func _howto() -> void:
	var steps := [
		["user", "Pilih atau buat peserta", "Satu HP dapat dipakai beberapa lansia. Pilih tokoh, warna baju, dan cara berlatih.", Game.TEAL_MID],
		["eye", "LIHAT materi", "Baca kartu materi di setiap pos. Tekan Dengarkan bila suara pemandu tersedia.", Game.SAFFRON_DARK],
		["run", "IKUTI gerakan", "Tekan Mulai lalu ikuti hitungan. Ulangi atau pilih versi lebih ringan kapan saja.", Game.TERRA],
		["quiz", "COBA tantangan", "Jawab kuis atau mainkan tantangan untuk mengumpulkan daun dan membuka pos berikutnya.", Game.LEAF],
		["calendar", "Catat dan ulangi", "Lihat hari aktif serta hasil kuis awal dan akhir di menu Catatan.", Color("5b6b78")],
		["people", "Sesi Bersama (kader)", "Pilih rangkaian, catat jumlah peserta, lalu putar latihan berurutan untuk kelompok.", Game.TEAL],
	]
	for i in steps.size():
		var s: Array = steps[i]
		var p := UI.panel("Inset")
		var h := UI.hbox(14)
		p.add_child(h)
		h.add_child(UI.badge(s[0], s[3], 52))
		var v := UI.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UI.label("%d. %s" % [i + 1, s[1]], "H3"))
		v.add_child(UI.label(s[2], "Body", true))
		h.add_child(v)
		_page.add_child(p)
