import '../../domain/entities/user.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String type;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'type': type};
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      type: type == 'ngo' ? UserType.ngo : UserType.donor,
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      type: user.type == UserType.ngo ? 'ngo' : 'donor',
    );
  }
}
