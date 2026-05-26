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
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
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
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _setLoading(AuthLoadingState.none);
      return true;
    } on AuthException catch (error) {
      _setError(error.message);
      return false;
    } catch (error) {
      _setError('Giriş yaparken beklenmeyen bir hata oluştu: $error');
      return false;
    }
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

      _setLoading(AuthLoadingState.none);
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
