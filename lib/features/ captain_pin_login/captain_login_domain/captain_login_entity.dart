class CaptainLoginEntity {
  final bool success;
  final int? statusCode;
  final String? code;
  final String? message;
  final CaptainData? data;

  CaptainLoginEntity({
    required this.success,
    this.statusCode,
    this.code,
    this.message,
    this.data,
  });
}

class CaptainData {
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
  final CaptainPermissions? permissions;
  final List<String>? printSettings; // 👈 new

  CaptainData({
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
    this.printSettings,
  });
}

class CaptainPermissions {
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

  CaptainPermissions({
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
}