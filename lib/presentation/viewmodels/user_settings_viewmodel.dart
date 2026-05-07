import 'package:flutter/foundation.dart';

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/domain/entities/adotante.dart';
import 'package:adota_pet/domain/entities/endereco.dart';
import 'package:adota_pet/domain/entities/protetor_ong.dart';
import 'package:adota_pet/domain/entities/usuario.dart';
import 'package:adota_pet/domain/entities/user_settings_params.dart';
import 'package:adota_pet/domain/repositories/cep_repository.dart';
import 'package:adota_pet/domain/repositories/users_repository.dart';

class UserSettingsViewModel extends ChangeNotifier {
  static const int maxFileSizeBytes = 5 * 1024 * 1024;
  static const int descricaoMaxLength = 1800;

  final UsersRepository usersRepository;
  final CepRepository cepRepository;

  bool isLoading = false;
  bool isSavingProfile = false;
  bool isChangingPassword = false;
  bool isCepLoading = false;
  bool hasLoaded = false;
  String? error;
  String? passwordError;
  Map<String, String> fieldErrors = {};
  Map<String, String> passwordFieldErrors = {};

  Adotante? adotante;
  ProtetorOng? protetorOng;
  String? _loadedUsuarioId;
  bool _profileHadEndereco = false;

  String tipoUsuario = '';
  String nome = '';
  String email = '';
  String documento = '';
  String telefone = '';
  String telefoneContato = '';
  String descricao = '';
  String? imagemBase64;
  Uint8List? imagemBytes;
  String? imagemFilename;
  bool removerImagem = false;

  String cep = '';
  String logradouro = '';
  String numero = '';
  String complemento = '';
  String bairro = '';
  String cidade = '';
  String estado = '';

  String senhaAtual = '';
  String senhaNova = '';
  String confirmarSenha = '';

  UserSettingsViewModel({
    required this.usersRepository,
    required this.cepRepository,
  });

  bool get isAdotante => tipoUsuario == Usuario.tipoAdotante;
  bool get isProtetor => tipoUsuario == Usuario.tipoProtetor;
  bool get isOng => tipoUsuario == Usuario.tipoOng;
  bool get isProtetorOuOng => isProtetor || isOng;

  String get tipoLabel {
    if (isOng) return 'ONG';
    if (isProtetor) return 'Protetor';
    if (isAdotante) return 'Doador';
    return 'Usuário';
  }

  bool get hasProfileImage =>
      imagemBytes != null ||
      ((imagemBase64 ?? '').trim().isNotEmpty && !removerImagem);

  Future<void> loadFor(Usuario usuario, {bool force = false}) async {
    if (isLoading) return;
    if (!force && hasLoaded && _loadedUsuarioId == usuario.id) return;

    isLoading = true;
    error = null;
    fieldErrors = {};
    passwordError = null;
    passwordFieldErrors = {};
    notifyListeners();

    try {
      if (usuario.isAdotante) {
        final profile = await usersRepository.getMeAdotante();
        _applyAdotante(profile);
      } else if (usuario.isProtetorOuOng) {
        final profile = await usersRepository.getMeProtetorOng();
        _applyProtetorOng(profile);
      } else {
        throw Failure('Tipo de usuário não suportado.');
      }
      _loadedUsuarioId = usuario.id;
      hasLoaded = true;
      isLoading = false;
      notifyListeners();
    } on Failure catch (f) {
      _setError(f);
    } catch (_) {
      _setError(Failure('Não foi possível carregar suas configurações.'));
    }
  }

  void setNome(String value) => _setField('nome', value, (x) => nome = x);
  void setTelefone(String value) =>
      _setField('telefone', value, (x) => telefone = x);
  void setTelefoneContato(String value) =>
      _setField('telefoneContato', value, (x) => telefoneContato = x);
  void setDescricao(String value) =>
      _setField('descricao', value, (x) => descricao = x);
  void setCep(String value) {
    cep = value;
    fieldErrors.remove('cep');
  }

  void setLogradouro(String value) =>
      _setField('logradouro', value, (x) => logradouro = x);
  void setNumero(String value) => _setField('numero', value, (x) => numero = x);
  void setComplemento(String value) =>
      _setField('complemento', value, (x) => complemento = x);
  void setBairro(String value) => _setField('bairro', value, (x) => bairro = x);
  void setCidade(String value) => _setField('cidade', value, (x) => cidade = x);
  void setEstado(String value) {
    estado = value.toUpperCase();
    fieldErrors.remove('estado');
  }

  void setImagem(Uint8List bytes, String filename) {
    imagemBytes = bytes;
    imagemFilename = filename;
    removerImagem = false;
    fieldErrors.remove('imagem');
    notifyListeners();
  }

  void removeImagem() {
    imagemBytes = null;
    imagemFilename = null;
    imagemBase64 = null;
    removerImagem = true;
    fieldErrors.remove('imagem');
    notifyListeners();
  }

  void setSenhaAtual(String value) =>
      _setPasswordField('senhaAtual', value, (x) => senhaAtual = x);
  void setSenhaNova(String value) =>
      _setPasswordField('senhaNova', value, (x) => senhaNova = x);
  void setConfirmarSenha(String value) =>
      _setPasswordField('confirmarSenha', value, (x) => confirmarSenha = x);

  Future<void> consultarCep() async {
    final clean = _digits(cep);
    if (clean.length != 8) return;

    isCepLoading = true;
    notifyListeners();

    final endereco = await cepRepository.consultarCep(clean);

    isCepLoading = false;
    if (endereco != null) {
      logradouro = endereco.logradouro;
      bairro = endereco.bairro;
      cidade = endereco.cidade;
      estado = endereco.estado;
      fieldErrors.remove('logradouro');
      fieldErrors.remove('bairro');
      fieldErrors.remove('cidade');
      fieldErrors.remove('estado');
    }
    notifyListeners();
  }

  Future<Usuario?> saveProfile() async {
    if (!_validateProfile()) return null;

    isSavingProfile = true;
    error = null;
    notifyListeners();

    try {
      final endereco = _shouldSendEndereco ? _buildEndereco() : null;
      final usuario = isAdotante
          ? await _saveAdotante(endereco)
          : await _saveProtetorOng(endereco);

      isSavingProfile = false;
      notifyListeners();
      return usuario;
    } on Failure catch (f) {
      _setError(f);
      return null;
    } catch (_) {
      _setError(Failure('Não foi possível salvar suas configurações.'));
      return null;
    }
  }

  Future<bool> changePassword() async {
    if (!_validatePassword()) return false;

    isChangingPassword = true;
    passwordError = null;
    notifyListeners();

    try {
      await usersRepository.alterarSenha(
        AlterarSenhaParams(senhaAtual: senhaAtual, senhaNova: senhaNova),
      );
      senhaAtual = '';
      senhaNova = '';
      confirmarSenha = '';
      isChangingPassword = false;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      _setPasswordError(f);
      return false;
    } catch (_) {
      _setPasswordError(Failure('Não foi possível alterar a senha.'));
      return false;
    }
  }

  void clearError() {
    if (error == null && fieldErrors.isEmpty) return;
    error = null;
    fieldErrors = {};
    notifyListeners();
  }

  void clearPasswordError() {
    if (passwordError == null && passwordFieldErrors.isEmpty) return;
    passwordError = null;
    passwordFieldErrors = {};
    notifyListeners();
  }

  void _applyAdotante(Adotante profile) {
    adotante = profile;
    protetorOng = null;
    tipoUsuario = profile.usuario.tipoUsuario;
    documento = profile.cpf;
    imagemBase64 = profile.imagemBase64;
    _applyUsuario(profile.usuario);
    _applyEndereco(profile.endereco);
  }

  void _applyProtetorOng(ProtetorOng profile) {
    protetorOng = profile;
    adotante = null;
    tipoUsuario = profile.usuario.tipoUsuario;
    documento = profile.cpfCnpj;
    telefoneContato = profile.telefoneContato ?? '';
    descricao = profile.descricao ?? '';
    imagemBase64 = profile.imagemBase64;
    _applyUsuario(profile.usuario);
    _applyEndereco(profile.endereco);
  }

  void _applyUsuario(Usuario usuario) {
    nome = usuario.nome;
    email = usuario.email;
    telefone = usuario.telefone ?? '';
    imagemBytes = null;
    imagemFilename = null;
    removerImagem = false;
  }

  void _applyEndereco(Endereco? endereco) {
    _profileHadEndereco = endereco != null;
    cep = endereco?.cep ?? '';
    logradouro = endereco?.logradouro ?? '';
    numero = endereco?.numero ?? '';
    complemento = endereco?.complemento ?? '';
    bairro = endereco?.bairro ?? '';
    cidade = endereco?.cidade ?? '';
    estado = endereco?.estado ?? '';
  }

  bool _validateProfile() {
    final errors = <String, String>{};

    if (nome.trim().length < 2) {
      errors['nome'] = 'Informe um nome com pelo menos 2 caracteres.';
    }

    final telefoneDigits = _digits(telefone);
    if (telefoneDigits.isNotEmpty &&
        telefoneDigits.length != 10 &&
        telefoneDigits.length != 11) {
      errors['telefone'] = 'Telefone inválido.';
    }

    final contatoDigits = _digits(telefoneContato);
    if (isProtetorOuOng &&
        contatoDigits.isNotEmpty &&
        contatoDigits.length != 10 &&
        contatoDigits.length != 11) {
      errors['telefoneContato'] = 'Telefone inválido.';
    }

    if (isProtetorOuOng && descricao.length > descricaoMaxLength) {
      errors['descricao'] = 'Descrição muito longa.';
    }

    if (imagemBytes != null && imagemBytes!.lengthInBytes > maxFileSizeBytes) {
      errors['imagem'] = 'Imagem muito grande. Limite: 5MB.';
    }

    if (_shouldSendEndereco) {
      final cleanCep = _digits(cep);
      if (cleanCep.length != 8) {
        errors['cep'] = 'CEP inválido.';
      }
      if (logradouro.trim().isEmpty) {
        errors['logradouro'] = 'Campo obrigatório.';
      }
      if (numero.trim().isEmpty) {
        errors['numero'] = 'Informe o número.';
      }
      if (bairro.trim().isEmpty) {
        errors['bairro'] = 'Campo obrigatório.';
      }
      if (cidade.trim().isEmpty) {
        errors['cidade'] = 'Campo obrigatório.';
      }
      if (estado.trim().length != 2) {
        errors['estado'] = 'UF inválida (use 2 letras).';
      }
    }

    fieldErrors = errors;
    error = null;
    notifyListeners();
    return errors.isEmpty;
  }

  bool _validatePassword() {
    final errors = <String, String>{};

    if (senhaAtual.isEmpty) {
      errors['senhaAtual'] = 'Informe sua senha atual.';
    }
    if (senhaNova.length < 8) {
      errors['senhaNova'] = 'A nova senha precisa de pelo menos 8 caracteres.';
    } else if (senhaNova.length > 72) {
      errors['senhaNova'] = 'A nova senha não pode passar de 72 caracteres.';
    }
    if (errors['senhaNova'] == null && senhaNova != confirmarSenha) {
      errors['confirmarSenha'] = 'As senhas não conferem.';
    }
    if (senhaAtual.isNotEmpty && senhaNova == senhaAtual) {
      errors['senhaNova'] = 'Use uma senha diferente da atual.';
    }

    passwordFieldErrors = errors;
    passwordError = null;
    notifyListeners();
    return errors.isEmpty;
  }

  Future<Usuario> _saveAdotante(Endereco? endereco) async {
    final updated = await usersRepository.atualizarAdotante(
      AtualizarAdotanteParams(
        nome: nome.trim(),
        telefone: _optionalDigits(telefone),
        imagemBytes: imagemBytes,
        removerImagem: removerImagem,
        endereco: endereco,
      ),
    );
    _applyAdotante(updated);
    return updated.usuario;
  }

  Future<Usuario> _saveProtetorOng(Endereco? endereco) async {
    final updated = await usersRepository.atualizarProtetorOng(
      AtualizarProtetorOngParams(
        nome: nome.trim(),
        telefone: _optionalDigits(telefone),
        telefoneContato: _optionalDigits(telefoneContato),
        descricao: descricao.trim(),
        imagemBytes: imagemBytes,
        removerImagem: removerImagem,
        endereco: endereco,
      ),
    );
    _applyProtetorOng(updated);
    return updated.usuario;
  }

  Endereco _buildEndereco() {
    return Endereco(
      logradouro: logradouro.trim(),
      numero: numero.trim(),
      complemento: complemento.trim().isEmpty ? null : complemento.trim(),
      bairro: bairro.trim(),
      cidade: cidade.trim(),
      estado: estado.trim().toUpperCase(),
      cep: _digits(cep),
    );
  }

  bool get _shouldSendEndereco {
    if (_profileHadEndereco) return true;
    return [
      cep,
      logradouro,
      numero,
      complemento,
      bairro,
      cidade,
      estado,
    ].any((value) => value.trim().isNotEmpty);
  }

  void _setField(String key, String value, void Function(String) apply) {
    apply(value);
    fieldErrors.remove(key);
  }

  void _setPasswordField(
    String key,
    String value,
    void Function(String) apply,
  ) {
    apply(value);
    passwordFieldErrors.remove(key);
  }

  void _setError(Failure f) {
    if (f.field != null) {
      fieldErrors = {f.field!: f.message};
      error = null;
    } else {
      fieldErrors = {};
      error = f.message;
    }
    isLoading = false;
    isSavingProfile = false;
    notifyListeners();
  }

  void _setPasswordError(Failure f) {
    final lower = f.message.toLowerCase();
    if (lower.contains('senha atual')) {
      passwordFieldErrors = {'senhaAtual': f.message};
      passwordError = null;
    } else {
      passwordFieldErrors = {};
      passwordError = f.message;
    }
    isChangingPassword = false;
    notifyListeners();
  }

  String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String? _optionalDigits(String value) {
    final digits = _digits(value);
    return digits.isEmpty ? null : digits;
  }
}
