import 'package:flutter_test/flutter_test.dart';
import 'package:finans_app/services/supabase_service.dart';

void main() {
  group('SupabaseService.fetchAllPages', () {
    // Sunucunun en fazla pageSize satır döndürdüğü bir tabloyu taklit eder
    Future<List<Map<String, dynamic>>> Function(int from, int to) fakeTable(
      int rowCount,
      List<String> calls,
    ) {
      final rows = List.generate(rowCount, (i) => <String, dynamic>{'id': i});
      return (from, to) async {
        calls.add('$from-$to');
        if (from >= rows.length) return [];
        return rows.sublist(from, (to + 1).clamp(0, rows.length));
      };
    }

    test('1000 satirdan fazla kayit sayfa sayfa eksiksiz cekilir', () async {
      final calls = <String>[];
      final rows = await SupabaseService.fetchAllPages(fakeTable(2350, calls));

      expect(rows, hasLength(2350));
      expect(rows.last['id'], 2349);
      expect(calls, ['0-999', '1000-1999', '2000-2999']);
    });

    test('Tam sayfa sinirinda bitince bos sayfayla sonlanir', () async {
      final calls = <String>[];
      final rows = await SupabaseService.fetchAllPages(
        fakeTable(4, calls),
        pageSize: 2,
      );

      expect(rows, hasLength(4));
      expect(calls, ['0-1', '2-3', '4-5']);
    });

    test('Tek sayfalik kayit tek istekte gelir', () async {
      final calls = <String>[];
      final rows = await SupabaseService.fetchAllPages(fakeTable(7, calls));

      expect(rows, hasLength(7));
      expect(calls, hasLength(1));
    });
  });
}
