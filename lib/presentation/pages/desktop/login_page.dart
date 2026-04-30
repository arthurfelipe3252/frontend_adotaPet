import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/platform/platform_info.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/presentation/pages/desktop/_auth_hero_panel.dart';
import 'package:adota_pet/presentation/pages/desktop/_error_banner.dart';
import 'package:adota_pet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/app_logo.dart';
import 'package:adota_pet/presentation/widgets/primary_button.dart';
import 'package:adota_pet/presentation/widgets/text_field_themed.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = context.read<AuthViewModel>();
    final ok = await vm.login(_emailCtrl.text, _senhaCtrl.text);
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
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
                        const AppLogo(size: 64),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        'Bem-vindo de volta 🐾',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Acesse sua conta para continuar',
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (vm.error != null) ...[
                        ErrorBanner(message: vm.error!),
                        const SizedBox(height: 18),
                      ],
                      TextFieldThemed(
                        label: 'E-mail',
                        hint: 'seu@email.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline_rounded,
                        textInputAction: TextInputAction.next,
                        errorText: vm.fieldErrors['email'],
                        onChanged: (_) {
                          if (vm.error != null) vm.clearError();
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFieldThemed(
                        label: 'Senha',
                        hint: '••••••••',
                        controller: _senhaCtrl,
                        obscureText: !_showPassword,
                        prefixIcon: Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        errorText: vm.fieldErrors['senha'],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text('Esqueci minha senha'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PrimaryButton(
                        label: 'Entrar',
                        trailingIcon: Icons.arrow_forward_rounded,
                        isLoading: vm.isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 28),
                      const _OuDivider(),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => context.push('/register-org'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: const Text('Criar uma conta'),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'Ao acessar, você concorda com os Termos de Uso\n'
                          'e a Política de Privacidade.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.mutedForeground,
                            fontSize: 12,
                          ),
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

class _OuDivider extends StatelessWidget {
  const _OuDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
