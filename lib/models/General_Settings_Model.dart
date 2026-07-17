class GeneralSettingsModel {
  final bool success;
  final GeneralSettingsData data;

  GeneralSettingsModel({
    required this.success,
    required this.data,
  });

  factory GeneralSettingsModel.fromJson(Map<String, dynamic> json) {
    return GeneralSettingsModel(
      success: json['success'] ?? false,
      data: GeneralSettingsData.fromJson(json['data'] ?? {}),
    );
  }
}

class GeneralSettingsData {
  final int userId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? userDeviceId;
  final bool gstin;
  final String companyName;
  final String profileUrl;
  final bool headerText;
  final bool footerText;
  final bool printSettings;
  final String receiptLogo;

  GeneralSettingsData({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.userDeviceId,
    required this.gstin,
    required this.companyName,
    required this.profileUrl,
    required this.headerText,
    required this.footerText,
    required this.printSettings,
    required this.receiptLogo,
  });

  factory GeneralSettingsData.fromJson(Map<String, dynamic> json) {
    return GeneralSettingsData(
      userId: json['user_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      userDeviceId: json['user_device_id'],
      gstin: json['gstin'] ?? false,
      companyName: json['company_name'] ?? '',
      profileUrl: json['profile_url'] ?? '',
      headerText: json['header_text'] ?? false,
      footerText: json['footer_text'] ?? false,
      printSettings: json['print_settings'] ?? false,
      receiptLogo: json['receipt_logo'] ?? '',
    );
  }
}
class SaveGeneralSettingsRequest {
  final String? headerText;
  final String? footerText;
  final String? printSettings;
  final String? receiptLogoUrl;

  SaveGeneralSettingsRequest({
    this.headerText,
    this.footerText,
    this.printSettings,
    this.receiptLogoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      "header_text": headerText,
      "footer_text": footerText,
      "print_settings": printSettings,
      "receipt_logo_url": receiptLogoUrl,
    };
  }
}
class SaveGeneralSettingsResponse {
  final bool success;
  final String message;
  final SaveGeneralSettingsData data;

  SaveGeneralSettingsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SaveGeneralSettingsResponse.fromJson(
      Map<String, dynamic> json) {
    return SaveGeneralSettingsResponse(
      success: json["success"],
      message: json["message"] ?? "",
      data: SaveGeneralSettingsData.fromJson(json["data"]),
    );
  }
}

class SaveGeneralSettingsData {
  final int userId;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? userDeviceId;
  final dynamic gstin;
  final String? companyName;
  final String? profileUrl;
  final String? headerText;
  final String? footerText;
  final String? printSettings;
  final String? receiptLogo;

  SaveGeneralSettingsData({
    required this.userId,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.userDeviceId,
    this.gstin,
    this.companyName,
    this.profileUrl,
    this.headerText,
    this.footerText,
    this.printSettings,
    this.receiptLogo,
  });

  factory SaveGeneralSettingsData.fromJson(
      Map<String, dynamic> json) {
    return SaveGeneralSettingsData(
      userId: json["user_id"] ?? 0,
      fullName: json["full_name"],
      email: json["email"],
      phoneNumber: json["phone_number"],
      userDeviceId: json["user_device_id"],
      gstin: json["gstin"],
      companyName: json["company_name"],
      profileUrl: json["profile_url"],
      headerText: json["header_text"],
      footerText: json["footer_text"],
      printSettings: json["print_settings"],
      receiptLogo: json["receipt_logo"],
    );
  }
}