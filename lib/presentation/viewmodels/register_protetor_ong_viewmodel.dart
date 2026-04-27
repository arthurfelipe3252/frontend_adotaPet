import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/domain/entities/criar_protetor_ong_params.dart';
import 'package:adota_pet/domain/entities/endereco.dart';
import 'package:adota_pet/domain/repositories/cep_repository.dart';
import 'package:adota_pet/domain/repositories/users_repository.dart';

typedef SenhaForca = ({String label, double progress, Color color});

class RegisterProtetorOngViewModel extends ChangeNotifier {
  static const int maxFileSizeBytes = 5 * 1024 * 1024;
  static const int descricaoMaxLength = 1800;
  static const String tipoProtetor = 'protetor';
  static const String tipoOng = 'ong';

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final UsersRepository usersRepository;
  final CepRepository cepRepository;

  // Step
  int currentStep = 0;

  // Step 1
  String tipoUsuario = tipoProtetor;
  String nome = '';
  String email = '';
  String cpfCnpj = '';
  String telefone = '';
  String telefoneContato = '';

  // Step 2
  String cep = '';
  String logradouro = '';
  String numero = '';
  String complemento = '';
  String bairro = '';
  String cidade = '';
  String estado = '';
  String descricao = '';
  String senha = '';
  String confirmarSenha = '';
  Uint8List? imagemBytes;
  String? imagemFilename;
  Uint8List? documentoBytes;
  String? documentoFilename;
  bool aceitaTermos = false;
  bool aceitaPrivacidade = false;

  // State
  bool isLoading = false;
  bool isCepLoading = false;
  bool sent = false;
  String? error;
  Map<String, String> fieldErrors = {};

  RegisterProtetorOngViewModel({
    required this.usersRepository,
    required this.cepRepository,
  });

  // ===== Setters =====

  void setTipoUsuario(String value) {
    if (value != tipoProtetor && value != tipoOng) return;
    if (value == tipoUsuario) return;
    tipoUsuario = value;
    cpfCnpj = '';
    fieldErrors.remove('cpfCnpj');
    notifyListeners();
  }

  void setNome(String v) => _setField('nome', v, (x) => nome = x);
  void setEmail(String v) => _setField('email', v, (x) => email = x.trim());
  void setCpfCnpj(String v) => _setField('cpfCnpj', v, (x) => cpfCnpj = x);
  void setTelefone(String v) => _setField('telefone', v, (x) => telefone = x);
  void setTelefoneContato(String v) =>
      _setField('telefoneContato', v, (x) => telefoneContato = x);

  void setCep(String v) {
    cep = v;
    fieldErrors.remove('cep');
  }

  void setLogradouro(String v) =>
      _setField('logradouro', v, (x) => logradouro = x);
  void setNumero(String v) => _setField('numero', v, (x) => numero = x);
  void setComplemento(String v) =>
      _setField('complemento', v, (x) => complemento = x);
  void setBairro(String v) => _setField('bairro', v, (x) => bairro = x);
  void setCidade(String v) => _setField('cidade', v, (x) => cidade = x);

  void setEstado(String v) {
    estado = v.toUpperCase();
    fieldErrors.remove('estado');
  }

  void setDescricao(String v) {
    descricao = v;
    fieldErrors.remove('descricao');
    notifyListeners();
  }

  void setSenha(String v) {
    senha = v;
    fieldErrors.remove('senha');
    notifyListeners();
  }

  void setConfirmarSenha(String v) {
    confirmarSenha = v;
    fieldErrors.remove('confirmarSenha');
  }

  void setImagem(Uint8List? bytes, String? filename) {
    imagemBytes = bytes;
    imagemFilename = filename;
    fieldErrors.remove('imagem');
    notifyListeners();
  }

  void setDocumento(Uint8List? bytes, String? filename) {
    documentoBytes = bytes;
    documentoFilename = filename;
    fieldErrors.remove('documento');
    notifyListeners();
  }

  void setAceitaTermos(bool v) {
    aceitaTermos = v;
    error = null;
    notifyListeners();
  }

  void setAceitaPrivacidade(bool v) {
    aceitaPrivacidade = v;
    error = null;
    notifyListeners();
  }

  void _setField(String key, String value, void Function(String) apply) {
    apply(value);
    fieldErrors.remove(key);
  }

  // ===== Indicador de força da senha =====

  SenhaForca get senhaForca {
    if (senha.isEmpty) {
      return (label: '', progress: 0, color: AppTheme.mutedForeground);
    }
    final hasUpper = senha.contains(RegExp(r'[A-Z]'));
    final hasDigit = senha.contains(RegExp(r'\d'));
    if (senha.length < 6) {
      return (label: 'Fraca', progress: 0.33, color: AppTheme.destructive);
    }
    if (senha.length >= 8 && hasUpper && hasDigit) {
      return (label: 'Forte', progress: 1.0, color: AppTheme.sage);
    }
    return (label: 'Média', progress: 0.66, color: AppTheme.accent);
  }

  // ===== ViaCEP =====

  Future<void> consultarCep() async {
    final clean = cep.replaceAll(RegExp(r'\D'), '');
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

  // ===== Validação =====

  bool validateStep1() {
    final errors = <String, String>{};

    if (nome.trim().length < 2) {
      errors['nome'] = 'Informe o nome completo.';
    }
    if (email.trim().isEmpty || !_emailRegex.hasMatch(email.trim())) {
      errors['email'] = 'Informe um email válido.';
    }

    final digitsCpfCnpj = cpfCnpj.replaceAll(RegExp(r'\D'), '');
    if (tipoUsuario == tipoProtetor) {
      if (digitsCpfCnpj.length != 11 || !CPFValidator.isValid(digitsCpfCnpj)) {
        errors['cpfCnpj'] = 'CPF inválido.';
      }
    } else {
      if (digitsCpfCnpj.length != 14 || !CNPJValidator.isValid(digitsCpfCnpj)) {
        errors['cpfCnpj'] = 'CNPJ inválido.';
      }
    }

    final digitsTelefone = telefone.replaceAll(RegExp(r'\D'), '');
    if (digitsTelefone.isNotEmpty &&
        digitsTelefone.length != 10 &&
        digitsTelefone.length != 11) {
      errors['telefone'] = 'Telefone inválido.';
    }
    final digitsContato = telefoneContato.replaceAll(RegExp(r'\D'), '');
    if (digitsContato.isNotEmpty &&
        digitsContato.length != 10 &&
        digitsContato.length != 11) {
      errors['telefoneContato'] = 'Telefone inválido.';
    }

    fieldErrors = errors;
    error = null;
    notifyListeners();
    return errors.isEmpty;
  }

  bool validateStep2() {
    final errors = <String, String>{};
    String? banner;

    final cleanCep = cep.replaceAll(RegExp(r'\D'), '');
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

    if (senha.length < 8) {
      errors['senha'] = 'Senha precisa de pelo menos 8 caracteres.';
    } else if (senha.length > 72) {
      errors['senha'] = 'Senha não pode passar de 72 caracteres.';
    }
    if (errors['senha'] == null && senha != confirmarSenha) {
      errors['confirmarSenha'] = 'As senhas não conferem.';
    }

    if (documentoBytes == null) {
      errors['documento'] = 'Envie o documento comprobatório.';
    } else if (documentoBytes!.lengthInBytes > maxFileSizeBytes) {
      errors['documento'] = 'Documento muito grande. Limite: 5MB.';
    }

    if (imagemBytes != null && imagemBytes!.lengthInBytes > maxFileSizeBytes) {
      errors['imagem'] = 'Imagem muito grande. Limite: 5MB.';
    }

    if (!aceitaTermos || !aceitaPrivacidade) {
      banner = 'Você precisa aceitar os termos para continuar.';
    }

    fieldErrors = errors;
    error = banner;
    notifyListeners();
    return errors.isEmpty && banner == null;
  }

  // ===== Steps =====

  bool nextStep() {
    if (currentStep != 0) return true;
    if (!validateStep1()) return false;
    currentStep = 1;
    notifyListeners();
    return true;
  }

  void prevStep() {
    if (currentStep == 0) return;
    currentStep = 0;
    error = null;
    notifyListeners();
  }

  // ===== Submit =====

  Future<bool> submit() async {
    if (!validateStep2()) return false;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final telefoneDigits = telefone.replaceAll(RegExp(r'\D'), '');
      final telefoneContatoDigits = telefoneContato.replaceAll(
        RegExp(r'\D'),
        '',
      );

      final params = CriarProtetorOngParams(
        nome: nome.trim(),
        email: email.trim().toLowerCase(),
        senha: senha,
        tipoUsuario: tipoUsuario,
        cpfCnpj: cpfCnpj.replaceAll(RegExp(r'\D'), ''),
        documentoBytes: documentoBytes!,
        documentoFilename: documentoFilename ?? 'documento.pdf',
        endereco: Endereco(
          logradouro: logradouro.trim(),
          numero: numero.trim(),
          complemento: complemento.trim().isEmpty ? null : complemento.trim(),
          bairro: bairro.trim(),
          cidade: cidade.trim(),
          estado: estado.trim().toUpperCase(),
          cep: cep.replaceAll(RegExp(r'\D'), ''),
        ),
        telefone: telefoneDigits.isEmpty ? null : telefoneDigits,
        telefoneContato: telefoneContatoDigits.isEmpty
            ? null
            : telefoneContatoDigits,
        descricao: descricao.trim().isEmpty ? null : descricao.trim(),
        imagemBytes: imagemBytes,
      );

      await usersRepository.criarProtetorOng(params);

      isLoading = false;
      sent = true;
      notifyListeners();
      return true;
    } on Failure catch (f) {
      _setError(f);
      // Se o conflito é em campo do step 1 (email/cpfCnpj), volta o usuário pra lá.
      if (f.field == 'email' || f.field == 'cpfCnpj') {
        currentStep = 0;
        notifyListeners();
      }
      return false;
    } catch (_) {
      _setError(Failure('Não foi possível concluir o cadastro.'));
      return false;
    }
  }

  void clearError() {
    if (error == null && fieldErrors.isEmpty) return;
    error = null;
    fieldErrors = {};
    notifyListeners();
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
    notifyListeners();
  }
}
