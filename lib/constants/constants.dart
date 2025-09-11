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

  // Slots
  static String getAllSlotsByDate(String formattedDate) =>
      '$baseApiPath/slots/get-all-slots?reservation_date=$formattedDate';
}