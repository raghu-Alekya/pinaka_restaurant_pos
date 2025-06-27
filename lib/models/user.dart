// models/user.dart

class User {
  final String pin;
  final String token;
  final String restaurantId;
  final String restaurantName;

  User({
    required this.pin,
    required this.token,
    required this.restaurantId,
    required this.restaurantName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      pin: json['pin'] ?? '',
      token: json['token'] ?? '',
      restaurantId: json['restaurant_id'] ?? '',
      restaurantName: json['restaurant_name'] ?? '',
    );
  }
}
