import 'package:cloud_firestore/cloud_firestore.dart';

import 'backup_service.dart';
import '../transaction_dao.dart';
import '../category_dao.dart';
import '../receipt_dao.dart';

/// Firebase (Firestore) tabanlı bulut yedekleme servisi
class FirebaseBackupService implements BackupService {
  final TransactionDao _transactionDao = TransactionDao();
  final CategoryDao _categoryDao = CategoryDao();
  final ReceiptDao _receiptDao = ReceiptDao();

  // NOT: Kullanıcı kimlik doğrulama işlemleri sonradan eklendiğinde,
  // kullanıcının UID'si alınarak data yalıtımı sağlanacak.
  final String _userId = 'default_user'; // Şimdilik dummy user id

  @override
  Future<bool> exportData() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      final categories = await _categoryDao.getAll();
      final transactions = await _transactionDao.getAll();
      final receipts = await _receiptDao.getAll();

      // Firestore Batch işlemi ile her şeyi topluca kaydet
      WriteBatch batch = firestore.batch();

      // Kategorileri kaydet
      final categoryRef = firestore.collection('users').doc(_userId).collection('categories');
      for (var cat in categories) {
        batch.set(categoryRef.doc(cat.id.toString()), cat.toMap());
      }

      // İşlemleri kaydet
      final txRef = firestore.collection('users').doc(_userId).collection('transactions');
      for (var tx in transactions) {
        batch.set(txRef.doc(tx.id.toString()), tx.toMap());
      }

      // Fişleri kaydet
      final receiptRef = firestore.collection('users').doc(_userId).collection('receipts');
      for (var rep in receipts) {
        batch.set(receiptRef.doc(rep.id.toString()), rep.toMap());
      }

      // Snapshot metadata'yı güncelle
      final userDocRef = firestore.collection('users').doc(_userId);
      batch.set(userDocRef, {
        'last_backup': DateTime.now().toIso8601String(),
        'backup_version': 1,
      }, SetOptions(merge: true));

      await batch.commit();
      print('Firebase Yedekleme başarılı');
      return true;
    } catch (e) {
      print('Firebase Dışa Aktarırken Hata: $e');
      return false;
    }
  }

  @override
  Future<bool> importData() async {
    try {
      // final firestore = FirebaseFirestore.instance;
      // final categoryRef = firestore.collection('users').doc(_userId).collection('categories');
      // final snapshot = await categoryRef.get();
      // snapshot.docs.forEach((doc) => _categoryDao.insert(Category.fromMap(doc.data())));
      
      print('Firebase İçe Aktarma çağrıldı');
      return true;
    } catch (e) {
      print('Firebase İçe Aktarırken Hata: $e');
      return false;
    }
  }
}
