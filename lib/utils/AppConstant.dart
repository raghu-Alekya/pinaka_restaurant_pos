class AppConstants {
  static const String merchantBaseUrl =
      "https://test.alekyatechsolutions.com";
  static String baseDomain =
      'https://merchantrestaurant.alektasolutions.com';

  /// Update base URL dynamically after merchant login
  static void updateBaseUrl(String url) {
    baseDomain = url.endsWith('/')
        ? url.substring(0, url.length - 1)
        : url;
  }

  static String get baseApiPath =>
      '$baseDomain/wp-json/pinaka-restaurant-pos/v1';

  static String get merchantLoginEndpoint =>
      '$merchantBaseUrl/wp-json/custom/v1/validate-merchant';
  static String get authTokenEndpoint =>
      '$baseApiPath/token';

  static String get logoutEndpoint =>
      '$baseApiPath/logout';

  static String get empOrderPinValidationEndpoint =>
      '$baseApiPath/emp-order-pin-validation';

   static String get ordersEndpoint =>
      "$baseApiPath/orders";

  static String get kitchenDisplayOrdersEndpoint =>
      "$baseApiPath/kot/kitchen-display-orders";

  static String get kitchenItemsCountEndpoint =>
      "$baseApiPath/kot/get-kitchen-items-count";

  static String get parentKotOrdersEndpoint =>
      "$baseApiPath/kot/get-parent-kot-orders";


}