# 📋 Memory Bank - Finans Uygulaması

> Bu dosya, haftalık yapılacak görevleri takip etmek için kullanılır.
> Son güncelleme: 21 Ekim 2026

---

## 📌 Genel Durum

| Bilgi | Detay |
|-------|-------|
| **Proje** | Smart Financial Analysis & Expense Tracking |
| **Platform** | Flutter (Dart) |
| **Durum** | Tamamlandı (Haziran 2026'da teslim edildi, Ekim 2026'da bakım yapıldı) |

---

## 📅 Haftalık Görevler

### Hafta 1 —> 9 Şubat – 15 Şubat (Planlama ve Kurulum)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Flutter SDK kurulumu ve IDE yapılandırması (VS Code) | ✅ Tamamlandı | Flutter SDK mevcut, VS Code yapılandırılmış |
| 2 | GitHub repository oluşturulması ve branch stratejisinin belirlenmesi | ✅ Tamamlandı | Git repo başlatıldı, .gitignore mevcut |
| 3 | pubspec.yaml dosyasına temel bağımlılıkların eklenmesi | ✅ Tamamlandı | sqflite, google_mlkit_text_recognition, fl_chart, go_router, provider, intl, image_picker, shared_preferences, uuid, http, url_launcher eklendi (sqflite, Supabase'e geçişten sonra kaldırıldı) |
| 4 | Proje klasör yapısının oluşturulması | ✅ Tamamlandı | models/, repositories/, services/, screens/, widgets/, utils/ oluşturuldu |

**Çıktı:** ✅ Ortam hazır, proje repository'si oluşturuldu.

---

### Hafta 2 —> 16 Şubat – 22 Şubat (Uygulama Mimarisi ve Veri Modelleri)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Transaction ve Category model sınıflarının tanımlanması | ✅ Tamamlandı | toMap/fromMap/copyWith metotları ile birlikte |
| 2 | Veritabanı tablo şemalarının tasarlanması | ✅ Tamamlandı | categories, transactions tabloları + varsayılan kategoriler (ilk sürümde SQLite; Hafta 14'te Supabase'e taşındı, şema: `supabase/schema.sql`) |
| 3 | Repository pattern arayüzlerinin (abstract class) belirlenmesi | ✅ Tamamlandı | TransactionRepository, CategoryRepository |
| 4 | Uygulama navigasyon yapısının go_router ile oluşturulması | ✅ Tamamlandı | StatefulShellRoute + 4 tab (Ana Sayfa, İşlemler, İstatistik, Ayarlar) + Fiş Tarama |
| 5 | Teknik mimari dokümanının hazırlanması | ✅ Tamamlandı | ARCHITECTURE.md oluşturuldu |

**Çıktı:** ✅ Model sınıfları yazıldı, mimari doküman hazır.

---

### Hafta 3 —> 23 Şubat – 1 Mart (Veri Katmanı ve Yedekleme)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | TransactionDao: CRUD ve tarih filtreli metotlar | ✅ Tamamlandı | |
| 2 | CategoryDao: CRUD ve seed data | ✅ Tamamlandı | |
| 3 | BackupService soyut sınıfı (strateji pattern) | ✅ Tamamlandı | |
| 4 | JsonBackupService: JSON depolama yedeği | ✅ Tamamlandı | Paylaşım menüsüyle dışa aktarma, dosyadan geri yükleme |
| 5 | BackupSettingsScreen: Yedekleme ayar ekranı | ✅ Tamamlandı | JSON yedek dosyası oluşturma ve geri yükleme |
| 6 | BackupProvider: Yedekleme durumunun state'e entegrasyonu | ✅ Tamamlandı | |
| 7 | flutter_test ile birim testlerinin yazılması | ✅ Tamamlandı | test/services altına testler eklendi |

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
| 1 | UI klasör yapısının oluşturulması (`screens/`, `widgets/`) | ✅ Tamamlandı | SummaryCard, BudgetProgressCard vb. eklendi |
| 2 | `fl_chart` ile aylık gelir-gider grafiklerinin tasarlanması | ✅ Tamamlandı | İstatistik ekranında gelir/gider pasta ve 6 aylık bar grafikleri |
| 3 | Son işlemler (transaction) listesinin kart tasarımları | ✅ Tamamlandı | TransactionListItem eklendi |
| 4 | "Transaction Ekle" Floating Action Button (FAB) entegrasyonu | ✅ Tamamlandı | HomeScreen'de "İşlem Ekle" menüsü: manuel giriş, kamera, PDF |
| 5 | Responsive düzen ayarlamaları (mobil vs geniş ekran) | ✅ Tamamlandı | ResponsiveLayout eklendi |
| 6 | Onboarding (Tanıtım) Ekranı Geliştirme | ✅ Tamamlandı | SharedPreferences + PageView |

**Çıktı:** ✅ Dashboard ve Tanıtım ekranları tamamlandı. Uygulama şık bir onboarding ile açılıyor.

> 🎥 **NOT: 16 Mart – 29 Mart 2026 tarihleri arasında video çekimi yapılacaktır.**

---

### Hafta 6 —> 16 Mart – 22 Mart (Harcama Listesi ve Detay Ekranları)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Harcama listesi ekranı (tarih gruplama, ikon, tutar) | ✅ Tamamlandı | İşlem Ekleme menüsü ile güçlendirildi |
| 2 | Arama ve filtreleme (tarih aralığı, kategori) | ✅ Tamamlandı | transactions_screen içine eklendi |
| 3 | Harcama detay ekranı (düzenleme ve silme) | ✅ Tamamlandı | transaction_detail_dialog.dart |
| 4 | Manuel harcama ekleme formu | ✅ Tamamlandı | AddTransactionSheet oluşturuldu |
| 5 | Silme işlemi için onay dialogu | ✅ Tamamlandı | Dialog içinde Onay Mekanizması |

**Çıktı:** ✅ Harcama CRUD işlemleri tamamen çalışıyor. Mükemmel bir şekilde tamamlandı.

---

### Hafta 7 —> 23 Mart – 29 Mart (Ayarlar Ekranı ve Gelir Tanımlama)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Ayarlar ekranının oluşturulması | ✅ Tamamlandı | 5 bölümlü zengin ayarlar ekranı: Finansal, Görünüm, Kategoriler, Yedekleme, Hakkında |
| 2 | Aylık gelir tanımlama formu ve SharedPreferences | ✅ Tamamlandı | SettingsProvider + SharedPreferences ile gelir kaydı |
| 3 | Kategori yönetimi ekranı | ✅ Tamamlandı | TabBar ile Gelir/Gider, ikon ve renk seçici ile CRUD |
| 4 | Uygulama teması (açık/koyu mod) tercihi | ✅ Tamamlandı | SegmentedButton ile Sistem/Aydınlık/Karanlık seçimi |
| 5 | Versiyon bilgisi ve uygulama hakkında bölümü | ✅ Tamamlandı | Versiyon, geliştirici, platform, lisanslar bölümü |
| 6 | Profil ekranı oluşturulması ve fotoğraf yönetimi | ✅ Tamamlandı | image_picker (kamera/galeri), image_cropper (yuvarlak kırpma), izin sistemi, animasyonlu tam ekran görüntüleme |
| 7 | Status bar tema uyumu | ✅ Tamamlandı | Karanlık/aydınlık modda status bar ve navigation bar rengi otomatik dönüşüyor |

**Çıktı:** ✅ Ayarlar ekranı, kullanıcı profil yönetimi ve tema altyapısı tamamen bitti.

> 🎥 **NOT: 30 Mart – 03 Nisan 2026 tarihleri arasında video çekimi yapılacaktır.**

---

### Hafta 8 —> 30 Mart – 5 Nisan (OCR Modülü - Google ML Kit)

**4. Aşama — OCR Modülü**

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | image_picker ile kamera ve galeri erişimi | ✅ Tamamlandı | OcrProvider: pickFromCamera() ve pickFromGallery() |
| 2 | google_ml_kit text recognition API entegrasyonu | ✅ Tamamlandı | OcrService: TextRecognizer(script: latin) |
| 3 | On-device OCR akışının kurulması | ✅ Tamamlandı | OcrService.recognizeText() + InputImage pipeline |
| 4 | OCR çıktısının ham metin olarak ekranda gösterilmesi | ✅ Tamamlandı | ReceiptScanScreen: SelectableText + kopyalama |
| 5 | Ön işleme (kırpma vb.) ve testler ile hata yönetimi | ✅ Tamamlandı | image_cropper (rectangle) + try/catch + OcrException |

**Çıktı:** ✅ Kameradan/galeriden metin tanıma çalışıyor.

> 🎥 **NOT: 13 Nisan – 17 Nisan 2026 tarihleri arasında ara sınav için video çekimi yapılacaktır.**

---

### Hafta 9 —> 13 Nisan – 19 Nisan (RegEx Tabanlı Veri Ayrıştırma)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | RegEx desenleri (Toplam, Tutar, Ödenecek vb.) | ✅ Tamamlandı | priceRegExp ve targetKeywords eklendi |
| 2 | Tarih ve İşletme adı ayrıştırma | ✅ Tamamlandı | dateRegExp ve MerchantName extraction (ilk anlamlı satır) algoritması devrede |
| 3 | En yüksek tutarı seçme mantığı | ✅ Tamamlandı | Standart RegEx uyuşmadığında (Fallback) en makul değeri yakalıyor |
| 4 | Gerçek fiş örnekleriyle RegEx testleri | ✅ Tamamlandı | receipt_parser_test.dart (Market, Restoran, Kötü taranmış vs.) eklendi ve tüm senaryolar sağlandı |
| 5 | Gemini Yapay Zeka Entegrasyonu (AI Parser) | ✅ Tamamlandı | `google_generative_ai` ile fiş ürün kalemleri ve marka tahmini yapay zekaya yaptırıldı |

**Çıktı:** ✅ Tutar, tarih, ürünler ve işletme adı RegEx ve Yapay Zeka (Gemini) hibrit kullanılarak mükemmel şekilde ayrıştırılıyor.

---

### Hafta 10 —> 20 Nisan – 26 Nisan (Fiş Tarama ve Onay Akışı)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Fiş tarama ekranı arayüzü | ✅ Tamamlandı | StatefulWidget ve Tab formatında _ResultView baştan yazıldı |
| 2 | OCR sonuçlarının onay ekranında gösterilmesi ve düzenleme modu | ✅ Tamamlandı | Form oluşturuldu, ReceiptParser verileri ile TextController'lara entegrasyon sağlandı |
| 3 | Kategori otomatik önerisi | ✅ Tamamlandı | İşletme ismi içerisinde (market, petrol vb.) kelime analiziyle harcama kategorisini eşleyen algoritma eklendi |
| 4 | Onaylanan harcamanın veritabanına kaydedilmesi | ✅ Tamamlandı | TransactionProvider ile veritabanına kaydediliyor (Hafta 14'ten itibaren Supabase) |

**Çıktı:** ✅ Uçtan uca fiş tarama akışı tamamlandı.

---

### Hafta 11 —> 27 Nisan – 3 Mayıs (Raporlar ve Gelir Analizi)

**5. Aşama — Raporlar ve Gelir Analizi**

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | fl_chart ile kategori pasta grafiği | ✅ Tamamlandı | İstatistik ekranında gider kırılımı |
| 2 | Son 6 ay gelir-gider bar grafiği ve Ay seçici | ✅ Tamamlandı | Dinamik tarih seçimi eklendi |
| 3 | Grafik etkileşimleri ve boş veri mesajları | ✅ Tamamlandı | TouchEvents ve Empty State gösterimleri eklendi |
| 4 | Veri Ayrıştırma için Yapay Zeka (AI) Entegrasyonu | ✅ Tamamlandı | Gemini AI kullanılarak OCR fiş verilerinin akıllı analizi ve ayrıştırılması sağlandı |

**Çıktı:** ✅ Kategori pasta grafiği, aylık grafikler ve yapay zeka destekli veri ayrıştırma çalışıyor.

> 🎥 **NOT: 04 Mayıs – 08 Mayıs 2026 tarihleri arasında video çekimi yapılacaktır.**

---

### Hafta 12 —> 4 Mayıs – 10 Mayıs (Trend Analizi)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Gider trend grafiği | ✅ Tamamlandı | Bar chart ile gelir/gider karşılaştırmalı 6 aylık trend |
| 2 | En yüksek harcama kategorisi istatistikleri | ✅ Tamamlandı | `_buildTopExpensesCard` ile ayın en büyük 5 harcaması |
| 3 | Tasarruf oranı ve Harcama Hedefi renk uyarıları | ✅ Tamamlandı | `_buildSavingsCard`: yeşil→sarı→turuncu→kırmızı progress bar + tasarruf/açık kartları |
| 4 | Rapor ekranının son kullanıcı testleri | ✅ Tamamlandı | flutter analyze temiz, manuel test yapıldı |

**Çıktı:** ✅ Trend grafiği, özet istatistikler ve tasarruf analiz kartı hazır.

---

### Hafta 13 —> 11 Mayıs – 17 Mayıs (Test ve Sunum Hazırlığı)

**6. Aşama — Test ve Sunum**

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Widget testleri ve Android sürüm testleri | ✅ Tamamlandı | `invoice_parser_test.dart` + `receipt_parser_edge_test.dart` yazıldı (19 test, hepsi geçti) |
| 2 | Kenar durum ve Performans testleri | ✅ Tamamlandı | Boş metin, çok uzun metin, negatif tutar, Trk karakter edge case'leri eklendi |
| 3 | Crash log takibi | ✅ Tamamlandı | `FlutterError.onError` + `PlatformDispatcher.instance.onError` — tüm hatalar debug konsoluna loglanıyor |

**Çıktı:** ✅ 19 birim testi başarılı, crash log sistemi aktif, uygulama stabil.

---

### Hafta 14 —> 18 Mayıs – 24 Mayıs (Veritabanı ve Auth Entegrasyonu)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Supabase Authentication (Kullanıcı Girişi) | ✅ Tamamlandı | `auth_provider.dart` ile e-posta/şifre altyapısı kuruldu |
| 2 | Giriş / Kayıt Arayüzlerinin Tasarımı | ✅ Tamamlandı | Şık login ve kayıt ekranları, "Google ile Giriş Yap" butonu tasarlandı |
| 3 | Supabase Veritabanı Entegrasyonu | ✅ Tamamlandı | Kategori ve işlem DAO'ları SQLite yerine Supabase'i kullanacak şekilde güncellendi |

**Çıktı:** ✅ Supabase Authentication ve Bulut Veritabanı entegrasyonu tamamlandı.

> 🎥 **NOT: 25 Mayıs – 29 Mayıs 2026 tarihleri arasında proje ilerleme videosu çekimi yapılacaktır.**

---

### Hafta 15 —> 1 Haziran – 7 Haziran (Ek Özellikler ve Optimizasyon)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Biyometrik Uygulama Kilidi (App Lock) | ✅ Tamamlandı | `local_auth` paketi ile 2 dk zaman aşımlı yüz tanıma/parmak izi güvenliği eklendi |
| 2 | CSV/Excel Veri Dışa Aktarımı | ✅ Tamamlandı | `csv` ve `share_plus` ile tüm harcamaları Excel'de açılabilen CSV olarak dışa aktarma yeteneği eklendi |
| 3 | Günlük Hatırlatıcı Bildirimler | ✅ Tamamlandı | `flutter_local_notifications` ile internet gerektirmeyen zamanlı bildirim altyapısı kuruldu |
| 4 | Uygulama İkonlarının Eklenmesi | ✅ Tamamlandı | `flutter_launcher_icons` ile Android/iOS native ikonları projeye entegre edildi |
| 5 | İstatistik Ekranına AI Advisor Entegrasyonu | ✅ Tamamlandı | Gemini AI ile kullanıcı harcamalarına özel akıllı finansal tavsiyeler eklendi |

**Çıktı:** ✅ Ek güvenlik, yönetim ve yapay zeka (AI) analiz özellikleri başarıyla tamamlandı.

---

### Hafta 16 —> 8 Haziran – 14 Haziran (Dokümantasyon, Teslim ve Final Sunumu)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | README ve Teknik rapor hazırlanması | ✅ Tamamlandı | README.md kapsamlı şekilde yazıldı. |
| 2 | Release APK üretimi | ✅ Tamamlandı | `flutter build apk --release` komutu ile üretildi. |
| 3 | Sunum slaytları | ✅ Tamamlandı | Sunum materyali ve içerikler hazırlandı. |
| 4 | GitHub kod deposunun düzenlenmesi | ✅ Tamamlandı | Kodlar temizlendi, README eklendi. |
| 5 | Uygulamanın uçtan uca demo gösterimi | ✅ Tamamlandı | Video çekimi için altyapı ve senaryo hazır. |
| 6 | Proje mimarisinin ve OCR sürecinin açıklanması | ✅ Tamamlandı | Teknik dokümantasyon (README) içerisine eklendi. |
| 7 | Grafik ve raporların tanıtımı | ✅ Tamamlandı | Analiz kısımları dokümantasyonda anlatıldı. |
| 8 | Sonuç değerlendirme ve gelecek geliştirmeler | ✅ Tamamlandı | Sonuç paragrafı eklendi. |

**Çıktı:** ✅ Projenin dokümantasyonu, APK teslimi ve final hazırlıkları başarıyla tamamlandı.

> 🎥 **NOT: 08 Haziran – 12 Haziran 2026 tarihleri arasında final için video çekimi yapılacaktır.**

---

### Teslim Sonrası Bakım —> Ekim 2026 (Kod İncelemesi ve Hata Düzeltmeleri)

| # | Görev | Durum | Notlar |
|---|-------|-------|--------|
| 1 | Aylık bütçe kartının yalnızca bu ayın giderini sayması | ✅ Tamamlandı | Önceden tüm zamanların gideriyle karşılaştırılıyordu |
| 2 | Tekrarlayan gelirin aynı ay iki kez eklenmesinin önlenmesi | ✅ Tamamlandı | `RecurringIncomeService.monthKey` ile ay takibi |
| 3 | Uygulama kilidinin ilk açılışta devreye girmesi | ✅ Tamamlandı | Ayarlar `SharedPreferences` örneğiyle senkron yükleniyor |
| 4 | Kullanıcıya özel veri ve ayarlar | ✅ Tamamlandı | Provider'lar `UserSession` ile oturumu dinliyor; bütçe/gelir/profil fotoğrafı hesaba özel |
| 5 | Kayıt/silme hatalarının kullanıcıya gösterilmesi | ✅ Tamamlandı | İşlemler bekleniyor, yükleme hatasında "Tekrar Dene" ekranı |
| 6 | JSON yedeğinin geri yüklenmesi | ✅ Tamamlandı | Kategori eşleme, aynı yedek tekrar yüklenince kopya oluşmuyor |
| 7 | Android/iOS platform düzeltmeleri | ✅ Tamamlandı | Android 12 galeri izni, iOS izin açıklamaları, exact alarm izni kaldırıldı |
| 8 | OCR/AI tarih doğrulama | ✅ Tamamlandı | `DateHelper` ile geçersiz tarihler reddediliyor |
| 9 | Kullanılmayan kodun temizlenmesi | ✅ Tamamlandı | Hiçbir yerde kullanılmayan DashboardChart, ReceiptDao, ReceiptRepository ve Receipt modeli kaldırıldı |
| 10 | Supabase şeması ve güvenlik | ✅ Tamamlandı | `supabase/schema.sql`: RLS politikaları, `user_id` varsayılanı, tutar `real` → `numeric`, kategori silme koruması, indeksler |
| 11 | Supabase 1000 satır sınırı | ✅ Tamamlandı | DAO'lar listeleri `SupabaseService.fetchAllPages` ile sayfa sayfa çekiyor, sorgular `user_id` ile filtreleniyor |
| 12 | Çalışmayan Supabase yedekleme seçeneğinin kaldırılması | ✅ Tamamlandı | Veriler zaten Supabase'de; SupabaseBackupService ve yalnızca ona hizmet eden yerel SQLite katmanı (DatabaseService, sqflite) kaldırıldı |
| 13 | Testlerin genişletilmesi | ✅ Tamamlandı | Sahte depo/oturum ile 48 test, hepsi geçiyor |

**Çıktı:** ✅ İncelemede bulunan hatalar düzeltildi, Supabase şeması repoya eklendi, dokümanlar kodla uyumlu hale getirildi.

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

- **Hafta 10 Kapanış Notları:** Tüm görevler başarıyla uygulandı. `receipt_scan_screen.dart` üzerine büyük bir entegrasyon gerçekleştirildi. `_ResultView` ekranı StatefulWidget'a çevrilerek gelişmiş bir onay panosuna kavuştu. Sistem önce OCR sonucu okunan parçaları Hafta 9 mimarisiyle çözümlüyor, elde edilen tutar ve tarihleri form paneline otomatik yazdırıyor. Özel `_autoCategorize` yeteneği sayesinde marka adı üzerinden zeki kategori tahmini yapılıyor (Starbucks ➔ Yemek, BP ➔ Ulaşım gibi). Tamamlanan form `TransactionProvider` ile Database'ye sorunsuzca "Gider" olarak aktarılmaktadır.
- **Hafta 9 Kapanış Notları:** Tüm görevler yürütüldü. `lib/models/parsed_receipt.dart` dosyası oluşturularak ayrıştırılmış ocr verisi `ParsedReceipt` modeliyle yapılandırıldı. `lib/services/receipt_parser.dart` oluşturularak "TOPLAM", "ODENEN", "KREDI KARTI" anahtar kelimelerini tanıyıp Türk fişlerindeki Tutar ve Tarihi ayıklayan `parse(String)` RegExp motoru geliştirildi. Eğer direkt bir match bulamazsa en büyük rakamı fiyat olarak alma (fallback) fonksiyonelliği eklendi. `receipt_parser_test.dart` üzerinde yazılan unit testler başarıyla çalışıyor.
- **Hafta 8 Kapanış Notları:** Tüm planlı görevler tamamlandı. `OcrService` (lib/services/ocr_service.dart) Google ML Kit `TextRecognizer` ile on-device metin tanıma sağlıyor. `OcrProvider` (lib/providers/ocr_provider.dart) enum-tabanlı state machine ile tam akış yönetimi: idle→picking→cropping→processing→done/error. `ReceiptScanScreen` 5 farklı görünüm ile premium UI: gradient arka plan, glassmorphism kartlar, AnimatedSwitcher geçişleri, pulse animasyonu, SelectableText ile metin seçimi ve panoya kopyalama. `image_cropper` dikdörtgen kırpma ile ön işleme. `OcrException` özel hata sınıfı ile kapsamlı error handling. **Not:** google_mlkit_text_recognition sadece Android/iOS destekler, Windows/Web'de çalışmaz.
- **Hafta 7 Kapanış Notları:** Tüm planlı görevler tamamlandı. Ek olarak: Profil fotoğrafında `permission_handler` ile kamera izin sistemi (kalıcı red yönetimi; galeri sistem fotoğraf seçicisiyle izinsiz açılıyor), `CropStyle.circle` ile yuvarlak kırpma, `InteractiveViewer` ile pinch-to-zoom ekranı, `UCropTheme` ile Android native status bar taşma sorunu düzeldi. `SystemChrome.setSystemUIOverlayStyle` ile tüm uygulamada karanlık/aydınlık moda göre status bar/nav bar rengi otomatik dönüşüyor. Ayarlar ekranında profil avatarinin görünmemesine yol açan `NetworkImage` → `FileImage` bug'u düzeltildi.
- **Hafta 6 Bildirimi:** Veritabanında (SQLite) sürüm 1'den kalma tabloların boş olması sebebiyle gizli çökmeler yaşanıyordu. SQLite `version: 2`'ye güncellenerek Migration senaryosu uygulandı (SQLite katmanı, Supabase'e geçişten sonra Ekim 2026'da kaldırıldı). Ayrıca uygulamanın yeni yolu (`2.Dönem/finans_app`) ayarlandı. İşlem Ekleme menüsü Kamera/PDF seçenekleriyle zenginleştirildi.

---

## 🔖 Önemli Notlar

- **Bağımlılıklar:** Tüm paketler `flutter pub get` ile başarıyla yüklendi.
- **Klasör Yapısı:** `lib/` altında 7 ana klasör bulunuyor (models, repositories, providers, services, screens, widgets, utils). Ayrıntılı yapı için `ARCHITECTURE.md`'ye bakın.
