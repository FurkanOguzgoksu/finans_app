import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:finans_app/services/ocr_service.dart';

/// OCR durumlarını temsil eden enum
enum OcrState {
  idle,       // Başlangıç — henüz bir işlem yok
  picking,    // Kamera/galeri seçimi yapılıyor
  cropping,   // Kırpma işlemi yapılıyor
  processing, // ML Kit OCR işliyor
  done,       // OCR tamamlandı, sonuç hazır
  error,      // Bir hata oluştu
}

/// OCR Provider — Fiş tarama akışının state yönetimi
///
/// Kamera/galeri seçimi → isteğe bağlı kırpma → OCR tarama → sonuç gösterimi
class OcrProvider extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  // ─── State ─────────────────────────────────────────
  OcrState _state = OcrState.idle;
  String? _imagePath;
  String? _rawText;
  String? _errorMessage;

  // ─── Getters ───────────────────────────────────────
  OcrState get state => _state;
  String? get imagePath => _imagePath;
  String? get rawText => _rawText;
  String? get errorMessage => _errorMessage;
  bool get hasImage => _imagePath != null;
  bool get hasResult => _rawText != null && _rawText!.isNotEmpty;

  // ─── Kameradan Fotoğraf Çek ────────────────────────
  Future<void> pickFromCamera() async {
    _setState(OcrState.picking);
    try {
      if (!await _checkCameraPermission()) {
        _setState(OcrState.idle);
        return;
      }
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (photo != null) {
        _imagePath = photo.path;
        _rawText = null;
        _errorMessage = null;
        _setState(OcrState.idle);
      } else {
        // Kullanıcı iptal etti
        _setState(OcrState.idle);
      }
    } catch (e) {
      _setError('Kamera erişiminde hata: $e');
    }
  }

  // ─── Galeriden Fotoğraf Seç ────────────────────────
  Future<void> pickFromGallery() async {
    _setState(OcrState.picking);
    try {
      if (!await _checkGalleryPermission()) {
        _setState(OcrState.idle);
        return;
      }
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (image != null) {
        _imagePath = image.path;
        _rawText = null;
        _errorMessage = null;
        _setState(OcrState.idle);
      } else {
        _setState(OcrState.idle);
      }
    } catch (e) {
      _setError('Galeri erişiminde hata: $e');
    }
  }

  // ─── Kırpma İşlemi (İsteğe Bağlı) ────────────────
  Future<void> cropImage(BuildContext context) async {
    if (_imagePath == null) return;

    _setState(OcrState.cropping);
    try {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _imagePath!,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Fişi Kırp',
            toolbarColor: theme.colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: theme.colorScheme.primary,
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            cropStyle: CropStyle.rectangle,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Fişi Kırp',
            cancelButtonTitle: 'İptal',
            doneButtonTitle: 'Tamam',
            cropStyle: CropStyle.rectangle,
          ),
        ],
      );

      if (croppedFile != null) {
        _imagePath = croppedFile.path;
        _rawText = null;
      }
      _setState(OcrState.idle);
    } catch (e) {
      _setError('Kırpma işleminde hata: $e');
    }
  }

  // ─── OCR Tarama ────────────────────────────────────
  Future<void> runOcr() async {
    if (_imagePath == null) {
      _setError('Lütfen önce bir fotoğraf seçin.');
      return;
    }

    // Dosyanın var olduğunu kontrol et
    final file = File(_imagePath!);
    if (!await file.exists()) {
      _setError('Seçilen fotoğraf dosyası bulunamadı.');
      return;
    }

    _setState(OcrState.processing);
    try {
      final text = await _ocrService.recognizeText(_imagePath!);

      if (text.isEmpty) {
        _rawText = '';
        _errorMessage = null;
        _setState(OcrState.done);
      } else {
        _rawText = text;
        _errorMessage = null;
        _setState(OcrState.done);
      }
    } on OcrException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Beklenmeyen bir hata oluştu: $e');
    }
  }

  // ─── State Sıfırlama ──────────────────────────────
  void reset() {
    _state = OcrState.idle;
    _imagePath = null;
    _rawText = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Yardımcı Metotlar ────────────────────────────
  void _setState(OcrState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(OcrState.error);
  }



  /// Kamera izni kontrolü
  Future<bool> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isPermanentlyDenied) {
      _setError('Kamera izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.');
      openAppSettings();
      return false;
    }
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        _setError('Kamera izni verilmedi.');
        return false;
      }
    }
    return true;
  }

  /// Galeri/Depolama izni kontrolü
  Future<bool> _checkGalleryPermission() async {
    PermissionStatus status;
    if (Platform.isAndroid) {
      status = await Permission.photos.status;
      if (!status.isGranted && !status.isLimited) {
        status = await Permission.photos.request();
      }
    } else {
      status = await Permission.photos.status;
      if (!status.isGranted && !status.isLimited) {
        status = await Permission.photos.request();
      }
    }

    if (status.isPermanentlyDenied) {
      _setError('Galeri izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.');
      openAppSettings();
      return false;
    }

    if (!status.isGranted && !status.isLimited) {
      _setError('Galeri erişim izni verilmedi.');
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
