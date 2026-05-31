import 'package:adota_pet/domain/entities/adotante.dart';
import 'package:adota_pet/domain/entities/criar_adotante_params.dart';
import 'package:adota_pet/domain/entities/criar_protetor_ong_params.dart';
import 'package:adota_pet/domain/entities/protetor_ong.dart';
import 'package:adota_pet/domain/entities/user_settings_params.dart';

abstract class UsersRepository {
  /// Cria um protetor (PF) ou ONG (PJ). Operação transacional no backend.
  /// Lança `Failure` com `field` direcionado em 409 (email/cpfCnpj duplicado).
  Future<ProtetorOng> criarProtetorOng(CriarProtetorOngParams params);

  /// Cria um adotante. Operação transacional no backend.
  /// Lança `Failure` com `field` direcionado em 409 (email/cpf duplicado).
  Future<Adotante> criarAdotante(CriarAdotanteParams params);

  /// Retorna o perfil completo do protetor/ong autenticado.
  Future<ProtetorOng> getMeProtetorOng();

  /// Retorna o perfil completo do adotante autenticado.
  Future<Adotante> getMeAdotante();

  /// Atualiza dados editáveis do adotante autenticado.
  Future<Adotante> atualizarAdotante(AtualizarAdotanteParams params);

  /// Atualiza dados editáveis do protetor/ong autenticado.
  Future<ProtetorOng> atualizarProtetorOng(AtualizarProtetorOngParams params);

  /// Altera a senha do usuário autenticado.
  Future<void> alterarSenha(AlterarSenhaParams params);
}
