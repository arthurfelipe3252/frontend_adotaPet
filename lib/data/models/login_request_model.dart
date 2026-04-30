class LoginRequestModel {
  final String email;
  final String senha;

  LoginRequestModel({required this.email, required this.senha});

  Map<String, dynamic> toJson() => {'email': email, 'senha': senha};
}
