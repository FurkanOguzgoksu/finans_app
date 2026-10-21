import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase bağlantısını yöneten singleton servis
class SupabaseService {
  static const String _supabaseUrl = 'https://rwnhdreiptfwibamjikg.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3bmhkcmVpcHRmd2liYW1qaWtnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2OTkyODMsImV4cCI6MjA5MDI3NTI4M30.9C7_uxBlmZq5UcPZYZE0actlk5_IS6EgRtf2sa7OX5g';

  /// Supabase'in tek istekte döndürdüğü en fazla satır sayısı (varsayılan ayar)
  static const int pageSize = 1000;

  /// Uygulama başlangıcında çağrılır
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  /// Supabase client'ına erişim noktası
  static SupabaseClient get client => Supabase.instance.client;

  /// Oturumdaki kullanıcının kimliği; oturum yoksa hata fırlatır
  static String get currentUserId {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Bu işlem için giriş yapmalısınız.');
    }
    return userId;
  }

  /// Sorgunun tüm satırlarını sayfa sayfa çeker.
  ///
  /// Supabase tek istekte en fazla [pageSize] satır döndürür; daha fazlası
  /// sessizce kesilir. [fetchPage] verilen aralığı (`range(from, to)`) çekmelidir
  /// ve sayfaların kaymaması için sorgu benzersiz bir sıralama içermelidir.
  static Future<List<Map<String, dynamic>>> fetchAllPages(
    Future<List<Map<String, dynamic>>> Function(int from, int to) fetchPage, {
    int pageSize = pageSize,
  }) async {
    final rows = <Map<String, dynamic>>[];
    for (var from = 0;; from += pageSize) {
      final page = await fetchPage(from, from + pageSize - 1);
      rows.addAll(page);
      if (page.length < pageSize) return rows;
    }
  }
}
