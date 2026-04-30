import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/data/datasources/users_remote_datasource.dart';
import 'package:adota_pet/data/models/criar_protetor_ong_request_model.dart';
import 'package:adota_pet/domain/entities/criar_protetor_ong_params.dart';
import 'package:adota_pet/domain/entities/protetor_ong.dart';
import 'package:adota_pet/domain/repositories/users_repository.dart';

class UsersRepositoryImpl implements UsersRepository {
  final UsersRemoteDatasource remote;

  UsersRepositoryImpl(this.remote);

  @override
  Future<ProtetorOng> criarProtetorOng(CriarProtetorOngParams params) async {
    try {
      final request = CriarProtetorOngRequestModel.fromParams(params);
      final model = await remote.criarProtetorOng(request);
      return model.toEntity();
    } on ConflictFailure catch (f) {
      // 409: inspeciona a mensagem do backend pra direcionar ao field correto.
      final lower = f.message.toLowerCase();
      if (lower.contains('email')) {
        throw Failure('Este email já está cadastrado.', field: 'email');
      }
      if (lower.contains('cpf') || lower.contains('cnpj')) {
        throw Failure('CPF/CNPJ já cadastrado.', field: 'cpfCnpj');
      }
      throw Failure('Email ou CPF/CNPJ já cadastrado.');
    }
  }

  @override
  Future<ProtetorOng> getMeProtetorOng() async {
    final model = await remote.getMe();
    return model.toEntity();
  }
}
