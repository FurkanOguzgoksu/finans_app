import 'package:flutter/material.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as models;

/// Her ay belirtilen günde aylık geliri otomatik işlem olarak ekleyen servis.
///
/// Çalışma mantığı:
/// 1. Aylık gelir ve gün ayarlanmış mı kontrol et
/// 2. Bugün >= ayarlanan gün mü?
/// 3. Bu ay daha önce eklendi mi? (lastIncomeMonth)
/// 4. Hepsi tamam → gelir işlemi ekle ve lastIncomeMonth güncelle
class RecurringIncomeService {
  /// Tarihin ay anahtarını döndürür: 'YYYY-MM' (metin olarak sıralanabilir)
  static String monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  /// Otomatik gelir kontrolünü çalıştırır, gelir eklendiyse true döner.
  /// [now] testlerde tarihi sabitlemek içindir.
  static Future<bool> checkAndAdd({
    required SettingsProvider settings,
    required TransactionProvider txProvider,
    DateTime? now,
  }) async {
    // Ayarlar yüklü değilse çık
    if (!settings.hasRecurringIncome) return false;

    now ??= DateTime.now();
    final currentMonthKey = monthKey(now);

    // Bu ayın (veya ileri bir ayın) geliri zaten eklendi mi?
    if (settings.lastIncomeMonth.compareTo(currentMonthKey) >= 0) return false;

    // Ay sonu düzeltme: örn. Mart'ta gün=31 ise son gün olan 31'i kullan
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final effectiveDay = settings.incomeDay.clamp(1, lastDayOfMonth);

    // Bugün henüz gelir günü gelmedi mi?
    if (now.day < effectiveDay) return false;

    // İşlem tarihini belirle: bu ayın gelir günü
    final incomeDate = DateTime(now.year, now.month, effectiveDay);

    final tx = models.Transaction(
      title: settings.incomeTitle,
      amount: settings.monthlyIncome,
      type: 'gelir',
      categoryId: settings.incomeCategoryId!,
      date: incomeDate,
      description: 'Otomatik aylık gelir (${settings.incomeDay}. gün)',
    );

    await txProvider.addTransaction(tx);
    await settings.setLastIncomeMonth(currentMonthKey);

    debugPrint(
      '[RecurringIncomeService] ${settings.incomeTitle} eklendi → '
      '₺${settings.monthlyIncome} / $currentMonthKey / gün: $effectiveDay',
    );

    return true; // eklendi
  }
}
