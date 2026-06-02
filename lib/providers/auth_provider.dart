import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

enum AuthLoadingState { none, signingIn, signingUp, signingOut }

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseService.client;
  User? _user;
  AuthLoadingState _loadingState = AuthLoadingState.none;
  String? _errorMessage;

  User? get user => _user;
  AuthLoadingState get loadingState => _loadingState;
  bool get isLoading => _loadingState != AuthLoadingState.none;
  String? get errorMessage => _errorMessage;

  // Kullanıcı adı (Ad Soyad)
  String get displayName {
    if (_user == null) return 'Misafir Kullanıcı';
    final metadata = _user!.userMetadata;
    if (metadata != null) {
      if (metadata['full_name'] != null) return metadata['full_name'] as String;
      if (metadata['name'] != null) return metadata['name'] as String;
    }
    return _user!.email?.split('@').first ?? 'Misafir';
  }

  // Kullanıcı profil resmi URL'i
  String? get avatarUrl {
    if (_user == null) return null;
    final metadata = _user!.userMetadata;
    if (metadata != null) {
      if (metadata['avatar_url'] != null) return metadata['avatar_url'] as String;
      if (metadata['picture'] != null) return metadata['picture'] as String;
    }
    return null;
  }

  // Giriş yöntemi (Google, E-posta vb.)
  String get loginMethod {
    if (_user == null) return 'Bilinmiyor';
    final provider = _user!.appMetadata['provider'] ?? 'email';
    if (provider == 'google') return 'Google';
    return 'E-posta';
  }

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _user = _supabase.auth.currentUser;
    
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  // E-posta ile Kayıt
  Future<bool> signUpWithEmail(String email, String password, String fullName) async {
    try {
      _setLoading(AuthLoadingState.signingUp);
      // Animasyonun görünmesi için minimum bekleme süresi
      final results = await Future.wait([
        _supabase.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': fullName},
        ),
        Future.delayed(const Duration(milliseconds: 2500)),
      ]);

      final response = results[0] as AuthResponse;

      // Eğer kayıt sonrası oturum açılmadıysa (e-posta doğrulama açık olabilir),
      // hemen giriş yapmayı dene
      if (response.session == null) {
        try {
          await _supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
        } catch (_) {
          // Giriş de başarısız olursa (e-posta doğrulama zorunluysa)
          // yine de kayıt başarılı sayılır, kullanıcı bilgilendirilir
        }
      }

      _setLoading(AuthLoadingState.none);
      return true;
    } on AuthException catch (error) {
      _setError(error.message);
      return false;
    } catch (error) {
      _setError('Kayıt olurken beklenmeyen bir hata oluştu: $error');
      return false;
    }
  }

  // E-posta ile Giriş
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setLoading(AuthLoadingState.signingIn);
      // Animasyonun görünmesi için minimum bekleme süresi
      await Future.wait([
        _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        ),
        Future.delayed(const Duration(milliseconds: 2500)),
      ]);
      _setLoading(AuthLoadingState.none);
      return true;
    } on AuthException catch (error) {
      debugPrint('⚠️ Supabase Auth Hatası: ${error.message} (statusCode: ${error.statusCode})');
      _setError(_mapAuthError(error.message));
      return false;
    } catch (error) {
      debugPrint('⚠️ Beklenmeyen Giriş Hatası: $error');
      _setError('Giriş yaparken beklenmeyen bir hata oluştu.');
      return false;
    }
  }

  /// Supabase İngilizce hata mesajlarını Türkçeye çevirir
  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('email not confirmed')) {
      return 'E-posta adresiniz doğrulanmamış. Lütfen e-posta kutunuzu kontrol edin veya yönetici panelinden e-posta doğrulamayı kapatın.';
    }
    if (lower.contains('invalid login credentials') || lower.contains('invalid_credentials')) {
      return 'E-posta veya şifre hatalı. Lütfen bilgilerinizi kontrol edin.';
    }
    if (lower.contains('user not found')) {
      return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
    }
    if (lower.contains('too many requests') || lower.contains('rate limit')) {
      return 'Çok fazla deneme yaptınız. Lütfen biraz bekleyin.';
    }
    if (lower.contains('network') || lower.contains('socket') || lower.contains('connection')) {
      return 'İnternet bağlantınızı kontrol edin.';
    }
    return message;
  }

  // Google ile Giriş
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(AuthLoadingState.signingIn);
      // Supabase'in yerleşik OAuth provider'ını kullanarak Google girişi
      // Bu işlem cihazın varsayılan tarayıcısını açar ve girişten sonra uygulamaya geri döner.
      
      final success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'finansapp://login-callback', // Bu URL Android Manifest ve Supabase Dashboard'da tanımlı olmalı
      );

      if (!success) {
        _setLoading(AuthLoadingState.none);
      } else {
        // Tarayıcıya geçiş yapana kadar loading animasyonu ekranda kalsın
        await Future.delayed(const Duration(milliseconds: 2500));
        _setLoading(AuthLoadingState.none);
      }
      return success;
    } on AuthException catch (error) {
      _setError(error.message);
      return false;
    } catch (error) {
      _setError('Google ile giriş yapılırken hata oluştu: $error');
      return false;
    }
  }

  // Çıkış Yap
  Future<void> signOut() async {
    try {
      _setLoading(AuthLoadingState.signingOut);
      // Animasyonun görünmesi için çıkış işlemini biraz geciktiriyoruz.
      // Çünkü signOut çağrıldığı an router otomatik login sayfasına atıyor.
      await Future.delayed(const Duration(milliseconds: 1500));
      
      await _supabase.auth.signOut();
      _setLoading(AuthLoadingState.none);
    } catch (error) {
      _setError('Çıkış yaparken bir hata oluştu: $error');
    }
  }

  // Hata durumunu sıfırla
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(AuthLoadingState state) {
    _loadingState = state;
    if (state != AuthLoadingState.none) _errorMessage = null; // Yükleme başlarken önceki hatayı temizle
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setLoading(AuthLoadingState.none);
  }
}
