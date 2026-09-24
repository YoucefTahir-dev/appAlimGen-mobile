import 'package:app_alim_gen_mobile/app/theme/app_colors.dart';
import 'package:app_alim_gen_mobile/core/navigation/app_drawer.dart';
import 'package:app_alim_gen_mobile/core/navigation/app_module.dart';
import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:app_alim_gen_mobile/core/widgets/language_menu.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ModuleScaffold extends ConsumerStatefulWidget {
  const ModuleScaffold({
    super.key,
    required this.title,
    required this.path,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
  });

  final String title;
  final String path;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  @override
  ConsumerState<ModuleScaffold> createState() => _ModuleScaffoldState();
}

class _ModuleScaffoldState extends ConsumerState<ModuleScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final permissions = PermissionService(user?.permissions ?? const {});
    final strings = AppLocalizations.of(context);
    final destinations = _mobileDestinations(permissions);
    final selected = destinations.indexWhere(
      (item) => item.path == widget.path,
    );
    final width = MediaQuery.sizeOf(context).width;
    final body = width >= 960
        ? Row(
            children: [
              NavigationRail(
                key: const Key('tablet-navigation'),
                selectedIndex: selected < 0 ? destinations.length : selected,
                labelType: NavigationRailLabelType.all,
                groupAlignment: -0.65,
                onDestinationSelected: (index) {
                  if (index == destinations.length) {
                    _scaffoldKey.currentState?.openDrawer();
                  } else {
                    context.go(destinations[index].path);
                  }
                },
                destinations: [
                  ...destinations.map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.icon, color: AppColors.primary),
                      label: Text(strings.text(item.labelKey)),
                    ),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.grid_view_rounded),
                    label: Text(strings.text('more')),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: widget.body),
            ],
          )
        : widget.body;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        titleSpacing: 4,
        title: Text(widget.title),
        actions: [
          ...widget.actions,
          const LanguageMenu(),
          const SizedBox(width: 4),
        ],
      ),
      drawer: AppDrawer(currentPath: widget.path),
      body: SafeArea(top: false, child: body),
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: width < 720
          ? NavigationBar(
              key: const Key('mobile-navigation'),
              selectedIndex: selected < 0 ? destinations.length : selected,
              onDestinationSelected: (index) {
                if (index == destinations.length) {
                  _scaffoldKey.currentState?.openDrawer();
                } else {
                  context.go(destinations[index].path);
                }
              },
              destinations: [
                ...destinations.map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.icon, color: AppColors.primary),
                    label: strings.text(item.labelKey),
                  ),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.grid_view_rounded),
                  label: strings.text('more'),
                ),
              ],
            )
          : null,
    );
  }

  List<AppModule> _mobileDestinations(PermissionService permissions) {
    const preferredPaths = [
      '/dashboard',
      '/sales',
      '/clients',
      '/operator-stock',
    ];
    return preferredPaths
        .map((path) => appModules.firstWhere((item) => item.path == path))
        .where((item) => item.allowed(permissions))
        .take(4)
        .toList(growable: false);
  }
}
