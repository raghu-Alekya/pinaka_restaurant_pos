import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../captain_login_domain/captain_login_entity.dart';
import 'captain_local_storage.dart';

class CaptainLocalStorageImpl implements CaptainLocalStorage {
  static const String _keyCaptainData = 'captain_data';

  @override
  Future<void> saveCaptainData(CaptainLoginEntity entity) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'success': entity.success,
      'statusCode': entity.statusCode,
      'code': entity.code,
      'message': entity.message,
      'data': entity.data != null ? {
        'token': entity.data!.token,
        'id': entity.data!.id,
        'email': entity.data!.email,
        'nicename': entity.data!.nicename,
        'firstName': entity.data!.firstName,
        'lastName': entity.data!.lastName,
        'displayName': entity.data!.displayName,
        'currencySymbol': entity.data!.currencySymbol,
        'role': entity.data!.role,
        'restaurantId': entity.data!.restaurantId,
        'restaurantName': entity.data!.restaurantName,
        'avatar': entity.data!.avatar,
        'printSettings': entity.data!.printSettings,
        'permissions': entity.data!.permissions != null ? {
          'canAccessDashboard': entity.data!.permissions!.canAccessDashboard,
          'canViewMenu': entity.data!.permissions!.canViewMenu,
          'canEditMenu': entity.data!.permissions!.canEditMenu,
          'canSetupTables': entity.data!.permissions!.canSetupTables,
          'canEditTables': entity.data!.permissions!.canEditTables,
          'canDeleteTables': entity.data!.permissions!.canDeleteTables,
          'canDoubleTap': entity.data!.permissions!.canDoubleTap,
          'canCreateShiftAttendance': entity.data!.permissions!.canCreateShiftAttendance,
          'canUpdateShiftAttendance': entity.data!.permissions!.canUpdateShiftAttendance,
          'canViewTables': entity.data!.permissions!.canViewTables,
          'canCreateReservation': entity.data!.permissions!.canCreateReservation,
          'canDefaultLayout': entity.data!.permissions!.canDefaultLayout,
          'canViewOrderPanel': entity.data!.permissions!.canViewOrderPanel,
          'canEditOrder': entity.data!.permissions!.canEditOrder,
          'canViewOrderTypes': entity.data!.permissions!.canViewOrderTypes,
          'canDeleteOrder': entity.data!.permissions!.canDeleteOrder,
          'canViewKOTStatus': entity.data!.permissions!.canViewKOTStatus,
          'canEditKOTStatus': entity.data!.permissions!.canEditKOTStatus,
          'canDeleteKOTStatus': entity.data!.permissions!.canDeleteKOTStatus,
          'canUpdateKOTStatus': entity.data!.permissions!.canUpdateKOTStatus,
          'canViewInventory': entity.data!.permissions!.canViewInventory,
          'canUpdateInventory': entity.data!.permissions!.canUpdateInventory,
          'canViewVendors': entity.data!.permissions!.canViewVendors,
          'canViewTips': entity.data!.permissions!.canViewTips,
          'canViewKDS': entity.data!.permissions!.canViewKDS,
          'canAccessSettings': entity.data!.permissions!.canAccessSettings,
        } : null,
      } : null,
    };
    final json = jsonEncode(map);
    await prefs.setString(_keyCaptainData, json);
  }

  @override
  Future<CaptainLoginEntity?> getCaptainData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyCaptainData);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return CaptainLoginEntity(
        success: map['success'] ?? false,
        statusCode: map['statusCode'],
        code: map['code'],
        message: map['message'],
        data: map['data'] != null ? CaptainData(
          token: map['data']['token'],
          id: map['data']['id'],
          email: map['data']['email'],
          nicename: map['data']['nicename'],
          firstName: map['data']['firstName'],
          lastName: map['data']['lastName'],
          displayName: map['data']['displayName'],
          currencySymbol: map['data']['currencySymbol'],
          role: map['data']['role'],
          restaurantId: map['data']['restaurantId'],
          restaurantName: map['data']['restaurantName'],
          avatar: map['data']['avatar'],
          printSettings: map['data']['printSettings'] is List
              ? List<String>.from(map['data']['printSettings'])
              : null,
          permissions: map['data']['permissions'] != null ? CaptainPermissions(
            canAccessDashboard: map['data']['permissions']['canAccessDashboard'],
            canViewMenu: map['data']['permissions']['canViewMenu'],
            canEditMenu: map['data']['permissions']['canEditMenu'],
            canSetupTables: map['data']['permissions']['canSetupTables'],
            canEditTables: map['data']['permissions']['canEditTables'],
            canDeleteTables: map['data']['permissions']['canDeleteTables'],
            canDoubleTap: map['data']['permissions']['canDoubleTap'],
            canCreateShiftAttendance: map['data']['permissions']['canCreateShiftAttendance'],
            canUpdateShiftAttendance: map['data']['permissions']['canUpdateShiftAttendance'],
            canViewTables: map['data']['permissions']['canViewTables'],
            canCreateReservation: map['data']['permissions']['canCreateReservation'],
            canDefaultLayout: map['data']['permissions']['canDefaultLayout'],
            canViewOrderPanel: map['data']['permissions']['canViewOrderPanel'],
            canEditOrder: map['data']['permissions']['canEditOrder'],
            canViewOrderTypes: map['data']['permissions']['canViewOrderTypes'],
            canDeleteOrder: map['data']['permissions']['canDeleteOrder'],
            canViewKOTStatus: map['data']['permissions']['canViewKOTStatus'],
            canEditKOTStatus: map['data']['permissions']['canEditKOTStatus'],
            canDeleteKOTStatus: map['data']['permissions']['canDeleteKOTStatus'],
            canUpdateKOTStatus: map['data']['permissions']['canUpdateKOTStatus'],
            canViewInventory: map['data']['permissions']['canViewInventory'],
            canUpdateInventory: map['data']['permissions']['canUpdateInventory'],
            canViewVendors: map['data']['permissions']['canViewVendors'],
            canViewTips: map['data']['permissions']['canViewTips'],
            canViewKDS: map['data']['permissions']['canViewKDS'],
            canAccessSettings: map['data']['permissions']['canAccessSettings'],
          ) : null,
        ) : null,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearCaptainData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCaptainData);
  }

  @override
  Future<String?> getToken() async {
    final data = await getCaptainData();
    return data?.data?.token;
  }

  @override
  Future<String?> getCurrencySymbol() async {
    final data = await getCaptainData();
    return data?.data?.currencySymbol;
  }


}