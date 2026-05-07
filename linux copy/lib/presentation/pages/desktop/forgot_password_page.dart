import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/notifications/app_notifier.dart';
import 'package:adota_pet/core/platform/platform_info.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/presentation/pages/desktop/_auth_hero_panel.dart';
import 'package:adota_pet/presentation/viewmodels/forgot_password_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/app_logo.dart';
import 'package:adota_pet/presentation/widgets/primary_button.dart';
import 'package:adota_pet/presentation/widgets/text_field_themed.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = context.read<ForgotPasswordViewModel>();
    vm.setEmail(_emailCtrl.text);
    await vm.submit();

    if (!mounted) return;
    if (vm.sent) {
      AppNotifier.instance.success(
        'Se este email existir, enviamos um link de recuperação.',
      );
      vm.reset();
      _emailCtrl.clear();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ForgotPasswordViewModel>();
    final isDesktop = PlatformInfo.isDesktopWidth(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          if (isDesktop) const Expanded(flex: 5, child: AuthHeroPanel()),
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 48,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isDesktop) ...[
                        const AppLogo(size: 56),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        'Esqueci minha senha',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Digite seu email e enviaremos um link para criar uma nova senha.',
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFieldThemed(
                        label: 'E-mail',
                        hint: 'seu@email.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline_rounded,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        onChanged: (v) => vm.setEmail(v),
                        errorText: vm.fieldErrors['email'],
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Enviar link de recuperação',
                        trailingIcon: Icons.arrow_forward_rounded,
                        isLoading: vm.isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text('Voltar ao login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
