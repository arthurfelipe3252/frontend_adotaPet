import 'package:flutter/material.dart';

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/data/datasources/match_remote_datasource.dart';
import 'package:adota_pet/domain/entities/match.dart';

/// Uma pergunta do questionário: título + opções (emoji, label, valor enum).
class MatchQuestion {
  final String title;
  final List<MatchOption> options;
  const MatchQuestion({required this.title, required this.options});
}

class MatchOption {
  final String emoji;
  final String label;
  final String value;
  const MatchOption({required this.emoji, required this.label, required this.value});
}

class MatchViewModel extends ChangeNotifier {
  final MatchRemoteDatasource datasource;
  MatchViewModel(this.datasource);

  // ── Perguntas do quiz (espelham os ENUMs do backend) ───────────────────────

  static const List<MatchQuestion> questions = [
    MatchQuestion(
      title: 'Onde você mora?',
      options: [
        MatchOption(emoji: '🏠', label: 'Casa com quintal grande', value: 'casa_quintal_grande'),
        MatchOption(emoji: '🏡', label: 'Casa com quintal pequeno', value: 'casa_quintal_pequeno'),
        MatchOption(emoji: '🏢', label: 'Apartamento', value: 'apartamento'),
        MatchOption(emoji: '🏠', label: 'Apartamento com lazer', value: 'apartamento_lazer'),
      ],
    ),
    MatchQuestion(
      title: 'Como é sua rotina?',
      options: [
        MatchOption(emoji: '⏱️', label: 'Fico em casa o dia todo', value: 'fica_em_casa'),
        MatchOption(emoji: '🏃', label: 'Saio e volto para almoço', value: 'sai_almoco'),
        MatchOption(emoji: '💼', label: 'Passo o dia fora', value: 'passa_dia_fora'),
        MatchOption(emoji: '🌍', label: 'Viajo frequentemente', value: 'viaja_frequentemente'),
      ],
    ),
    MatchQuestion(
      title: 'Experiência com pets?',
      options: [
        MatchOption(emoji: '✅', label: 'Sim, tenho experiência', value: 'sim_tem_experiencia'),
        MatchOption(emoji: '🔄', label: 'Sim, mas faz tempo', value: 'sim_faz_tempo'),
        MatchOption(emoji: '🆕', label: 'Nunca tive, quero aprender', value: 'nunca_quer_aprender'),
        MatchOption(emoji: '👶', label: 'Primeiro pet da família', value: 'primeiro_pet_familia'),
      ],
    ),
    MatchQuestion(
      title: 'Há crianças em casa?',
      options: [
        MatchOption(emoji: '👶', label: 'Bebê (0–3 anos)', value: 'bebe'),
        MatchOption(emoji: '🧒', label: 'Criança pequena (4–10)', value: 'crianca_pequena'),
        MatchOption(emoji: '👦', label: 'Criança maior (11+)', value: 'crianca_maior'),
        MatchOption(emoji: '🚫', label: 'Não', value: 'nao'),
      ],
    ),
    MatchQuestion(
      title: 'Outros pets em casa?',
      options: [
        MatchOption(emoji: '🐕', label: 'Sim, cão(ões)', value: 'cao'),
        MatchOption(emoji: '🐈', label: 'Sim, gato(s)', value: 'gato'),
        MatchOption(emoji: '🐾', label: 'Sim, outros', value: 'outros'),
        MatchOption(emoji: '🚫', label: 'Não tenho', value: 'nao'),
      ],
    ),
    MatchQuestion(
      title: 'Que companheiro busca?',
      options: [
        MatchOption(emoji: '🛋️', label: 'Tranquilo, ficar em casa', value: 'tranquilo'),
        MatchOption(emoji: '⚡', label: 'Energético, atividades', value: 'energetico'),
        MatchOption(emoji: '🤗', label: 'Carinhoso e apegado', value: 'carinhoso'),
        MatchOption(emoji: '🧠', label: 'Inteligente e treinável', value: 'inteligente'),
      ],
    ),
  ];

  static const List<String> _fieldOrder = [
    'tipoMoradia',
    'disponibilidade',
    'experienciaPrevia',
    'criancasEmCasa',
    'outrosPets',
    'perfilCompanheiro',
  ];

  // ── Estado do quiz ─────────────────────────────────────────────────────────

  int currentQuestion = 0;
  final Map<String, String> answers = {};
  int? selectedOptionIndex;
  bool quizCompleted = false;

  // ── Estado de rede ─────────────────────────────────────────────────────────

  bool isSaving = false;
  bool isLoadingResult = false;
  String? error;

  MatchResult? result;
  bool hasExistingQuestionario = false;

  String _msg(Object e) => e is Failure ? e.message : e.toString();

  // ── Navegação do quiz ──────────────────────────────────────────────────────

  void selectOption(int index) {
    selectedOptionIndex = index;
    notifyListeners();
  }

  bool get isLastQuestion => currentQuestion == questions.length - 1;

  void nextQuestion() {
    if (selectedOptionIndex == null) return;

    final field = _fieldOrder[currentQuestion];
    final value = questions[currentQuestion].options[selectedOptionIndex!].value;
    answers[field] = value;

    if (isLastQuestion) {
      quizCompleted = true;
    } else {
      currentQuestion++;
      selectedOptionIndex = null;
    }
    notifyListeners();
  }

  void previousQuestion() {
    if (currentQuestion == 0) return;
    currentQuestion--;
    selectedOptionIndex = null;
    notifyListeners();
  }

  void resetQuiz() {
    currentQuestion = 0;
    answers.clear();
    selectedOptionIndex = null;
    quizCompleted = false;
    error = null;
    notifyListeners();
  }

  // ── Persistência ───────────────────────────────────────────────────────────

  /// Verifica se o adotante já respondeu o questionário antes (ex: ao abrir
  /// a tela de match pela primeira vez na sessão).
  Future<void> checkExistingQuestionario() async {
    try {
      final existing = await datasource.buscarMeuQuestionario();
      hasExistingQuestionario = existing != null;
    } catch (_) {
      hasExistingQuestionario = false;
    }
    notifyListeners();
  }

  /// Envia as respostas para o backend ao final do quiz.
  Future<bool> submitQuestionario() async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await datasource.salvarQuestionario(
        tipoMoradia: answers['tipoMoradia']!,
        disponibilidade: answers['disponibilidade']!,
        experienciaPrevia: answers['experienciaPrevia']!,
        criancasEmCasa: answers['criancasEmCasa']!,
        outrosPets: answers['outrosPets']!,
        perfilCompanheiro: answers['perfilCompanheiro']!,
      );
      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = _msg(e);
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Calcula e carrega os resultados de match (pets ordenados por score).
  Future<void> loadResult() async {
    isLoadingResult = true;
    error = null;
    notifyListeners();
    try {
      final model = await datasource.calcularMeuMatch();
      result = model.toEntity();
    } catch (e) {
      error = _msg(e);
    }
    isLoadingResult = false;
    notifyListeners();
  }

  /// Remove o questionário salvo e reinicia o quiz do zero.
  Future<void> refazerQuiz() async {
    try {
      await datasource.removerQuestionario();
    } catch (_) {
      // Mesmo se a remoção falhar, permite refazer localmente
    }
    result = null;
    hasExistingQuestionario = false;
    resetQuiz();
  }
}
