class Validators {
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // static String? validateStoreId(String? value) {
  //   if (value == null || value.trim().isEmpty) {
  //     return 'Store ID is required';
  //   }
  //   return null;
  // }
  //
  // static String? validateDeviceId(String? value) {
  //   if (value == null || value.trim().isEmpty) {
  //     return 'Device ID is required';
  //   }
  //   return null;
  // }
}