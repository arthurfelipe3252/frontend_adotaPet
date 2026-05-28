enum FollowUpStatus {
  emDia,
  proximoVencimento,
  atrasado,
  pendente,
  concluido,
}

class AdoptionFollowUp {
  final String id;
  final String petId;
  final String petNome;
  final String? petFotoUrl;
  final String adotanteId;
  final String adotanteNome;
  final String anuncianteId;
  final String anuncianteNome;
  final String anuncianteTipo; // "ong" ou "pessoa"
  final DateTime dataInicio;
  final DateTime? dataUltimaAtualizacao;
  final DateTime dataProximaAtualizacao;
  final FollowUpStatus status;

  const AdoptionFollowUp({
    required this.id,
    required this.petId,
    required this.petNome,
    this.petFotoUrl,
    required this.adotanteId,
    required this.adotanteNome,
    required this.anuncianteId,
    required this.anuncianteNome,
    required this.anuncianteTipo,
    required this.dataInicio,
    this.dataUltimaAtualizacao,
    required this.dataProximaAtualizacao,
    required this.status,
  });
}
