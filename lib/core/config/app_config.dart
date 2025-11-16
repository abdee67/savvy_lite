class AppConfig {
  static const bool isTestMode = true;
  static const bool bypassApi = true;
  static const bool useFakeData = true;

  static String get apiBaseUrl {
    if (bypassApi) {
      return ''; // Empty string prevents API calls
    }
    return 'https://your-real-api.com/api/v1';
  }
}
