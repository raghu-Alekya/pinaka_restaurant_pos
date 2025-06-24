// models/user.dart

class User {
  final String pin;
  final String token;

  User({required this.pin, required this.token});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      pin: json['pin'] ?? '',
      token: json['token'] ?? '',
    );
  }
}
