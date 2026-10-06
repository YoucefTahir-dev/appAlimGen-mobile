import 'package:app_alim_gen_mobile/app/providers.dart';
import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';
import 'package:app_alim_gen_mobile/core/widgets/language_menu.dart';
import 'package:app_alim_gen_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;
  AppFailure? _failure;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/login')),
        actions: const [LanguageMenu()],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _submitted
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.mark_email_read_outlined,
                              size: 56,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              strings.text('resetNeutralMessage'),
                              key: const Key('password-reset-success'),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () => context.go('/login'),
                              child: Text(strings.text('backToLogin')),
                            ),
                          ],
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                strings.text('forgotPassword'),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(strings.text('forgotPasswordHelp')),
                              const SizedBox(height: 24),
                              TextFormField(
                                key: const Key('reset-email'),
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: InputDecoration(
                                  labelText: strings.text('email'),
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) return strings.required;
                                  if (!email.contains('@')) {
                                    return strings.text('invalidEmail');
                                  }
                                  return null;
                                },
                                onFieldSubmitted: _submitting
                                    ? null
                                    : (_) => _submit(),
                              ),
                              if (_failure != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _failure!.message,
                                  key: const Key('password-reset-error'),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              FilledButton(
                                key: const Key('password-reset-submit'),
                                onPressed: _submitting ? null : _submit,
                                child: _submitting
                                    ? const SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(strings.text('sendResetLink')),
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

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _submitting = true;
      _failure = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(_email.text);
      if (mounted) setState(() => _submitted = true);
    } catch (error) {
      if (mounted) {
        setState(() => _failure = ref.read(errorMapperProvider).map(error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
