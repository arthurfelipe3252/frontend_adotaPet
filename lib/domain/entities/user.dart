enum UserType { ngo, donor }

class User {
  final String id;
  final String name;
  final String email;
  final UserType type;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
  });
}
