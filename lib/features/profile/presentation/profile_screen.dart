import 'package:app_alim_gen_mobile/core/navigation/module_scaffold.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
}
