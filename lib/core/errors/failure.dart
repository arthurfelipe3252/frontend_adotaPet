class Failure implements Exception {
  final String message;
  final String? field;

  Failure(this.message, {this.field});

  @override
  String toString() =>
      'Failure: $message${field != null ? ' (field: $field)' : ''}';
}

/// Sentinel para HTTP 409 — usado para o repository diferenciar
/// "email já cadastrado" vs "cpf/cnpj já cadastrado" pela mensagem.
class ConflictFailure extends Failure {
  ConflictFailure(super.message);
}
