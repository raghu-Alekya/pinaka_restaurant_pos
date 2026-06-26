class MerchantLoginResponse {
  final bool success;
  final String message;
  final int userId;
  final String username;
  final String email;
  final String storeId;
  final String subscriptionType;
  final String storeInfo;
  final String storeName;
  final String expirationDate;
  final List<dynamic> deviceImeis;
  final String storeBaseUrl;
  final String storeAddress;
  final String storePhone;
  final String licenseKey;
  final String licenseStatus;
  final String storeLogo;
  final String storeGstin;

  MerchantLoginResponse({
    required this.success,
    required this.message,
    required this.userId,
    required this.username,
    required this.email,
    required this.storeId,
    required this.subscriptionType,
    required this.storeInfo,
    required this.storeName,
    required this.expirationDate,
    required this.deviceImeis,
    required this.storeBaseUrl,
    required this.storeAddress,
    required this.storePhone,
    required this.licenseKey,
    required this.licenseStatus,
    required this.storeLogo,
    required this.storeGstin,
  });

  factory MerchantLoginResponse.fromJson(
      Map<String, dynamic> json) {
    return MerchantLoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      storeId: json['store_id'] ?? '',
      subscriptionType: json['subscription_type'] ?? '',
      storeInfo: json['store_info'] ?? '',
      storeName: json['store_name'] ?? '',
      expirationDate: json['expiration_date'] ?? '',
      deviceImeis: json['device_imeis'] ?? [],
      storeBaseUrl: json['store_base_url'] ?? '',
      storeAddress: json['store_address'] ?? '',
      storeGstin: json['store_gstin'] ?? '',
      storePhone: json['store_phone'] ?? '',
      licenseKey: json['license_key'] ?? '',
      licenseStatus: json['license_status'] ?? '',
      storeLogo: json['store_logo'] ?? '',
    );
  }
}