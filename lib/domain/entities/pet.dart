class Pet {
  final String id;
  final String protetorId;
  final String nome;
  final String especie;
  final String? raca;
  final String porte;
  final String sexo;
  final int idadeMeses;
  final bool castrado;
  final bool vacinado;
  final String? descricao;
  final String? temperamento;
  final String status;
  final List<String> fotosUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Pet({
    required this.id,
    required this.protetorId,
    required this.nome,
    required this.especie,
    this.raca,
    required this.porte,
    required this.sexo,
    required this.idadeMeses,
    required this.castrado,
    required this.vacinado,
    this.descricao,
    this.temperamento,
    required this.status,
    this.fotosUrls = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get idadeFormatada {
    final anos = idadeMeses ~/ 12;
    final meses = idadeMeses % 12;
    if (anos > 0 && meses > 0) return '${anos}a ${meses}m';
    if (anos > 0) return '$anos ${anos == 1 ? 'ano' : 'anos'}';
    return '$meses ${meses == 1 ? 'mês' : 'meses'}';
  }

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

  String get sexoLabel => sexo == 'macho' ? 'Macho' : 'Fêmea';

  String get statusLabel {
    switch (status) {
      case 'disponivel':
        return 'Disponível';
      case 'em_processo':
        return 'Em processo';
      case 'adotado':
        return 'Adotado';
      default:
        return status;
    }
  }
}
