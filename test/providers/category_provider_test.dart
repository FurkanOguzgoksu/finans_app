import 'package:flutter_test/flutter_test.dart';
import 'package:finans_app/models/category.dart';
import 'package:finans_app/providers/category_provider.dart';

import '../helpers/fakes.dart';

void main() {
  group('CategoryProvider', () {
    test('Ayni anda gelen yuklemeler varsayilan kategorileri bir kez ekler', () async {
      final repository = FakeCategoryRepository(
        delay: const Duration(milliseconds: 20),
      );

      // Oluşturulurken yükleme başlar; hemen ardından ikinci bir yükleme istenir
      final provider = CategoryProvider(FakeSession('yeni-kullanici'), repository: repository);
      await provider.loadCategories();

      expect(repository.items, hasLength(7));
      expect(provider.categories, hasLength(7));
    });

    test('Cikis yapilinca kategoriler temizlenir, yeni kullanicinin verisi yuklenir', () async {
      final repository = FakeCategoryRepository();
      final session = FakeSession('kullanici-a');
      final provider = CategoryProvider(session, repository: repository);
      await provider.loadCategories();
      expect(provider.categories, isNotEmpty);

      session.logout();
      expect(provider.categories, isEmpty);

      repository.items
        ..clear()
        ..add(Category(id: 99, name: 'Kira', type: 'gider'));
      session.login('kullanici-b');
      await provider.loadCategories();

      expect(provider.categories.map((c) => c.name), ['Kira']);
    });
  });
}
