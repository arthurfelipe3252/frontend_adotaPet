// ignore_for_file: unnecessary_underscores

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/pet.dart';
import 'package:adota_pet/presentation/viewmodels/adoption_request_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/catalog_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/pet_viewmodel.dart';

class PetDetailPage extends StatefulWidget {
  final String petId;
  const PetDetailPage({super.key, required this.petId});

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  bool _liked = false;
  Pet? _pet;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPet());
  }

  Future<void> _loadPet() async {
    final catalogVm = context.read<CatalogViewModel>();
    final cached = catalogVm.getPetById(widget.petId);
    if (cached != null) {
      setState(() { _pet = cached; _loading = false; });
      return;
    }
    final petVm = context.read<PetViewModel>();
    await petVm.loadPetById(widget.petId);
    setState(() { _pet = petVm.selectedPet; _loading = false; });
  }

  static const _maxWidth = 430.0;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    if (_pet == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('Pet não encontrado.',
              style: GoogleFonts.nunito(color: AppTheme.mutedForeground)),
        ),
      );
    }

    final pet = _pet!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SizedBox(
          width: _maxWidth,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(context, pet),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildName(pet),
                          const SizedBox(height: 16),
                          _buildTraits(pet),
                          const SizedBox(height: 20),
                          _buildAbout(pet),
                          const SizedBox(height: 20),
                          _buildHealth(pet),
                          if (pet.temperamento != null) ...[
                            const SizedBox(height: 20),
                            _buildPersonality(pet),
                          ],
                          const SizedBox(height: 20),
                          _buildOrg(pet),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _buildCTA(context, pet),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, Pet pet) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.42,
      child: Stack(
        children: [
          _PetHeroPhoto(fotosUrls: pet.fotosUrls, nome: pet.nome),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppTheme.background.withOpacity(0.7)],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 48, left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_left_rounded,
                    size: 22, color: AppTheme.foreground),
              ),
            ),
          ),
          Positioned(
            top: 48, right: 16,
            child: Row(children: [
              GestureDetector(
                onTap: () => setState(() => _liked = !_liked),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withOpacity(0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 18,
                    color: _liked ? const Color(0xFFE05070) : AppTheme.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_outlined,
                    size: 18, color: AppTheme.foreground),
              ),
            ]),
          ),
          Positioned(
            bottom: 16, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.sage.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Disponível para adoção',
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildName(Pet pet) {
    return Text(pet.nome,
        style: GoogleFonts.quicksand(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppTheme.foreground));
  }

  Widget _buildTraits(Pet pet) {
    final traits = [
      _TraitItem(icon: Icons.pets_rounded, label: pet.especieLabel),
      _TraitItem(icon: Icons.straighten_rounded, label: pet.porteLabel),
      _TraitItem(icon: Icons.cake_rounded, label: pet.idadeFormatada),
      _TraitItem(icon: Icons.circle_rounded, label: pet.sexoLabel),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: traits
            .map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1ECE3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(t.icon, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(t.label,
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.foreground)),
                    ]),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildAbout(Pet pet) {
    if (pet.descricao == null || pet.descricao!.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Sobre ${pet.nome}',
          style: GoogleFonts.quicksand(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
      const SizedBox(height: 8),
      Text(pet.descricao!,
          style: GoogleFonts.nunito(
              fontSize: 13, color: AppTheme.mutedForeground, height: 1.6)),
    ]);
  }

  Widget _buildHealth(Pet pet) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Saúde',
          style: GoogleFonts.quicksand(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
      const SizedBox(height: 10),
      Row(children: [
        _HealthCard(
            label: pet.vacinado ? 'Vacinado' : 'Não vacinado',
            icon: Icons.vaccines_rounded,
            active: pet.vacinado),
        const SizedBox(width: 10),
        _HealthCard(
            label: pet.castrado ? 'Castrado' : 'Não castrado',
            icon: Icons.content_cut_rounded,
            active: pet.castrado),
      ]),
    ]);
  }

  Widget _buildPersonality(Pet pet) {
    final tags = pet.temperamento!
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Personalidade',
          style: GoogleFonts.quicksand(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags
            .map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(tag,
                      style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary)),
                ))
            .toList(),
      ),
    ]);
  }

  Widget _buildOrg(Pet pet) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Responsável pela adoção',
          style: GoogleFonts.quicksand(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x0A2A2622), blurRadius: 12, offset: Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppTheme.sage, AppTheme.sageMint]),
            ),
            child: Center(
              child: Text('O',
                  style: GoogleFonts.quicksand(
                      fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ONG Responsável',
                  style: GoogleFonts.nunito(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
              Text('Sua cidade, BR',
                  style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.mutedForeground)),
            ]),
          ),
          TextButton(
            onPressed: () {},
            child: Text('Ver perfil',
                style: GoogleFonts.nunito(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildCTA(BuildContext context, Pet pet) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.97),
        border: const Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 42,
        child: ElevatedButton(
          onPressed: () => _openAdoptionSheet(context, pet),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            'Quero adotar ${pet.nome} 🐾',
            style: GoogleFonts.quicksand(
                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _openAdoptionSheet(BuildContext context, Pet pet) {
    final auth = context.read<AuthViewModel>();
    if (!auth.isAuthenticated) {
      context.push('/login');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdoptionRequestSheet(pet: pet),
    );
  }
}

// ── Bottom Sheet ──────────────────────────────────────────────────────────────

class _AdoptionRequestSheet extends StatefulWidget {
  final Pet pet;
  const _AdoptionRequestSheet({required this.pet});

  @override
  State<_AdoptionRequestSheet> createState() => _AdoptionRequestSheetState();
}

class _AdoptionRequestSheetState extends State<_AdoptionRequestSheet> {
  int _step = 0;

  String _tipoMoradia = 'apartamento';
  int _horasDia = 3;
  bool _temExperiencia = false;
  bool _temCriancas = false;
  bool _temOutrosPets = false;

  final _mensagemCtrl = TextEditingController();

  @override
  void dispose() {
    _mensagemCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: _step == 2
                ? _buildSuccess()
                : _step == 1
                    ? _buildStepMensagem()
                    : _buildStepQuestionario(),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40, height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppTheme.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildStepQuestionario() {
    return Column(
      key: const ValueKey('step0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHandle(),
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets_rounded, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quero adotar ${widget.pet.nome}',
                  style: GoogleFonts.quicksand(
                      fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.foreground)),
              Text('Responda algumas perguntas rápidas',
                  style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.mutedForeground)),
            ]),
          ),
        ]),
        const SizedBox(height: 24),
        _buildStepIndicator(0),
        const SizedBox(height: 20),
        _buildSectionTitle('Sua moradia'),
        const SizedBox(height: 10),
        _buildMoradiaSelector(),
        const SizedBox(height: 20),
        _buildSectionTitle('Horas disponíveis por dia para o pet'),
        const SizedBox(height: 10),
        _buildHorasSlider(),
        const SizedBox(height: 20),
        _buildSectionTitle('Sobre você'),
        const SizedBox(height: 10),
        _buildToggleItem('Tenho experiência com animais',
            Icons.workspace_premium_rounded, _temExperiencia,
            (v) => setState(() => _temExperiencia = v)),
        const SizedBox(height: 8),
        _buildToggleItem('Tenho crianças em casa',
            Icons.child_care_rounded, _temCriancas,
            (v) => setState(() => _temCriancas = v)),
        const SizedBox(height: 8),
        _buildToggleItem('Tenho outros pets',
            Icons.pets_rounded, _temOutrosPets,
            (v) => setState(() => _temOutrosPets = v)),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Próximo',
                  style: GoogleFonts.quicksand(
                      fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMoradiaSelector() {
    final opcoes = [
      ('casa_com_quintal', Icons.home_rounded, 'Casa\nc/ quintal'),
      ('casa_sem_quintal', Icons.house_rounded, 'Casa\ns/ quintal'),
      ('apartamento', Icons.apartment_rounded, 'Apartamento'),
    ];
    return Row(
      children: opcoes.map((o) {
        final selected = _tipoMoradia == o.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _tipoMoradia = o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : const Color(0xFFF1ECE3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppTheme.primary : AppTheme.border,
                    width: 2,
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(o.$2,
                      size: 22,
                      color: selected ? Colors.white : AppTheme.mutedForeground),
                  const SizedBox(height: 6),
                  Text(o.$3,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : AppTheme.foreground,
                          height: 1.3)),
                ]),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHorasSlider() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$_horasDia horas/dia',
            style: GoogleFonts.nunito(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        Text(
            _horasDia >= 6 ? '😊 Ótimo' : _horasDia >= 3 ? '👍 Bom' : '⚠️ Pouco',
            style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.mutedForeground)),
      ]),
      SliderTheme(
        data: SliderThemeData(
          activeTrackColor: AppTheme.primary,
          inactiveTrackColor: const Color(0xFFF1ECE3),
          thumbColor: AppTheme.primary,
          overlayColor: AppTheme.primary.withOpacity(0.15),
          trackHeight: 6,
        ),
        child: Slider(
          value: _horasDia.toDouble(),
          min: 0,
          max: 12,
          divisions: 12,
          onChanged: (v) => setState(() => _horasDia = v.round()),
        ),
      ),
    ]);
  }

  Widget _buildToggleItem(String label, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: value ? AppTheme.primary.withOpacity(0.08) : const Color(0xFFF7F3F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? AppTheme.primary.withOpacity(0.4) : AppTheme.border,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: value ? AppTheme.primary : AppTheme.mutedForeground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.foreground)),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: value ? AppTheme.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: value ? AppTheme.primary : AppTheme.border,
                width: 2,
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
        ]),
      ),
    );
  }

  Widget _buildStepMensagem() {
    return Consumer<AdoptionRequestViewmodel>(
      key: const ValueKey('step1'),
      builder: (context, vm, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHandle(),
          Row(children: [
            GestureDetector(
              onTap: () => setState(() => _step = 0),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECE3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chevron_left_rounded,
                    color: AppTheme.foreground, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Sua mensagem',
                    style: GoogleFonts.quicksand(
                        fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.foreground)),
                Text('Fale um pouco sobre você para a ONG',
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: AppTheme.mutedForeground)),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          _buildStepIndicator(1),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    'Apresente-se e explique por que você seria um lar ideal para ${widget.pet.nome}.',
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: AppTheme.primary, height: 1.5)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mensagemCtrl,
            maxLines: 5,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText:
                  'Olá! Me chamo ... e adoraria adotar ${widget.pet.nome} porque...',
              hintStyle: GoogleFonts.nunito(
                  fontSize: 13, color: AppTheme.mutedForeground),
              filled: true,
              fillColor: const Color(0xFFF1ECE3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),
          _buildResumoQuestionario(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: vm.isSending ? null : () => _enviarSolicitacao(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: vm.isSending
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Enviar solicitação',
                          style: GoogleFonts.quicksand(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoQuestionario() {
    final moradiaLabel = {
      'casa_com_quintal': 'Casa com quintal',
      'casa_sem_quintal': 'Casa sem quintal',
      'apartamento': 'Apartamento',
    }[_tipoMoradia]!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Resumo do seu perfil',
            style: GoogleFonts.nunito(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.mutedForeground)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _ResumoChip(label: moradiaLabel, icon: Icons.home_rounded),
          _ResumoChip(label: '$_horasDia h/dia', icon: Icons.schedule_rounded),
          if (_temExperiencia)
            _ResumoChip(
                label: 'Experiente',
                icon: Icons.workspace_premium_rounded,
                color: AppTheme.sage),
          if (_temCriancas)
            _ResumoChip(label: 'Tem crianças', icon: Icons.child_care_rounded),
          if (_temOutrosPets)
            _ResumoChip(label: 'Tem outros pets', icon: Icons.pets_rounded),
        ]),
      ]),
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('step2'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHandle(),
        const SizedBox(height: 16),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppTheme.sage.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: AppTheme.sage, size: 44),
        ),
        const SizedBox(height: 20),
        Text('Solicitação enviada! 🐾',
            style: GoogleFonts.quicksand(
                fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.foreground),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
            'Sua solicitação para adotar ${widget.pet.nome} foi recebida.\nA ONG responsável entrará em contato em breve.',
            style: GoogleFonts.nunito(
                fontSize: 14, color: AppTheme.mutedForeground, height: 1.6),
            textAlign: TextAlign.center),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text('Fechar',
                style: GoogleFonts.quicksand(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int current) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.quicksand(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.foreground));
  }

  Future<void> _enviarSolicitacao(BuildContext context) async {
    final vm = context.read<AdoptionRequestViewmodel>();

    final questionario = {
      'tipoMoradia': _tipoMoradia,
      'horasDisponiveisDia': _horasDia,
      'temExperiencia': _temExperiencia,
      'temCriancas': _temCriancas,
      'temOutrosPets': _temOutrosPets,
    };

    final ok = await vm.createFromPetDetail(
      petId: widget.pet.id,
      mensagem: _mensagemCtrl.text.trim().isEmpty ? null : _mensagemCtrl.text.trim(),
      questionario: questionario,
    );

    if (ok) setState(() => _step = 2);
  }
}

// ── Resumo chip ───────────────────────────────────────────────────────────────

class _ResumoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  const _ResumoChip({required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.mutedForeground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12, fontWeight: FontWeight.w700, color: c)),
      ]),
    );
  }
}

// ── Auxiliares ────────────────────────────────────────────────────────────────

class _TraitItem {
  final IconData icon;
  final String label;
  const _TraitItem({required this.icon, required this.label});
}

class _HealthCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  const _HealthCard({required this.label, required this.icon, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppTheme.sage.withOpacity(0.12) : const Color(0xFFF1ECE3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: active ? AppTheme.sage : AppTheme.mutedForeground),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? AppTheme.sage : AppTheme.mutedForeground)),
      ]),
    );
  }
}

class _PetHeroPhoto extends StatefulWidget {
  final List<String> fotosUrls;
  final String nome;
  const _PetHeroPhoto({required this.fotosUrls, required this.nome});

  @override
  State<_PetHeroPhoto> createState() => _PetHeroPhotoState();
}

class _PetHeroPhotoState extends State<_PetHeroPhoto> {
  int _current = 0;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Uint8List? _decode(String raw) {
    try {
      final b64 = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fotos = widget.fotosUrls;
    if (fotos.isEmpty) return _placeholder();
    final validas = fotos.map(_decode).whereType<Uint8List>().toList();
    if (validas.isEmpty) return _placeholder();

    return Stack(children: [
      PageView.builder(
        controller: _ctrl,
        itemCount: validas.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => Image.memory(
          validas[i],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      ),
      if (validas.length > 1)
        Positioned(
          bottom: 12, right: 16,
          child: Row(
            children: List.generate(
              validas.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i ? Colors.white : Colors.white54,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.4),
            AppTheme.accent.withOpacity(0.25)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          widget.nome[0].toUpperCase(),
          style: GoogleFonts.quicksand(
              fontSize: 96,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.6)),
        ),
      ),
    );
  }
}