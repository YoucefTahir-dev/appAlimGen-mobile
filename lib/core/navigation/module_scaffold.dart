import 'package:app_alim_gen_mobile/core/navigation/app_drawer.dart';
import 'package:app_alim_gen_mobile/core/widgets/language_menu.dart';
import 'package:flutter/material.dart';

class ModuleScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: [...actions, const LanguageMenu()],
    ),
    drawer: AppDrawer(currentPath: path),
    body: body,
    floatingActionButton: floatingActionButton,
  );
}
