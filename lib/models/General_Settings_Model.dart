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
      data: GeneralSettingsData.fromJson(
        json['data'] ?? {},
      ),
    );
  }
}

class GeneralSettingsData {
  final int userId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? userDeviceId;

  // API returns string
  final String gstin;

  final String companyName;
  final String profileUrl;

  // API returns string
  final String headerText;
  final String footerText;

  // API returns array of printer names/IPs
  final List<String> printSettings;

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

  factory GeneralSettingsData.fromJson(
      Map<String, dynamic> json,
      ) {
    return GeneralSettingsData(
      userId: json['user_id'] ?? 0,

      fullName: json['full_name'] ?? '',

      email: json['email'] ?? '',

      phoneNumber: json['phone_number'],

      userDeviceId: json['user_device_id'],

      gstin: json['gstin']?.toString() ?? '',

      companyName: json['company_name'] ?? '',

      profileUrl: json['profile_url'] ?? '',

      headerText: json['header_text']?.toString() ?? '',

      footerText: json['footer_text']?.toString() ?? '',

      // IMPORTANT:
      // print_settings is an array
      printSettings: json['print_settings'] != null
          ? List<String>.from(
        (json['print_settings'] as List)
            .map((e) => e.toString()),
      )
          : [],

      receiptLogo: json['receipt_logo'] ?? '',
    );
  }
}


// ============================================================
// SAVE REQUEST
// ============================================================

class SaveGeneralSettingsRequest {
  final String? headerText;
  final String? footerText;

  // IMPORTANT:
  // This is now a List<String>, not String
  final List<String> printSettings;

  final String? receiptLogoUrl;

  SaveGeneralSettingsRequest({
    this.headerText,
    this.footerText,
    this.printSettings = const [],
    this.receiptLogoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      "header_text": headerText,
      "footer_text": footerText,

      // Send printer names/IPs as an array
      "print_settings": printSettings,

      "receipt_logo_url": receiptLogoUrl,
    };
  }
}


// ============================================================
// SAVE RESPONSE
// ============================================================

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
      Map<String, dynamic> json,
      ) {
    return SaveGeneralSettingsResponse(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: SaveGeneralSettingsData.fromJson(
        json["data"] ?? {},
      ),
    );
  }
}


// ============================================================
// SAVE RESPONSE DATA
// ============================================================

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

  // IMPORTANT:
  // Printer settings are an array
  final List<String> printSettings;

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
    required this.printSettings,
    this.receiptLogo,
  });

  factory SaveGeneralSettingsData.fromJson(
      Map<String, dynamic> json,
      ) {
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

      // IMPORTANT
      printSettings: json["print_settings"] != null
          ? List<String>.from(
        (json["print_settings"] as List)
            .map((e) => e.toString()),
      )
          : [],

      receiptLogo: json["receipt_logo"],
    );
  }
}