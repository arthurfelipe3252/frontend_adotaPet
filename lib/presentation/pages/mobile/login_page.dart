import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:adota_pet/core/notifications/app_notifier.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/usuario.dart';
import 'package:adota_pet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/app_logo.dart';
import 'package:adota_pet/presentation/widgets/primary_button.dart';
import 'package:adota_pet/presentation/widgets/text_field_themed.dart';

/// URL do painel web da ONG/Protetor. Trocar quando o front for hospedado em
/// outro domínio.
const String _painelWebUrl = 'https://adotapet.upperlavtech.com';

/// Largura máxima do "viewport mobile" — bate com o protótipo Lovable e com
/// o `CatalogPage`. Em telas maiores o conteúdo fica centralizado.
const double _mobileMaxWidth = 430.0;

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
    final ok = await vm.login(
      _emailCtrl.text,
      _senhaCtrl.text,
      tiposPermitidos: const {Usuario.tipoAdotante},
      mensagemTipoInvalido:
          'Esta área é exclusiva para adotantes. Acesse o painel web para gerenciar sua ONG ou protetor.',
    );
    if (!mounted) return;
    if (ok) {
      context.go('/home');
      return;
    }
    if (vm.error != null) {
      AppNotifier.instance.error(vm.error!);
      vm.clearError();
    }
  }

  Future<void> _abrirPainelWeb() async {
    final uri = Uri.parse(_painelWebUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppNotifier.instance.error('Não foi possível abrir o painel web.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFEEE8DC), // bg-muted do protótipo
      // Não empurrar a tela quando o teclado abrir — evita overflow num layout
      // sem scroll. O usuário fecha o teclado tocando fora para ver o botão.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: SizedBox(
            width: _mobileMaxWidth,
            child: Container(
              color: AppTheme.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HeroGradient(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        // Sem scroll quando o conteúdo cabe; permite scroll
                        // suave quando o ErrorBanner estoura a tela disponível.
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Transform.translate(
                                      offset: const Offset(0, -8),
                                      child: _LoginCard(
                                        vm: vm,
                                        emailCtrl: _emailCtrl,
                                        senhaCtrl: _senhaCtrl,
                                        showPassword: _showPassword,
                                        onTogglePassword: () => setState(
                                          () =>
                                              _showPassword = !_showPassword,
                                        ),
                                        onSubmit: _submit,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const _OuDivider(),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        // Limpa controllers + erros antes de
                                        // sair pra cadastro. Combinado com
                                        // `go` (não `push`), garante login
                                        // limpo na próxima entrada.
                                        _emailCtrl.clear();
                                        _senhaCtrl.clear();
                                        vm.clearError();
                                        context.go('/register-adotante');
                                      },
                                      style: OutlinedButton.styleFrom(
                                        minimumSize:
                                            const Size(double.infinity, 48),
                                        side: const BorderSide(
                                          color: AppTheme.border,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Text('Criar uma conta'),
                                    ),
                                    const SizedBox(height: 4),
                                    TextButton(
                                      onPressed: _abrirPainelWeb,
                                      child: const Text(
                                        'Sou ONG / Protetor → Acessar painel',
                                        style: TextStyle(
                                          color: AppTheme.mutedForeground,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        'Ao acessar, você concorda com nossos Termos de Uso '
                                        'e Política de Privacidade (LGPD).',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppTheme.mutedForeground,
                                          fontSize: 10,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroGradient extends StatelessWidget {
  const _HeroGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: const Column(
        children: [
          AppLogo(size: 72, onDarkBackground: true),
          SizedBox(height: 14),
          Text(
            'Conectando vidas, transformando histórias.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final AuthViewModel vm;
  final TextEditingController emailCtrl;
  final TextEditingController senhaCtrl;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  const _LoginCard({
    required this.vm,
    required this.emailCtrl,
    required this.senhaCtrl,
    required this.showPassword,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 28,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bem-vindo de volta 🐾',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 2),
          const Text(
            'Acesse sua conta para continuar',
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          TextFieldThemed(
            label: 'E-mail',
            hint: 'seu@email.com',
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
            textInputAction: TextInputAction.next,
            errorText: vm.fieldErrors['email'],
            onChanged: (_) {
              if (vm.error != null) vm.clearError();
            },
          ),
          const SizedBox(height: 8),
          TextFieldThemed(
            label: 'Senha',
            hint: '••••••••',
            controller: senhaCtrl,
            obscureText: !showPassword,
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              icon: Icon(
                showPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
              ),
              onPressed: onTogglePassword,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
            errorText: vm.fieldErrors['senha'],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Esqueci minha senha',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Entrar',
            trailingIcon: Icons.arrow_forward_rounded,
            isLoading: vm.isLoading,
            onPressed: onSubmit,
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
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}