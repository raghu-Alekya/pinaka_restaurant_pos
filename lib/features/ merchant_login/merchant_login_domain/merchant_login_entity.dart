class MerchantLoginEntity {
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

  MerchantLoginEntity({
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
}