# VITAMOVE – Jelajah Sehat Desa

Game edukasi aktivitas fisik untuk lansia (Android, landscape), dibuat dengan **Godot 4.7.2** berdasarkan proposal Pengabdian Masyarakat Telkom University 2026 untuk Posyandu Lansia Wreda Asih 2, Desa Muntang.

## Cara membuka
1. Buka Godot 4.7.2 → **Import** → pilih `project.godot` di folder ini.
2. Tekan **F5** untuk menjalankan.
3. Ekspor Android: **Project → Export → Android** (preset sudah tersedia, paket `id.ac.telkomuniversity.vitamove`, orientasi landscape). Isi keystore milik tim sebelum ekspor rilis.

APK siap pasang tersedia di halaman **Releases** repositori ini.

## Alur game
- **Peserta**: satu HP bisa dipakai beberapa lansia; pilih Mbah Putri/Kakung dan cara berlatih (duduk, berpegangan, mandiri).
- **Peta desa**: 9 pos (Balai Desa → Posyandu) sesuai materi proposal: manfaat, persiapan, pemanasan, keseimbangan, kelenturan, kekuatan ringan, aktivitas sehari-hari, pendinginan, keselamatan.
- **Setiap pos**: LIHAT kartu materi → IKUTI demonstrasi gerakan berhitung (cek badan harian, versi lebih ringan) → COBA tantangan (kuis, Rapikan Rumah, Titian Pematang, Belanja Aman, Lampu Tubuh) → dapat daun.
- **Catatan**: hari aktif, riwayat latihan, kuis awal/akhir (pretest–posttest) dengan persentase peningkatan.
- **Sesi Bersama (kader)**: pilih rangkaian, catat jumlah peserta, putar latihan berurutan.
- **Info Aplikasi**: ketua tim, anggota tim, tim mahasiswa, mitra, cara memakai.

## Struktur
- `scripts/game.gd` (status, simpan, tema, TTS), `scripts/sfx.gd` (audio), `scripts/data.gd` (materi)
- `scripts/screens/` layar, `scripts/challenges/` tantangan, `scripts/draw/` grafis vektor (tokoh, desa, maskot Jali)
- `assets/` fon (OFL) dan audio gamelan buatan sendiri

Catatan: VITAMOVE adalah sarana edukasi, bukan pengganti nasihat tenaga kesehatan.

## Aset prosedural
`tools/gen_audio.py` dan `tools/gen_images.py` (Python 3 + Pillow) membuat ulang audio gamelan, ikon, dan splash.
