import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Bildirimler yalnızca mobil platformlarda kurulur. Diğer platformlarda
  /// (ör. Windows) eklenti ek ayar ister ve hata fırlatırsa uygulama açılmaz.
  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (_isInitialized || !_isSupportedPlatform) return;

    // Timezone initalization
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul')); // Varsayılan olarak Türkiye saati

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Bildirime tıklanınca yapılacak işlem eklenebilir
        debugPrint('Bildirime tıklandı: ${details.payload}');
      },
    );

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (!_isInitialized) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    return false;
  }

  /// Tüm zamanlanmış bildirimleri iptal eder.
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    try {
      await _localNotificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Bildirimler iptal edilemedi: $e');
    }
  }

  /// Kullanıcının belirlediği saatlere göre günlük bildirimleri kurar.
  Future<void> scheduleDailyReminders(List<TimeOfDay> times) async {
    if (!_isInitialized) return;
    await cancelAllNotifications();

    if (times.isEmpty) return;

    try {
      int id = 0;
      for (var time in times) {
        await _scheduleDailyNotification(id, time);
        id++;
      }
    } catch (e) {
      debugPrint('Günlük hatırlatıcılar kurulamadı: $e');
    }
  }

  Future<void> _scheduleDailyNotification(int id, TimeOfDay time) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Eğer zaman geçtiyse yarına ayarla
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Günlük Hatırlatıcılar',
      channelDescription: 'Harcama girmeyi hatırlatan günlük bildirimler',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.zonedSchedule(
      id: id,
      title: 'Finans Asistanı',
      body: 'Bugün hiç harcama girdiniz mi? Fişlerinizi taramayı unutmayın!',
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      // Hatırlatıcı için birkaç dakikalık sapma sorun değil; tam zamanlı alarm
      // (exact alarm) özel izin ister ve Play Store politikasına takılır.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Her gün tekrarlaması için
    );
  }
}
