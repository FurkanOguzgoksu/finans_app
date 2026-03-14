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
