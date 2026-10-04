# Perubahan Fitur GERAK

1. Kelola Konten Admin
   - Konten dengan tipe dan judul yang sama tidak dapat diinput dua kali.
   - Pengecekan dilakukan di server dan tidak hanya di form.
   - Link YouTube yang sama tetap ditolak.

2. Tanggal Publish
   - Form tambah/edit konten memiliki field Tanggal Publish.
   - Hari ini dan tanggal setelahnya diperbolehkan.
   - Tanggal sebelum hari ini ditolak oleh browser dan validasi server.
   - Konten dengan tanggal publish di masa depan tidak ditampilkan ke pengguna sampai tanggal tersebut tiba.

3. Notifikasi
   - Ditambahkan tombol/icon 🔔 pada navbar pengguna.
   - Badge jumlah notifikasi yang belum dibaca ditampilkan.
   - Ditambahkan halaman daftar notifikasi.
   - Pengguna dapat menekan tombol "Tandai dibaca".
   - Notifikasi hanya dapat dibaca oleh pemilik jadwal terkait.

4. Lupa Password
   - Link "Lupa Password?" di halaman login awal dihapus sesuai permintaan.

5. Zona Waktu
   - Konfigurasi aplikasi diubah ke Asia/Jakarta agar aturan tanggal mengikuti waktu Indonesia.

Catatan pengujian:
- PHP syntax check: berhasil.
- Laravel route list: berhasil.
- Migrasi database penuh tidak dapat dijalankan pada lingkungan pengecekan karena PHP CLI tidak memiliki driver SQLite.
