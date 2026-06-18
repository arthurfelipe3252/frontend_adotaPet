import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:adota_pet/core/notifications/app_notifier.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/presentation/viewmodels/match_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/mobile_shell_scope.dart';

class MatchQuizPage extends StatefulWidget {
  const MatchQuizPage({super.key});

  @override
  State<MatchQuizPage> createState() => _MatchQuizPageState();
}

class _MatchQuizPageState extends State<MatchQuizPage> {
  static const _maxWidth = 430.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchViewModel>().resetQuiz();
    });
  }

  Future<void> _handleNext(MatchViewModel vm) async {
    if (vm.selectedOptionIndex == null) return;

    if (vm.isLastQuestion) {
      vm.nextQuestion(); // marca quizCompleted = true
      final ok = await vm.submitQuestionario();
      if (!mounted) return;
      if (!ok) {
        AppNotifier.instance.error(vm.error ?? 'Não foi possível salvar suas respostas.');
        vm.quizCompleted = false; // permite tentar de novo
      }
    } else {
      vm.nextQuestion();
    }
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
            child: vm.quizCompleted ? _buildDoneState(context, vm) : _buildQuizState(context, vm),
          ),
        ),
      ),
    );
  }

  // ── Estado: concluído ────────────────────────────────────────────────────

  Widget _buildDoneState(BuildContext context, MatchViewModel vm) {
    if (vm.isSaving) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Match encontrado!',
              style: GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.foreground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Com base no seu perfil, encontramos pets compatíveis com você.',
              style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.mutedForeground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/match-results'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Ver meus matches',
                  style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Estado: respondendo ──────────────────────────────────────────────────

  Widget _buildQuizState(BuildContext context, MatchViewModel vm) {
    final question = MatchViewModel.questions[vm.currentQuestion];
    final total = MatchViewModel.questions.length;
    final progress = (vm.currentQuestion + 1) / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: fechar + contador
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => MobileShellScope.of(context)?.goTo(0),
                child: const Icon(Icons.close_rounded, size: 22, color: AppTheme.mutedForeground),
              ),
              Text(
                'Pergunta ${vm.currentQuestion + 1} de $total',
                style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.mutedForeground),
              ),
              const SizedBox(width: 22),
            ],
          ),
          const SizedBox(height: 20),

          // Progress bar
          ClipRRect(
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
          const SizedBox(height: 28),

          // Pergunta + opções (com fade/slide ao trocar)
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.title,
                      style: GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.foreground),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(question.options.length, (i) {
                      final opt = question.options[i];
                      final selected = vm.selectedOptionIndex == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => vm.selectOption(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.primary.withOpacity(0.08) : AppTheme.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected ? AppTheme.primary : AppTheme.border,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(opt.emoji, style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    opt.label,
                                    style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.foreground),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Botão avançar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: vm.selectedOptionIndex != null ? () => _handleNext(vm) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.inputFill,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  vm.isLastQuestion ? 'Finalizar' : 'Próximo',
                  style: GoogleFonts.quicksand(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: vm.selectedOptionIndex != null ? Colors.white : AppTheme.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
