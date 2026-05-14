import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/pet.dart';
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
    // Tenta do cache do catálogo primeiro
    final catalogVm = context.read<CatalogViewModel>();
    final cached = catalogVm.getPetById(widget.petId);
    if (cached != null) {
      setState(() { _pet = cached; _loading = false; });
      return;
    }
    // Fallback: busca via PetViewModel
    final petVm = context.read<PetViewModel>();
    await petVm.loadPetById(widget.petId);
    setState(() { _pet = petVm.selectedPet; _loading = false; });
  }

  static const _maxWidth = 430.0;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    }
    if (_pet == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Pet não encontrado.', style: GoogleFonts.nunito(color: AppTheme.mutedForeground))),
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
              // Scrollable content
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
              // CTA fixo no rodapé
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

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context, Pet pet) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.42,
      child: Stack(
        children: [
          // Foto / placeholder com gradiente
          _PetHeroPhoto(fotosUrls: pet.fotosUrls, nome: pet.nome),
          // Gradient overlay
          Positioned.fill(child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppTheme.background.withOpacity(0.7)],
                stops: const [0.55, 1.0],
              ),
            ),
          )),
          // Botão voltar
          Positioned(
            top: 48, left: 16,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: AppTheme.surface.withOpacity(0.85), shape: BoxShape.circle),
                child: const Icon(Icons.chevron_left_rounded, size: 22, color: AppTheme.foreground),
              ),
            ),
          ),
          // Botões favorito e share
          Positioned(
            top: 48, right: 16,
            child: Row(children: [
              GestureDetector(
                onTap: () => setState(() => _liked = !_liked),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: AppTheme.surface.withOpacity(0.85), shape: BoxShape.circle),
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
                decoration: BoxDecoration(color: AppTheme.surface.withOpacity(0.85), shape: BoxShape.circle),
                child: const Icon(Icons.share_outlined, size: 18, color: AppTheme.foreground),
              ),
            ]),
          ),
          // Badge disponível
          Positioned(
            bottom: 16, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.sage.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Disponível para adoção',
                style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Nome ──────────────────────────────────────────────────────────────────

  Widget _buildName(Pet pet) {
    return Text(pet.nome, style: GoogleFonts.quicksand(fontSize: 32, fontWeight: FontWeight.w800, color: AppTheme.foreground));
  }

  // ── Traits chips ─────────────────────────────────────────────────────────

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
        children: traits.map((t) => Padding(
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
              Text(t.label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
            ]),
          ),
        )).toList(),
      ),
    );
  }

  // ── Sobre ─────────────────────────────────────────────────────────────────

  Widget _buildAbout(Pet pet) {
    if (pet.descricao == null || pet.descricao!.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Sobre ${pet.nome}', style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
      const SizedBox(height: 8),
      Text(pet.descricao!, style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.mutedForeground, height: 1.6)),
    ]);
  }

  // ── Saúde ─────────────────────────────────────────────────────────────────

  Widget _buildHealth(Pet pet) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Saúde', style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
      const SizedBox(height: 10),
      Row(children: [
        _HealthCard(label: pet.vacinado ? 'Vacinado' : 'Não vacinado', icon: Icons.vaccines_rounded, active: pet.vacinado),
        const SizedBox(width: 10),
        _HealthCard(label: pet.castrado ? 'Castrado' : 'Não castrado', icon: Icons.content_cut_rounded, active: pet.castrado),
      ]),
    ]);
  }

  // ── Personalidade ─────────────────────────────────────────────────────────

  Widget _buildPersonality(Pet pet) {
    final tags = pet.temperamento!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Personalidade', style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: tags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(tag, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
      )).toList()),
    ]);
  }

  // ── ONG responsável ───────────────────────────────────────────────────────

  Widget _buildOrg(Pet pet) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Responsável pela adoção', style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x0A2A2622), blurRadius: 12, offset: Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppTheme.sage, AppTheme.sageMint]),
            ),
            child: Center(child: Text('O', style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ONG Responsável', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
            Text('Sua cidade, BR', style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.mutedForeground)),
          ])),
          TextButton(
            onPressed: () {},
            child: Text('Ver perfil', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ),
        ]),
      ),
    ]);
  }

  // ── CTA Fixo ──────────────────────────────────────────────────────────────

  Widget _buildCTA(BuildContext context, Pet pet) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.97),
        border: const Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            'Quero adotar ${pet.nome} 🐾',
            style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

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
        Text(label, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700,
          color: active ? AppTheme.sage : AppTheme.mutedForeground)),
      ]),
    );
  }
}

// ── Widget hero com foto(s) do pet ────────────────────────────────────────────

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

    return Stack(
      children: [
        // Carrossel de fotos
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
        // Indicadores de página (só se tiver mais de 1 foto)
        if (validas.length > 1)
          Positioned(
            bottom: 12,
            right: 16,
            child: Row(
              children: List.generate(validas.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i ? Colors.white : Colors.white54,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withOpacity(0.4), AppTheme.accent.withOpacity(0.25)],
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
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
