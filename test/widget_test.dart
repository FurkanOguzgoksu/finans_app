import 'package:flutter_test/flutter_test.dart';
import 'package:finans_app/main.dart';
import 'package:finans_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('Uygulama yuklenme duman testi (smoke test)', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Ağa çıkmayan, zamanlayıcı başlatmayan sahte Supabase auth istemcisi
    final authProvider = AuthProvider(
      auth: GoTrueClient(
        url: 'http://localhost',
        autoRefreshToken: false,
        flowType: AuthFlowType.implicit,
      ),
    );

    // Projemize ozel MultiProvider ve FinansApp sarmaliyla uygulamayi baslat
    await tester.pumpWidget(
      MultiProvider(
        providers: buildAppProviders(prefs, authProvider: authProvider),
        child: const FinansApp(showOnboarding: false),
      ),
    );
    await tester.pumpAndSettle();

    // Uygulamanin cokmeden acildigini ve oturum yokken giris ekranina
    // yonlendirdigini dogrula
    expect(find.byType(FinansApp), findsOneWidget);
    expect(find.text("Finans Takip'e Hoşgeldin"), findsOneWidget);
  });
}
