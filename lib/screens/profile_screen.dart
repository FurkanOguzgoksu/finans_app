import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';

/// Profil Ekranı
/// Kullanıcının profil bilgilerini (fotoğraf, isim, e-posta) gösterdiği ve
/// fotoğraf düzenleme işlemlerini yaptığı sayfa.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), centerTitle: true),
      body: Consumer2<SettingsProvider, AuthProvider>(
        builder: (context, settings, authProvider, child) {
          final theme = Theme.of(context);
          final user = authProvider.user;

          // Kullanıcı bilgileri (Supabase'den, yoksa yerel ayarlardan alıyoruz)
          final userName = user != null 
              ? authProvider.displayName 
              : (settings.userName.isNotEmpty ? settings.userName : 'Misafir Kullanıcı');
          
          final userEmail = user != null 
              ? (user.email ?? '') 
              : (settings.userEmail.isNotEmpty ? settings.userEmail : 'Giriş yapılmadı');

          final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

          // Profil fotoğrafı kaynağını belirleme
          ImageProvider? avatarImage;
          bool hasPhoto = false;

          if (user != null && authProvider.avatarUrl != null) {
            avatarImage = NetworkImage(authProvider.avatarUrl!);
            hasPhoto = true;
          } else if (settings.userPhotoPath.isNotEmpty) {
            avatarImage = FileImage(File(settings.userPhotoPath));
            hasPhoto = true;
          }

          final nameController = TextEditingController(text: userName);
          final emailController = TextEditingController(text: userEmail);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                // Profil Fotoğrafı
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: hasPhoto
                          ? () {
                              showDialog(
                                context: context,
                                builder: (ctx) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: EdgeInsets.zero,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () => Navigator.of(ctx).pop(),
                                        child: Container(
                                          color: Colors.black87,
                                          width: double.infinity,
                                          height: double.infinity,
                                          child: InteractiveViewer(
                                            child: avatarImage != null
                                                ? Image(image: avatarImage, fit: BoxFit.contain)
                                                : const SizedBox(),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: kToolbarHeight,
                                        right: 16,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        backgroundImage: avatarImage,
                        child: !hasPhoto
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          final source =
                              await showModalBottomSheet<ImageSource>(
                                context: context,
                                builder: (ctx) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt),
                                        title: const Text('Kamerayla Çek'),
                                        onTap: () => Navigator.pop(
                                          ctx,
                                          ImageSource.camera,
                                        ),
                                      ),
                                      ListTile(
                                        leading: const Icon(
                                          Icons.photo_library,
                                        ),
                                        title: const Text('Galeriden Seç'),
                                        onTap: () => Navigator.pop(
                                          ctx,
                                          ImageSource.gallery,
                                        ),
                                      ),
                                      if (hasPhoto)
                                        ListTile(
                                          leading: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          title: const Text(
                                            'Fotoğrafı Kaldır',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          onTap: () {
                                            settings.setUserPhotoPath('');
                                            Navigator.pop(ctx);
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              );

                          if (source != null) {
                            PermissionStatus status;
                            bool isGranted = false;

                            if (source == ImageSource.camera) {
                              status = await Permission.camera.request();
                              isGranted = status.isGranted;
                            } else {
                              if (Platform.isAndroid) {
                                final photosStatus = await Permission.photos
                                    .request();
                                final storageStatus = await Permission.storage
                                    .request();
                                isGranted =
                                    photosStatus.isGranted ||
                                    storageStatus.isGranted;
                                status =
                                    photosStatus.isPermanentlyDenied ||
                                        storageStatus.isPermanentlyDenied
                                    ? PermissionStatus.permanentlyDenied
                                    : photosStatus;
                              } else {
                                status = await Permission.photos.request();
                                isGranted = status.isGranted;
                              }
                            }

                            if (isGranted) {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(
                                source: source,
                              );
                              if (pickedFile != null) {
                                final croppedFile = await ImageCropper()
                                    .cropImage(
                                      sourcePath: pickedFile.path,
                                      aspectRatio: const CropAspectRatio(
                                        ratioX: 1,
                                        ratioY: 1,
                                      ),
                                      compressQuality: 90,
                                      uiSettings: [
                                        AndroidUiSettings(
                                          toolbarTitle: 'Profil Fotoğrafı',
                                          toolbarColor:
                                              theme.colorScheme.primary,
                                          toolbarWidgetColor:
                                              theme.colorScheme.onPrimary,
                                          activeControlsWidgetColor:
                                              theme.colorScheme.primary,
                                          cropStyle: CropStyle.circle,
                                          initAspectRatio:
                                              CropAspectRatioPreset.square,
                                          lockAspectRatio: true,
                                        ),
                                        IOSUiSettings(
                                          title: 'Fotoğrafı Kırp',
                                          aspectRatioLockEnabled: true,
                                          resetButtonHidden: true,
                                          aspectRatioPickerButtonHidden: true,
                                        ),
                                      ],
                                    );

                                if (croppedFile != null) {
                                  settings.setUserPhotoPath(croppedFile.path);
                                }
                              }
                            } else if (status.isPermanentlyDenied) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Bu işlem için ayarlardan izin vermeniz gerekiyor.',
                                  ),
                                  action: SnackBarAction(
                                    label: 'Ayarlar',
                                    onPressed: () => openAppSettings(),
                                  ),
                                ),
                              );
                            } else {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Erişim izni reddedildi.'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // İsim Soyisim
                TextField(
                  controller: nameController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 24),

                // E-Posta
                TextField(
                  controller: emailController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'E-Posta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Kişisel bilgiler (isim ve e-posta) kullandığınız hesaptan otomatik olarak gelir ve sadece giriş yapıldığında güncellenir.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
