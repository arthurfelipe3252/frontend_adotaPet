import '../../domain/entities/pet.dart';

class PetModel {
  final String id;
  final String protetorId;
  final String nome;
  final String especie;
  final String? raca;
  final String porte;
  final String sexo;
  final int idadeMeses;
  final bool castrado;
  final bool vacinado;
  final String? descricao;
  final String? temperamento;
  final String status;
  final List<String> fotosUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  PetModel({
    required this.id,
    required this.protetorId,
    required this.nome,
    required this.especie,
    this.raca,
    required this.porte,
    required this.sexo,
    required this.idadeMeses,
    required this.castrado,
    required this.vacinado,
    this.descricao,
    this.temperamento,
    required this.status,
    this.fotosUrls = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'],
      protetorId: json['protetorId'],
      nome: json['nome'],
      especie: json['especie'],
      raca: json['raca'],
      porte: json['porte'],
      sexo: json['sexo'],
      idadeMeses: json['idadeMeses'],
      castrado: json['castrado'],
      vacinado: json['vacinado'],
      descricao: json['descricao'],
      temperamento: json['temperamento'],
      status: json['status'],
      fotosUrls: (json['fotosUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Pet toEntity() {
    return Pet(
      id: id,
      protetorId: protetorId,
      nome: nome,
      especie: especie,
      raca: raca,
      porte: porte,
      sexo: sexo,
      idadeMeses: idadeMeses,
      castrado: castrado,
      vacinado: vacinado,
      descricao: descricao,
      temperamento: temperamento,
      status: status,
      fotosUrls: fotosUrls,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
