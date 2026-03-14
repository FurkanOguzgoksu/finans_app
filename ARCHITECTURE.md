# 🏗️ Teknik Mimari Dokümanı - Finans Takip Uygulaması

## Genel Bakış

**Proje Adı:** Akıllı Finansal Analiz ve Otomatik Harcama Takip Sistemi  
**Platform:** Flutter (Dart)  
**Mimari Yaklaşım:** Repository Pattern + Provider State Management  

---

## Katmanlı Mimari

```
┌──────────────────────────────────────┐
│           UI Katmanı (Screens)       │
│  home / transactions / statistics    │
│  settings / receipt_scan             │
├──────────────────────────────────────┤
│        State Management (Provider)   │
├──────────────────────────────────────┤
│     Repository Katmanı (Abstract)    │
│  TransactionRepo / CategoryRepo     │
│  ReceiptRepo                         │
├──────────────────────────────────────┤
│        Service Katmanı               │
│  DatabaseService / OCR Service       │
├──────────────────────────────────────┤
│        Veri Katmanı (SQLite)         │
│  categories / transactions / receipts│
└──────────────────────────────────────┘
```

---

## Klasör Yapısı

```
lib/
├── main.dart                  # Uygulama giriş noktası
├── models/                    # Veri modelleri
│   ├── category.dart          # Kategori modeli
│   ├── transaction.dart       # İşlem modeli
│   └── receipt.dart           # Fiş/Fatura modeli
├── repositories/              # Repository arayüzleri (abstract)
│   ├── transaction_repository.dart
│   ├── category_repository.dart
│   └── receipt_repository.dart
├── services/                  # İş mantığı servisleri
│   └── database_service.dart  # SQLite veritabanı yönetimi
├── screens/                   # UI ekranları
│   ├── home_screen.dart
│   ├── transactions_screen.dart
│   ├── statistics_screen.dart
│   ├── settings_screen.dart
│   └── receipt_scan_screen.dart
├── widgets/                   # Yeniden kullanılabilir widget'lar
└── utils/                     # Yardımcı araçlar
    └── app_router.dart        # go_router navigasyon yapısı
```

---

## Veritabanı Şeması (SQLite)

### categories
| Sütun | Tip | Kısıtlama |
|-------|-----|-----------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT |
| name | TEXT | NOT NULL |
| type | TEXT | NOT NULL, CHECK('gelir','gider') |
| icon | TEXT | DEFAULT 'category' |
| color | TEXT | DEFAULT '#4CAF50' |

### transactions
| Sütun | Tip | Kısıtlama |
|-------|-----|-----------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT |
| title | TEXT | NOT NULL |
| amount | REAL | NOT NULL |
| type | TEXT | NOT NULL, CHECK('gelir','gider') |
| category_id | INTEGER | FOREIGN KEY → categories(id) |
| date | TEXT | NOT NULL |
| description | TEXT | - |
| receipt_id | TEXT | - |
| created_at | TEXT | NOT NULL |

### receipts
| Sütun | Tip | Kısıtlama |
|-------|-----|-----------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT |
| image_path | TEXT | NOT NULL |
| extracted_text | TEXT | - |
| extracted_amount | REAL | - |
| merchant_name | TEXT | - |
| receipt_date | TEXT | - |
| created_at | TEXT | NOT NULL |

---

## Navigasyon Yapısı (go_router)

```
/ (Ana Sayfa)                    → HomeScreen
/transactions (İşlemler)         → TransactionsScreen
/statistics (İstatistikler)      → StatisticsScreen
/settings (Ayarlar)              → SettingsScreen
/scan (Fiş Tarama - Tam Ekran)  → ReceiptScanScreen
```

**Bottom Navigation:** 4 tab (Ana Sayfa, İşlemler, İstatistik, Ayarlar)  
**StatefulShellRoute** ile tab state korunur.

---

## Kullanılan Teknolojiler

| Paket | Amaç |
|-------|------|
| sqflite | SQLite veritabanı |
| google_mlkit_text_recognition | OCR fiş tarama |
| fl_chart | Grafik & veri görselleştirme |
| go_router | Navigasyon |
| provider | State management |
| image_picker | Kamera/galeri erişimi |
| intl | Tarih/para formatı |
| shared_preferences | Yerel ayarlar |
