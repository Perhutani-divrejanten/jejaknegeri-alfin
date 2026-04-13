# 🔧 Troubleshooting - Masalah & Solusi

## Masalah 1 & 2: Gambar Salah di Search & Category Filter
**Gejala:** Saat search atau klik kategori Lingkungan, berita1-f tampil tapi gambar menunjukkan `berita10.png` instead of gambar seharusnya.

### Root Cause:
- File gambar **`img/beritaf1.jpg` belum ada** di folder `img/`
- search.html & category filter membaca `image` field dari `articles.json`
- articles.json punya path: `"image": "img/beritaf1.jpg"`
- Browser coba load gambar yang tidak ada → fallback ke `berita10.png`

### Solusi:
**Option A: Upload File Gambar (Recommended)**
1. Siapkan file gambar (JPG/PNG)
2. Upload ke folder `img/` dengan nama **`beritaf1.jpg`** (sesuai yang di-spreadsheet)
3. Maka gambar akan tampil benar

**Option B: Gunakan URL Publik**
1. Di Google Sheets column `image`, isi dengan URL publik: `https://example.com/foto.jpg`
2. Generator akan gunakan URL langsung tanpa prepend `img/`
3. Gambar akan load dari URL publik

**Option C: Rename File**
1. Jika file gambar punya nama berbeda, rename di spreadsheet column `image`
2. Misal: column `image` isi "berita1-f.jpg" (sesuai nama file di folder img/)
3. Run generator sekali lagi

---

## Masalah 3: Berita1-f Tidak Muncul di News Listing (All News)
**Gejala:** Di halaman news.html, berita1-f tidak ada di daftar "All News" padahal sudah di-search dan di-category filter ketemu.

### Root Cause:
- news.html punya **hardcoded list artikel** (hanya 20+ artikel manual)
- Generated artikel tidak ter-integrasi ke hardcoded list
- Perlu update HTML atau gunakan dynamic loading

### Solusi (Sudah Ter-Fix ✅):
Script **`js/load-news.js`** sudah di-buat untuk:
- Otomatis fetch dari `articles.json`
- Clear hardcoded list
- Render dinamis dari database

**Yang sudah dilakukan:**
1. ✅ Buat `js/load-news.js` dengan logic untuk load articles.json
2. ✅ Add `<script src="js/load-news.js"></script>` ke news.html
3. ✅ Script akan auto-populate newsContainer dengan semua artikel

**Verifikasi:**
1. Refresh `news.html` di browser (Ctrl+F5 untuk clear cache)
2. Buka browser console (F12)
3. Lihat message: `✅ Loaded XX articles from articles.json`
4. Scroll ke bawah di All News → berita1-f harus ada di daftar

---

## Rekap Perbaikan

| Masalah | Penyebab | Status | Solusi |
|---------|---------|--------|--------|
| Search gambar salah | File img/beritaf1.jpg tidak ada | ⏳ Pending User | Upload file ke img/ |
| Category filter gambar salah | File img/beritaf1.jpg tidak ada | ⏳ Pending User | Upload file ke img/ |
| Berita1-f tidak ada di All News | hardcoded list | ✅ FIXED | Added js/load-news.js |

---

## Checklist Untuk User

- [ ] **Upload file gambar ke folder `img/`**
  - Nama file harus match kolom `image` di spreadsheet
  - Misal: spreadsheet isi "beritaf1.jpg" → upload file `img/beritaf1.jpg`

- [ ] **Test di website:**
  - [ ] Buka `news.html` → scroll down → cek berita1-f ada di "All News"
  - [ ] Search "Perhutani KPH Bandung" → berita1-f tampil dengan gambar benar
  - [ ] Footer klik kategori "Lingkungan" → berita1-f tampil dengan gambar benar

---

## Catatan Teknis

### Bagaimana search.html & category filter menampilkan gambar:
```javascript
// search.js line 82-83
img.src = m.image || 'img/berita10.png';
img.onerror = function() {
    this.src = 'img/berita10.png';
};
```
- Grab `image` field dari articles.json
- Jika tidak ada atau error load → fallback ke `berita10.png`

### Bagaimana news.html menampilkan artikel:
```javascript
// js/load-news.js
fetch('/articles.json')
    .then(articles => {
        articles.forEach(article => {
            // render setiap artikel dengan image path dari articles.json
        });
    });
```
- Fetch `articles.json`
- Loop setiap entry
- Render HTML dengan data dari JSON

### Alur Lengkap:
```
Google Sheets (image: "beritaf1.jpg")
    ↓
Generator → articles.json (image: "img/beritaf1.jpg")
    ↓
browser → folder img/beritaf1.jpg ❌ (not found)
    ↓
fallback → img/berita10.png ✓ (exists)
```

**FIX:** Upload file beritaf1.jpg ke folder img/

---

**Updated:** 2026-02-12

