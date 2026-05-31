import 'package:adota_pet/domain/entities/dashboard_data.dart';

/// Faz o parse defensivo do payload de `GET /reports/dashboard` para as
/// entidades de domínio. Campos numéricos podem chegar como int ou double; os
/// nullable (`taxaConversaoPct`, `tempoMedioAdocaoDias`) vêm como `number|null`.
class DashboardResponseModel {
  final DashboardData data;

  const DashboardResponseModel(this.data);

  factory DashboardResponseModel.fromJson(Map<String, dynamic> json) {
    return DashboardResponseModel(
      DashboardData(
        kpis: _parseKpis(json['kpis'] as Map<String, dynamic>? ?? const {}),
        adoptionsTimeline: _parseTimeline(json['adoptionsTimeline']),
        requestsTimeline: _parseTimeline(json['requestsTimeline']),
        funnel: _parseFunnel(
          json['funnel'] as Map<String, dynamic>? ?? const {},
        ),
        topPets: _parseTopPets(json['topPets']),
        stalePets: _parseStalePets(json['stalePets']),
      ),
    );
  }

  DashboardData toEntity() => data;

  // ── Helpers de parse ────────────────────────────────────────────────────
  static int _int(dynamic v) => (v as num?)?.toInt() ?? 0;
  static double? _doubleN(dynamic v) => (v as num?)?.toDouble();
  static String _str(dynamic v) => v?.toString() ?? '';
  static DateTime _date(dynamic v) =>
      DateTime.tryParse(v?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  static DashboardKpis _parseKpis(Map<String, dynamic> j) {
    return DashboardKpis(
      petsDisponivel: _int(j['petsDisponivel']),
      petsEmProcesso: _int(j['petsEmProcesso']),
      petsAdotadoTotal: _int(j['petsAdotadoTotal']),
      petsAdotadoMesAtual: _int(j['petsAdotadoMesAtual']),
      solicitacoesPendentes: _int(j['solicitacoesPendentes']),
      conversasAtivas: _int(j['conversasAtivas']),
      mensagensNaoLidas: _int(j['mensagensNaoLidas']),
      taxaConversaoPct: _doubleN(j['taxaConversaoPct']),
      tempoMedioAdocaoDias: _doubleN(j['tempoMedioAdocaoDias']),
    );
  }

  static List<TimelinePoint> _parseTimeline(dynamic v) {
    if (v is! List) return const [];
    return v
        .whereType<Map<String, dynamic>>()
        .map(
          (j) => TimelinePoint(
            monthStart: _date(j['monthStart']),
            count: _int(j['count']),
          ),
        )
        .toList();
  }

  static AdoptionFunnel _parseFunnel(Map<String, dynamic> j) {
    return AdoptionFunnel(
      received: _int(j['received']),
      inAnalysis: _int(j['inAnalysis']),
      approved: _int(j['approved']),
      rejected: _int(j['rejected']),
    );
  }

  static List<TopPet> _parseTopPets(dynamic v) {
    if (v is! List) return const [];
    return v
        .whereType<Map<String, dynamic>>()
        .map(
          (j) => TopPet(
            petId: _str(j['petId']),
            nome: _str(j['nome']),
            especie: _str(j['especie']),
            porte: _str(j['porte']),
            status: _str(j['status']),
            totalRequests: _int(j['totalRequests']),
          ),
        )
        .toList();
  }

  static List<StalePet> _parseStalePets(dynamic v) {
    if (v is! List) return const [];
    return v
        .whereType<Map<String, dynamic>>()
        .map(
          (j) => StalePet(
            id: _str(j['id']),
            nome: _str(j['nome']),
            especie: _str(j['especie']),
            porte: _str(j['porte']),
            createdAt: _date(j['createdAt']),
            diasNoCatalogo: _int(j['diasNoCatalogo']),
          ),
        )
        .toList();
  }
}
