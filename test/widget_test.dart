import 'package:flutter_test/flutter_test.dart';
import 'package:finans_app/main.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/providers/backup_provider.dart';
import 'package:finans_app/providers/category_provider.dart';
import 'package:finans_app/providers/transaction_provider.dart';

void main() {
  testWidgets('Uygulama yuklenme duman testi (smoke test)', (WidgetTester tester) async {
    // Projemize ozel MultiProvider ve FinansApp sarmaliyla uygulamayi baslat
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BackupProvider()),
          ChangeNotifierProvider(create: (_) => CategoryProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ],
        child: const FinansApp(showOnboarding: false),
      ),
    );


    // Uygulamanin cokmeden acildigini dogrula
    expect(find.byType(FinansApp), findsOneWidget);
  });
}
