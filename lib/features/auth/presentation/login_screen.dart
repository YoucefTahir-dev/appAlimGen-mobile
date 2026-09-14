import 'package:app_alim_gen_mobile/core/widgets/language_menu.dart';
import 'package:app_alim_gen_mobile/features/auth/presentation/auth_controller.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final auth = ref.watch(authControllerProvider);
    final busy = auth.status == AuthStatus.submitting;
    return Scaffold(
      appBar: AppBar(actions: const [LanguageMenu()]),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 104,
                          semanticLabel: strings.app,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          strings.login,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          key: const Key('username'),
                          controller: _username,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: strings.username,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? strings.required
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('password'),
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: strings.password,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? strings.required
                              : null,
                          onFieldSubmitted: busy ? null : (_) => _submit(),
                        ),
                        if (auth.failure != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                auth.failure!.message,
                                key: const Key('login-error'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('login-button'),
                            onPressed: busy ? null : _submit,
                            child: busy
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(strings.signIn),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    ref
        .read(authControllerProvider.notifier)
        .login(_username.text, _password.text);
  }
}
