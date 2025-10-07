class AppConstants {
  static const String baseDomain = 'https://merchantrestaurant.alektasolutions.com';
  static const String baseApiPath = '$baseDomain/wp-json/pinaka-restaurant-pos/v1';

  // Authentication
  static const String authTokenEndpoint = '$baseApiPath/token';
  static const String empOrderPinValidationEndpoint = '$baseApiPath/emp-order-pin-validation';
  static const String logoutEndpoint = '$baseApiPath/logout';

  // Zone Management
  static const String createZoneEndpoint = '$baseApiPath/zones/create-zone';
  static const String updateZoneEndpoint = '$baseApiPath/zones/update-zone';
  static const String getAllZonesEndpoint = '$baseApiPath/zones/get-all-zones';
  static const String deleteZoneEndpoint = '$baseApiPath/zones/delete-zone';

  // Dashboard
  static const String dashboardRevenueByFiltersEndpoint =
      '$baseApiPath/merchant-dashboard/get-revenue-by-filters';
  static const String topProductsSoldEndpoint =
      '$baseApiPath/merchant-dashboard/top-products-sold';
  static const String topCategoriesSoldEndpoint =
      '$baseApiPath/merchant-dashboard/top-categories-sold';

  // Table Management
  static const String createTableEndpoint = '$baseApiPath/tables/create-table';
  static const String getAllTablesEndpoint = '$baseApiPath/tables/get-all-tables';
  static const String updateTableEndpoint = '$baseApiPath/tables/update-table';
  static const String deleteTableEndpoint = '$baseApiPath/tables/delete-table';
  static const String getAllMergeTablesEndpoint = '$baseApiPath/tables/get-all-merge-tables';
  static const String createMergeTablesWithStatusEndpoint = '$baseApiPath/tables/create-merge-tables-with-table-status';
  static const String updateMergeTablesWithStatusEndpoint = '$baseApiPath/tables/update-merge-tables-with-table-status';
  static const String deleteMergeTablesWithStatusEndpoint = '$baseApiPath/tables/delete-merge-tables-with-table-status';
  static String getAllTablesByTime(String reservationTime, String reservationDate) => '$baseApiPath/tables/get-all-tables-by-time?reservation_time=${Uri.encodeComponent(reservationTime)}&reservation_date=${Uri.encodeComponent(reservationDate)}';

  // Employee Management
  static const String getAllEmployeesEndpoint = '$baseApiPath/users/get-all-employees';

  // Employee Attendance
  static const String currentShiftEmployeesEndpoint =
      '$baseApiPath/employee-attendance/current-shift';
  static const String employeeAttendanceEndpoint =
      '$baseApiPath/employee-attendance';
  static const String inventoryAlertsEndpoint =
      '$baseApiPath/employee-attendance/get-inventory-alerts';
  static const String completedOrdersEndpoint =
      '$baseApiPath/employee-attendance/get-all-completed-orders';

  // Shift Management
  static const String createShiftEndpoint = '$baseApiPath/shifts/create-shift';
  static const String updateShiftEndpoint = '$baseApiPath/shifts/update-shift';
  static const String closeShiftEndpoint = '$baseApiPath/shifts/close-shift';
  static const String currentShiftEndpoint = '$baseApiPath/shifts/current-shift';
  static const String getAllShiftsEndpoint = '$baseApiPath/users/get-all-shifts';

  // Reservation Management
  static const String createReservationEndpoint = '$baseApiPath/reservation/create-reservation';
  static const String getAllReservationsEndpoint = '$baseApiPath/reservation/get-all-reservations';
  static const String updateReservationEndpoint = '$baseApiPath/reservation/update-reservation';
  static const String cancelReservationEndpoint = '$baseApiPath/reservation/cancel-reservation';
  static const String reservationDateRangeEndpoint = '$baseApiPath/reservation/reservation-date-range';
  static const String getAllMergeTablesWithReservationEndpoint = '$baseApiPath/tables/get-all-merge-tables-with-reservation';

  // kitchen status
  static const String getAllOrderTypesEndpoint = '$baseApiPath/kot/get-all-order-types';
  static const String getAllUsersEndpoint = '$baseApiPath/users/get-all-users';
  static const String getAllOrdersEndpoint = '$baseApiPath/kot/order-filters-api';
  static const String getParentKotOrdersEndpoint = '$baseApiPath/kot/get-parent-kot-orders';

  // Slots
  static String getAllSlotsByDate(String formattedDate) =>
      '$baseApiPath/slots/get-all-slots?reservation_date=$formattedDate';
}