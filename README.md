# VITAMOVE – Jelajah Sehat Desa (v1.2)

Game edukasi aktivitas fisik untuk lansia (Android, landscape), dibuat dengan **Godot 4.7.2** berdasarkan proposal Pengabdian Masyarakat Telkom University 2026 untuk Posyandu Lansia Wreda Asih 2, Desa Muntang.

## Cara membuka
1. Buka Godot 4.7.2 → **Import** → pilih `project.godot` di folder ini.
2. Tekan **F5** untuk menjalankan.
3. Ekspor Android: **Project → Export → Android** (preset tersedia, paket `id.ac.telkomuniversity.vitamove`, orientasi landscape). Isi keystore milik tim sebelum ekspor rilis.

## Alur game
- **Splash beranimasi**: daun kertas berjatuhan, logo VITAMOVE menyatu dari dua sisi diiringi gong gamelan, pita "Jelajah Sehat Desa" terbuka, lalu Jali si Jalak terbang masuk dan berkicau. Dapat dilewati kapan saja dan hanya muncul sekali saat aplikasi dibuka.
- **Peserta**: satu HP untuk beberapa lansia; pilih tokoh (Mbah Putri/Mbah Kakung), warna baju, dan cara berlatih (duduk, berpegangan, mandiri).
- **Peta desa berlapis**: 9 pos (Balai Desa → Posyandu) sesuai materi proposal. Tokoh berjalan ke pos baru yang terbuka.
- **Setiap pos**: LIHAT kartu materi → IKUTI demonstrasi gerakan berhitung (cek badan harian, versi lebih ringan) → COBA tantangan (kuis, Rapikan Rumah, Titian Pematang, Belanja Aman, Lampu Tubuh) → perayaan daun.
- **Catatan**: kalender 14 hari, riwayat, grafik kuis awal/akhir dengan persentase peningkatan.
- **Sesi Bersama (kader)**: pilih rangkaian, catat kehadiran, pilih pemandu (Bu Kader/Mbah Putri/Mbah Kakung), putar latihan berurutan.
- **Info Aplikasi**: ketua tim, anggota tim, tim mahasiswa, mitra, cara memakai.

## Yang baru di v1.2
- Layar **splash beranimasi** (sekitar 4 detik) dengan tombol **Lewati**; ketuk di mana saja atau tekan tombol apa pun juga melewatinya.
- Warna boot splash Godot disetel krem agar menyambung mulus ke animasi, tanpa kedipan warna.
- Mengikuti pengaturan **Animasi: Dikurangi** → logo tampil sebentar lalu langsung masuk.
- Dua suara baru: gong gamelan dan kicau Jali.

## Yang baru di v1.1
- Tokoh berkontur dengan gerak luwes (pegas), napas dan kedip saat diam, ekspresi wajah per gerakan, dan tokoh baru Bu Kader.
- Komponen UI baru: tombol taktil, kartu ketuk, penunjuk langkah, cincin hitungan, gelembung bicara, lencana ikon, notifikasi singkat.
- Transisi layar "sapuan kertas" bermotif kawung, kemunculan bertahap, semburan daun dan konfeti.
- Pengaturan **Animasi: Dikurangi** untuk pengguna yang mudah pusing.

## Struktur
- `scripts/game.gd` (status, simpan, tema), `scripts/sfx.gd` (audio), `scripts/data.gd` (materi)
- `scripts/screens/` layar, `scripts/challenges/` tantangan, `scripts/ui/` komponen, `scripts/draw/` grafis vektor
- `assets/` fon (OFL), audio gamelan dan efek prosedural, tekstur partikel
- `tools/` skrip Python pembuat aset; `scripts/dev/tour.gd` tur tangkapan layar (tidak ikut diekspor)

Catatan: VITAMOVE adalah sarana edukasi, bukan pengganti nasihat tenaga kesehatan.
