enum UserRole { HOST, VIEWER }

class UserModel {
  final String name;
  final UserRole role;

  UserModel({required this.name, required this.role});

  bool get isHost => role == UserRole.HOST;
}
