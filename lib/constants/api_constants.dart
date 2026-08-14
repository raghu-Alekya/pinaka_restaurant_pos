class ApiConstants {
  // Verify the domain: it must match exactly as in the curl
  static const String baseUrl =
      'https://test.alekyatechsolutions.com/wp-json/custom/v1';
  static const String merchantLoginEndpoint = '/validate-merchant';
  static String get merchantLoginUrl => '$baseUrl$merchantLoginEndpoint';
}