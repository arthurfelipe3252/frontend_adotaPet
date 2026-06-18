import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/match.dart';
import 'package:adota_pet/presentation/viewmodels/match_viewmodel.dart';

class MatchResultsPage extends StatefulWidget {
  const MatchResultsPage({super.key});

  @override
  State<MatchResultsPage> createState() => _MatchResultsPageState();
}

class _MatchResultsPageState extends State<MatchResultsPage> {
  static const _maxWidth = 430.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchViewModel>().loadResult();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MatchViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SizedBox(
          width: _maxWidth,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildBody(context, vm)),
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => context.go('/home'),
              child: const Icon(Icons.chevron_left_rounded, size: 24, color: AppTheme.foreground),
            ),
            Text(
              'Seus matches 💛',
              style: GoogleFonts.quicksand(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.foreground),
            ),
            GestureDetector(
              onTap: () => _confirmRefazer(context),
              child: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRefazer(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Refazer questionário?'),
        content: const Text('Suas respostas atuais serão substituídas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            child: const Text('Refazer'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<MatchViewModel>().refazerQuiz();
      if (context.mounted) context.go('/match');
    }
  }

  // ── Corpo ─────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, MatchViewModel vm) {
    if (vm.isLoadingResult) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (vm.error != null) {
      final precisaQuiz = vm.error!.toLowerCase().contains('questionário');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(precisaQuiz ? '🐾' : '⚠️', style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                vm.error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.mutedForeground),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => precisaQuiz ? context.go('/match') : vm.loadResult(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  precisaQuiz ? 'Responder questionário' : 'Tentar novamente',
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final resultados = vm.result?.resultados ?? [];

    if (resultados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🐾', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'Nenhum pet disponível para análise agora.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.mutedForeground),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      itemCount: resultados.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _MatchResultCard(item: resultados[i]),
      ),
    );
  }

  // ── Bottom nav (mesmo padrão do catálogo) ───────────────────────────────────

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
              _NavItem(icon: Icons.search_rounded, label: 'Catálogo', onTap: () => context.go('/catalog')),
              _NavItem(icon: Icons.favorite_rounded, label: 'Match', active: true, onTap: () {}),
              _NavItem(icon: Icons.person_outline_rounded, label: 'Perfil', onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card de resultado ─────────────────────────────────────────────────────────

class _MatchResultCard extends StatelessWidget {
  final MatchResultItem item;
  const _MatchResultCard({required this.item});

  Color _scoreColor(int score) {
    if (score >= 90) return AppTheme.sage;
    if (score >= 80) return AppTheme.primary;
    return AppTheme.mutedForeground;
  }

  Color _scoreBg(int score) {
    if (score >= 90) return AppTheme.sage.withOpacity(0.12);
    if (score >= 80) return AppTheme.primary.withOpacity(0.1);
    return AppTheme.inputFill;
  }

  ImageProvider? _photo() {
    if (item.fotosUrls.isEmpty) return null;
    final src = item.fotosUrls.first;
    if (src.isEmpty) return null;
    try {
      if (src.startsWith('data:')) {
        return MemoryImage(base64Decode(src.substring(src.indexOf(',') + 1)));
      }
      return NetworkImage(src);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photo();
    final scoreColor = _scoreColor(item.score);
    final tags = item.temperamentoTags.take(2).toList();

    return GestureDetector(
      onTap: () => context.push('/catalog/${item.petId}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x0A2A2622), blurRadius: 12, offset: Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: photo != null
                      ? Image(image: photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.nome,
                            style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.foreground),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: _scoreBg(item.score), borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            '${item.score}% compatível',
                            style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: scoreColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.raca ?? item.especieLabel} · ${item.porteLabel} · ${item.idadeFormatada}',
                      style: GoogleFonts.nunito(fontSize: 11.5, color: AppTheme.mutedForeground),
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: tags.map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.inputFill, borderRadius: BorderRadius.circular(20)),
                          child: Text(t, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.mutedForeground)),
                        )).toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: item.score / 100,
                        minHeight: 5,
                        backgroundColor: AppTheme.inputFill,
                        valueColor: AlwaysStoppedAnimation(scoreColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(
        child: Text(
          item.nome.isNotEmpty ? item.nome[0].toUpperCase() : '🐾',
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
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
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: active ? AppTheme.primary : AppTheme.mutedForeground),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: active ? AppTheme.primary : AppTheme.mutedForeground)),
          ],
        ),
      ),
    );
  }
}
