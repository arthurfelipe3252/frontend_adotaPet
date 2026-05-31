import 'package:adota_pet/domain/entities/endereco.dart';

abstract class CepRepository {
  /// Consulta o CEP no ViaCEP. Retorna `null` quando o CEP não existe ou
  /// quando há falha de rede (preenchimento manual continua possível).
  /// O `numero` do `Endereco` retornado virá vazio — não vem da resposta do CEP.
  Future<Endereco?> consultarCep(String cep);
}
