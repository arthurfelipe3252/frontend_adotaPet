import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/pet_viewmodel.dart';
import '../widgets/org_layout.dart';
import 'package:file_picker/file_picker.dart';

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
  // URLs das fotos já salvas no backend (exibidas quando não há bytes novos)
  final List<String?> _fotosUrls = List.filled(8, null);

  static const _temperamentos = [
    'Brincalhão','Carinhoso','Tranquilo','Ativo','Inteligente',
    'Medroso','Independente','Comunicativo','Sociável','Apegado','Treinado','Calmo',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<PetViewModel>().loadPetById(widget.petId!);
        _fillForm();
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
          pet.temperamento!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty),
        );
      }
      // Carrega TODAS as fotos já salvas no backend
      for (int i = 0; i < pet.fotosUrls.length && i < 8; i++) {
        if (pet.fotosUrls[i].isNotEmpty) {
          _fotosUrls[i] = pet.fotosUrls[i];
        }
      }
      _loaded = true;
    });
  }

  void _toggleTemp(String t) {
    setState(() {
      if (_selectedTemps.contains(t)) _selectedTemps.remove(t);
      else if (_selectedTemps.length < 6) _selectedTemps.add(t);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Foto muito grande. Máximo 5MB por imagem.'),
          backgroundColor: Colors.red,
        ));
      }
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
    setState(() { _erroNome = null; _erroIdade = null; _erroFoto = null; });

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

    // Monta a lista de fotos: para cada slot, usa bytes novos (convertendo para
    // base64) ou mantém a URL já salva no backend. Slots vazios são ignorados.
    final List<String> fotosUrls = [];
    for (int i = 0; i < 8; i++) {
      if (_fotosBytes[i] != null) {
        final base64Data = base64Encode(_fotosBytes[i]!);
        fotosUrls.add('data:image/jpeg;base64,$base64Data');
      } else if (_fotosUrls[i] != null && _fotosUrls[i]!.isNotEmpty) {
        fotosUrls.add(_fotosUrls[i]!);
      }
    }

    final data = {
      'protetorId': '00000000-0000-0000-0000-000000000001',
      'nome': _nomeController.text.trim(),
      'especie': _especie,
      'raca': _racaController.text.trim().isEmpty ? null : _racaController.text.trim(),
      'porte': _porte,
      'sexo': _sexo,
      'idadeMeses': anos * 12 + meses,
      'castrado': _castrado,
      'vacinado': _vacinado,
      'descricao': _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
      'temperamento': _selectedTemps.isEmpty ? null : _selectedTemps.join(', '),
      'status': _status,
      'fotosUrls': fotosUrls,
    };

    final vm = context.read<PetViewModel>();
    final ok = widget.isEditing
        ? await vm.updatePet(widget.petId!, data)
        : await vm.createPet(data);

    if (!context.mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(vm.successMessage ?? 'Salvo!'),
        ]),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.pop(context);
    } else {
      final mensagem = vm.error ?? 'Erro ao salvar.';
      if (mensagem.contains('\n')) {
        showDialog(context: context, builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Campos inválidos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          content: Text(mensagem, style: const TextStyle(fontSize: 13, height: 1.6)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi'))],
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(mensagem)),
          ]),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
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
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFCC6633))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F0),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('Painel da ONG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500])),
                  Text(widget.isEditing ? 'Editar pet' : 'Cadastrar novo pet',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                ]),
              ]),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          _Section(emoji: '📸', title: 'Fotos', child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  final slotSize = (constraints.maxWidth - spacing * 3) / 4;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: List.generate(8, (i) {
                      final hasPhoto = _fotosBytes[i] != null;
                      final hasUrl = _fotosUrls[i] != null;
                      final hasAny = hasPhoto || hasUrl;
                      final isMain = i == 0;

                      ImageProvider? imageProvider;
                      if (hasPhoto) {
                        imageProvider = MemoryImage(_fotosBytes[i]!);
                      } else if (hasUrl) {
                        imageProvider = NetworkImage(_fotosUrls[i]!);
                      }

                      return GestureDetector(
                        onTap: () => _pickFoto(i),
                        child: SizedBox(
                          width: slotSize,
                          height: slotSize,
                          child: Stack(
                            children: [
                              Container(
                                width: slotSize,
                                height: slotSize,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEEAE6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isMain && _erroFoto != null
                                      ? Border.all(color: Colors.red, width: 1.5)
                                      : null,
                                  image: imageProvider != null
                                      ? DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: hasAny
                                    ? null
                                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Icon(Icons.add_photo_alternate_outlined, size: 22, color: Colors.grey[400]),
                                        if (isMain) Text('Principal', style: TextStyle(fontSize: 8, color: Colors.grey[400])),
                                      ]),
                              ),
                              if (hasAny)
                                Positioned(
                                  top: 4, right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeFoto(i),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(3),
                                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              if (isMain && hasAny)
                                Positioned(
                                  bottom: 4, left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Principal', style: TextStyle(fontSize: 8, color: Colors.white)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 6),
              Text('Mínimo 1 foto. JPG, PNG, WEBP · máx. 5MB',
                style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              if (_erroFoto != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(_erroFoto!, style: const TextStyle(fontSize: 11, color: Colors.red)),
                ),
            ],
          )),
          const SizedBox(height: 16),

          _Section(emoji: '🏷️', title: 'Identificação', child: Column(children: [
            _Field(label: 'Nome do pet *', child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Input(controller: _nomeController, hint: 'Nome do pet', hasError: _erroNome != null),
                if (_erroNome != null) Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(_erroNome!, style: const TextStyle(fontSize: 11, color: Colors.red)),
                ),
              ],
            )),
            const SizedBox(height: 14),
            _Field(label: 'Espécie *', child: _Select(
              value: _especie,
              items: const [
                DropdownMenuItem(value: 'cao', child: Text('Cão')),
                DropdownMenuItem(value: 'gato', child: Text('Gato')),
                DropdownMenuItem(value: 'outro', child: Text('Outro')),
              ],
              onChanged: (v) => setState(() => _especie = v!),
            )),
            const SizedBox(height: 14),
            _Field(label: 'Raça', child: _Input(controller: _racaController, hint: 'Ex: Golden Retriever')),
            const SizedBox(height: 14),
            _Field(label: 'Porte *', child: _Select(
              value: _porte,
              items: const [
                DropdownMenuItem(value: 'pequeno', child: Text('Pequeno (<10kg)')),
                DropdownMenuItem(value: 'medio', child: Text('Médio (10-25kg)')),
                DropdownMenuItem(value: 'grande', child: Text('Grande (>25kg)')),
              ],
              onChanged: (v) => setState(() => _porte = v!),
            )),
            const SizedBox(height: 14),
            _Field(label: 'Sexo *', child: _Select(
              value: _sexo,
              items: const [
                DropdownMenuItem(value: 'macho', child: Text('Macho')),
                DropdownMenuItem(value: 'femea', child: Text('Fêmea')),
              ],
              onChanged: (v) => setState(() => _sexo = v!),
            )),
            const SizedBox(height: 14),
            _Field(label: 'Idade *', child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: _Input(controller: _anosController, hint: 'Anos', keyboardType: TextInputType.number, hasError: _erroIdade != null)),
                  const SizedBox(width: 10),
                  Expanded(child: _Input(controller: _mesesController, hint: 'Meses', keyboardType: TextInputType.number, hasError: _erroIdade != null)),
                ]),
                if (_erroIdade != null) Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(_erroIdade!, style: const TextStyle(fontSize: 11, color: Colors.red)),
                ),
              ],
            )),
            if (widget.isEditing) ...[
              const SizedBox(height: 14),
              _Field(label: 'Status', child: _Select(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'disponivel', child: Text('Disponível')),
                  DropdownMenuItem(value: 'em_processo', child: Text('Em processo')),
                  DropdownMenuItem(value: 'adotado', child: Text('Adotado')),
                ],
                onChanged: (v) => setState(() => _status = v!),
              )),
            ],
          ])),
          const SizedBox(height: 16),

          _Section(emoji: '💉', title: 'Saúde', child: Column(children: [
            _ToggleRow(label: 'Vacinado', value: _vacinado, onChanged: (v) => setState(() => _vacinado = v)),
            const SizedBox(height: 8),
            _ToggleRow(label: 'Castrado', value: _castrado, onChanged: (v) => setState(() => _castrado = v)),
          ])),
          const SizedBox(height: 16),

          _Section(emoji: '🐾', title: 'Personalidade', child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selecione até 6 características', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: _temperamentos.map((t) {
                final sel = _selectedTemps.contains(t);
                return GestureDetector(
                  onTap: () => _toggleTemp(t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFCC6633) : const Color(0xFFEEEAE6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : Colors.grey[600])),
                  ),
                );
              }).toList()),
              const SizedBox(height: 14),
              _Field(label: 'Descrição livre', child: TextField(
                controller: _descricaoController,
                maxLines: 4, maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Conte a história e personalidade do pet...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  filled: true, fillColor: const Color(0xFFEEEAE6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: const TextStyle(fontSize: 13),
              )),
            ],
          )),
          const SizedBox(height: 24),

          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: Color(0xFFCC6633)),
              ),
              child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFCC6633))),
            )),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: GestureDetector(
              onTap: vm.isSaving ? null : _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFCC6633), Color(0xFFE8923E)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: const Color(0xFFCC6633).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Center(child: vm.isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.isEditing ? 'Salvar alterações' : 'Publicar 🐾',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
              ),
            )),
          ]),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String emoji, title;
  final Widget child;
  const _Section({required this.emoji, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$emoji $title', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500])),
      const SizedBox(height: 6),
      child,
    ]);
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool hasError;
  const _Input({required this.controller, required this.hint, this.keyboardType, this.hasError = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
        filled: true,
        fillColor: hasError ? Colors.red.withOpacity(0.05) : const Color(0xFFEEEAE6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: hasError ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: hasError ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: hasError ? const BorderSide(color: Colors.red, width: 1.5) : const BorderSide(color: Color(0xFFCC6633), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}

class _Select<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _Select({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: const Color(0xFFEEEAE6), borderRadius: BorderRadius.circular(12)),
      child: DropdownButton<T>(
        value: value, items: items, onChanged: onChanged,
        isExpanded: true, underline: const SizedBox(),
        style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFEEEAE6), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFFCC6633)),
      ]),
    );
  }
}