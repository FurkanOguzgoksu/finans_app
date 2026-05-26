import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseService.client;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
      _setLoading(true);
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      _setLoading(false);
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
      _setLoading(true);
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
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
      _setLoading(true);
      // Supabase'in yerleşik OAuth provider'ını kullanarak Google girişi
      // Bu işlem cihazın varsayılan tarayıcısını açar ve girişten sonra uygulamaya geri döner.
      
      final success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'finansapp://login-callback', // Bu URL Android Manifest ve Supabase Dashboard'da tanımlı olmalı
      );

      _setLoading(false);
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
      _setLoading(true);
      await _supabase.auth.signOut();
      _setLoading(false);
    } catch (error) {
      _setError('Çıkış yaparken bir hata oluştu: $error');
    }
  }

  // Hata durumunu sıfırla
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null; // Yükleme başlarken önceki hatayı temizle
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setLoading(false);
  }
}
