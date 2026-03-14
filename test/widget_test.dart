import 'package:flutter_test/flutter_test.dart';
import 'package:finans_app/main.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/providers/backup_provider.dart';

void main() {
  testWidgets('Uygulama yuklenme duman testi (smoke test)', (WidgetTester tester) async {
    // Projemize ozel MultiProvider ve FinansApp sarmaliyla uygulamayi baslat
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BackupProvider()),
        ],
        child: const FinansApp(),
      ),
    );

    // Uygulamanin cokmeden acildigini dogrula
    expect(find.byType(FinansApp), findsOneWidget);
  });
}
