import 'package:adota_pet/data/datasources/cep_remote_datasource.dart';
import 'package:adota_pet/domain/entities/endereco.dart';
import 'package:adota_pet/domain/repositories/cep_repository.dart';

class CepRepositoryImpl implements CepRepository {
  final CepRemoteDatasource remote;

  CepRepositoryImpl(this.remote);

  @override
  Future<Endereco?> consultarCep(String cep) async {
    try {
      final model = await remote.consultar(cep);
      return model?.toEntity();
    } catch (_) {
      // Engole erros de rede — preenchimento manual continua possível.
      return null;
    }
  }
}
