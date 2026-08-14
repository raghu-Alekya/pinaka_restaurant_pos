import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../merchant_login_domain/merchant_login_entity.dart';
import 'merchant_local_storage.dart';

class MerchantLocalStorageImpl implements MerchantLocalStorage {
  static const String _keyMerchantData = 'merchant_data';

  @override
  Future<void> saveMerchantData(MerchantLoginEntity entity) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'success': entity.success,
      'message': entity.message,
      'userId': entity.userId,
      'username': entity.username,
      'email': entity.email,
      'storeId': entity.storeId,
      'subscriptionType': entity.subscriptionType,
      'storeInfo': entity.storeInfo,
      'storeName': entity.storeName,
      'expirationDate': entity.expirationDate,
      'deviceImeis': entity.deviceImeis,
      'storeBaseUrl': entity.storeBaseUrl,
      'storeAddress': entity.storeAddress,
      'storeGstin': entity.storeGstin,
      'storePhone': entity.storePhone,
      'licenseKey': entity.licenseKey,
      'licenseStatus': entity.licenseStatus,
      'storeLogo': entity.storeLogo,
    };
    final json = jsonEncode(map);
    await prefs.setString(_keyMerchantData, json);
  }

  @override
  Future<MerchantLoginEntity?> getMerchantData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyMerchantData);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return MerchantLoginEntity(
        success: map['success'] ?? false,
        message: map['message'],
        userId: map['userId'],
        username: map['username'],
        email: map['email'],
        storeId: map['storeId'],
        subscriptionType: map['subscriptionType'],
        storeInfo: map['storeInfo'],
        storeName: map['storeName'],
        expirationDate: map['expirationDate'],
        deviceImeis: List<String>.from(map['deviceImeis'] ?? []),
        storeBaseUrl: map['storeBaseUrl'],
        storeAddress: map['storeAddress'],
        storeGstin: map['storeGstin'],
        storePhone: map['storePhone'],
        licenseKey: map['licenseKey'],
        licenseStatus: map['licenseStatus'],
        storeLogo: map['storeLogo'],
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearMerchantData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMerchantData);
  }

  @override
  Future<String?> getStoreBaseUrl() async {
    final data = await getMerchantData();
    return data?.storeBaseUrl;
  }
}