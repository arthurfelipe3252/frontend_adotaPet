// ignore_for_file: unnecessary_underscores

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/pet.dart';
import 'package:adota_pet/presentation/viewmodels/catalog_viewmodel.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogViewModel>().loadPets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Layout mobile centrado igual ao protótipo ──────────────────────────────

  static const _maxWidth = 430.0;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatalogViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SizedBox(
          width: _maxWidth,
          child: Column(
            children: [
              _buildHeader(context, vm),
              _buildFiltersPanel(vm),
              Expanded(child: _buildBody(context, vm)),
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header com busca e controles ──────────────────────────────────────────

  Widget _buildHeader(BuildContext context, CatalogViewModel vm) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
      child: Row(
        children: [
          // Voltar
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chevron_left_rounded, size: 22, color: AppTheme.foreground),
            ),
          ),
          const SizedBox(width: 10),
          // Busca
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1ECE3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search_rounded, size: 18, color: AppTheme.mutedForeground),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: vm.setSearch,
                      style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.foreground),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nome, raça...',
                        hintStyle: GoogleFonts.nunito(fontSize: 13, color: AppTheme.mutedForeground),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
                  ),
                  if (vm.searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        vm.setSearch('');
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Icon(Icons.close_rounded, size: 16, color: AppTheme.mutedForeground),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filtros
          GestureDetector(
            onTap: vm.toggleFiltersPanel,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: vm.totalFiltrosAtivos > 0 ? AppTheme.primary : const Color(0xFFF1ECE3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  Center(child: Icon(
                    Icons.tune_rounded, size: 18,
                    color: vm.totalFiltrosAtivos > 0 ? Colors.white : AppTheme.foreground,
                  )),
                  if (vm.totalFiltrosAtivos > 0)
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        width: 14, height: 14,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            '${vm.totalFiltrosAtivos}',
                            style: GoogleFonts.nunito(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primary),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Grid/Lista toggle
          GestureDetector(
            onTap: vm.toggleView,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: const Color(0xFFF1ECE3), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Icon(
                vm.isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                size: 18, color: AppTheme.foreground,
              )),
            ),
          ),
        ],
      ),
    );
  }

  // ── Painel de filtros colapsável ──────────────────────────────────────────

  Widget _buildFiltersPanel(CatalogViewModel vm) {
    if (!vm.showFilters) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: AppTheme.surface,
      child: Column(
        children: [
          const Divider(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FilterGroup(
                  label: 'ESPÉCIE',
                  options: const [
                    _FilterOption(value: 'cao', label: 'Cão'),
                    _FilterOption(value: 'gato', label: 'Gato'),
                    _FilterOption(value: 'outro', label: 'Outros'),
                  ],
                  category: 'especie',
                  vm: vm,
                ),
                const SizedBox(height: 12),
                _FilterGroup(
                  label: 'PORTE',
                  options: const [
                    _FilterOption(value: 'pequeno', label: 'Pequeno'),
                    _FilterOption(value: 'medio', label: 'Médio'),
                    _FilterOption(value: 'grande', label: 'Grande'),
                  ],
                  category: 'porte',
                  vm: vm,
                ),
                const SizedBox(height: 12),
                _FilterGroup(
                  label: 'SEXO',
                  options: const [
                    _FilterOption(value: 'macho', label: 'Macho'),
                    _FilterOption(value: 'femea', label: 'Fêmea'),
                  ],
                  category: 'sexo',
                  vm: vm,
                ),
                const SizedBox(height: 12),
                _FilterGroup(
                  label: 'SAÚDE',
                  options: const [
                    _FilterOption(value: 'vacinado', label: 'Vacinado'),
                    _FilterOption(value: 'castrado', label: 'Castrado'),
                  ],
                  category: 'saude',
                  vm: vm,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: vm.clearFilters,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: const BorderSide(color: AppTheme.border),
                        ),
                        child: Text('Limpar', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.mutedForeground)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: vm.toggleFiltersPanel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text('Aplicar', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
        ],
      ),
    );
  }

  // ── Corpo principal ───────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, CatalogViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 52, color: AppTheme.mutedForeground.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text(vm.error!, textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.mutedForeground)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: vm.loadPets,
                child: Text('Tentar novamente', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ),
            ],
          ),
        ),
      );
    }

    final pets = vm.filteredPets;

    if (pets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 52, color: AppTheme.mutedForeground.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('Nenhum pet encontrado', style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
            const SizedBox(height: 4),
            Text('Tente outros critérios de busca.', style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.mutedForeground)),
          ],
        ),
      );
    }

    if (vm.isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: pets.length,
        itemBuilder: (_, i) => _PetGridCard(pet: pets[i]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      itemCount: pets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _PetListRow(pet: pets[i]),
    );
  }

  // ── Bottom nav do adotante ────────────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', onTap: () => context.go('/home')),
              _NavItem(icon: Icons.search_rounded, label: 'Catálogo', active: true, onTap: () {}),
              _NavItem(icon: Icons.favorite_border_rounded, label: 'Match', onTap: () {}),
              _NavItem(icon: Icons.person_outline_rounded, label: 'Perfil', onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card Grid ─────────────────────────────────────────────────────────────────

class _PetGridCard extends StatefulWidget {
  final Pet pet;
  const _PetGridCard({required this.pet});

  @override
  State<_PetGridCard> createState() => _PetGridCardState();
}

class _PetGridCardState extends State<_PetGridCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    return GestureDetector(
      onTap: () => context.push('/catalog/${pet.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x0F2A2622), blurRadius: 16, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            Expanded(
              child: Stack(
                children: [
                  _PetPhoto(
                    fotosUrls: pet.fotosUrls,
                    nome: pet.nome,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    fontSize: 40,
                  ),
                  // Badge saúde
                  Positioned(top: 8, right: 8, child: Column(
                    children: [
                      if (pet.vacinado) _HealthBadge(icon: Icons.vaccines_rounded),
                      if (pet.castrado) ...[const SizedBox(height: 4), _HealthBadge(icon: Icons.content_cut_rounded)],
                    ],
                  )),
                  // Favorito
                  Positioned(top: 8, left: 8, child: GestureDetector(
                    onTap: () => setState(() => _liked = !_liked),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(color: AppTheme.surface.withOpacity(0.85), shape: BoxShape.circle),
                      child: Icon(
                        _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 16,
                        color: _liked ? const Color(0xFFE05070) : AppTheme.mutedForeground,
                      ),
                    ),
                  )),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.nome, style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
                  const SizedBox(height: 2),
                  Text(
                    '${pet.raca ?? pet.especieLabel} · ${pet.porteLabel}',
                    style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.mutedForeground),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_on_rounded, size: 11, color: AppTheme.mutedForeground),
                    const SizedBox(width: 2),
                    Expanded(child: Text('Sua região', overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.mutedForeground))),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card Lista ────────────────────────────────────────────────────────────────

class _PetListRow extends StatefulWidget {
  final Pet pet;
  const _PetListRow({required this.pet});

  @override
  State<_PetListRow> createState() => _PetListRowState();
}

class _PetListRowState extends State<_PetListRow> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    return GestureDetector(
      onTap: () => context.push('/catalog/${pet.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x0A2A2622), blurRadius: 12, offset: Offset(0, 2))],
        ),
        child: Row(children: [
          // Avatar
          SizedBox(
            width: 70, height: 70,
            child: _PetPhoto(
              fotosUrls: pet.fotosUrls,
              nome: pet.nome,
              borderRadius: BorderRadius.circular(14),
              fontSize: 28,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pet.nome, style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.foreground)),
              const SizedBox(height: 2),
              Text('${pet.raca ?? pet.especieLabel} · ${pet.porteLabel} · ${pet.idadeFormatada}',
                style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.mutedForeground)),
              const SizedBox(height: 6),
              Row(children: [
                if (pet.vacinado) _Chip(label: 'Vacinado', color: AppTheme.sage),
                if (pet.vacinado && pet.castrado) const SizedBox(width: 6),
                if (pet.castrado) _Chip(label: 'Castrado', color: AppTheme.sage),
              ]),
            ],
          )),
          // Favorito
          GestureDetector(
            onTap: () => setState(() => _liked = !_liked),
            child: Icon(
              _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
              color: _liked ? const Color(0xFFE05070) : AppTheme.mutedForeground,
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _HealthBadge extends StatelessWidget {
  final IconData icon;
  const _HealthBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26, height: 26,
      decoration: BoxDecoration(color: AppTheme.sage.withOpacity(0.9), shape: BoxShape.circle),
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  final String label;
  final String category;
  final List<_FilterOption> options;
  final CatalogViewModel vm;
  const _FilterGroup({required this.label, required this.category, required this.options, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.mutedForeground, letterSpacing: 0.6)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: options.map((opt) {
        final isActive = vm.activeFilters[category]!.contains(opt.value);
        return GestureDetector(
          onTap: () => vm.toggleFilter(category, opt.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primary : const Color(0xFFF1ECE3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(opt.label, style: GoogleFonts.nunito(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : AppTheme.mutedForeground,
            )),
          ),
        );
      }).toList()),
    ]);
  }
}

class _FilterOption {
  final String value;
  final String label;
  const _FilterOption({required this.value, required this.label});
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(color: Colors.transparent, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: active ? AppTheme.primary : AppTheme.mutedForeground),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700,
            color: active ? AppTheme.primary : AppTheme.mutedForeground)),
        ],
      )),
    );
  }
}

// ── Widget reutilizável de foto do pet ────────────────────────────────────────

class _PetPhoto extends StatelessWidget {
  final List<String> fotosUrls;
  final String nome;
  final BorderRadius borderRadius;
  final double fontSize;

  const _PetPhoto({
    required this.fotosUrls,
    required this.nome,
    required this.borderRadius,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    // Tenta exibir a primeira foto base64 disponível
    if (fotosUrls.isNotEmpty) {
      try {
        final raw = fotosUrls.first;
        // Remove prefixo data:image/...;base64, se existir
        final b64 = raw.contains(',') ? raw.split(',').last : raw;
        final bytes = base64Decode(b64);
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _placeholder(),
          ),
        );
      } catch (_) {
        // Se falhar o decode, cai no placeholder
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          colors: [AppTheme.primary.withOpacity(0.3), AppTheme.accent.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          nome[0].toUpperCase(),
          style: GoogleFonts.quicksand(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}
