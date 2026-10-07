import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/features/auth/data/biometric_auth_service.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _biometricBusy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadBiometricState);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    return ModuleScaffold(
      title: strings.profile,
      path: '/profile',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 42,
            child: Text(
              (user?.displayName ?? '?').characters.first.toUpperCase(),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user?.displayName ?? '',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Center(child: Text(user?.role ?? '')),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(user?.username ?? ''),
          ),
          if (user?.email.isNotEmpty ?? false)
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: Text(user!.email),
            ),
          if (_biometricAvailable || _biometricEnabled) ...[
            const Divider(height: 36),
            Text(
              strings.text('security'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SwitchListTile(
              key: const Key('biometric-setting-toggle'),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.fingerprint),
              title: Text(strings.text('biometricLogin')),
              subtitle: Text(strings.text('biometricSettingDescription')),
              value: _biometricEnabled,
              onChanged: _biometricBusy ? null : _toggleBiometrics,
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            key: const Key('logout-button'),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: Text(strings.logout),
          ),
        ],
      ),
    );
  }

  Future<void> _loadBiometricState() async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    final manager = ref.read(biometricSessionManagerProvider);
    final availability = await manager.availability();
    final enabled = await manager.isEnabledFor(user.id);
    if (!mounted) return;
    setState(() {
      _biometricAvailable = availability == BiometricAvailability.available;
      _biometricEnabled = enabled;
    });
  }

  Future<void> _toggleBiometrics(bool enabled) async {
    final strings = AppLocalizations.of(context);
    setState(() => _biometricBusy = true);
    String message;
    if (!enabled) {
      final result = await ref
          .read(authControllerProvider.notifier)
          .disableBiometrics();
      if (result == BiometricAuthResult.success) {
        _biometricEnabled = false;
        message = strings.text('biometricDisabled');
      } else {
        message = _biometricResultMessage(strings, result);
      }
    } else {
      final result = await ref
          .read(authControllerProvider.notifier)
          .enableBiometrics();
      _biometricEnabled = result == BiometricAuthResult.success;
      message = result == BiometricAuthResult.success
          ? strings.text('biometricEnabled')
          : _biometricResultMessage(strings, result);
    }
    if (!mounted) return;
    setState(() => _biometricBusy = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _biometricResultMessage(
    AppLocalizations strings,
    BiometricAuthResult result,
  ) => switch (result) {
    BiometricAuthResult.notEnrolled => strings.text('biometricNotEnrolled'),
    BiometricAuthResult.temporaryLockout => strings.text(
      'biometricTemporaryLockout',
    ),
    BiometricAuthResult.permanentLockout => strings.text(
      'biometricPermanentLockout',
    ),
    BiometricAuthResult.unavailable => strings.text('biometricUnavailable'),
    _ => strings.text('biometricEnableFailed'),
  };
}
