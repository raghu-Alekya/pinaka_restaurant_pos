// lib/constants/constants.dart

class AppConstants {
  static const String baseDomain = 'https://merchantrestaurant.alektasolutions.com';
  static const String baseApiPath = '$baseDomain/wp-json/pinaka-restaurant-pos/v1';

  // Authentication
  static const String authTokenEndpoint = '$baseApiPath/token';
  static const String empOrderPinValidationEndpoint = '$baseApiPath/emp-order-pin-validation';

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

  // Employee Management
  static const String getAllEmployeesEndpoint = '$baseApiPath/users/get-all-employees';

  // Shift Management
  static const String createShiftEndpoint = '$baseApiPath/shifts/create-shift';
  static const String getAllShiftsEndpoint = '$baseApiPath/users/get-all-shifts';
}
