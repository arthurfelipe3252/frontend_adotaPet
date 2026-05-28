class FollowUpUpdate {
  final String id;
  final String followUpId;
  final DateTime dataEnvio;
  final List<String> fotosUrls;
  final String? descricao;
  final String? statusSaude;
  final String? statusComportamento;
  final String? statusAlimentacao;
  final bool aprovadoPeloAnunciante;
  final String? comentarioAnunciante;

  const FollowUpUpdate({
    required this.id,
    required this.followUpId,
    required this.dataEnvio,
    required this.fotosUrls,
    this.descricao,
    this.statusSaude,
    this.statusComportamento,
    this.statusAlimentacao,
    this.aprovadoPeloAnunciante = false,
    this.comentarioAnunciante,
  });
}
