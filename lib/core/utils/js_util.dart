import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class JsUtil {
  static bool isValidationFailed() {
    // Implement validation logic as needed
    return false;
  }

  static void addSuccessMessage(String message) {
    // Implement success message display
    if (kDebugMode) {
      developer.log('SUCCESS: $message');
    }
  }

  static void addErrorMessage(String message) {
    // Implement error message display
    if (kDebugMode) {
      developer.log('ERROR: $message');
    }
  }
}
