# 🏗️ Teknik Mimari Dokümanı - Finans Takip Uygulaması

## Genel Bakış

**Proje Adı:** Akıllı Finansal Analiz ve Otomatik Harcama Takip Sistemi  
**Platform:** Flutter (Dart)  
**Mimari Yaklaşım:** Repository Pattern + Provider State Management  
**Veri Kaynağı:** Supabase (PostgreSQL + Authentication)

---

## Katmanlı Mimari

```
┌───────────────────────────────────────────────┐
│            UI Katmanı (Screens/Widgets)       │
│  home / transactions / statistics / settings  │
│  receipt_scan / login / register / profile    │
├───────────────────────────────────────────────┤
│          State Management (Provider)          │
│  Auth / Transaction / Category / Settings     │
│  Theme / Ocr / Backup                         │
├───────────────────────────────────────────────┤
│        Repository Katmanı (Abstract)          │
│  TransactionRepository / CategoryRepository   │
├───────────────────────────────────────────────┤
│        DAO ve Servis Katmanı                  │
│  TransactionDao / CategoryDao (Supabase)      │
│  OcrService / ReceiptParser / InvoiceParser   │
│  AiParserService / AiAdvisorService           │
│  NotificationService / ExportService / Backup │
├───────────────────────────────────────────────┤
│               Veri Katmanı                    │
│  Supabase: categories / transactions          │
│  SharedPreferences: ayarlar                   │
│  Cihaz dosyaları: fiş fotoğrafı / PDF         │
└───────────────────────────────────────────────┘
```

---

## Oturum ve Kullanıcıya Özel Veri

- `AuthProvider`, Supabase oturumunu dinler ve `UserSession` arayüzü üzerinden oturumdaki kullanıcının kimliğini sunar.
- `TransactionProvider`, `CategoryProvider` ve `SettingsProvider` bu oturumu dinler: çıkış yapılınca verilerini temizler, yeni kullanıcı giriş yapınca onun verilerini yükler.
- Bütçe limiti, aylık gelir ayarları ve profil fotoğrafı her kullanıcı için ayrı anahtarlarla saklanır. Bildirim, tema ve uygulama kilidi gibi ayarlar ise cihaza aittir.
- Provider'lar veri kaynağını `Repository` arayüzü üzerinden alır; testlerde Supabase yerine sahte (in-memory) depolar verilir.

---

## Klasör Yapısı

```
lib/
├── main.dart                        # Uygulama giriş noktası, provider listesi
├── models/                          # Veri modelleri
│   ├── category.dart                # Kategori modeli
│   ├── transaction.dart             # İşlem modeli + TransactionItem (fiş kalemleri)
│   └── parsed_receipt.dart          # OCR/AI ile ayrıştırılmış fiş sonucu
├── repositories/                    # Repository arayüzleri (abstract)
│   ├── transaction_repository.dart
│   └── category_repository.dart
├── providers/                       # State management (ChangeNotifier)
│   ├── auth_provider.dart           # Supabase giriş/kayıt/çıkış, UserSession
│   ├── transaction_provider.dart    # İşlemler, toplamlar, ana ekran widget'ı
│   ├── category_provider.dart       # Kategoriler ve varsayılan kategori ekleme
│   ├── settings_provider.dart       # Cihaz ve kullanıcıya özel ayarlar
│   ├── theme_provider.dart          # Açık/koyu tema
│   ├── ocr_provider.dart            # Fiş tarama akışı (kamera/galeri/PDF)
│   └── backup_provider.dart         # Yedekleme durumu
├── services/                        # İş mantığı ve dış servisler
│   ├── supabase_service.dart        # Supabase bağlantısı
│   ├── transaction_dao.dart         # İşlem CRUD (Supabase)
│   ├── category_dao.dart            # Kategori CRUD (Supabase)
│   ├── ocr_service.dart             # Google ML Kit metin tanıma
│   ├── receipt_parser.dart          # Fiş metni RegEx ayrıştırma
│   ├── invoice_parser.dart          # PDF fatura metni ayrıştırma
│   ├── ai_parser_service.dart       # Gemini ile fiş ayrıştırma
│   ├── ai_advisor_service.dart      # Gemini ile finansal tavsiye
│   ├── recurring_income_service.dart # Aylık gelirin otomatik eklenmesi
│   ├── notification_service.dart    # Günlük hatırlatıcı bildirimleri
│   ├── export_service.dart          # CSV dışa aktarma
│   └── backup/                      # Yedekleme
│       ├── backup_service.dart      # Ortak arayüz
│       └── json_backup_service.dart # JSON dosyası dışa/içe aktarma
├── screens/                         # UI ekranları
│   ├── onboarding_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── transactions_screen.dart
│   ├── statistics_screen.dart
│   ├── settings_screen.dart
│   ├── profile_screen.dart
│   ├── category_management_screen.dart
│   ├── backup_settings_screen.dart
│   └── receipt_scan_screen.dart
├── widgets/                         # Yeniden kullanılabilir widget'lar
│   ├── summary_card.dart            # Bakiye, gelir/gider ve tasarruf özeti
│   ├── budget_progress_card.dart    # Bu ayın gideri / aylık bütçe
│   ├── transaction_list_item.dart
│   ├── transaction_detail_dialog.dart
│   ├── transaction_actions.dart     # Ortak düzenle/sil akışı
│   ├── transaction_options_sheet.dart # Manuel / kamera / PDF seçimi
│   ├── add_transaction_sheet.dart   # İşlem ekleme ve düzenleme formu
│   ├── ai_advisor_bottom_sheet.dart
│   ├── app_lock_wrapper.dart        # Biyometrik uygulama kilidi
│   └── loading_overlay.dart
└── utils/                           # Yardımcı araçlar
    ├── app_router.dart              # go_router navigasyon yapısı
    ├── app_theme.dart
    ├── currency_formatter.dart      # Tutar biçimlendirme ve giriş formatı
    ├── date_helper.dart             # Tarih doğrulama, tarih seçici sınırları
    ├── text_helper.dart             # Türkçe küçük harf dönüşümü
    └── responsive_layout.dart
```

---

## Veri Modeli (Supabase)

Şemanın tamamı `supabase/schema.sql` dosyasındadır; Supabase SQL Editor'de çalıştırılarak kurulur.

- **Güvenlik:** Tablolarda Row Level Security (RLS) açıktır; her kullanıcı yalnızca `user_id = auth.uid()` olan kayıtlarını okuyup değiştirebilir. DAO'lar ayrıca her sorguyu `user_id` ile filtreler ve kayıt eklerken `user_id` gönderir.
- **Sayfalama:** Supabase tek istekte en fazla 1000 satır döndürür. DAO'lar listeleri `SupabaseService.fetchAllPages` ile sayfa sayfa çeker.
- **Tarihler:** Uygulama tarihleri saat dilimi eki olmadan (yerel saat) gönderir. Postgres bunları UTC kabul eder ve uygulama aynı saat değerini geri okur, yani saat kayması olmaz.

### categories
| Sütun | İçerik |
|-------|--------|
| id | Otomatik artan kimlik |
| name | Kategori adı |
| type | `gelir` veya `gider` |
| icon | Material ikon adı (varsayılan `category`) |
| color | Renk kodu (varsayılan `#4CAF50`) |
| user_id | Kaydın sahibi |

### transactions
| Sütun | İçerik |
|-------|--------|
| id | Otomatik artan kimlik |
| title | İşlem başlığı |
| amount | Tutar (`numeric(14,2)`; kuruş hassasiyeti kaybolmaz) |
| type | `gelir` veya `gider` |
| category_id | `categories.id` (işlemi olan kategori silinemez) |
| date | İşlem tarihi (ISO 8601) |
| description | Açıklama; fiş taramasında ham OCR metni |
| receipt_id | Fiş fotoğrafının veya PDF'in cihazdaki dosya yolu |
| items_json | Fiş kalemleri (JSON metni) |
| created_at | Oluşturulma zamanı |
| user_id | Kaydın sahibi |

Yeni bir kullanıcının hiç kategorisi yoksa `CategoryProvider` temel kategorileri ekler.

---

## Navigasyon Yapısı (go_router)

```
/onboarding (Tanıtım)                 → OnboardingScreen
/login (Giriş)                        → LoginScreen
/register (Kayıt)                     → RegisterScreen
/ (Ana Sayfa)                         → HomeScreen
/transactions (İşlemler)              → TransactionsScreen
/statistics (İstatistikler)           → StatisticsScreen
/settings (Ayarlar)                   → SettingsScreen
/scan (Fiş Tarama - Tam Ekran)        → ReceiptScanScreen
/backup_settings (Yedekleme)          → BackupSettingsScreen
/category_management (Kategoriler)    → CategoryManagementScreen
/profile (Profil)                     → ProfileScreen
```

**Bottom Navigation:** 4 tab (Ana Sayfa, İşlemler, İstatistik, Ayarlar)  
**StatefulShellRoute** ile tab state korunur.  
**Yönlendirme:** Oturum yoksa kullanıcı `/login`'e, giriş yapınca `/`'e yönlendirilir.

---

## Kullanılan Teknolojiler

| Paket | Amaç |
|-------|------|
| supabase_flutter | Kimlik doğrulama ve bulut veritabanı |
| provider | State management |
| go_router | Navigasyon |
| google_mlkit_text_recognition | Cihaz içi OCR fiş tarama |
| google_generative_ai | Gemini ile fiş ayrıştırma ve finansal tavsiye |
| image_picker / image_cropper | Kamera/galeri erişimi ve kırpma |
| file_picker / syncfusion_flutter_pdf | PDF fatura seçme ve metin çıkarma |
| fl_chart | Grafik & veri görselleştirme |
| local_auth | Biyometrik uygulama kilidi |
| flutter_local_notifications / timezone | Günlük hatırlatıcılar |
| home_widget | Android ana ekran widget'ı |
| csv / share_plus | CSV dışa aktarma ve paylaşım |
| shared_preferences | Yerel ayarlar |
| flutter_dotenv | Gemini API anahtarı (`assets/env/.env`) |
| intl | Tarih/para formatı |
