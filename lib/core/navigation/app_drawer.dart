import 'package:app_alim_gen_mobile/core/navigation/app_module.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key, required this.currentPath});
  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).user;
    final permissions = PermissionService(user?.permissions ?? const {});
    final visible = appModules
        .where((module) => module.allowed(permissions))
        .toList(growable: false);
    NavigationSection? previousSection;
    final children = <Widget>[
      UserAccountsDrawerHeader(
        currentAccountPicture: CircleAvatar(
          child: Text(
            (user?.displayName ?? '?').characters.first.toUpperCase(),
          ),
        ),
        accountName: Text(user?.displayName ?? ''),
        accountEmail: Text(user?.role ?? ''),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      ),
    ];
    for (final module in visible) {
      if (module.section != previousSection) {
        children.add(
          _SectionLabel(strings.text('section_${module.section.name}')),
        );
        previousSection = module.section;
      }
      children.add(
        ListTile(
          key: Key('drawer-${module.labelKey}'),
          leading: Icon(module.icon),
          title: Text(strings.text(module.labelKey)),
          selected: currentPath == module.path,
          onTap: () {
            Navigator.pop(context);
            context.go(module.path);
          },
        ),
      );
    }
    children.addAll([
      const Divider(),
      ListTile(
        key: const Key('drawer-logout'),
        leading: const Icon(Icons.logout),
        title: Text(strings.logout),
        onTap: () => _confirmLogout(context, ref),
      ),
      const SafeArea(top: false, child: SizedBox(height: 8)),
    ]);
    return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: children),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.logout),
        content: Text(strings.text('logoutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.logout),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
    child: Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
