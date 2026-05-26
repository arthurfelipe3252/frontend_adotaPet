import 'package:adota_pet/domain/entities/adoption_request.dart';

class AdoptionRequestModel extends AdoptionRequest {
    AdoptionRequestModel({
    required super.id,
    required super.petId,
    required super.adopterId,
    required super.status,
    required super.preTriageStatus,
    super.matchScore,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
});

  factory AdoptionRequestModel.fromJson(Map<String, dynamic> json) {
    return AdoptionRequestModel(
      id: json['id'] as String,
      petId: json['petId'] as String,
      adopterId: json['adopterId'] as String,
      status: json['status'] as String,
      preTriageStatus: json['preTriageStatus'] as String,
      matchScore: (json['matchScore'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  Map<String, dynamic> toJson() => {
    'petId': petId,
    'adopterId': adopterId,
    if (notes != null) 'notes': notes,
    if (matchScore != null) 'matchScore': matchScore,
  };
}