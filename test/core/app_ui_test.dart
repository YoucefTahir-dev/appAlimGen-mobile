import 'package:app_alim_gen_mobile/app/theme/app_theme.dart';
import 'package:app_alim_gen_mobile/core/utils/app_formats.dart';
import 'package:app_alim_gen_mobile/core/widgets/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uniformise les montants en DZD', () {
    expect(AppFormats.money('24850.00'), contains('24'));
    expect(AppFormats.money('24850.00'), endsWith(' DZD'));
    expect(AppFormats.money(null), '0 DZD');
  });

  testWidgets('les états vide et erreur exposent une action accessible', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppErrorState(
            title: 'Chargement impossible',
            message: 'Vérifiez votre connexion.',
            retryLabel: 'Réessayer',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    expect(retried, isTrue);
  });

  testWidgets('le badge affiche aussi un libellé, pas seulement une couleur', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: StatusBadge(label: 'Payée', tone: StatusTone.success),
        ),
      ),
    );

    expect(find.text('Payée'), findsOneWidget);
  });
}
