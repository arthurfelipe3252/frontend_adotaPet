import '../../domain/entities/follow_up_update.dart';

class FollowUpUpdateModel {
  final String id;
  final String followUpId;
  final DateTime dataEnvio;
  final List<String> fotosUrls;
  final String? descricao;
  final String? statusSaude;
  final String? statusComportamento;
  final String? statusAlimentacao;
  final bool aprovado;
  final String? comentario;

  FollowUpUpdateModel({
    required this.id,
    required this.followUpId,
    required this.dataEnvio,
    required this.fotosUrls,
    this.descricao,
    this.statusSaude,
    this.statusComportamento,
    this.statusAlimentacao,
    required this.aprovado,
    this.comentario,
  });

  factory FollowUpUpdateModel.fromJson(Map<String, dynamic> json) {
    return FollowUpUpdateModel(
      id: json['id'],
      followUpId: json['followUpId'],
      dataEnvio: DateTime.parse(json['dataEnvio']),
      fotosUrls: List<String>.from(json['fotosUrls'] ?? []),
      descricao: json['descricao'],
      statusSaude: json['statusSaude'],
      statusComportamento: json['statusComportamento'],
      statusAlimentacao: json['statusAlimentacao'],
      aprovado: json['aprovado'] ?? false,
      comentario: json['comentario'],
    );
  }

  FollowUpUpdate toEntity() {
    return FollowUpUpdate(
      id: id,
      followUpId: followUpId,
      dataEnvio: dataEnvio,
      fotosUrls: fotosUrls,
      descricao: descricao,
      statusSaude: statusSaude,
      statusComportamento: statusComportamento,
      statusAlimentacao: statusAlimentacao,
      aprovadoPeloAnunciante: aprovado,
      comentarioAnunciante: comentario,
    );
  }
}
