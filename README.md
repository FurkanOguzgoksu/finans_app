# 📊 Smart Financial Analysis & Automatic Expense Tracking System

Smart Financial Analysis, kullanıcıların kişisel finans yönetimini kolaylaştırmak, harcamalarını grafiklerle analiz etmek ve özellikle fiziksel fiş/faturaları OCR (Yapay Zeka) destekli metin tanıma teknolojisi ile dijital ortama saniyeler içinde aktarmak için geliştirilmiş gelişmiş bir mobil uygulamadır.

## ✨ Temel Özellikler

- **📸 Akıllı Fiş Tarama (OCR):** Google ML Kit ve Gemini AI ile kamera veya galeriden seçilen fişlerdeki toplam tutar, tarih ve marka bilgisini saniyeler içinde ayıklar.
- **☁️ Bulut Senkronizasyonu & Güvenlik:** Supabase entegrasyonu ile cihazlar arası güvenli veri eşitleme. E-posta/şifre girişi ve App Lock (Biyometrik Yüz/Parmak İzi kilidi).
- **📈 Kapsamlı Analiz, Grafikler ve AI Danışman:** `fl_chart` kullanılarak hazırlanan pasta (gider kırılımı), bar (aylık karşılaştırma) ve çizgi (trend) grafikleri. Tasarruf uyarıları ve Gemini AI destekli kişiselleştirilmiş finansal tavsiyeler (AI Advisor).
- **📤 Veri Dışa Aktarımı:** Tüm harcama geçmişini CSV veya Excel formatında tek tıkla dışa aktarabilme.
- **🔔 Hatırlatıcılar:** Günlük harcama girişi için yerel bildirim altyapısı.
- **🎨 Modern Arayüz:** Karanlık/Aydınlık tema desteği, cam efekti (glassmorphism) tasarımlar ve akıcı animasyonlar.

## 🏗️ Mimari Yapı ve Katmanlar

Proje kod yapısı ayrık katmanlı bir mimari (Layered Architecture) etrafında şekillenmiştir:
- **UI (Arayüz):** Ekranlar (`screens/`) ve yeniden kullanılabilir bileşenler (`widgets/`).
- **State Management:** `provider` tabanlı reaktif yapı. Veri değiştiğinde sadece ilgili arayüz güncellenir (`providers/`).
- **Services (İş Mantığı & Servisler):** Dış dünyaya veya donanıma erişen modüller. (`ocr_service`, `supabase_service`, `database_service`).
- **Veri Katmanı (DAO & SQLite):** Veritabanı okuma/yazma işlemleri Data Access Object pattern'i ile soyutlanmıştır.

## 🔍 OCR ve Veri Ayrıştırma Akışı

Fiziksel fişlerin dijitale dönüştürülme süreci 4 aşamadan oluşur:
1. **Görsel Seçimi:** Kullanıcı kameradan fişi çeker veya galeriden seçer (`image_picker`). Gerekirse kenarlar kırpılır (`image_cropper`).
2. **Metin Tanıma (OCR):** Görsel cihaz içinde, internetsiz olarak Google ML Kit `TextRecognizer` modeline verilir ve ham metin (String) elde edilir.
3. **Ayrıştırma (Regex & AI):** Özel geliştirilmiş Regex algoritmaları ve Gemini AI entegrasyonu sayesinde ham metin taranır. "TOPLAM", "Tarih", İşletme adı (ilk satırlar) bulunur. Akıllı eşleştirme ile kahve markaları yemeğe, benzin istasyonları ulaşıma atanır.
4. **Onay ve Kayıt:** Ayrıştırılmış veri kullanıcıya sunulur. Kullanıcı eksikleri tamamlar veya düzenler, SQLite ve Supabase'e kaydedilir.

## 🚀 Kurulum

1. **Flutter SDK**'nın güncel versiyonunun bilgisayarınızda kurulu olduğundan emin olun (`>=3.8.1`).
2. Projeyi klonlayın: `git clone https://github.com/kullaniciadi/finans_app.git`
3. Bağımlılıkları yükleyin:
   ```bash
   flutter pub get
   ```
4. Uygulamayı çalıştırın:
   ```bash
   flutter run
   ```

## 📦 Sürüm (Release) APK Alma

Android cihazlar için optimize edilmiş (küçültülmüş ve obfuscate edilmiş) kurulum paketini almak için terminalde şu komutu çalıştırın:
```bash
flutter build apk --release
```
*Üretilen APK dosyası projenin `build/app/outputs/flutter-apk/app-release.apk` dizininde yer alacaktır.*

## 🔮 Sonuç Değerlendirmesi ve Gelecek Geliştirmeler

Bu proje, akademik bir çalışmadan çıkarak son kullanıcıya doğrudan fayda sağlayacak, uçtan uca çalışır (production-ready) bir ürün haline gelmiştir. Karşılaşılan OCR hataları Regex "fallback" mantığı ile en aza indirilmiş, veri bütünlüğü Supabase ile sağlanmıştır.
**Gelecekte Eklenebilecekler:**
- **Çoklu Para Birimi:** Canlı kur çevirisi ile yurtdışı harcamalarının entegrasyonu.
- **Paylaşımlı Bütçe:** Aile veya ev arkadaşları için ortak harcama havuzları.
- **Fatura Taraması:** Fişlerin yanı sıra A4 fatura okuma kabiliyetinin gelişmiş PDF ayrıştırma ile sağlanması.
