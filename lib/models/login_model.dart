class LoginModel {
  final bool success;
  final String message;
  final LoginData data;

  LoginModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: LoginData.fromJson(json["data"] ?? {}),
    );
  }
}

class LoginData {
  final String token;
  final int id;
  final String email;
  final String displayName;
  final String role;
  final int restaurantId;
  final String restaurantName;
  final Permissions permissions;

  LoginData({
    required this.token,
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.restaurantId,
    required this.restaurantName,
    required this.permissions,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      token: json["token"] ?? "",
      id: json["id"] ?? 0,
      email: json["email"] ?? "",
      displayName: json["displayName"] ?? "",
      role: json["role"] ?? "",
      restaurantId: json["restaurant_id"] ?? 0,
      restaurantName: json["restaurant_name"] ?? "",
      permissions: Permissions.fromJson(
        json["permissions"] ?? {},
      ), // <-- Add this
    );
  }
}
class LogoutResponse {
  final bool success;
  final String message;

  LogoutResponse({
    required this.success,
    required this.message,
  });

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "message": message,
    };
  }
}
class Permissions {
  final bool canViewKDS;

  Permissions({
    required this.canViewKDS,
  });

  factory Permissions.fromJson(Map<String, dynamic> json) {
    return Permissions(
      canViewKDS: json["canViewKDS"] ?? false,
    );
  }
}