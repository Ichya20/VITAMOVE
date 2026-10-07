extends Screen
## Info aplikasi: tentang VITAMOVE, mitra, dan tim pengusul (sesuai proposal).

const KETUA := {"name": "Aminatus Sa'adah, S.Si., M.Si.", "role": "Ketua Tim · Koordinator", "detail": "Asisten Ahli · S1 Teknik Informatika, Telkom University Kampus Purwokerto"}
const ANGGOTA := [
	{"name": "Evia Zunita Dwi Pratiwi, S.T., M.Sc.", "role": "Anggota Tim (Dosen)"},
	{"name": "Yohani Setiya Rafika Nur, S.Kom., M.Kom", "role": "Anggota Tim (Dosen)"},
]
const MAHASISWA := [
	{"name": "Ichya Ulumiddiin", "nim": "103112400076"},
	{"name": "Muhammad Zakiy Mubarok", "nim": "103022400120"},
	{"name": "Muhammad Nafal Fiqrian", "nim": "101132400003"},
	{"name": "Elisa Kusumaningsih", "nim": "101132400034"},
]

var _tabs: Array[Button] = []
var _page: VBoxContainer
var _tab := 0
var _scroll: ScrollContainer


func build() -> void:
	soft_bg("balai", "pagi", 0.66)
	make_content(26)
	var v := UI.vbox(12)
	content.add_child(v)
	v.add_child(top_bar("Info Aplikasi"))
	var row := UI.hbox(16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(row)
	var side := UI.vbox(10)
	side.custom_minimum_size = Vector2(280, 0)
	row.add_child(side)
	var names := ["Tentang VITAMOVE", "Tim Pengusul", "Mitra & Program", "Cara Memakai"]
	var icons := ["leaf", "people", "home", "book"]
	for i in names.size():
		var b := UI.btn(names[i], "ChoiceButton", icons[i], 76, 30)
		b.toggle_mode = true
		b.button_pressed = i == 0
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			Sfx.play("tap")
			_show(i))
		side.add_child(b)
		_tabs.append(b)
	side.add_child(UI.spacer(false, true))
	var ver := UI.label("Versi 1.0.0 · Godot 4.7", "Small")
	side.add_child(ver)
	var card := UI.panel("Card")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(card)
	_scroll = UI.scroll_v()
	card.add_child(_scroll)
	_page = UI.vbox(14)
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_page)
	_show(0)


func default_focus() -> Control:
	return _tabs[_tab]


func _show(i: int) -> void:
	_tab = i
	for k in _tabs.size():
		_tabs[k].set_pressed_no_signal(k == i)
	for c in _page.get_children():
		c.queue_free()
	_scroll.scroll_vertical = 0
	match i:
		0: _about()
		1: _team()
		2: _partner()
		3: _howto()


func _p(text: String, variation: String = "Body") -> void:
	_page.add_child(UI.label(text, variation, true))


func _about() -> void:
	var h := UI.hbox(16)
	var j := Mascot.new()
	j.custom_minimum_size = Vector2(130, 130)
	h.add_child(j)
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(UI.label("VITAMOVE", "H1"))
	v.add_child(UI.label("Multimedia Interaktif Edukasi Aktivitas Fisik untuk Peningkatan Kemandirian Lansia", "H3", true))
	h.add_child(v)
	_page.add_child(h)
	_p("VITAMOVE membantu lansia melihat, memahami, mempraktikkan, mengevaluasi, dan mengulang aktivitas fisik secara aman. Materi disajikan dengan teks ringkas, ilustrasi, suara, demonstrasi gerakan yang dapat diulang, dan latihan interaktif.")
	_p("Materi: manfaat bergerak, persiapan latihan, pemanasan, keseimbangan, kelenturan, kekuatan ringan, aktivitas sehari-hari, pendinginan, dan keselamatan.")
	var np := UI.panel("Note")
	np.add_child(UI.label("Penting: VITAMOVE adalah sarana edukasi, bukan pengganti pemeriksaan atau rekomendasi medis. Penyesuaian latihan tetap mengikuti arahan tenaga kesehatan.", "Body", true))
	_page.add_child(np)
	_p("Kredit: fon Atkinson Hyperlegible (Braille Institute) dan Lilita One, berlisensi SIL Open Font License. Musik gamelan dan efek suara dibuat khusus untuk aplikasi ini.", "Small")


func _person(name: String, role: String, detail: String, icon_col: Color, big: bool = false) -> Control:
	var p := UI.panel("Cream" if big else "Pill")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := UI.hbox(14)
	p.add_child(h)
	var badge := Control.new()
	var sz := 72.0 if big else 54.0
	badge.custom_minimum_size = Vector2(sz, sz)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var initials := ""
	for w in name.replace(",", " ").split(" ", false):
		if initials.length() < 2 and w.length() > 0 and w[0] == w[0].to_upper() and not w.contains("."):
			initials += w[0]
	badge.draw.connect(func() -> void:
		badge.draw_circle(badge.size / 2.0, sz / 2.0, icon_col, true, -1.0, true)
		var f := Game.font_display
		var fsz := int(sz * 0.42)
		var tw := f.get_string_size(initials, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
		badge.draw_string(f, Vector2(badge.size.x / 2.0 - tw / 2.0, badge.size.y / 2.0 + fsz * 0.36), initials, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color.WHITE))
	h.add_child(badge)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var rl := UI.label(role, "Small")
	rl.add_theme_color_override("font_color", icon_col.darkened(0.2))
	v.add_child(rl)
	v.add_child(UI.label(name, "H2" if big else "H3", true))
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
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for m in MAHASISWA:
		grid.add_child(_person(m["name"], "Mahasiswa", "NIM %s" % m["nim"], Color("c98a12")))
	_page.add_child(grid)
	_p("Direktorat Kampus Purwokerto · Kelompok Keahlian Data Science and Optimization", "Small")


func _partner() -> void:
	_page.add_child(UI.label("Mitra Sasaran", "H2"))
	_p("Posyandu Lansia Wreda Asih 2, Desa Muntang, Kecamatan Kemangkon, Kabupaten Purbalingga, Jawa Tengah.")
	var row := UI.hbox(12)
	for s in [["30", "lansia", Game.TERRA], ["10", "kader", Game.TEAL_MID], ["2", "tenaga kesehatan", Game.LEAF]]:
		var p := UI.panel("Pill")
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UI.vbox(0)
		p.add_child(v)
		var b := UI.label(s[0], "Big", false, HORIZONTAL_ALIGNMENT_CENTER)
		b.add_theme_color_override("font_color", s[2])
		v.add_child(b)
		v.add_child(UI.label(s[1], "Body", false, HORIZONTAL_ALIGNMENT_CENTER))
		row.add_child(p)
	_page.add_child(row)
	_page.add_child(UI.label("Program", "H2"))
	_p("Pengabdian kepada Masyarakat Telkom University · Tahun 2026, Periode 2 · Skema Teknologi Tepat Guna (TTG) · Bidang fokus Kesehatan · SDG 3 (Kehidupan Sehat dan Sejahtera) dan SDG 4 (Pendidikan Berkualitas).")
	_p("Tahapan: sosialisasi dan pemetaan, pelatihan kader, tenaga kesehatan, dan lansia, penerapan VITAMOVE, pendampingan dan evaluasi, serta penguatan keberlanjutan.")
	_page.add_child(UI.label("Peran", "H2"))
	_p("Lansia: pengguna utama yang belajar dan berlatih.\nKader: operator dan pemandu sesi melalui menu Sesi Bersama.\nTenaga kesehatan: pengarah materi dan keselamatan latihan.")


func _howto() -> void:
	var steps := [
		["user", "Pilih atau buat peserta", "Satu HP dapat dipakai beberapa lansia. Pilih cara berlatih: duduk, berpegangan, atau mandiri."],
		["eye", "LIHAT materi", "Baca kartu materi di setiap pos. Tekan Dengarkan bila suara pemandu tersedia."],
		["run", "IKUTI gerakan", "Tekan Mulai, ikuti hitungan dan contoh gerakan. Ulangi atau pilih versi lebih ringan kapan saja."],
		["quiz", "COBA tantangan", "Jawab kuis atau mainkan tantangan untuk mengumpulkan daun dan membuka pos berikutnya."],
		["calendar", "Catat dan ulangi", "Lihat hari aktif dan hasil kuis awal-akhir di menu Catatan."],
		["people", "Sesi Bersama (kader)", "Pilih rangkaian, catat jumlah peserta, lalu putar latihan berurutan untuk kelompok."],
	]
	for i in steps.size():
		var s: Array = steps[i]
		var p := UI.panel("Pill")
		var h := UI.hbox(14)
		p.add_child(h)
		h.add_child(Icon.new(s[0], Game.TERRA, 46))
		var v := UI.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UI.label("%d. %s" % [i + 1, s[1]], "H3"))
		v.add_child(UI.label(s[2], "Body", true))
		h.add_child(v)
		_page.add_child(p)
