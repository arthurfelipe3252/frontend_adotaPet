import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/notifications/app_notifier.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/presentation/viewmodels/register_adotante_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/password_strength_indicator.dart';
import 'package:adota_pet/presentation/widgets/primary_button.dart';
import 'package:adota_pet/presentation/widgets/progress_stepper.dart';
import 'package:adota_pet/presentation/widgets/text_field_themed.dart';

const double _mobileMaxWidth = 430.0;

class RegisterAdotantePage extends StatefulWidget {
  const RegisterAdotantePage({super.key});

  @override
  State<RegisterAdotantePage> createState() => _RegisterAdotantePageState();
}

class _RegisterAdotantePageState extends State<RegisterAdotantePage> {
  // Step 0
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmarSenhaCtrl = TextEditingController();

  // Step 1
  final _cepCtrl = TextEditingController();
  final _logradouroCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();

  Timer? _cepDebounce;
  bool _showPassword = false;
  bool _showConfirmar = false;

  late final MaskTextInputFormatter _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
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
  void initState() {
    super.initState();
    // Reseta o VM ao entrar na Page para garantir wizard limpo em cada sessão
    // (o VM é singleton no DI e manteria estado entre navegações).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RegisterAdotanteViewModel>().reset();
    });
  }

  @override
  void dispose() {
    _cepDebounce?.cancel();
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _cpfCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmarSenhaCtrl.dispose();
    _cepCtrl.dispose();
    _logradouroCtrl.dispose();
    _numeroCtrl.dispose();
    _complementoCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    super.dispose();
  }

  void _syncFromVm(RegisterAdotanteViewModel vm) {
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
  }

  void _onCepChanged(String value, RegisterAdotanteViewModel vm) {
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
    final vm = context.read<RegisterAdotanteViewModel>();
    final ok = vm.nextStep();
    if (!ok && vm.error != null) {
      AppNotifier.instance.error(vm.error!);
      vm.clearError();
    } else if (!ok && vm.fieldErrors.isNotEmpty) {
      AppNotifier.instance.error(
        'Confira os campos destacados antes de continuar.',
      );
    }
  }

  Future<void> _onSubmit() async {
    final vm = context.read<RegisterAdotanteViewModel>();
    final ok = await vm.submit();
    if (!mounted) return;
    if (ok) {
      AppNotifier.instance.success('Cadastro realizado com sucesso! 🐾');
      context.go('/login');
      return;
    }
    if (vm.error != null) {
      AppNotifier.instance.error(vm.error!);
      vm.clearError();
    } else if (vm.fieldErrors.isNotEmpty) {
      AppNotifier.instance.error(
        'Confira os campos destacados antes de continuar.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterAdotanteViewModel>();
    _syncFromVm(vm);

    return Scaffold(
      backgroundColor: const Color(0xFFEEE8DC),
      body: Center(
        child: SizedBox(
          width: _mobileMaxWidth,
          child: Container(
            color: AppTheme.background,
            child: SafeArea(
              child: Column(
                children: [
                  _Header(currentStep: vm.currentStep),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: ProgressStepper(
                      currentStep: vm.currentStep,
                      totalSteps: 3,
                      stepLabels: const [
                        'Dados pessoais',
                        'Endereço',
                        'Confirmação',
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: _buildStep(vm),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: _BottomBar(
                      vm: vm,
                      onNext: _onNext,
                      onSubmit: _onSubmit,
                      onPrev: () => vm.prevStep(),
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

  Widget _buildStep(RegisterAdotanteViewModel vm) {
    switch (vm.currentStep) {
      case 0:
        return _Step0Dados(
          key: const ValueKey('step-0'),
          vm: vm,
          nomeCtrl: _nomeCtrl,
          emailCtrl: _emailCtrl,
          telefoneCtrl: _telefoneCtrl,
          cpfCtrl: _cpfCtrl,
          senhaCtrl: _senhaCtrl,
          confirmarSenhaCtrl: _confirmarSenhaCtrl,
          cpfMask: _cpfMask,
          telefoneMask: _telefoneMask,
          showPassword: _showPassword,
          showConfirmar: _showConfirmar,
          onTogglePassword: () =>
              setState(() => _showPassword = !_showPassword),
          onToggleConfirmar: () =>
              setState(() => _showConfirmar = !_showConfirmar),
        );
      case 1:
        return _Step1Endereco(
          key: const ValueKey('step-1'),
          vm: vm,
          cepCtrl: _cepCtrl,
          logradouroCtrl: _logradouroCtrl,
          numeroCtrl: _numeroCtrl,
          complementoCtrl: _complementoCtrl,
          bairroCtrl: _bairroCtrl,
          cidadeCtrl: _cidadeCtrl,
          estadoCtrl: _estadoCtrl,
          cepMask: _cepMask,
          onCepChanged: (v) => _onCepChanged(v, vm),
        );
      default:
        return _Step2Revisao(
          key: const ValueKey('step-2'),
          vm: vm,
          onEditar: () => vm.goToStep(0),
        );
    }
  }
}

class _Header extends StatelessWidget {
  final int currentStep;
  const _Header({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            // Sempre `go` (não `pop`) — descarta a Page de cadastro do stack
            // pra que a próxima entrada no cadastro comece com controllers
            // limpos junto com o reset do VM.
            onPressed: () => context.go('/login'),
          ),
          Text(
            'Criar conta — Adotante',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

// ── Step 0: Dados pessoais ────────────────────────────────────────────────────

class _Step0Dados extends StatelessWidget {
  final RegisterAdotanteViewModel vm;
  final TextEditingController nomeCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController telefoneCtrl;
  final TextEditingController cpfCtrl;
  final TextEditingController senhaCtrl;
  final TextEditingController confirmarSenhaCtrl;
  final MaskTextInputFormatter cpfMask;
  final MaskTextInputFormatter telefoneMask;
  final bool showPassword;
  final bool showConfirmar;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmar;

  const _Step0Dados({
    super.key,
    required this.vm,
    required this.nomeCtrl,
    required this.emailCtrl,
    required this.telefoneCtrl,
    required this.cpfCtrl,
    required this.senhaCtrl,
    required this.confirmarSenhaCtrl,
    required this.cpfMask,
    required this.telefoneMask,
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
        Center(
          child: _AvatarUpload(
            bytes: vm.imagemBytes,
            errorText: vm.fieldErrors['imagem'],
            onPick: vm.setImagem,
          ),
        ),
        const SizedBox(height: 24),
        TextFieldThemed(
          label: 'Nome completo',
          hint: 'Seu nome completo',
          controller: nomeCtrl,
          prefixIcon: Icons.person_outline_rounded,
          errorText: vm.fieldErrors['nome'],
          onChanged: vm.setNome,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextFieldThemed(
          label: 'E-mail',
          hint: 'seu@email.com',
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
          errorText: vm.fieldErrors['email'],
          onChanged: vm.setEmail,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextFieldThemed(
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
        const SizedBox(height: 12),
        TextFieldThemed(
          label: 'CPF',
          hint: '000.000.000-00',
          controller: cpfCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [cpfMask],
          prefixIcon: Icons.badge_outlined,
          errorText: vm.fieldErrors['cpf'],
          onChanged: vm.setCpf,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
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
          textInputAction: TextInputAction.next,
        ),
        PasswordStrengthIndicator(strength: vm.senhaForca),
        const SizedBox(height: 12),
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
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

// ── Step 1: Endereço ─────────────────────────────────────────────────────────

class _Step1Endereco extends StatelessWidget {
  final RegisterAdotanteViewModel vm;
  final TextEditingController cepCtrl;
  final TextEditingController logradouroCtrl;
  final TextEditingController numeroCtrl;
  final TextEditingController complementoCtrl;
  final TextEditingController bairroCtrl;
  final TextEditingController cidadeCtrl;
  final TextEditingController estadoCtrl;
  final MaskTextInputFormatter cepMask;
  final ValueChanged<String> onCepChanged;

  const _Step1Endereco({
    super.key,
    required this.vm,
    required this.cepCtrl,
    required this.logradouroCtrl,
    required this.numeroCtrl,
    required this.complementoCtrl,
    required this.bairroCtrl,
    required this.cidadeCtrl,
    required this.estadoCtrl,
    required this.cepMask,
    required this.onCepChanged,
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
        const SizedBox(height: 12),
        TextFieldThemed(
          label: 'Logradouro',
          hint: 'Rua, avenida...',
          controller: logradouroCtrl,
          prefixIcon: Icons.signpost_outlined,
          errorText: vm.fieldErrors['logradouro'],
          onChanged: vm.setLogradouro,
        ),
        const SizedBox(height: 12),
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
                hint: 'Apto, bloco (opcional)',
                controller: complementoCtrl,
                errorText: vm.fieldErrors['complemento'],
                onChanged: vm.setComplemento,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFieldThemed(
          label: 'Bairro',
          hint: 'Bairro',
          controller: bairroCtrl,
          errorText: vm.fieldErrors['bairro'],
          onChanged: vm.setBairro,
        ),
        const SizedBox(height: 12),
        TextFieldThemed(
          label: 'Cidade',
          hint: 'Cidade',
          controller: cidadeCtrl,
          errorText: vm.fieldErrors['cidade'],
          onChanged: vm.setCidade,
        ),
      ],
    );
  }
}

// ── Step 2: Revisão ──────────────────────────────────────────────────────────

class _Step2Revisao extends StatelessWidget {
  final RegisterAdotanteViewModel vm;
  final VoidCallback onEditar;

  const _Step2Revisao({super.key, required this.vm, required this.onEditar});

  String _formatTelefone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return value;
  }

  String _formatCep(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) {
      return '${digits.substring(0, 5)}-${digits.substring(5)}';
    }
    return value;
  }

  String _formatCpf(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final enderecoLinha1 = [
      vm.logradouro,
      vm.numero,
      if (vm.complemento.isNotEmpty) vm.complemento,
    ].where((s) => s.isNotEmpty).join(', ');
    final enderecoLinha2 =
        '${vm.bairro} — ${vm.cidade}/${vm.estado} · ${_formatCep(vm.cep)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Revise seus dados',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1ECE3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResumoLinha(label: 'Nome', value: vm.nome),
              _ResumoLinha(label: 'E-mail', value: vm.email),
              _ResumoLinha(
                label: 'Telefone',
                value: _formatTelefone(vm.telefone),
              ),
              _ResumoLinha(label: 'CPF', value: _formatCpf(vm.cpf)),
              _ResumoLinha(label: 'Endereço', value: enderecoLinha1),
              _ResumoLinha(label: '', value: enderecoLinha2),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onEditar,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text(
                  'Editar dados',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _TermosCheckbox(
          value: vm.aceitaTermos,
          onChanged: vm.setAceitaTermos,
          label: 'Termos de Uso',
          required: true,
        ),
        const SizedBox(height: 6),
        _TermosCheckbox(
          value: vm.aceitaPrivacidade,
          onChanged: vm.setAceitaPrivacidade,
          label: 'Política de Privacidade',
          suffix: ' (LGPD)',
          required: true,
        ),
        const SizedBox(height: 6),
        _TermosCheckbox(
          value: vm.aceitaNewsletter,
          onChanged: vm.setAceitaNewsletter,
          label: 'Quero receber dicas de adoção e novidades por e-mail',
          plainText: true,
        ),
      ],
    );
  }
}

class _ResumoLinha extends StatelessWidget {
  final String label;
  final String value;
  const _ResumoLinha({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              color: AppTheme.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermosCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final String? suffix;
  final bool required;
  final bool plainText;

  const _TermosCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
    this.suffix,
    this.required = false,
    this.plainText = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                shape: const CircleBorder(),
                activeColor: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: plainText
                    ? Text(
                        label,
                        style: const TextStyle(
                          color: AppTheme.foreground,
                          fontSize: 13,
                        ),
                      )
                    : RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: AppTheme.foreground,
                            fontSize: 13,
                          ),
                          children: [
                            const TextSpan(text: 'Li e aceito '),
                            TextSpan(
                              text: label,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            if (suffix != null) TextSpan(text: suffix!),
                            if (required)
                              const TextSpan(
                                text: ' *',
                                style: TextStyle(color: AppTheme.destructive),
                              ),
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

// ── Avatar upload (obrigatório no Step 0) ────────────────────────────────────

class _AvatarUpload extends StatelessWidget {
  final Uint8List? bytes;
  final String? errorText;
  final void Function(Uint8List? bytes, String? filename) onPick;

  const _AvatarUpload({
    required this.bytes,
    required this.errorText,
    required this.onPick,
  });

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    onPick(file.bytes, file.name);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = bytes != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _pick,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF1ECE3),
              shape: BoxShape.circle,
              border: Border.all(
                color: errorText != null
                    ? AppTheme.destructive
                    : AppTheme.border,
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Image.memory(bytes!, fit: BoxFit.cover)
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 32,
                          color: AppTheme.mutedForeground,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Foto *',
                          style: TextStyle(
                            color: AppTheme.mutedForeground,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        if (hasImage)
          TextButton.icon(
            onPressed: () => onPick(null, null),
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Remover foto'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.destructive,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Toque para escolher uma foto · JPG ou PNG · até 5MB',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 11,
              ),
            ),
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: AppTheme.destructive,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final RegisterAdotanteViewModel vm;
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
    final isLastStep = vm.currentStep == 2;
    return Column(
      children: [
        PrimaryButton(
          label: isLastStep ? 'Criar minha conta' : 'Próximo',
          trailingIcon:
              isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
          isLoading: vm.isLoading,
          onPressed: isLastStep ? onSubmit : onNext,
        ),
        if (vm.currentStep > 0) ...[
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: vm.isLoading ? null : onPrev,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Voltar ao passo anterior'),
          ),
        ],
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
