# Arsitektur Kasir Cepat (POS Offline)

Proyek ini menggunakan **Clean Architecture** yang dikombinasikan dengan **Riverpod** sebagai pengatur state (state management). Pendekatan ini memisahkan kode menjadi lapisan-lapisan mandiri yang mudah diuji, dirawat, dan dikembangkan secara modular.

---

## 1. Struktur Direktori Proyek

Aplikasi dibagi menjadi dua bagian utama: **Core** (modul global/infrastruktur dasar) dan **Feature** (modul fitur bisnis).

```text
lib/
├── core/
│   ├── database/     # Helper database lokal (SQLite - sqflite)
│   ├── errors/       # Kelas Exception dan Failure (kegagalan sistem)
│   ├── network/      # Cek status koneksi (stub offline)
│   ├── routes/       # Pengaturan navigasi rute (GoRouter)
│   ├── themes/       # Pilihan warna, tipografi, dan tema aplikasi (Outfit Font)
│   ├── usecase/      # Definisi usecase dasar (Clean Architecture)
│   └── utils/        # Widget animasi (impact) & Toast Helper global
│
├── feature/          # Modul fungsional berdasarkan fitur POS
│   ├── auth/         # Login Cashier & Splash Screen
│   ├── bussiness/    # Dashboard & Profil Bisnis
│   ├── categories/   # Kelola Kategori Produk
│   ├── discount/     # Manajemen Diskon/Promo
│   ├── payment/      # Halaman Pembayaran & Kalkulasi
│   ├── printer/      # Pengaturan Printer Kasir (Bluetooth/USB/ESC-POS)
│   ├── product/      # Daftar & Manajemen Produk
│   ├── stock/        # Manajemen Stok / Kartu Stok
│   └── unit/         # Kelola Satuan Produk (Pcs, Box, Kg)
│
└── main.dart         # Entry point aplikasi & Inisialisasi awal
```

---

## 2. Struktur Modular Fitur (Clean Architecture Sub-Layers)

Setiap folder di dalam `lib/feature/...` idealnya dibagi menjadi 3 lapisan:

### A. Data Layer (`data/`)
Berfungsi untuk mengambil dan menyimpan data dari sumber luar (SQLite, SharedPreferences).
- **Models**: Representasi data mentah dari database, menyertakan helper serialization (`toMap`, `fromMap`, `fromJson`).
- **Datasources**: Penghubung langsung ke database lokal (`LocalDataSource`).
- **Repositories Implementation**: Implementasi interface repositori yang berada di Domain layer. Bertanggung jawab menangani exception database dan mengubahnya menjadi tipe data `Failure`.

### B. Domain Layer (`domain/`)
Merupakan inti logika bisnis (business logic) aplikasi, bersifat murni Dart tanpa dependensi eksternal UI.
- **Entities**: Objek bisnis utama aplikasi (misal: `Product`, `Transaction`).
- **Repositories Interface**: Deklarasi kontrak fungsi penyimpanan/pengambilan data.
- **UseCases**: Alur proses spesifik (misal: `AddProduct`, `CheckoutSale`). Setiap UseCase mengimplementasikan kelas dasar `UseCase<Type, Params>` dan mengembalikan data bertipe `Either<Failure, Type>`.

### C. Presentation Layer (`presentation/`)
Menangani interaksi antarmuka pengguna (UI).
- **Notifiers / Providers**: Menyediakan state ke UI menggunakan `StateNotifier` (Riverpod) atau notifier generator.
- **Pages**: Layar penuh aplikasi (misal: `POSPage`, `ProductListPage`).
- **Widgets**: Bagian UI kecil yang reusable (misal: `ProductCard`, `CartItemRow`).

---

## 3. Alur Data (Data Flow)

Data mengalir satu arah:
1. **User Action**: Pengguna menekan tombol "Bayar" di UI (`Page`).
2. **Provider Trigger**: Notifier dipanggil, mengaktifkan `UseCase` yang relevan.
3. **Logika Bisnis**: `UseCase` memanggil metode di `Repository`.
4. **Data Access**: `RepositoryImpl` melakukan query database melalui `DataSource`, mendapatkan raw map, mengubahnya menjadi model, lalu mengembalikan data berupa `Right(Transaction)` jika sukses atau `Left(DatabaseFailure)` jika gagal.
5. **State Update**: Notifier menerima hasil `Either` tersebut, memperbarui state UI, dan memicu re-render widget.

---

## 4. Panduan Desain & Style

Sesuai dengan ketentuan `design.md`:
- **Portrait First**: Layout diprioritaskan untuk layar HP tegak.
- **Premium Red Theme**: Warna merah elegan sebagai warna utama, dipadu dengan font **Outfit** dari Google Fonts.
- **Card-Based UI**: Semua navigasi menu dan tampilan konten menggunakan container berbentuk Card melayang (*floating card*) ber-radius `16px` tanpa garis tepi (*borderless*).
- **Impact Effect**: Setiap tombol dan Card interaktif wajib dibungkus `ScaleImpactAnimation` untuk memberikan efek getaran/tekanan visual yang premium.
