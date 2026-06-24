// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/notifications/app_notifier.dart';
import 'package:adota_pet/core/theme/app_dimens.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/presentation/viewmodels/pet_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/app_dropdown_field.dart';
import 'package:adota_pet/presentation/widgets/page_header.dart';
import 'package:adota_pet/presentation/widgets/pet_image.dart';
import 'package:adota_pet/presentation/widgets/primary_button.dart';
import 'package:adota_pet/presentation/widgets/section_card.dart';
import 'package:adota_pet/presentation/widgets/state_views.dart';
import 'package:adota_pet/presentation/widgets/text_field_themed.dart';

class PetFormPage extends StatefulWidget {
  final String? petId;
  const PetFormPage({super.key, this.petId});
  bool get isEditing => petId != null;

  @override
  State<PetFormPage> createState() => _PetFormPageState();
}

class _PetFormPageState extends State<PetFormPage> {
  final _nomeController = TextEditingController();
  final _racaController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _anosController = TextEditingController();
  final _mesesController = TextEditingController();

  String _especie = 'cao';
  String _porte = 'medio';
  String _sexo = 'macho';
  String _status = 'disponivel';
  bool _castrado = false;
  bool _vacinado = false;
  final List<String> _selectedTemps = [];
  bool _loaded = false;

  String? _erroNome;
  String? _erroIdade;
  String? _erroFoto;

  // Fotos: máx 8 slots, índice 0 = foto principal
  final List<Uint8List?> _fotosBytes = List.filled(8, null);
  final List<String?> _fotosNomes = List.filled(8, null);
  // URLs/data-URIs das fotos já salvas no backend.
  final List<String?> _fotosUrls = List.filled(8, null);

  static const _temperamentos = [
    'Brincalhão', 'Carinhoso', 'Tranquilo', 'Ativo', 'Inteligente',
    'Medroso', 'Independente', 'Comunicativo', 'Sociável', 'Apegado',
    'Treinado', 'Calmo',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<PetViewModel>().loadPetById(widget.petId!);
        if (mounted) _fillForm();
      });
    }
  }

  void _fillForm() {
    final pet = context.read<PetViewModel>().selectedPet;
    if (pet == null) return;
    _nomeController.text = pet.nome;
    _racaController.text = pet.raca ?? '';
    _descricaoController.text = pet.descricao ?? '';
    _anosController.text = (pet.idadeMeses ~/ 12).toString();
    _mesesController.text = (pet.idadeMeses % 12).toString();
    setState(() {
      _especie = pet.especie;
      _porte = pet.porte;
      _sexo = pet.sexo;
      _status = pet.status;
      _castrado = pet.castrado;
      _vacinado = pet.vacinado;
      if (pet.temperamento != null) {
        _selectedTemps.addAll(
          pet.temperamento!
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty),
        );
      }
      for (int i = 0; i < pet.fotosUrls.length && i < 8; i++) {
        if (pet.fotosUrls[i].isNotEmpty) {
          _fotosUrls[i] = pet.fotosUrls[i];
        }
      }
      _loaded = true;
    });
  }

  /// Resolve a imagem de um slot: bytes recém-escolhidos têm prioridade;
  /// senão delega ao [petImageProvider] (data-URI base64 ou URL http).
  ImageProvider? _slotImage(int i) {
    if (_fotosBytes[i] != null) return MemoryImage(_fotosBytes[i]!);
    return petImageProvider(_fotosUrls[i]);
  }

  void _toggleTemp(String t) {
    setState(() {
      if (_selectedTemps.contains(t)) {
        _selectedTemps.remove(t);
      } else if (_selectedTemps.length < 6) {
        _selectedTemps.add(t);
      } else {
        AppNotifier.instance.info('Você pode escolher até 6 características.');
      }
    });
  }

  Future<void> _pickFoto(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    if (file.bytes!.lengthInBytes > 5 * 1024 * 1024) {
      AppNotifier.instance.error('Foto muito grande. Máximo 5MB por imagem.');
      return;
    }
    setState(() {
      _fotosBytes[index] = file.bytes;
      _fotosNomes[index] = file.name;
      if (index == 0) _erroFoto = null;
    });
  }

  void _removeFoto(int index) {
    setState(() {
      _fotosBytes[index] = null;
      _fotosNomes[index] = null;
      _fotosUrls[index] = null;
    });
  }

  bool _validar() {
    bool valido = true;
    setState(() {
      _erroNome = null;
      _erroIdade = null;
      _erroFoto = null;
    });

    if (_fotosBytes[0] == null && _fotosUrls[0] == null) {
      setState(() => _erroFoto = 'Adicione pelo menos 1 foto do pet.');
      valido = false;
    }

    if (_nomeController.text.trim().isEmpty) {
      setState(() => _erroNome = 'O nome do pet é obrigatório.');
      valido = false;
    } else if (_nomeController.text.trim().length < 2) {
      setState(() => _erroNome = 'O nome deve ter pelo menos 2 caracteres.');
      valido = false;
    }

    final anos = int.tryParse(_anosController.text) ?? 0;
    final meses = int.tryParse(_mesesController.text) ?? 0;
    if (anos == 0 && meses == 0) {
      setState(() => _erroIdade = 'Informe a idade do pet.');
      valido = false;
    } else if (meses > 11) {
      setState(() => _erroIdade = 'Meses deve ser entre 0 e 11.');
      valido = false;
    } else if (anos > 30) {
      setState(() => _erroIdade = 'Idade máxima é 30 anos.');
      valido = false;
    }
    return valido;
  }

  Future<void> _submit() async {
    if (!_validar()) return;

    final anos = int.tryParse(_anosController.text) ?? 0;
    final meses = int.tryParse(_mesesController.text) ?? 0;

    // Para cada slot: bytes novos viram data-URI base64; senão mantém a foto
    // já salva. Slots vazios são ignorados.
    final List<String> fotosUrls = [];
    for (int i = 0; i < 8; i++) {
      if (_fotosBytes[i] != null) {
        fotosUrls.add('data:image/jpeg;base64,${base64Encode(_fotosBytes[i]!)}');
      } else if (_fotosUrls[i] != null && _fotosUrls[i]!.isNotEmpty) {
        fotosUrls.add(_fotosUrls[i]!);
      }
    }

    // protetorId NÃO vai no body: o backend deriva o protetor do JWT.
    final data = {
      'nome': _nomeController.text.trim(),
      'especie': _especie,
      'raca': _racaController.text.trim().isEmpty
          ? null
          : _racaController.text.trim(),
      'porte': _porte,
      'sexo': _sexo,
      'idadeMeses': anos * 12 + meses,
      'castrado': _castrado,
      'vacinado': _vacinado,
      'descricao': _descricaoController.text.trim().isEmpty
          ? null
          : _descricaoController.text.trim(),
      'temperamento': _selectedTemps.isEmpty ? null : _selectedTemps.join(', '),
      'status': _status,
      'fotosUrls': fotosUrls,
    };

    final vm = context.read<PetViewModel>();
    final ok = widget.isEditing
        ? await vm.updatePet(widget.petId!, data)
        : await vm.createPet(data);

    if (!mounted) return;

    if (ok) {
      AppNotifier.instance.success(vm.successMessage ?? 'Pet salvo com sucesso!');
      context.go('/pets');
    } else {
      AppNotifier.instance.error(vm.error ?? 'Não foi possível salvar o pet.');
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _racaController.dispose();
    _descricaoController.dispose();
    _anosController.dispose();
    _mesesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PetViewModel>();

    if (widget.isEditing && vm.isLoading && !_loaded) {
      return const ColoredBox(
        color: AppTheme.background,
        child: LoadingView(message: 'Carregando pet...'),
      );
    }

    return ColoredBox(
      color: AppTheme.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: widget.isEditing ? 'Editar pet' : 'Cadastrar novo pet',
                  subtitle: 'Preencha os dados do animal para publicá-lo.',
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.go('/pets'),
                    tooltip: 'Voltar',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _fotosSection(),
                const SizedBox(height: AppSpacing.lg),
                _identificacaoSection(),
                const SizedBox(height: AppSpacing.lg),
                _saudeSection(),
                const SizedBox(height: AppSpacing.lg),
                _personalidadeSection(),
                const SizedBox(height: AppSpacing.xl),
                _actions(vm),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fotosSection() {
    return SectionCard(
      title: 'Fotos',
      subtitle: 'Mínimo 1 foto · JPG, PNG ou WEBP · até 5MB cada',
      icon: Icons.photo_library_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              const spacing = 10.0;
              final cols = (c.maxWidth / 130).floor().clamp(2, 8);
              final slot = (c.maxWidth - spacing * (cols - 1)) / cols;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [for (var i = 0; i < 8; i++) _photoSlot(i, slot)],
              );
            },
          ),
          if (_erroFoto != null)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 2),
              child: Text(
                _erroFoto!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.destructive,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoSlot(int i, double size) {
    final img = _slotImage(i);
    final isMain = i == 0;
    final hasAny = img != null;
    final errorBorder = isMain && _erroFoto != null && !hasAny;

    final Color borderColor = errorBorder
        ? AppTheme.destructive
        : (isMain && hasAny ? AppTheme.primary : AppTheme.border);

    return GestureDetector(
      onTap: () => _pickFoto(i),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppTheme.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: (isMain && hasAny) || errorBorder ? 1.6 : 1,
                ),
                image: img != null
                    ? DecorationImage(image: img, fit: BoxFit.cover)
                    : null,
              ),
              child: hasAny
                  ? null
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 22,
                          color: AppTheme.mutedForeground.withOpacity(0.6),
                        ),
                        if (isMain)
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text(
                              'Principal',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            if (hasAny)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeFoto(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: const Icon(Icons.close, size: 13, color: Colors.white),
                  ),
                ),
              ),
            if (isMain && hasAny)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Principal',
                    style: TextStyle(fontSize: 9, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _identificacaoSection() {
    return SectionCard(
      title: 'Identificação',
      icon: Icons.badge_rounded,
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 560;
          return Column(
            children: [
              TextFieldThemed(
                label: 'Nome do pet *',
                hint: 'Ex: Thor',
                controller: _nomeController,
                errorText: _erroNome,
              ),
              const SizedBox(height: 16),
              _two(
                wide,
                AppDropdownField<String>(
                  label: 'Espécie *',
                  value: _especie,
                  items: const [
                    AppDropdownItem('cao', 'Cão'),
                    AppDropdownItem('gato', 'Gato'),
                    AppDropdownItem('outro', 'Outro'),
                  ],
                  onChanged: (v) => setState(() => _especie = v ?? _especie),
                ),
                TextFieldThemed(
                  label: 'Raça',
                  hint: 'Ex: Golden Retriever',
                  controller: _racaController,
                ),
              ),
              const SizedBox(height: 16),
              _two(
                wide,
                AppDropdownField<String>(
                  label: 'Porte *',
                  value: _porte,
                  items: const [
                    AppDropdownItem('pequeno', 'Pequeno (até 10kg)'),
                    AppDropdownItem('medio', 'Médio (10–25kg)'),
                    AppDropdownItem('grande', 'Grande (acima de 25kg)'),
                  ],
                  onChanged: (v) => setState(() => _porte = v ?? _porte),
                ),
                AppDropdownField<String>(
                  label: 'Sexo *',
                  value: _sexo,
                  items: const [
                    AppDropdownItem('macho', 'Macho'),
                    AppDropdownItem('femea', 'Fêmea'),
                  ],
                  onChanged: (v) => setState(() => _sexo = v ?? _sexo),
                ),
              ),
              const SizedBox(height: 16),
              _idadeField(),
              if (widget.isEditing) ...[
                const SizedBox(height: 16),
                _two(
                  wide,
                  AppDropdownField<String>(
                    label: 'Status',
                    value: _status,
                    items: const [
                      AppDropdownItem('disponivel', 'Disponível'),
                      AppDropdownItem('em_processo', 'Em processo'),
                      AppDropdownItem('adotado', 'Adotado'),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? _status),
                  ),
                  const SizedBox.shrink(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _idadeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFieldThemed(
                label: 'Idade — anos *',
                hint: 'Anos',
                controller: _anosController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFieldThemed(
                label: 'Meses *',
                hint: 'Meses',
                controller: _mesesController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        if (_erroIdade != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _erroIdade!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.destructive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _saudeSection() {
    return SectionCard(
      title: 'Saúde',
      icon: Icons.medical_services_rounded,
      child: Column(
        children: [
          _ToggleRow(
            label: 'Vacinado',
            value: _vacinado,
            onChanged: (v) => setState(() => _vacinado = v),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            label: 'Castrado',
            value: _castrado,
            onChanged: (v) => setState(() => _castrado = v),
          ),
        ],
      ),
    );
  }

  Widget _personalidadeSection() {
    return SectionCard(
      title: 'Personalidade',
      subtitle: 'Selecione até 6 características',
      icon: Icons.pets_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _temperamentos)
                _TempChip(
                  label: t,
                  selected: _selectedTemps.contains(t),
                  onTap: () => _toggleTemp(t),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFieldThemed(
            label: 'Descrição livre',
            hint: 'Conte a história e a personalidade do pet...',
            controller: _descricaoController,
            maxLines: 4,
            minLines: 4,
            maxLength: 500,
          ),
        ],
      ),
    );
  }

  Widget _actions(PetViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.go('/pets'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 54),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: PrimaryButton(
            label: widget.isEditing ? 'Salvar alterações' : 'Publicar pet',
            trailingIcon: Icons.check_rounded,
            variant: PrimaryButtonVariant.sage,
            isLoading: vm.isSaving,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }

  /// Dois campos lado a lado em telas largas; empilhados em estreitas.
  Widget _two(bool wide, Widget a, Widget b) {
    if (!wide) {
      return Column(
        children: [a, const SizedBox(height: 16), b],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 16),
        Expanded(child: b),
      ],
    );
  }
}

class _TempChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TempChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.foreground,
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
