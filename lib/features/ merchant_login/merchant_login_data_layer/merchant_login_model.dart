import '../merchant_login_domain/merchant_login_entity.dart';

class MerchantLoginResponse {
  final bool success;
  final String? message;
  final int? userId;
  final String? username;
  final String? email;
  final String? storeId;
  final String? subscriptionType;
  final String? storeInfo;
  final String? storeName;
  final String? expirationDate;
  final List<String> deviceImeis;
  final String? storeBaseUrl;
  final String? storeAddress;
  final String? storeGstin;
  final String? storePhone;
  final String? licenseKey;
  final String? licenseStatus;
  final String? storeLogo;

  MerchantLoginResponse({
    required this.success,
    this.message,
    this.userId,
    this.username,
    this.email,
    this.storeId,
    this.subscriptionType,
    this.storeInfo,
    this.storeName,
    this.expirationDate,
    this.deviceImeis = const [],
    this.storeBaseUrl,
    this.storeAddress,
    this.storeGstin,
    this.storePhone,
    this.licenseKey,
    this.licenseStatus,
    this.storeLogo,
  });

  factory MerchantLoginResponse.fromJson(Map<String, dynamic> json) {
    return MerchantLoginResponse(
      success: json['success'] ?? false,
      message: json['message'],
      userId: json['user_id'],
      username: json['username'],
      email: json['email'],
      storeId: json['store_id'],
      subscriptionType: json['subscription_type'],
      storeInfo: json['store_info'],
      storeName: json['store_name'],
      expirationDate: json['expiration_date'],
      deviceImeis: List<String>.from(json['device_imeis'] ?? []),
      storeBaseUrl: json['store_base_url'],
      storeAddress: json['store_address'],
      storeGstin: json['store_gstin'],
      storePhone: json['store_phone'],
      licenseKey: json['license_key'],
      licenseStatus: json['license_status'],
      storeLogo: json['store_logo'],
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'user_id': userId,
    'username': username,
    'email': email,
    'store_id': storeId,
    'subscription_type': subscriptionType,
    'store_info': storeInfo,
    'store_name': storeName,
    'expiration_date': expirationDate,
    'device_imeis': deviceImeis,
    'store_base_url': storeBaseUrl,
    'store_address': storeAddress,
    'store_gstin': storeGstin,
    'store_phone': storePhone,
    'license_key': licenseKey,
    'license_status': licenseStatus,
    'store_logo': storeLogo,
  };

  // Convert to Domain Entity
  MerchantLoginEntity toEntity() => MerchantLoginEntity(
    success: success,
    message: message,
    userId: userId,
    username: username,
    email: email,
    storeId: storeId,
    subscriptionType: subscriptionType,
    storeInfo: storeInfo,
    storeName: storeName,
    expirationDate: expirationDate,
    deviceImeis: deviceImeis,
    storeBaseUrl: storeBaseUrl,
    storeAddress: storeAddress,
    storeGstin: storeGstin,
    storePhone: storePhone,
    licenseKey: licenseKey,
    licenseStatus: licenseStatus,
    storeLogo: storeLogo,
  );
}