/// Tipos de resposta do questionário de match — mantidos como String para
/// bater 1:1 com os enums do backend (snake_case) sem camada extra de
/// mapeamento.
class QuestionarioMatch {
  final String id;
  final String adotanteId;
  final String tipoMoradia;
  final String disponibilidade;
  final String experienciaPrevia;
  final String criancasEmCasa;
  final String outrosPets;
  final String perfilCompanheiro;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuestionarioMatch({
    required this.id,
    required this.adotanteId,
    required this.tipoMoradia,
    required this.disponibilidade,
    required this.experienciaPrevia,
    required this.criancasEmCasa,
    required this.outrosPets,
    required this.perfilCompanheiro,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Um pet com seu score de compatibilidade calculado pelo backend.
class MatchResultItem {
  final String petId;
  final String nome;
  final String especie;
  final String? raca;
  final String porte;
  final String sexo;
  final int idadeMeses;
  final bool castrado;
  final bool vacinado;
  final String? temperamento;
  final List<String> fotosUrls;
  final int score;

  MatchResultItem({
    required this.petId,
    required this.nome,
    required this.especie,
    this.raca,
    required this.porte,
    required this.sexo,
    required this.idadeMeses,
    required this.castrado,
    required this.vacinado,
    this.temperamento,
    required this.fotosUrls,
    required this.score,
  });

  String get especieLabel {
    switch (especie) {
      case 'cao':
        return 'Cão';
      case 'gato':
        return 'Gato';
      default:
        return 'Outro';
    }
  }

  String get porteLabel {
    switch (porte) {
      case 'pequeno':
        return 'Pequeno';
      case 'medio':
        return 'Médio';
      default:
        return 'Grande';
    }
  }

  String get idadeFormatada {
    final anos = idadeMeses ~/ 12;
    final meses = idadeMeses % 12;
    if (anos > 0 && meses > 0) return '${anos}a ${meses}m';
    if (anos > 0) return '$anos ${anos == 1 ? 'ano' : 'anos'}';
    return '$meses ${meses == 1 ? 'mês' : 'meses'}';
  }

  List<String> get temperamentoTags {
    if (temperamento == null || temperamento!.isEmpty) return [];
    return temperamento!
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }
}

/// Resultado completo do cálculo de match: o questionário usado e a lista
/// de pets ordenados por score decrescente.
class MatchResult {
  final String adotanteId;
  final QuestionarioMatch questionario;
  final List<MatchResultItem> resultados;
  final int totalPetsAnalisados;
  final DateTime geradoEm;

  MatchResult({
    required this.adotanteId,
    required this.questionario,
    required this.resultados,
    required this.totalPetsAnalisados,
    required this.geradoEm,
  });
}
