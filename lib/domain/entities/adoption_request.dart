class AdoptionRequest {
  final String id;
  final String petId;
  final String? protetorId;
  final String adopterId;
  final String? adopterNome;
  final String? protetorNome;
  final String status;
  final String preTriageStatus;
  final double? matchScore;
  final Map<String, dynamic>? matchAnswers;
  final String? mensagem;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdoptionRequest({
    required this.id,
    required this.petId,
    this.protetorId,
    required this.adopterId,
    this.adopterNome,
    this.protetorNome,
    required this.status,
    required this.preTriageStatus,
    this.matchScore,
    this.matchAnswers,
    this.mensagem,
    required this.createdAt,
    required this.updatedAt,
  });

  // Alias para compatibilidade com código legado que usa .notes
  String? get notes => mensagem;
}