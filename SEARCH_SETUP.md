# Search Feature Setup & Usage

## Apa yang diperbaiki?

Fitur pencarian telah diperbaiki untuk menampilkan **SEMUA hasil yang relevan** (bukan hanya 6 atau 3 artikel).

Sekarang pengguna dapat:
- Mencari berdasarkan **judul** artikel
- Mencari berdasarkan **kategori** (Politics, Economy, Sports, Education, Environment, dll)
- Mencari berdasarkan **tanggal**
- Mencari berdasarkan **lokasi/tempat** (Bandung, Jakarta, Purwakarta, dll)
- Mencari berdasarkan **tema/kata kunci** apapun yang relevan

## File yang Ditambahkan/Diubah

1. **`articles.json`** (AUTO-GENERATED)
   - Index dari 93 artikel di folder `article/`
   - Berisi: title, excerpt, category, date, image URL, article URL
   - Dibuat otomatis oleh script `tools/build_index.py`

2. **`js/search.js`** (BARU)
   - Script pencarian client-side yang:
     - Membaca parameter `?q=...` dari URL
     - Memuat dan mencari di `articles.json`
     - Menampilkan semua hasil yang cocok (unlimited)
     - Fallback ke filter DOM jika `articles.json` tidak tersedia

3. **`search.html`** (DIMODIFIKASI)
   - Tambah id `searchResultsRow` pada kontainer hasil
   - Load script `js/search.js`

4. **`tools/build_index.py`** (BARU)
   - Script Python untuk membuat `articles.json`
   - Scan semua file `.html` di folder `article/`
   - Extract title, kategori, tanggal, ringkasan, gambar

## Setup & Testing

### 1. Generate/Update Index (setiap kali ada artikel baru)

```powershell
py tools\build_index.py
```

Output: `articles.json` dengan semua artikel.

### 2. (Optional) Local Testing

```powershell
py -m http.server 8000
```

Buka browser: `http://localhost:8000/search.html?q=perhutani`

Hasil akan menampilkan semua artikel yang mengandung "perhutani".

## Cara Kerja

1. User mencari: `search.html?q=kata+kunci`
2. Script `js/search.js` mengambil parameter `q`
3. Load `articles.json` (93 artikel diindeks)
4. Filter artikel yang cocok dengan **semua kata kunci** (AND logic)
   - Cek di: title, excerpt, category, date, URL
5. Render hasil secara dinamis
6. Tampilkan pesan: "Found X result(s) for 'kata kunci'"

## Contoh Query

| URL Search | Hasil |
|--|--|
| `?q=perhutani` | Semua artikel tentang Perhutani (20+) |
| `?q=bandung` | Semua artikel tentang Bandung (30+) |
| `?q=environment` | Semua artikel kategori Environment |
| `?q=jan 2026` | Artikel dari Januari 2026 |
| `?q=perhutani bandung` | Artikel Perhutani DAN Bandung (AND logic) |

## Maintenance

**Saat menambah artikel baru:**
1. Simpan file `.html` di folder `article/`
2. Jalankan: `py tools\build_index.py`
3. `articles.json` otomatis terupdate
4. Pencarian langsung mencakup artikel baru

## Teknologi

- **Frontend**: Vanilla JS (no framework)
- **Index**: JSON static file
- **Search**: Client-side filtering
- **Fallback**: DOM element filtering (jika index tidak ada)

---

**Status**: ✓ Ready to use  
**Total Articles Indexed**: 93  
**Search Performant**: Yes (all in-browser)

