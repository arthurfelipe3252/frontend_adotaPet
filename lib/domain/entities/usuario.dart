class Usuario {
  static const String tipoAdotante = 'adotante';
  static const String tipoProtetor = 'protetor';
  static const String tipoOng = 'ong';

  final String id;
  final String nome;
  final String email;
  final String tipoUsuario;
  final String? telefone;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipoUsuario,
    this.telefone,
  });

  bool get isAdotante => tipoUsuario == tipoAdotante;
  bool get isProtetor => tipoUsuario == tipoProtetor;
  bool get isOng => tipoUsuario == tipoOng;
  bool get isProtetorOuOng => isProtetor || isOng;
}
