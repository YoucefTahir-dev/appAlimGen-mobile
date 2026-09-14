import 'package:app_alim_gen_mobile/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'démarrage minimal sans identifiant de production',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ElAmineApp()));
      await tester.pump();
      expect(find.byType(ElAmineApp), findsOneWidget);
    },
    skip: const bool.fromEnvironment(
      'SKIP_DEVICE_INTEGRATION',
      defaultValue: true,
    ),
  );
}
