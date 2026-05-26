class AdoptionRequest {
  final String id;
  final String petId;
  final String adopterId;
  final String status;
  final String preTriageStatus;
  final double? matchScore;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  

  AdoptionRequest({
    required this.id,
    required this.petId,
    required this.adopterId,
    required this.status,
    required this.preTriageStatus,
    this.matchScore,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}