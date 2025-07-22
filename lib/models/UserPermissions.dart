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

  factory UserPermissions.fullAccess() {
    return UserPermissions(
      canAccessDashboard: true,
      canViewMenu: true,
      canEditMenu: true,
      canSetupTables: true,
      canEditTables: true,
      canDeleteTables: true,
      canDoubleTap: true,
      canViewTables: true,
      canDefaultLayout: "normal",
      canViewOrderPanel: true,
      canEditOrder: true,
      canDeleteOrder: true,
      canViewKOTStatus: true,
      canEditKOTStatus: true,
      canDeleteKOTStatus: true,
      canUpdateKOTStatus: true,
      canViewInventory: true,
      canUpdateInventory: true,
      canAccessSettings: true,
    );
  }


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
      canDefaultLayout: json['canDefaultLayout'] ?? "normal",
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
    );
  }
}
