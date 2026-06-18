// ignore_for_file: unnecessary_underscores

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:adota_pet/core/notifications/app_notifier.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/match.dart';
import 'package:adota_pet/presentation/viewmodels/match_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/confirm_dialog.dart';
import 'package:adota_pet/presentation/widgets/mobile_screen_header.dart';
import 'package:adota_pet/presentation/widgets/primary_button.dart';
import 'package:adota_pet/presentation/widgets/state_views.dart';

/// Aba "Match" do app do adotante: questionário de estilo de vida → pets
/// compatíveis por score. É uma única tela com dois estágios internos
/// (`quiz` ↔ `results`) — sem rotas soltas nem bottom-nav própria; a navegação
/// entre abas é responsabilidade do `MobileShell`.
class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

enum _Stage { quiz, results }

class _MatchPageState extends State<MatchPage> {
  static const _maxWidth = 430.0;

  /// `null` enquanto verifica se já existe questionário salvo.
  _Stage? _stage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final vm = context.read<MatchViewModel>();
    await vm.checkExistingQuestionario();
    if (!mounted) return;
    if (vm.hasExistingQuestionario) {
      setState(() => _stage = _Stage.results);
      vm.loadResult();
    } else {
      vm.resetQuiz();
      setState(() => _stage = _Stage.quiz);
    }
  }

  Future<void> _handleNext(MatchViewModel vm) async {
    if (vm.selectedOptionIndex == null) return;

    if (vm.isLastQuestion) {
      vm.nextQuestion(); // grava a última resposta + marca quizCompleted
      final ok = await vm.submitQuestionario();
      if (!mounted) return;
      if (ok) {
        setState(() => _stage = _Stage.results);
        vm.loadResult();
      } else {
        AppNotifier.instance
            .error(vm.error ?? 'Não foi possível salvar suas respostas.');
        vm.quizCompleted = false; // permite tentar de novo
      }
    } else {
      vm.nextQuestion();
    }
  }

  Future<void> _confirmRefazer(MatchViewModel vm) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Refazer questionário?',
      message: 'Suas respostas atuais serão substituídas.',
      confirmLabel: 'Refazer',
    );
    if (!ok || !mounted) return;
    await vm.refazerQuiz();
    if (!mounted) return;
    setState(() => _stage = _Stage.quiz);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MatchViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SizedBox(
          width: _maxWidth,
          child: SafeArea(
            child: switch (_stage) {
              null => const LoadingView(),
              _Stage.quiz => _buildQuiz(context, vm),
              _Stage.results => _buildResults(context, vm),
            },
          ),
        ),
      ),
    );
  }

  // ── Estágio: quiz ──────────────────────────────────────────────────────────

  Widget _buildQuiz(BuildContext context, MatchViewModel vm) {
    final total = MatchViewModel.questions.length;
    final question = MatchViewModel.questions[vm.currentQuestion];
    final progress = (vm.currentQuestion + 1) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MobileScreenHeader(
          icon: Icons.favorite_rounded,
          title: 'Match',
          subtitle: 'Pergunta ${vm.currentQuestion + 1} de $total',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: AppTheme.inputFill,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: SingleChildScrollView(
              key: ValueKey(vm.currentQuestion),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.title,
                    style: GoogleFonts.quicksand(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...List.generate(question.options.length, (i) {
                    final opt = question.options[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OptionTile(
                        emoji: opt.emoji,
                        label: opt.label,
                        selected: vm.selectedOptionIndex == i,
                        onTap: () => vm.selectOption(i),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: PrimaryButton(
            label: vm.isLastQuestion ? 'Finalizar' : 'Próximo',
            trailingIcon: vm.isLastQuestion ? null : Icons.arrow_forward_rounded,
            isLoading: vm.isSaving,
            onPressed: vm.selectedOptionIndex != null
                ? () => _handleNext(vm)
                : null,
          ),
        ),
      ],
    );
  }

  // ── Estágio: resultados ──────────────────────────────────────────────────────

  Widget _buildResults(BuildContext context, MatchViewModel vm) {
    final count = vm.result?.resultados.length;
    final subtitle = count != null
        ? '$count ${count == 1 ? 'pet compatível' : 'pets compatíveis'} com você'
        : 'Pets compatíveis com você';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MobileScreenHeader(
          icon: Icons.favorite_rounded,
          title: 'Seus matches',
          subtitle: subtitle,
          trailing: vm.result != null
              ? IconButton(
                  onPressed: () => _confirmRefazer(vm),
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppTheme.primary),
                  tooltip: 'Refazer questionário',
                )
              : null,
        ),
        Expanded(child: _buildResultsBody(context, vm)),
      ],
    );
  }

  Widget _buildResultsBody(BuildContext context, MatchViewModel vm) {
    if (vm.isLoadingResult) {
      return const LoadingView(message: 'Calculando seus matches...');
    }

    if (vm.error != null) {
      final precisaQuiz = vm.error!.toLowerCase().contains('question');
      if (precisaQuiz) {
        return EmptyState(
          icon: Icons.assignment_outlined,
          title: vm.error!,
          actionLabel: 'Responder questionário',
          actionIcon: Icons.arrow_forward_rounded,
          onAction: () {
            vm.resetQuiz();
            setState(() => _stage = _Stage.quiz);
          },
        );
      }
      return ErrorStateView(message: vm.error!, onRetry: vm.loadResult);
    }

    final resultados = vm.result?.resultados ?? [];
    if (resultados.isEmpty) {
      return const EmptyState(
        icon: Icons.pets_rounded,
        title: 'Nenhum pet disponível para análise agora.',
        message: 'Volte mais tarde — novos pets entram no catálogo o tempo todo.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: resultados.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _MatchResultCard(item: resultados[i]),
      ),
    );
  }
}

// ── Card de opção do quiz ─────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.emoji,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.08) : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.foreground,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  size: 20, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

// ── Card de resultado de match ────────────────────────────────────────────────

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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 2)),
          ],
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
                      ? Image(
                          image: photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
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
                            style: GoogleFonts.quicksand(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.foreground,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: _scoreBg(item.score),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${item.score}% compatível',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: scoreColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.raca ?? item.especieLabel} · ${item.porteLabel} · ${item.idadeFormatada}',
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .map((t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.inputFill,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    t,
                                    style: GoogleFonts.nunito(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.mutedForeground,
                                    ),
                                  ),
                                ))
                            .toList(),
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
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          item.nome.isNotEmpty ? item.nome[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
