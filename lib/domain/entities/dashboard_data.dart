// Entidades do painel/dashboard da ONG, espelhando o payload agregado de
// `GET /reports/dashboard`. Imutáveis e sem dependência de framework.

class DashboardKpis {
  final int petsDisponivel;
  final int petsEmProcesso;
  final int petsAdotadoTotal;
  final int petsAdotadoMesAtual;
  final int solicitacoesPendentes;
  final int conversasAtivas;
  final int mensagensNaoLidas;

  /// Percentual de solicitações aprovadas sobre o total. `null` quando não há
  /// nenhuma solicitação (evita divisão por zero no backend).
  final double? taxaConversaoPct;

  /// Média de dias entre criação e aprovação. `null` se nenhuma adoção foi
  /// concluída ainda.
  final double? tempoMedioAdocaoDias;

  const DashboardKpis({
    required this.petsDisponivel,
    required this.petsEmProcesso,
    required this.petsAdotadoTotal,
    required this.petsAdotadoMesAtual,
    required this.solicitacoesPendentes,
    required this.conversasAtivas,
    required this.mensagensNaoLidas,
    this.taxaConversaoPct,
    this.tempoMedioAdocaoDias,
  });
}

class TimelinePoint {
  final DateTime monthStart;
  final int count;

  const TimelinePoint({required this.monthStart, required this.count});
}

class AdoptionFunnel {
  final int received;
  final int inAnalysis;
  final int approved;
  final int rejected;

  const AdoptionFunnel({
    required this.received,
    required this.inAnalysis,
    required this.approved,
    required this.rejected,
  });

  int get total => received + inAnalysis + approved + rejected;
}

class TopPet {
  final String petId;
  final String nome;
  final String especie;
  final String porte;
  final String status;
  final int totalRequests;

  const TopPet({
    required this.petId,
    required this.nome,
    required this.especie,
    required this.porte,
    required this.status,
    required this.totalRequests,
  });

  String get especieLabel => _especieLabel(especie);
}

class StalePet {
  final String id;
  final String nome;
  final String especie;
  final String porte;
  final DateTime createdAt;
  final int diasNoCatalogo;

  const StalePet({
    required this.id,
    required this.nome,
    required this.especie,
    required this.porte,
    required this.createdAt,
    required this.diasNoCatalogo,
  });

  String get especieLabel => _especieLabel(especie);
}

class DashboardData {
  final DashboardKpis kpis;
  final List<TimelinePoint> adoptionsTimeline;
  final List<TimelinePoint> requestsTimeline;
  final AdoptionFunnel funnel;
  final List<TopPet> topPets;
  final List<StalePet> stalePets;

  const DashboardData({
    required this.kpis,
    required this.adoptionsTimeline,
    required this.requestsTimeline,
    required this.funnel,
    required this.topPets,
    required this.stalePets,
  });
}

String _especieLabel(String especie) {
  switch (especie) {
    case 'cao':
      return 'Cão';
    case 'gato':
      return 'Gato';
    default:
      return 'Outro';
  }
}
