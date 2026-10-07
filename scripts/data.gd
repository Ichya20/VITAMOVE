class_name Data
extends RefCounted
## Isi materi VITAMOVE: 9 pos desa, gerakan, dan kuis.
## Materi bersifat edukasi umum; penyesuaian individu tetap mengikuti arahan tenaga kesehatan.

# --------------------------------------------------------------------------- GERAKAN
# keys  : pose tujuan berurutan (satu hitungan per pose, dikali 'beats')
# arms  : gerakan tangan -> pada mode "berpegangan" dilakukan sambil duduk
# hold  : butuh pegangan kursi walau mode mandiri (latihan keseimbangan/kaki)
# chair : selalu memakai kursi (duduk-berdiri)
const MOVES := {
	"napas": {
		"name": "Napas Perut Dalam", "reps": 4, "arms": true,
		"steps": ["Duduk atau berdiri tegak, bahu rileks.", "Tarik napas lewat hidung sambil tangan naik pelan.", "Hembuskan lewat mulut sambil tangan turun."],
		"benefit": "Menenangkan napas dan menyiapkan tubuh.",
		"safety": "Jangan menahan napas. Bila pusing, bernapaslah biasa.",
		"keys": [{"breath": 1.0, "la": 70.0, "ra": 70.0}, {"breath": 0.0}],
		"beats": [2, 2], "cues": ["Tarik napas...", "Hembuskan pelan..."], "sounds": ["breath_in", "breath_out"],
	},
	"bahu": {
		"name": "Angkat dan Putar Bahu", "reps": 6, "arms": false,
		"steps": ["Biarkan tangan menggantung santai.", "Angkat kedua bahu mendekati telinga.", "Turunkan bahu perlahan, rasakan lemas."],
		"benefit": "Melemaskan leher dan bahu yang kaku.",
		"safety": "Gerak pelan, tidak menyentak.",
		"keys": [{"shrug": 1.0}, {"shrug": 0.0}],
		"beats": [1, 1], "cues": ["Angkat bahu", "Turunkan"],
	},
	"tengok": {
		"name": "Tengok Kanan dan Kiri", "reps": 3, "arms": false,
		"steps": ["Pandang lurus ke depan.", "Putar kepala pelan ke kanan, lalu kembali.", "Putar kepala pelan ke kiri, lalu kembali."],
		"benefit": "Menjaga kelenturan leher untuk menoleh sehari-hari.",
		"safety": "Putar sebatas nyaman. Hentikan bila pusing.",
		"keys": [{"head": 1.0}, {"head": 0.0}, {"head": -1.0}, {"head": 0.0}],
		"beats": [1, 1, 1, 1], "cues": ["Tengok kanan", "Depan", "Tengok kiri", "Depan"],
	},
	"jalan": {
		"name": "Jalan di Tempat", "reps": 6, "arms": false,
		"steps": ["Berdiri tegak di dekat kursi.", "Angkat lutut kanan dan kiri bergantian.", "Ayunkan tangan santai, napas tetap biasa."],
		"benefit": "Menghangatkan otot kaki dan melancarkan peredaran darah.",
		"safety": "Angkat lutut serendah yang nyaman saja.",
		"keys": [{"rl": 0.5, "lf": 0.45, "le": 35.0}, {"ll": 0.5, "rf": 0.45, "re": 35.0}],
		"beats": [1, 1], "cues": ["Kanan", "Kiri"],
	},
	"geser": {
		"name": "Geser Berat Badan", "reps": 5, "arms": false, "hold": true,
		"steps": ["Buka kaki selebar bahu.", "Pindahkan berat badan ke kaki kanan, tahan sebentar.", "Pindahkan ke kaki kiri, tahan sebentar."],
		"benefit": "Melatih tubuh menjaga keseimbangan saat melangkah.",
		"safety": "Telapak kaki tetap menapak. Jangan sampai condong jauh.",
		"keys": [{"bx": 16.0, "tilt": -3.0, "lab": 7.0, "rab": 7.0}, {"bx": -16.0, "tilt": 3.0, "lab": 7.0, "rab": 7.0}],
		"beats": [2, 2], "cues": ["Geser ke kanan, tahan", "Geser ke kiri, tahan"],
	},
	"satukaki": {
		"name": "Berdiri Satu Kaki", "reps": 3, "arms": false, "hold": true,
		"steps": ["Berdiri di samping kursi, satu tangan berpegangan.", "Angkat kaki kanan sedikit dari lantai, tahan 3 hitungan.", "Turunkan, lalu ganti kaki kiri."],
		"benefit": "Menguatkan keseimbangan dan mengurangi risiko jatuh.",
		"safety": "Selalu berpegangan. Mulai dengan menahan 1-2 hitungan saja.",
		"keys": [{"rl": 0.32}, {"rl": 0.0}, {"ll": 0.32}, {"ll": 0.0}],
		"beats": [3, 1, 3, 1], "cues": ["Angkat kaki kanan, tahan", "Turunkan", "Angkat kaki kiri, tahan", "Turunkan"],
	},
	"jinjit": {
		"name": "Angkat Tumit (Jinjit)", "reps": 6, "arms": false, "hold": true,
		"steps": ["Berdiri tegak, berpegangan pada sandaran kursi.", "Angkat kedua tumit perlahan, bertumpu di ujung kaki.", "Turunkan tumit pelan-pelan."],
		"benefit": "Menguatkan betis dan pergelangan kaki untuk berjalan.",
		"safety": "Naik sedikit saja bila goyah.",
		"keys": [{"heel": 1.0}, {"heel": 0.0}],
		"beats": [2, 2], "cues": ["Jinjit pelan", "Turunkan tumit"],
	},
	"raih": {
		"name": "Raih ke Atas", "reps": 4, "arms": true,
		"steps": ["Duduk atau berdiri tegak.", "Angkat kedua tangan ke atas setinggi nyaman.", "Tahan, tarik napas, lalu turunkan pelan."],
		"benefit": "Meregangkan bahu, lengan, dan punggung.",
		"safety": "Tidak perlu lurus penuh bila bahu terasa nyeri.",
		"keys": [{"la": 160.0, "ra": 160.0, "breath": 0.7}, {"la": 8.0, "ra": 8.0}],
		"beats": [2, 2], "cues": ["Raih ke atas, tahan", "Turunkan pelan"], "sounds": ["breath_in", "breath_out"],
	},
	"samping": {
		"name": "Condong ke Samping", "reps": 2, "arms": true,
		"steps": ["Tangan kanan naik ke atas kepala.", "Condongkan badan pelan ke kiri, tahan.", "Kembali tegak, lalu ganti sisi."],
		"benefit": "Melenturkan sisi badan dan pinggang.",
		"safety": "Condong sedikit saja. Badan tidak berputar.",
		"keys": [{"ra": 150.0, "re": 15.0, "tilt": -10.0}, {}, {"la": 150.0, "le": 15.0, "tilt": 10.0}, {}],
		"beats": [3, 1, 3, 1], "cues": ["Condong ke kiri, tahan", "Tegak", "Condong ke kanan, tahan", "Tegak"],
	},
	"silang": {
		"name": "Tarik Lengan Menyilang", "reps": 2, "arms": true,
		"steps": ["Luruskan tangan kanan menyilang di depan dada.", "Tangan kiri menahan lengan kanan, tahan.", "Lepas, lalu ganti tangan."],
		"benefit": "Meregangkan bahu dan lengan atas.",
		"safety": "Tarik lembut, tidak sampai nyeri.",
		"keys": [{"ra": -92.0, "la": -30.0, "le": -75.0}, {}, {"la": -92.0, "ra": -30.0, "re": -75.0}, {}],
		"beats": [3, 1, 3, 1], "cues": ["Silangkan tangan kanan, tahan", "Lepas", "Silangkan tangan kiri, tahan", "Lepas"],
	},
	"dudukberdiri": {
		"name": "Duduk-Berdiri dari Kursi", "reps": 4, "arms": false, "chair": true,
		"steps": ["Duduk di ujung kursi, kaki menapak selebar bahu.", "Condong sedikit ke depan, lalu berdiri pelan.", "Duduk kembali perlahan, jangan menjatuhkan badan."],
		"benefit": "Menguatkan paha untuk bangun dari kursi dan toilet.",
		"safety": "Boleh bertumpu tangan pada paha atau sandaran kursi.",
		"keys": [{"sit": 0.0, "lf": 0.7, "rf": 0.7, "la": 20.0, "ra": 20.0}, {"sit": 1.0, "lf": 0.7, "rf": 0.7, "la": 20.0, "ra": 20.0}],
		"seated_keys": [{"sit": 0.62, "lf": 0.7, "rf": 0.7, "la": 20.0, "ra": 20.0, "nod": 0.3}, {"sit": 1.0}],
		"beats": [2, 2], "cues": ["Berdiri pelan", "Duduk perlahan"], "seated_cues": ["Dorong badan sedikit naik", "Duduk kembali"],
	},
	"botol": {
		"name": "Angkat Botol Air", "reps": 8, "arms": true,
		"steps": ["Pegang botol air minum berisi di kedua tangan.", "Tekuk siku, angkat botol mendekati bahu.", "Turunkan pelan."],
		"benefit": "Menguatkan lengan untuk mengangkat barang sehari-hari.",
		"safety": "Gunakan botol ringan (sekitar 600 ml). Siku dekat badan.",
		"keys": [{"bottle": 1.0, "le": 135.0, "re": 135.0, "la": 4.0, "ra": 4.0}, {"bottle": 1.0, "la": 6.0, "ra": 6.0}],
		"beats": [1, 1], "cues": ["Angkat", "Turunkan"],
	},
	"kakisamping": {
		"name": "Angkat Kaki ke Samping", "reps": 4, "arms": false, "hold": true,
		"steps": ["Berdiri tegak, berpegangan kursi.", "Angkat kaki kanan ke samping perlahan.", "Turunkan, lalu ganti kaki kiri."],
		"benefit": "Menguatkan pinggul agar langkah lebih mantap.",
		"safety": "Badan tetap tegak, angkat rendah saja.",
		"keys": [{"rab": 24.0, "tilt": -3.0}, {}, {"lab": 24.0, "tilt": 3.0}, {}],
		"beats": [2, 1, 2, 1], "cues": ["Kaki kanan ke samping", "Turunkan", "Kaki kiri ke samping", "Turunkan"],
	},
	"angkatbarang": {
		"name": "Mengangkat Barang dengan Lutut", "reps": 4, "arms": false, "hold": false,
		"steps": ["Berdiri dekat barang ringan, kaki selebar bahu.", "Tekuk lutut, punggung tetap tegak.", "Berdiri sambil membawa beban dibagi dua tangan."],
		"benefit": "Melatih cara aman membawa belanjaan agar punggung terlindungi.",
		"safety": "Bawa beban ringan, dekat badan. Jangan memutar badan.",
		"keys": [{"squat": 0.65, "bags": 1.0, "nod": 0.2}, {"bags": 1.0}],
		"seated_keys": [{"bags": 1.0, "sit": 1.0, "shrug": 0.5, "breath": 0.4}, {"bags": 1.0, "sit": 1.0}],
		"beats": [2, 2], "cues": ["Tekuk lutut, punggung tegak", "Berdiri tegak"], "seated_cues": ["Angkat tas, duduk tegak", "Turunkan"],
	},
	"raihrak": {
		"name": "Meraih Barang di Rak", "reps": 4, "arms": false, "hold": true,
		"steps": ["Berdiri dekat rak, satu tangan berpegangan.", "Raih barang perlahan setinggi bahu.", "Turunkan tangan, kaki tetap menapak."],
		"benefit": "Melatih gerak meraih tanpa kehilangan keseimbangan.",
		"safety": "Jangan berjinjit atau naik bangku. Barang berat simpan di rak bawah.",
		"keys": [{"la": 130.0, "le": 10.0, "tilt": 3.0}, {}],
		"beats": [2, 2], "cues": ["Raih pelan", "Turunkan"],
	},
	"sandal": {
		"name": "Memakai Alas Kaki Sambil Duduk", "reps": 2, "arms": false, "chair": true,
		"steps": ["Duduk di kursi yang kokoh.", "Angkat satu kaki, pakaikan alas kaki dengan dua tangan.", "Turunkan, lalu ganti kaki."],
		"benefit": "Kebiasaan aman agar tidak terjatuh saat berpakaian.",
		"safety": "Hindari memakai alas kaki sambil berdiri satu kaki.",
		"keys": [{"sit": 1.0, "rl": 0.45, "lf": 0.75, "rf": 0.75, "la": 22.0, "ra": 22.0, "nod": 0.6}, {"sit": 1.0}, {"sit": 1.0, "ll": 0.45, "lf": 0.75, "rf": 0.75, "la": 22.0, "ra": 22.0, "nod": 0.6}, {"sit": 1.0}],
		"beats": [2, 1, 2, 1], "cues": ["Angkat kaki kanan", "Turunkan", "Angkat kaki kiri", "Turunkan"],
	},
	"napaspelan": {
		"name": "Napas Pelan Menenangkan", "reps": 3, "arms": false,
		"steps": ["Duduk santai, tangan di pangkuan atau di samping.", "Tarik napas pelan 3 hitungan.", "Hembuskan lebih lama, 4 hitungan."],
		"benefit": "Menurunkan denyut jantung kembali tenang.",
		"safety": "Bernapas senyaman mungkin.",
		"keys": [{"breath": 1.0}, {"breath": 0.0}],
		"beats": [3, 4], "cues": ["Tarik napas...", "Hembuskan..."], "sounds": ["breath_in", "breath_out"],
	},
	"leher": {
		"name": "Peregangan Leher Lembut", "reps": 2, "arms": false,
		"steps": ["Duduk tegak, bahu turun.", "Miringkan telinga kanan ke arah bahu, tahan.", "Kembali tegak, lalu ke sisi kiri."],
		"benefit": "Mengendurkan otot leher setelah bergerak.",
		"safety": "Miring pelan saja. Jangan memutar kepala melingkar.",
		"keys": [{"htilt": 16.0}, {}, {"htilt": -16.0}, {}],
		"beats": [3, 1, 3, 1], "cues": ["Miring ke kanan, tahan", "Tegak", "Miring ke kiri, tahan", "Tegak"],
	},
	"goyang": {
		"name": "Goyang Tangan Rileks", "reps": 6, "arms": false,
		"steps": ["Biarkan tangan menggantung.", "Goyangkan tangan pelan seperti mengibas air.", "Rasakan otot menjadi lemas."],
		"benefit": "Melepas tegang pada lengan dan bahu.",
		"safety": "Goyang ringan, tidak perlu kuat.",
		"keys": [{"la": 18.0, "ra": 4.0, "le": 12.0}, {"la": 4.0, "ra": 18.0, "re": 12.0}],
		"beats": [1, 1], "cues": ["Goyang", "Goyang"],
	},
	"peluk": {
		"name": "Peluk Diri Sendiri", "reps": 3, "arms": true,
		"steps": ["Silangkan kedua tangan memeluk bahu.", "Tahan sambil bernapas pelan.", "Lepaskan dan tersenyum. Latihan selesai!"],
		"benefit": "Meregangkan punggung atas dan menutup latihan dengan rasa tenang.",
		"safety": "Peluk senyaman mungkin.",
		"keys": [{"la": -22.0, "le": -115.0, "ra": -22.0, "re": -115.0, "nod": 0.25}, {}],
		"beats": [3, 1], "cues": ["Peluk bahu, tahan", "Lepaskan"],
	},
}

# --------------------------------------------------------------------------- POS DESA
const STATIONS := [
	{
		"id": "manfaat", "name": "Manfaat Bergerak", "place": "Balai Desa", "icon": "heart", "color": "c8553d",
		"intro": "Sugeng rawuh, Mbah! Kita mulai dari balai desa. Mengapa tubuh perlu bergerak setiap hari?",
		"cards": [
			{"t": "Otot tetap kuat", "x": "Bergerak teratur menjaga otot kaki dan tangan, sehingga Mbah lebih mudah berdiri, berjalan, dan membawa barang.", "i": "strength"},
			{"t": "Keseimbangan terjaga", "x": "Latihan keseimbangan membantu mengurangi risiko jatuh saat berjalan atau berbalik badan.", "i": "balance"},
			{"t": "Sendi lebih lentur", "x": "Peregangan membuat gerakan sehari-hari seperti menoleh, meraih, dan memakai baju terasa lebih ringan.", "i": "flex"},
			{"t": "Hati senang, tidur nyenyak", "x": "Bergerak bersama teman di Posyandu membuat suasana hati lebih baik dan tidur lebih nyenyak.", "i": "sun"},
			{"t": "Sedikit demi sedikit", "x": "Usahakan aktif sekitar 150 menit per minggu, boleh dicicil 10-30 menit setiap hari, sesuai kemampuan.", "i": "calendar"},
		],
		"moves": [],
		"challenge": {"type": "quiz", "q": [
			{"q": "Apa manfaat bergerak teratur bagi Mbah?", "a": ["Otot kuat dan lebih mandiri", "Badan menjadi lemas", "Tidak ada manfaatnya"], "ok": 0},
			{"q": "Latihan keseimbangan membantu...", "a": ["Mengurangi risiko jatuh", "Menambah rasa kantuk", "Membuat kaki kaku"], "ok": 0},
			{"q": "Waktu aktif yang dianjurkan dalam seminggu?", "a": ["Sekitar 150 menit, boleh dicicil", "Cukup 5 menit sebulan", "Harus 5 jam sehari"], "ok": 0},
		]},
	},
	{
		"id": "persiapan", "name": "Persiapan Latihan", "place": "Rumah Mbah", "icon": "home", "color": "b07c4a",
		"intro": "Sebelum latihan, siapkan diri dan tempat agar aman. Ayo kita rapikan rumah!",
		"cards": [
			{"t": "Pakaian dan alas kaki", "x": "Pakai baju longgar yang nyaman. Gunakan alas kaki yang tidak licin, atau bertelanjang kaki di lantai kering.", "i": "user"},
			{"t": "Kursi yang kokoh", "x": "Siapkan kursi kokoh tanpa roda dan tanpa goyang. Letakkan menempel dinding agar tidak bergeser.", "i": "chair"},
			{"t": "Minum air putih", "x": "Minum beberapa teguk air sebelum dan sesudah latihan. Jangan latihan saat sangat lapar atau baru makan kenyang.", "i": "water"},
			{"t": "Ruang lapang", "x": "Singkirkan barang di lantai, karpet yang terlipat, dan pastikan lampu cukup terang.", "i": "eye"},
		],
		"moves": [],
		"challenge": {"type": "tidy"},
	},
	{
		"id": "pemanasan", "name": "Pemanasan", "place": "Sawah Pagi", "icon": "sun", "color": "f2b134",
		"intro": "Udara sawah pagi segar sekali. Kita hangatkan badan pelan-pelan dulu.",
		"cards": [
			{"t": "Mengapa pemanasan?", "x": "Pemanasan 5 menit menghangatkan otot dan sendi, sehingga latihan inti lebih nyaman dan aman.", "i": "sun"},
			{"t": "Pelan dan bertahap", "x": "Mulai dari gerakan kecil. Ikuti hitungan dengan tenang. Tidak perlu sama persis dengan contoh.", "i": "run"},
		],
		"moves": ["napas", "bahu", "tengok", "jalan"],
		"challenge": {"type": "quiz", "q": [
			{"q": "Pemanasan dilakukan kapan?", "a": ["Sebelum latihan inti", "Sesudah tidur siang saja", "Tidak perlu dilakukan"], "ok": 0},
			{"q": "Saat bergerak, napas sebaiknya...", "a": ["Tetap mengalir, tidak ditahan", "Ditahan selama mungkin", "Dibuat sangat cepat"], "ok": 0},
			{"q": "Saat menengok ke samping, kita...", "a": ["Memutar kepala pelan sebatas nyaman", "Menyentak kepala cepat", "Memutar kepala sampai sakit"], "ok": 0},
		]},
	},
	{
		"id": "keseimbangan", "name": "Keseimbangan", "place": "Pematang Sawah", "icon": "balance", "color": "4f8a3c",
		"intro": "Berjalan di pematang butuh keseimbangan. Mari latih dengan berpegangan kursi.",
		"cards": [
			{"t": "Kunci tidak mudah jatuh", "x": "Keseimbangan yang baik membuat Mbah lebih mantap saat berjalan, berbalik, dan naik turun tangga.", "i": "balance"},
			{"t": "Selalu dekat pegangan", "x": "Lakukan latihan di samping kursi kokoh atau meja. Pegangan boleh dilepas hanya bila sudah sangat mantap.", "i": "chair"},
		],
		"moves": ["geser", "satukaki", "jinjit"],
		"challenge": {"type": "balance"},
	},
	{
		"id": "kelenturan", "name": "Kelenturan", "place": "Rumpun Bambu", "icon": "flex", "color": "1f6f6a",
		"intro": "Bambu lentur tertiup angin namun tidak patah. Ayo lenturkan badan seperti bambu.",
		"cards": [
			{"t": "Regangkan, tahan, lepaskan", "x": "Regangkan otot sampai terasa tertarik ringan, tahan beberapa hitungan sambil bernapas, lalu lepaskan.", "i": "flex"},
			{"t": "Tidak boleh nyeri", "x": "Rasa tertarik itu wajar. Rasa nyeri tajam berarti terlalu jauh, kurangi gerakannya.", "i": "shield"},
		],
		"moves": ["raih", "samping", "silang"],
		"challenge": {"type": "quiz", "q": [
			{"q": "Saat meregangkan otot, rasa yang benar adalah...", "a": ["Tertarik ringan, tidak nyeri", "Nyeri tajam", "Tidak terasa apa-apa sama sekali"], "ok": 0},
			{"q": "Ketika menahan regangan, kita sebaiknya...", "a": ["Tetap bernapas biasa", "Menahan napas", "Bergerak memantul-mantul"], "ok": 0},
			{"q": "Bila bahu terasa nyeri saat meraih ke atas...", "a": ["Angkat setinggi yang nyaman saja", "Paksa sampai lurus", "Tambah beban berat"], "ok": 0},
		]},
	},
	{
		"id": "kekuatan", "name": "Kekuatan Ringan", "place": "Sumur Desa", "icon": "strength", "color": "9c3d2a",
		"intro": "Menimba air butuh tangan dan kaki yang kuat. Kita latih dengan beban ringan.",
		"cards": [
			{"t": "Otot kuat, hidup mandiri", "x": "Latihan kekuatan ringan 2-3 kali seminggu membantu Mbah bangun dari kursi dan membawa barang sendiri.", "i": "strength"},
			{"t": "Beban dari rumah", "x": "Botol air minum berisi sudah cukup sebagai beban. Mulai dari sedikit pengulangan, tambah perlahan.", "i": "water"},
		],
		"moves": ["dudukberdiri", "botol", "kakisamping"],
		"challenge": {"type": "quiz", "q": [
			{"q": "Beban latihan yang aman dari rumah adalah...", "a": ["Botol air minum ringan", "Karung beras 25 kg", "Batu besar"], "ok": 0},
			{"q": "Saat duduk kembali ke kursi, kita...", "a": ["Duduk perlahan dan terkendali", "Menjatuhkan badan", "Duduk sambil memutar badan"], "ok": 0},
			{"q": "Kursi untuk latihan duduk-berdiri sebaiknya...", "a": ["Kokoh dan tidak beroda", "Kursi putar beroda", "Kursi lipat yang goyang"], "ok": 0},
		]},
	},
	{
		"id": "fungsional", "name": "Aktivitas Sehari-hari", "place": "Pasar Desa", "icon": "basket", "color": "d48f16",
		"intro": "Di pasar kita membawa belanjaan, meraih barang, dan berganti alas kaki. Ayo lakukan dengan aman!",
		"cards": [
			{"t": "Latihan dalam keseharian", "x": "Mengangkat, meraih, dan bangun dari kursi adalah gerakan harian. Melatihnya membuat Mbah tetap mandiri.", "i": "basket"},
			{"t": "Jaga punggung", "x": "Tekuk lutut saat mengangkat, bawa beban dekat badan, dan bagi beban di dua tangan.", "i": "shield"},
		],
		"moves": ["angkatbarang", "raihrak", "sandal"],
		"challenge": {"type": "market"},
	},
	{
		"id": "pendinginan", "name": "Pendinginan", "place": "Tepi Kali", "icon": "wave", "color": "3b8ea5",
		"intro": "Gemericik kali menenangkan. Saatnya mendinginkan badan dengan gerakan pelan.",
		"cards": [
			{"t": "Menutup latihan", "x": "Pendinginan 3-5 menit membantu napas dan denyut jantung kembali tenang.", "i": "wave"},
			{"t": "Minum dan istirahat", "x": "Setelah latihan, minum air putih dan duduk sebentar sebelum melanjutkan kegiatan.", "i": "water"},
		],
		"moves": ["napaspelan", "leher", "goyang", "peluk"],
		"challenge": {"type": "quiz", "q": [
			{"q": "Pendinginan dilakukan...", "a": ["Setelah latihan, dengan gerakan pelan", "Sebelum bangun tidur", "Tidak perlu"], "ok": 0},
			{"q": "Setelah latihan sebaiknya Mbah...", "a": ["Minum air dan duduk sebentar", "Langsung mengangkat beban berat", "Mandi air sangat dingin"], "ok": 0},
			{"q": "Peregangan leher yang aman adalah...", "a": ["Miring pelan ke samping", "Memutar kepala melingkar cepat", "Menarik kepala dengan kuat"], "ok": 0},
		]},
	},
	{
		"id": "keselamatan", "name": "Keselamatan", "place": "Posyandu Lansia", "icon": "shield", "color": "b3261e",
		"intro": "Pos terakhir: Posyandu. Kenali tanda tubuh kapan boleh lanjut dan kapan harus berhenti.",
		"cards": [
			{"t": "Uji bicara", "x": "Latihan yang pas: napas sedikit lebih cepat, tetapi Mbah masih bisa berbicara dengan jelas.", "i": "people"},
			{"t": "Segera berhenti bila...", "x": "Nyeri atau rasa berat di dada, sesak napas berat, pusing berputar, keringat dingin, atau nyeri sendi tajam.", "i": "stop"},
			{"t": "Lalu lakukan ini", "x": "Duduk, istirahat, dan beri tahu kader atau tenaga kesehatan. Bila keluhan berat, segera cari pertolongan medis.", "i": "shield"},
			{"t": "VITAMOVE bukan pengganti dokter", "x": "Aplikasi ini untuk edukasi. Jenis dan takaran latihan tetap disesuaikan dengan arahan tenaga kesehatan.", "i": "info"},
		],
		"moves": [],
		"challenge": {"type": "traffic"},
	},
]

# --------------------------------------------------------------------------- KUIS PENGETAHUAN (pretest/posttest)
const KNOWLEDGE_TEST := [
	{"q": "Manfaat aktivitas fisik teratur bagi lansia adalah...", "a": ["Menjaga kekuatan otot dan keseimbangan", "Membuat cepat lelah", "Tidak ada manfaat"], "ok": 0},
	{"q": "Sebelum latihan inti, sebaiknya kita...", "a": ["Pemanasan ringan terlebih dahulu", "Langsung gerakan berat", "Makan sampai sangat kenyang"], "ok": 0},
	{"q": "Kursi untuk latihan sebaiknya...", "a": ["Kokoh dan tidak beroda", "Kursi putar beroda", "Bangku yang goyang"], "ok": 0},
	{"q": "Bila dada terasa nyeri saat latihan, kita harus...", "a": ["Berhenti, duduk, dan beri tahu kader atau tenaga kesehatan", "Terus sampai selesai", "Menambah kecepatan"], "ok": 0},
	{"q": "Saat latihan, napas sebaiknya...", "a": ["Tetap mengalir, tidak ditahan", "Ditahan selama mungkin", "Dibuat secepat mungkin"], "ok": 0},
	{"q": "Tanda latihan dengan takaran yang pas adalah...", "a": ["Masih bisa berbicara walau napas lebih cepat", "Tidak bisa bicara sama sekali", "Badan terasa sangat nyeri"], "ok": 0},
	{"q": "Latihan keseimbangan bermanfaat untuk...", "a": ["Mengurangi risiko jatuh", "Menambah berat badan", "Memperbaiki penglihatan"], "ok": 0},
	{"q": "Cara aman mengangkat barang dari lantai adalah...", "a": ["Tekuk lutut, punggung tegak, barang dekat badan", "Membungkuk dengan kaki lurus", "Memutar badan sambil mengangkat"], "ok": 0},
	{"q": "Pendinginan dilakukan...", "a": ["Setelah latihan, dengan gerakan pelan", "Sebelum pemanasan", "Tidak perlu dilakukan"], "ok": 0},
	{"q": "Pakaian dan alas kaki yang tepat untuk latihan adalah...", "a": ["Pakaian longgar dan alas kaki tidak licin", "Sandal licin", "Pakaian sangat ketat"], "ok": 0},
]

# --------------------------------------------------------------------------- TANTANGAN KHUSUS
# Rumah: ketuk benda yang berbahaya untuk dirapikan.
const TIDY_ITEMS := [
	{"name": "Karpet terlipat", "bad": true, "fix": "Karpet diratakan agar tidak tersandung."},
	{"name": "Kursi beroda", "bad": true, "fix": "Diganti kursi kayu yang kokoh."},
	{"name": "Lantai basah", "bad": true, "fix": "Lantai dikeringkan agar tidak licin."},
	{"name": "Kabel melintang", "bad": true, "fix": "Kabel dirapikan ke pinggir."},
	{"name": "Sandal licin", "bad": true, "fix": "Diganti alas kaki bersol karet."},
	{"name": "Gelas air putih", "bad": false, "fix": "Air minum memang perlu disiapkan."},
	{"name": "Kursi kayu kokoh", "bad": false, "fix": "Kursi kokoh aman untuk berpegangan."},
	{"name": "Lampu terang", "bad": false, "fix": "Ruangan terang membantu melihat jelas."},
]

# Pasar: pilih cara yang aman.
const MARKET := [
	{"q": "Mbah membeli beras 2 kg dan sayur. Cara membawanya?", "a": ["Dibagi di dua tas, kiri dan kanan", "Semua di satu tangan", "Dipanggul di bahu sambil berlari"], "ok": 0},
	{"q": "Gula ada di rak paling atas. Apa yang Mbah lakukan?", "a": ["Minta tolong pedagang mengambilkan", "Naik ke bangku plastik", "Berjinjit sambil menarik rak"], "ok": 0},
	{"q": "Mbah mau memakai sandal setelah dari musala pasar.", "a": ["Duduk dulu, lalu pakai sandal", "Berdiri satu kaki tanpa pegangan", "Sambil berjalan cepat"], "ok": 0},
	{"q": "Ada kantong jatuh di lantai. Cara mengambilnya?", "a": ["Tekuk lutut, punggung tegak, pegangan meja", "Membungkuk dengan kaki lurus", "Menendangnya ke dinding"], "ok": 0},
]

# Posyandu: lampu lalu lintas tubuh.
const TRAFFIC := [
	{"t": "Napas sedikit lebih cepat, masih bisa mengobrol", "c": 0},
	{"t": "Badan terasa hangat dan sedikit berkeringat", "c": 0},
	{"t": "Otot terasa tertarik ringan saat peregangan", "c": 0},
	{"t": "Mulai sedikit lelah, napas agak berat", "c": 1},
	{"t": "Kaki mulai goyah saat jinjit", "c": 1},
	{"t": "Nyeri atau rasa berat di dada", "c": 2},
	{"t": "Pusing berputar atau pandangan gelap", "c": 2},
	{"t": "Sesak napas sampai sulit berbicara", "c": 2},
	{"t": "Keringat dingin dan badan lemas sekali", "c": 2},
]
const TRAFFIC_LABELS := ["Lanjutkan", "Pelankan / istirahat", "Berhenti & lapor"]

# --------------------------------------------------------------------------- SESI BERSAMA (mode kader)
const SESSION_TEMPLATES := [
	{"name": "Sesi Singkat", "desc": "Sekitar 8 menit. Cocok untuk awal kegiatan Posyandu.", "moves": ["napas", "bahu", "jalan", "jinjit", "botol", "napaspelan", "peluk"]},
	{"name": "Sesi Lengkap", "desc": "Sekitar 15 menit. Pemanasan, keseimbangan, kelenturan, kekuatan, pendinginan.",
		"moves": ["napas", "bahu", "tengok", "jalan", "geser", "jinjit", "raih", "samping", "dudukberdiri", "botol", "napaspelan", "leher", "peluk"]},
	{"name": "Sesi Duduk", "desc": "Sekitar 10 menit. Semua gerakan dilakukan sambil duduk.", "moves": ["napas", "bahu", "tengok", "jalan", "raih", "silang", "botol", "jinjit", "napaspelan", "leher", "peluk"], "capacity": 0},
]


static func station_index(id: String) -> int:
	for i in STATIONS.size():
		if STATIONS[i]["id"] == id:
			return i
	return -1


static func move_variant(move_id: String, capacity: int) -> Dictionary:
	## Menghasilkan pengaturan tampilan gerakan sesuai kemampuan peserta.
	var m: Dictionary = MOVES[move_id]
	var out := {
		"keys": m["keys"], "cues": m.get("cues", []), "chair": 0, "support": false, "sit_base": 0.0,
		"note": "",
	}
	var seated := capacity == 0 or (capacity == 1 and bool(m.get("arms", false)))
	if bool(m.get("chair", false)):
		seated = false
		out["chair"] = 1
		if capacity == 0 and m.has("seated_keys"):
			out["keys"] = m["seated_keys"]
			out["cues"] = m.get("seated_cues", out["cues"])
			out["note"] = "Versi duduk: cukup dorong badan sedikit naik."
		return out
	if seated:
		out["chair"] = 1
		out["sit_base"] = 1.0
		if m.has("seated_keys"):
			out["keys"] = m["seated_keys"]
			out["cues"] = m.get("seated_cues", out["cues"])
			out["sit_base"] = 0.0
			out["note"] = "Versi duduk khusus untuk gerakan ini."
		elif capacity == 1:
			out["note"] = "Gerakan tangan dilakukan sambil duduk agar lebih aman."
		else:
			out["note"] = "Lakukan sambil duduk tegak di kursi."
		return out
	if capacity == 1 or bool(m.get("hold", false)):
		out["chair"] = 2
		out["support"] = true
		out["note"] = "Tangan berpegangan pada sandaran kursi."
	return out
