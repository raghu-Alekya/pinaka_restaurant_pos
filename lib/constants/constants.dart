class AppConstants {
  static String baseDomain =
      'https://merchantrestaurant.alektasolutions.com';

  static void updateBaseUrl(String url) {
    baseDomain = url.endsWith('/')
        ? url.substring(0, url.length - 1)
        : url;
  }

  static String get baseApiPath =>
      '$baseDomain/wp-json/pinaka-restaurant-pos/v1';

  // Authentication
  static String get authTokenEndpoint =>
      '$baseApiPath/token';
  static String get getKotStatusCountEndpoint =>
      '$baseApiPath/kot/get-kot-status-count';

  static String get empOrderPinValidationEndpoint =>
      '$baseApiPath/emp-order-pin-validation';

  static String get logoutEndpoint =>
      '$baseApiPath/logout';

  // Zone Management
  static String get createZoneEndpoint =>
      '$baseApiPath/zones/create-zone';

  static String get updateZoneEndpoint =>
      '$baseApiPath/zones/update-zone';

  static String get getAllZonesEndpoint =>
      '$baseApiPath/zones/get-all-zones';

  static String get deleteZoneEndpoint =>
      '$baseApiPath/zones/delete-zone';

  // Dashboard
  static String get getChartRevenueEndpoint =>
      '$baseApiPath/merchant-dashboard/get-chart-revenue';

  static String get getPaymentModesRevenueEndpoint =>
      '$baseApiPath/merchant-dashboard/get-payment-modes-revenue';

  static String get getRevenueByFiltersEndpoint =>
      '$baseApiPath/merchant-dashboard/get-revenue-by-filters';

  static String get topProductsSoldEndpoint =>
      '$baseApiPath/merchant-dashboard/top-products-sold';

  static String get topCategoriesSoldEndpoint =>
      '$baseApiPath/merchant-dashboard/top-categories-sold';

  // Table Management
  static String get createTableEndpoint =>
      '$baseApiPath/tables/create-table';

  static String get getAllTablesEndpoint =>
      '$baseApiPath/tables/get-all-tables';

  static String get updateTableEndpoint =>
      '$baseApiPath/tables/update-table';

  static String get deleteTableEndpoint =>
      '$baseApiPath/tables/delete-table';

  static String get getAllMergeTablesEndpoint =>
      '$baseApiPath/tables/get-all-merge-tables';

  static String get createMergeTablesWithStatusEndpoint =>
      '$baseApiPath/tables/create-merge-tables-with-table-status';

  static String get updateMergeTablesWithStatusEndpoint =>
      '$baseApiPath/tables/update-merge-tables-with-table-status';

  static String get deleteMergeTablesWithStatusEndpoint =>
      '$baseApiPath/tables/delete-merge-tables-with-table-status';

  // Employee Management
  static String get getAllEmployeesEndpoint =>
      '$baseApiPath/users/get-all-employees';

  // Employee Attendance
  static String get currentShiftEmployeesEndpoint =>
      '$baseApiPath/attendance-all/current-shift';

  static String get employeeAttendanceEndpoint =>
      '$baseApiPath/attendance-all';

  static String get inventoryAlertsEndpoint =>
      '$baseApiPath/attendance-all/get-inventory-alerts';

  static String get completedOrdersEndpoint =>
      '$baseApiPath/attendance-all/get-all-completed-orders';

  // Shift Management
  static String get createShiftEndpoint =>
      '$baseApiPath/shifts/create-shift';

  static String get updateShiftEndpoint =>
      '$baseApiPath/shifts/update-shift';

  static String get closeShiftEndpoint =>
      '$baseApiPath/shifts/close-shift';

  static String get currentShiftEndpoint =>
      '$baseApiPath/shifts/current-shift';

  static String get getAllShiftsEndpoint =>
      '$baseApiPath/users/get-all-shifts';

  // Reservation Management
  static String get createReservationEndpoint =>
      '$baseApiPath/reservation/create-reservation';

  static String get getAllReservationsEndpoint =>
      '$baseApiPath/reservation/get-all-reservations';

  static String get updateReservationEndpoint =>
      '$baseApiPath/reservation/update-reservation';

  static String get cancelReservationEndpoint =>
      '$baseApiPath/reservation/cancel-reservation';

  static String get reservationDateRangeEndpoint =>
      '$baseApiPath/reservation/reservation-date-range';

  static String get getAllMergeTablesWithReservationEndpoint =>
      '$baseApiPath/tables/get-all-merge-tables-with-reservation';

  // Kitchen Status
  static String get getAllOrderTypesEndpoint =>
      '$baseApiPath/kot/get-all-order-types';

  static String get getAllUsersEndpoint =>
      '$baseApiPath/users/get-all-users';

  static String get getAllOrdersEndpoint =>
      '$baseApiPath/kot/order-filters-api';

  static String get getParentKotOrdersEndpoint =>
      '$baseApiPath/kot/get-parent-kot-orders';

  // Settings
  static String get getGeneralSettingsEndpoint =>
      '$baseApiPath/settings/get-general-settings';

  // Orders
  static String get getAllOrdersList =>
      '$baseApiPath/kot/get-all-orders';

  static String getAllTablesByTime(
      String reservationTime,
      String reservationDate,
      ) {
    return '$baseApiPath/tables/get-all-tables-by-time'
        '?reservation_time=${Uri.encodeComponent(reservationTime)}'
        '&reservation_date=${Uri.encodeComponent(reservationDate)}';
  }

  static String getAllSlotsByDate(
      String formattedDate,
      ) {
    return '$baseApiPath/slots/get-all-slots'
        '?reservation_date=$formattedDate';
  }

  static String cancelOrder(int orderId) {
    return '$baseApiPath/orders/$orderId';
  }
}