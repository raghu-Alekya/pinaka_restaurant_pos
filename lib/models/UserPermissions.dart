class UserPermissions {
  final bool canAccessDashboard;
  final bool canViewMenu;
  final bool canEditMenu;
  final bool canSetupTables;
  final bool canEditTables;
  final bool canDeleteTables;
  final bool canDoubleTap;
  final bool canViewTables;
  final String canDefaultLayout;
  final bool canViewOrderPanel;
  final bool canEditOrder;
  final bool canDeleteOrder;
  final bool canViewKOTStatus;
  final bool canEditKOTStatus;
  final bool canDeleteKOTStatus;
  final bool canUpdateKOTStatus;
  final bool canViewInventory;
  final bool canUpdateInventory;
  final bool canAccessSettings;
  final bool canUpdateShiftAttendance;
  final String displayName;
  final String role;

  UserPermissions({
    required this.canAccessDashboard,
    required this.canViewMenu,
    required this.canEditMenu,
    required this.canSetupTables,
    required this.canEditTables,
    required this.canDeleteTables,
    required this.canDoubleTap,
    required this.canViewTables,
    required this.canDefaultLayout,
    required this.canViewOrderPanel,
    required this.canEditOrder,
    required this.canDeleteOrder,
    required this.canViewKOTStatus,
    required this.canEditKOTStatus,
    required this.canDeleteKOTStatus,
    required this.canUpdateKOTStatus,
    required this.canViewInventory,
    required this.canUpdateInventory,
    required this.canAccessSettings,
    required this.canUpdateShiftAttendance,
    required this.displayName,
    required this.role,
  });

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions(
      canAccessDashboard: json['canAccessDashboard'] ?? false,
      canViewMenu: json['canViewMenu'] ?? false,
      canEditMenu: json['canEditMenu'] ?? false,
      canSetupTables: json['canSetupTables'] ?? false,
      canEditTables: json['canEditTables'] ?? false,
      canDeleteTables: json['canDeleteTables'] ?? false,
      canDoubleTap: json['canDoubleTap'] ?? false,
      canViewTables: json['canViewTables'] ?? false,
      canDefaultLayout: json['canDefaultLayout'] ?? "gridCommonImage",
      canViewOrderPanel: json['canViewOrderPanel'] ?? false,
      canEditOrder: json['canEditOrder'] ?? false,
      canDeleteOrder: json['canDeleteOrder'] ?? false,
      canViewKOTStatus: json['canViewKOTStatus'] ?? false,
      canEditKOTStatus: json['canEditKOTStatus'] ?? false,
      canDeleteKOTStatus: json['canDeleteKOTStatus'] ?? false,
      canUpdateKOTStatus: json['canUpdateKOTStatus'] ?? false,
      canViewInventory: json['canViewInventory'] ?? false,
      canUpdateInventory: json['canUpdateInventory'] ?? false,
      canAccessSettings: json['canAccessSettings'] ?? false,
      canUpdateShiftAttendance: json['canUpdateShiftAttendance'] ?? false,
      displayName: json['displayName'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canAccessDashboard': canAccessDashboard,
      'canViewMenu': canViewMenu,
      'canEditMenu': canEditMenu,
      'canSetupTables': canSetupTables,
      'canEditTables': canEditTables,
      'canDeleteTables': canDeleteTables,
      'canDoubleTap': canDoubleTap,
      'canViewTables': canViewTables,
      'canDefaultLayout': canDefaultLayout,
      'canViewOrderPanel': canViewOrderPanel,
      'canEditOrder': canEditOrder,
      'canDeleteOrder': canDeleteOrder,
      'canViewKOTStatus': canViewKOTStatus,
      'canEditKOTStatus': canEditKOTStatus,
      'canDeleteKOTStatus': canDeleteKOTStatus,
      'canUpdateKOTStatus': canUpdateKOTStatus,
      'canViewInventory': canViewInventory,
      'canUpdateInventory': canUpdateInventory,
      'canAccessSettings': canAccessSettings,
      'canUpdateShiftAttendance': canUpdateShiftAttendance,
      'displayName': displayName,
      'role': role,
    };
  }
}