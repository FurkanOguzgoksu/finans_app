import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase bağlantısını yöneten singleton servis
class SupabaseService {
  static const String _supabaseUrl = 'https://rwnhdreiptfwibamjikg.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3bmhkcmVpcHRmd2liYW1qaWtnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2OTkyODMsImV4cCI6MjA5MDI3NTI4M30.9C7_uxBlmZq5UcPZYZE0actlk5_IS6EgRtf2sa7OX5g';

  /// Uygulama başlangıcında çağrılır
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  /// Supabase client'ına erişim noktası
  static SupabaseClient get client => Supabase.instance.client;
}
