# 📋 Memory Bank - Finans Uygulaması

> Bu dosya, haftalık yapılacak görevleri takip etmek için kullanılır.
> Son güncelleme: 14 Mart 2026

---

## 📌 Genel Durum

| Bilgi | Detay |
|-------|-------|
| **Proje** | Smart Financial Analysis & Expense Tracking |
| **Platform** | Flutter (Dart) |
| **Durum** | Aktif Geliştirme |

---

## 📅 Haftalık Görevler

### Hafta 1 —> 9 Şubat – 15 Şubat (Planlama ve Kurulum)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Flutter SDK kurulumu ve IDE yapılandırması (VS Code) | ✅ Tamamlandı | Flutter SDK mevcut, VS Code yapılandırılmış |
| 2 | GitHub repository oluşturulması ve branch stratejisinin belirlenmesi | ✅ Tamamlandı | Git repo başlatıldı, .gitignore mevcut |
| 3 | pubspec.yaml dosyasına temel bağımlılıkların eklenmesi | ✅ Tamamlandı | sqflite, google_mlkit_text_recognition, fl_chart, go_router, provider, intl, image_picker, shared_preferences, uuid, http, url_launcher eklendi |
| 4 | Proje klasör yapısının oluşturulması | ✅ Tamamlandı | models/, repositories/, services/, screens/, widgets/, utils/ oluşturuldu |

**Çıktı:** ✅ Ortam hazır, proje repository'si oluşturuldu.

---

### Hafta 2 —> 16 Şubat – 22 Şubat (Uygulama Mimarisi ve Veri Modelleri)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Transaction, Category ve Receipt model sınıflarının tanımlanması | ✅ Tamamlandı | toMap/fromMap/copyWith metotları ile birlikte |
| 2 | SQLite tablo şemalarının (CREATE TABLE) tasarlanması | ✅ Tamamlandı | categories, transactions, receipts tabloları + varsayılan kategoriler |
| 3 | Repository pattern arayüzlerinin (abstract class) belirlenmesi | ✅ Tamamlandı | TransactionRepository, CategoryRepository, ReceiptRepository |
| 4 | Uygulama navigasyon yapısının go_router ile oluşturulması | ✅ Tamamlandı | StatefulShellRoute + 4 tab (Ana Sayfa, İşlemler, İstatistik, Ayarlar) + Fiş Tarama |
| 5 | Teknik mimari dokümanının hazırlanması | ✅ Tamamlandı | ARCHITECTURE.md oluşturuldu |

**Çıktı:** ✅ Model sınıfları yazıldı, mimari doküman hazır.

---

### Hafta 3 —> 23 Şubat – 1 Mart (Veri Katmanı ve Yedekleme)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | DatabaseHelper singleton sınıfı ve migration yönetimi | ✅ Tamamlandı | |
| 2 | TransactionDao: CRUD ve tarih filtreli metotlar | ✅ Tamamlandı | |
| 3 | CategoryDao: CRUD ve seed data | ✅ Tamamlandı | |
| 4 | ReceiptDao: OCR için ham fiş kaydı | ✅ Tamamlandı | |
| 5 | BackupService soyut sınıfı (strateji pattern) | ✅ Tamamlandı | |
| 6 | JsonBackupService: JSON depolama yedeği | ✅ Tamamlandı | |
| 7 | FirebaseBackupService: Firestore senkronizasyonu | ✅ Tamamlandı | |
| 8 | BackupSettingsScreen: JSON veya Firebase yedekleme ayar ekranı | ✅ Tamamlandı | |
| 9 | BackupProvider: Yedekleme durumunun state'e entegrasyonu | ✅ Tamamlandı | |
| 10 | flutter_test ile birim testlerinin yazılması | ✅ Tamamlandı | test/services altına testler eklendi |

**Çıktı:** ✅ CRUD işlemleri çalışıyor, birim testleri başarılı.

### Hafta 4 —> 2 Mart – 8 Mart (Provider / State Management)

**2. Aşamanın Devamı**

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Provider veya Riverpod paketi ile global state yapısının kurulması | ✅ Tamamlandı | Provider kullanıldı |
| 2 | TransactionProvider: harcama listesi state yönetimi | ✅ Tamamlandı | lib/providers/ eklendi |
| 3 | CategoryProvider: kategori listesi state yönetimi | ✅ Tamamlandı | lib/providers/ eklendi |
| 4 | Mock veri ile state akışının doğrulanması | ✅ Tamamlandı | home_screen üzerinden test edildi |
| 5 | ChangeNotifier pattern ile UI'ın reaktif güncellenmesinin test edilmesi | ✅ Tamamlandı | |

**Çıktı:** ✅ State yönetimi çalışıyor, ekranlar mock veri ile beslenebiliyor.

---

### Hafta 5 —> 9 Mart – 15 Mart (UI Geliştirme - Dashboard)

**3. Aşama — UI Geliştirme**

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Aylık gelir-gider özet kartının tasarlanması | ⬜ Bekliyor | |
| 2 | Son 5 harcamanın listelendiği mini liste oluşturulması | ⬜ Bekliyor | |
| 3 | Bütçe doluluk oranı progress bar bileşeni | ⬜ Bekliyor | |
| 4 | BottomNavigationBar ile sekmeler arası navigasyon | ⬜ Bekliyor | Mevcut placeholder |
| 5 | Responsive tasarım kontrolü | ⬜ Bekliyor | |

**Çıktı:** ⬜ Dashboard ekranı gerçek verilerle çalışıyor.

> 🎥 **NOT: 16 Mart – 29 Mart 2026 tarihleri arasında video çekimi yapılacaktır.**

---

### Hafta 6 —> 16 Mart – 22 Mart (Harcama Listesi ve Detay Ekranları)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Harcama listesi ekranı (tarih gruplama, ikon, tutar) | ⬜ Bekliyor | |
| 2 | Arama ve filtreleme (tarih aralığı, kategori) | ⬜ Bekliyor | |
| 3 | Harcama detay ekranı (düzenleme ve silme) | ⬜ Bekliyor | |
| 4 | Manuel harcama ekleme formu | ⬜ Bekliyor | |
| 5 | Silme işlemi için onay dialogu | ⬜ Bekliyor | |

**Çıktı:** ⬜ Harcama CRUD işlemleri tamamen çalışıyor.

---

### Hafta 7 —> 23 Mart – 29 Mart (Ayarlar Ekranı ve Gelir Tanımlama)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Ayarlar ekranının oluşturulması | ⬜ Bekliyor | |
| 2 | Aylık gelir tanımlama formu ve SharedPreferences | ⬜ Bekliyor | |
| 3 | Kategori yönetimi ekranı | ⬜ Bekliyor | |
| 4 | Uygulama teması (açık/koyu mod) tercihi | ⬜ Bekliyor | Kısmen başladı |
| 5 | Versiyon bilgisi ve uygulama hakkında bölümü | ⬜ Bekliyor | |

**Çıktı:** ⬜ Kullanıcı aylık gelirini tanımlayabiliyor.

> 🎥 **NOT: 30 Mart – 03 Nisan 2026 tarihleri arasında video çekimi yapılacaktır.**

---

### Hafta 8 —> 30 Mart – 5 Nisan (OCR Modülü - Google ML Kit)

**4. Aşama — OCR Modülü**

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | image_picker ile kamera ve galeri erişimi | ⬜ Bekliyor | |
| 2 | google_ml_kit text recognition API entegrasyonu | ⬜ Bekliyor | |
| 3 | On-device OCR akışının kurulması | ⬜ Bekliyor | |
| 4 | OCR çıktısının ham metin olarak ekranda gösterilmesi | ⬜ Bekliyor | |
| 5 | Ön işleme (kırpma vb.) ve testler ile hata yönetimi | ⬜ Bekliyor | |

**Çıktı:** ⬜ Kameradan/galeriden metin tanıma çalışıyor.

> 🎥 **NOT: 13 Nisan – 17 Nisan 2026 tarihleri arasında ara sınav için video çekimi yapılacaktır.**

---

### Hafta 9 —> 13 Nisan – 19 Nisan (RegEx Tabanlı Veri Ayrıştırma)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | RegEx desenleri (Toplam, Tutar, Ödenecek vb.) | ⬜ Bekliyor | |
| 2 | Tarih ve İşletme adı ayrıştırma | ⬜ Bekliyor | |
| 3 | En yüksek tutarı seçme mantığı | ⬜ Bekliyor | |
| 4 | Gerçek fiş örnekleriyle RegEx testleri | ⬜ Bekliyor | |

**Çıktı:** ⬜ Tutar, tarih ve işletme adı otomatik ayrıştırılıyor.

---

### Hafta 10 —> 20 Nisan – 26 Nisan (Fiş Tarama ve Onay Akışı)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Fiş tarama ekranı arayüzü | ⬜ Bekliyor | |
| 2 | OCR sonuçlarının onay ekranında gösterilmesi ve düzenleme modu | ⬜ Bekliyor | |
| 3 | Kategori otomatik önerisi | ⬜ Bekliyor | |
| 4 | Onaylanan harcamanın veritabanına kaydedilmesi | ⬜ Bekliyor | |

**Çıktı:** ⬜ Uçtan uca fiş tarama akışı tamamlandı.

---

### Hafta 11 —> 27 Nisan – 3 Mayıs (Raporlar ve Gelir Analizi)

**5. Aşama — Raporlar ve Gelir Analizi**

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | fl_chart ile kategori pasta grafiği | ⬜ Bekliyor | |
| 2 | Son 6 ay gelir-gider bar grafiği ve Ay seçici | ⬜ Bekliyor | |
| 3 | Grafik etkileşimleri ve boş veri mesajları | ⬜ Bekliyor | |

**Çıktı:** ⬜ Kategori pasta grafiği ve aylık grafikler çalışıyor.

> 🎥 **NOT: 04 Mayıs – 08 Mayıs 2026 tarihleri arasında video çekimi yapılacaktır.**

---

### Hafta 12 —> 4 Mayıs – 10 Mayıs (Trend Analizi)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | LineChart ile gider trend grafiği | ⬜ Bekliyor | |
| 2 | En yüksek harcama kategorisi istatistikleri | ⬜ Bekliyor | |
| 3 | Tasarruf oranı ve Harcama Hedefi renk uyarıları | ⬜ Bekliyor | |
| 4 | Rapor ekranının son kullanıcı testleri | ⬜ Bekliyor | |

**Çıktı:** ⬜ Trend grafiği ve özet istatistikler hazır.

---

### Hafta 13 —> 11 Mayıs – 17 Mayıs (Test ve Sunum Hazırlığı)

**6. Aşama — Test ve Sunum**

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Widget testleri ve Android sürüm testleri | ⬜ Bekliyor | |
| 2 | Kenar durum ve Performans testleri | ⬜ Bekliyor | |
| 3 | Crash log takibi | ⬜ Bekliyor | |

**Çıktı:** ⬜ Kritik hatalar giderildi, uygulama stabil.

---

### Hafta 14 —> 18 Mayıs – 24 Mayıs (Dokümantasyon ve Teslim Hazırlığı)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | README ve Teknik rapor hazırlanması | ⬜ Bekliyor | |
| 2 | Release APK üretimi | ⬜ Bekliyor | |
| 3 | Sunum slaytları | ⬜ Bekliyor | |
| 4 | GitHub kod deposunun düzenlenmesi | ⬜ Bekliyor | |

**Çıktı:** ⬜ Release APK hazır, teknik rapor ve sunum tamamlandı.

> 🎥 **NOT: 25 Mayıs – 29 Mayıs 2026 tarihleri arasında proje ilerleme videosu çekimi yapılacaktır.**

---

### Hafta 15 —> 1 Haziran – 7 Haziran (Final Proje Demosu ve Değerlendirme)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Uygulamanın uçtan uca demo gösterimi | ⬜ Bekliyor | |
| 2 | Proje mimarisinin ve OCR sürecinin açıklanması | ⬜ Bekliyor | |
| 3 | Grafik ve raporların tanıtımı | ⬜ Bekliyor | |
| 4 | Sonuç değerlendirme ve gelecek geliştirmeler | ⬜ Bekliyor | |

**Çıktı:** ⬜ Projenin final demosu ve değerlendirme sunumu tamamlandı.

> 🎥 **NOT: 08 Haziran – 12 Haziran 2026 tarihleri arasında final için video çekimi yapılacaktır.**

---

<!--
Durum Emojileri:
⬜ Bekliyor
🔄 Devam Ediyor
✅ Tamamlandı
❌ İptal Edildi
⏸️ Beklemede
-->

---

## 📝 Geçmiş Hafta Notları

_Henüz geçmiş hafta notu yok._

---

## 🔖 Önemli Notlar

- **Bağımlılıklar:** Tüm paketler `flutter pub get` ile başarıyla yüklendi.
- **Klasör Yapısı:** `lib/` altında 6 ana klasör oluşturuldu (models, repositories, services, screens, widgets, utils).
