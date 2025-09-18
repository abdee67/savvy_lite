class ApiConstants {
  static const String baseUrl = 'https://api.api-domain.com/api/v1';

  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String logout = '$baseUrl/auth/logout';
  static const String refreshToken = '$baseUrl/auth/refresh';

  // System constants endpoints
  static const String systemConstants = '$baseUrl/system-constants';
  static String systemConstantById(int id) => '$systemConstants/$id';
  static const String systemConstantsSync = '$systemConstants/sync';

  // UDC endpoints
  static const String udcDetails = '$baseUrl/udc-details';
  static String udcDetailsById(int id) => '$udcDetails/$id';

  // Company endpoints
  static const String companies = '$baseUrl/companies';
  static String companyById(int id) => '$companies/$id';

  // User endpoints
  static const String users = '$baseUrl/users';
  static String userById(int id) => '$users/$id';
  static const String userProfile = '$users/profile';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers
  static const String contentTypeHeader = 'Content-Type';
  static const String authorizationHeader = 'Authorization';
  static const String acceptHeader = 'Accept';
  static const String contentTypeJson = 'application/json';
  static const String acceptJson = 'application/json';

  // Status codes
  static const int success = 200;
  static const int created = 201;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int internalServerError = 500;
  static const int serviceUnavailable = 503;
}
