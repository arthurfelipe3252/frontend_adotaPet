import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/notifications/app_notifier.dart';
import 'package:adota_pet/core/platform/platform_info.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/presentation/pages/desktop/_auth_hero_panel.dart';
import 'package:adota_pet/presentation/viewmodels/reset_password_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/app_logo.dart';
import 'package:adota_pet/presentation/widgets/primary_button.dart';
import 'package:adota_pet/presentation/widgets/text_field_themed.dart';

/// Tela aberta a partir do link enviado por e-mail
/// (`/reset-password?token=...`). Usada tanto no fluxo web quanto mobile —
/// no mobile, hoje, o link abre no navegador do sistema (sem deep link
/// configurado ainda); ver PLANO_recuperacao_senha.md para o que falta caso
/// se queira abrir direto no app.
class ResetPasswordPage extends StatefulWidget {
  final String? token;

  const ResetPasswordPage({super.key, this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _senhaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _showSenha = false;
  bool _showConfirmar = false;

  @override
  void dispose() {
    _senhaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = context.read<ResetPasswordViewModel>();
    vm.setNovaSenha(_senhaCtrl.text);
    vm.setConfirmarSenha(_confirmarCtrl.text);
    await vm.submit(widget.token);

    if (!mounted) return;
    if (vm.done) {
      AppNotifier.instance.success(
        'Senha redefinida com sucesso. Faça login com a nova senha.',
      );
      vm.reset();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      context.go('/login');
    } else if (vm.error != null) {
      AppNotifier.instance.error(vm.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ResetPasswordViewModel>();
    final isDesktop = PlatformInfo.isDesktopWidth(context);

    // Sem token na URL: link malformado/incompleto. Mostra estado de erro
    // em vez do formulário, com saída clara para solicitar um novo link.
    if (widget.token == null || widget.token!.isEmpty) {
      return _InvalidTokenView(isDesktop: isDesktop);
    }

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
                        'Defina uma nova senha',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Escolha uma nova senha para acessar sua conta.',
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextFieldThemed(
                        label: 'Nova senha',
                        hint: 'Mínimo de 8 caracteres',
                        controller: _senhaCtrl,
                        obscureText: !_showSenha,
                        prefixIcon: Icons.lock_outline_rounded,
                        textInputAction: TextInputAction.next,
                        onChanged: (v) => vm.setNovaSenha(v),
                        errorText: vm.fieldErrors['novaSenha'],
                        suffix: IconButton(
                          icon: Icon(
                            _showSenha
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _showSenha = !_showSenha),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFieldThemed(
                        label: 'Confirmar nova senha',
                        hint: 'Repita a senha',
                        controller: _confirmarCtrl,
                        obscureText: !_showConfirmar,
                        prefixIcon: Icons.lock_outline_rounded,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        onChanged: (v) => vm.setConfirmarSenha(v),
                        errorText: vm.fieldErrors['confirmarSenha'],
                        suffix: IconButton(
                          icon: Icon(
                            _showConfirmar
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _showConfirmar = !_showConfirmar,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Redefinir senha',
                        trailingIcon: Icons.check_rounded,
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

class _InvalidTokenView extends StatelessWidget {
  final bool isDesktop;

  const _InvalidTokenView({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          if (isDesktop) const Expanded(flex: 5, child: AuthHeroPanel()),
          Expanded(
            flex: 4,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.link_off_rounded,
                        size: 48,
                        color: AppTheme.mutedForeground,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Link inválido',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Este link de redefinição de senha está incompleto '
                        'ou não foi aberto corretamente. Solicite um novo '
                        'link na tela de login.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Voltar ao login',
                        trailingIcon: Icons.arrow_forward_rounded,
                        onPressed: () => context.go('/login'),
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