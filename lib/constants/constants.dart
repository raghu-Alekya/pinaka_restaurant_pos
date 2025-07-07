// lib/constants/constants.dart

/// App-wide constant URLs
class AppConstants {
  static const String baseDomain = 'https://merchantrestaurant.alektasolutions.com';

  // API endpoints
  static const String authTokenEndpoint = '$baseDomain/wp-json/pinaka-restaurant-pos/v1/token';
  static const String createZoneEndpoint = '$baseDomain/wp-json/pinaka-pos/v1/zones/create-zone';
  static const String updateZoneEndpoint = '$baseDomain/wp-json/pinaka-pos/v1/zones/update-zone';
  static const String getAllZonesEndpoint = '$baseDomain/wp-json/pinaka-pos/v1/zones/get-all-zones';
  static const String deleteZoneEndpoint = '$baseDomain/wp-json/pinaka-pos/v1/zones/delete-zone';
  static const String createTableEndpoint = '$baseDomain/wp-json/pinaka-pos/v1/tables/create-table';
  static const String getAllTablesEndpoint= '$baseDomain/wp-json/pinaka-pos/v1/tables/get-all-tables';
  static const String updateTableEndpoint = '$baseDomain/wp-json/pinaka-pos/v1/tables/update-table';
  static const String deleteTableEndpoint = '$baseDomain/wp-json/pinaka-pos/v1/tables/delete-table';
}
