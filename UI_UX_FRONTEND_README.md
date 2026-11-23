# Kedai Seblak Rheya — Frontend UI/UX (revisi 2)

Revisi ini hanya menyentuh frontend Flutter (`mobile_frontend/lib/`). Backend, database, dependensi (`pubspec.yaml`), dan file native tidak diubah.

## Cara memasang

1. Ekstrak ZIP ke root repository, pertahankan folder `mobile_frontend/`.
2. Izinkan file menimpa file lama dengan nama sama.
3. Jalankan `flutter pub get` lalu `flutter analyze` di folder `mobile_frontend/`.
4. Periksa diff sebelum commit.

> **Belum dikompilasi.** Flutter SDK tidak tersedia di lingkungan penyusun revisi ini, jadi `flutter analyze` dan `flutter run` belum pernah dijalankan. Kontras warna, ukuran font, dan konsistensi import sudah dicek dengan skrip. Jika `flutter analyze` menampilkan error, kirim hasilnya agar bisa diperbaiki.

## Struktur file

```
lib/
  main.dart                          tema (tombol, input, snackbar)
  constants/
    app_colors.dart                  token warna (brand asli + token baru)
    api_config.dart                  alamat API + penanda "Data contoh"
  models/stock_item.dart             StockItem, ActivityEntry, enum, daftar kategori & satuan
  controllers/inventory_controller.dart   semua data & aturan stok (di memori)
  utils/formatters.dart              angka (koma desimal), waktu aktivitas
  views/
    auth/login_view.dart
    owners/owner_dashboard.dart      tidak berubah
    cashiers/cashier_dashboard.dart  tidak berubah
    shared/
      inventory_app.dart             kerangka: app bar, 4 tab, logout
      pages/   dashboard_page, inventory_page, opname_page, activity_page
      sheets/  item_form_sheet, stock_movement_sheet, stock_detail_sheet
      widgets/ stock_tile, status_pill, metric_card, quick_action, section_heading, empty_state
```

`inventory_app.dart` yang tadinya satu file 270 baris kini dipecah per layar. Semua perubahan data lewat `InventoryController`, jadi saat backend siap cukup method di controller yang diganti menjadi pemanggilan API.

## Yang diperbaiki

| Masalah di review | Perbaikan |
|---|---|
| Bug opname: kolom fisik basi setelah stok berubah | Isian fisik kini disimpan di controller dan dikosongkan tiap sesi selesai |
| Opname rawan salah | Kolom mulai kosong, ada progres "x dari y dihitung", pencarian, satu tombol simpan, dialog konfirmasi berisi daftar selisih, catatan opsional, tombol Kosongkan |
| Form gagal tanpa pesan | Semua form memakai validasi dengan pesan di bawah kolom (mis. "Melebihi stok tersedia (8 kg)") |
| Teks developer tampil ke user | Dihapus. Penanda "Data contoh" kecil di app bar, bisa dimatikan lewat `ApiConfig.demoData = false` |
| Kontras 2,4–2,9:1 dan font 9–11 px | Oranye tombol/teks `#C2410C` (5,2:1), semua warna status lolos 4,5:1, font minimum 12 px |
| Dashboard: banner besar, info penting di bawah | Banner ringkas dengan jumlah barang perlu perhatian, lalu Aksi cepat, lalu Perlu diperhatikan (Habis dulu), lalu Ringkasan |
| Daftar "Perlu diperhatikan" terpotong / tanpa kondisi kosong | Diurutkan Habis → Menipis, tampil kondisi "Semua stok aman" |
| Kartu ringkasan tidak bisa diketuk | Jenis barang / Menipis / Habis membuka Inventaris dengan filter yang sesuai |
| Chip kategori hanya 4 dari 7 | Kategori dan satuan dari satu daftar (`kCategories`, `kUnits`) |
| Label tab vs judul tidak seragam | Beranda, Inventaris, Opname, Aktivitas dipakai di keduanya |
| Lonceng notifikasi tanpa fungsi | Dihapus |
| Pencarian kosong tanpa pesan | Ada tampilan kosong + tombol Reset filter |
| Tidak ada hapus barang | Owner bisa hapus di Edit barang (dengan konfirmasi) |
| Edit barang mengubah stok tanpa jejak | Jumlah stok tidak lagi diedit di form Edit; hanya lewat Stok masuk/keluar/Opname |
| Aktivitas tanpa pelaku dan jam | Tiap entri mencatat peran (Owner/Kasir) dan waktu ("Hari ini, 14.05") |
| Kasir mengetuk barang tanpa respons | Ketuk barang membuka rincian dengan Stok masuk / Stok keluar (Owner juga ada Edit) |
| Logout tanpa konfirmasi | Ada dialog konfirmasi |
| Login: PIN menerima huruf, tanpa validasi, bisa menggantung | Hanya angka (4), validasi per kolom, batas waktu 10 detik, footer diganti "Lupa PIN? Hubungi owner kedai." |

## Perubahan perilaku yang perlu diketahui

- **Alamat API.** Di Android emulator, `localhost` tidak menjangkau komputer host. `ApiConfig` kini otomatis memakai `http://10.0.2.2:3000` di Android dan `http://localhost:3000` di platform lain. Untuk HP fisik atau alamat lain:
  `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000`
- **Data masih contoh.** Stok dan aktivitas hanya di memori dan kembali ke data awal setelah logout atau aplikasi dimulai ulang (sama seperti revisi sebelumnya).
- Opname menyimpan **semua barang yang sudah dihitung sekaligus**; barang yang belum dihitung tidak berubah.

## Arah desain

Tetap hangat dan oranye. Oranye brand `#FF7B00` dipertahankan di `AppColors.primary`, sedangkan tombol, teks, dan ikon memakai `primaryDark` agar terbaca jelas. Status stok selalu berupa ikon + teks + warna, tidak hanya warna.
