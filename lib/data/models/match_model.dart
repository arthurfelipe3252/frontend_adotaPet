import 'package:adota_pet/domain/entities/match.dart';

class QuestionarioMatchModel {
  final String id;
  final String adotanteId;
  final String tipoMoradia;
  final String disponibilidade;
  final String experienciaPrevia;
  final String criancasEmCasa;
  final String outrosPets;
  final String perfilCompanheiro;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuestionarioMatchModel({
    required this.id,
    required this.adotanteId,
    required this.tipoMoradia,
    required this.disponibilidade,
    required this.experienciaPrevia,
    required this.criancasEmCasa,
    required this.outrosPets,
    required this.perfilCompanheiro,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuestionarioMatchModel.fromJson(Map<String, dynamic> json) {
    return QuestionarioMatchModel(
      id: json['id'] as String,
      adotanteId: json['adotanteId'] as String,
      tipoMoradia: json['tipoMoradia'] as String,
      disponibilidade: json['disponibilidade'] as String,
      experienciaPrevia: json['experienciaPrevia'] as String,
      criancasEmCasa: json['criancasEmCasa'] as String,
      outrosPets: json['outrosPets'] as String,
      perfilCompanheiro: json['perfilCompanheiro'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  QuestionarioMatch toEntity() => QuestionarioMatch(
        id: id,
        adotanteId: adotanteId,
        tipoMoradia: tipoMoradia,
        disponibilidade: disponibilidade,
        experienciaPrevia: experienciaPrevia,
        criancasEmCasa: criancasEmCasa,
        outrosPets: outrosPets,
        perfilCompanheiro: perfilCompanheiro,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

class MatchResultItemModel {
  final String petId;
  final String nome;
  final String especie;
  final String? raca;
  final String porte;
  final String sexo;
  final int idadeMeses;
  final bool castrado;
  final bool vacinado;
  final String? temperamento;
  final List<String> fotosUrls;
  final int score;

  MatchResultItemModel({
    required this.petId,
    required this.nome,
    required this.especie,
    this.raca,
    required this.porte,
    required this.sexo,
    required this.idadeMeses,
    required this.castrado,
    required this.vacinado,
    this.temperamento,
    required this.fotosUrls,
    required this.score,
  });

  factory MatchResultItemModel.fromJson(Map<String, dynamic> json) {
    return MatchResultItemModel(
      petId: json['petId'] as String,
      nome: json['nome'] as String,
      especie: json['especie'] as String,
      raca: json['raca'] as String?,
      porte: json['porte'] as String,
      sexo: json['sexo'] as String,
      idadeMeses: json['idadeMeses'] as int,
      castrado: json['castrado'] as bool,
      vacinado: json['vacinado'] as bool,
      temperamento: json['temperamento'] as String?,
      fotosUrls: (json['fotosUrls'] as List?)?.cast<String>() ?? [],
      score: (json['score'] as num).toInt(),
    );
  }

  MatchResultItem toEntity() => MatchResultItem(
        petId: petId,
        nome: nome,
        especie: especie,
        raca: raca,
        porte: porte,
        sexo: sexo,
        idadeMeses: idadeMeses,
        castrado: castrado,
        vacinado: vacinado,
        temperamento: temperamento,
        fotosUrls: fotosUrls,
        score: score,
      );
}

class MatchResultModel {
  final String adotanteId;
  final QuestionarioMatchModel questionario;
  final List<MatchResultItemModel> resultados;
  final int totalPetsAnalisados;
  final DateTime geradoEm;

  MatchResultModel({
    required this.adotanteId,
    required this.questionario,
    required this.resultados,
    required this.totalPetsAnalisados,
    required this.geradoEm,
  });

  factory MatchResultModel.fromJson(Map<String, dynamic> json) {
    return MatchResultModel(
      adotanteId: json['adotanteId'] as String,
      questionario: QuestionarioMatchModel.fromJson(
        json['questionario'] as Map<String, dynamic>,
      ),
      resultados: (json['resultados'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MatchResultItemModel.fromJson)
          .toList(),
      totalPetsAnalisados: json['totalPetsAnalisados'] as int,
      geradoEm: DateTime.parse(json['geradoEm'] as String),
    );
  }

  MatchResult toEntity() => MatchResult(
        adotanteId: adotanteId,
        questionario: questionario.toEntity(),
        resultados: resultados.map((r) => r.toEntity()).toList(),
        totalPetsAnalisados: totalPetsAnalisados,
        geradoEm: geradoEm,
      );
}
