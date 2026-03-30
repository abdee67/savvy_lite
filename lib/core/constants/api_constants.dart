class ApiConstants {
  // Use a non-existent domain to ensure offline mode works
  // or empty string to avoid connection attempts
  static const String baseUrl = ''; // This will prevent connection attempts

  // Alternatively, if you want to test with a real API later:
  // static const String baseUrl = 'https://your-real-api.com/api/v1';

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String logout = '$baseUrl/auth/logout';
  static const String refreshToken = '$baseUrl/auth/refresh';

  // System constants endpoints
  static const String systemConstants = '$baseUrl/system-constants';
  static String systemConstantById(int id) => '$systemConstants/$id';

  // Sync endpoints (appended to target server URLs from system_url_config)
  static const String syncPush = '/api/sync/push';
  static const String syncPull = '/api/sync/pull';
  static const String syncNodeStatus = '/api/sync/node-status';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 5);

  // Headers
  static const String contentTypeHeader = 'Content-Type';
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeJson = 'application/json';
}
