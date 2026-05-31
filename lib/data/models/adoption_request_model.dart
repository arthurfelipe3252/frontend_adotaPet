import 'package:adota_pet/domain/entities/adoption_request.dart';

class AdoptionRequestModel extends AdoptionRequest {
  AdoptionRequestModel({
    required super.id,
    required super.petId,
    super.protetorId,
    required super.adopterId,
    super.adopterNome,
    super.protetorNome,
    required super.status,
    required super.preTriageStatus,
    super.matchScore,
    super.matchAnswers,
    super.mensagem,
    required super.createdAt,
    required super.updatedAt,
  });

  // O NestJS serializa a classe de domínio via JSON.stringify, que expõe
  // os campos privados com underscore (_id, _petId, etc.) pois não há
  // toJSON() nem ClassSerializerInterceptor configurado no backend.
  // O fromJson tenta primeiro a forma sem underscore (GET retorna do DB
  // via restore() que pode ter id), depois com underscore (POST/PATCH
  // retornam create() sem id ainda).
  factory AdoptionRequestModel.fromJson(Map<String, dynamic> json) {
    return AdoptionRequestModel(
      id: _str(json['id']) ?? _str(json['_id']) ?? '',
      petId: _str(json['petId']) ?? _str(json['_petId']) ?? '',
      protetorId: _str(json['protetorId']) ?? _str(json['_protetorId']),
      adopterId: _str(json['adopterId']) ?? _str(json['_adopterId']) ?? '',
      adopterNome: _nestedNome(json['adopter']),
      protetorNome: _nestedNome(json['protetor']),
      status: _str(json['status']) ?? _str(json['_status']) ?? 'received',
      preTriageStatus: _str(json['preTriageStatus']) ?? _str(json['_preTriageStatus']) ?? 'review',
      matchScore: ((json['matchScore'] ?? json['_matchScore']) as num?)?.toDouble(),
      matchAnswers: (json['matchAnswers'] ?? json['_matchAnswers']) != null
          ? Map<String, dynamic>.from((json['matchAnswers'] ?? json['_matchAnswers']) as Map)
          : null,
      mensagem: _str(json['notes']) ?? _str(json['_notes']) ?? _str(json['mensagem']),
      createdAt: _parseDate(json['createdAt'] ?? json['_createdAt']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['_updatedAt']),
    );
  }

  factory AdoptionRequestModel.fromParams({
    required String petId,
    required String adopterId,
    String? protetorId,
    String? mensagem,
    int? matchScore,
    Map<String, dynamic>? questionario,
  }) {
    final now = DateTime.now();
    return AdoptionRequestModel(
      id: '',
      petId: petId,
      adopterId: adopterId,
      protetorId: protetorId,
      status: 'received',
      preTriageStatus: _preTriageFromScore(matchScore),
      matchScore: matchScore?.toDouble(),
      matchAnswers: questionario,
      mensagem: mensagem,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'petId': petId,
        if (protetorId != null) 'protetorId': protetorId,
        'adopterId': adopterId,
        if (mensagem != null && mensagem!.isNotEmpty) 'mensagem': mensagem,
        if (matchScore != null) 'matchScore': matchScore!.round(),
        if (matchAnswers != null) 'questionario': matchAnswers,
      };

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return (s.isEmpty || s == 'null' || s == 'undefined') ? null : s;
  }

  /// Extrai `nome` de um objeto aninhado (`adopter`/`protetor`) que o backend
  /// passou a incluir na resposta de adoção.
  static String? _nestedNome(dynamic v) {
    if (v is Map) return _str(v['nome']);
    return null;
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  static String _preTriageFromScore(int? score) {
    if (score == null) return 'review';
    if (score >= 70) return 'qualified';
    return 'disqualified';
  }
}