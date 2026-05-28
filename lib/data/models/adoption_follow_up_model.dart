import '../../domain/entities/adoption_follow_up.dart';

class AdoptionFollowUpModel {
  final String id;
  final String petId;
  final String petNome;
  final String? petFotoUrl;
  final String adotanteId;
  final String adotanteNome;
  final String anuncianteId;
  final String anuncianteNome;
  final String anuncianteTipo;
  final DateTime dataInicio;
  final DateTime? dataUltimaAtualizacao;
  final DateTime dataProximaAtualizacao;
  final String status;

  AdoptionFollowUpModel({
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

  factory AdoptionFollowUpModel.fromJson(Map<String, dynamic> json) {
    return AdoptionFollowUpModel(
      id: json['id'],
      petId: json['petId'],
      petNome: json['petNome'],
      petFotoUrl: json['petFotoUrl'],
      adotanteId: json['adotanteId'],
      adotanteNome: json['adotanteNome'],
      anuncianteId: json['anuncianteId'],
      anuncianteNome: json['anuncianteNome'],
      anuncianteTipo: json['anuncianteTipo'],
      dataInicio: DateTime.parse(json['dataInicio']),
      dataUltimaAtualizacao: json['dataUltimaAtualizacao'] != null
          ? DateTime.parse(json['dataUltimaAtualizacao'])
          : null,
      dataProximaAtualizacao: DateTime.parse(json['dataProximaAtualizacao']),
      status: json['status'],
    );
  }

  AdoptionFollowUp toEntity() {
    FollowUpStatus entityStatus;
    switch (status) {
      case 'EM_DIA':
        entityStatus = FollowUpStatus.emDia;
        break;
      case 'PROXIMO_VENCIMENTO':
        entityStatus = FollowUpStatus.proximoVencimento;
        break;
      case 'ATRASADO':
        entityStatus = FollowUpStatus.atrasado;
        break;
      case 'PENDENTE':
        entityStatus = FollowUpStatus.pendente;
        break;
      case 'CONCLUIDO':
        entityStatus = FollowUpStatus.concluido;
        break;
      default:
        entityStatus = FollowUpStatus.emDia;
    }

    return AdoptionFollowUp(
      id: id,
      petId: petId,
      petNome: petNome,
      petFotoUrl: petFotoUrl,
      adotanteId: adotanteId,
      adotanteNome: adotanteNome,
      anuncianteId: anuncianteId,
      anuncianteNome: anuncianteNome,
      anuncianteTipo: anuncianteTipo,
      dataInicio: dataInicio,
      dataUltimaAtualizacao: dataUltimaAtualizacao,
      dataProximaAtualizacao: dataProximaAtualizacao,
      status: entityStatus,
    );
  }
}
