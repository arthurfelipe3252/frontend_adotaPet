import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/notifications/app_notifier.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/user_settings_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/confirm_dialog.dart';
import 'package:adota_pet/presentation/widgets/mobile_screen_header.dart';
import 'package:adota_pet/presentation/widgets/primary_button.dart';
import 'package:adota_pet/presentation/widgets/mobile_section_card.dart';
import 'package:adota_pet/presentation/widgets/state_views.dart';
import 'package:adota_pet/presentation/widgets/text_field_themed.dart';

/// Perfil do adotante (mobile) — aba do `MobileShell`.
///
/// Tela única rolável e editável que reaproveita o `UserSettingsViewModel`
/// global (o mesmo das configurações web), restilizada para mobile e limitada
/// ao caso adotante (sem telefone público / descrição).
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const double _maxWidth = 430;

  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _documentoCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
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
  UserSettingsViewModel? _settingsVm;
  bool _showSenhaAtual = false;
  bool _showSenhaNova = false;
  bool _showConfirmarSenha = false;

  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'\d')},
  );
  final _telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'\d')},
  );
  final _cepMask = MaskTextInputFormatter(
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
    final vm = context.read<UserSettingsViewModel>();
    _settingsVm = vm;
    // Re-sincroniza os campos quando o VM terminar de carregar — inclusive se a
    // carga foi disparada por outra tela (ex.: a Home), caso em que o loadFor
    // abaixo retorna cedo (guarda de isLoading) ainda sem dados.
    vm.addListener(_onSettingsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await vm.loadFor(usuario);
      if (mounted) _syncFromVm(vm);
    });
  }

  void _onSettingsChanged() {
    if (mounted) _syncFromVm(_settingsVm!);
  }

  @override
  void dispose() {
    _settingsVm?.removeListener(_onSettingsChanged);
    _cepDebounce?.cancel();
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _documentoCtrl.dispose();
    _telefoneCtrl.dispose();
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

  // ── Sincronização VM → controllers ──────────────────────────────────────────

  void _syncFromVm(UserSettingsViewModel vm) {
    _setText(_nomeCtrl, vm.nome);
    _setText(_emailCtrl, vm.email);
    _setText(_documentoCtrl, _formatWithMask(_cpfMask, vm.documento));
    _setText(_telefoneCtrl, _formatWithMask(_telefoneMask, vm.telefone));
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

  // ── Ações ────────────────────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    final vm = context.read<UserSettingsViewModel>();
    final updated = await vm.saveProfile();
    if (!mounted || updated == null) return;
    context.read<AuthViewModel>().updateUsuario(updated);
    _syncFromVm(vm);
    AppNotifier.instance.success('Perfil atualizado.');
  }

  Future<void> _changePassword() async {
    final ok = await context.read<UserSettingsViewModel>().changePassword();
    if (!mounted || !ok) return;
    _senhaAtualCtrl.clear();
    _senhaNovaCtrl.clear();
    _confirmarSenhaCtrl.clear();
    AppNotifier.instance.success('Senha alterada.');
  }

  Future<void> _logoutCurrent() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Sair desta sessão',
      message: 'Você precisará entrar novamente para usar o app.',
      confirmLabel: 'Sair',
    );
    if (!ok || !mounted) return;
    await context.read<AuthViewModel>().logout();
    if (mounted) context.go('/login');
  }

  Future<void> _logoutAll() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Sair de todos os dispositivos',
      message: 'Todas as sessões ativas desta conta serão encerradas.',
      confirmLabel: 'Encerrar sessões',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await context.read<AuthViewModel>().logoutAll();
    if (mounted) context.go('/login');
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserSettingsViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: vm.isLoading
          ? const LoadingView()
          : SafeArea(
              child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async {
                final usuario =
                    context.read<AuthViewModel>().session?.usuario;
                if (usuario == null) return;
                final vm = context.read<UserSettingsViewModel>();
                await vm.loadFor(usuario, force: true);
                if (mounted) _syncFromVm(vm);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: SizedBox(
                    width: _maxWidth,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(vm),
                          const SizedBox(height: 20),
                          if (vm.error != null) ...[
                            _ErrorBanner(message: vm.error!),
                            const SizedBox(height: 16),
                          ],
                          _buildPersonalData(vm),
                          const SizedBox(height: 16),
                          _buildAddress(vm),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Salvar alterações',
                            trailingIcon: Icons.check_rounded,
                            isLoading: vm.isSavingProfile,
                            onPressed: _saveProfile,
                          ),
                          const SizedBox(height: 24),
                          _buildPassword(vm),
                          const SizedBox(height: 16),
                          _buildLogout(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ),
    );
  }

  // ── Cabeçalho (avatar + nome + email + tipo + foto) ──────────────────────────

  Widget _buildHeader(UserSettingsViewModel vm) {
    final bytes = vm.imagemBytes ?? _decodeBase64(vm.imagemBase64);
    final hasImage = bytes != null && !vm.removerImagem;
    final nome = vm.nome.trim().isEmpty ? 'Adotante' : vm.nome.trim();

    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary.withOpacity(0.12),
            border: Border.all(
              color: vm.fieldErrors['imagem'] == null
                  ? AppTheme.border
                  : AppTheme.destructive,
              width: 1.5,
            ),
            image: hasImage
                ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
                : null,
          ),
          alignment: Alignment.center,
          child: hasImage
              ? null
              : Text(
                  nome[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: AppTheme.primary,
            shape: const CircleBorder(
              side: BorderSide(color: AppTheme.background, width: 2.5),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _pickImage(vm),
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(Icons.photo_camera_rounded,
                    size: 13, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MobileScreenHeader(
          leading: avatar,
          title: 'Meu perfil',
          subtitle: vm.email.isNotEmpty ? vm.email : null,
        ),
        if (hasImage)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: TextButton.icon(
              onPressed: vm.removeImagem,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Remover foto'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.destructive),
            ),
          ),
        if (vm.fieldErrors['imagem'] != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              vm.fieldErrors['imagem']!,
              style: const TextStyle(color: AppTheme.destructive, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Future<void> _pickImage(UserSettingsViewModel vm) async {
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

  // ── Dados pessoais ───────────────────────────────────────────────────────────

  Widget _buildPersonalData(UserSettingsViewModel vm) {
    return MobileSectionCard(
      title: 'Dados pessoais',
      icon: Icons.person_outline_rounded,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFieldThemed(
            label: 'Nome completo',
            controller: _nomeCtrl,
            prefixIcon: Icons.person_outline_rounded,
            errorText: vm.fieldErrors['nome'],
            onChanged: vm.setNome,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFieldThemed(
            label: 'Telefone',
            hint: '(00) 00000-0000',
            controller: _telefoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [_telefoneMask],
            prefixIcon: Icons.phone_outlined,
            errorText: vm.fieldErrors['telefone'],
            onChanged: vm.setTelefone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFieldThemed(
            label: 'E-mail',
            controller: _emailCtrl,
            prefixIcon: Icons.mail_outline_rounded,
            enabled: false,
          ),
          const SizedBox(height: 16),
          TextFieldThemed(
            label: 'CPF',
            controller: _documentoCtrl,
            prefixIcon: Icons.badge_outlined,
            enabled: false,
          ),
        ],
      ),
    );
  }

  // ── Endereço ─────────────────────────────────────────────────────────────────

  Widget _buildAddress(UserSettingsViewModel vm) {
    return MobileSectionCard(
      title: 'Endereço',
      icon: Icons.location_on_outlined,
      padding: const EdgeInsets.all(18),
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
                  controller: _cepCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_cepMask],
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
                  onChanged: (value) => _onCepChanged(value, vm),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFieldThemed(
                  label: 'UF',
                  hint: 'SP',
                  controller: _estadoCtrl,
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
            controller: _logradouroCtrl,
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
                  controller: _numeroCtrl,
                  keyboardType: TextInputType.number,
                  errorText: vm.fieldErrors['numero'],
                  onChanged: vm.setNumero,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFieldThemed(
                  label: 'Complemento',
                  controller: _complementoCtrl,
                  errorText: vm.fieldErrors['complemento'],
                  onChanged: vm.setComplemento,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFieldThemed(
            label: 'Bairro',
            controller: _bairroCtrl,
            prefixIcon: Icons.holiday_village_outlined,
            errorText: vm.fieldErrors['bairro'],
            onChanged: vm.setBairro,
          ),
          const SizedBox(height: 16),
          TextFieldThemed(
            label: 'Cidade',
            controller: _cidadeCtrl,
            prefixIcon: Icons.location_city_outlined,
            errorText: vm.fieldErrors['cidade'],
            onChanged: vm.setCidade,
          ),
        ],
      ),
    );
  }

  // ── Segurança (senha) ────────────────────────────────────────────────────────

  Widget _buildPassword(UserSettingsViewModel vm) {
    return MobileSectionCard(
      title: 'Segurança',
      icon: Icons.lock_outline_rounded,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (vm.passwordError != null) ...[
            _ErrorBanner(message: vm.passwordError!),
            const SizedBox(height: 16),
          ],
          TextFieldThemed(
            label: 'Senha atual',
            controller: _senhaAtualCtrl,
            obscureText: !_showSenhaAtual,
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              icon: Icon(
                _showSenhaAtual
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _showSenhaAtual = !_showSenhaAtual),
            ),
            errorText: vm.passwordFieldErrors['senhaAtual'],
            onChanged: vm.setSenhaAtual,
          ),
          const SizedBox(height: 16),
          TextFieldThemed(
            label: 'Nova senha',
            controller: _senhaNovaCtrl,
            obscureText: !_showSenhaNova,
            prefixIcon: Icons.password_rounded,
            suffix: IconButton(
              icon: Icon(
                _showSenhaNova
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
              ),
              onPressed: () => setState(() => _showSenhaNova = !_showSenhaNova),
            ),
            errorText: vm.passwordFieldErrors['senhaNova'],
            onChanged: vm.setSenhaNova,
          ),
          const SizedBox(height: 16),
          TextFieldThemed(
            label: 'Confirmar senha',
            controller: _confirmarSenhaCtrl,
            obscureText: !_showConfirmarSenha,
            prefixIcon: Icons.password_rounded,
            suffix: IconButton(
              icon: Icon(
                _showConfirmarSenha
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _showConfirmarSenha = !_showConfirmarSenha),
            ),
            errorText: vm.passwordFieldErrors['confirmarSenha'],
            onChanged: vm.setConfirmarSenha,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Alterar senha',
            trailingIcon: Icons.key_rounded,
            variant: PrimaryButtonVariant.sage,
            isLoading: vm.isChangingPassword,
            onPressed: _changePassword,
          ),
        ],
      ),
    );
  }

  // ── Sair ───────────────────────────────────────────────────────────────────

  Widget _buildLogout() {
    return MobileSectionCard(
      title: 'Conta',
      icon: Icons.logout_rounded,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _logoutCurrent,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sair desta sessão'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _logoutAll,
            icon: const Icon(Icons.power_settings_new_rounded, size: 18),
            label: const Text('Sair de todos os dispositivos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.destructive,
              side: const BorderSide(color: AppTheme.destructive),
            ),
          ),
        ],
      ),
    );
  }

  Uint8List? _decodeBase64(String? value) {
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

/// Banner de erro inline (mesma linguagem visual do painel, em versão mobile).
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.destructive.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppTheme.destructive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.destructive,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
