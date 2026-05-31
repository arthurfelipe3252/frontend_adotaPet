import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/notifications/app_notifier.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/presentation/pages/desktop/_error_banner.dart';
import 'package:adota_pet/presentation/viewmodels/register_protetor_ong_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/animated_symbols_background.dart';
import 'package:adota_pet/presentation/widgets/app_footer.dart';
import 'package:adota_pet/presentation/widgets/app_nav_bar.dart';
import 'package:adota_pet/presentation/widgets/file_upload_card.dart';
import 'package:adota_pet/presentation/widgets/password_strength_indicator.dart';
import 'package:adota_pet/presentation/widgets/pf_pj_toggle.dart';
import 'package:adota_pet/presentation/widgets/primary_button.dart';
import 'package:adota_pet/presentation/widgets/progress_stepper.dart';
import 'package:adota_pet/presentation/widgets/text_field_themed.dart';

class RegisterProtetorOngPage extends StatefulWidget {
  const RegisterProtetorOngPage({super.key});

  @override
  State<RegisterProtetorOngPage> createState() =>
      _RegisterProtetorOngPageState();
}

class _RegisterProtetorOngPageState extends State<RegisterProtetorOngPage> {
  // Step 1
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cpfCnpjCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _telefoneContatoCtrl = TextEditingController();

  // Step 2
  final _cepCtrl = TextEditingController();
  final _logradouroCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmarSenhaCtrl = TextEditingController();

  Timer? _cepDebounce;
  bool _showPassword = false;
  bool _showConfirmar = false;
  String _lastTipoUsuario = 'protetor';

  late final MaskTextInputFormatter _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'\d')},
  );
  late final MaskTextInputFormatter _cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {'#': RegExp(r'\d')},
  );
  late final MaskTextInputFormatter _telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'\d')},
  );
  late final MaskTextInputFormatter _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'\d')},
  );

  @override
  void dispose() {
    _cepDebounce?.cancel();
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _cpfCnpjCtrl.dispose();
    _telefoneCtrl.dispose();
    _telefoneContatoCtrl.dispose();
    _cepCtrl.dispose();
    _logradouroCtrl.dispose();
    _numeroCtrl.dispose();
    _complementoCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    _descricaoCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmarSenhaCtrl.dispose();
    super.dispose();
  }

  void _syncFromVm(RegisterProtetorOngViewModel vm) {
    if (_logradouroCtrl.text != vm.logradouro) {
      _logradouroCtrl.text = vm.logradouro;
    }
    if (_bairroCtrl.text != vm.bairro) {
      _bairroCtrl.text = vm.bairro;
    }
    if (_cidadeCtrl.text != vm.cidade) {
      _cidadeCtrl.text = vm.cidade;
    }
    if (_estadoCtrl.text != vm.estado) {
      _estadoCtrl.text = vm.estado;
    }
    if (_lastTipoUsuario != vm.tipoUsuario) {
      _lastTipoUsuario = vm.tipoUsuario;
      _cpfCnpjCtrl.clear();
      _cpfMask.clear();
      _cnpjMask.clear();
    }
  }

  void _onCepChanged(String value, RegisterProtetorOngViewModel vm) {
    vm.setCep(value);
    _cepDebounce?.cancel();
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 8) {
      _cepDebounce = Timer(
        const Duration(milliseconds: 500),
        () => vm.consultarCep(),
      );
    }
  }

  void _onNext() {
    final vm = context.read<RegisterProtetorOngViewModel>();
    vm.nextStep();
  }

  Future<void> _onSubmit() async {
    final vm = context.read<RegisterProtetorOngViewModel>();
    final ok = await vm.submit();
    if (!mounted) return;
    if (ok) {
      AppNotifier.instance.success('Cadastro realizado com sucesso! 🐾');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterProtetorOngViewModel>();
    _syncFromVm(vm);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedSymbolsBackground()),
          Column(
            children: [
              const AppNavBar(),
              // Página estática: o card tem altura fixa (todo o espaço entre
                // navbar e footer), e o scroll acontece dentro do próprio card.
                Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: SizedBox(
                        height: double.infinity,
                        child: _UnifiedFormCard(
                        vm: vm,
                        nomeCtrl: _nomeCtrl,
                        emailCtrl: _emailCtrl,
                        cpfCnpjCtrl: _cpfCnpjCtrl,
                        telefoneCtrl: _telefoneCtrl,
                        telefoneContatoCtrl: _telefoneContatoCtrl,
                        cepCtrl: _cepCtrl,
                        logradouroCtrl: _logradouroCtrl,
                        numeroCtrl: _numeroCtrl,
                        complementoCtrl: _complementoCtrl,
                        bairroCtrl: _bairroCtrl,
                        cidadeCtrl: _cidadeCtrl,
                        estadoCtrl: _estadoCtrl,
                        descricaoCtrl: _descricaoCtrl,
                        senhaCtrl: _senhaCtrl,
                        confirmarSenhaCtrl: _confirmarSenhaCtrl,
                        cpfMask: _cpfMask,
                        cnpjMask: _cnpjMask,
                        telefoneMask: _telefoneMask,
                        cepMask: _cepMask,
                        showPassword: _showPassword,
                        showConfirmar: _showConfirmar,
                        onTogglePassword: () =>
                            setState(() => _showPassword = !_showPassword),
                        onToggleConfirmar: () =>
                            setState(() => _showConfirmar = !_showConfirmar),
                        onCepChanged: (v) => _onCepChanged(v, vm),
                        onNext: _onNext,
                        onSubmit: _onSubmit,
                        onPrev: () => vm.prevStep(),
                      ),
                    ),
                  ),
                ),
              ),
              ),
              const AppFooter(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card único contendo header (back + título) + stepper + form + bottom bar.
/// Tudo dentro do mesmo container visualmente coeso.
class _UnifiedFormCard extends StatelessWidget {
  final RegisterProtetorOngViewModel vm;
  final TextEditingController nomeCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController cpfCnpjCtrl;
  final TextEditingController telefoneCtrl;
  final TextEditingController telefoneContatoCtrl;
  final TextEditingController cepCtrl;
  final TextEditingController logradouroCtrl;
  final TextEditingController numeroCtrl;
  final TextEditingController complementoCtrl;
  final TextEditingController bairroCtrl;
  final TextEditingController cidadeCtrl;
  final TextEditingController estadoCtrl;
  final TextEditingController descricaoCtrl;
  final TextEditingController senhaCtrl;
  final TextEditingController confirmarSenhaCtrl;
  final MaskTextInputFormatter cpfMask;
  final MaskTextInputFormatter cnpjMask;
  final MaskTextInputFormatter telefoneMask;
  final MaskTextInputFormatter cepMask;
  final bool showPassword;
  final bool showConfirmar;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmar;
  final ValueChanged<String> onCepChanged;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final VoidCallback onPrev;

  const _UnifiedFormCard({
    required this.vm,
    required this.nomeCtrl,
    required this.emailCtrl,
    required this.cpfCnpjCtrl,
    required this.telefoneCtrl,
    required this.telefoneContatoCtrl,
    required this.cepCtrl,
    required this.logradouroCtrl,
    required this.numeroCtrl,
    required this.complementoCtrl,
    required this.bairroCtrl,
    required this.cidadeCtrl,
    required this.estadoCtrl,
    required this.descricaoCtrl,
    required this.senhaCtrl,
    required this.confirmarSenhaCtrl,
    required this.cpfMask,
    required this.cnpjMask,
    required this.telefoneMask,
    required this.cepMask,
    required this.showPassword,
    required this.showConfirmar,
    required this.onTogglePassword,
    required this.onToggleConfirmar,
    required this.onCepChanged,
    required this.onNext,
    required this.onSubmit,
    required this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 40,
            offset: Offset(0, 12),
          ),
        ],
      ),
      // Tudo dentro do mesmo scroll: stepper, erro, fields, divider e botões.
      // O card mantém altura fixa (definida pelo parent), e o scroll acontece
      // só aqui dentro.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProgressStepper(
              currentStep: vm.currentStep,
              totalSteps: 2,
              stepLabels: const [
                'Dados da organização',
                'Sobre a organização',
              ],
            ),
            if (vm.error != null) ...[
              const SizedBox(height: 20),
              ErrorBanner(message: vm.error!),
            ],
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: vm.currentStep == 0
                  ? _Step1Fields(
                      key: const ValueKey('step-1'),
                      vm: vm,
                      nomeCtrl: nomeCtrl,
                      emailCtrl: emailCtrl,
                      cpfCnpjCtrl: cpfCnpjCtrl,
                      telefoneCtrl: telefoneCtrl,
                      telefoneContatoCtrl: telefoneContatoCtrl,
                      cpfMask: cpfMask,
                      cnpjMask: cnpjMask,
                      telefoneMask: telefoneMask,
                    )
                  : _Step2Fields(
                      key: const ValueKey('step-2'),
                      vm: vm,
                      cepCtrl: cepCtrl,
                      logradouroCtrl: logradouroCtrl,
                      numeroCtrl: numeroCtrl,
                      complementoCtrl: complementoCtrl,
                      bairroCtrl: bairroCtrl,
                      cidadeCtrl: cidadeCtrl,
                      estadoCtrl: estadoCtrl,
                      descricaoCtrl: descricaoCtrl,
                      senhaCtrl: senhaCtrl,
                      confirmarSenhaCtrl: confirmarSenhaCtrl,
                      cepMask: cepMask,
                      onCepChanged: onCepChanged,
                      showPassword: showPassword,
                      showConfirmar: showConfirmar,
                      onTogglePassword: onTogglePassword,
                      onToggleConfirmar: onToggleConfirmar,
                    ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: AppTheme.border),
            const SizedBox(height: 20),
            _BottomBar(
              vm: vm,
              onNext: onNext,
              onSubmit: onSubmit,
              onPrev: onPrev,
            ),
          ],
        ),
      ),
    );
  }
}

class _Step1Fields extends StatelessWidget {
  final RegisterProtetorOngViewModel vm;
  final TextEditingController nomeCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController cpfCnpjCtrl;
  final TextEditingController telefoneCtrl;
  final TextEditingController telefoneContatoCtrl;
  final MaskTextInputFormatter cpfMask;
  final MaskTextInputFormatter cnpjMask;
  final MaskTextInputFormatter telefoneMask;

  const _Step1Fields({
    super.key,
    required this.vm,
    required this.nomeCtrl,
    required this.emailCtrl,
    required this.cpfCnpjCtrl,
    required this.telefoneCtrl,
    required this.telefoneContatoCtrl,
    required this.cpfMask,
    required this.cnpjMask,
    required this.telefoneMask,
  });

  @override
  Widget build(BuildContext context) {
    final isPF = vm.tipoUsuario == 'protetor';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PfPjToggle(selected: vm.tipoUsuario, onChanged: vm.setTipoUsuario),
        const SizedBox(height: 24),
        TextFieldThemed(
          label: isPF ? 'Nome completo' : 'Nome da organização',
          hint: isPF ? 'Seu nome completo' : 'Nome da ONG',
          controller: nomeCtrl,
          prefixIcon: isPF
              ? Icons.person_outline_rounded
              : Icons.business_outlined,
          errorText: vm.fieldErrors['nome'],
          onChanged: vm.setNome,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextFieldThemed(
          label: isPF ? 'CPF' : 'CNPJ',
          hint: isPF ? '000.000.000-00' : '00.000.000/0000-00',
          controller: cpfCnpjCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [isPF ? cpfMask : cnpjMask],
          prefixIcon: Icons.badge_outlined,
          errorText: vm.fieldErrors['cpfCnpj'],
          onChanged: vm.setCpfCnpj,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextFieldThemed(
          label: 'E-mail',
          hint: 'contato@ong.org',
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
          errorText: vm.fieldErrors['email'],
          onChanged: vm.setEmail,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFieldThemed(
                label: 'Telefone',
                hint: '(00) 00000-0000',
                controller: telefoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [telefoneMask],
                prefixIcon: Icons.phone_outlined,
                errorText: vm.fieldErrors['telefone'],
                onChanged: vm.setTelefone,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFieldThemed(
                label: 'Telefone de contato',
                hint: 'Público (opcional)',
                controller: telefoneContatoCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [telefoneMask],
                prefixIcon: Icons.support_agent_outlined,
                errorText: vm.fieldErrors['telefoneContato'],
                onChanged: vm.setTelefoneContato,
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Step2Fields extends StatelessWidget {
  final RegisterProtetorOngViewModel vm;
  final TextEditingController cepCtrl;
  final TextEditingController logradouroCtrl;
  final TextEditingController numeroCtrl;
  final TextEditingController complementoCtrl;
  final TextEditingController bairroCtrl;
  final TextEditingController cidadeCtrl;
  final TextEditingController estadoCtrl;
  final TextEditingController descricaoCtrl;
  final TextEditingController senhaCtrl;
  final TextEditingController confirmarSenhaCtrl;
  final MaskTextInputFormatter cepMask;
  final ValueChanged<String> onCepChanged;
  final bool showPassword;
  final bool showConfirmar;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmar;

  const _Step2Fields({
    super.key,
    required this.vm,
    required this.cepCtrl,
    required this.logradouroCtrl,
    required this.numeroCtrl,
    required this.complementoCtrl,
    required this.bairroCtrl,
    required this.cidadeCtrl,
    required this.estadoCtrl,
    required this.descricaoCtrl,
    required this.senhaCtrl,
    required this.confirmarSenhaCtrl,
    required this.cepMask,
    required this.onCepChanged,
    required this.showPassword,
    required this.showConfirmar,
    required this.onTogglePassword,
    required this.onToggleConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFieldThemed(
                label: 'CEP',
                hint: '00000-000',
                controller: cepCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [cepMask],
                prefixIcon: Icons.location_on_outlined,
                suffix: vm.isCepLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                errorText: vm.fieldErrors['cep'],
                onChanged: onCepChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFieldThemed(
                label: 'UF',
                hint: 'SP',
                controller: estadoCtrl,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(2),
                  _UpperCaseFormatter(),
                ],
                prefixIcon: Icons.map_outlined,
                errorText: vm.fieldErrors['estado'],
                onChanged: vm.setEstado,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFieldThemed(
          label: 'Logradouro',
          hint: 'Rua, avenida...',
          controller: logradouroCtrl,
          prefixIcon: Icons.signpost_outlined,
          errorText: vm.fieldErrors['logradouro'],
          onChanged: vm.setLogradouro,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFieldThemed(
                label: 'Número',
                hint: '100',
                controller: numeroCtrl,
                errorText: vm.fieldErrors['numero'],
                onChanged: vm.setNumero,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFieldThemed(
                label: 'Complemento',
                hint: 'Apto, sala (opcional)',
                controller: complementoCtrl,
                errorText: vm.fieldErrors['complemento'],
                onChanged: vm.setComplemento,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFieldThemed(
                label: 'Bairro',
                hint: 'Bairro',
                controller: bairroCtrl,
                errorText: vm.fieldErrors['bairro'],
                onChanged: vm.setBairro,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFieldThemed(
                label: 'Cidade',
                hint: 'Cidade',
                controller: cidadeCtrl,
                errorText: vm.fieldErrors['cidade'],
                onChanged: vm.setCidade,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FileUploadCard(
          label: 'Foto de perfil',
          hint: 'JPG, PNG · máx. 5MB (opcional)',
          icon: Icons.photo_camera_outlined,
          bytes: vm.imagemBytes,
          filename: vm.imagemFilename,
          allowedExtensions: const ['jpg', 'jpeg', 'png'],
          onPick: vm.setImagem,
          onRemove: () => vm.setImagem(null, null),
          errorText: vm.fieldErrors['imagem'],
        ),
        const SizedBox(height: 16),
        FileUploadCard(
          label: 'Documento comprobatório',
          hint:
              'Cartão CNPJ, contrato social ou documento oficial. PDF, JPG, PNG · máx. 5MB',
          icon: Icons.shield_outlined,
          bytes: vm.documentoBytes,
          filename: vm.documentoFilename,
          allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
          onPick: vm.setDocumento,
          onRemove: () => vm.setDocumento(null, null),
          errorText: vm.fieldErrors['documento'],
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: AppTheme.mutedForeground,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Seus documentos são tratados com sigilo total (LGPD)',
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextFieldThemed(
          label: 'Descrição / Bio',
          hint:
              'Conte um pouco sobre você ou sua organização, sua missão e como trabalha com os animais...',
          controller: descricaoCtrl,
          maxLines: 5,
          minLines: 4,
          maxLength: RegisterProtetorOngViewModel.descricaoMaxLength,
          errorText: vm.fieldErrors['descricao'],
          onChanged: vm.setDescricao,
        ),
        const SizedBox(height: 16),
        TextFieldThemed(
          label: 'Senha',
          hint: 'Crie uma senha forte',
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
          errorText: vm.fieldErrors['senha'],
          onChanged: vm.setSenha,
        ),
        PasswordStrengthIndicator(strength: vm.senhaForca),
        const SizedBox(height: 16),
        TextFieldThemed(
          label: 'Confirmar senha',
          hint: 'Repita a senha',
          controller: confirmarSenhaCtrl,
          obscureText: !showConfirmar,
          prefixIcon: Icons.lock_outline_rounded,
          suffix: IconButton(
            icon: Icon(
              showConfirmar
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: 20,
            ),
            onPressed: onToggleConfirmar,
          ),
          errorText: vm.fieldErrors['confirmarSenha'],
          onChanged: vm.setConfirmarSenha,
        ),
        const SizedBox(height: 20),
        _TermosCheckbox(
          value: vm.aceitaTermos,
          onChanged: vm.setAceitaTermos,
          label: 'Termos de Uso',
        ),
        const SizedBox(height: 8),
        _TermosCheckbox(
          value: vm.aceitaPrivacidade,
          onChanged: vm.setAceitaPrivacidade,
          label: 'Política de Privacidade',
          suffix: ' (LGPD)',
        ),
      ],
    );
  }
}

class _TermosCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final String? suffix;

  const _TermosCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: value,
                  onChanged: (v) => onChanged(v ?? false),
                  shape: const CircleBorder(),
                  activeColor: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppTheme.foreground,
                      fontSize: 14,
                    ),
                    children: [
                      const TextSpan(text: 'Li e aceito '),
                      TextSpan(
                        text: label,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      if (suffix != null) TextSpan(text: suffix!),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final RegisterProtetorOngViewModel vm;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final VoidCallback onPrev;

  const _BottomBar({
    required this.vm,
    required this.onNext,
    required this.onSubmit,
    required this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    if (vm.currentStep == 0) {
      return PrimaryButton(
        label: 'Próximo',
        trailingIcon: Icons.arrow_forward_rounded,
        variant: PrimaryButtonVariant.sage,
        onPressed: onNext,
      );
    }

    return Column(
      children: [
        PrimaryButton(
          label: 'Finalizar cadastro',
          trailingIcon: Icons.check_rounded,
          variant: PrimaryButtonVariant.sage,
          isLoading: vm.isLoading,
          onPressed: onSubmit,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: vm.isLoading ? null : onPrev,
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text('Voltar'),
        ),
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
