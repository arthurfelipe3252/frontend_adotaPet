import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/notifications/app_notifier.dart';
import 'package:adota_pet/core/theme/app_dimens.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/presentation/pages/desktop/_error_banner.dart';
import 'package:adota_pet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/user_settings_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/page_header.dart';
import 'package:adota_pet/presentation/widgets/primary_button.dart';
import 'package:adota_pet/presentation/widgets/section_card.dart';
import 'package:adota_pet/presentation/widgets/state_views.dart';
import 'package:adota_pet/presentation/widgets/text_field_themed.dart';

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _documentoCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _telefoneContatoCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _logradouroCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _senhaAtualCtrl = TextEditingController();
  final _senhaNovaCtrl = TextEditingController();
  final _confirmarSenhaCtrl = TextEditingController();

  Timer? _cepDebounce;
  bool _didRequestLoad = false;
  bool _showSenhaAtual = false;
  bool _showSenhaNova = false;
  bool _showConfirmarSenha = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRequestLoad) return;
    final usuario = context.read<AuthViewModel>().session?.usuario;
    if (usuario == null) return;
    _didRequestLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final vm = context.read<UserSettingsViewModel>();
      await vm.loadFor(usuario);
      if (mounted) _syncFromVm(vm);
    });
  }

  @override
  void dispose() {
    _cepDebounce?.cancel();
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _documentoCtrl.dispose();
    _telefoneCtrl.dispose();
    _telefoneContatoCtrl.dispose();
    _descricaoCtrl.dispose();
    _cepCtrl.dispose();
    _logradouroCtrl.dispose();
    _numeroCtrl.dispose();
    _complementoCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    _senhaAtualCtrl.dispose();
    _senhaNovaCtrl.dispose();
    _confirmarSenhaCtrl.dispose();
    super.dispose();
  }

  void _syncFromVm(UserSettingsViewModel vm) {
    _setText(_nomeCtrl, vm.nome);
    _setText(_emailCtrl, vm.email);
    _setText(_documentoCtrl, _formatDocumento(vm));
    _setText(_telefoneCtrl, _formatWithMask(_telefoneMask, vm.telefone));
    _setText(
      _telefoneContatoCtrl,
      _formatWithMask(_telefoneMask, vm.telefoneContato),
    );
    _setText(_descricaoCtrl, vm.descricao);
    _setText(_cepCtrl, _formatWithMask(_cepMask, vm.cep));
    _setText(_logradouroCtrl, vm.logradouro);
    _setText(_numeroCtrl, vm.numero);
    _setText(_complementoCtrl, vm.complemento);
    _setText(_bairroCtrl, vm.bairro);
    _setText(_cidadeCtrl, vm.cidade);
    _setText(_estadoCtrl, vm.estado);

    if (vm.senhaAtual.isEmpty) _setText(_senhaAtualCtrl, '');
    if (vm.senhaNova.isEmpty) _setText(_senhaNovaCtrl, '');
    if (vm.confirmarSenha.isEmpty) _setText(_confirmarSenhaCtrl, '');
  }

  void _setText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  String _formatDocumento(UserSettingsViewModel vm) {
    final mask = vm.isOng ? _cnpjMask : _cpfMask;
    return _formatWithMask(mask, vm.documento);
  }

  String _formatWithMask(MaskTextInputFormatter mask, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    return mask.maskText(digits);
  }

  void _onCepChanged(String value, UserSettingsViewModel vm) {
    vm.setCep(value);
    _cepDebounce?.cancel();
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 8) {
      _cepDebounce = Timer(const Duration(milliseconds: 500), () async {
        await vm.consultarCep();
        if (mounted) _syncFromVm(vm);
      });
    }
  }

  Future<void> _saveProfile() async {
    final vm = context.read<UserSettingsViewModel>();
    final updatedUsuario = await vm.saveProfile();
    if (!mounted || updatedUsuario == null) return;
    context.read<AuthViewModel>().updateUsuario(updatedUsuario);
    AppNotifier.instance.success('Configurações salvas.');
  }

  Future<void> _changePassword() async {
    final ok = await context.read<UserSettingsViewModel>().changePassword();
    if (!mounted || !ok) return;
    _senhaAtualCtrl.clear();
    _senhaNovaCtrl.clear();
    _confirmarSenhaCtrl.clear();
    AppNotifier.instance.success('Senha alterada.');
  }

  Future<void> _logoutAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair de todos os dispositivos'),
        content: const Text(
          'Todas as sessões ativas desta conta serão encerradas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Encerrar sessões'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthViewModel>().logoutAll();
    if (mounted) context.go('/login');
  }

  Future<void> _logoutCurrent() async {
    await context.read<AuthViewModel>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserSettingsViewModel>();

    return ColoredBox(
      color: AppTheme.background,
      child: vm.isLoading
          ? const LoadingView()
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async {
                final usuario = context.read<AuthViewModel>().session?.usuario;
                if (usuario != null) {
                  final vm = context.read<UserSettingsViewModel>();
                  await vm.loadFor(usuario, force: true);
                  if (mounted) _syncFromVm(vm);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const PageHeader(
                          title: 'Configurações',
                          subtitle:
                              'Gerencie os dados da sua conta e da organização.',
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (vm.error != null) ...[
                          ErrorBanner(message: vm.error!),
                          const SizedBox(height: 16),
                        ],
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 920;
                            final profile = _ProfileSection(
                              vm: vm,
                              nomeCtrl: _nomeCtrl,
                              emailCtrl: _emailCtrl,
                              documentoCtrl: _documentoCtrl,
                              telefoneCtrl: _telefoneCtrl,
                              telefoneContatoCtrl: _telefoneContatoCtrl,
                              descricaoCtrl: _descricaoCtrl,
                              telefoneMask: _telefoneMask,
                            );
                            final address = _AddressSection(
                              vm: vm,
                              cepCtrl: _cepCtrl,
                              logradouroCtrl: _logradouroCtrl,
                              numeroCtrl: _numeroCtrl,
                              complementoCtrl: _complementoCtrl,
                              bairroCtrl: _bairroCtrl,
                              cidadeCtrl: _cidadeCtrl,
                              estadoCtrl: _estadoCtrl,
                              cepMask: _cepMask,
                              onCepChanged: _onCepChanged,
                            );

                            if (!wide) {
                              return Column(
                                children: [
                                  profile,
                                  const SizedBox(height: 16),
                                  address,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: profile),
                                const SizedBox(width: 16),
                                Expanded(flex: 4, child: address),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, c) {
                            final wide = c.maxWidth >= 520;
                            final btn = PrimaryButton(
                              label: 'Salvar alterações',
                              trailingIcon: Icons.check_rounded,
                              fullWidth: !wide,
                              isLoading: vm.isSavingProfile,
                              onPressed: _saveProfile,
                            );
                            return wide
                                ? Align(
                                    alignment: Alignment.centerRight,
                                    child: btn,
                                  )
                                : btn;
                          },
                        ),
                        const SizedBox(height: 24),
                        _PasswordSection(
                          vm: vm,
                          senhaAtualCtrl: _senhaAtualCtrl,
                          senhaNovaCtrl: _senhaNovaCtrl,
                          confirmarSenhaCtrl: _confirmarSenhaCtrl,
                          showSenhaAtual: _showSenhaAtual,
                          showSenhaNova: _showSenhaNova,
                          showConfirmarSenha: _showConfirmarSenha,
                          onToggleSenhaAtual: () => setState(
                            () => _showSenhaAtual = !_showSenhaAtual,
                          ),
                          onToggleSenhaNova: () =>
                              setState(() => _showSenhaNova = !_showSenhaNova),
                          onToggleConfirmarSenha: () => setState(
                            () => _showConfirmarSenha = !_showConfirmarSenha,
                          ),
                          onSubmit: _changePassword,
                        ),
                        const SizedBox(height: 16),
                        _SessionsSection(
                          onLogoutCurrent: _logoutCurrent,
                          onLogoutAll: _logoutAll,
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

class _ProfileSection extends StatelessWidget {
  final UserSettingsViewModel vm;
  final TextEditingController nomeCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController documentoCtrl;
  final TextEditingController telefoneCtrl;
  final TextEditingController telefoneContatoCtrl;
  final TextEditingController descricaoCtrl;
  final MaskTextInputFormatter telefoneMask;

  const _ProfileSection({
    required this.vm,
    required this.nomeCtrl,
    required this.emailCtrl,
    required this.documentoCtrl,
    required this.telefoneCtrl,
    required this.telefoneContatoCtrl,
    required this.descricaoCtrl,
    required this.telefoneMask,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Perfil',
      icon: Icons.manage_accounts_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileImagePicker(vm: vm),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.verified_user_outlined,
                      label: vm.tipoLabel,
                    ),
                    _InfoPill(
                      icon: Icons.mail_outline_rounded,
                      label: vm.email.isEmpty ? 'Email' : vm.email,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFieldThemed(
            label: vm.isOng ? 'Nome da organização' : 'Nome completo',
            controller: nomeCtrl,
            prefixIcon: vm.isOng
                ? Icons.business_outlined
                : Icons.person_outline_rounded,
            errorText: vm.fieldErrors['nome'],
            onChanged: vm.setNome,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFieldThemed(
                  label: 'E-mail',
                  controller: emailCtrl,
                  prefixIcon: Icons.mail_outline_rounded,
                  enabled: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFieldThemed(
                  label: vm.isOng ? 'CNPJ' : 'CPF',
                  controller: documentoCtrl,
                  prefixIcon: Icons.badge_outlined,
                  enabled: false,
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
              if (vm.isProtetorOuOng) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: TextFieldThemed(
                    label: 'Telefone público',
                    hint: '(00) 00000-0000',
                    controller: telefoneContatoCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [telefoneMask],
                    prefixIcon: Icons.support_agent_outlined,
                    errorText: vm.fieldErrors['telefoneContato'],
                    onChanged: vm.setTelefoneContato,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ],
          ),
          if (vm.isProtetorOuOng) ...[
            const SizedBox(height: 16),
            TextFieldThemed(
              label: 'Descrição / Bio',
              controller: descricaoCtrl,
              maxLines: 5,
              minLines: 4,
              maxLength: UserSettingsViewModel.descricaoMaxLength,
              prefixIcon: Icons.notes_rounded,
              errorText: vm.fieldErrors['descricao'],
              onChanged: vm.setDescricao,
            ),
          ],
        ],
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  final UserSettingsViewModel vm;
  final TextEditingController cepCtrl;
  final TextEditingController logradouroCtrl;
  final TextEditingController numeroCtrl;
  final TextEditingController complementoCtrl;
  final TextEditingController bairroCtrl;
  final TextEditingController cidadeCtrl;
  final TextEditingController estadoCtrl;
  final MaskTextInputFormatter cepMask;
  final void Function(String value, UserSettingsViewModel vm) onCepChanged;

  const _AddressSection({
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
    return SectionCard(
      title: 'Endereço',
      icon: Icons.location_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
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
                  onChanged: (value) => onCepChanged(value, vm),
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
                  controller: bairroCtrl,
                  errorText: vm.fieldErrors['bairro'],
                  onChanged: vm.setBairro,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFieldThemed(
                  label: 'Cidade',
                  controller: cidadeCtrl,
                  errorText: vm.fieldErrors['cidade'],
                  onChanged: vm.setCidade,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PasswordSection extends StatelessWidget {
  final UserSettingsViewModel vm;
  final TextEditingController senhaAtualCtrl;
  final TextEditingController senhaNovaCtrl;
  final TextEditingController confirmarSenhaCtrl;
  final bool showSenhaAtual;
  final bool showSenhaNova;
  final bool showConfirmarSenha;
  final VoidCallback onToggleSenhaAtual;
  final VoidCallback onToggleSenhaNova;
  final VoidCallback onToggleConfirmarSenha;
  final VoidCallback onSubmit;

  const _PasswordSection({
    required this.vm,
    required this.senhaAtualCtrl,
    required this.senhaNovaCtrl,
    required this.confirmarSenhaCtrl,
    required this.showSenhaAtual,
    required this.showSenhaNova,
    required this.showConfirmarSenha,
    required this.onToggleSenhaAtual,
    required this.onToggleSenhaNova,
    required this.onToggleConfirmarSenha,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Segurança',
      icon: Icons.lock_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (vm.passwordError != null) ...[
            ErrorBanner(message: vm.passwordError!),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 780;
              final fields = [
                TextFieldThemed(
                  label: 'Senha atual',
                  controller: senhaAtualCtrl,
                  obscureText: !showSenhaAtual,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    icon: Icon(
                      showSenhaAtual
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20,
                    ),
                    onPressed: onToggleSenhaAtual,
                  ),
                  errorText: vm.passwordFieldErrors['senhaAtual'],
                  onChanged: vm.setSenhaAtual,
                ),
                TextFieldThemed(
                  label: 'Nova senha',
                  controller: senhaNovaCtrl,
                  obscureText: !showSenhaNova,
                  prefixIcon: Icons.password_rounded,
                  suffix: IconButton(
                    icon: Icon(
                      showSenhaNova
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20,
                    ),
                    onPressed: onToggleSenhaNova,
                  ),
                  errorText: vm.passwordFieldErrors['senhaNova'],
                  onChanged: vm.setSenhaNova,
                ),
                TextFieldThemed(
                  label: 'Confirmar senha',
                  controller: confirmarSenhaCtrl,
                  obscureText: !showConfirmarSenha,
                  prefixIcon: Icons.password_rounded,
                  suffix: IconButton(
                    icon: Icon(
                      showConfirmarSenha
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20,
                    ),
                    onPressed: onToggleConfirmarSenha,
                  ),
                  errorText: vm.passwordFieldErrors['confirmarSenha'],
                  onChanged: vm.setConfirmarSenha,
                ),
              ];
              if (!wide) {
                return Column(
                  children: [
                    for (final field in fields) ...[
                      field,
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < fields.length; i++) ...[
                    Expanded(child: fields[i]),
                    if (i < fields.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: PrimaryButton(
              label: 'Alterar senha',
              trailingIcon: Icons.key_rounded,
              fullWidth: false,
              variant: PrimaryButtonVariant.sage,
              isLoading: vm.isChangingPassword,
              onPressed: onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionsSection extends StatelessWidget {
  final VoidCallback onLogoutCurrent;
  final VoidCallback onLogoutAll;

  const _SessionsSection({
    required this.onLogoutCurrent,
    required this.onLogoutAll,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Sessões',
      icon: Icons.devices_rounded,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: onLogoutCurrent,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sair desta sessão'),
          ),
          OutlinedButton.icon(
            onPressed: onLogoutAll,
            icon: const Icon(Icons.power_settings_new_rounded, size: 18),
            label: const Text('Sair de todos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.destructive,
              side: const BorderSide(color: AppTheme.destructive),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileImagePicker extends StatelessWidget {
  final UserSettingsViewModel vm;

  const _ProfileImagePicker({required this.vm});

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    vm.setImagem(file.bytes!, file.name);
  }

  @override
  Widget build(BuildContext context) {
    final bytes = vm.imagemBytes ?? _decodeBase64Image(vm.imagemBase64);
    final hasImage = bytes != null && !vm.removerImagem;

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.inputFill,
            border: Border.all(
              color: vm.fieldErrors['imagem'] == null
                  ? AppTheme.border
                  : AppTheme.destructive,
            ),
            image: hasImage
                ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
                : null,
          ),
          child: hasImage
              ? null
              : const Icon(
                  Icons.person_outline_rounded,
                  size: 40,
                  color: AppTheme.mutedForeground,
                ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.photo_camera_outlined, size: 16),
              label: Text(hasImage ? 'Trocar' : 'Adicionar'),
            ),
            if (hasImage)
              IconButton.outlined(
                tooltip: 'Remover foto',
                onPressed: vm.removeImagem,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: AppTheme.destructive,
              ),
          ],
        ),
        if (vm.fieldErrors['imagem'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              vm.fieldErrors['imagem']!,
              style: const TextStyle(color: AppTheme.destructive, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Uint8List? _decodeBase64Image(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    final payload = raw.contains(',') ? raw.split(',').last : raw;
    try {
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
