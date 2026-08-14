

import '../captain_login_domain/captain_login_entity.dart';

class CaptainLoginResponse {
  final bool success;
  final int? statusCode;
  final String? code;
  final String? message;
  final CaptainDataModel? data;

  CaptainLoginResponse({
    required this.success,
    this.statusCode,
    this.code,
    this.message,
    this.data,
  });

  factory CaptainLoginResponse.fromJson(Map<String, dynamic> json) {
    return CaptainLoginResponse(
      success: json['success'] ?? false,
      statusCode: json['statusCode'],
      code: json['code'],
      message: json['message'],
      data: json['data'] != null
          ? CaptainDataModel.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'statusCode': statusCode,
    'code': code,
    'message': message,
    'data': data?.toJson(),
  };

  CaptainLoginEntity toEntity() => CaptainLoginEntity(
    success: success,
    statusCode: statusCode,
    code: code,
    message: message,
    data: data?.toEntity(),
  );
}

class CaptainDataModel {
  final String? token;
  final int? id;
  final String? email;
  final String? nicename;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? currencySymbol;
  final String? role;
  final int? restaurantId;
  final String? restaurantName;
  final String? avatar;
  final CaptainPermissionsModel? permissions;

  CaptainDataModel({
    this.token,
    this.id,
    this.email,
    this.nicename,
    this.firstName,
    this.lastName,
    this.displayName,
    this.currencySymbol,
    this.role,
    this.restaurantId,
    this.restaurantName,
    this.avatar,
    this.permissions,
  });

  factory CaptainDataModel.fromJson(Map<String, dynamic> json) {
    return CaptainDataModel(
      token: json['token'],
      id: json['id'],
      email: json['email'],
      nicename: json['nicename'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      displayName: json['displayName'],
      currencySymbol: json['currency_symbol'],
      role: json['role'],
      restaurantId: json['restaurant_id'],
      restaurantName: json['restaurant_name'],
      avatar: json['avatar'],
      permissions: json['permissions'] != null
          ? CaptainPermissionsModel.fromJson(json['permissions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'id': id,
    'email': email,
    'nicename': nicename,
    'firstName': firstName,
    'lastName': lastName,
    'displayName': displayName,
    'currency_symbol': currencySymbol,
    'role': role,
    'restaurant_id': restaurantId,
    'restaurant_name': restaurantName,
    'avatar': avatar,
    'permissions': permissions?.toJson(),
  };

  CaptainData toEntity() => CaptainData(
    token: token,
    id: id,
    email: email,
    nicename: nicename,
    firstName: firstName,
    lastName: lastName,
    displayName: displayName,
    currencySymbol: currencySymbol,
    role: role,
    restaurantId: restaurantId,
    restaurantName: restaurantName,
    avatar: avatar,
    permissions: permissions?.toEntity(),
  );
}

class CaptainPermissionsModel {
  final bool? canAccessDashboard;
  final bool? canViewMenu;
  final bool? canEditMenu;
  final bool? canSetupTables;
  final bool? canEditTables;
  final bool? canDeleteTables;
  final bool? canDoubleTap;
  final bool? canCreateShiftAttendance;
  final bool? canUpdateShiftAttendance;
  final bool? canViewTables;
  final bool? canCreateReservation;
  final String? canDefaultLayout;
  final bool? canViewOrderPanel;
  final bool? canEditOrder;
  final bool? canViewOrderTypes;
  final bool? canDeleteOrder;
  final bool? canViewKOTStatus;
  final bool? canEditKOTStatus;
  final bool? canDeleteKOTStatus;
  final bool? canUpdateKOTStatus;
  final bool? canViewInventory;
  final bool? canUpdateInventory;
  final bool? canViewVendors;
  final bool? canViewTips;
  final bool? canViewKDS;
  final bool? canAccessSettings;

  CaptainPermissionsModel({
    this.canAccessDashboard,
    this.canViewMenu,
    this.canEditMenu,
    this.canSetupTables,
    this.canEditTables,
    this.canDeleteTables,
    this.canDoubleTap,
    this.canCreateShiftAttendance,
    this.canUpdateShiftAttendance,
    this.canViewTables,
    this.canCreateReservation,
    this.canDefaultLayout,
    this.canViewOrderPanel,
    this.canEditOrder,
    this.canViewOrderTypes,
    this.canDeleteOrder,
    this.canViewKOTStatus,
    this.canEditKOTStatus,
    this.canDeleteKOTStatus,
    this.canUpdateKOTStatus,
    this.canViewInventory,
    this.canUpdateInventory,
    this.canViewVendors,
    this.canViewTips,
    this.canViewKDS,
    this.canAccessSettings,
  });

  factory CaptainPermissionsModel.fromJson(Map<String, dynamic> json) {
    return CaptainPermissionsModel(
      canAccessDashboard: json['canAccessDashboard'],
      canViewMenu: json['canViewMenu'],
      canEditMenu: json['canEditMenu'],
      canSetupTables: json['canSetupTables'],
      canEditTables: json['canEditTables'],
      canDeleteTables: json['canDeleteTables'],
      canDoubleTap: json['canDoubleTap'],
      canCreateShiftAttendance: json['canCreateShiftAttendance'],
      canUpdateShiftAttendance: json['canUpdateShiftAttendance'],
      canViewTables: json['canViewTables'],
      canCreateReservation: json['canCreateReservation'],
      canDefaultLayout: json['canDefaultLayout'],
      canViewOrderPanel: json['canViewOrderPanel'],
      canEditOrder: json['canEditOrder'],
      canViewOrderTypes: json['canViewOrderTypes'],
      canDeleteOrder: json['canDeleteOrder'],
      canViewKOTStatus: json['canViewKOTStatus'],
      canEditKOTStatus: json['canEditKOTStatus'],
      canDeleteKOTStatus: json['canDeleteKOTStatus'],
      canUpdateKOTStatus: json['canUpdateKOTStatus'],
      canViewInventory: json['canViewInventory'],
      canUpdateInventory: json['canUpdateInventory'],
      canViewVendors: json['canViewVendors'],
      canViewTips: json['canViewTips'],
      canViewKDS: json['canViewKDS'],
      canAccessSettings: json['canAccessSettings'],
    );
  }

  Map<String, dynamic> toJson() => {
    'canAccessDashboard': canAccessDashboard,
    'canViewMenu': canViewMenu,
    'canEditMenu': canEditMenu,
    'canSetupTables': canSetupTables,
    'canEditTables': canEditTables,
    'canDeleteTables': canDeleteTables,
    'canDoubleTap': canDoubleTap,
    'canCreateShiftAttendance': canCreateShiftAttendance,
    'canUpdateShiftAttendance': canUpdateShiftAttendance,
    'canViewTables': canViewTables,
    'canCreateReservation': canCreateReservation,
    'canDefaultLayout': canDefaultLayout,
    'canViewOrderPanel': canViewOrderPanel,
    'canEditOrder': canEditOrder,
    'canViewOrderTypes': canViewOrderTypes,
    'canDeleteOrder': canDeleteOrder,
    'canViewKOTStatus': canViewKOTStatus,
    'canEditKOTStatus': canEditKOTStatus,
    'canDeleteKOTStatus': canDeleteKOTStatus,
    'canUpdateKOTStatus': canUpdateKOTStatus,
    'canViewInventory': canViewInventory,
    'canUpdateInventory': canUpdateInventory,
    'canViewVendors': canViewVendors,
    'canViewTips': canViewTips,
    'canViewKDS': canViewKDS,
    'canAccessSettings': canAccessSettings,
  };

  CaptainPermissions toEntity() => CaptainPermissions(
    canAccessDashboard: canAccessDashboard,
    canViewMenu: canViewMenu,
    canEditMenu: canEditMenu,
    canSetupTables: canSetupTables,
    canEditTables: canEditTables,
    canDeleteTables: canDeleteTables,
    canDoubleTap: canDoubleTap,
    canCreateShiftAttendance: canCreateShiftAttendance,
    canUpdateShiftAttendance: canUpdateShiftAttendance,
    canViewTables: canViewTables,
    canCreateReservation: canCreateReservation,
    canDefaultLayout: canDefaultLayout,
    canViewOrderPanel: canViewOrderPanel,
    canEditOrder: canEditOrder,
    canViewOrderTypes: canViewOrderTypes,
    canDeleteOrder: canDeleteOrder,
    canViewKOTStatus: canViewKOTStatus,
    canEditKOTStatus: canEditKOTStatus,
    canDeleteKOTStatus: canDeleteKOTStatus,
    canUpdateKOTStatus: canUpdateKOTStatus,
    canViewInventory: canViewInventory,
    canUpdateInventory: canUpdateInventory,
    canViewVendors: canViewVendors,
    canViewTips: canViewTips,
    canViewKDS: canViewKDS,
    canAccessSettings: canAccessSettings,
  );
}