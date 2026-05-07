import 'package:adota_pet/domain/entities/criar_protetor_ong_params.dart';
import 'package:adota_pet/domain/entities/protetor_ong.dart';

abstract class UsersRepository {
  /// Cria um protetor (PF) ou ONG (PJ). Operação transacional no backend.
  /// Lança `Failure` com `field` direcionado em 409 (email/cpfCnpj duplicado).
  Future<ProtetorOng> criarProtetorOng(CriarProtetorOngParams params);

  /// Retorna o perfil completo do protetor/ong autenticado.
  Future<ProtetorOng> getMeProtetorOng();
}
